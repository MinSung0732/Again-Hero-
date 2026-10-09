shader_type canvas_item;
uniform float closed : hint_range(0.0,1.0) = 0.0;
void fragment() {
	vec4 original = texture(TEXTURE,UV);
	vec2 p = UV*vec2(768.0,1280.0);
	// Original eye regions only; preserved outline becomes the closed eyelash.
	float left = step(356.0,p.x)*step(p.x,389.0)*step(431.0,p.y)*step(p.y,448.0);
	float right = step(399.0,p.x)*step(p.x,418.0)*step(439.0,p.y)*step(p.y,453.0);
	float mask = max(left,right)*closed;
	vec3 skin = texture(TEXTURE,UV+vec2(0.0,14.0/1280.0)).rgb;
	float line_y = mix(439.0,446.0,right);
	float lash = 1.0-step(1.3,abs(p.y-line_y));
	COLOR = vec4(mix(original.rgb,mix(skin,vec3(0.15,0.045,0.025),lash),mask),original.a)*COLOR;
}
