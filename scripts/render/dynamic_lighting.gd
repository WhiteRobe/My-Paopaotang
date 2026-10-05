extends RefCounted
var g
var overlay:ColorRect
var shader_material:ShaderMaterial
var blocker_image:Image
var blocker_texture:ImageTexture
var timer=0.0
var enabled=true
func _init(game):
	g=game;overlay=ColorRect.new();overlay.position=Vector2.ZERO;overlay.visible=false;overlay.size=Vector2(g.W*g.TILE,g.H*g.TILE);overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	shader_material=ShaderMaterial.new();shader_material.shader=preload("res://assets/shaders/dynamic_lighting.gdshader");shader_material.set_shader_parameter("board_size",Vector2(g.W,g.H));overlay.material=shader_material;overlay.z_index=1
	g.world_clip.add_child(overlay);blocker_image=Image.create(g.W,g.H,false,Image.FORMAT_RGBA8);blocker_texture=ImageTexture.create_from_image(blocker_image);shader_material.set_shader_parameter("blockers",blocker_texture);shader_material.set_shader_parameter("fog_map",g.weather.fog_texture)
func light(data,colors,pos,radius,color,strength=1.0):
	if data.size()>=40:return
	data.append(Vector4(pos.x/g.W,pos.y/g.H,radius,strength));colors.append(Vector4(color.r,color.g,color.b,1))
func update(dt):
	overlay.visible=enabled and g.state=="play"
	if not overlay.visible:return
	overlay.position=-g.camera*g.TILE+Vector2(sin(g.elapsed*83),cos(g.elapsed*71))*g.shake
	if blocker_image.get_width()!=g.W or blocker_image.get_height()!=g.H:
		blocker_image=Image.create(g.W,g.H,false,Image.FORMAT_RGBA8);blocker_texture=ImageTexture.create_from_image(blocker_image);shader_material.set_shader_parameter("blockers",blocker_texture);timer=0
	overlay.size=Vector2(g.W,g.H)*g.TILE;shader_material.set_shader_parameter("board_size",Vector2(g.W,g.H))
	timer-=dt
	if timer<=0:
		timer=.12
		for y in range(g.H):
			for x in range(g.W):blocker_image.set_pixel(x,y,Color.WHITE if g.grid[y][x] in [1,2] else Color.BLACK)
		blocker_texture.update(blocker_image)
	var data:PackedVector4Array=[];var colors:PackedVector4Array=[]
	var theme=g.Catalog.MAPS[g.arena].theme
	var ambience=[.83,.78,.82,.85,.68,.78,.87,.58,.65,.69,.72,.78,.54,.1][theme]
	ambience=maxf(ambience,.9) if not g.Catalog.MAPS[g.arena].get("night",false) else ambience
	var darkness=maxf(g.weather.nightness,1.0 if g.rule()=="blackout" and fmod(g.round_time,12)>=8 else 0.0)
	ambience=lerpf(ambience,.015,darkness)
	if g.weather.flare_time>0:ambience=1
	shader_material.set_shader_parameter("ambient",Vector3(ambience*.95,ambience,ambience*1.06))
	shader_material.set_shader_parameter("fog_amount",g.weather.fog_strength if g.weather.flare_time<=0 else 0)
	var limited=darkness>.1 or g.weather.fog_strength>.1
	for p in g.players:
		if limited and not p.dead:light(data,colors,p.visual+Vector2(.5,.5),5.8 if p.get("torch",0)>0 else 3.1,Color("ffdfb2") if p.get("torch",0)>0 else Color("daf2f4"),1.35 if limited else .25)
	for c in g.weather.torches:
		if g.grid[c.y][c.x]!=3:light(data,colors,Vector2(c)+Vector2(.5,.5),3.5,Color("ffcf96"),1.12)
	if g.mode==3 and darkness<.3:
		light(data,colors,Vector2(g.adventure.checkpoint)+Vector2(.5,.5),4,Color("c6ffad"),.85 if g.adventure.objective_done else .3)
		for o in g.adventure.objects:
			if o.type=="beacons" or not o.active:light(data,colors,Vector2(o.cell)+Vector2(.5,.5),2.8,Color("ffe5aa"),.6 if o.active else .35)
	for b in (g.bombs if limited else []):
		var charge=clampf((1.2-b.timer)/1.2,0,1)
		light(data,colors,Vector2(b.cell)+Vector2(.5,.5),1+charge*3.3,Color(g.BubbleEffects.STYLES[b.get("element",0)].color),.02+charge*charge*1.3)
	for f in g.blasts:
		if not limited and f.get("pulse_only",false):continue
		if data.size()>=40:break
		var color=Color(g.Adventure.SKILL_COLORS[f.skill]) if f.has("skill") else Color("ff693e") if f.get("hazard","")=="laser" else Color(g.BubbleEffects.STYLES[f.get("element",0)].color)
		light(data,colors,Vector2(f.cell)+Vector2(.5,.5),2.2,color,.8*minf(1,f.time*3))
	var count=data.size()
	while data.size()<40:data.append(Vector4.ZERO);colors.append(Vector4.ZERO)
	shader_material.set_shader_parameter("light_count",count);shader_material.set_shader_parameter("light_data",data);shader_material.set_shader_parameter("light_colors",colors)
