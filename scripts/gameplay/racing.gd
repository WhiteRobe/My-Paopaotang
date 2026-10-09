extends RefCounted
# Race state shares the game's movement, bombs, players and save lifecycle.
const FIRST_MAP=44
const MAPS=3
const ART="maps/racing/race-v490.png"
const GROUND="maps/racing/terrain-v493.png"
const CHECKPOINT="maps/racing/checkpoints-v493.png"
var g
var laps=3
var time_limit=180
var selected=0
var route:Array=[]
var checkpoints:Array=[]
var road={}
var stations:Array=[]
var sidings={}
var cover={}
var station_timers={}
var finish_order:Array=[]
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
	# Each circuit has distinct corner order; the factory crosses itself at its hub.
	route=[Vector2i(1,1),Vector2i(25,1),Vector2i(25,7),Vector2i(17,7),Vector2i(17,16),Vector2i(1,16),Vector2i(1,10),Vector2i(9,10),Vector2i(9,6),Vector2i(1,6)]
	if index==45:route=[Vector2i(1,1),Vector2i(25,1),Vector2i(25,6),Vector2i(16,6),Vector2i(16,11),Vector2i(25,11),Vector2i(25,16),Vector2i(1,16),Vector2i(1,11),Vector2i(9,11),Vector2i(9,6),Vector2i(1,6)]
	elif index==46:route=[Vector2i(1,8),Vector2i(25,8),Vector2i(25,1),Vector2i(13,1),Vector2i(13,16),Vector2i(1,16)]
	road.clear();checkpoints.clear();stations.clear();station_timers.clear()
	for i in range(route.size()):
		var a=route[i];var b=route[(i+1)%route.size()];var dir=(b-a).sign();var c=a
		while true:
			for y in range(2):
				for x in range(2):road[c+Vector2i(x,y)]=true
			if c==b:break
			c+=dir
		checkpoints.append({"pos":Vector2(a+b)/2+Vector2.ONE*.5,"dir":Vector2(dir)})
	if index==46:checkpoints[0].pos=Vector2(19.5,8.5)
	# Supply bays sit off the track and connect to the infield alleys.
	stations=[Vector2i(24,3),Vector2i(3,8)]
	if index==45:stations=[Vector2i(21,3),Vector2i(5,15)]
	elif index==46:stations=[Vector2i(21,10),Vector2i(3,13)]
	sidings.clear();cover.clear()
	var links=[ [Vector2i(5,2),Vector2i(5,6)], [Vector2i(10,13),Vector2i(18,13)], [Vector2i(21,2),Vector2i(21,7)] ]
	var islands=[Vector2i(12,4),Vector2i(3,12),Vector2i(12,13),Vector2i(21,11),Vector2i(23,14)]
	if index==45:
		links=[[Vector2i(5,2),Vector2i(5,6)],[Vector2i(20,7),Vector2i(20,11)],[Vector2i(5,12),Vector2i(5,16)],[Vector2i(10,8),Vector2i(16,8)]]
		islands=[Vector2i(11,4),Vector2i(3,8),Vector2i(12,13),Vector2i(21,13),Vector2i(22,8)]
	elif index==46:
		links=[[Vector2i(18,2),Vector2i(18,8)],[Vector2i(2,12),Vector2i(13,12)],[Vector2i(7,9),Vector2i(7,16)]]
		islands=[Vector2i(16,4),Vector2i(21,4),Vector2i(4,10),Vector2i(10,13),Vector2i(4,3),Vector2i(8,4),Vector2i(18,13),Vector2i(23,14)]
	for link in links:
		var c=link[0];var dir=(link[1]-c).sign()
		while true:
			sidings[c]=true
			if c==link[1]:break
			c+=dir
	for at in islands:
		for y in range(2):
			for x in range(2):
				var c=at+Vector2i(x,y)
				if not road.has(c) and not sidings.has(c):cover[c]=true
	var finish=Vector2i(checkpoints[0].pos)
	for y in range(g.H):
		var row=[]
		for x in range(g.W):row.append(0 if road.has(Vector2i(x,y)) else 1)
		g.grid.append(row)
	g.SPAWNS=[]
	for i in range(8):g.SPAWNS.append(finish+Vector2i(-2-int(i/2)*2,1+i%2))
	# The infield is playable: crate islands separated by connected supply alleys.
	for y in range(1,g.H-1):
		for x in range(1,g.W-1):
			var c=Vector2i(x,y)
			if not road.has(c):g.grid[y][x]=1 if cover.has(c) else 0 if sidings.has(c) or x%4==0 or y%4==0 else 2
	for i in range(route.size()):
		var a=route[i];var b=route[(i+1)%route.size()];var dir=(b-a).sign()
		for n in range(3,int(g.manhattan(a,b))-2,5):
			var c=a+dir*n+(Vector2i.DOWN if dir.x>0 else Vector2i.RIGHT if dir.y<0 else Vector2i.ZERO)
			if not checkpoints.any(func(cp):return Vector2(c).distance_to(cp.pos)<2):g.grid[c.y][c.x]=2
	# Keep the gate and its roadside beacons free of crates.
	for cp in checkpoints:
		for y in range(1,g.H-1):
			for x in range(1,g.W-1):
				if Vector2(x,y).distance_to(cp.pos)<1.6:g.grid[y][x]=0
	for c in g.SPAWNS:
		for d in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.RIGHT]:g.grid[c.y+d.y][c.x+d.x]=0
		if not road.has(c+Vector2i(0,2)):g.grid[c.y+2][c.x]=2
	for c in stations:
		for d in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var bay=c+d
			if g.inside(bay) and bay.x>0 and bay.x<g.W-1 and bay.y>0 and bay.y<g.H-1:
				g.grid[bay.y][bay.x]=0;cover.erase(bay)
				if not road.has(bay):sidings[bay]=true
	g.crates.setup()
