extends RefCounted
const HERO_VIEWS=["characters/views/heroes-front-hd.png","characters/views/heroes-back-hd.png","characters/views/heroes-left-hd.png","characters/views/heroes-right-hd.png"]
const WALK_NAMES=["sailor","bunny","frog","fox","bear","witch","robot","flame"]
const WALL_TINTS=["d1e1ff", "d5ffbb", "b9dcff", "ffc76b", "b4c7ff", "b0d0ff", "ff906a", "a7b2ff", "eeffdc", "f3ddff", "83deff", "afd0ff", "b2bfff", "abc8ff"]
const FLOOR_COLORS=["e2c5a4", "9ead75", "c8dff2", "f3cc92", "bcb0ab", "a8b2bf", "fcddcd", "c3bfd4", "a3aa9a", "cabfb0", "bcccc4", "bfc7d4", "a9abc5", "94a0b1"]
var g
var regions:Dictionary
var textures:Dictionary={}
var enemy_baselines:Dictionary={}
var animation_baselines:Dictionary={}
func _init(game):
	g=game
	regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/atlas-regions.json"))
	for name in regions:textures[name]=load("res://assets/art/"+name)
func region(name,index):
	var r=regions[name][index]
	return Rect2(r[0],r[1],r[2],r[3])
func draw_region(name,index,destination,tint=Color.WHITE):
	var source=region(name,index)
	var parts=[source]
	var data=regions[name][index]
	if data.size()>4:
		for omitted in data[4]:
			var cut=Rect2(omitted[0],omitted[1],omitted[2],omitted[3]);var next=[]
			for part in parts:
				var overlap=part.intersection(cut)
				if not overlap.has_area():next.append(part);continue
				for piece in [Rect2(part.position,Vector2(part.size.x,overlap.position.y-part.position.y)),Rect2(Vector2(part.position.x,overlap.end.y),Vector2(part.size.x,part.end.y-overlap.end.y)),Rect2(Vector2(part.position.x,overlap.position.y),Vector2(overlap.position.x-part.position.x,overlap.size.y)),Rect2(Vector2(overlap.end.x,overlap.position.y),Vector2(part.end.x-overlap.end.x,overlap.size.y))]:
					if piece.has_area():next.append(piece)
			parts=next
	var ratio=destination.size/source.size
	for part in parts:g.canvas.draw_texture_rect_region(textures[name],Rect2(destination.position+(part.position-source.position)*ratio,part.size*ratio),part,tint)
func sprite(name,index,pos,size,tint=Color.WHITE,fit=true):
	var source=region(name,index)
	var drawn=size
	if fit:drawn=source.size*minf(size.x/source.size.x,size.y/source.size.y)
	draw_region(name,index,Rect2(pos+Vector2((size.x-drawn.x)/2,size.y-drawn.y),drawn),tint)
func theme_name(theme):return "maps/decorations/theme-"+g.Catalog.THEMES[theme]+"-hd.png"
func theme_sprite(theme,index,pos,size,tint=Color.WHITE,fit=true):
	if index in range(2,8):
		var block_tint=tint*Color(WALL_TINTS[theme]) if index==2 else tint
		sprite("maps/blocks/blocks-depth-v463.png",index,pos,size,block_tint,false)
		return
	var name="maps/floors/playfield-"+g.Catalog.THEMES[theme]+"-hd.png"
	if index<8 and regions.has(name):sprite(name,index,pos,size,tint,fit)
	else:sprite(theme_name(theme),index,pos,size,tint,fit)
func enemy_sprite(kind,pos,size,tint=Color.WHITE):sprite("monsters/creatures-hd.png",kind,pos,Vector2.ONE*size,tint)
func enemy_frame(kind,row,frame,pos,side,tint=Color.WHITE):
	var name="monsters/animations/monster-%02d-anim.png" % kind
	if not regions.has(name):enemy_sprite(kind,pos,side,tint);return
	var source=region(name,row*6+posmod(frame,6))
	if not enemy_baselines.has(name):
		var baseline=Vector2.ZERO
		for i in range(18):baseline=baseline.max(region(name,i).size)
		enemy_baselines[name]=baseline
	var baseline=enemy_baselines[name]
	var drawn=source.size*(side/maxf(baseline.x,baseline.y))
	g.canvas.draw_texture_rect_region(textures[name],Rect2(pos+Vector2((side-drawn.x)/2,side-drawn.y),drawn),source,tint)
func mount_sprite(kind,direction,pos,size,tint=Color.WHITE,phase=0.0):
	var source=region("mounts/mounts-hd.png",direction*3+kind-1)
	var drawn=source.size*minf(size.x/source.size.x,size.y/source.size.y)
	var squash=Vector2(1+sin(phase)*.012,1-abs(sin(phase))*.015)
	var offset=Vector2((size.x-drawn.x)/2,size.y-drawn.y)+Vector2(0,-abs(sin(phase))*.4)
	# The source rabbit left frame faces right; mirror it to match the rider.
	if kind==3 and direction==2:
		g.canvas.draw_set_transform(pos+Vector2(size.x,0)+Vector2(sin(g.elapsed*83),cos(g.elapsed*71))*g.shake,0,Vector2(-1,1))
		draw_region("mounts/mounts-hd.png",direction*3+kind-1,Rect2(offset,drawn*squash),tint)
		g.canvas.draw_set_transform(Vector2(sin(g.elapsed*83),cos(g.elapsed*71))*g.shake)
	else:draw_region("mounts/mounts-hd.png",direction*3+kind-1,Rect2(pos+offset,drawn*squash),tint)

func animation_baseline(name):
	if not animation_baselines.has(name):
		var baseline=Vector2.ZERO
		for frame in regions[name]:baseline=baseline.max(Vector2(frame[2],frame[3]))
		animation_baselines[name]=baseline
	return animation_baselines[name]
func ambient_frame(name,index,center,size,tint=Color.WHITE):
	var source=region(name,index)
	var baseline=animation_baseline(name)
	var drawn=source.size*minf(size.x/baseline.x,size.y/baseline.y)
	draw_region(name,index,Rect2(center-drawn/2,drawn),tint)

func riding_sprite(pos,p,kind,direction,frame,tint=Color.WHITE):
	var name="riding/"+WALK_NAMES[p.character]+"-"+["duck","turtle","rabbit","car"][kind-1]+".png"
	if not regions.has(name):return false
	var source=region(name,direction*4+posmod(frame,4));var baseline=animation_baseline(name)
	var size=Vector2(32,36) if kind!=4 else Vector2(30,29)
	var drawn=source.size*minf(size.x/baseline.x,size.y/baseline.y)
	g.canvas.draw_texture_rect(g.hero_palette.texture_for(p.id,false,textures[name],source,1.0,[],true),Rect2(pos+Vector2(-drawn.x*.5,6-drawn.y),drawn),false,tint)
	return true
