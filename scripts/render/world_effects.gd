extends RefCounted
var g
var events:Array=[]
var links:Array=[]
var footsteps:Array=[]
func _init(game):g=game
func impact(pos,kind=0,size=30):
	events.append({"pos":pos,"kind":kind,"life":.48,"size":size})
	if events.size()>90:events.pop_front()
func footstep(pos,direction,mounted=false):
	footsteps.append({"pos":pos,"dir":Vector2(direction),"life":.35,"mounted":mounted})
	if footsteps.size()>40:footsteps.pop_front()
func chain(from,to):links.append({"from":from,"to":to,"life":.3})
func update(dt):
	for foot in footsteps:foot.life-=dt
	footsteps=footsteps.filter(func(foot):return foot.life>0)
	for link in links:link.life-=dt
	links=links.filter(func(link):return link.life>0)
	for event in events:event.life-=dt
	events=events.filter(func(event):return event.life>0)
func design_board(pve=false):
	add_permanent_cover(pve)
	# Boss courts use perimeter cover, leaving the central dodge lane clear.
	if pve and g.adventure.stage.mission=="boss":
		for c in [Vector2i(6,7),Vector2i(7,7),Vector2i(14,8),Vector2i(14,9),Vector2i(10,11),Vector2i(11,11)]:
			if not design_reserved(c,true):g.grid[c.y][c.x]=2
	# Add paired cover islands to cleared rooms; task routes and entrances stay open.
	for y in range(4,g.H-4,5):
		for x in range(4,g.W-4,5):
			var clear=true
			for dy in range(-2,3):
				for dx in range(-2,3):
					var c=Vector2i(x+dx,y+dy)
					if not g.inside(c) or g.grid[c.y][c.x]!=0:clear=false
			if not clear:continue
			for offset in [Vector2i(-1,-1),Vector2i(0,-1),Vector2i(1,1)]:
				var c=Vector2i(x,y)+offset
				if design_reserved(c,pve):continue
				if g.mode in [1,2] and g.battle_options.density==1 and offset!=Vector2i(-1,-1):continue
				if not pve:
					var mirror=Vector2i(g.W-1-c.x,g.H-1-c.y)
					if design_reserved(mirror,false):continue
					g.grid[mirror.y][mirror.x]=2
				g.grid[c.y][c.x]=2
func design_reserved(c,pve,allow_crate=false):
	if not g.inside(c) or g.grid[c.y][c.x] not in ([0,2] if allow_crate else [0]) or g.terrain.has(c):return true
	if g.gold_boxes.has(c) or g.vine_cells.has(c):return true
	if c.x==g.W/2 or c.y==g.H/2:return true
	for spawn in g.SPAWNS:
		if g.manhattan(c,spawn)<=3:return true
	if pve:
		if g.drops.has(c):return true
		for obj in g.adventure.objects+g.adventure.bonus_objects:
			if c.x==obj.cell.x or g.manhattan(c,obj.cell)<=2:return true
		for enemy in g.adventure.enemies:
			if g.manhattan(c,enemy.cell)<(4 if enemy.boss else 2):return true
		if g.manhattan(c,g.adventure.checkpoint)<=3:return true
	return false
func add_permanent_cover(pve):
	# Short piers and paired pillars remain useful after the crates are destroyed.
	for y in range(4,g.H-4,6):
		for x in range(4+(3 if (y/6)%2 else 0),g.W-4,6):
			var cells=[Vector2i(x,y),Vector2i(x,y)+(Vector2i.RIGHT if (g.arena+x+y)%2 else Vector2i.DOWN)]
			if not pve:
				for c in cells.duplicate():
					var mirror=Vector2i(g.W-1-c.x,g.H-1-c.y)
					if not cells.has(mirror):cells.append(mirror)
			if cells.any(func(c):return design_reserved(c,pve,true)):continue
			var crowded=false
			for c in cells:
				var neighbors=0
				for d in g.DIRS:
					if g.grid[c.y+d.y][c.x+d.x]==1:neighbors+=1
				if neighbors>1:crowded=true
			if crowded:continue
			var previous=[]
			var entrances=[]
			for c in cells:
				previous.append(g.grid[c.y][c.x]);g.grid[c.y][c.x]=1
			for c in cells:
				for d in g.DIRS:
					var next=c+d
					if g.inside(next) and g.grid[next.y][next.x] in [0,2] and not entrances.has(next):entrances.append(next)
			# Include breakable crates in the route check: no permanent sealed pockets.
			var seen={};var queue=[]
			if not entrances.is_empty():queue.append(entrances[0]);seen[entrances[0]]=true
			var head=0
			while head<queue.size():
				var c=queue[head];head+=1
				for d in g.DIRS:
					var next=c+d
					if g.inside(next) and g.grid[next.y][next.x] in [0,2] and not seen.has(next):seen[next]=true;queue.append(next)
			if entrances.any(func(c):return not seen.has(c)):
				for i in range(cells.size()):g.grid[cells[i].y][cells[i].x]=previous[i]