func setup():
	finish_order.clear();ship=null;parcels.clear();ship_wait=g.rng.randf_range(15,23)
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
	if g.clock_time<=0:finish();return
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
				if p.race_lap>=laps:complete(p)
			p.race_next=(p.race_next+1)%checkpoints.size()
		p.race_before=p.visual
	if finish_order.size()==g.players.size():finish()
func finish():
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
	p.velocity=Vector2.ZERO;p.move=1;p.facing=Vector2i.DOWN
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
	var on_road=road.has(p.cell)
	var maximum=(6.0+p.speed*.12)*(1.0 if on_road else .42)
	if p.slow>0:maximum*=.55
	if p.dash>0:maximum*=1.18
	if dir==Vector2.ZERO:return p.velocity.move_toward(Vector2.ZERO,dt*20)
	# Brake reversals first; remove sideways drift quickly when steering.
	if p.velocity.dot(dir)<-.1:return p.velocity.move_toward(Vector2.ZERO,dt*28)
	var forward=maxf(0,p.velocity.dot(dir))
	var sideways=(p.velocity-dir*forward).move_toward(Vector2.ZERO,dt*32)
	forward=move_toward(forward,maximum,dt*(10 if on_road else 4.5))
	var velocity=(dir*forward+sideways).limit_length(maxf(maximum,p.velocity.length()-dt*12))
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
	# A car collected inside the supply maze returns to the nearest reachable track.
	if not road.has(p.cell):
		var queue=[p.cell];var visited={p.cell:true};var head=0
		while head<queue.size():
			var c=queue[head];head+=1
			if road.has(c):return g.route_direction(p,c,danger)
			for d in g.DIRS:
				var next=c+d
				if visited.has(next) or danger.has(next) or not g.passable(next,p):continue
				visited[next]=true;queue.append(next)
	var cp=checkpoints[p.race_next]
	var corner=Vector2(route[p.race_next])+Vector2.ONE*.5;var goal=cp.pos+cp.dir*1.1
	# Recover a missed gate from its approach side instead of circling beyond it forever.
	if (p.visual-cp.pos).dot(cp.dir)>=0:goal=cp.pos-cp.dir*1.1
	var previous=checkpoints[posmod(p.race_next-1,checkpoints.size())]
	if p.race_corner!=p.race_next:
		if (p.visual-corner).dot(previous.dir)<-.35:goal=corner+previous.dir*.55
		else:p.race_corner=p.race_next
	var track_danger=danger.duplicate()
	for y in range(1,g.H-1):
		for x in range(1,g.W-1):
			var c=Vector2i(x,y)
			if not road.has(c):track_danger[c]=0
	var direction=g.route_direction(p,Vector2i(goal.round()),track_danger)
	if direction==Vector2i.ZERO:direction=g.route_direction(p,Vector2i(goal.round()),danger)
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
func draw_tile(c):
	var theme=g.arena-FIRST_MAP;var pos=g.ORIGIN+Vector2(c)*g.TILE
	var lane=road.has(c);var kind=0 if lane else 2 if g.grid[c.y][c.x]==1 and not cover.has(c) else 1
	g.hd.sprite(GROUND,theme*3+kind,pos,Vector2.ONE*g.TILE,Color.WHITE,false)
	if sidings.has(c) and not lane:
		g.canvas.draw_line(pos+Vector2(4,8),pos+Vector2(12,8),Color(.85,.75,.52,.45),1)
	# Thin edging follows every actual track edge, in all four directions.
	if lane:
		for d in g.DIRS:
			if road.has(c+d):continue
			var at=pos+Vector2(0,14 if d.y>0 else 0) if d.y!=0 else pos+Vector2(14 if d.x>0 else 0,0)
			g.hd.sprite(GROUND,theme*3+2,at,Vector2(16,2) if d.y!=0 else Vector2(2,16),Color.WHITE,false)
