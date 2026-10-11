shader_type canvas_item;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
 vec4 art = texture(TEXTURE, UV);
 // Generated alpha occasionally contains 1/255 noise in empty pixels.
 // Crisp cutout edges; the timeline fades the entire effect via vertex tint.
 if (art.a < 0.5) { discard; }
 COLOR = vec4(art.rgb, 1.0) * vertex_tint;
}
