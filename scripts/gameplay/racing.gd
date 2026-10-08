extends RefCounted
# Race state shares the game's movement, bombs, players and save lifecycle.
const FIRST_MAP=44
const MAPS=3
const ART="maps/racing/race-v490.png"
var g
var laps=3
var time_limit=180
var selected=0
var route:Array=[]
var checkpoints:Array=[]
var road={}
var stations:Array=[]
var station_timers={}
var finish_order:Array=[]
var overtime=0.0
var views:Array=[]
var view_team=-1
var view_player=-1
var ship=null
var parcels:Array=[]
var ship_wait=18.0
func _init(game):g=game
func active():return g.mode==1
func build(index):
	g.arena=index;g.W=28;g.H=19;g.camera=Vector2.ZERO;g.map_void.clear()
	g.grid.clear();g.terrain.clear();g.gates.clear();g.vine_cells.clear();g.gold_boxes.clear()
	route=[Vector2i(1,1),Vector2i(25,1),Vector2i(25,16),Vector2i(1,16)]
	if index==45:route=[Vector2i(1,1),Vector2i(25,1),Vector2i(25,8),Vector2i(18,8),Vector2i(18,16),Vector2i(1,16)]
	elif index==46:route=[Vector2i(1,1),Vector2i(18,1),Vector2i(18,8),Vector2i(25,8),Vector2i(25,16),Vector2i(1,16)]
	road.clear();checkpoints.clear();stations.clear();station_timers.clear()
	for i in range(route.size()):
		var a=route[i];var b=route[(i+1)%route.size()];var dir=(b-a).sign();var c=a
		while true:
			for y in range(2):
				for x in range(2):road[c+Vector2i(x,y)]=true
			if c==b:break
			c+=dir
		checkpoints.append({"pos":Vector2(a+b)/2+Vector2.ONE*.5,"dir":Vector2(dir)})
	# Two starting rows stay on the track; a single inner supply strip replaces the yard.
	var finish=Vector2i(checkpoints[0].pos)
	for y in range(g.H):
		var row=[]
		for x in range(g.W):row.append(0 if road.has(Vector2i(x,y)) else 1)
		g.grid.append(row)
	g.SPAWNS=[]
	for i in range(8):g.SPAWNS.append(finish+Vector2i(-2-int(i/2)*2,i%2))
	# Small supply alcoves sit inside the two-lane circuit.
	for i in range(route.size()):
		var a=route[i];var b=route[(i+1)%route.size()];var dir=(b-a).sign();var side=Vector2i(-dir.y,dir.x)
		for n in range(3,int(g.manhattan(a,b))-2,5):
			var anchor=a+dir*n+(Vector2i.DOWN if dir.x>0 else Vector2i.RIGHT if dir.y<0 else Vector2i.ZERO)
			for depth in range(1,3):
				for offset in range(2):
					var c=anchor+side*depth+dir*offset
					if not g.inside(c) or road.has(c):continue
					g.grid[c.y][c.x]=2 if (depth+offset+n)%3!=0 else 0
			# Boxes occupy the inner lane only; the outer lane stays usable before bombing.
			var c=anchor
			if not checkpoints.any(func(cp):return Vector2(c).distance_to(cp.pos)<2):g.grid[c.y][c.x]=2
	for c in g.SPAWNS:
		for d in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.RIGHT]:g.grid[c.y+d.y][c.x+d.x]=0
		g.grid[3][c.x]=2
	stations=[route[1],route[-1]]
	for c in stations:g.grid[c.y][c.x]=0
	g.crates.setup()
func setup():
	finish_order.clear();overtime=0;ship=null;parcels.clear();ship_wait=g.rng.randf_range(15,23)
	for p in g.players:
		p.car=false;p.race_lap=0;p.race_next=1;p.race_rank=0;p.race_points=0;p.race_finished=false;p.respawn=0.0
		p.race_corner=-1;p.race_attack=0.0;p.race_flash=0.0;p.race_before=p.visual;p.race_checkpoint=p.visual;p.car_heading=Vector2.RIGHT
		p.facing=Vector2i.RIGHT
	for c in stations:station_timers[c]=12.0
func reset_air():
	ship=null;parcels.clear();ship_wait=g.rng.randf_range(18,30)
