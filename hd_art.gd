extends RefCounted
const HERO_VIEWS=["heroes-front-hd.png","heroes-back-hd.png","heroes-left-hd.png","heroes-right-hd.png"]
const WALK_NAMES=["sailor","bunny","frog","fox","bear","witch","robot","flame"]
var g
var regions:Dictionary
var textures:Dictionary={}
var enemy_baselines:Dictionary={}
func _init(game):
	g=game
	regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/hd/regions.json"))
	for name in regions:textures[name]=load("res://assets/hd/"+name)
func region(name,index):
	var r=regions[name][index]
	return Rect2(r[0],r[1],r[2],r[3])
func sprite(name,index,pos,size,tint=Color.WHITE,fit=true):
	var source=region(name,index)
	var drawn=size
	if fit:drawn=source.size*minf(size.x/source.size.x,size.y/source.size.y)
	g.draw_texture_rect_region(textures[name],Rect2(pos+Vector2((size.x-drawn.x)/2,size.y-drawn.y),drawn),source,tint)
func theme_name(theme):return "theme-"+g.Catalog.THEMES[theme]+"-hd.png"
func theme_sprite(theme,index,pos,size,tint=Color.WHITE,fit=true):
	var name="playfield-"+g.Catalog.THEMES[theme]+"-hd.png"
	if index<8 and regions.has(name):sprite(name,index,pos,size,tint,fit)
	else:sprite(theme_name(theme),index,pos,size,tint,fit)
func enemy_sprite(kind,pos,size,tint=Color.WHITE):sprite("creatures-hd.png",kind,pos,Vector2.ONE*size,tint)
func enemy_frame(kind,row,frame,pos,side,tint=Color.WHITE):
	var name="monster-%02d-anim.png" % kind
	if not regions.has(name):enemy_sprite(kind,pos,side,tint);return
	var source=region(name,row*6+posmod(frame,6))
	if not enemy_baselines.has(name):
		var baseline=Vector2.ZERO
		for i in range(18):baseline=baseline.max(region(name,i).size)
		enemy_baselines[name]=baseline
	var baseline=enemy_baselines[name]
	var drawn=source.size*(side/maxf(baseline.x,baseline.y))
	g.draw_texture_rect_region(textures[name],Rect2(pos+Vector2((side-drawn.x)/2,side-drawn.y),drawn),source,tint)
func mount_sprite(kind,direction,pos,size,tint=Color.WHITE,phase=0.0):
	var source=region("mounts-hd.png",direction*3+kind-1)
	var drawn=source.size*minf(size.x/source.size.x,size.y/source.size.y)
	var squash=Vector2(1+sin(phase)*.012,1-abs(sin(phase))*.015)
	g.draw_texture_rect_region(textures["mounts-hd.png"],Rect2(pos+Vector2((size.x-drawn.x)/2,size.y-drawn.y)+Vector2(0,-abs(sin(phase))*.4),drawn*squash),source,tint)
