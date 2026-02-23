shader_type spatial;

// Densetsu Flowing Water (DFW) - Phase 1
// Lightweight, deterministic, per-quad border-aware UV advection for water materials.
// Phase 1 scope:
// - Drop-in shader material
// - Manual border mask input (optional)
// - Full debug views
// - No vertex displacement (illusion via normals/roughness/albedo)

render_mode cull_back, diffuse_burley, specular_schlick_ggx;

const float DFW_PI = 3.14159265359;
const float DFW_EPS = 0.00001;

// Core -----------------------------------------------------------------------
uniform bool dfw_enabled = true;
// When enabled, all quads share the same advection speed/phase.
// Border steering can still adjust direction per quad near edges.
uniform bool sync_global_advection = true;
// Optional override: allow cosmetic per-quad randomization even while synced.
uniform bool allow_quad_randomization = false;
uniform vec2 base_dir = vec2(1.0, 0.0);
uniform float quad_uv_size : hint_range(0.001, 1.0, 0.001) = 0.0625;
uniform float speed : hint_range(0.0, 8.0, 0.001) = 0.15;
uniform float speed_variation : hint_range(0.0, 1.0, 0.001) = 0.15;
uniform float seed : hint_range(0.0, 99999.0, 0.001) = 1.0;
uniform float jitter_angle_deg : hint_range(0.0, 180.0, 0.1) = 16.0;

// Time / determinism ---------------------------------------------------------
uniform float time_scale : hint_range(0.0, 16.0, 0.001) = 1.0;
uniform bool use_manual_time = false;
uniform float manual_time : hint_range(-100000.0, 100000.0, 0.001) = 0.0;

// UV handling ----------------------------------------------------------------
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);
uniform float continuous_warp_amp : hint_range(0.0, 1.0, 0.0001) = 0.005;
uniform float continuous_warp_scale : hint_range(0.01, 256.0, 0.01) = 3.0;
uniform float per_quad_warp_amp : hint_range(0.0, 1.0, 0.0001) = 0.0025;
uniform float per_quad_warp_detail_mix : hint_range(0.0, 1.0, 0.001) = 0.35;
// Blends neighboring quad flows near cell borders to hide visible quad seams.
uniform bool use_quad_edge_blend = true;
uniform float quad_edge_blend_width : hint_range(0.0, 0.49, 0.001) = 0.12;
uniform float quad_edge_blend_strength : hint_range(0.0, 1.0, 0.001) = 1.0;
// Static cell-density boost near border-mask edges (no camera/radial dependency).
uniform bool use_mask_edge_cell_density = true;
uniform float mask_edge_cell_scale_min : hint_range(0.125, 1.0, 0.001) = 0.35;
uniform float mask_edge_cell_density_power : hint_range(0.1, 8.0, 0.01) = 1.5;
uniform float mask_edge_cell_density_gain : hint_range(0.0, 4.0, 0.001) = 1.0;

// Border steering (optional mask; 0=edge, 1=interior by default) -------------
uniform bool use_border = false;
uniform sampler2D border_mask : source_color;
uniform bool border_mask_invert = false;
// Transforms water UVs before sampling `border_mask` (used for cropped/local masks).
uniform vec2 border_mask_uv_scale = vec2(1.0, 1.0);
uniform vec2 border_mask_uv_offset = vec2(0.0, 0.0);
uniform float border_strength : hint_range(0.0, 8.0, 0.001) = 1.0;
uniform float border_smooth : hint_range(0.05, 8.0, 0.01) = 1.0;
uniform float border_gradient_step_mul : hint_range(0.1, 4.0, 0.01) = 1.0;
uniform float border_influence_gain : hint_range(0.0, 4.0, 0.001) = 1.0;
// Neighbor-aware border steering (extra taps near detected borders).
uniform bool use_neighbor_border_influence = true;
uniform float neighbor_influence_strength : hint_range(0.0, 8.0, 0.001) = 1.0;
uniform float neighbor_influence_blend : hint_range(0.0, 1.0, 0.001) = 0.6;
uniform float neighbor_influence_min_edge : hint_range(0.0, 1.0, 0.001) = 0.02;

