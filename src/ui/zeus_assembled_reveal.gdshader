shader_type canvas_item;
render_mode unshaded;

uniform float reveal_edge = -0.08;
uniform vec4 silhouette_color : source_color = vec4(0.025, 0.035, 0.075, 1.0);
uniform float motion_time = 0.0;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
	// All layers share this field, so partition edges remain coincident.
	// Small distal breeze only; torso, head, hands, staff and feet stay at rest.
	float left = 1.0 - smoothstep(180.0, 270.0, VERTEX.x);
	float right = smoothstep(460.0, 540.0, VERTEX.x);
	float lower = smoothstep(700.0, 780.0, VERTEX.y) * (1.0 - smoothstep(1060.0, 1150.0, VERTEX.y));
	float hair = smoothstep(440.0, 500.0, VERTEX.y) * (1.0 - smoothstep(610.0, 720.0, VERTEX.y));
	float strength = smoothstep(2.4, 3.0, motion_time) * (1.0 - smoothstep(4.0, 5.0, motion_time));
	VERTEX.x += sin(motion_time * 3.0 + VERTEX.y * 0.006) * 1.5 * strength * (left * hair + max(left, right) * lower);
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float revealed = 1.0 - smoothstep(reveal_edge - 0.025, reveal_edge + 0.025, UV.y);
	float rim = max(0.0, 1.0 - abs(UV.y - reveal_edge) / 0.008);
	vec3 body = mix(silhouette_color.rgb, source.rgb, revealed);
	body = mix(body, vec3(0.6, 0.88, 1.0), rim * 0.65);
	COLOR = vec4(body, source.a) * vertex_tint;
}