func draw_ground():
	for i in range(route.size()):
		var a=Vector2(route[i])+Vector2.ONE*.5;var b=Vector2(route[(i+1)%route.size()])+Vector2.ONE*.5;var dir=(b-a).normalized()
		for n in range(2,int(a.distance_to(b))-1,4):
			var at=g.ORIGIN+(a+dir*n+Vector2.ONE*.5)*g.TILE
			g.canvas.draw_line(at,at+dir*7,Color(.98,.91,.68,.45),1)
	var viewer=g.players[view_player] if view_player>=0 else null
	for i in range(checkpoints.size()):
		var cp=checkpoints[i];var pos=g.ORIGIN+(cp.pos+Vector2.ONE*.5)*g.TILE
		var side=Vector2(-cp.dir.y,cp.dir.x)
		var next=viewer!=null and not viewer.race_finished and viewer.race_next==i
		var color=Color("8bfff2") if next else Color("83c7d0")
		if next:
			for ring in range(3):
				var radius=11+ring*4+sin(g.elapsed*4)*1.5
				g.canvas.draw_circle(pos,radius,Color(color,.07))
		g.canvas.draw_set_transform(pos+Vector2(sin(g.elapsed*83),cos(g.elapsed*71))*g.shake,Vector2.UP.angle_to(cp.dir))
		g.hd.sprite(CHECKPOINT,1 if next else 0,Vector2(-18,-5),Vector2(36,10),Color.WHITE)
		g.canvas.draw_set_transform(Vector2(sin(g.elapsed*83),cos(g.elapsed*71))*g.shake)
		if i==0:g.hd.sprite(CHECKPOINT,3,pos-cp.dir*12-Vector2(8,8),Vector2(16,16))
		for sign_value in [-1,1]:
			var at=pos+side*sign_value*20
			g.hd.sprite(CHECKPOINT,2,at-Vector2(6,14),Vector2(12,18),Color(1,1,1,1 if next else .58))
			if next:
				g.canvas.draw_circle(at+Vector2(0,3),3.2+sin(g.elapsed*5)*.7,Color(.45,1,.9,.25))
		if next:
			for n in range(3):
				var at=pos-cp.dir*(11+fposmod(g.elapsed*10+n*8,24))
				g.canvas.draw_polyline(PackedVector2Array([at-cp.dir*2-side*2,at,at-cp.dir*2+side*2]),Color("a6fff0"),1.2)
	for c in stations:g.hd.sprite(ART,6,g.center(c)-Vector2(9,7),Vector2(18,16))
func draw_air():
	if not g.hd.regions.has(ART):return
	if ship!=null:
		var at=g.ORIGIN+Vector2(ship.x,ship.y)*g.TILE
		var overlaps=g.players.any(func(p):return not p.dead and absf(p.visual.x-ship.x)<2.5 and p.visual.y>ship.y-3.6 and p.visual.y<ship.y)
		g.hd.sprite(ART,4,at-Vector2(35,50),Vector2(70,38),Color(1,1,1,.35 if overlaps else .9))
	for parcel in parcels:
		var at=g.center(parcel.cell)-Vector2(0,parcel.time*28)
		g.hd.sprite(ART,5,at-Vector2(9,20),Vector2(18,24))
