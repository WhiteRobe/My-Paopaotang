extends RefCounted
var g
var timer=0.0
var cells:Array=[]
var bridge_open=true
var echoes:Array=[]
var drop_transit={}
func _init(game):g=game
func setup():
	cells.clear();echoes.clear();drop_transit.clear();timer=6 if g.rule()=="whirlpool" else 5;bridge_open=true
	var points=[Vector2i(4,4),Vector2i(g.W-5,g.H-5),Vector2i(4,g.H-5),Vector2i(g.W-5,4),Vector2i(g.W/2,g.H/2-3),Vector2i(g.W/2,g.H/2+3)]
	match g.rule():
		"mud","poison","spikes","gustpads","whirlpool","mirror","geyser","chronofield":
			for c in points:
				g.clear_patch(c);cells.append(c)
				var type={"mud":"mud","poison":"spore","spikes":"spike","gustpads":"gust","whirlpool":"vortex","mirror":"mirror","geyser":"geyser","chronofield":"clock"}[g.rule()]
				g.terrain[c]={"type":type,"turn":1 if c.x<g.W/2 else -1}
		"currents":
			for y in [4,g.H-5]:
				for x in range(2,g.W-2):
					g.grid[y][x]=0;g.terrain[Vector2i(x,y)]={"type":"flow","dir":Vector2i.RIGHT if y==4 else Vector2i.LEFT}
		"bridges":
			for x in [g.W/2-4,g.W/2-3,g.W/2-2,g.W/2+2,g.W/2+3,g.W/2+4]:
				var c=Vector2i(x,g.H/2);cells.append(c);g.grid[c.y][c.x]=0;g.terrain[c]={"type":"bridge"}
		"turrets":cells=[Vector2i(0,g.H/2-5),Vector2i(g.W-1,g.H/2+5),Vector2i(g.W/2-7,0),Vector2i(g.W/2+7,g.H-1)]
		"blackout":
			for c in points:g.clear_patch(c);g.terrain[c]={"type":"lamp"};cells.append(c)
func update(dt):
	update_transport(dt)
	if g.arena<20:return
	timer-=dt
	for echo in echoes.duplicate():
		echo.wait-=dt
		if echo.wait<=0:
			for c in echo.cells:
				if g.inside(c) and g.grid[c.y][c.x] not in [1,3]:g.register_blast({"cell":c,"time":.4,"owner":echo.owner,"element":echo.element,"pulse_only":true})
			echoes.erase(echo);g.sound("splash");g.shake=1.3
	if g.rule()=="chronofield":
		for b in g.bombs:
			if cells.any(func(c):return g.manhattan(c,b.cell)<=2):b.timer+=dt*.55
	for p in g.players:
		if p.dead or not g.terrain.has(p.cell):continue
		var type=g.terrain[p.cell].type
		if type=="mud":p.slow=maxf(p.slow,.25)
		elif type=="clock":p.dash=maxf(p.dash,.3)
		elif type=="gust" and p.flow<=0:
			p.dash=maxf(p.dash,2.4);p.flow=3;g.burst(g.center(p.cell),Color("d3ffe0"),7)
	if timer>0:return
	match g.rule():
		"poison","spikes","whirlpool":
			timer=8 if g.rule()=="poison" else 6
			var marked:Array=[]
			for c in cells:
				if g.grid[c.y][c.x]==3:continue
				marked.append(c)
				if g.rule()=="whirlpool":
					for y in range(-3,4):
						for x in range(-3,4):
							var at=c+Vector2i(x,y)
							if abs(x)+abs(y)<=3 and g.inside(at) and not marked.has(at):marked.append(at)
				elif g.rule()!="spikes":
					for d in g.DIRS:marked.append(c+d)
			g.hazards.append({"cells":marked,"wait":1.5,"type":g.rule()})
		"bridges":
			timer=5;bridge_open=not bridge_open
			for c in cells:
				if g.grid[c.y][c.x]==3:continue
				if bridge_open:g.grid[c.y][c.x]=0
				elif g.occupied(c)==null and g.bomb_at(c)==null:g.grid[c.y][c.x]=1
			g.announce("浮桥展开！" if bridge_open else "浮桥收起，绕行两侧！")
		"turrets":
			timer=6
			var marked:Array=[]
			var column=int(g.round_time/6)%2==0
			var alive=g.players.filter(func(p):return not p.dead)
			var target=alive[g.rng.randi_range(0,alive.size()-1)].cell if not alive.is_empty() else Vector2i(10,7)
			if column:
				for y in range(1,g.H-1):marked.append(Vector2i(target.x,y))
			else:
				for x in range(1,g.W-1):marked.append(Vector2i(x,target.y))
			g.hazards.append({"cells":marked,"wait":1.4,"type":"cannon"})
		"geyser":
			timer=5
			for b in g.bombs:
				if not cells.any(func(c):return g.manhattan(c,b.cell)<=1):continue
				var dest=b.cell+g.DIRS[int(g.round_time/5)%4]*2
				if g.bubble_can_move(dest):g.burst(g.center(b.cell),Color("b1ebef"),12);b.cell=dest;b.slide=Vector2i.ZERO
		"blackout":timer=12;g.announce("灯塔熄灭！留心危险标记。")
		_:timer=8
