shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D albedo_texture : source_color, hint_default_white, filter_linear, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);
uniform vec2 uv_scroll = vec2(0.0, 0.0);
uniform float time_seconds = 0.0;
uniform vec2 material_uv_scale = vec2(1.0, 1.0);
uniform vec2 material_uv_offset = vec2(0.0, 0.0);

void fragment() {
	vec2 base_uv = UV * material_uv_scale + material_uv_offset;
	vec2 mapped_uv = base_uv * uv_scale + uv_offset + uv_scroll * time_seconds;
	vec4 tex = texture(albedo_texture, mapped_uv);
	COLOR = tex * albedo_color;
}