func airborne(dt):
	ship_wait-=dt
	if ship==null and ship_wait<=0:
		var cells=[]
		for y in range(2,g.H-2):
			for x in range(2,g.W-2):
				var c=Vector2i(x,y)
				if g.grid[y][x]==0 and not g.drops.has(c):cells.append(c)
		if not cells.is_empty():
			var target=cells[g.rng.randi_range(0,cells.size()-1)]
			ship={"x":-5.0,"y":float(target.y),"target":target,"dropped":false}
		ship_wait=g.rng.randf_range(28,44)
	if ship!=null:
		ship.x+=dt*8
		if not ship.dropped and ship.x>=ship.target.x:
			ship.dropped=true
			parcels.append({"cell":ship.target,"time":1.5,"kind":31 if active() else g.random_drop()})
		if ship.x>g.W+5:ship=null
	for parcel in parcels:
		parcel.time-=dt
		if parcel.time<=0 and g.inside(parcel.cell) and g.grid[parcel.cell.y][parcel.cell.x]==0 and not g.drops.has(parcel.cell) and g.bomb_at(parcel.cell)==null:
			g.drops[parcel.cell]=parcel.kind;g.burst(g.center(parcel.cell),Color("ffe3a8"),8)
	parcels=parcels.filter(func(p):return p.time>0)
func update(dt):
	for c in stations:
		station_timers[c]=station_timers.get(c,30.0)-dt
		if station_timers[c]<=0:
			if g.grid[c.y][c.x]==0 and not g.drops.has(c) and g.bomb_at(c)==null:g.drops[c]=31
			station_timers[c]=30.0
	for p in g.players:
		p.race_flash=maxf(0,p.race_flash-dt);p.race_attack=maxf(0,p.race_attack-dt)
		if p.race_finished:continue
		if p.dead:
			p.respawn-=dt
			if p.respawn<=0:revive(p)
			continue
		var cp=checkpoints[p.race_next]
		var before=(p.race_before-cp.pos).dot(cp.dir)
		var after=(p.visual-cp.pos).dot(cp.dir)
		var side=Vector2(-cp.dir.y,cp.dir.x)
		var crossing=p.race_before.lerp(p.visual,clampf(-before/(after-before),0,1)) if after>before else p.visual
		if p.car and before<0 and after>=0 and absf((crossing-cp.pos).dot(side))<=1.0:
			p.race_corner=-1;p.race_flash=.9;g.sound("pickup")
			p.race_checkpoint=cp.pos+cp.dir
			if p.race_next==0:
				p.race_lap+=1
				if p.race_lap>=laps or g.clock_time<=0:complete(p)
			p.race_next=(p.race_next+1)%checkpoints.size()
		p.race_before=p.visual
	if g.clock_time<=0:overtime+=dt
	# A stopped/absent player cannot keep the lobby waiting forever.
	if finish_order.size()==g.players.size() or overtime>=60:
		var totals={}
		for p in g.players:totals[p.team]=totals.get(p.team,0)+p.race_points
		var best=-1;var winners=[]
		for team in totals:
			if totals[team]>best:best=totals[team];winners=[team]
			elif totals[team]==best:winners.append(team)
		var winner=winners[0] if winners.size()==1 and best>0 else -1
		g.finish_round(winner)
func complete(p):
	if p.race_finished:return
	p.race_finished=true;p.race_rank=finish_order.size()+1;p.race_points=9-p.race_rank
	p.velocity=Vector2.ZERO;p.move=1
	finish_order.append(p.id);g.sound("win")
func revive(p):
	var origin=Vector2i(p.race_checkpoint.round());var danger=g.danger_cells();var chosen=null
	for radius in range(5):
		for d in g.DIRS:
			var c=origin+d*radius
			if g.passable(c) and danger.get(c,99)>1:chosen=c;break
		if chosen!=null:break
	if chosen==null:p.respawn=.5;return
	p.dead=false;p.car=false;p.mount=0;p.trap=0;p.freeze=0;p.slow=0;p.grace=2.5;p.down=0;p.item=0
	g.teleport(p,chosen);p.race_before=p.visual;p.race_corner=-1
