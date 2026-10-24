shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;
uniform vec4 spectral_color : source_color = vec4(0.30, 0.16, 0.75, 0.65);
uniform float wave_speed : hint_range(0.0, 5.0) = 1.5;
uniform float wave_frequency : hint_range(0.1, 20.0) = 8.0;
uniform float displacement : hint_range(0.0, 0.5) = 0.12;
void vertex() {
 float wave = sin(TIME * wave_speed + (VERTEX.x + VERTEX.z) * wave_frequency);
 VERTEX.y += wave * displacement;
}
void fragment() {
 ALBEDO = spectral_color.rgb;
 ALPHA = spectral_color.a * (0.85 + 0.15 * sin(TIME * 2.0));
 EMISSION = spectral_color.rgb * 0.9;
}
