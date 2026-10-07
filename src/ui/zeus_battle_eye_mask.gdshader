shader_type canvas_item;
render_mode unshaded;
uniform float eye_closed = 0.0;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
	vec2 p = UV * vec2(190.0, 145.0);
	vec2 a = (p - vec2(94.0,55.0)) / vec2(23.0,15.0);
	vec2 b = (p - vec2(134.0,75.0)) / vec2(21.0,15.0);
	float mask = 1.0 - smoothstep(0.84,1.0,min(length(a),length(b)));
	vec4 source = texture(TEXTURE,UV);
	COLOR = vec4(source.rgb,source.a * mask * eye_closed) * vertex_tint;
}