func draw_car(pos,p,tint):
	if p.race_finished:pos.y-=absf(sin(g.elapsed*6+p.id*.4))*2.5
	if p.grace>0:tint.a=.6+.4*sin(g.elapsed*22)
	var direction=0 if p.facing==Vector2i.DOWN else 1 if p.facing==Vector2i.UP else 2 if p.facing==Vector2i.LEFT else 3
	var frame=int(g.elapsed*6)%4 if p.race_finished else int(p.gait*2)%4 if p.move<1 else 0
	g.canvas.draw_set_transform(pos+Vector2(0,5),0,Vector2(1,.35))
	g.canvas.draw_circle(Vector2.ZERO,12,Color(.05,.09,.15,.3*tint.a))
	g.canvas.draw_arc(Vector2.ZERO,13,0,TAU,32,Color(g.color_for(p),.85*tint.a),1.4)
	g.canvas.draw_set_transform(Vector2(sin(g.elapsed*83),cos(g.elapsed*71))*g.shake)
	g.hd.riding_sprite(pos,p,4,direction,frame,tint)
	g.text_at(("B" if p.bot else "P")+str(p.id+1),pos+Vector2(-7,-24),7,g.color_for(p))
	if p.reverse_time>0:g.item_icon(pos+Vector2(-5,-38),30,10)
	if p.shield>0:g.canvas.draw_arc(pos+Vector2(0,-5),17,g.elapsed*1.5,g.elapsed*1.5+TAU*.8,32,Color("b3ffe0"),1)
	if p.freeze>0:g.rect(pos+Vector2(-15,-24),Vector2(30,32),Color(.67,.88,1,.16))
	if p.trap>0:
		g.hd.sprite("effects/bubbles-hd.png",7,pos+Vector2(-16,-28),Vector2(32,34))
		g.text_at(str(snappedf(p.trap,.1)),pos+Vector2(8,9),8,Color("fff3c5"))
	if p.race_finished:
		for n in range(4):
			var at=pos+Vector2((n-1.5)*7,-21-fposmod(g.elapsed*10+n*4,15))
			g.canvas.draw_line(at-Vector2(1.5,0),at+Vector2(1.5,0),Color(1,.86,.35,.8),1)
			g.canvas.draw_line(at-Vector2(0,1.5),at+Vector2(0,1.5),Color(1,.86,.35,.8),1)
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
		views[i].clip.position=Vector2(5+(i%columns)*254,26+int(i/columns)*160)
		views[i].clip.size=Vector2(506 if columns==1 else 249,312 if rows==1 else 152)
		views[i].canvas.queue_redraw()
func draw_hud():
	g.text_at(g.Catalog.MAPS[g.arena].name,Vector2(8,15),10,g.CREAM,200)
	g.draw_round_timer()
	g.button(Vector2(552,3),Vector2(80,20),"暂停 / 退出")
	g.panel(Vector2(518,27),Vector2(115,311),Color("62ceff"))
	g.text_at("当前名次",Vector2(525,43),11,Color("ffe3a8"),100)
	var list=ordered()
	for i in range(list.size()):
		var p=list[i];var at=Vector2(525,61+i*31)
		g.text_at(str(i+1)+". "+("B" if p.bot else "P")+str(p.id+1)+" · "+g.team_name(p.team),at,8,g.color_for(p),100)
		var label=(g.loc("%d 分") % p.race_points) if p.race_finished else (g.loc("复活 %d 秒") % ceili(p.respawn)) if p.dead else (g.loc("%d/%d 圈 · CP%d") % [p.race_lap,laps,p.race_next])
		g.text_at(label,at+Vector2(0,10),7,g.CREAM,100)
		g.text_at(g.loc("泡泡%d · 水柱%d · 速度%d") % [p.capacity,p.range,p.speed],at+Vector2(0,20),7,Color("acd5df"),100)
	g.text_at("仅驾驶赛车通过检查点有效",Vector2(8,353),8,g.CREAM,300)
