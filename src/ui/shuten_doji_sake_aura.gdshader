shader_type canvas_item;
render_mode unshaded, blend_add;

// Two cached quads; deterministic clock resets with the reused presentation.
uniform float clock = 0.0;
uniform float foreground = 0.0;

float band(float radius, float center, float width) {
	return 1.0 - smoothstep(width * 0.4, width, abs(radius - center));
}

void fragment() {
	vec2 pixel = UV * vec2(540.0, 820.0);
	vec2 p = (pixel - vec2(270.0, 467.0)) / 270.0;
	float r = length(p);
	float angle = atan(p.y, p.x);
	float charge = smoothstep(0.45, 1.8, clock) * (1.0 - smoothstep(2.2, 2.65, clock));
	float release_age = max(clock - 2.2, 0.0);
	float release = smoothstep(2.2, 2.28, clock) * (1.0 - smoothstep(2.8, 3.45, clock));
	float hold = smoothstep(0.4, 1.15, clock) * (1.0 - smoothstep(4.3, 5.0, clock));
	float swirl = pow(max(0.0, sin(angle * 5.0 - r * 9.0 + clock * 2.1)), 6.0);
	float corona = band(r, 0.72, 0.10) + band(r, 0.85, 0.028);
	float sigils = step(0.85, cos(angle * 24.0 + clock * 0.4)) * band(r, 0.79, 0.07);
	float ray = pow(max(0.0, cos(angle * 17.0 - clock * 0.25)), 38.0);
	float burst = band(r, release_age * 1.6 + 0.15, 0.085) * release;
	vec2 floor_p = (pixel - vec2(270.0, 770.0)) / vec2(230.0, 58.0);
	float floor_r = length(floor_p);
	float floor_a = atan(floor_p.y, floor_p.x);
	float floor_ring = band(floor_r, 0.82, 0.035) + band(floor_r, 1.0, 0.022);
	float runes = step(0.7, cos(floor_a * 18.0 - clock)) * band(floor_r, 0.92, 0.05);
	float ember = pow(max(0.0, sin(pixel.x * 0.19 + clock * 1.5) * sin(pixel.y * 0.12 - clock * 3.0)), 18.0);
	float edges = smoothstep(0.20, 0.60, abs(p.x));
	float back = (corona * 0.20 + sigils * 0.45 + swirl * 0.10 * (1.0 - smoothstep(0.7, 1.3, r))) * hold;
	back += (floor_ring + runes) * hold * 0.65;
	back += ray * charge * smoothstep(0.4, 0.8, r) * (1.0 - smoothstep(1.0, 1.6, r)) * 0.4;
	float front = burst * 0.65 + ray * release * smoothstep(0.65, 0.95, r) * 0.5;
	front += ember * edges * hold * 0.22;
	float energy = mix(back, front, foreground);
	vec3 tint = mix(vec3(0.85, 0.06, 0.12), vec3(1.0, 0.57, 0.16), foreground * 0.5 + sigils * 0.2);
	COLOR = vec4(tint, clamp(energy, 0.0, 0.85));
}
