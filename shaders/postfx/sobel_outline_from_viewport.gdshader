shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float edge_threshold : hint_range(0.0, 2.0) = 0.15;
uniform float edge_softness : hint_range(0.001, 1.0) = 0.08;
uniform float edge_strength : hint_range(0.0, 8.0) = 2.0;
uniform float thickness : hint_range(0.25, 4.0) = 1.0;
uniform float overlay_opacity : hint_range(0.0, 1.0) = 1.0;
uniform float global_mix : hint_range(0.0, 1.0) = 0.0;
uniform bool preview_edges = false;
uniform float debug_force_mix : hint_range(0.0, 1.0) = 0.0;

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 texel = SCREEN_PIXEL_SIZE * thickness;

	float tl = luma(texture(screen_tex, SCREEN_UV + vec2(-texel.x, -texel.y)).rgb);
	float tc = luma(texture(screen_tex, SCREEN_UV + vec2(0.0, -texel.y)).rgb);
	float tr = luma(texture(screen_tex, SCREEN_UV + vec2(texel.x, -texel.y)).rgb);
	float ml = luma(texture(screen_tex, SCREEN_UV + vec2(-texel.x, 0.0)).rgb);
	float mr = luma(texture(screen_tex, SCREEN_UV + vec2(texel.x, 0.0)).rgb);
	float bl = luma(texture(screen_tex, SCREEN_UV + vec2(-texel.x, texel.y)).rgb);
	float bc = luma(texture(screen_tex, SCREEN_UV + vec2(0.0, texel.y)).rgb);
	float br = luma(texture(screen_tex, SCREEN_UV + vec2(texel.x, texel.y)).rgb);

	float gx = -tl - 2.0 * ml - bl + tr + 2.0 * mr + br;
	float gy = -tl - 2.0 * tc - tr + bl + 2.0 * bc + br;
	float edge_raw = length(vec2(gx, gy)) * 2.5;
	float edge_base = smoothstep(edge_threshold, edge_threshold + edge_softness, edge_raw);
	float strength = max(edge_strength, 0.001);
	float edge = 1.0 - pow(1.0 - edge_base, strength);
	edge = clamp(edge, 0.0, 1.0);

	vec4 src = texture(screen_tex, SCREEN_UV);
	if (debug_force_mix > 0.0) {
		vec3 debug_rgb = mix(src.rgb, outline_color.rgb, debug_force_mix);
		COLOR = vec4(debug_rgb, 1.0);
	} else if (preview_edges) {
		COLOR = vec4(vec3(edge), 1.0);
	} else {
		float outline_alpha = edge * outline_color.a * overlay_opacity;
		float final_mix = clamp(max(outline_alpha, global_mix), 0.0, 1.0);
		vec3 rgb = mix(src.rgb, outline_color.rgb, final_mix);
		COLOR = vec4(rgb, 1.0);
	}
}
