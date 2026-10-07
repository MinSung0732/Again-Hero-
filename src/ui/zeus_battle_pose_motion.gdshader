shader_type canvas_item;
render_mode unshaded;
uniform float motion_time = 0.0;
uniform vec2 canvas_size = vec2(768.0, 1280.0);
varying vec4 vertex_tint;
void vertex() {
	vertex_tint = COLOR;
	vec2 p = VERTEX / canvas_size;
	float sides = 1.0 - smoothstep(0.12, 0.32, min(p.x, 1.0 - p.x));
	float cloth = smoothstep(0.4, 0.65, p.y) * (1.0 - smoothstep(0.82, 0.9, p.y));
	VERTEX.x += sin(motion_time * 3.0 + p.y * 8.0) * 2.0 * sides * cloth;
}
void fragment() {
	COLOR = texture(TEXTURE, UV) * vertex_tint;
}
