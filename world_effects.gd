extends RefCounted
var g
var accents=preload("res://assets/decorations.png")
var impacts=preload("res://assets/impact-effects.png")
var events:Array=[]
func _init(game):g=game
func impact(pos,kind=0,size=30):
	events.append({"pos":pos,"kind":kind,"life":.48,"size":size})
	if events.size()>90:events.pop_front()
func update(dt):
	for event in events:event.life-=dt
	events=events.filter(func(event):return event.life>0)
func draw_ground():
	var theme=g.Catalog.MAPS[g.arena].theme
	for y in range(1,g.H-1):
		for x in range(1,g.W-1):
			var c=Vector2i(x,y)
			if g.grid[y][x]!=0 or g.terrain.has(c):continue
			var hash_value=x*37+y*19+g.arena*11
			if hash_value%19!=0:continue
			var variant=int(hash_value/19)%3
			if theme in [4,5,7,9,11,12] and variant==1:variant=0
			g.draw_texture_rect_region(accents,Rect2(g.ORIGIN+Vector2(c)*g.TILE-Vector2(1,1),Vector2(20,20)),Rect2(Vector2(variant*20,theme*20),Vector2(20,20)))
	for c in [Vector2i(2,0),Vector2i(g.W-3,0),Vector2i(0,3),Vector2i(g.W-1,g.H-4)]:
		var pos=g.center(c)
		var variant=6 if theme in [0,3,9,11] else (5 if theme in [1,8] else 3)
		g.draw_texture_rect_region(accents,Rect2(pos-Vector2(10,13),Vector2(20,20)),Rect2(Vector2(variant*20,theme*20),Vector2(20,20)))
		if variant==3:
			for radius in [10,7,4]:g.draw_circle(pos+Vector2(0,-7),radius,Color(1,.88,.64,.045))
func draw_air():
	var theme=g.Catalog.MAPS[g.arena].theme
	var color=[Color("c4efdf"),Color("c6dba0"),Color("e5f7ff"),Color("eed0aa"),Color("ffba83"),Color("bddbdd"),Color("ffe0ed"),Color("dfd6ff"),Color("d3edaa"),Color("decfb7"),Color("b9eeeb"),Color("e6f3e9"),Color("d1b6ef")][theme]
	for n in range(20):
		var pos=g.ORIGIN+Vector2(fposmod(n*53+g.elapsed*(3 if theme in [7,8,12] else 9),g.W*g.TILE),fposmod(n*29+g.elapsed*(8 if theme==2 else -4),g.H*g.TILE))
		var alpha=.24+.24*sin(g.elapsed*2+n)
		if theme in [0,10]:
			g.draw_arc(pos,1.5+(n%3)*.5,0,TAU,10,Color(color,alpha),1)
		elif theme in [1,8]:
			g.rect(pos,Vector2(2,1),Color(color,alpha));g.rect(pos+Vector2(1,-1),Vector2(1,3),Color(color,alpha))
		elif theme in [7,12]:
			g.draw_line(pos-Vector2(2,0),pos+Vector2(2,0),Color(color,alpha),1);g.draw_line(pos-Vector2(0,2),pos+Vector2(0,2),Color(color,alpha),1)
		else:g.rect(pos,Vector2(1 if theme in [3,9] else 2,1),Color(color,alpha))
	for event in events:
		var frame=clampi(int((.48-event.life)/.12),0,3)
		g.draw_texture_rect_region(impacts,Rect2(event.pos-Vector2.ONE*event.size/2.0,Vector2.ONE*event.size),Rect2(Vector2(event.kind*32,frame*32),Vector2(32,32)))
