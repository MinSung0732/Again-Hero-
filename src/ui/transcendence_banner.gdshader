shader_type canvas_item;
render_mode unshaded;
uniform float crop_height = 0.36;
uniform float crop_top = 0.10;

void fragment() {
	// Profile banners place the character on the left. Mirror into the right
	// half and focus on the face without rewriting or stretching the source.
	vec2 source_uv = vec2(1.0 - UV.x, crop_top + UV.y * crop_height);
	COLOR = texture(TEXTURE, source_uv);
	COLOR.a *= smoothstep(0.34, 0.68, UV.x);
}