func vehicle_velocity(p,dir,dt):
	var maximum=(6.0 if road.has(p.cell) else 3.4)+p.speed*.12
	if p.slow>0:maximum*=.55
	if p.dash>0:maximum*=1.18
	if dir==Vector2.ZERO:return p.velocity.move_toward(Vector2.ZERO,dt*20)
	# Brake reversals first; remove sideways drift quickly when steering.
	if p.velocity.dot(dir)<-.1:return p.velocity.move_toward(Vector2.ZERO,dt*28)
	var forward=maxf(0,p.velocity.dot(dir))
	var sideways=(p.velocity-dir*forward).move_toward(Vector2.ZERO,dt*32)
	forward=move_toward(forward,maximum,dt*10)
	var velocity=(dir*forward+sideways).limit_length(maximum)
	p.car_heading=velocity.normalized() if velocity.length()>.1 else dir
	return velocity
func bot_direction(p,danger):
	if p.race_finished:return Vector2i.ZERO
	if danger.has(p.cell):return g.escape_direction(p,danger)
	if not p.car:
		var queue=[p.cell];var visited={p.cell:true};var best=null;var score=99999
		var distance={p.cell:0}
		while not queue.is_empty():
			var c=queue.pop_front();var cost=distance[c]
			if g.drops.has(c):
				var kind=int(g.drops[c])
				if kind==31 or (kind in [4,5,7] and not g.growth_full(p,kind)):
					var value=cost-12 if kind==31 else cost-3
					if value<score:best=c;score=value
			if g.DIRS.any(func(d):return g.inside(c+d) and g.grid[c.y+d.y][c.x+d.x]==2) and cost+2<score:
				best=c;score=cost+2
			for d in g.DIRS:
				var next=c+d
				if visited.has(next) or danger.has(next) or not g.passable(next,p) or not g.can_cross(c,next):continue
				visited[next]=true;distance[next]=cost+1;queue.append(next)
		if best!=null:return g.route_direction(p,best,danger)
	var cp=checkpoints[p.race_next]
	var corner=Vector2(route[p.race_next])+Vector2.ONE*.5;var goal=cp.pos+cp.dir*1.1
	# Recover a missed gate from its approach side instead of circling beyond it forever.
	if (p.visual-cp.pos).dot(cp.dir)>=0:goal=cp.pos-cp.dir*1.1
	var previous=checkpoints[posmod(p.race_next-1,checkpoints.size())]
	if p.race_corner!=p.race_next:
		if (p.visual-corner).dot(previous.dir)<-.35:goal=corner+previous.dir*.55
		else:p.race_corner=p.race_next
	var direction=g.route_direction(p,Vector2i(goal.round()),danger)
	if direction!=Vector2i.ZERO:return direction
	var delta=goal-p.visual
	if delta.length()<.2:return Vector2i(cp.dir)
	return Vector2i(signf(delta.x),0) if absf(delta.x)>absf(delta.y) else Vector2i(0,signf(delta.y))
func ordered():
	var list=g.players.duplicate()
	list.sort_custom(func(a,b):
		if a.race_finished or b.race_finished:return a.race_rank<b.race_rank if a.race_finished and b.race_finished else a.race_finished
		var ap=a.race_lap*checkpoints.size()+posmod(a.race_next-1,checkpoints.size())
		var bp=b.race_lap*checkpoints.size()+posmod(b.race_next-1,checkpoints.size())
		if ap!=bp:return ap>bp
		return a.visual.distance_to(checkpoints[a.race_next].pos)<b.visual.distance_to(checkpoints[b.race_next].pos))
	return list
func bot_actions(p,danger):
	# Space attacks out so racers can escape their own bombs and keep progressing.
	if p.race_attack>0 or danger.has(p.cell):return
	var supplies=not p.car and g.DIRS.any(func(d):return g.inside(p.cell+d) and g.grid[p.cell.y+d.y][p.cell.x+d.x]==2)
	var blocked=p.car and p.ai_dir!=Vector2i.ZERO and not g.passable(p.cell+p.ai_dir,p)
	var rival=p.car and g.difficulty>0 and g.players.any(func(other):return not other.dead and not other.race_finished and other.team!=p.team and g.manhattan(p.cell,other.cell)<=mini(2,p.range) and (other.visual-p.visual).dot(p.car_heading)>.5)
	if not supplies and not blocked and not rival and p.item==0:return
	var count=g.bombs.size()
	g.bot_actions(p,danger)
	if g.bombs.size()>count:p.race_attack=3.0 if supplies or blocked else 8.0 if g.difficulty==1 else 5.0
