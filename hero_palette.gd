extends RefCounted
var g
var renders={}
func _init(game):g=game
func texture_for(id,portrait,texture,region,body_fraction=1.0):
	var key=id+8 if portrait else id
	if not renders.has(key):
		var viewport=SubViewport.new()
		viewport.size=Vector2i(192,192);viewport.transparent_bg=true;viewport.disable_3d=true
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		g.add_child(viewport)
		var sprite=Sprite2D.new();sprite.centered=false;sprite.region_enabled=true
		var material=ShaderMaterial.new();material.shader=preload("res://assets/shaders/hero_palette.gdshader")
		material.set_shader_parameter("theme_color",g.COLORS[id])
		sprite.material=material;viewport.add_child(sprite)
		renders[key]={"viewport":viewport,"sprite":sprite,"material":material}
	var render=renders[key]
	render.sprite.texture=texture;render.sprite.region_rect=region
	render.sprite.scale=Vector2(192,192)/region.size
	render.material.set_shader_parameter("region_uv",Vector4(region.position.x/texture.get_width(),region.position.y/texture.get_height(),region.size.x/texture.get_width(),region.size.y/texture.get_height()))
	render.material.set_shader_parameter("body_fraction",body_fraction)
	return render.viewport.get_texture()
