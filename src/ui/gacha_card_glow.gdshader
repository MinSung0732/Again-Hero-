shader_type canvas_item;

uniform vec4 rarity_color : source_color = vec4(1.0);
uniform float pulse_phase = 0.0;

// Select the source frame's gold rails, excluding the purple card interior.
float rail_mask(sampler2D source, vec2 uv) {
	vec4 sample_color = texture(source, clamp(uv, vec2(0.0), vec2(1.0)));
	float gold = smoothstep(0.08, 0.22, sample_color.r - sample_color.b)
		* smoothstep(0.025, 0.13, sample_color.g - sample_color.b);
	float edge = 1.0 - step(0.15, uv.x) * step(uv.x, 0.85)
		* step(0.13, uv.y) * step(uv.y, 0.86);
	return gold * edge * sample_color.a;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 spread = vec2(0.018, 0.013);
	float core = rail_mask(TEXTURE, UV);
	float halo = 0.0;
	halo += rail_mask(TEXTURE, UV + vec2(spread.x, 0.0));
	halo += rail_mask(TEXTURE, UV - vec2(spread.x, 0.0));
	halo += rail_mask(TEXTURE, UV + vec2(0.0, spread.y));
	halo += rail_mask(TEXTURE, UV - vec2(0.0, spread.y));
	halo += rail_mask(TEXTURE, UV + spread);
	halo += rail_mask(TEXTURE, UV - spread);
	halo += rail_mask(TEXTURE, UV + vec2(spread.x, -spread.y));
	halo += rail_mask(TEXTURE, UV + vec2(-spread.x, spread.y));
	halo *= 0.125;
	float pulse = 0.65 + 0.35 * (0.5 + 0.5 * sin(TIME * 2.4 + pulse_phase));
	float sweep = pow(max(cos(UV.x * 8.0 + UV.y * 12.0 - TIME * 1.7 + pulse_phase), 0.0), 12.0);
	vec3 bright = mix(rarity_color.rgb, vec3(1.0), sweep * 0.24);
	base.rgb = mix(base.rgb, bright * (0.80 + pulse * 0.30), core);
	float glow = halo * pulse * 0.75;
	base.rgb = mix(base.rgb, rarity_color.rgb, glow * (1.0 - core));
	base.a = max(base.a, glow);
	COLOR = base;
}
