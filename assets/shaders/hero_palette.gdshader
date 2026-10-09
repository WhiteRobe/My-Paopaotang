shader_type canvas_item;
render_mode unshaded;
uniform vec4 theme_color : source_color = vec4(.3,.8,1.,1.);
uniform vec4 region_uv;
uniform int excluded_count=0;
uniform vec4 excluded_uv[8];
uniform float body_fraction=1.0;
uniform bool riding=false;
uniform bool defeated=false;
uniform int puppet_part=0;
vec3 hsv(vec3 c) {
 vec4 K=vec4(0.,-1./3.,2./3.,-1.);
 vec4 p=mix(vec4(c.bg,K.wz),vec4(c.gb,K.xy),step(c.b,c.g));
 vec4 q=mix(vec4(p.xyw,c.r),vec4(c.r,p.yzx),step(p.x,c.r));
 float d=q.x-min(q.w,q.y);
 return vec3(abs(q.z+(q.w-q.y)/(6.*d+.00001)),d/(q.x+.00001),q.x);
}
vec3 rgb(vec3 c) {return c.z*mix(vec3(1.),clamp(abs(fract(c.xxx+vec3(0.,2./3.,1./3.))*6.-3.)-1.,0.,1.),c.y);}
void fragment() {
 vec4 pixel=texture(TEXTURE,UV);
 for (int i=0;i<8;i++) {
  if (i>=excluded_count) break;
  vec4 r=excluded_uv[i];
  if (UV.x>=r.x && UV.x<r.x+r.z && UV.y>=r.y && UV.y<r.y+r.w) pixel.a=0.;
 }
 vec3 original=hsv(pixel.rgb);vec3 theme=hsv(theme_color.rgb);
 float y=(UV.y-region_uv.y)/region_uv.w*body_fraction;
 float clothing=smoothstep(.40,.53,y)*(1.-smoothstep(.83,.98,y));
 if (puppet_part==1) clothing=1.-smoothstep(.67,.86,y);
 if (puppet_part==2) clothing=1.-smoothstep(.42,.60,y);
 if (riding) clothing=smoothstep(.22,.30,y)*(1.-smoothstep(.38,.45,y));
 // Warm skin, fur, pale fabric and metallic highlights keep their original colours.
 float warm=1.-smoothstep(.10,.16,original.x);
 float skin=warm*smoothstep(.38,.58,original.z);
 float mask=clothing*smoothstep(.12,.30,original.y)*(1.-skin);
 vec3 replacement=rgb(vec3(theme.x,mix(original.y,max(original.y,.55),.55),original.z));
 vec3 painted=mix(pixel.rgb,replacement,mask*.88);
 if (defeated) painted=vec3(dot(painted,vec3(.299,.587,.114)));
 COLOR=vec4(painted,pixel.a);
}
