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
var ship=null
var parcels:Array=[]
var ship_wait=18.0
func _init(game):g=game
func active():return g.mode==1
func build(index):
	g.arena=index;g.W=67;g.H=43;g.camera=Vector2.ZERO;g.map_void.clear()
	g.grid.clear();g.terrain.clear();g.gates.clear();g.vine_cells.clear();g.gold_boxes.clear()
	route=[Vector2i(10,7),Vector2i(56,7),Vector2i(56,35),Vector2i(10,35)]
	if index==45:route=[Vector2i(10,7),Vector2i(56,7),Vector2i(56,20),Vector2i(40,20),Vector2i(40,35),Vector2i(10,35)]
	elif index==46:route=[Vector2i(10,7),Vector2i(40,7),Vector2i(40,17),Vector2i(56,17),Vector2i(56,35),Vector2i(10,35)]
	road.clear();checkpoints.clear();stations.clear();station_timers.clear()
	for i in range(route.size()):
		var a=route[i];var b=route[(i+1)%route.size()];var dir=(b-a).sign()
		var c=a
		while true:
			for y in range(-3,4):
				for x in range(-3,4):road[c+Vector2i(x,y)]=true
			if c==b:break
			c+=dir
		var middle=Vector2(a+b)/2
		checkpoints.append({"pos":middle,"dir":Vector2(dir)})
		stations.append(a)
	for y in range(g.H):
		var row=[]
		for x in range(g.W):row.append(0 if road.has(Vector2i(x,y)) else 1)
		g.grid.append(row)
	g.SPAWNS=[]
	var finish=checkpoints[0].pos
	for i in range(8):g.SPAWNS.append(Vector2i(finish)+Vector2i(-4-int(i/4)*3,-3+(i%4)*2))
	# Breakable supplies sit beside the racing line, leaving three clear lanes.
	for i in range(route.size()):
		var a=route[i];var b=route[(i+1)%route.size()];var dir=(b-a).sign();var side=Vector2i(-dir.y,dir.x)
		for n in range(7,int(g.manhattan(a,b))-4,8):
			var c=a+dir*n+side*2
			if not checkpoints.any(func(cp):return Vector2(c).distance_to(cp.pos)<4):g.grid[c.y][c.x]=2
	g.crates.setup()
func setup():
	finish_order.clear();overtime=0;ship=null;parcels.clear();ship_wait=g.rng.randf_range(15,23)
	for p in g.players:
		p.car=false;p.race_lap=0;p.race_next=1;p.race_rank=0;p.race_points=0;p.race_finished=false;p.respawn=0.0
		p.race_before=p.visual;p.race_checkpoint=p.visual;p.car_heading=Vector2.RIGHT
		p.facing=Vector2i.RIGHT
	for c in stations+g.SPAWNS:
		if not stations.has(c):stations.append(c)
		g.drops[c]=31;station_timers[c]=18.0
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
		station_timers[c]=station_timers.get(c,18.0)-dt
		if station_timers[c]<=0:
			if not g.drops.has(c) and g.bomb_at(c)==null:g.drops[c]=31
			station_timers[c]=18.0
	for p in g.players:
		if p.race_finished:continue
		if p.dead:
			p.respawn-=dt
			if p.respawn<=0:revive(p)
			continue
		var cp=checkpoints[p.race_next]
		var before=(p.race_before-cp.pos).dot(cp.dir)
		var after=(p.visual-cp.pos).dot(cp.dir)
		var side=Vector2(-cp.dir.y,cp.dir.x)
		if p.car and before<0 and after>=0 and absf((p.visual-cp.pos).dot(side))<=3.4:
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
	g.teleport(p,chosen);p.race_before=p.visual
func vehicle_target(p,dir,dt):
	var on_track=road.has(p.cell)
	var maximum=9.0 if on_track else 3.0
	if p.slow>0:maximum*=.55
	if dir!=Vector2.ZERO:
		p.car_heading=p.car_heading.slerp(dir,1-exp(-dt*3.6)).normalized()
		var alignment=maxf(.18,p.velocity.normalized().dot(dir)) if p.velocity.length()>.5 else 1.0
		return p.car_heading*maximum*alignment
	return Vector2.ZERO
func bot_direction(p,danger):
	if p.race_finished:return Vector2i.ZERO
	if not p.car:
		var best=null;var dist=99999
		for c in g.drops:
			if g.drops[c]==31 and g.manhattan(c,p.cell)<dist:dist=g.manhattan(c,p.cell);best=c
		if best!=null:return g.route_direction(p,best,danger)
	var cp=checkpoints[p.race_next]
	# Follow the next corner before the checkpoint, preventing infield shortcuts.
	var corner=Vector2(route[p.race_next])
	var goal=cp.pos+cp.dir*2
	var previous=checkpoints[posmod(p.race_next-1,checkpoints.size())]
	if (p.visual-corner).dot(previous.dir)<-1:goal=corner
	var delta=goal-p.visual
	if danger.has(p.cell):return g.escape_direction(p,danger)
	if delta.length()<.3:return Vector2i(cp.dir)
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
func draw_ground():
	for i in range(route.size()):
		var a=Vector2(route[i]);var b=Vector2(route[(i+1)%route.size()]);var dir=(b-a).normalized()
		for n in range(2,int(a.distance_to(b))-1,4):
			var at=g.ORIGIN+(a+dir*n)*g.TILE
			g.canvas.draw_line(at,at+dir*18,Color(.91,.91,.78,.5),1.2)
	for i in range(checkpoints.size()):
		var cp=checkpoints[i];var pos=g.ORIGIN+cp.pos*g.TILE
		var side=Vector2(-cp.dir.y,cp.dir.x)
		for n in range(-3,4):
			var at=pos+side*n*g.TILE
			g.rect(at-Vector2(7,7),Vector2(14,14),Color(.8,.94,1,.12) if i else Color(.98,.95,.8,.3))
			if i==0:
				for k in range(4):g.rect(at-Vector2(7,7)+Vector2(k%2,int(k/2))*7,Vector2(7,7),Color("e7e9dd") if (k%2+int(k/2)+n)%2==0 else Color("203443"))
		g.text_at("终点" if i==0 else str(i),pos-side*4*g.TILE,9,Color("ffe3a8"))
		for sign_value in [-1,1]:
			g.hd.sprite(ART,7 if i==0 else 11,pos+side*sign_value*3.7*g.TILE-Vector2(7,12),Vector2(14,19))
	for c in stations:
		g.hd.sprite(ART,6,g.center(c)-Vector2(9,7),Vector2(18,16))
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
