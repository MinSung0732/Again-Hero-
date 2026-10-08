shader_type canvas_item;
render_mode unshaded;
uniform sampler2D closed_eyes : filter_nearest;
uniform vec2 source_size = vec2(971.0,1619.0);
uniform vec2 eye_center = vec2(311.0,385.0);
uniform float eye_closed = 1.0;
uniform float reveal_edge = 0.0;
varying vec4 vertex_tint;
void vertex() {vertex_tint = COLOR;}
void fragment() {
    vec4 original = texture(TEXTURE,UV);
    vec2 eye = (UV*source_size-eye_center)/vec2(29.0,16.0);
    float mask = 1.0-smoothstep(0.65,1.0,length(eye));
    vec4 closed = texture(closed_eyes,UV);
    vec3 face = mix(original.rgb,closed.rgb,eye_closed*mask);
    float exposed = 1.0-smoothstep(reveal_edge-0.03,reveal_edge+0.03,UV.y);
    COLOR = vec4(face*exposed,original.a)*vertex_tint;
}