func on_explode(b,water_cells):
	if g.rule()=="echo":echoes.append({"cells":water_cells.duplicate(),"owner":b.owner,"element":b.get("element",0),"wait":.9})
func draw():
	if g.arena<20:return
	for echo in echoes:
		for c in echo.cells:
			g.canvas.draw_rect(Rect2(g.ORIGIN+Vector2(c)*g.TILE+Vector2(2,2),Vector2(14,14)),Color("adc9ff"),false,1)
func draw_turret(c):
	var pos=g.center(c)
	var rotation=PI/2 if c.x==0 else -PI/2 if c.x==g.W-1 else PI if c.y==0 else 0.0
	g.canvas.draw_set_transform(pos,rotation)
	g.hd.sprite("maps/mechanisms/mechanisms-v472.png",8,Vector2(-8,-8),Vector2(16,16))
	g.canvas.draw_set_transform(Vector2(sin(g.elapsed*83),cos(g.elapsed*71))*g.shake)

func draw_overlay():
	if g.rule()!="blackout" or fmod(g.round_time,12)<8:return
	for hazard in g.hazards:
		for c in hazard.cells:g.canvas.draw_arc(g.center(c),6,0,TAU,16,Color("ffdd9d"),1)

func pull_vortex():
	for b in g.bombs:
		if b.slide!=Vector2i.ZERO:continue
		var nearest=null
		var distance=4
		for c in cells:
			var candidate=g.manhattan(c,b.cell)
			if candidate>0 and candidate<distance and g.bubble_fx.clear_path(c,b.cell,3):nearest=c;distance=candidate
		if nearest==null:continue
		var d=Vector2i(signi(nearest.x-b.cell.x),0) if nearest.x!=b.cell.x else Vector2i(0,signi(nearest.y-b.cell.y))
		if not g.bubble_can_move(b.cell+d) or not g.can_cross(b.cell,b.cell+d):continue
		g.burst(g.center(b.cell),Color("a7e7f4"),4)
		b.cell+=d;b.slide=Vector2i.ZERO;b.step=0

# Keep grid occupancy authoritative, interpolating only the artwork between cells.
func transport_free(c,from,for_drop=false):
	if not g.inside(c) or g.grid[c.y][c.x]!=0 or not g.can_cross(from,c):return false
	if g.bomb_at(c)!=null:return false
	if not for_drop and g.occupied(c)!=null:return false
	if for_drop and g.drops.has(c):return false
	for b in g.bombs:
		if b.get("belt_to",b.cell)==c:return false
	for move in drop_transit.values():
		if move.to==c:return false
	return true

func update_transport(dt):
	for c in drop_transit.keys():
		var move=drop_transit[c]
		if not g.drops.has(c) or g.drops[c]!=move.kind or g.grid[c.y][c.x]!=0:
			drop_transit.erase(c);continue
		move.progress=minf(1,move.progress+dt/.48)
		if move.progress>=1:
			var target=move.to
			# Its own reservation must not prevent arrival.
			drop_transit.erase(c)
			if transport_free(target,c,true):g.drops.erase(c);g.drops[target]=move.kind
	for c in g.drops.keys():
		if drop_transit.has(c) or not g.terrain.has(c) or g.terrain[c].type!="flow":continue
		var target=c+g.terrain[c].dir
		if transport_free(target,c,true):drop_transit[c]={"to":target,"kind":g.drops[c],"progress":0.0}
	for b in g.bombs:
		if b.slide!=Vector2i.ZERO or (b.has("belt_from") and b.belt_from!=b.cell):
			b.erase("belt_to");b.erase("belt_progress");b.erase("belt_from");continue
		if b.has("belt_to"):
			b.belt_progress=minf(1,b.belt_progress+dt/.48)
			if b.belt_progress>=1:
				var previous=b.cell;var target=b.belt_to
				b.erase("belt_to");b.erase("belt_progress");b.erase("belt_from")
				if transport_free(target,previous):
					b.cell=target
					# Everyone touching the moving bubble can step clear of it.
					for p in g.players:
						if absf(p.visual.x-target.x)<.76 and absf(p.visual.y-target.y)<.76 and not p.bubble_pass_cells.has(target):p.bubble_pass_cells.append(target)
		if not b.has("belt_to") and g.terrain.has(b.cell) and g.terrain[b.cell].type=="flow":
			var target=b.cell+g.terrain[b.cell].dir
			if transport_free(target,b.cell):b.belt_from=b.cell;b.belt_to=target;b.belt_progress=0.0

func bubble_position(b):
	return g.center(b.cell).lerp(g.center(b.belt_to),b.belt_progress) if b.has("belt_to") else g.center(b.cell)

func drop_position(c):
	return g.center(c).lerp(g.center(drop_transit[c].to),drop_transit[c].progress) if drop_transit.has(c) else g.center(c)