// Flow/noise source for procedural fallback ----------------------------------
// 0 = procedural hash noise
// 1 = albedo luminance
// 2 = roughness map
// 3 = AO map
uniform int flow_noise_source : hint_range(0, 3, 1) = 0;
uniform float flow_noise_scale : hint_range(0.01, 256.0, 0.01) = 3.0;
uniform float flow_noise_contrast : hint_range(0.1, 4.0, 0.01) = 1.0;
uniform float flow_noise_bias : hint_range(-1.0, 1.0, 0.001) = 0.0;

// Material maps (drop-in shader equivalents) ---------------------------------
uniform vec4 albedo_color : source_color = vec4(0.18, 0.27, 0.35, 1.0);
uniform sampler2D albedo_tex : source_color;
uniform bool use_albedo_tex = false;
uniform float albedo_tex_mix : hint_range(0.0, 1.0, 0.001) = 1.0;
uniform float albedo_flow_influence : hint_range(0.0, 1.0, 0.001) = 0.6;

uniform sampler2D normal_tex : hint_normal;
uniform bool use_normal_tex = false;
uniform float normal_strength : hint_range(0.0, 8.0, 0.001) = 1.0;
uniform float normal_uv_scale : hint_range(0.01, 128.0, 0.01) = 2.0;
uniform float normal_detail_scale : hint_range(0.1, 32.0, 0.01) = 3.0;
uniform float normal_detail_speed_mul : hint_range(0.0, 8.0, 0.001) = 1.35;
uniform float normal_detail_mix : hint_range(0.0, 1.0, 0.001) = 0.5;
uniform float procedural_normal_strength : hint_range(0.0, 8.0, 0.001) = 0.85;
uniform float procedural_normal_step : hint_range(0.0005, 0.1, 0.0005) = 0.01;

uniform float roughness_base : hint_range(0.0, 1.0, 0.001) = 0.18;
uniform sampler2D roughness_tex;
uniform bool use_roughness_tex = false;
uniform float roughness_tex_mix : hint_range(0.0, 1.0, 0.001) = 1.0;
uniform float roughness_flow_amp : hint_range(0.0, 1.0, 0.001) = 0.12;

uniform float metallic_base : hint_range(0.0, 1.0, 0.001) = 0.0;
uniform sampler2D metallic_tex;
uniform bool use_metallic_tex = false;
uniform float metallic_tex_mix : hint_range(0.0, 1.0, 0.001) = 1.0;

uniform float specular_base : hint_range(0.0, 1.0, 0.001) = 0.5;

uniform float ao_base : hint_range(0.0, 1.0, 0.001) = 1.0;
uniform sampler2D ao_tex;
uniform bool use_ao_tex = false;
uniform float ao_tex_mix : hint_range(0.0, 1.0, 0.001) = 1.0;

uniform vec3 emission_color : source_color = vec3(0.0, 0.0, 0.0);
uniform float emission_energy : hint_range(0.0, 16.0, 0.001) = 0.0;
uniform sampler2D emission_tex : source_color;
uniform bool use_emission_tex = false;
uniform float emission_tex_mix : hint_range(0.0, 1.0, 0.001) = 1.0;

// Edge foam (optional, cheap) ------------------------------------------------
uniform bool use_edge_foam = false;
uniform vec3 foam_color : source_color = vec3(0.85, 0.9, 0.95);
uniform float foam_intensity : hint_range(0.0, 4.0, 0.001) = 0.8;
uniform float foam_edge_bias : hint_range(0.0, 1.0, 0.001) = 0.7;
uniform float foam_noise_scale : hint_range(0.01, 64.0, 0.01) = 8.0;
uniform float foam_noise_cutoff : hint_range(0.0, 1.0, 0.001) = 0.35;

