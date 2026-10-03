extends RefCounted
var g
var timer=0.0
var cells:Array=[]
var bridge_open=true
var echoes:Array=[]
func _init(game):g=game
func setup():
	cells.clear();echoes.clear();timer=5;bridge_open=true
	var points=[Vector2i(4,4),Vector2i(16,10),Vector2i(4,10),Vector2i(16,4),Vector2i(10,5),Vector2i(10,9)]
	match g.rule():
		"mud","poison","spikes","gustpads","whirlpool","mirror","geyser","chronofield":
			for c in points:
				g.clear_patch(c);cells.append(c)
				var type={"mud":"mud","poison":"spore","spikes":"spike","gustpads":"gust","whirlpool":"vortex","mirror":"mirror","geyser":"geyser","chronofield":"clock"}[g.rule()]
				g.terrain[c]={"type":type,"turn":1 if c.x<10 else -1}
		"currents":
			for y in [4,10]:
				for x in range(2,g.W-2):
					g.grid[y][x]=0;g.terrain[Vector2i(x,y)]={"type":"flow","dir":Vector2i.RIGHT if y==4 else Vector2i.LEFT}
		"bridges":
			for x in [5,6,7,13,14,15]:
				var c=Vector2i(x,7);cells.append(c);g.grid[c.y][c.x]=0;g.terrain[c]={"type":"bridge"}
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
				if g.inside(c) and g.grid[c.y][c.x] not in [1,3]:g.blasts.append({"cell":c,"time":.4,"owner":echo.owner,"element":echo.element})
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
			g.draw_rect(Rect2(g.ORIGIN+Vector2(c)*g.TILE+Vector2(2,2),Vector2(14,14)),Color("adc9ff"),false,1)
	for c in cells:
		var pos=g.center(c)
		if g.inside(c) and g.grid[c.y][c.x]==3:continue
		match g.rule():
			"geyser":
				g.draw_circle(pos,7,Color("568ea9"));g.draw_arc(pos,5,0,TAU,16,Color("b8eff0"),2)
				if timer<1.5:g.draw_line(pos+Vector2(-3,2),pos+Vector2(-3,-10),Color("c6f6ef"),2);g.draw_line(pos+Vector2(3,2),pos+Vector2(3,-7),Color("c6f6ef"),2)
			"chronofield":
				g.draw_circle(pos,7,Color("656c9c"));g.draw_arc(pos,6,0,TAU,20,Color("e3dfaa"),1);g.draw_line(pos,pos+Vector2(sin(g.elapsed)*4,-cos(g.elapsed)*4),Color("fff1a8"),1)
			"mud":
				g.draw_circle(pos,7,Color("82705d"))
				g.draw_arc(pos,5,.2,2.8,15,Color("b1a27d"),1)
			"poison":
				g.rect(pos+Vector2(-2,-1),Vector2(4,8),Color("c9b68b"));g.draw_circle(pos+Vector2(0,-3),6,Color("b984c5"));g.draw_circle(pos+Vector2(-2,-5),1.5,Color("e8e2b4"))
			"spikes":
				for x in [-5,0,5]:g.draw_colored_polygon(PackedVector2Array([pos+Vector2(x-2,4),pos+Vector2(x,-4),pos+Vector2(x+2,4)]),Color("c9cbcd"))
			"gustpads":
				g.draw_circle(pos,7,Color("6d899b"));g.draw_arc(pos,5,g.elapsed*3,g.elapsed*3+4,20,Color("e5ebc1"),2)
			"mirror":
				g.draw_colored_polygon(PackedVector2Array([pos+Vector2(0,-7),pos+Vector2(6,0),pos+Vector2(0,7),pos+Vector2(-6,0)]),Color("9bdfdf"))
				g.draw_line(pos+Vector2(-4,4),pos+Vector2(4,-4),Color("f3ffe2"),2)
			"whirlpool":
				for r in [3,6,8]:g.draw_arc(pos,r,g.elapsed*2+r,g.elapsed*2+r+4.5,20,Color("b5d5ee"),1)
			"bridges":
				g.rect(pos-Vector2(8,8),Vector2(16,16),Color("b4a482") if bridge_open else Color("303b54"))
				for y in [-6,-2,2,6]:g.draw_line(pos+Vector2(-7,y),pos+Vector2(7,y),Color("ecdbc0") if bridge_open else Color("695d73"),1)
			"blackout":
				g.rect(pos+Vector2(-2,-4),Vector2(4,13),Color("bba1c4"));g.rect(pos+Vector2(-5,-9),Vector2(10,7),Color("f2e8a4") if fmod(g.round_time,12)<8 else Color("676080"))
			"turrets":
				g.draw_circle(pos,7,Color("786e87"));g.rect(pos+Vector2(-3,-5),Vector2(6,10),Color("e2bb8d"));g.draw_circle(pos,2,Color("25334a"))
func draw_overlay():
	if g.rule()!="blackout" or fmod(g.round_time,12)<8:return
	for y in range(1,g.H-1):
		for x in range(1,g.W-1):
			var c=Vector2i(x,y);var visible=false
			for p in g.players:
				if not p.dead and g.manhattan(c,p.cell)<=3:visible=true;break
			if not visible:g.rect(g.ORIGIN+Vector2(c)*g.TILE,Vector2(g.TILE,g.TILE),Color(.04,.03,.1,.72))
	for hazard in g.hazards:
		for c in hazard.cells:g.draw_arc(g.center(c),6,0,TAU,16,Color("ffdd9d"),1)
