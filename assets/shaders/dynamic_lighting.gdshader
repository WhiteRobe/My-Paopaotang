shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D fog_map : repeat_disable, filter_linear;
uniform float fog_amount = 0.0;
uniform sampler2D blockers : repeat_disable, filter_nearest;
uniform vec4 light_data[40]; // xy = map UV, z = radius in tiles, w = intensity
uniform vec4 light_colors[40];
uniform vec2 board_size=vec2(27.,19.);
uniform int light_count = 0;
uniform vec3 ambient = vec3(0.75, 0.80, 0.86);
void fragment() {
 vec2 cell_uv = floor(UV*(board_size*32.))/(board_size*32.);
 float fog = texture(fog_map,cell_uv).r*fog_amount;
 vec3 lighting = ambient*(1.0-fog*0.985);
 float visibility = 0.0;
 for (int i=0;i<40;i++) {
  if(i>=light_count) { break; }
  vec2 delta=(cell_uv-light_data[i].xy)*board_size;
  float distance_to_light=length(delta);
  float falloff=pow(max(0.0,1.0-distance_to_light/light_data[i].z),1.5)*light_data[i].w;
  if(falloff>0.002) {
   float shadow=1.0;
   for (int j=1;j<17;j++) {
    float fraction=float(j)/17.0;
    vec2 sample_uv=mix(light_data[i].xy,cell_uv,fraction);
    if(length(delta)*fraction>0.6 && length(delta)*(1.0-fraction)>0.15 && texture(blockers,sample_uv).r>0.5) {shadow=0.16;break;}
   }
   lighting+=light_colors[i].rgb*falloff*shadow;
   visibility=max(visibility,falloff*shadow);
  }
 }
 vec4 scene=texture(screen_texture,SCREEN_UV);
 vec3 color=scene.rgb*min(lighting,vec3(1.23));
 color=mix(color,vec3(0.16,0.20,0.24),fog*(1.0-clamp(visibility*1.4,0.0,1.0))*0.8);
 COLOR=vec4(color,scene.a);
}
