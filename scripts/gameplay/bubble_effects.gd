extends RefCounted
const STYLES=[
	{"name":"清水","color":"83e6ff","fx":0},
	{"name":"冰晶","color":"a7d8ff","fx":1},
	{"name":"烈焰","color":"ffa278","fx":2},
	{"name":"雷鸣","color":"cfb2ff","fx":3},
	{"name":"藤蔓","color":"b0e7a3","fx":4},
	{"name":"净化","color":"ffbdd7","fx":5},
	{"name":"穿透","color":"fff0aa","fx":0}]
var g
var vines:Array=[]
func _init(game):g=game
func infuse(p,element,duration=20.0):
	p.element=element;p.element_time=duration
	for b in g.bombs:
		if b.owner==p.id:b.element=element;g.world_fx.impact(g.center(b.cell),STYLES[element].fx,28)
	g.world_fx.impact(g.center(p.cell),STYLES[element].fx,34)
	g.announce(STYLES[element].name+"泡泡已充能！")
func update(dt):
	for p in g.players:
		p.element_time=maxf(0,p.element_time-dt)
		if p.element_time<=0:p.element=0
	for field in vines:field.time-=dt
	vines=vines.filter(func(field):return field.time>0)
	for p in g.players:
		if p.dead:continue
		for field in vines:
			if field.cell==p.cell and hostile(p,field.owner):p.slow=maxf(p.slow,.3)
		for f in g.blasts:
			if not f.get("pulse_only",false) and f.get("element",0)==5 and f.cell==p.cell and f.owner>=0 and (f.owner==p.id or g.players[f.owner].team==p.team):
				if p.trap>0:g.release_player(p,f.owner)
				p.grace=maxf(p.grace,.5);p.shield=maxf(p.shield,1.2)
func hostile(p,owner):
	if owner<0:return true
	return g.players[owner].team!=p.team
# Short flood search blocks abilities through solid walls, crates and abyss.
func clear_path(source,target,reach):
	if g.manhattan(source,target)>reach:return false
	var queue=[{"cell":source,"steps":0}]
	var seen={source:true}
	while not queue.is_empty():
		var node=queue.pop_front()
		if node.cell==target:return true
		if node.steps>=reach:continue
		for direction in g.DIRS:
			var c=node.cell+direction
			if seen.has(c) or not g.inside(c) or g.grid[c.y][c.x]!=0 or not g.can_cross(node.cell,c):continue
			seen[c]=true;queue.append({"cell":c,"steps":node.steps+1})
	return false

func affect_player(p,f):
	var element=f.get("element",0)
	if element==5 and f.owner>=0 and (f.owner==p.id or g.players[f.owner].team==p.team):
		if p.trap>0:g.release_player(p,f.owner)
		p.grace=maxf(p.grace,.5);p.shield=maxf(p.shield,1.2);return
	if p.dead or p.trap>0 or p.grace>0:return
	if p.shield>0 or p.mount>0:
		g.damage_player(p,f.owner);return
	if element==1:p.freeze=maxf(p.freeze,1.1)
	elif element==3:p.slow=maxf(p.slow,1.5)
	elif element==4 and hostile(p,f.owner):p.slow=maxf(p.slow,3.0)
	g.damage_player(p,f.owner)
func affect_enemy(e,f):
	var element=f.get("element",0)
	if element==1:e.freeze=maxf(e.freeze,.65 if e.boss else 1.5)
	elif element==4:e.slow=maxf(e.get("slow",0),1.2 if e.boss else 3.0)
	g.adventure.hit_enemy(e,maxi(1,f.get("damage",1))+(1 if element==2 else 0),f.get("pulse_only",false),f.owner)
func extra_cells(b,cells):
	var element=b.get("element",0)
	if element==2:
		for y in range(-1,2):
			for x in range(-1,2):
				var c=b.cell+Vector2i(x,y)
				if not g.inside(c) or g.grid[c.y][c.x] in [1,3] or cells.has(c):continue
				if x!=0 and y!=0 and g.grid[b.cell.y][c.x] in [1,2,3] and g.grid[c.y][b.cell.x] in [1,2,3]:continue
				if not clear_path(b.cell,c,2):continue
				cells.append(c)
	elif element==3:
		var candidates:Array=[]
		for p in g.players:
			if not p.dead and p.id!=b.owner and g.players[b.owner].team!=p.team:candidates.append(p.cell)
		if g.mode==3:
			for e in g.adventure.enemies:
				if not e.dead:candidates.append(e.cell)
		for other in g.bombs:
			if other!=b:candidates.append(other.cell)
		var original=cells.duplicate();var links=0
		for c in candidates:
			if links>=3:break
			if not cells.has(c) and original.any(func(source):return clear_path(source,c,2)):cells.append(c);links+=1
	return cells
func on_explode(b,cells):
	var element=b.get("element",0)
	if element==4:
		for c in cells:
			if g.grid[c.y][c.x]==0:vines.append({"cell":c,"time":4.0,"owner":b.owner})
	# The center splash uses the same animation atlas as the connected jets.
func draw_fields():
	for field in vines:
		if g.grid[field.cell.y][field.cell.x]!=0:continue
		var age=4.0-field.time
		var frame=0 if age<.25 else 1 if field.time>1.3 else 2 if field.time>.4 else 3
		var friendly=field.owner>=0 and g.players[field.owner].team==g.primary_player().team
		var tint=Color(1,1,1,minf(.38 if friendly else 1.0,field.time/.4))
		g.hd.sprite("effects/water-vines-v473.png",frame*4+3,g.center(field.cell)-Vector2(8,7),Vector2(16,14),tint)