func draw_ground():
	var theme=g.Catalog.MAPS[g.arena].theme
	var paving=[1,0,0,3,2,2,3,3,0,3,0,3,3,0][theme]
	var feature=[4,6,5,5,5,4,7,5,6,5,7,4,5,5][theme]
	# Broad inlaid patches mark courtyards and routes without competing with actors.
	for y in range(3,g.H-2,7):
		for x in range(3,g.W-2,7):
			var anchor=Vector2i(x,y)
			if absf(x-g.camera.x)>g.VIEW_SIZE.x+3 or absf(y-g.camera.y)>g.VIEW_SIZE.y+3:continue
			for dy in range(-1,2):
				for dx in range(-1,2):
					var c=anchor+Vector2i(dx,dy)
					if not g.inside(c) or g.grid[c.y][c.x] in [1,3] or g.terrain.has(c):continue
					g.hd.sprite("maps/decorations/site-details-v478.png",paving,g.center(c)-Vector2.ONE*8,Vector2.ONE*16,Color(1,1,1,.25),false)
			if g.inside(anchor) and g.grid[y][x]==0 and not g.terrain.has(anchor):
				g.hd.sprite("maps/decorations/site-details-v478.png",feature,g.center(anchor)-Vector2.ONE*7,Vector2.ONE*14,Color(1,1,1,.36))
func draw_visitors(theme):
	var origin=g.ORIGIN+g.camera*g.TILE
	var width=g.VIEW_SIZE.x*g.TILE
	var height=g.VIEW_SIZE.y*g.TILE
	if theme in [13,0,11,12,1,8,10]:
		var cycle=18.0 if theme==13 else 26.0
		var t=fposmod(g.elapsed+g.arena*.37,cycle)
		if t<10:
			var pos=origin+Vector2(-22+(width+44)*t/10,24+sin(t*.9)*8)
			if theme==13:
				g.hd.ambient_frame("maps/decorations/bat-flight-v478.png",posmod(int(g.elapsed*20),16),pos,Vector2(22,14),Color(1,1,1,.82))
			else:
				var row=0 if theme in [0,11,12] else 1 if theme==1 else 2 if theme==8 else 3
				g.hd.ambient_frame("maps/decorations/habitat-flight-v478.png",row*8+posmod(int(g.elapsed*[12,10,18,10][row]),8),pos,Vector2(20,12),Color(1,1,1,.65))
	for n in range(3):
		var pos=origin+Vector2(35+n*width*.32,20+height*.22*(n+1))
		var age=fposmod(g.elapsed*.4+n*.37,1)
		if theme in [5,9,13]:
			# Thin rising steam, ancient dust, or falling cave droplets.
			if theme==13:
				var fall=fposmod(g.elapsed*.65+n*.41,1)
				var at=pos+Vector2(0,fall*18)
				g.canvas.draw_line(at-Vector2(0,2),at,Color(.5,.76,.82,.35*(1-fall)),1)
				if fall>.85:g.canvas.draw_arc(pos+Vector2(0,18),1+(fall-.85)*12,0,TAU,16,Color(.5,.76,.82,(1-fall)*2),.5)
			else:
				for k in range(3):
					var at=pos+Vector2(sin(age*4+n+k)*3,-age*20-k*3)
					g.canvas.draw_arc(at,1+age*3,PI*.2,PI*.8,10,Color(.76,.85,.83,(1-age)*.18),.6)
		elif theme in [6,10]:
			g.canvas.draw_arc(pos+Vector2(sin(age*5)*2,-age*26),1+age*3,0,TAU,18,Color(.85,.94,.97,(1-age)*.22),.6)
		elif theme==7 and fposmod(g.elapsed+n*6,23)<1:
			var at=pos+Vector2(age*70,-age*20)
			g.canvas.draw_line(at-Vector2(12,-4),at,Color(.82,.80,1,.35),1)
			g.canvas.draw_circle(at,.7,Color(.94,.87,1,.7))
