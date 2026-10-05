shader_type canvas_item;
render_mode unshaded, blend_add;

// Resolution-independent geometry: no enlarged, blurry frame textures.
// One deterministic timeline drives the ring, sigil and eight quiet sparks.
uniform float phase : hint_range(0.0, 1.0) = 0.0;
uniform float fade : hint_range(0.0, 1.0) = 1.0;
uniform vec2 viewport_size = vec2(1080.0, 1920.0);

float stroke(float distance, float width, float aa) {
	return 1.0 - smoothstep(width, width + aa, abs(distance));
}

void fragment() {
	vec2 p = (UV - vec2(0.5, 0.55)) * viewport_size / 1080.0;
	float aa = max(fwidth(length(p)), 0.001);
	float arrive = smoothstep(0.0, 0.62, phase);
	float settle = smoothstep(0.70, 1.0, phase);
	float radius = mix(0.36, 0.285, arrive);
	vec2 ring_p = p / vec2(1.0, 0.38);
	float ring_distance = length(ring_p) - radius;
	float ring = stroke(ring_distance, 0.0018, aa * 2.0);
	float inner = stroke(length(ring_p) - radius * 0.85, 0.001, aa * 2.0);
	float theta = atan(ring_p.y, ring_p.x);
	float runes = pow(max(cos(theta * 12.0 - phase * 0.8), 0.0), 12.0);
	float marks = stroke(ring_distance, 0.007, aa * 2.0) * runes;
	float glow = exp(-abs(ring_distance) * 110.0) * 0.15;
	float sigil = stroke(abs(ring_p.x) + abs(ring_p.y) - radius * 0.62, 0.0016, aa * 2.0);
	float light = (ring + inner * 0.45 + marks * 0.40 + sigil * 0.55 + glow) * arrive;
	float sparks = 0.0;
	for (int i = 0; i < 8; i++) {
		float fi = float(i);
		float angle = fi * 0.785398 + 0.23;
		float distance = mix(0.43, 0.12, arrive);
		vec2 center = vec2(cos(angle) * distance, sin(angle) * distance * 0.90 - 0.17);
		vec2 delta = p - center;
		float diamond = abs(delta.x) + abs(delta.y);
		sparks += stroke(diamond, 0.003, aa) * sin(phase * 3.141593);
	}
	float strength = (light * mix(0.80, 0.34, settle) + sparks * 0.65) * fade;
	vec3 violet = mix(vec3(0.48, 0.20, 0.90), vec3(0.80, 0.55, 1.0), settle * 0.30);
	COLOR = vec4(violet * strength, 1.0);
}
