shader_type canvas_item;
uniform float seconds = 0.0;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
 vec2 p=UV; float center=abs(p.x-0.5);
 vec3 c=mix(vec3(0.015,0.025,0.08),vec3(0.11,0.23,0.35),1.0-p.y);
 float arch=abs(length(vec2((p.x-0.5)*1.3,(p.y-0.43)*0.9))-0.47);
 float gold=(1.0-smoothstep(0.006,0.016,arch));
 float pillar=(1.0-smoothstep(0.008,0.015,abs(center-0.40)))*step(0.38,p.y);
 c+=vec3(0.5,0.35,0.14)*(gold+pillar);
 float ray=pow(max(0.0,cos(atan(p.y-0.17,p.x-0.5)*11.0+seconds*0.1)),20.0);
 float wake=smoothstep(0.4,2.2,seconds);
 c+=vec3(0.19,0.24,0.26)*ray*wake*(1.0-p.y);
 COLOR=vec4(c,1.0)*vertex_tint;
}
