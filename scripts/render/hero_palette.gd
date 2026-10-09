extends RefCounted
var g
var renders={}
func _init(game):g=game
func texture_for(id,portrait,texture,region,body_fraction=1.0,omissions=[],riding=false,walk_anchor=[]):
	var key=id+24 if not walk_anchor.is_empty() else id+16 if riding else id+8 if portrait else id
	if not renders.has(key):
		var viewport=SubViewport.new()
		viewport.size=Vector2i(176,200) if not walk_anchor.is_empty() else Vector2i(192,192);viewport.transparent_bg=true;viewport.disable_3d=true
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		g.add_child(viewport)
		var sprite=Sprite2D.new();sprite.centered=false;sprite.region_enabled=true
		var material=ShaderMaterial.new();material.shader=preload("res://assets/shaders/hero_palette.gdshader")
		sprite.material=material;viewport.add_child(sprite)
		renders[key]={"viewport":viewport,"sprite":sprite,"material":material}
	var render=renders[key]
	var team=g.players[id].team if g.state in ["play","pause","finale","result"] and id<g.players.size() else g.slot_team(id)
	render.material.set_shader_parameter("theme_color",g.COLORS[posmod(team,8)])
	render.sprite.texture=texture;render.sprite.region_rect=region
	if walk_anchor.is_empty():
		render.sprite.scale=Vector2(192,192)/region.size
		render.sprite.position=Vector2.ZERO
	else:
		# Keep the destination fixed while the offscreen renderer switches frames.
		var factor=8.0*minf(22.0/float(walk_anchor[1][0]),25.0/float(walk_anchor[1][1]))
		render.sprite.scale=Vector2.ONE*factor
		render.sprite.position=Vector2(88-float(walk_anchor[0])*factor,0)
	render.material.set_shader_parameter("region_uv",Vector4(region.position.x/texture.get_width(),region.position.y/texture.get_height(),region.size.x/texture.get_width(),region.size.y/texture.get_height()))
	var excluded=PackedVector4Array()
	for rect in omissions:excluded.append(Vector4(float(rect[0])/texture.get_width(),float(rect[1])/texture.get_height(),float(rect[2])/texture.get_width(),float(rect[3])/texture.get_height()))
	render.material.set_shader_parameter("excluded_count",mini(8,excluded.size()))
	while excluded.size()<8:excluded.append(Vector4.ZERO)
	render.material.set_shader_parameter("excluded_uv",excluded)
	render.material.set_shader_parameter("body_fraction",body_fraction)
	render.material.set_shader_parameter("riding",riding)
	return render.viewport.get_texture()
