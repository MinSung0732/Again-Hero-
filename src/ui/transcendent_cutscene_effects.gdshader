shader_type canvas_item;
render_mode unshaded;
varying vec4 vertex_tint;
void vertex() {
	vertex_tint = COLOR;
}
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	float intensity = max(pixel.r, max(pixel.g, pixel.b));
	vec3 blue = mix(vec3(0.12, 0.38, 1.0), vec3(0.85, 0.97, 1.0), intensity * intensity);
	COLOR = vec4(blue, pixel.a) * vertex_tint;
}
