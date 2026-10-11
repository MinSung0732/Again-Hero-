shader_type canvas_item;
uniform float revealed = 0.0;
uniform float closed = 0.0;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
 vec4 original = texture(TEXTURE, UV); vec2 p = UV * vec2(768.0,1280.0);
 vec4 eye = original;
 bool right = p.x>347.0 && p.x<377.0 && p.y>338.0 && p.y<359.0;
 bool left = p.x>320.0 && p.x<339.0 && p.y>352.0 && p.y<369.0;
 if (right || left) {
  float eye_y = right ? 356.0 : 367.0;
  vec4 skin = texture(TEXTURE, vec2(UV.x,(right ? 366.0 : 377.0)/1280.0));
  float edge = smoothstep(right ? 347.0 : 320.0,right ? 350.0 : 322.0,p.x)*(1.0-smoothstep(right ? 374.0 : 337.0,right ? 377.0 : 339.0,p.x));
  float lid = 1.0-smoothstep(0.8,1.8,abs(p.y-eye_y));
  eye.rgb = mix(original.rgb,mix(skin.rgb,vec3(0.19,0.11,0.075),lid),closed*edge);
 }
 COLOR = vec4(mix(vec3(0.025,0.05,0.12),eye.rgb,revealed),original.a)*vertex_tint;
}
