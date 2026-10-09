extends RefCounted
var g
var renders={}
# Shoulder and hip anchors are anatomical, independent of the swinging silhouettes.
const SHOULDERS=[Vector2(.57,.68),Vector2(.51,.76),Vector2(.53,.69),Vector2(.53,.68),Vector2(.53,.66),Vector2(.51,.72),Vector2(.56,.68),Vector2(.51,.70)]
func _init(game):g=game
func texture_for(id,character,phase,walking):
	var key=id if id>=0 else 8+character
	if not renders.has(key):
		var viewport=SubViewport.new()
		viewport.size=Vector2i(176,200);viewport.transparent_bg=true;viewport.disable_3d=true
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		g.add_child(viewport)
		var sprites=[]
		for i in range(5):
			var sprite=Sprite2D.new();sprite.centered=false;sprite.region_enabled=true
			var material=ShaderMaterial.new();material.shader=preload("res://assets/shaders/hero_palette.gdshader")
			sprite.material=material;viewport.add_child(sprite);sprites.append(sprite)
		renders[key]={"viewport":viewport,"sprites":sprites,"amount":0.0,"frame":-1}
	var render=renders[key]
	if render.frame!=Engine.get_process_frames():
		render.amount=move_toward(render.amount,1.0 if walking else 0.0,minf(.05,g.get_process_delta_time())*7.0)
		render.frame=Engine.get_process_frames()
	var rig="characters/rigs/"+g.HDArt.WALK_NAMES[character]+"-v501.png"
	var torso="characters/rigs/torsos-"+str(int(character/4))+"-v501.png"
	var entry=g.hd.regions[torso][character%4]
	var body=Rect2(entry[0],entry[1],entry[2],entry[3])
	var factor=19.0/body.size.y
	var origin=Vector2(11-float(entry[4])*factor,0)
	var shoulder=origin+body.size*SHOULDERS[character]*factor
	# Backpacks and rear shoulders must not push the legs behind the head/body axis.
	var hip=Vector2(11,17.3)
	var swing=sin(phase*TAU/12.0)*render.amount
	var team=g.players[id].team if id>=0 and id<g.players.size() and g.state in ["play","pause","finale","result"] else g.slot_team(maxi(0,id))
	# Far leg, far arm, near leg, torso, near arm. Opposite arm and leg advance together.
	var parts=[4,2,3,-1,1]
	for i in range(5):
		var sprite=render.sprites[i]
		var is_body=parts[i]<0
		var name=torso if is_body else rig
		var region=body if is_body else g.hd.region(rig,parts[i])
		sprite.texture=g.hd.textures[name];sprite.region_rect=region
		var scale_factor=factor if is_body else (8.7 if i in [0,2] else 8.1)/region.size.y
		var joint=Vector2(region.size.x*.5,region.size.y*.12)
		if i in [0,2]:joint.x=float(g.hd.regions[rig][parts[i]][5])
		sprite.offset=Vector2.ZERO if is_body else -joint
		sprite.scale=Vector2.ONE*scale_factor*8
		sprite.position=(origin if is_body else hip+Vector2(-.6 if i==0 else .6,0) if i in [0,2] else shoulder+Vector2(-1.0 if i==1 else 0,0))*8
		sprite.rotation=0 if is_body else swing*([.38,-.40,-.38,0,.40][i])
		if i in [0,2]:sprite.position.y-=maxf(0,swing*(-1 if i==0 else 1))*.45*8
		var material=sprite.material
		material.set_shader_parameter("region_uv",Vector4(region.position.x/sprite.texture.get_width(),region.position.y/sprite.texture.get_height(),region.size.x/sprite.texture.get_width(),region.size.y/sprite.texture.get_height()))
		material.set_shader_parameter("theme_color",g.COLORS[posmod(team,8)])
		material.set_shader_parameter("puppet_part",0 if is_body else 2 if i in [0,2] else 1)
		var omissions=entry[5] if is_body else g.hd.regions[rig][parts[i]][4]
		var excluded=PackedVector4Array()
		for rect in omissions:excluded.append(Vector4(float(rect[0])/sprite.texture.get_width(),float(rect[1])/sprite.texture.get_height(),float(rect[2])/sprite.texture.get_width(),float(rect[3])/sprite.texture.get_height()))
		material.set_shader_parameter("excluded_count",mini(8,excluded.size()))
		while excluded.size()<8:excluded.append(Vector4.ZERO)
		material.set_shader_parameter("excluded_uv",excluded)
	return render.viewport.get_texture()
