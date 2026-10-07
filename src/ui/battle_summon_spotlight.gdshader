shader_type canvas_item;
render_mode unshaded;
uniform vec2 focus = vec2(0.5);
uniform vec2 panel_size = vec2(1080.0, 1174.0);
uniform float strength = 0.0;
void fragment() {
	float d = length((UV - focus) * panel_size);
	float outside = smoothstep(75.0, 220.0, d);
	COLOR = vec4(0.015, 0.025, 0.065, outside * strength * 0.68);
}
