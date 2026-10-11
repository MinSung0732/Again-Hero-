shader_type canvas_item;
uniform float revealed = 0.0;
uniform float closed = 0.0;
uniform sampler2D closed_eyes_art : filter_nearest;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
 vec4 original = texture(TEXTURE, UV); vec2 p = UV * vec2(768.0,1280.0);
 vec4 eye = original;
 bool right = p.x>347.0 && p.x<377.0 && p.y>338.0 && p.y<359.0;
 bool left = p.x>320.0 && p.x<339.0 && p.y>352.0 && p.y<369.0;
 if (right || left) {
  // Generated closed lids only. Original hair, face, armor and silhouette are untouched.
  // The generated source has the same normalized canvas composition (971x1619).
  vec4 closed_pixel = texture(closed_eyes_art, UV);
  float edge = smoothstep(right ? 347.0 : 320.0,right ? 349.0 : 322.0,p.x)
   *(1.0-smoothstep(right ? 375.0 : 337.0,right ? 377.0 : 339.0,p.x));
  eye.rgb = mix(original.rgb,closed_pixel.rgb,closed*edge*closed_pixel.a);
 }

 COLOR = vec4(mix(vec3(0.025,0.05,0.12),eye.rgb,revealed),original.a)*vertex_tint;
}
