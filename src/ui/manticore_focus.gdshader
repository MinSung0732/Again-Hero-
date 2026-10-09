shader_type canvas_item;
uniform float closed : hint_range(0.0,1.0) = 0.0;
uniform sampler2D closed_eyes : source_color, filter_nearest, repeat_disable;
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
// Aligned atlas regions from the generated expression; original anatomy remains intact.
vec4 eyelid(vec2 p, vec4 destination, vec4 source) {
	vec2 q = (p-destination.xy)/destination.zw;
	vec2 edge = min(p-destination.xy,destination.xy+destination.zw-p);
	float mask = smoothstep(0.0,1.0,min(edge.x,edge.y));
	vec3 skin = texture(closed_eyes,(source.xy+clamp(q,vec2(0.0),vec2(1.0))*source.zw)/vec2(971.0,1619.0)).rgb;
	return vec4(skin,mask);
}
void fragment() {
	vec4 original = texture(TEXTURE,UV);
	vec2 p = UV*vec2(768.0,1280.0);
	vec4 left = eyelid(p,vec4(355.0,429.0,36.0,20.0),vec4(450.0,542.0,48.0,27.0));
	vec4 right = eyelid(p,vec4(397.0,438.0,23.0,19.0),vec4(504.0,553.0,30.0,27.0));
	vec3 rgb = mix(original.rgb,left.rgb,left.a*closed);
	rgb = mix(rgb,right.rgb,right.a*closed);
	COLOR = vec4(rgb,original.a)*vertex_tint;
}