// Debug ----------------------------------------------------------------------
// 0 Off, 1 FlowDir, 2 CellHash, 3 BorderFactor, 4 BorderGradient, 5 Noise,
// 6 Roughness, 7 Normal, 8 UV, 9 CellScale, 10 NeighborInfluence
uniform bool debug_flow = false;
uniform int debug_mode : hint_range(0, 10, 1) = 0;
uniform bool debug_freeze_animation = false;
uniform float debug_time : hint_range(-100000.0, 100000.0, 0.001) = 0.0;

float dfw_hash12(vec2 p) {
	p += vec2(seed * 0.173, seed * 0.619);
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 dfw_hash22(vec2 p) {
	return vec2(
		dfw_hash12(p + vec2(19.19, 73.73)),
		dfw_hash12(p + vec2(91.17, 17.31))
	);
}

float dfw_hash13(vec3 p) {
	p += vec3(seed * 0.097, seed * 0.233, seed * 0.411);
	return fract(sin(dot(p, vec3(12.9898, 78.233, 45.164))) * 43758.5453123);
}

vec2 dfw_safe_normalize2(vec2 v, vec2 fallback_dir) {
	float l = length(v);
	if (l <= DFW_EPS) {
		return fallback_dir;
	}
	return v / l;
}

vec3 dfw_decode_normal(vec3 enc) {
	vec3 n = enc * 2.0 - 1.0;
	n.z = max(n.z, 0.001);
	return normalize(n);
}

vec3 dfw_encode_normal(vec3 n) {
	return clamp(n * 0.5 + 0.5, 0.0, 1.0);
}

float dfw_luma(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

float dfw_value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);

	float a = dfw_hash12(i + vec2(0.0, 0.0));
	float b = dfw_hash12(i + vec2(1.0, 0.0));
	float c = dfw_hash12(i + vec2(0.0, 1.0));
	float d = dfw_hash12(i + vec2(1.0, 1.0));

	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float dfw_sample_border_mask(vec2 uv) {
	vec2 mask_uv = uv * border_mask_uv_scale + border_mask_uv_offset;
	float m = texture(border_mask, mask_uv).r;
	if (border_mask_invert) {
		m = 1.0 - m;
	}
	return clamp(m, 0.0, 1.0);
}

float dfw_time_value() {
	if (debug_freeze_animation) {
		return debug_time;
	}
	if (use_manual_time) {
		return manual_time;
	}
	return TIME * time_scale;
}

float dfw_flow_noise_from_maps(vec2 uv) {
	float v = 0.0;
	if (flow_noise_source == 1) {
		v = dfw_luma(texture(albedo_tex, uv).rgb);
	} else if (flow_noise_source == 2) {
		v = texture(roughness_tex, uv).r;
	} else if (flow_noise_source == 3) {
		v = texture(ao_tex, uv).r;
	} else {
		v = dfw_value_noise(uv);
	}
	v = (v - 0.5) * flow_noise_contrast + 0.5 + flow_noise_bias;
	return clamp(v, 0.0, 1.0);
}

float dfw_sample_flow_noise(vec2 uv_main, vec2 uv_adv) {
	vec2 uv_noise = mix(uv_main, uv_adv, 0.7) * flow_noise_scale;
	return dfw_flow_noise_from_maps(uv_noise);
}

vec2 dfw_compute_continuous_warp(vec2 uv_main) {
	if (continuous_warp_amp <= DFW_EPS) {
		return vec2(0.0);
	}
	float n1 = dfw_value_noise(uv_main * continuous_warp_scale + vec2(seed * 0.1, 17.0));
	float n2 = dfw_value_noise(uv_main * continuous_warp_scale + vec2(37.0, seed * 0.2));
	return (vec2(n1, n2) - 0.5) * 2.0 * continuous_warp_amp;
}

vec2 dfw_cell_flow_dir_for_blend(
	vec2 cell,
	float quad_size,
	vec2 base_flow_dir,
	bool use_quad_random_local,
	bool border_enabled_lod,
	float border_lod_factor,
	float neighbor_distance_factor
) {
	vec2 flow_dir_local = base_flow_dir;
	if (use_quad_random_local && jitter_angle_deg > DFW_EPS) {
		float jitter_angle = radians(jitter_angle_deg) * (dfw_hash12(cell + vec2(3.7, 9.1)) * 2.0 - 1.0);
		float jitter_s = sin(jitter_angle);
		float jitter_c = cos(jitter_angle);
		flow_dir_local = vec2(
			base_flow_dir.x * jitter_c - base_flow_dir.y * jitter_s,
			base_flow_dir.x * jitter_s + base_flow_dir.y * jitter_c
		);
		flow_dir_local = dfw_safe_normalize2(flow_dir_local, base_flow_dir);
	}

	if (!border_enabled_lod) {
		return flow_dir_local;
	}

	vec2 cell_center_uv_local = (cell + vec2(0.5)) * quad_size;
	float border_mask_center_local = dfw_sample_border_mask(cell_center_uv_local);
	float edge_local = clamp(1.0 - border_mask_center_local, 0.0, 1.0);
	float border_factor_local = pow(edge_local, max(border_smooth, 0.05)) * border_influence_gain * border_lod_factor;
	if (border_factor_local <= DFW_EPS) {
		return flow_dir_local;
	}

	float grad_step_local = max(quad_size * border_gradient_step_mul, 0.0005);
	float m_r = dfw_sample_border_mask(cell_center_uv_local + vec2(grad_step_local, 0.0));
	float m_l = dfw_sample_border_mask(cell_center_uv_local - vec2(grad_step_local, 0.0));
	float m_u = dfw_sample_border_mask(cell_center_uv_local + vec2(0.0, grad_step_local));
	float m_d = dfw_sample_border_mask(cell_center_uv_local - vec2(0.0, grad_step_local));
	vec2 border_gradient_local = vec2(m_r - m_l, m_u - m_d);

	float neighbor_influence_factor_local = 0.0;
	if (neighbor_distance_factor > DFW_EPS && edge_local >= neighbor_influence_min_edge) {
		vec2 neighbor_sum = vec2(0.0);
		float neighbor_weight_sum = 0.0;
		for (int oy = -1; oy <= 1; oy++) {
			for (int ox = -1; ox <= 1; ox++) {
				if (ox == 0 && oy == 0) {
					continue;
				}
				vec2 offset_cell = vec2(float(ox), float(oy));
				vec2 offset_uv = cell_center_uv_local + offset_cell * quad_size;
				float m_n = dfw_sample_border_mask(offset_uv);
				float edge_n = clamp(1.0 - m_n, 0.0, 1.0);
				if (edge_n <= DFW_EPS) {
					continue;
				}
				float w_n = edge_n / max(length(offset_cell), 1.0);
				neighbor_sum += normalize(offset_cell) * w_n;
				neighbor_weight_sum += w_n;
			}
		}
		if (neighbor_weight_sum > DFW_EPS) {
			vec2 neighbor_border_gradient_local = (-neighbor_sum / neighbor_weight_sum);
			neighbor_influence_factor_local = neighbor_distance_factor * edge_local * neighbor_influence_strength;
			border_gradient_local = mix(
				border_gradient_local,
				border_gradient_local + neighbor_border_gradient_local * max(quad_size, 0.001),
				clamp(neighbor_influence_blend * neighbor_distance_factor, 0.0, 1.0)
			);
		}
	}

	float g_len_local = length(border_gradient_local);
	if (g_len_local > DFW_EPS) {
		vec2 edge_vec_local = border_gradient_local / g_len_local;
		vec2 edge_side_local = edge_vec_local - flow_dir_local * dot(edge_vec_local, flow_dir_local);
		float steering_gain_local = border_factor_local * border_strength * (1.0 + neighbor_influence_factor_local);
		flow_dir_local = dfw_safe_normalize2(flow_dir_local + edge_side_local * steering_gain_local, flow_dir_local);
	}
	return flow_dir_local;
}

void fragment() {
	vec2 uv_raw = UV;
	float quad_size = max(quad_uv_size, 0.001);
	if (use_mask_edge_cell_density && use_border) {
		float edge_probe = clamp(1.0 - dfw_sample_border_mask(uv_raw), 0.0, 1.0);
		float edge_density = pow(edge_probe, mask_edge_cell_density_power) * mask_edge_cell_density_gain;
		edge_density = clamp(edge_density, 0.0, 1.0);
		float edge_scale = mix(1.0, clamp(mask_edge_cell_scale_min, 0.125, 1.0), edge_density);
		quad_size = max(quad_size * edge_scale, 0.001);
	}

	float border_lod_factor = use_border ? 1.0 : 0.0;
	float detail_lod_factor = 1.0;
	float foam_lod_factor = 1.0;
	float neighbor_distance_factor = (use_neighbor_border_influence && use_border) ? 1.0 : 0.0;
	bool border_enabled_lod = use_border;
	bool detail_enabled_lod = true;
	bool foam_enabled_lod = use_edge_foam;

	vec2 cell = floor(uv_raw / quad_size);
	vec2 cell_center_uv = (cell + vec2(0.5)) * quad_size;

	vec2 base_flow_dir = dfw_safe_normalize2(base_dir, vec2(1.0, 0.0));
	bool use_quad_random = (!sync_global_advection) || allow_quad_randomization;
	vec2 flow_dir = base_flow_dir;
	if (use_quad_random && jitter_angle_deg > DFW_EPS) {
		float jitter_angle = radians(jitter_angle_deg) * (dfw_hash12(cell + vec2(3.7, 9.1)) * 2.0 - 1.0);
		float jitter_s = sin(jitter_angle);
		float jitter_c = cos(jitter_angle);
		flow_dir = vec2(
			base_flow_dir.x * jitter_c - base_flow_dir.y * jitter_s,
			base_flow_dir.x * jitter_s + base_flow_dir.y * jitter_c
		);
		flow_dir = dfw_safe_normalize2(flow_dir, base_flow_dir);
	}

	float border_mask_center = 1.0;
	float border_factor = 0.0;
	vec2 border_gradient = vec2(0.0);
	float neighbor_influence_factor = 0.0;
	vec2 neighbor_border_gradient = vec2(0.0);

	if (border_enabled_lod) {
		border_mask_center = dfw_sample_border_mask(cell_center_uv);
		float edge = clamp(1.0 - border_mask_center, 0.0, 1.0);
		border_factor = pow(edge, max(border_smooth, 0.05)) * border_influence_gain * border_lod_factor;

		float grad_step = max(quad_size * border_gradient_step_mul, 0.0005);
		float m_r = dfw_sample_border_mask(cell_center_uv + vec2(grad_step, 0.0));
		float m_l = dfw_sample_border_mask(cell_center_uv - vec2(grad_step, 0.0));
		float m_u = dfw_sample_border_mask(cell_center_uv + vec2(0.0, grad_step));
		float m_d = dfw_sample_border_mask(cell_center_uv - vec2(0.0, grad_step));

		border_gradient = vec2(m_r - m_l, m_u - m_d);
		if (neighbor_distance_factor > DFW_EPS && edge >= neighbor_influence_min_edge) {
			vec2 neighbor_sum = vec2(0.0);
			float neighbor_weight_sum = 0.0;
			for (int oy = -1; oy <= 1; oy++) {
				for (int ox = -1; ox <= 1; ox++) {
					if (ox == 0 && oy == 0) {
						continue;
					}
					vec2 offset_cell = vec2(float(ox), float(oy));
					vec2 offset_uv = cell_center_uv + offset_cell * quad_size;
					float m_n = dfw_sample_border_mask(offset_uv);
					float edge_n = clamp(1.0 - m_n, 0.0, 1.0);
					if (edge_n <= DFW_EPS) {
						continue;
					}
					float w_n = edge_n / max(length(offset_cell), 1.0);
					neighbor_sum += normalize(offset_cell) * w_n;
					neighbor_weight_sum += w_n;
				}
			}
			if (neighbor_weight_sum > DFW_EPS) {
				neighbor_border_gradient = (-neighbor_sum / neighbor_weight_sum);
				neighbor_influence_factor = neighbor_distance_factor * edge * neighbor_influence_strength;
				border_gradient = mix(border_gradient, border_gradient + neighbor_border_gradient * max(quad_size, 0.001), clamp(neighbor_influence_blend * neighbor_distance_factor, 0.0, 1.0));
			}
		}
		float g_len = length(border_gradient);
		if (g_len > DFW_EPS && border_factor > DFW_EPS) {
			vec2 edge_vec = border_gradient / g_len;
			// Side-only steering avoids reversing the base flow.
			vec2 edge_side = edge_vec - flow_dir * dot(edge_vec, flow_dir);
			float steering_gain = border_factor * border_strength * (1.0 + neighbor_influence_factor);
			flow_dir = dfw_safe_normalize2(flow_dir + edge_side * steering_gain, flow_dir);
		}
	}

	float t = dfw_time_value();
	float speed_per_quad = max(0.0, speed);
	if (use_quad_random && speed_variation > DFW_EPS) {
		float speed_rand = mix(1.0 - speed_variation, 1.0 + speed_variation, dfw_hash12(cell + vec2(21.0, 4.0)));
		speed_per_quad = max(0.0, speed * speed_rand);
	}

	if (use_quad_edge_blend && quad_edge_blend_strength > DFW_EPS && quad_edge_blend_width > DFW_EPS) {
		float blend_cell_size = max(quad_uv_size, 0.001);
		vec2 blend_cell = floor(uv_raw / blend_cell_size);
		vec2 local_cell_uv = fract(uv_raw / blend_cell_size);
		float blend_w = clamp(quad_edge_blend_width, 0.001, 0.49);
		float w_left = 1.0 - smoothstep(0.0, blend_w, local_cell_uv.x);
		float w_right = smoothstep(1.0 - blend_w, 1.0, local_cell_uv.x);
		float w_down = 1.0 - smoothstep(0.0, blend_w, local_cell_uv.y);
		float w_up = smoothstep(1.0 - blend_w, 1.0, local_cell_uv.y);
		vec2 flow_accum = flow_dir;
		float weight_accum = 1.0;

		// Edge neighbors.
		if (w_left > DFW_EPS) {
			vec2 c = blend_cell + vec2(-1.0, 0.0);
			float ww = w_left * quad_edge_blend_strength;
			flow_accum += dfw_cell_flow_dir_for_blend(c, blend_cell_size, base_flow_dir, use_quad_random, border_enabled_lod, border_lod_factor, neighbor_distance_factor) * ww;
			weight_accum += ww;
		}
		if (w_right > DFW_EPS) {
			vec2 c = blend_cell + vec2(1.0, 0.0);
			float ww = w_right * quad_edge_blend_strength;
			flow_accum += dfw_cell_flow_dir_for_blend(c, blend_cell_size, base_flow_dir, use_quad_random, border_enabled_lod, border_lod_factor, neighbor_distance_factor) * ww;
			weight_accum += ww;
		}
		if (w_down > DFW_EPS) {
			vec2 c = blend_cell + vec2(0.0, -1.0);
			float ww = w_down * quad_edge_blend_strength;
			flow_accum += dfw_cell_flow_dir_for_blend(c, blend_cell_size, base_flow_dir, use_quad_random, border_enabled_lod, border_lod_factor, neighbor_distance_factor) * ww;
			weight_accum += ww;
		}
		if (w_up > DFW_EPS) {
			vec2 c = blend_cell + vec2(0.0, 1.0);
			float ww = w_up * quad_edge_blend_strength;
			flow_accum += dfw_cell_flow_dir_for_blend(c, blend_cell_size, base_flow_dir, use_quad_random, border_enabled_lod, border_lod_factor, neighbor_distance_factor) * ww;
			weight_accum += ww;
		}

		if (weight_accum > DFW_EPS) {
			flow_dir = dfw_safe_normalize2(flow_accum / weight_accum, flow_dir);
		}
	}

	vec2 uv_main = uv_raw * uv_scale + uv_offset;
	vec2 uv_adv = uv_main + flow_dir * (t * speed_per_quad);

	vec2 per_quad_warp = vec2(0.0);
	if (!sync_global_advection && per_quad_warp_amp > DFW_EPS) {
		per_quad_warp = (dfw_hash22(cell + vec2(101.0, 47.0)) - 0.5) * 2.0 * per_quad_warp_amp;
	}
	vec2 continuous_warp = dfw_compute_continuous_warp(uv_main + vec2(t * 0.03, t * 0.02));
	uv_adv += mix(per_quad_warp, continuous_warp, per_quad_warp_detail_mix) + continuous_warp;

	vec2 uv_detail = uv_main * normal_detail_scale + flow_dir * (t * speed_per_quad * normal_detail_speed_mul);
	vec2 uv_normal_a = uv_adv * normal_uv_scale;
	vec2 uv_normal_b = uv_detail * normal_uv_scale;

	float flow_noise = dfw_sample_flow_noise(uv_main, uv_adv);

	vec3 tangent_normal = vec3(0.0, 0.0, 1.0);
	if (use_normal_tex) {
		vec3 n_a = dfw_decode_normal(texture(normal_tex, uv_normal_a).xyz);
		vec3 n_mix = n_a;
		if (detail_enabled_lod && normal_detail_mix > DFW_EPS) {
			vec3 n_b = dfw_decode_normal(texture(normal_tex, uv_normal_b).xyz);
			n_mix = normalize(mix(n_a, n_b, normal_detail_mix * detail_lod_factor));
		}
		tangent_normal = n_mix;
	} else {
		if (detail_enabled_lod) {
			float step_uv = max(procedural_normal_step, 0.0005);
			float h_l = dfw_sample_flow_noise(uv_main, uv_adv - vec2(step_uv, 0.0));
			float h_r = dfw_sample_flow_noise(uv_main, uv_adv + vec2(step_uv, 0.0));
			float h_d = dfw_sample_flow_noise(uv_main, uv_adv - vec2(0.0, step_uv));
			float h_u = dfw_sample_flow_noise(uv_main, uv_adv + vec2(0.0, step_uv));
			vec2 grad = vec2(h_l - h_r, h_d - h_u) * procedural_normal_strength * detail_lod_factor;
			tangent_normal = normalize(vec3(grad.x, grad.y, 1.0));
		}
	}

	NORMAL_MAP = dfw_encode_normal(tangent_normal);
	NORMAL_MAP_DEPTH = max(normal_strength, 0.0);

	vec4 albedo_sample = texture(albedo_tex, mix(uv_main, uv_adv, albedo_flow_influence));
	vec3 albedo_tex_rgb = mix(vec3(1.0), albedo_sample.rgb, albedo_tex_mix);
	vec3 final_albedo = albedo_color.rgb;
	if (use_albedo_tex) {
		final_albedo *= albedo_tex_rgb;
	}

	float roughness_value = roughness_base;
	if (use_roughness_tex) {
		float r_tex = texture(roughness_tex, uv_adv).r;
		roughness_value = mix(roughness_value, r_tex, roughness_tex_mix);
	}
	roughness_value = clamp(roughness_value + (flow_noise - 0.5) * 2.0 * roughness_flow_amp, 0.0, 1.0);

	float metallic_value = metallic_base;
	if (use_metallic_tex) {
		metallic_value = mix(metallic_value, texture(metallic_tex, uv_adv).r, metallic_tex_mix);
	}
	metallic_value = clamp(metallic_value, 0.0, 1.0);

	float ao_value = ao_base;
	if (use_ao_tex) {
		ao_value = mix(ao_value, texture(ao_tex, uv_adv).r, ao_tex_mix);
	}
	ao_value = clamp(ao_value, 0.0, 1.0);

	vec3 emission_value = emission_color * emission_energy;
	if (use_emission_tex) {
		vec3 e_tex = texture(emission_tex, uv_adv).rgb;
		emission_value *= mix(vec3(1.0), e_tex, emission_tex_mix);
	}

	if (foam_enabled_lod) {
		float edge_term = pow(clamp(1.0 - border_mask_center, 0.0, 1.0), max(foam_edge_bias * 4.0, 0.001));
		float foam_n = dfw_value_noise(uv_adv * foam_noise_scale + vec2(seed * 0.01, seed * 0.02));
		float foam_mask = edge_term * step(foam_noise_cutoff, foam_n);
		final_albedo = mix(final_albedo, foam_color, clamp(foam_mask * foam_intensity * foam_lod_factor, 0.0, 1.0));
	}

	int dbg = debug_flow ? 1 : debug_mode;
	vec3 debug_color = vec3(0.0);
	if (dbg == 1) {
		debug_color = vec3(flow_dir * 0.5 + 0.5, 0.0);
	} else if (dbg == 2) {
		float h = dfw_hash12(cell + vec2(0.3, 0.7));
		debug_color = vec3(h, fract(h * 7.0), fract(h * 13.0));
	} else if (dbg == 3) {
		debug_color = vec3(border_factor);
	} else if (dbg == 4) {
		vec2 g = dfw_safe_normalize2(border_gradient, vec2(0.0));
		debug_color = vec3(g * 0.5 + 0.5, border_mask_center);
	} else if (dbg == 5) {
		debug_color = vec3(flow_noise);
	} else if (dbg == 6) {
		debug_color = vec3(roughness_value);
	} else if (dbg == 7) {
		debug_color = tangent_normal * 0.5 + 0.5;
	} else if (dbg == 8) {
		debug_color = vec3(fract(uv_adv.x), fract(uv_adv.y), 0.0);
	} else if (dbg == 9) {
		float cell_scale_ratio = clamp(quad_size / max(quad_uv_size, 0.001), 0.0, 1.0);
		float edge_probe_dbg = use_border ? clamp(1.0 - dfw_sample_border_mask(uv_raw), 0.0, 1.0) : 0.0;
		debug_color = vec3(cell_scale_ratio, edge_probe_dbg, use_mask_edge_cell_density ? 1.0 : 0.0);
	} else if (dbg == 10) {
		vec2 ng = dfw_safe_normalize2(neighbor_border_gradient, vec2(0.0));
		debug_color = vec3(ng * 0.5 + 0.5, clamp(neighbor_influence_factor, 0.0, 1.0));
	}

	if (dbg > 0) {
		ALBEDO = debug_color;
		ROUGHNESS = 1.0;
		METALLIC = 0.0;
		SPECULAR = 0.0;
		AO = 1.0;
		EMISSION = vec3(0.0);
		ALPHA = 1.0;
	} else {
		if (!dfw_enabled) {
			// Preserve material sampling but disable flow advection.
			vec4 base_no_flow = texture(albedo_tex, uv_main);
			vec3 albedo_no_flow = albedo_color.rgb;
			if (use_albedo_tex) {
				albedo_no_flow *= mix(vec3(1.0), base_no_flow.rgb, albedo_tex_mix);
			}
			ALBEDO = albedo_no_flow;
		} else {
			ALBEDO = final_albedo;
		}
		ROUGHNESS = roughness_value;
		METALLIC = metallic_value;
		SPECULAR = clamp(specular_base, 0.0, 1.0);
		AO = ao_value;
		EMISSION = emission_value;
		ALPHA = albedo_color.a;
	}
}
