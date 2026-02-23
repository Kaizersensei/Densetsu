shader_type sky;

uniform sampler2D hour_gradient: hint_default_white, filter_linear;
uniform float time_hours: hint_range(0.0, 24.0, 0.01) = 12.0;
uniform float day_of_year: hint_range(1.0, 366.0, 1.0) = 172.0;
uniform float days_per_year: hint_range(1.0, 1000.0, 1.0) = 365.0;
uniform float horizon_shift_hours: hint_range(-12.0, 12.0, 0.01) = -1.5;
uniform float sky_intensity: hint_range(0.0, 8.0, 0.01) = 1.0;
uniform float horizon_exponent: hint_range(0.1, 8.0, 0.01) = 1.65;
uniform vec3 sun_direction = vec3(0.0, 0.7071068, -0.7071068);
uniform vec3 moon_direction = vec3(0.0, -0.7071068, 0.7071068);
uniform float moon_phase: hint_range(0.0, 1.0, 0.0001) = 0.5;
uniform float sun_visibility: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float moon_visibility: hint_range(0.0, 1.0, 0.01) = 1.0;

uniform vec4 sun_tint: source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform float sun_disk_size: hint_range(0.001, 0.25, 0.001) = 0.035;
uniform float sun_glow_size: hint_range(0.0, 2.0, 0.001) = 0.45;
uniform float sun_falloff: hint_range(0.5, 64.0, 0.1) = 18.0;
uniform float sun_brightness: hint_range(0.0, 128.0, 0.1) = 9.0;
uniform vec4 moon_tint: source_color = vec4(0.65, 0.78, 1.0, 1.0);
uniform float moon_disk_size: hint_range(0.001, 0.2, 0.001) = 0.02;
uniform float moon_brightness: hint_range(0.0, 8.0, 0.01) = 0.8;
uniform float moon_phase_softness: hint_range(0.001, 0.2, 0.001) = 0.02;
uniform float moon_earthshine: hint_range(0.0, 0.5, 0.001) = 0.08;
uniform bool moon_lock_phase_orientation = true;
uniform sampler2D moon_surface_texture: hint_default_white, filter_linear, repeat_enable;
uniform vec4 moon_surface_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec2 moon_surface_uv_scale = vec2(1.0, 1.0);
uniform vec2 moon_surface_uv_offset = vec2(0.0, 0.0);

uniform sampler2D cloud_group_texture: hint_default_white, filter_linear, repeat_enable;
uniform float cloud_group_opacity: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float cloud_group_brightness: hint_range(0.0, 8.0, 0.01) = 1.0;
uniform float cloud_group_contrast: hint_range(0.1, 4.0, 0.01) = 1.0;
uniform vec2 cloud_uv_offset = vec2(0.0, 0.0);
uniform float cloud_seam_blend_width: hint_range(0.0, 0.2, 0.0001) = 0.01;

uniform vec4 fog_shift_color: source_color = vec4(0.6, 0.7, 0.8, 1.0);
uniform float fog_shift_amount: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform vec4 weather_shift_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float weather_shift_amount: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform vec4 weather_override_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float weather_override_amount: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float weather_mask: hint_range(0.0, 1.0, 0.01) = 1.0;
uniform bool stars_enabled = true;
uniform float stars_density: hint_range(0.0, 1.0, 0.001) = 0.28;
uniform float stars_brightness: hint_range(0.0, 8.0, 0.01) = 1.15;
uniform float stars_size: hint_range(0.25, 3.0, 0.01) = 1.0;
uniform float stars_twinkle_speed: hint_range(0.0, 5.0, 0.01) = 0.35;
uniform float stars_seed = 1337.0;

const float TWO_PI = PI * 2.0;

vec2 dir_to_equirect_uv(vec3 n) {
	vec3 dir = normalize(n);
	float u = atan(dir.x, dir.z) / TWO_PI + 0.5;
	float v = asin(clamp(dir.y, -1.0, 1.0)) / PI + 0.5;
	return vec2(u, v);
}

vec3 sample_hour_color(float hour_offset) {
	float wrapped_hours = mod(time_hours + hour_offset, 24.0);
	float t = wrapped_hours / 24.0;
	return texture(hour_gradient, vec2(t, 0.5)).rgb;
}