func draw_ground():
	for i in range(route.size()):
		var a=Vector2(route[i])+Vector2.ONE*.5;var b=Vector2(route[(i+1)%route.size()])+Vector2.ONE*.5;var dir=(b-a).normalized()
		for n in range(2,int(a.distance_to(b))-1,4):
			var at=g.ORIGIN+(a+dir*n+Vector2.ONE*.5)*g.TILE
			g.canvas.draw_line(at,at+dir*10,Color(.91,.91,.78,.5),1.2)
	var viewer=null
	for p in g.players:
		if not p.bot and (view_team<0 or p.team==view_team):viewer=p;break
	# Each split follows its own player, including teammates on different checkpoints.
	if view_player>=0:viewer=g.players[view_player]
	for i in range(checkpoints.size()):
		var cp=checkpoints[i];var pos=g.ORIGIN+(cp.pos+Vector2.ONE*.5)*g.TILE
		var side=Vector2(-cp.dir.y,cp.dir.x);var next=viewer!=null and not viewer.race_finished and viewer.race_next==i
		var color=Color("ffe08e") if i==0 or next else Color("66dfff")
		g.canvas.draw_line(pos-side*g.TILE,pos+side*g.TILE,Color(.04,.11,.18,.85),7)
		for n in range(8):
			var at=pos+side*(n-3.5)*4
			g.canvas.draw_line(at-cp.dir*2,at+cp.dir*2,color if n%2==0 else Color("203443"),4)
		if next:
			g.canvas.draw_line(pos-side*g.TILE,pos+side*g.TILE,Color(color, .45+.3*sin(g.elapsed*5)),2)
			for n in range(3):
				var at=pos-cp.dir*(10+fposmod(g.elapsed*12+n*9,27))
				g.canvas.draw_polyline(PackedVector2Array([at-cp.dir*3-side*3,at,at-cp.dir*3+side*3]),color,1.5)
		for sign_value in [-1,1]:
			g.hd.sprite(ART,7 if i==0 else 11,pos+side*sign_value*1.25*g.TILE-Vector2(5,9),Vector2(10,14))
	for c in stations:
		g.hd.sprite(ART,6,g.center(c)-Vector2(9,7),Vector2(18,16))
func draw_checkpoint_labels():
	var viewer=g.players[view_player] if view_player>=0 else null
	for i in range(checkpoints.size()):
		var cp=checkpoints[i];var pos=g.ORIGIN+(cp.pos+Vector2.ONE*.5)*g.TILE
		var next=viewer!=null and not viewer.race_finished and viewer.race_next==i
		var color=Color("ffe08e") if i==0 or next else Color("66dfff")
		var label=g.loc("终点") if i==0 else g.loc("检查点 %d") % i
		if next:label=g.loc("下一检查点 %d") % i if i>0 else g.loc("下一站：终点")
		var width=76 if next else 54
		var side=Vector2(-cp.dir.y,cp.dir.x)
		var at=pos+side*(g.TILE+10+(width*.5 if side.x!=0 else 0))-Vector2(width*.5,6)
		if view_player>=0:
			var base=g.ORIGIN+g.camera*g.TILE;var extent=g.canvas.get_parent().size
			if not Rect2(base,extent).has_point(pos):continue
			at=at.clamp(base+Vector2(2,31),base+extent-Vector2(width+2,14))
		g.rect(at,Vector2(width,12),Color(.04,.11,.18,.82))
		g.text_at(label,at+Vector2(3,9),7,color,width-6)
func draw_air():
	if active():draw_checkpoint_labels()
	if not g.hd.regions.has(ART):return
	if ship!=null:
		var at=g.ORIGIN+Vector2(ship.x,ship.y)*g.TILE
		var overlaps=g.players.any(func(p):return not p.dead and absf(p.visual.x-ship.x)<2.5 and p.visual.y>ship.y-3.6 and p.visual.y<ship.y)
		g.hd.sprite(ART,4,at-Vector2(35,50),Vector2(70,38),Color(1,1,1,.35 if overlaps else .9))
	for parcel in parcels:
		var at=g.center(parcel.cell)-Vector2(0,parcel.time*28)
		g.hd.sprite(ART,5,at-Vector2(9,20),Vector2(18,24))
