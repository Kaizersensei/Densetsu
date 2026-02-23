shader_type spatial;

// Mesh skew axis: this is the axis used to read per-vertex position for the bend mask.
uniform int skew_axis : hint_enum("X", "Y", "Z") = 1;

// Direction the mesh is pushed toward while bending.
uniform vec3 skew_direction = vec3(1.0, 0.0, 0.0);

// Angle range in degrees.
uniform float angle_min_deg : hint_range(-90.0, 90.0, 0.1) = -4.0;
uniform float angle_max_deg : hint_range(-90.0, 90.0, 0.1) = 6.0;

// One full oscillation length in seconds.
uniform float sine_period : hint_range(0.01, 120.0, 0.01) = 2.0;

// Optional phase offset if you want variation between materials.
uniform float phase_offset : hint_range(-6.28318, 6.28318, 0.001) = 0.0;
uniform float instance_phase_jitter : hint_range(0.0, 6.28318, 0.001) = 1.2;

// Pivot along selected axis. Usually 0.0 if mesh base is near origin.
uniform float pivot = 0.0;

// Falloff controls.
// false = uniform (all vertices affected equally)
// true  = weighted by selected axis position and curve.
uniform bool weighted_falloff = true;
uniform float falloff_min = 0.0;
uniform float falloff_max = 1.0;
uniform float falloff_curve : hint_range(0.01, 8.0, 0.01) = 1.5;

// Optional world-space desync so nearby meshes do not move in perfect sync.
uniform bool use_world_noise = true;
uniform float noise_scale : hint_range(0.001, 10.0, 0.001) = 0.2;
uniform float noise_speed : hint_range(0.0, 10.0, 0.01) = 0.6;
uniform float noise_phase_strength : hint_range(0.0, 6.28318, 0.001) = 1.1;
uniform float noise_amplitude_strength : hint_range(0.0, 1.0, 0.001) = 0.3;


float _axis_value(vec3 v, int axis_id) {
	if (axis_id == 0) {
		return v.x;
	}
	if (axis_id == 1) {
		return v.y;
	}
	return v.z;
}


vec3 _axis_vector(int axis_id) {
	if (axis_id == 0) {
		return vec3(1.0, 0.0, 0.0);
	}
	if (axis_id == 1) {
		return vec3(0.0, 1.0, 0.0);
	}
	return vec3(0.0, 0.0, 1.0);
}

float _hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float _value_noise(vec2 uv) {
	vec2 i = floor(uv);
	vec2 f = fract(uv);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = _hash12(i + vec2(0.0, 0.0));
	float b = _hash12(i + vec2(1.0, 0.0));
	float c = _hash12(i + vec2(0.0, 1.0));
	float d = _hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}


void vertex() {
	float period = max(sine_period, 0.01);
	float phase = (TIME / period) * 6.28318530718 + phase_offset;

	// Stable per-instance jitter derived from object world origin.
	vec3 obj_origin = vec3(MODEL_MATRIX[3].x, MODEL_MATRIX[3].y, MODEL_MATRIX[3].z);
	float instance_rand = _hash12(obj_origin.xz * 0.173);
	phase += (instance_rand * 2.0 - 1.0) * instance_phase_jitter;

	float amp = 1.0;
	if (use_world_noise) {
		vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		vec2 noise_uv = world_pos.xz * noise_scale + vec2(TIME * noise_speed, TIME * noise_speed * 0.37);
		float n = _value_noise(noise_uv); // 0..1
		phase += (n * 2.0 - 1.0) * noise_phase_strength;
		amp = mix(1.0 - noise_amplitude_strength, 1.0 + noise_amplitude_strength, n);
	}

	float osc01 = sin(phase) * 0.5 + 0.5;
	float angle_rad = radians(mix(angle_min_deg, angle_max_deg, osc01) * amp);

	float axis_pos = _axis_value(VERTEX, skew_axis);
	float axis_distance = axis_pos - pivot;

	float falloff = 1.0;
	if (weighted_falloff) {
		float span = max(abs(falloff_max - falloff_min), 0.0001);
		float t = clamp((axis_pos - falloff_min) / span, 0.0, 1.0);
		falloff = pow(t, max(falloff_curve, 0.01));
	}

	vec3 axis_vec = _axis_vector(skew_axis);
	vec3 dir = skew_direction;

	// Remove axis component so skew stays orthogonal to the selected axis.
	dir -= axis_vec * dot(dir, axis_vec);
	float dir_len = length(dir);
	if (dir_len < 0.0001) {
		return;
	}
	dir /= dir_len;

	// Shear-like skew: displacement grows with distance from pivot.
	VERTEX += dir * (axis_distance * tan(angle_rad) * falloff);
}
