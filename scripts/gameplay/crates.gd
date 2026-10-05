extends RefCounted
var g
var boxes:Array=[]
var by_cell:Dictionary={}
func _init(game):g=game
func footprint(b,anchor=null):
	var result:Array=[]
	var pos=b.cell if anchor==null else anchor
	for y in range(b.size.y):
		for x in range(b.size.x):result.append(pos+Vector2i(x,y))
	return result
func at(c):
	var b=by_cell.get(c)
	return b if b!=null and not b.dead and g.inside(c) and g.grid[c.y][c.x]==2 else null
func rebuild():
	by_cell.clear()
	for b in boxes:
		if not b.dead:
			for c in footprint(b):by_cell[c]=b
func add(c,kind,size=Vector2i.ONE):
	var hp={"normal":1,"push":1,"armor":2,"vault":8}[kind]
	var b={"cell":c,"visual":Vector2(c),"from":Vector2(c),"move":1.0,"size":size,"kind":kind,"hp":hp,"max_hp":hp,"flash":0.0,"dead":false,"serial":boxes.size()}
	for tile in footprint(b):g.grid[tile.y][tile.x]=2
	boxes.append(b)
	return b
func setup():
	boxes.clear();by_cell.clear()
	for y in range(1,g.H-1):
		for x in range(1,g.W-1):
			var c=Vector2i(x,y)
			if g.grid[y][x]!=2:continue
			var mirrored=c if y<g.H/2 or (y==g.H/2 and x<=g.W/2) else Vector2i(g.W-1-x,g.H-1-y)
			var seed_value=(mirrored.x*13+mirrored.y*37+g.arena*7)%10
			var kind="push" if seed_value<2 else ("armor" if seed_value<4 else "normal")
			if g.gold_boxes.has(c) or g.vine_cells.has(c):kind="normal"
			add(c,kind)
	# Paired vaults keep opposing battle spawns equally far from the reward.
	var vault_positions=[Vector2i(g.W/2-5,g.H/2-3),Vector2i(g.W/2+4,g.H/2+2)] if g.mode!=3 else [Vector2i(16,9) if (g.adventure_stage%4)==0 else Vector2i(7,3)]
	for vault_pos in vault_positions:
		for b in boxes:
			if footprint(b).any(func(c):return Rect2i(vault_pos,Vector2i(2,2)).has_point(c)):b.dead=true
		add(vault_pos,"vault",Vector2i(2,2))

	rebuild()
func prune():
	for b in boxes:
		if b.dead:continue
		if footprint(b).any(func(c):return g.grid[c.y][c.x]!=2):
			b.dead=true
			for c in footprint(b):
				if g.grid[c.y][c.x]==2:g.grid[c.y][c.x]=0
	rebuild()
func update(dt):
	prune()
	for b in boxes:
		b.flash=maxf(0,b.flash-dt);b.move=minf(1,b.move+dt/.14);b.visual=b.from.lerp(Vector2(b.cell),b.move)
func try_push(c,dir,p):
	var b=at(c)
	if b==null or b.kind!="push":return false
	var dest=b.cell+dir
	for tile in footprint(b,dest):
		if not g.inside(tile) or g.grid[tile.y][tile.x]!=0 or g.bomb_at(tile)!=null or g.occupied(tile,p.id)!=null:return false
	for tile in footprint(b):g.grid[tile.y][tile.x]=0
	b.from=b.visual;b.cell=dest;b.move=0
	for tile in footprint(b):g.grid[tile.y][tile.x]=2
	rebuild();g.burst(g.center(c),Color("d4b28e"),4);g.sound("item")
	return true
func damage(c,owner=-1,hit_boxes=null):
	var b=at(c)
	if b==null:
		g.grid[c.y][c.x]=0
		if owner>=0 and owner<g.players.size() and g.players[owner].get("control",owner)==0:g.stat("crates")
		if g.gold_boxes.has(c):g.drops[c]=19;g.gold_boxes.erase(c)
		elif g.rng.randf()<g.loot_chance(.76):g.drops[c]=g.random_drop()
		return
	if hit_boxes!=null:
		if hit_boxes.has(b.serial):return
		hit_boxes[b.serial]=true
	b.hp-=1;b.flash=.2;g.burst(g.center(c),Color("e8c396"),5)
	if b.hp>0:return
	b.dead=true
	for tile in footprint(b):
		g.grid[tile.y][tile.x]=0
		if g.gold_boxes.has(tile):g.gold_boxes.erase(tile);g.drops[tile]=19
	if owner>=0 and owner<g.players.size() and g.players[owner].get("control",owner)==0:g.stat("crates")
	if b.kind=="vault":
		var locations=footprint(b)+[b.cell+Vector2i(-1,0),b.cell+Vector2i(2,1),b.cell+Vector2i(0,2),b.cell+Vector2i(1,-1)]
		var rewards=[15,g.rng.randi_range(20,25),7,16,4,5]
		if g.mode==3:rewards.append(28)
		var index=0
		for tile in locations:
			if index>=rewards.size():break
			if not g.inside(tile) or g.grid[tile.y][tile.x]!=0 or g.bomb_at(tile)!=null:continue
			g.drops[tile]=rewards[index];index+=1
		g.announce("宝库开启：坐骑、成长、属性核心！");g.world_fx.impact(g.center(b.cell)+Vector2(9,9),5,60);g.shake=2
	elif not g.drops.has(c) and g.rng.randf()<g.loot_chance(.95 if b.kind=="armor" else .76):g.drops[c]=g.random_drop()
	rebuild()
func draw_box(b):
	var theme=g.Catalog.MAPS[g.arena].theme
	if b.dead:return
	var state=0 if b.hp==b.max_hp else (1 if b.hp>b.max_hp/3 else 2)
	var pos=g.ORIGIN+b.visual*g.TILE
	if b.kind=="vault":
		g.hd.theme_sprite(theme,6 if state==0 else 7,pos,Vector2.ONE*g.TILE*2,Color.WHITE,false)
		if b.hp<b.max_hp:g.health_bar(pos+Vector2(3,g.TILE*2-3),b.hp,b.max_hp,g.TILE*2-6,2)
		if int(g.elapsed*3)%3==0:g.rect(pos+Vector2(30,5),Vector2(2,2),Color("fff6ce"))
	else:
		var kind={"normal":0,"push":1,"armor":2}[b.kind]
		g.hd.theme_sprite(theme,3+kind,pos,Vector2.ONE*g.TILE,Color.WHITE,false)
		if state>0:
			g.canvas.draw_polyline(PackedVector2Array([pos+Vector2(7,3),pos+Vector2(9,7),pos+Vector2(6,11),pos+Vector2(10,16)]),Color("584136"),.6)
			if state==2:g.canvas.draw_line(pos+Vector2(9,7),pos+Vector2(14,5),Color("584136"),.6)
		if b.hp<b.max_hp:g.health_bar(pos+Vector2(5 if b.kind=="armor" else 7,13),b.hp,b.max_hp,7 if b.kind=="armor" else 3,2)
		if g.gold_boxes.has(b.cell):g.item_icon(pos+Vector2(4,2),19,12)
	if b.flash>0:g.canvas.draw_rect(Rect2(pos,Vector2(b.size)*g.TILE),Color(1,.93,.75,b.flash*1.5))