func draw_car(pos,p,tint):
	if p.grace>0:tint.a=.6+.4*sin(g.elapsed*22)
	var direction=0 if p.facing==Vector2i.DOWN else 1 if p.facing==Vector2i.UP else 2 if p.facing==Vector2i.LEFT else 3
	g.hd.sprite(ART,direction,pos+Vector2(-13,-13),Vector2(26,21),tint)
	g.hero_sprite(pos+Vector2(-7,-21),p.character,Vector2(14,15),direction,0,tint,true,-1,p.id)
	g.text_at(("B" if p.bot else "P")+str(p.id+1),pos+Vector2(-7,-24),7,g.COLORS[p.id])
	if p.reverse_time>0:g.item_icon(pos+Vector2(-5,-38),30,10)
	if p.shield>0:g.canvas.draw_arc(pos+Vector2(0,-5),17,g.elapsed*1.5,g.elapsed*1.5+TAU*.8,32,Color("b3ffe0"),1)
	if p.freeze>0:g.rect(pos+Vector2(-15,-24),Vector2(30,32),Color(.67,.88,1,.16))
	if p.trap>0:
		g.hd.sprite("effects/bubbles-hd.png",7,pos+Vector2(-16,-28),Vector2(32,34))
		g.text_at(str(snappedf(p.trap,.1)),pos+Vector2(8,9),8,Color("fff3c5"))
	g.draw_bubble_break(pos,p)
func sync_views():
	var visible=active() and g.state in ["play","pause","finale","result"]
	var humans=g.players.filter(func(p):return not p.bot)
	while views.size()<humans.size():
		var clip=Control.new();clip.clip_contents=true;clip.mouse_filter=Control.MOUSE_FILTER_IGNORE
		g.add_child(clip)
		var canvas=preload("res://scripts/render/world_canvas.gd").new();canvas.g=g;canvas.race_view=views.size();clip.add_child(canvas)
		views.append({"clip":clip,"canvas":canvas})
	for i in range(views.size()):
		views[i].clip.visible=visible and i<humans.size()
		if not views[i].clip.visible:continue
		var columns=1 if humans.size()==1 else 2;var rows=2 if humans.size()>2 else 1
		views[i].clip.position=Vector2(8+(i%columns)*220,43+int(i/columns)*154)
		views[i].clip.size=Vector2(432 if columns==1 else 212,300 if rows==1 else 146)
		views[i].canvas.queue_redraw()
func draw_hud():
	g.text_at(g.Catalog.MAPS[g.arena].name,Vector2(8,15),12,g.CREAM,260)
	g.text_at(g.loc("剩余 %d 秒") % maxi(0,ceili(g.clock_time)) if g.clock_time>0 else "加时：下次过终点结束",Vector2(8,32),10,Color("ffe3a8"),300)
	g.panel(Vector2(451,43),Vector2(181,299),Color("62ceff"))
	g.text_at("当前名次",Vector2(462,61),14,Color("ffe3a8"))
	var list=ordered()
	for i in range(list.size()):
		var p=list[i];var at=Vector2(462,80+i*28)
		g.text_at(str(i+1)+". "+("B" if p.bot else "P")+str(p.id+1)+" · "+(g.loc("队伍 %d") % (p.team+1)),at,10,g.COLORS[p.team])
		var label=(g.loc("%d 分") % p.race_points) if p.race_finished else (g.loc("复活 %d 秒") % ceili(p.respawn)) if p.dead else (g.loc("%d/%d 圈 · CP%d") % [p.race_lap,laps,p.race_next])
		g.text_at(label,at+Vector2(0,12),8,g.CREAM)
	g.text_at("仅驾驶赛车通过检查点有效",Vector2(461,313),8,g.CREAM,165)
	g.button(Vector2(549,315),Vector2(78,25),"暂停 / 退出")
	for i in range(views.size()):
		if views[i].clip.visible:g.text_at("P"+str(g.players.filter(func(p):return not p.bot)[i].id+1),views[i].clip.position+Vector2(4,-3),9,Color("ffe3a8"))
