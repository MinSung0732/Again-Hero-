shader_type canvas_item;

void fragment() {
	// COLOR already includes the source texture and CanvasItem tint.
	// Preserve transparency and convert only the rendered icon to grayscale.
	float luminance = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = vec3(luminance);
}
