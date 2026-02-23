shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float edge_threshold : hint_range(0.0, 2.0) = 0.15;
uniform float edge_softness : hint_range(0.001, 1.0) = 0.08;
uniform float edge_strength : hint_range(0.0, 8.0) = 2.0;
uniform float thickness : hint_range(0.25, 4.0) = 1.0;
uniform float overlay_opacity : hint_range(0.0, 1.0) = 1.0;
uniform float global_mix : hint_range(0.0, 1.0) = 0.0;
uniform bool preview_edges = false;
uniform float debug_force_mix : hint_range(0.0, 1.0) = 0.0;

uniform bool use_distance_controls = true;
uniform bool invert_depth = false;
uniform float camera_near : hint_range(0.001, 10.0) = 0.05;
uniform float camera_far : hint_range(1.0, 10000.0) = 500.0;
uniform float near_thickness_multiplier : hint_range(0.1, 8.0) = 2.0;
uniform float far_thickness_multiplier : hint_range(0.05, 4.0) = 0.5;
uniform float distance_start : hint_range(0.0, 10000.0) = 10.0;
uniform float distance_end : hint_range(0.1, 10000.0) = 100.0;

uniform vec2 screen_texel_size = vec2(0.00052, 0.00093);

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

float linearize_depth(float depth_raw) {
	if (invert_depth) {
		depth_raw = 1.0 - depth_raw;
	}
	float z = depth_raw * 2.0 - 1.0;
	float denom = camera_far + camera_near - z * (camera_far - camera_near);
	denom = max(denom, 0.000001);
	return (2.0 * camera_near * camera_far) / denom;
}

void fragment() {
	float scene_depth = linearize_depth(texture(depth_tex, SCREEN_UV).r);

	float dist_t = 0.0;
	if (use_distance_controls) {
		float span = max(distance_end - distance_start, 0.0001);
		dist_t = clamp((scene_depth - distance_start) / span, 0.0, 1.0);
	}

	float thickness_mul = mix(near_thickness_multiplier, far_thickness_multiplier, dist_t);
	vec2 texel = screen_texel_size * (thickness * thickness_mul);

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

	if (debug_force_mix > 0.0) {
		ALBEDO = outline_color.rgb;
		ALPHA = clamp(debug_force_mix, 0.0, 1.0);
	} else if (preview_edges) {
		ALBEDO = vec3(edge);
		ALPHA = 1.0;
	} else {
		float distance_alpha = 1.0 - dist_t;
		float outline_alpha = edge * outline_color.a * overlay_opacity * distance_alpha;
		float final_alpha = clamp(max(outline_alpha, global_mix), 0.0, 1.0);
		ALBEDO = outline_color.rgb;
		ALPHA = final_alpha;
	}
}
