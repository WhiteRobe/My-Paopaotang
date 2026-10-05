extends RefCounted
var g
var nightness=0.0
var fog_strength=0.0
var flare_time=0.0
var wind=false
var torches:Array=[]
var fog_patches:Array=[]
var epoch=-1
var mask_timer=0.0
var fog_image:Image
var fog_texture:ImageTexture
func _init(game):
	g=game;fog_image=Image.create(g.W*2,g.H*2,false,Image.FORMAT_RGBA8);fog_image.fill(Color.BLACK);fog_texture=ImageTexture.create_from_image(fog_image)
func setup():
	if fog_image.get_width()!=g.W*2 or fog_image.get_height()!=g.H*2:
		fog_image=Image.create(g.W*2,g.H*2,false,Image.FORMAT_RGBA8);fog_image.fill(Color.BLACK);fog_texture=ImageTexture.create_from_image(fog_image)
		if g.lighting:g.lighting.shader_material.set_shader_parameter("fog_map",fog_texture)
	for c in torches:
		if g.terrain.has(c) and g.terrain[c].type=="torch":g.terrain.erase(c)
	torches.clear();fog_patches.clear();flare_time=0;epoch=-1;mask_timer=0
	if g.Catalog.MAPS[g.arena].get("night",false):
		var candidates:Array=[]
		for y in range(2,g.H-2):
			for x in range(2,g.W-2):
				var c=Vector2i(x,y)
				if g.grid[y][x]==0 and not g.terrain.has(c):candidates.append(c)
		for n in range(6):
			if candidates.is_empty():break
			var c=candidates[g.rng.randi_range(0,candidates.size()-1)];torches.append(c);g.terrain[c]={"type":"torch"}
			candidates=candidates.filter(func(other):return g.manhattan(c,other)>=4)
		# Fixed flames never expire; the temporary carried torch is a separate item.
	update(0)
func update(dt):
	flare_time=maxf(0,flare_time-dt)
	var phase=fmod(g.round_time,90)
	nightness=0.0 if phase<35 else (clampf((phase-35)/10,0,1) if phase<75 else clampf((90-phase)/15,0,1))
	if not g.Catalog.MAPS[g.arena].get("daynight",false):nightness=0
	if g.mode in [1,2]:
		if g.battle_options.daylight==1:nightness=0
		elif g.battle_options.daylight==2:nightness=0.0 if phase<35 else (clampf((phase-35)/10,0,1) if phase<75 else clampf((90-phase)/15,0,1))
		elif g.battle_options.daylight==3:nightness=1
	if g.Catalog.MAPS[g.arena].get("night",false):nightness=1
	var fog_phase=fmod(g.round_time+(g.arena%7)*2,60)
	var fog_enabled=g.Catalog.MAPS[g.arena].get("fog",false)
	if g.mode in [1,2] and g.battle_options.fog>0:fog_enabled=g.battle_options.fog==2
	wind=fog_enabled and fog_phase>=50
	fog_strength=clampf(minf((fog_phase-18)/4,(50-fog_phase)/5),0,1)
	if not fog_enabled:fog_strength=0
	var new_epoch=int((g.round_time+(g.arena%7)*2)/60)
	if new_epoch!=epoch:
		epoch=new_epoch;fog_patches.clear()
		for n in range(7):fog_patches.append({"pos":Vector2(g.rng.randf_range(1,g.W-1),g.rng.randf_range(1,g.H-1)),"radius":g.rng.randf_range(3,5.5),"phase":g.rng.randf_range(0,TAU)})
	mask_timer-=dt
	if mask_timer<=0 and DisplayServer.get_name()!="headless" and fog_strength>.01:
		mask_timer=.2
		for y in range(g.H*2):
			for x in range(g.W*2):
				var pos=Vector2(x+.5,y+.5)/2.0;var density=0.0
				for patch in fog_patches:
					var drift=Vector2(sin(g.round_time*.13+patch.phase),cos(g.round_time*.09+patch.phase))*.9
					density=maxf(density,clampf(1-pos.distance_to(patch.pos+drift)/patch.radius,0,1)*1.8)
				fog_image.set_pixel(x,y,Color(clampf(density,0,1),0,0,1))
		fog_texture.update(fog_image)
func label():
	if flare_time>0:return g.loc("照明弹 %d秒") % int(ceil(flare_time))
	if wind:return "风吹散雾"
	if fog_strength>.3:return "雾气弥漫"
	if g.Catalog.MAPS[g.arena].get("night",false):return "洞窟 · 常夜"
	if nightness>.9:return "夜晚"
	if nightness>.1:return "黄昏" if fmod(g.round_time,90)<75 else "黎明"
	return "白昼"
func draw_torch(c):
	if g.grid[c.y][c.x]==3:return
	var pos=g.center(c)
	g.canvas.draw_circle(pos+Vector2(0,5),4,Color(0,0,0,.20))
	g.hd.sprite("maps/decorations/site-details-v478.png",13,pos+Vector2(-8,-17),Vector2(16,23))
	g.canvas.draw_circle(pos+Vector2(0,-10),.7+sin(g.elapsed*11+c.x)*.15,Color("fff1b5"))
