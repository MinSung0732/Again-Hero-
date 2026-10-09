shader_type canvas_item;
render_mode unshaded;
uniform float reveal_edge = -0.08;
uniform vec4 silhouette_color : source_color = vec4(0.015, 0.008, 0.025, 1.0);
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float revealed = 1.0 - smoothstep(reveal_edge - 0.025, reveal_edge + 0.025, UV.y);
	float rim = max(0.0, 1.0 - abs(UV.y - reveal_edge) / 0.008);
	vec3 body = mix(silhouette_color.rgb, source.rgb, revealed);
	body = mix(body, vec3(0.8, 0.95, 0.3), rim * 0.65);
	COLOR = vec4(body, source.a) * vertex_tint;
}