vec3 safe_normalize(vec3 value, vec3 fallback) {
	float len = length(value);
	if (len < 0.000001) {
		return fallback;
	}
	return value / len;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float sample_stars(vec3 dir, float night_visibility) {
	if (!stars_enabled) {
		return 0.0;
	}
	float density = clamp(stars_density, 0.0, 1.0);
	if (density <= 0.0001) {
		return 0.0;
	}
	vec2 uv = dir_to_equirect_uv(dir);
	float base_scale = mix(160.0, 2200.0, density);
	vec2 grid_size = vec2(base_scale * 2.0, base_scale);
	vec2 grid_uv = uv * grid_size;
	vec2 cell = floor(grid_uv);
	vec2 local = fract(grid_uv) - 0.5;
	float seed = stars_seed * 0.0001;
	float random_value = hash12(cell + vec2(seed, seed * 1.61803));
	float threshold = mix(0.9994, 0.965, density);
	float present = step(threshold, random_value);
	float twinkle = 0.65 + 0.35 * sin(TIME * stars_twinkle_speed + random_value * TWO_PI);
	float star_radius = max(0.01, 0.35 / max(stars_size, 0.001));
	float radial = 1.0 - smoothstep(star_radius, star_radius * 1.8, length(local));
	float brightness_rand = mix(0.4, 1.0, hash12(cell + vec2(17.13, 91.7)));
	float horizon_fade = smoothstep(-0.2, 0.2, dir.y);
	return present * radial * twinkle * brightness_rand * horizon_fade * night_visibility * stars_brightness;
}

vec4 sample_cloud_wrapped(vec2 uv) {
	vec2 wrapped_uv = fract(uv);
	vec2 grad_x = dFdx(uv);
	vec2 grad_y = dFdy(uv);
	// Horizontal UV is periodic; wrap derivatives to avoid seam LOD spikes.
	grad_x.x -= round(grad_x.x);
	grad_y.x -= round(grad_y.x);
	vec4 center = textureGrad(cloud_group_texture, wrapped_uv, grad_x, grad_y);
	float seam_width = clamp(cloud_seam_blend_width, 0.0, 0.25);
	if (seam_width <= 0.000001) {
		return center;
	}
	float distance_to_seam = min(wrapped_uv.x, 1.0 - wrapped_uv.x);
	float seam_mix = 1.0 - smoothstep(0.0, seam_width, distance_to_seam);
	// Mirror across the seam so right edge samples left edge and vice versa.
	float opposite_x = 1.0 - wrapped_uv.x;
	vec2 opposite_grad_x = vec2(-grad_x.x, grad_x.y);
	vec2 opposite_grad_y = vec2(-grad_y.x, grad_y.y);
	vec4 opposite = textureGrad(cloud_group_texture, vec2(opposite_x, wrapped_uv.y), opposite_grad_x, opposite_grad_y);
	// Pull both sides toward a shared midpoint at the seam to avoid directional "slide".
	vec4 seam_mid = (center + opposite) * 0.5;
	return mix(center, seam_mid, seam_mix);
}

void sky() {
	vec3 view_dir = normalize(EYEDIR);
	vec3 sun_dir = safe_normalize(sun_direction, vec3(0.0, 1.0, 0.0));
	vec3 moon_dir = safe_normalize(moon_direction, -sun_dir);
	float up = clamp(view_dir.y * 0.5 + 0.5, 0.0, 1.0);
	float horizon_mix = pow(1.0 - abs(view_dir.y), horizon_exponent);

	vec3 top_color = sample_hour_color(0.0);
	vec3 horizon_color = sample_hour_color(horizon_shift_hours);
	vec3 sky_color = mix(top_color, horizon_color, horizon_mix) * sky_intensity;
	float safe_days_per_year = max(days_per_year, 1.0);
	float seasonal_shift = 0.02 * sin((day_of_year / safe_days_per_year) * TWO_PI);
	sky_color *= 1.0 + seasonal_shift;

	float sun_dot = clamp(dot(view_dir, sun_dir), 0.0, 1.0);
	float sun_core = smoothstep(1.0 - sun_disk_size, 1.0, sun_dot);
	float sun_glow = pow(sun_dot, sun_falloff) * sun_glow_size;
	vec3 sun_color = sun_tint.rgb * (sun_core + sun_glow) * sun_brightness * clamp(sun_visibility, 0.0, 1.0);

	vec3 fallback_axis = abs(moon_dir.y) > 0.99 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
	vec3 moon_right = normalize(cross(fallback_axis, moon_dir));
	vec3 moon_up = normalize(cross(moon_dir, moon_right));
	float moon_radius_sin = max(sin(moon_disk_size), 0.00001);
	float moon_x = dot(view_dir, moon_right) / moon_radius_sin;
	float moon_y = dot(view_dir, moon_up) / moon_radius_sin;
	float moon_rr = moon_x * moon_x + moon_y * moon_y;
	float moon_mask = 1.0 - smoothstep(0.92, 1.0, moon_rr);
	vec2 moon_uv_centered = vec2(moon_x, -moon_y) * 0.5;
	vec2 moon_uv = moon_uv_centered * moon_surface_uv_scale + vec2(0.5, 0.5) + moon_surface_uv_offset;
	vec3 moon_surface_sample_color = texture(moon_surface_texture, moon_uv).rgb * moon_surface_color.rgb;
	float moon_z = sqrt(max(1.0 - moon_rr, 0.0));
	vec2 moon_light_dir_2d = vec2(dot(-sun_dir, moon_right), dot(-sun_dir, moon_up));
	if (moon_lock_phase_orientation) {
		// Lock lit side to phase progression instead of sky basis rotation.
		float lit_side = moon_phase < 0.5 ? 1.0 : -1.0;
		moon_light_dir_2d = vec2(lit_side, 0.0);
	}
	float light_2d_len = length(moon_light_dir_2d);
	if (light_2d_len < 0.00001) {
		moon_light_dir_2d = vec2(1.0, 0.0);
	} else {
		moon_light_dir_2d /= light_2d_len;
	}
	float phase_z = -cos(moon_phase * TWO_PI);
	float phase_xy = sqrt(max(1.0 - phase_z * phase_z, 0.0));
	vec3 phase_light = normalize(vec3(moon_light_dir_2d * phase_xy, phase_z));
	vec3 moon_local_normal = vec3(moon_x, -moon_y, moon_z);
	float moon_lit_signed = dot(moon_local_normal, phase_light);
	float lit_mask = smoothstep(-moon_phase_softness, moon_phase_softness, moon_lit_signed);
	float moon_shape = mix(moon_earthshine, 1.0, lit_mask);
	vec3 moon_color = moon_tint.rgb * moon_surface_sample_color * moon_shape * moon_mask * moon_brightness * clamp(moon_visibility, 0.0, 1.0);

	float night_visibility = 1.0 - smoothstep(-0.25, 0.05, sun_dir.y);
	float stars = sample_stars(view_dir, night_visibility);

	vec3 celestial_mix = sky_color + vec3(stars) + sun_color + moon_color;

	vec2 cloud_uv = dir_to_equirect_uv(view_dir) + cloud_uv_offset;
	vec4 cloud_sample = sample_cloud_wrapped(cloud_uv);
	float cloud_alpha = clamp(cloud_sample.a, 0.0, 1.0);
	float cloud_luma = dot(cloud_sample.rgb, vec3(0.3333333));
	float cloud_contrast_value = clamp((cloud_luma - 0.5) * cloud_group_contrast + 0.5, 0.0, 1.0);
	float sky_visibility = smoothstep(-0.15, 0.2, view_dir.y);
	float cloud_mix = cloud_alpha * cloud_contrast_value * cloud_group_opacity * sky_visibility;
	vec3 cloud_color = cloud_sample.rgb * cloud_group_brightness;

	vec3 layered = mix(celestial_mix, cloud_color, cloud_mix);

	float horizon_fog_mask = pow(1.0 - up, 2.0);
	// At low values, keep fog near the horizon. At high values, expand to full-sky coverage.
	float fog_coverage = smoothstep(0.65, 1.0, fog_shift_amount);
	float fog_mask = mix(horizon_fog_mask, 1.0, fog_coverage);
	float fog_amount = clamp(fog_shift_amount * fog_mask, 0.0, 1.0);
	// Tint and softly haze the sky instead of fully covering it.
	vec3 fog_tint = layered * mix(vec3(1.0), fog_shift_color.rgb, 0.75);
	vec3 fog_haze = mix(fog_tint, (fog_tint + fog_shift_color.rgb) * 0.5, 0.2);
	layered = mix(layered, fog_haze, fog_amount);

	layered = mix(layered, layered * weather_shift_color.rgb, weather_shift_amount * weather_mask);
	layered = mix(layered, weather_override_color.rgb, weather_override_amount * weather_mask);

	COLOR = layered;
}