func draw_air():
	var theme=g.Catalog.MAPS[g.arena].theme
	draw_visitors(theme)
	var color=[Color("c4efdf"),Color("c6dba0"),Color("e5f7ff"),Color("eed0aa"),Color("ffba83"),Color("bddbdd"),Color("ffe0ed"),Color("dfd6ff"),Color("d3edaa"),Color("decfb7"),Color("b9eeeb"),Color("e6f3e9"),Color("d1b6ef"),Color("a4c7d1")][theme]
	for n in range(8):
		var pos=g.ORIGIN+Vector2(fposmod(n*53+g.elapsed*(3 if theme in [7,8,12] else 9),g.VIEW_SIZE.x*g.TILE),fposmod(n*29+g.elapsed*(8 if theme==2 else -4),g.VIEW_SIZE.y*g.TILE))+g.camera*g.TILE
		var alpha=.12+.12*sin(g.elapsed*2+n)
		if theme in [0,10]:
			g.canvas.draw_arc(pos,1.5+(n%3)*.5,0,TAU,10,Color(color,alpha),1)
		elif theme in [1,8]:
			g.rect(pos,Vector2(2,1),Color(color,alpha));g.rect(pos+Vector2(1,-1),Vector2(1,3),Color(color,alpha))
		elif theme in [7,12]:
			g.canvas.draw_line(pos-Vector2(2,0),pos+Vector2(2,0),Color(color,alpha),1);g.canvas.draw_line(pos-Vector2(0,2),pos+Vector2(0,2),Color(color,alpha),1)
		elif theme==2:
			g.canvas.draw_line(pos-Vector2(1,2),pos+Vector2(1,1),Color(color,alpha+.1),.7)
		elif theme==3:
			g.canvas.draw_arc(pos,3+n%3,PI*.08,PI*.35,12,Color(color,alpha*.65),.7)
		elif theme==4:
			g.canvas.draw_circle(pos,.65,Color(color,alpha+.12))
			g.canvas.draw_line(pos,pos+Vector2(-1,3),Color(color,alpha*.5),.7)
		else:g.canvas.draw_circle(pos,.5,Color(color,alpha))
	for foot in footsteps:
		var age=1-foot.life/.35
		for side in [-1,1]:
			var at=foot.pos-foot.dir*age*4+Vector2(-foot.dir.y,foot.dir.x)*side*(2+age*3)+Vector2(0,5)
			g.canvas.draw_circle(at,1.5 if foot.mounted else 1,Color(.82,.84,.74,(1-age)*.4))
	for link in links:
		g.canvas.draw_line(link.from,link.to,Color(.65,.91,1,link.life*3),3)
		g.canvas.draw_line(link.from,link.to,Color(1,1,1,link.life*3),1)
	for event in events:
		var frame=clampi(int((.48-event.life)/.12),0,3)
		if event.kind==0:g.hd.sprite("effects/water-vines-v473.png",frame*4+2,event.pos-Vector2.ONE*event.size/2.0,Vector2.ONE*event.size)
		else:g.hd.sprite("effects/impacts-hd.png",frame*6+event.kind,event.pos-Vector2.ONE*event.size/2.0,Vector2.ONE*event.size)

func add_shelters(pve=false):
	var theme=g.Catalog.MAPS[g.arena].theme
	var pools=[[5,6],[0,3,4],[7,6],[6,1,2],[7,1,2],[1,2,5],[5,0],[7,6],[0,3,4],[7,0],[7,1,2],[6,5],[7,5],[7,1,2]]
	var total=g.terrain.values().filter(func(tile):return tile.type=="shelter").size()
	var limit=12 if pve else 8
	for y in range(3,g.H-3,3):
		for x in range(3,g.W-3,3):
			if total>=limit:break
			var c=Vector2i(x,y)
			var points=[c]
			if not pve:points.append(Vector2i(g.W-1-x,g.H-1-y))
			if points.any(func(at):return design_reserved(at,pve) or g.DIRS.any(func(d):return not g.inside(at+d) or g.grid[at.y+d.y][at.x+d.x] in [1,3] or g.terrain.has(at+d))):continue
			var art=pools[theme][posmod(x+y+g.arena,pools[theme].size())]
			var axis="x" if art in [1,3] else "y" if art in [2,4] else "all"
			for at in points:g.terrain[at]={"type":"shelter","art":art,"axis":axis}
			# A directional shelter must not seal either neighboring corridor.
			var seen={points[0]:true};var queue=[points[0]];var head=0
			while head<queue.size():
				var at=queue[head];head+=1
				for d in g.DIRS:
					var next=at+d
					if not seen.has(next) and g.inside(next) and g.grid[next.y][next.x] in [0,2] and g.can_cross(at,next):seen[next]=true;queue.append(next)
			var connected=points.all(func(at):return g.DIRS.all(func(d):return seen.has(at+d)))
			if not connected:
				for at in points:g.terrain.erase(at)
				continue
			for at in points:
				for d in g.DIRS:g.grid[at.y+d.y][at.x+d.x]=0
			total+=points.size()
	if g.crates:g.crates.prune()

func draw_shelter(c):
	var art=g.terrain[c].art;var pos=g.center(c)
	var size=Vector2(24,22) if art in [0,1,2,3,4] else Vector2(26,30)
	var tint=Color(.86,.92,1) if g.Catalog.MAPS[g.arena].theme in [2,7,12] else Color(.96,.94,.88)
	var shake=Vector2(sin(g.elapsed*83),cos(g.elapsed*71))*g.shake
	g.canvas.draw_set_transform(pos+Vector2(0,6)+shake,0,Vector2(1,.28))
	g.canvas.draw_circle(Vector2.ZERO,10,Color(.05,.09,.12,.24))
	g.canvas.draw_set_transform(shake)
	g.hd.sprite("maps/decorations/shelters-v480.png",art,pos+Vector2(-size.x*.5,8-size.y),size,tint)
