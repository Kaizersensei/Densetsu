shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float fresnel_power : hint_range(0.1, 8.0) = 3.0;
uniform float fresnel_strength : hint_range(0.0, 4.0) = 1.0;
uniform float min_alpha : hint_range(0.0, 1.0) = 0.0;


void fragment() {
	float ndv = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - ndv, max(fresnel_power, 0.1)) * fresnel_strength;
	float alpha = max(min_alpha, fresnel * outline_color.a);

	ALBEDO = outline_color.rgb;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
