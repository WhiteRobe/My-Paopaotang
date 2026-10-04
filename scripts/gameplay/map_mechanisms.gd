extends RefCounted
var g
var timer=0.0
var cells:Array=[]
var bridge_open=true
var echoes:Array=[]
func _init(game):g=game
func setup():
	cells.clear();echoes.clear();timer=5;bridge_open=true
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
		"turrets":cells=[Vector2i(0,4),Vector2i(g.W-1,10),Vector2i(6,0),Vector2i(14,g.H-1)]
		"blackout":
			for c in points:g.clear_patch(c);g.terrain[c]={"type":"lamp"};cells.append(c)
func update(dt):
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
	if g.rule()=="whirlpool":
		for b in g.bombs:
			if b.slide!=Vector2i.ZERO or b.timer<.8:continue
			for c in cells:
				if g.manhattan(b.cell,c)<=3 and g.manhattan(b.cell,c)>0:
					var d=Vector2i(signi(c.x-b.cell.x),0) if c.x!=b.cell.x else Vector2i(0,signi(c.y-b.cell.y))
					if g.bubble_can_move(b.cell+d):b.slide=d;b.step=.22
					break
	if timer>0:return
	match g.rule():
		"poison","spikes","whirlpool":
			timer=8 if g.rule()=="poison" else 6
			var marked:Array=[]
			for c in cells:
				if g.grid[c.y][c.x]==3:continue
				marked.append(c)
				if g.rule()!="spikes":
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
	g.hd.sprite("mechanisms-v472.png",8,Vector2(-8,-8),Vector2(16,16))
	g.canvas.draw_set_transform(Vector2(sin(g.elapsed*83),cos(g.elapsed*71))*g.shake)

func draw_overlay():
	if g.rule()!="blackout" or fmod(g.round_time,12)<8:return
	for hazard in g.hazards:
		for c in hazard.cells:g.canvas.draw_arc(g.center(c),6,0,TAU,16,Color("ffdd9d"),1)
