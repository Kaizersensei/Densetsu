@tool
extends Node3D
class_name DensetsuSkySystem3D

const SKY_SHADER_PATH: String = "res://shaders/sky/densetsu_sky.gdshader"
const CLOUD_BASE_MATERIAL_ADAPTER_SHADER_PATH: String = "res://shaders/sky/cloud_layer_base_material_adapter.gdshader"
const CLOUD_VIEWPORT_NODE_NAME: String = "_CloudCompositeViewport"
const CLOUD_CANVAS_NODE_NAME: String = "_CloudCanvasRoot"
const MOON_SURFACE_VIEWPORT_NODE_NAME: String = "_MoonSurfaceViewport"
const MOON_SURFACE_CANVAS_NODE_NAME: String = "_MoonSurfaceCanvas"
const MOON_SURFACE_RECT_NODE_NAME: String = "_MoonSurfaceRect"
const MOON_SURFACE_3D_ROOT_NODE_NAME: String = "_MoonSurface3DRoot"
const MOON_SURFACE_3D_ENV_NODE_NAME: String = "_MoonSurfaceWorldEnvironment"
const MOON_SURFACE_3D_CAMERA_NODE_NAME: String = "_MoonSurfaceCamera3D"
const MOON_SURFACE_3D_MESH_NODE_NAME: String = "_MoonSurfaceMesh3D"
const MOON_SURFACE_3D_LIGHT_NODE_NAME: String = "_MoonSurfaceLight3D"
const WEATHER_ROOT_NODE_NAME: String = "_WeatherTiers"
const WEATHER_NEAR_NODE_NAME: String = "NearTier"
const WEATHER_MID_NODE_NAME: String = "MidTier"
const WEATHER_FAR_NODE_NAME: String = "FarTier"
const LIGHTNING_OVERLAY_LAYER_NODE_NAME: String = "_LightningOverlayLayer"
const LIGHTNING_OVERLAY_ROOT_NODE_NAME: String = "_LightningOverlayRoot"
const LIGHTNING_BOLT_NODE_NAME: String = "_LightningBolt"
const SKY_DEBUG_UI_LAYER_NODE_NAME: String = "_SkyDebugUI"

@export_group("Targets")
## Path to the WorldEnvironment this system should control.
@export var world_environment_path: NodePath = NodePath("")
## Path to the main directional sun light.
@export var sun_light_path: NodePath = NodePath("")
## Optional path to a directional moon light used for night lighting.
@export var moon_light_path: NodePath = NodePath("")
## Optional camera path used for weather tiers and indoor checks.
@export var weather_camera_path: NodePath = NodePath("")
## Finds WorldEnvironment/DirectionalLight3D automatically when paths fail.
@export var auto_find_targets: bool = true
## Replaces Environment.sky with the Densetsu sky material.
@export var apply_sky_to_environment: bool = true

@export_group("Clock Source")
## Path to DensetsuSkyClock node.
@export var clock_path: NodePath = NodePath("Clock")
## Creates a child DensetsuSkyClock if missing.
@export var auto_create_clock: bool = true
## Uses clock time instead of manual_time_hours.
@export var use_clock_time: bool = true
## Manual fallback time (hours, 0-24) when not using clock.
@export_range(0.0, 24.0, 0.001) var manual_time_hours: float = 12.0

@export_group("Clock Controls")
## Mirrors DensetsuSkyClock.running for top-level control.
@export var clock_running: bool = true
## Mirrors DensetsuSkyClock.editor_preview.
@export var clock_editor_preview: bool = false
## Mirrors DensetsuSkyClock.minutes_per_real_second.
@export_range(0.0, 1200.0, 0.01) var clock_minutes_per_real_second: float = 10.0
## Mirrors DensetsuSkyClock.year.
@export var clock_year: int = 1
## Mirrors DensetsuSkyClock.month.
@export_range(1, 12, 1) var clock_month: int = 1
## Mirrors DensetsuSkyClock.day.
@export_range(1, 31, 1) var clock_day: int = 1
## Mirrors DensetsuSkyClock.month_lengths.
@export var clock_month_lengths: PackedInt32Array = PackedInt32Array([31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31])
## Mirrors DensetsuSkyClock.hour.
@export_range(0, 23, 1) var clock_hour: int = 12
## Mirrors DensetsuSkyClock.minute.
@export_range(0, 59, 1) var clock_minute: int = 0
## Mirrors DensetsuSkyClock.second.
@export_range(0, 59, 1) var clock_second: int = 0

@export_group("Preview")
## Time multiplier for cloud UV scrolling.
@export_range(0.0, 50.0, 0.01) var cloud_time_scale: float = 1.0
## Applies updates while editing in the editor viewport.
@export var editor_preview: bool = true

@export_group("Sky Gradient")
## Gradient sampled across 24 hours (wraps).
@export var hour_gradient: GradientTexture1D
## Auto-creates a default 24-step gradient when hour_gradient is null.
@export var use_default_hour_gradient: bool = true
## Horizon color sampling offset in hours.
@export_range(-12.0, 12.0, 0.01) var horizon_shift_hours: float = -1.5
## Overall sky intensity multiplier.
@export_range(0.0, 8.0, 0.01) var sky_intensity: float = 1.0
## Horizon blend curvature.
@export_range(0.1, 8.0, 0.01) var horizon_exponent: float = 1.65

@export_group("Sun And Moon")
## Sky-visible sun tint.
@export var sun_tint: Color = Color(1.0, 0.95, 0.85, 1.0)
## Apparent sun disk size in sky shader.
@export_range(0.001, 0.25, 0.001) var sun_disk_size: float = 0.035
## Sun glow halo strength.
@export_range(0.0, 2.0, 0.001) var sun_glow_size: float = 0.45
## Sun falloff exponent (higher = tighter glow).
@export_range(0.5, 64.0, 0.1) var sun_falloff: float = 18.0
## Sky sun brightness multiplier.
@export_range(0.0, 128.0, 0.1) var sun_brightness: float = 9.0
## Sky-visible moon tint.
@export var moon_tint: Color = Color(0.65, 0.78, 1.0, 1.0)
## Apparent moon disk size.
@export_range(0.001, 0.2, 0.001) var moon_disk_size: float = 0.02
## Moon brightness multiplier.
@export_range(0.0, 8.0, 0.01) var moon_brightness: float = 0.8
## Softness of the moon phase terminator edge (flat-disc phase model).
@export_range(0.001, 0.2, 0.001) var moon_phase_softness: float = 0.02
## Minimum moon brightness on the dark side.
@export_range(0.0, 0.5, 0.001) var moon_earthshine: float = 0.08
## Uses flat-disc moon shading and prefers direct material albedo extraction.
@export var moon_flat_sprite_mode: bool = true
## Locks moon phase orientation to phase cycle (prevents midnight side flips).
@export var moon_lock_phase_orientation: bool = true
## Applies sun energy changes to the directional light.
@export var sync_sun_light_energy: bool = true
## Applies sun tint to directional light color.
@export var sync_sun_light_color: bool = true
## Rotates directional light to the computed sun direction (Z axis treated as north/south).
@export var sync_sun_light_direction: bool = true
## Global multiplier over captured base directional light energy.
@export_range(0.0, 8.0, 0.01) var sun_light_energy_multiplier: float = 1.0
## Makes sun directional energy follow computed sun visibility.
@export var sun_light_use_visibility: bool = true
## Additional sun dimming driven by moon visibility (0 disables, 1 full dim at full moon visibility).
@export_range(0.0, 1.0, 0.01) var sun_light_dim_by_moon: float = 1.0
## Applies moon energy changes to the moon directional light.
@export var sync_moon_light_energy: bool = true
## Applies moon tint to the moon directional light color.
@export var sync_moon_light_color: bool = true
## Rotates moon directional light to the computed moon direction.
@export var sync_moon_light_direction: bool = true
## Global multiplier over captured base moon light energy.
@export_range(0.0, 8.0, 0.01) var moon_light_energy_multiplier: float = 1.0
## Makes moon directional energy follow computed moon visibility.
@export var moon_light_use_visibility: bool = true
## Keeps synced directional lights shadow-enabled while sky/weather controls are active.
@export var keep_synced_light_shadows_enabled: bool = true
## Minimum fallback base energy used if captured sun light energy is near zero.
@export_range(0.0, 8.0, 0.01) var minimum_sun_base_energy: float = 1.0
## Minimum fallback base energy used if captured moon light energy is near zero.
@export_range(0.0, 8.0, 0.01) var minimum_moon_base_energy: float = 0.0
## Minimum sun directional energy when sun visibility is above zero.
@export_range(0.0, 8.0, 0.01) var sun_light_min_visible_energy: float = 0.2
## Smoothing speed for directional light direction updates.
@export_range(0.0, 30.0, 0.01) var light_direction_smooth_speed: float = 8.0
## Smoothing speed for directional light energy updates.
@export_range(0.0, 30.0, 0.01) var light_energy_smooth_speed: float = 10.0
## Smoothing speed for directional light color updates.
@export_range(0.0, 30.0, 0.01) var light_color_smooth_speed: float = 10.0
## Sun is visible/moving only inside this daily range.
@export_range(0.0, 24.0, 0.001) var sun_active_start_hours: float = 4.5
## Sun is visible/moving only inside this daily range.
@export_range(0.0, 24.0, 0.001) var sun_active_end_hours: float = 22.0
## Edge fade around sun visibility start/end.
@export_range(0.0, 3.0, 0.001) var sun_visibility_fade_hours: float = 0.25
## Freezes sun motion outside active window.
@export var constrain_sun_motion_to_active_window: bool = true
## Forces moon direction to be opposite sun direction.
@export var moon_inverse_of_sun: bool = true
## Legacy moon fade value kept for backward compatibility.
@export_range(0.0, 6.0, 0.001) var moon_visibility_fade_hours: float = 1.25
## Moon fade-in starts this many hours before sun_active_end_hours.
@export_range(0.0, 12.0, 0.001) var moon_fade_in_lead_hours: float = 1.25
## Moon fade-out ends this many hours after sun_active_start_hours.
@export_range(0.0, 12.0, 0.001) var moon_fade_out_lag_hours: float = 1.25
## In inverse mode, use continuous orbital sun direction to drive moon (prevents night snapping).
@export var moon_inverse_uses_unclamped_sun: bool = true

@export_group("Moon Surface")
## Optional moon material rendered to a texture and sampled in sky shader.
## Supports both CanvasItem and Spatial materials.
@export var moon_surface_material: Material
## Moon surface render texture size (when using moon_surface_material).
@export var moon_surface_size: Vector2i = Vector2i(512, 512)

@export_group("Celestial Cycle")
## Observer latitude in degrees, used to compute sun/moon altitude and azimuth.
@export_range(-89.9, 89.9, 0.001) var latitude_deg: float = 35.0
## Axial tilt used by seasonal solar declination.
@export_range(0.0, 45.0, 0.001) var axial_tilt_deg: float = 23.44
## Total days in one in-game year for seasonal progression.
@export_range(1.0, 1000.0, 1.0) var days_per_year: float = 365.0
## Uses clock date (month/day/year) for sun/moon seasonal and phase calculations.
@export var use_clock_calendar: bool = true
## Fallback day-of-year when clock calendar is disabled.
@export_range(1, 366, 1) var manual_day_of_year: int = 172
## Lunar synodic cycle length in days.
@export_range(1.0, 60.0, 0.0001) var moon_synodic_days: float = 29.530588
## Phase offset in days for aligning custom moon cycles.
@export_range(-60.0, 60.0, 0.01) var moon_phase_offset_days: float = 0.0
## Additional moon declination tilt.
@export_range(0.0, 15.0, 0.001) var moon_orbital_tilt_deg: float = 5.14

@export_group("Stars")
## Enables/disables procedural stars.
@export var stars_enabled: bool = true
## Star density from sparse (0) to dense (1), seeded and deterministic.
@export_range(0.0, 1.0, 0.001) var stars_density: float = 0.28
## Star brightness multiplier.
@export_range(0.0, 8.0, 0.01) var stars_brightness: float = 1.15
## Apparent star size multiplier.
@export_range(0.25, 3.0, 0.01) var stars_size: float = 1.0
## Twinkle animation speed.
@export_range(0.0, 5.0, 0.01) var stars_twinkle_speed: float = 0.35
## Deterministic star map seed.
@export var stars_seed: int = 1337

@export_group("Cloud Group")
## Unlimited cloud materials composited into one texture sampled by sky shader.
@export var cloud_layers: Array[DensetsuCloudLayer] = []
## Cloud compositor viewport resolution.
@export var cloud_composite_size: Vector2i = Vector2i(1024, 512)
## Global cloud opacity after layer compositing.
@export_range(0.0, 1.0, 0.01) var cloud_group_opacity: float = 1.0
## Global cloud brightness multiplier.
@export_range(0.0, 8.0, 0.01) var cloud_group_brightness: float = 1.0
## Global cloud contrast multiplier.
@export_range(0.1, 4.0, 0.01) var cloud_group_contrast: float = 1.0
## Global UV offset for cloud group sampling.
@export var cloud_uv_offset: Vector2 = Vector2.ZERO
## Global UV scroll speed applied to cloud group sampling.
@export var cloud_uv_scroll_speed: Vector2 = Vector2.ZERO
## Seam blending width for horizontal equirect cloud wrap (0 disables).
@export_range(0.0, 0.2, 0.0001) var cloud_seam_blend_width: float = 0.01

@export_group("Fog")
## Sky-only fog tint shift color.
@export var fog_shift_color: Color = Color(0.6, 0.7, 0.8, 1.0)
## Sky-only fog tint blend amount.
@export_range(0.0, 1.0, 0.01) var fog_shift_amount: float = 0.0
## Uses shader-side sky fog overlay. Disable to rely only on built-in Environment fog.
@export var use_sky_shader_fog_overlay: bool = false
## Uses captured Environment fog values as the base before weather offsets.
@export var use_captured_environment_fog_base: bool = false
## Base Environment fog enabled state when not using captured baseline.
@export var base_environment_fog_enabled: bool = true
## Base Environment fog density when not using captured baseline.
@export_range(0.0, 2.0, 0.0001) var base_environment_fog_density: float = 0.02
## Curve shaping for final Environment fog density (1.0 = linear).
@export_range(0.1, 4.0, 0.01) var environment_fog_density_curve: float = 1.0
## Base Environment fog light color when not using captured baseline.
@export var base_environment_fog_light_color: Color = Color(1.0, 1.0, 1.0, 1.0)
## Base Environment volumetric fog enabled state when not using captured baseline.
@export var base_environment_volumetric_fog_enabled: bool = false
## Base Environment volumetric fog density when not using captured baseline.
@export_range(0.0, 2.0, 0.0001) var base_environment_volumetric_fog_density: float = 0.0
## Curve shaping for final Environment volumetric fog density (1.0 = linear).
@export_range(0.1, 4.0, 0.01) var environment_volumetric_fog_density_curve: float = 1.0
## Soft cap for final Environment fog density to avoid hard white-out.
@export_range(0.01, 2.0, 0.001) var environment_fog_density_soft_cap: float = 1.0
## Soft cap for final Environment volumetric fog density to avoid full-screen white flash.
@export_range(0.01, 2.0, 0.001) var environment_volumetric_fog_density_soft_cap: float = 0.35
## Response strength for fog soft-cap remap (higher reaches cap faster).
@export_range(0.1, 16.0, 0.01) var environment_fog_soft_cap_response: float = 2.5
## Applies weather-driven fog offsets to Environment.
@export var apply_weather_to_environment_fog: bool = true
## Multiplier applied to weather fog density offsets before adding to base fog.
@export_range(0.0, 5.0, 0.001) var weather_fog_offset_scale: float = 0.1
## Response curve for weather fog blending (1.0 linear, <1 faster early, >1 slower early).
@export_range(0.1, 4.0, 0.01) var weather_fog_blend_curve: float = 0.7
## Forces Environment fog_enabled when weather fog contribution is present.
@export var weather_force_enable_environment_fog: bool = true
## Forces Environment volumetric_fog_enabled when volumetric contribution is present.
@export var weather_force_enable_volumetric_fog: bool = true

@export_group("Weather")
## Unlimited weather condition resources.
@export var weather_conditions: Array[DensetsuWeatherCondition] = []
## Optional weather bundles used for group-first weighted selection.
@export var weather_groups: Array[DensetsuWeatherGroup] = []
## Active weather id.
@export var active_weather_id: String = "clear"
## Time in in-game hours to blend into a newly activated weather.
@export_range(0.0, 240.0, 0.01) var weather_blend: float = 0.0
## If true, weather is selected automatically from weighted seasonal quotas.
@export var weather_auto_enabled: bool = false
## Allows automatic weather progression while in editor preview.
@export var weather_auto_in_editor: bool = false
## Uses weather_groups as a first selection step before choosing a condition.
@export var weather_use_groups: bool = true
## Optional fixed group filter for automatic selection (empty = weighted group pick/all).
@export var weather_group_override_id: String = ""
## Minimum in-game hours a weather condition should persist before rerolling.
@export_range(0.01, 240.0, 0.01) var weather_auto_hold_min_hours: float = 2.0
## Maximum in-game hours a weather condition should persist before rerolling.
@export_range(0.01, 240.0, 0.01) var weather_auto_hold_max_hours: float = 6.0
## Deterministic seed for automatic weather rolls.
@export var weather_random_seed: int = 1337
## If true, randomizes seed on _ready for non-deterministic weather rolls.
@export var weather_randomize_seed_on_ready: bool = false
## Spring start day in a 365-day reference calendar.
@export_range(1, 365, 1) var season_spring_start_day_365: int = 60
## Summer start day in a 365-day reference calendar.
@export_range(1, 365, 1) var season_summer_start_day_365: int = 152
## Autumn start day in a 365-day reference calendar.
@export_range(1, 365, 1) var season_autumn_start_day_365: int = 244
## Winter start day in a 365-day reference calendar.
@export_range(1, 365, 1) var season_winter_start_day_365: int = 335

@export_group("Weather Tiers")
## Distance of near weather tier from camera.
@export_range(0.0, 512.0, 0.1) var weather_near_distance: float = 6.0
## Distance of mid weather tier from camera.
@export_range(0.0, 1024.0, 0.1) var weather_mid_distance: float = 18.0
## Distance of far weather tier from camera.
@export_range(0.0, 2048.0, 0.1) var weather_far_distance: float = 42.0
## Base emission multiplier for all weather particle tiers.
@export_range(0.0, 4.0, 0.01) var weather_emission_multiplier: float = 1.0
## Enables indoor detection for weather suppression.
@export var indoor_detection_enabled: bool = true
## Seconds between indoor checks.
@export_range(0.05, 5.0, 0.01) var indoor_check_interval: float = 0.25
## Upward ray length for indoor detection.
@export_range(1.0, 1000.0, 0.1) var indoor_check_height: float = 40.0

@export_group("Debug UI")
## Enables in-game debug UI for time/calendar/weather controls and monitoring.
@export var debug_ui_enabled: bool = false
## Shows weather icon (if assigned in weather condition resource).
@export var debug_ui_show_weather_icon: bool = true
## Debug UI panel anchor offset from top-left.
@export var debug_ui_offset: Vector2 = Vector2(18.0, 18.0)

var _world_environment: WorldEnvironment = null
var _sun_light: DirectionalLight3D = null
var _moon_light: DirectionalLight3D = null
var _weather_camera: Camera3D = null
var _clock: DensetsuSkyClock = null

var _environment: Environment = null
var _sky: Sky = null
var _sky_shader: Shader = null
var _sky_material: ShaderMaterial = null
var _cloud_base_material_adapter_shader: Shader = null

var _cloud_viewport: SubViewport = null
var _cloud_canvas: Control = null
var _cloud_layer_rects: Array[ColorRect] = []
var _cloud_signature: String = ""
var _cloud_scroll_uv: Vector2 = Vector2.ZERO
var _cloud_shader_uniform_cache: Dictionary = {}
var _moon_surface_viewport: SubViewport = null
var _moon_surface_canvas: Control = null
var _moon_surface_rect: ColorRect = null
var _moon_surface_3d_root: Node3D = null
var _moon_surface_3d_env: WorldEnvironment = null
var _moon_surface_3d_camera: Camera3D = null
var _moon_surface_3d_mesh: MeshInstance3D = null
var _moon_surface_3d_light: DirectionalLight3D = null
var _warned_unsupported_moon_material: bool = false

var _weather_root: Node3D = null
var _weather_near_tier: Node3D = null
var _weather_mid_tier: Node3D = null
var _weather_far_tier: Node3D = null
var _weather_near_instance: Node = null
var _weather_mid_instance: Node = null
var _weather_far_instance: Node = null
var _active_weather: DensetsuWeatherCondition = null
var _active_weather_id_cached: String = ""
var _weather_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _weather_last_time_hours: float = 0.0
var _weather_hours_until_reroll: float = 0.0
var _weather_auto_initialized: bool = false
var _weather_elapsed_total_hours: float = 0.0
var _weather_segment_start_hours: float = 0.0
var _weather_segment_end_hours: float = 0.0
var _weather_blend_factor: float = 1.0
var _weather_blend_elapsed_hours: float = 0.0
var _weather_blend_in_progress: bool = false
var _weather_group_percent_prev: Dictionary = {}
var _weather_condition_percent_prev_buckets: Dictionary = {}
var _debug_force_season_override: bool = false
var _debug_forced_season_index: int = 0
var _clock_controls_prev_signature: String = ""

var _debug_ui_layer: CanvasLayer = null
var _debug_ui_panel: PanelContainer = null
var _debug_clock_label: Label = null
var _debug_timescale_label: Label = null
var _debug_timescale_slider: HSlider = null
var _debug_timescale_spin: SpinBox = null
var _debug_calendar_label: Label = null
var _debug_season_label: Label = null
var _debug_weather_icon: TextureRect = null
var _debug_weather_stack_label: RichTextLabel = null
var _debug_timeline_bar: ProgressBar = null
var _debug_timeline_label: Label = null
var _debug_weather_stack_last_click_id: String = ""
var _debug_weather_stack_last_click_ms: int = -1000000
var _debug_timescale_ui_syncing: bool = false

var _base_sun_energy: float = 1.0
var _base_sun_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var _base_moon_energy: float = 1.0
var _base_moon_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var _base_fog_density: float = 0.0
var _base_volumetric_fog_density: float = 0.0
var _base_fog_light_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var _base_fog_enabled: bool = false
var _base_volumetric_fog_enabled: bool = false
var _base_sun_state_captured: bool = false
var _base_moon_state_captured: bool = false
var _base_state_captured: bool = false

var _indoor_accum: float = 0.0
var _is_indoors: bool = false
var _warned_missing_shader: bool = false
var _warned_invalid_shader: bool = false
var _warned_invalid_world_environment_target: bool = false
var _warned_invalid_sun_light_target: bool = false
var _warned_invalid_moon_light_target: bool = false
var _warned_invalid_weather_camera_target: bool = false
var _computed_sun_direction: Vector3 = Vector3(0.0, 0.7071068, -0.7071068)
var _computed_moon_direction: Vector3 = Vector3(0.0, -0.7071068, 0.7071068)
var _computed_moon_phase: float = 0.5
var _computed_day_of_year: float = 172.0
var _computed_total_days: float = 0.0
var _computed_sun_visibility: float = 1.0
var _computed_moon_visibility: float = 1.0
var _sun_light_direction_smoothed: Vector3 = Vector3.ZERO
var _moon_light_direction_smoothed: Vector3 = Vector3.ZERO
var _sun_light_energy_smoothed: float = 0.0
var _moon_light_energy_smoothed: float = 0.0
var _sun_light_color_smoothed: Color = Color(1.0, 1.0, 1.0, 1.0)
var _moon_light_color_smoothed: Color = Color(1.0, 1.0, 1.0, 1.0)
var _sun_light_runtime_initialized: bool = false
var _moon_light_runtime_initialized: bool = false
var _frame_delta_seconds: float = 0.0166667

var _thunder_seconds_to_next_strike: float = -1.0
var _thunder_pulses_remaining: int = 0
var _thunder_seconds_to_next_pulse: float = 0.0
var _thunder_current_pulse_time_left: float = 0.0
var _thunder_current_pulse_duration: float = 0.0
var _thunder_current_pulse_energy_mult: float = 1.0
var _thunder_current_pulse_intensity: float = 0.0
var _thunder_current_color_lerp: float = 0.0
var _thunder_current_sky_tint_strength: float = 0.0
var _thunder_current_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
var _lightning_overlay_layer: CanvasLayer = null
var _lightning_overlay_root: Control = null
var _lightning_bolt_line: Line2D = null
var _lightning_bolt_time_left: float = 0.0
var _lightning_bolt_lifetime: float = 0.0
var _lightning_bolt_base_color: Color = Color(1.0, 1.0, 1.0, 1.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_initialize_weather_rng()
	ensure_setup()
	_apply_all()


func _process(delta: float) -> void:
	_frame_delta_seconds = max(delta, 0.0)
	if Engine.is_editor_hint():
		_rebalance_weather_percentages_if_needed()
		if not editor_preview:
			return

	ensure_setup()
	_update_cloud_signature_and_rebuild_if_needed()
	_update_weather_auto_selection(delta)
	_update_active_weather()
	_update_weather_blend_progress(delta)
	_update_cloud_runtime(delta)
	_update_indoor_detection(delta)
	_update_weather_tiers()
	_update_thunder_and_lightning(delta)
	_apply_all()
	_update_debug_ui()


func ensure_setup() -> void:
	_resolve_targets()
	_ensure_clock()
	_sync_clock_controls()
	_ensure_cloud_compositor()
	_ensure_moon_surface()
	_ensure_weather_tiers()
	_ensure_sky_material()
	_capture_base_state()
	_ensure_default_hour_gradient()
	_ensure_debug_ui()


func _resolve_targets() -> void:
	var prev_sun: DirectionalLight3D = _sun_light
	var prev_moon: DirectionalLight3D = _moon_light
	if not world_environment_path.is_empty() and (_world_environment == null or not is_instance_valid(_world_environment)):
		_world_environment = get_node_or_null(world_environment_path) as WorldEnvironment
	if not sun_light_path.is_empty() and (_sun_light == null or not is_instance_valid(_sun_light)):
		_sun_light = get_node_or_null(sun_light_path) as DirectionalLight3D
	if not moon_light_path.is_empty() and (_moon_light == null or not is_instance_valid(_moon_light)):
		_moon_light = get_node_or_null(moon_light_path) as DirectionalLight3D
	if not weather_camera_path.is_empty() and (_weather_camera == null or not is_instance_valid(_weather_camera)):
		_weather_camera = get_node_or_null(weather_camera_path) as Camera3D
	_validate_explicit_targets()

	if not auto_find_targets:
		return

	var scene_root: Node = get_tree().edited_scene_root
	if scene_root == null:
		scene_root = get_tree().current_scene
	if scene_root == null:
		return

	if _world_environment == null:
		_world_environment = _find_first_world_environment(scene_root)
	if _sun_light == null:
		_sun_light = _find_first_directional_light(scene_root)
	if _moon_light == null:
		_moon_light = _find_first_directional_light_excluding(scene_root, _sun_light)
	if _weather_camera == null:
		_weather_camera = _find_first_camera(scene_root)

	if prev_sun != _sun_light:
		_base_sun_state_captured = false
		_sun_light_runtime_initialized = false
	if prev_moon != _moon_light:
		_base_moon_state_captured = false
		_moon_light_runtime_initialized = false


func _find_first_world_environment(node: Node) -> WorldEnvironment:
	if node is WorldEnvironment:
		var candidate: WorldEnvironment = node as WorldEnvironment
		if _is_valid_world_environment_target(candidate):
			return candidate
	for child_any in node.get_children():
		var child: Node = child_any as Node
		if child == null:
			continue
		var found: WorldEnvironment = _find_first_world_environment(child)
		if found != null:
			return found
	return null


func _find_first_directional_light(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		var candidate: DirectionalLight3D = node as DirectionalLight3D
		if _is_valid_directional_light_target(candidate):
			return candidate
	for child_any in node.get_children():
		var child: Node = child_any as Node
		if child == null:
			continue
		var found: DirectionalLight3D = _find_first_directional_light(child)
		if found != null:
			return found
	return null


func _find_first_directional_light_excluding(node: Node, excluded: DirectionalLight3D) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		var candidate: DirectionalLight3D = node as DirectionalLight3D
		if candidate != excluded and _is_valid_directional_light_target(candidate):
			return candidate
	for child_any in node.get_children():
		var child: Node = child_any as Node
		if child == null:
			continue
		var found: DirectionalLight3D = _find_first_directional_light_excluding(child, excluded)
		if found != null:
			return found
	return null


func _find_first_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		var candidate: Camera3D = node as Camera3D
		if _is_valid_weather_camera_target(candidate):
			return candidate
	for child_any in node.get_children():
		var child: Node = child_any as Node
		if child == null:
			continue
		var found: Camera3D = _find_first_camera(child)
		if found != null:
			return found
	return null


func _validate_explicit_targets() -> void:
	if _world_environment != null and not _is_valid_world_environment_target(_world_environment):
		if not _warned_invalid_world_environment_target:
			push_warning("DensetsuSkySystem3D: world_environment_path resolved to an internal helper node. Ignoring it.")
			_warned_invalid_world_environment_target = true
		_world_environment = null
	if _sun_light != null and not _is_valid_directional_light_target(_sun_light):
		if not _warned_invalid_sun_light_target:
			push_warning("DensetsuSkySystem3D: sun_light_path resolved to an internal helper light/subviewport light. Ignoring it.")
			_warned_invalid_sun_light_target = true
		_sun_light = null
	if _moon_light != null and not _is_valid_directional_light_target(_moon_light):
		if not _warned_invalid_moon_light_target:
			push_warning("DensetsuSkySystem3D: moon_light_path resolved to an internal helper light/subviewport light. Ignoring it.")
			_warned_invalid_moon_light_target = true
		_moon_light = null
	if _weather_camera != null and not _is_valid_weather_camera_target(_weather_camera):
		if not _warned_invalid_weather_camera_target:
			push_warning("DensetsuSkySystem3D: weather_camera_path resolved to an internal helper/subviewport camera. Ignoring it.")
			_warned_invalid_weather_camera_target = true
		_weather_camera = null


func _is_valid_world_environment_target(node: WorldEnvironment) -> bool:
	if node == null:
		return false
	return not _is_internal_helper_branch(node)


func _is_valid_directional_light_target(node: DirectionalLight3D) -> bool:
	if node == null:
		return false
	return not _is_internal_helper_branch(node)


func _is_valid_weather_camera_target(node: Camera3D) -> bool:
	if node == null:
		return false
	return not _is_internal_helper_branch(node)


func _is_internal_helper_branch(node: Node) -> bool:
	if node == null:
		return false
	var current: Node = node
	while current != null:
		if current is SubViewport:
			return true
		var current_name: String = String(current.name)
		if current_name == CLOUD_VIEWPORT_NODE_NAME \
		or current_name == MOON_SURFACE_VIEWPORT_NODE_NAME \
		or current_name == WEATHER_ROOT_NODE_NAME \
		or current_name == SKY_DEBUG_UI_LAYER_NODE_NAME \
		or current_name == LIGHTNING_OVERLAY_LAYER_NODE_NAME:
			return true
		if current == self:
			break
		current = current.get_parent()
	return false


func _ensure_clock() -> void:
	_clock = get_node_or_null(clock_path) as DensetsuSkyClock
	if _clock != null:
		return
	if not auto_create_clock:
		return
	var created_clock: DensetsuSkyClock = DensetsuSkyClock.new()
	created_clock.name = "Clock"
	add_child(created_clock)
	if Engine.is_editor_hint():
		var edited_root: Node = get_tree().edited_scene_root
		if edited_root != null:
			created_clock.owner = edited_root
	_clock = created_clock


func _sync_clock_controls() -> void:
	if _clock == null:
		return
	var current_signature: String = _build_clock_controls_signature()
	if _clock_controls_prev_signature.is_empty():
		_push_clock_controls_to_clock()
		_pull_clock_controls_from_clock()
		_clock_controls_prev_signature = _build_clock_controls_signature()
		return
	if current_signature != _clock_controls_prev_signature:
		_push_clock_controls_to_clock()
	_pull_clock_controls_from_clock()
	_clock_controls_prev_signature = _build_clock_controls_signature()


func _build_clock_controls_signature() -> String:
	return "%s|%s|%.6f|%d|%d|%d|%s|%d|%d|%d" % [
		str(clock_running),
		str(clock_editor_preview),
		clock_minutes_per_real_second,
		clock_year,
		clock_month,
		clock_day,
		str(clock_month_lengths),
		clock_hour,
		clock_minute,
		clock_second
	]


func _push_clock_controls_to_clock() -> void:
	if _clock == null:
		return
	_clock.running = clock_running
	_clock.editor_preview = clock_editor_preview
	_clock.minutes_per_real_second = max(clock_minutes_per_real_second, 0.0)
	_clock.year = max(clock_year, 1)
	_clock.month_lengths = clock_month_lengths.duplicate()
	var month_count: int = max(_clock.month_lengths.size(), 1)
	_clock.month = clampi(clock_month, 1, month_count)
	var max_day: int = 30
	if _clock.month_lengths.size() > 0:
		max_day = max(_clock.month_lengths[_clock.month - 1], 1)
	_clock.day = clampi(clock_day, 1, max_day)
	_clock.hour = clampi(clock_hour, 0, 23)
	_clock.minute = clampi(clock_minute, 0, 59)
	_clock.second = clampi(clock_second, 0, 59)


func _pull_clock_controls_from_clock() -> void:
	if _clock == null:
		return
	clock_running = _clock.running
	clock_editor_preview = _clock.editor_preview
	clock_minutes_per_real_second = _clock.minutes_per_real_second
	clock_year = _clock.year
	clock_month = _clock.month
	clock_day = _clock.day
	clock_month_lengths = _clock.month_lengths.duplicate()
	clock_hour = _clock.hour
	clock_minute = _clock.minute
	clock_second = _clock.second


func _ensure_default_hour_gradient() -> void:
	if hour_gradient != null:
		return
	if not use_default_hour_gradient:
		return
	hour_gradient = _build_default_hour_gradient()


func _build_default_hour_gradient() -> GradientTexture1D:
	var gradient: Gradient = Gradient.new()
	var offsets: PackedFloat32Array = PackedFloat32Array()
	var colors: PackedColorArray = PackedColorArray()
	for i in range(24):
		var hour_value: int = i
		offsets.append(float(hour_value) / 23.0)
		colors.append(_default_hour_color(hour_value))
	gradient.offsets = offsets
	gradient.colors = colors
	var tex: GradientTexture1D = GradientTexture1D.new()
	tex.width = 512
	tex.gradient = gradient
	return tex


func _default_hour_color(hour_value: int) -> Color:
	if hour_value < 5:
		return Color(0.04, 0.07, 0.14, 1.0)
	if hour_value < 7:
		return Color(0.20, 0.22, 0.35, 1.0)
	if hour_value < 9:
		return Color(0.65, 0.47, 0.34, 1.0)
	if hour_value < 16:
		return Color(0.44, 0.67, 0.95, 1.0)
	if hour_value < 18:
		return Color(0.85, 0.56, 0.34, 1.0)
	if hour_value < 20:
		return Color(0.31, 0.26, 0.42, 1.0)
	return Color(0.06, 0.08, 0.16, 1.0)


func _ensure_cloud_compositor() -> void:
	var needs_rebuild: bool = false
	_cloud_viewport = get_node_or_null(CLOUD_VIEWPORT_NODE_NAME) as SubViewport
	if _cloud_viewport == null:
		var created_viewport: SubViewport = SubViewport.new()
		created_viewport.name = CLOUD_VIEWPORT_NODE_NAME
		created_viewport.disable_3d = true
		created_viewport.transparent_bg = true
		created_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		created_viewport.size = cloud_composite_size
		add_child(created_viewport)
		if Engine.is_editor_hint():
			var edited_root: Node = get_tree().edited_scene_root
			if edited_root != null:
				created_viewport.owner = edited_root
		_cloud_viewport = created_viewport
		needs_rebuild = true

	if _cloud_viewport.size != cloud_composite_size:
		_cloud_viewport.size = cloud_composite_size
		needs_rebuild = true

	_cloud_canvas = _cloud_viewport.get_node_or_null(CLOUD_CANVAS_NODE_NAME) as Control
	if _cloud_canvas == null:
		var created_canvas: Control = Control.new()
		created_canvas.name = CLOUD_CANVAS_NODE_NAME
		created_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		created_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
		created_canvas.offset_left = 0.0
		created_canvas.offset_top = 0.0
		created_canvas.offset_right = float(cloud_composite_size.x)
		created_canvas.offset_bottom = float(cloud_composite_size.y)
		_cloud_viewport.add_child(created_canvas)
		if Engine.is_editor_hint():
			var edited_root2: Node = get_tree().edited_scene_root
			if edited_root2 != null:
				created_canvas.owner = edited_root2
		_cloud_canvas = created_canvas
		needs_rebuild = true

	if _cloud_canvas != null:
		_cloud_canvas.offset_right = float(cloud_composite_size.x)
		_cloud_canvas.offset_bottom = float(cloud_composite_size.y)

	if needs_rebuild or _cloud_signature.is_empty():
		_rebuild_cloud_layers()


func _ensure_moon_surface() -> void:
	if moon_surface_material == null:
		return

	_moon_surface_viewport = get_node_or_null(MOON_SURFACE_VIEWPORT_NODE_NAME) as SubViewport
	if _moon_surface_viewport == null:
		var created_viewport: SubViewport = SubViewport.new()
		created_viewport.name = MOON_SURFACE_VIEWPORT_NODE_NAME
		created_viewport.disable_3d = true
		created_viewport.transparent_bg = true
		created_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		created_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
		created_viewport.size = moon_surface_size
		add_child(created_viewport)
		if Engine.is_editor_hint():
			var edited_root: Node = get_tree().edited_scene_root
			if edited_root != null:
				created_viewport.owner = edited_root
		_moon_surface_viewport = created_viewport
	if _moon_surface_viewport.size != moon_surface_size:
		_moon_surface_viewport.size = moon_surface_size
	_moon_surface_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_moon_surface_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

	var is_canvas_material: bool = _is_canvas_moon_material(moon_surface_material)
	var is_spatial_material: bool = _is_spatial_moon_material(moon_surface_material)
	if not is_canvas_material and not is_spatial_material:
		if not _warned_unsupported_moon_material:
			push_warning("DensetsuSkySystem3D: unsupported moon_surface_material type. Use CanvasItem or Spatial material.")
			_warned_unsupported_moon_material = true
		return

	if is_spatial_material:
		if _moon_surface_viewport.disable_3d:
			_moon_surface_viewport.disable_3d = false
		_moon_surface_viewport.own_world_3d = true
		_ensure_moon_surface_spatial_nodes()
		if _moon_surface_canvas != null:
			_moon_surface_canvas.visible = false
		if _moon_surface_3d_root != null:
			_moon_surface_3d_root.visible = true
		if _moon_surface_3d_mesh != null:
			_moon_surface_3d_mesh.material_override = moon_surface_material as Material
			_moon_surface_3d_mesh.visible = true
		return

	if not is_canvas_material:
		return
	if not _moon_surface_viewport.disable_3d:
		_moon_surface_viewport.disable_3d = true
	if _moon_surface_3d_root != null:
		_moon_surface_3d_root.visible = false

	_moon_surface_canvas = _moon_surface_viewport.get_node_or_null(MOON_SURFACE_CANVAS_NODE_NAME) as Control
	if _moon_surface_canvas == null:
		var created_canvas: Control = Control.new()
		created_canvas.name = MOON_SURFACE_CANVAS_NODE_NAME
		created_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		created_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
		created_canvas.offset_left = 0.0
		created_canvas.offset_top = 0.0
		created_canvas.offset_right = float(moon_surface_size.x)
		created_canvas.offset_bottom = float(moon_surface_size.y)
		_moon_surface_viewport.add_child(created_canvas)
		if Engine.is_editor_hint():
			var edited_root2: Node = get_tree().edited_scene_root
			if edited_root2 != null:
				created_canvas.owner = edited_root2
		_moon_surface_canvas = created_canvas
	_moon_surface_canvas.offset_right = float(moon_surface_size.x)
	_moon_surface_canvas.offset_bottom = float(moon_surface_size.y)

	_moon_surface_rect = _moon_surface_canvas.get_node_or_null(MOON_SURFACE_RECT_NODE_NAME) as ColorRect
	if _moon_surface_rect == null:
		var created_rect: ColorRect = ColorRect.new()
		created_rect.name = MOON_SURFACE_RECT_NODE_NAME
		created_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		created_rect.offset_left = 0.0
		created_rect.offset_top = 0.0
		created_rect.offset_right = 0.0
		created_rect.offset_bottom = 0.0
		created_rect.color = Color.WHITE
		created_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_moon_surface_canvas.add_child(created_rect)
		if Engine.is_editor_hint():
			var edited_root3: Node = get_tree().edited_scene_root
			if edited_root3 != null:
				created_rect.owner = edited_root3
		_moon_surface_rect = created_rect
	_moon_surface_canvas.visible = true
	_moon_surface_rect.material = moon_surface_material


func _is_canvas_moon_material(material: Material) -> bool:
	if material == null:
		return false
	if material is CanvasItemMaterial:
		return true
	var shader_material: ShaderMaterial = material as ShaderMaterial
	if shader_material != null and shader_material.shader != null:
		return shader_material.shader.get_mode() == Shader.MODE_CANVAS_ITEM
	return false


func _is_spatial_moon_material(material: Material) -> bool:
	if material == null:
		return false
	if material is BaseMaterial3D:
		return true
	var shader_material: ShaderMaterial = material as ShaderMaterial
	if shader_material != null and shader_material.shader != null:
		return shader_material.shader.get_mode() == Shader.MODE_SPATIAL
	return false


func _ensure_moon_surface_spatial_nodes() -> void:
	if _moon_surface_viewport == null:
		return
	_moon_surface_3d_root = _moon_surface_viewport.get_node_or_null(MOON_SURFACE_3D_ROOT_NODE_NAME) as Node3D
	if _moon_surface_3d_root == null:
		var created_root: Node3D = Node3D.new()
		created_root.name = MOON_SURFACE_3D_ROOT_NODE_NAME
		_moon_surface_viewport.add_child(created_root)
		if Engine.is_editor_hint():
			var edited_root: Node = get_tree().edited_scene_root
			if edited_root != null:
				created_root.owner = edited_root
		_moon_surface_3d_root = created_root

	_moon_surface_3d_env = _moon_surface_3d_root.get_node_or_null(MOON_SURFACE_3D_ENV_NODE_NAME) as WorldEnvironment
	if _moon_surface_3d_env == null:
		var created_env_node: WorldEnvironment = WorldEnvironment.new()
		created_env_node.name = MOON_SURFACE_3D_ENV_NODE_NAME
		var env: Environment = Environment.new()
		env.background_mode = Environment.BG_COLOR
		if _object_has_property(env, "background_color"):
			env.set("background_color", Color(0.0, 0.0, 0.0, 1.0))
		if _object_has_property(env, "ambient_light_color"):
			env.set("ambient_light_color", Color(1.0, 1.0, 1.0, 1.0))
		if _object_has_property(env, "ambient_light_energy"):
			env.set("ambient_light_energy", 0.85)
		if _object_has_property(env, "ambient_light_sky_contribution"):
			env.set("ambient_light_sky_contribution", 0.0)
		created_env_node.environment = env
		_moon_surface_3d_root.add_child(created_env_node)
		if Engine.is_editor_hint():
			var edited_root_env: Node = get_tree().edited_scene_root
			if edited_root_env != null:
				created_env_node.owner = edited_root_env
		_moon_surface_3d_env = created_env_node

	_moon_surface_3d_camera = _moon_surface_3d_root.get_node_or_null(MOON_SURFACE_3D_CAMERA_NODE_NAME) as Camera3D
	if _moon_surface_3d_camera == null:
		var created_camera: Camera3D = Camera3D.new()
		created_camera.name = MOON_SURFACE_3D_CAMERA_NODE_NAME
		created_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		created_camera.size = 2.1
		created_camera.near = 0.01
		created_camera.far = 20.0
		created_camera.position = Vector3(0.0, 0.0, 3.0)
		created_camera.look_at(Vector3.ZERO, Vector3.UP)
		_moon_surface_3d_root.add_child(created_camera)
		if Engine.is_editor_hint():
			var edited_root2: Node = get_tree().edited_scene_root
			if edited_root2 != null:
				created_camera.owner = edited_root2
		_moon_surface_3d_camera = created_camera
	if _moon_surface_3d_camera != null:
		_moon_surface_3d_camera.current = true

	_moon_surface_3d_mesh = _moon_surface_3d_root.get_node_or_null(MOON_SURFACE_3D_MESH_NODE_NAME) as MeshInstance3D
	if _moon_surface_3d_mesh == null:
		var created_mesh: MeshInstance3D = MeshInstance3D.new()
		created_mesh.name = MOON_SURFACE_3D_MESH_NODE_NAME
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		sphere.radial_segments = 64
		sphere.rings = 32
		created_mesh.mesh = sphere
		created_mesh.position = Vector3.ZERO
		created_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_moon_surface_3d_root.add_child(created_mesh)
		if Engine.is_editor_hint():
			var edited_root3: Node = get_tree().edited_scene_root
			if edited_root3 != null:
				created_mesh.owner = edited_root3
		_moon_surface_3d_mesh = created_mesh

	_moon_surface_3d_light = _moon_surface_3d_root.get_node_or_null(MOON_SURFACE_3D_LIGHT_NODE_NAME) as DirectionalLight3D
	if _moon_surface_3d_light == null:
		var created_light: DirectionalLight3D = DirectionalLight3D.new()
		created_light.name = MOON_SURFACE_3D_LIGHT_NODE_NAME
		created_light.light_energy = 2.0
		created_light.light_color = Color(1.0, 1.0, 1.0, 1.0)
		created_light.rotation_degrees = Vector3(0.0, 180.0, 0.0)
		_moon_surface_3d_root.add_child(created_light)
		if Engine.is_editor_hint():
			var edited_root4: Node = get_tree().edited_scene_root
			if edited_root4 != null:
				created_light.owner = edited_root4
		_moon_surface_3d_light = created_light


func _update_cloud_signature_and_rebuild_if_needed() -> void:
	var signature: String = _build_cloud_signature()
	if signature == _cloud_signature:
		return
	_rebuild_cloud_layers()


func _build_cloud_signature() -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("%d|%d" % [cloud_composite_size.x, cloud_composite_size.y])
	for layer_any in cloud_layers:
		var layer: DensetsuCloudLayer = layer_any as DensetsuCloudLayer
		if layer == null:
			parts.append("null")
			continue
		var material_fingerprint: String = _cloud_material_fingerprint(layer.material)
		var line: String = "%s|%s|%s|%f|%f|%f|%f|%f|%f|%f|%f|%f" % [
			str(layer.enabled),
			material_fingerprint,
			str(layer.tint),
			layer.opacity,
			layer.uv_scale.x,
			layer.uv_scale.y,
			layer.uv_offset.x,
			layer.uv_offset.y,
			layer.uv_scroll.x,
			layer.uv_scroll.y,
			cloud_group_opacity,
			cloud_group_contrast
		]
		parts.append(line)
	return "|".join(parts)


func _cloud_material_fingerprint(source_material: Material) -> String:
	if source_material == null:
		return "null"
	var id_part: String = ""
	if not source_material.resource_path.is_empty():
		id_part = source_material.resource_path
	else:
		id_part = "iid:%d" % source_material.get_instance_id()
	if source_material is BaseMaterial3D:
		var albedo_data: Dictionary = _extract_base_material_albedo(source_material)
		var albedo_color_value: Color = Color.WHITE
		var color_variant: Variant = albedo_data.get("color", Color.WHITE)
		if typeof(color_variant) == TYPE_COLOR:
			albedo_color_value = color_variant
		var albedo_texture_value: Texture2D = null
		var texture_variant: Variant = albedo_data.get("texture", null)
		if texture_variant is Texture2D:
			albedo_texture_value = texture_variant as Texture2D
		var tex_part: String = "none"
		if albedo_texture_value != null:
			if not albedo_texture_value.resource_path.is_empty():
				tex_part = albedo_texture_value.resource_path
			else:
				tex_part = "iid:%d" % albedo_texture_value.get_instance_id()
		var uv_data: Dictionary = _extract_base_material_uv(source_material)
		var uv_scale_value: Vector2 = Vector2.ONE
		var uv_offset_value: Vector2 = Vector2.ZERO
		var uv_scale_variant: Variant = uv_data.get("scale", Vector2.ONE)
		if typeof(uv_scale_variant) == TYPE_VECTOR2:
			uv_scale_value = uv_scale_variant
		var uv_offset_variant: Variant = uv_data.get("offset", Vector2.ZERO)
		if typeof(uv_offset_variant) == TYPE_VECTOR2:
			uv_offset_value = uv_offset_variant
		return "%s|alb:%s|tex:%s|uvs:%f,%f|uvo:%f,%f" % [
			id_part,
			str(albedo_color_value),
			tex_part,
			uv_scale_value.x,
			uv_scale_value.y,
			uv_offset_value.x,
			uv_offset_value.y
		]
	return id_part


func _rebuild_cloud_layers() -> void:
	if _cloud_canvas == null:
		return

	var old_children: Array[Node] = []
	for child_any in _cloud_canvas.get_children():
		var child: Node = child_any as Node
		if child != null:
			old_children.append(child)
	for old_child in old_children:
		if old_child == null or not is_instance_valid(old_child):
			continue
		_cloud_canvas.remove_child(old_child)
		old_child.free()
	_cloud_layer_rects.clear()

	var layer_index: int = 0
	for layer_any in cloud_layers:
		var layer: DensetsuCloudLayer = layer_any as DensetsuCloudLayer
		if layer == null:
			layer_index += 1
			continue
		var rect: ColorRect = ColorRect.new()
		rect.name = "CloudLayer_%d" % layer_index
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.offset_left = 0.0
		rect.offset_top = 0.0
		rect.offset_right = 0.0
		rect.offset_bottom = 0.0
		rect.material = _build_cloud_canvas_material(layer.material)
		rect.color = Color(1.0, 1.0, 1.0, 1.0)
		rect.modulate = Color(layer.tint.r, layer.tint.g, layer.tint.b, layer.tint.a * layer.opacity)
		rect.visible = layer.enabled
		rect.z_index = layer_index
		_cloud_canvas.add_child(rect)
		if Engine.is_editor_hint():
			var edited_root: Node = get_tree().edited_scene_root
			if edited_root != null:
				rect.owner = edited_root
		_cloud_layer_rects.append(rect)
		layer_index += 1

	_cloud_signature = _build_cloud_signature()


func _build_cloud_canvas_material(source_material: Material) -> Material:
	if source_material == null:
		return null
	if _is_canvas_moon_material(source_material):
		return source_material
	if source_material is BaseMaterial3D:
		var adapter_shader: Shader = _get_cloud_base_material_adapter_shader()
		if adapter_shader == null:
			return null
		var adapter_material: ShaderMaterial = ShaderMaterial.new()
		adapter_material.shader = adapter_shader
		adapter_material.resource_local_to_scene = true
		var albedo_data: Dictionary = _extract_base_material_albedo(source_material)
		var albedo_color_value: Color = Color.WHITE
		var color_variant: Variant = albedo_data.get("color", Color.WHITE)
		if typeof(color_variant) == TYPE_COLOR:
			albedo_color_value = color_variant
		var albedo_texture_value: Texture2D = null
		var texture_variant: Variant = albedo_data.get("texture", null)
		if texture_variant is Texture2D:
			albedo_texture_value = texture_variant as Texture2D
		var uv_data: Dictionary = _extract_base_material_uv(source_material)
		var uv_scale_value: Vector2 = Vector2.ONE
		var uv_offset_value: Vector2 = Vector2.ZERO
		var uv_scale_variant: Variant = uv_data.get("scale", Vector2.ONE)
		if typeof(uv_scale_variant) == TYPE_VECTOR2:
			uv_scale_value = uv_scale_variant
		var uv_offset_variant: Variant = uv_data.get("offset", Vector2.ZERO)
		if typeof(uv_offset_variant) == TYPE_VECTOR2:
			uv_offset_value = uv_offset_variant
		adapter_material.set_shader_parameter("albedo_color", albedo_color_value)
		adapter_material.set_shader_parameter("albedo_texture", albedo_texture_value)
		adapter_material.set_shader_parameter("material_uv_scale", uv_scale_value)
		adapter_material.set_shader_parameter("material_uv_offset", uv_offset_value)
		return adapter_material
	return null


func _get_cloud_base_material_adapter_shader() -> Shader:
	if _cloud_base_material_adapter_shader != null:
		return _cloud_base_material_adapter_shader
	_cloud_base_material_adapter_shader = load(CLOUD_BASE_MATERIAL_ADAPTER_SHADER_PATH) as Shader
	return _cloud_base_material_adapter_shader


func _is_cloud_adapter_shader(shader: Shader) -> bool:
	if shader == null:
		return false
	if _cloud_base_material_adapter_shader != null and shader == _cloud_base_material_adapter_shader:
		return true
	return shader.resource_path == CLOUD_BASE_MATERIAL_ADAPTER_SHADER_PATH


func _cloud_material_matches_source(current_material: Material, source_material: Material) -> bool:
	if source_material == null:
		return current_material == null
	if _is_canvas_moon_material(source_material):
		return current_material == source_material
	if source_material is BaseMaterial3D:
		var shader_material: ShaderMaterial = current_material as ShaderMaterial
		if shader_material == null:
			return false
		return _is_cloud_adapter_shader(shader_material.shader)
	return false


func _extract_base_material_albedo(source_material: Material) -> Dictionary:
	var albedo_color_value: Color = Color(1.0, 1.0, 1.0, 1.0)
	var albedo_texture_value: Texture2D = null
	if source_material == null:
		return {
			"color": albedo_color_value,
			"texture": albedo_texture_value
		}
	if _object_has_property(source_material, "albedo_color"):
		var color_variant: Variant = source_material.get("albedo_color")
		if typeof(color_variant) == TYPE_COLOR:
			albedo_color_value = color_variant
	if _object_has_property(source_material, "albedo_texture"):
		albedo_texture_value = source_material.get("albedo_texture") as Texture2D
	if albedo_texture_value == null and _object_has_property(source_material, "texture_albedo"):
		albedo_texture_value = source_material.get("texture_albedo") as Texture2D
	return {
		"color": albedo_color_value,
		"texture": albedo_texture_value
	}


func _extract_base_material_uv(source_material: Material) -> Dictionary:
	var uv_scale_value: Vector2 = Vector2.ONE
	var uv_offset_value: Vector2 = Vector2.ZERO
	if source_material == null:
		return {
			"scale": uv_scale_value,
			"offset": uv_offset_value
		}
	if _object_has_property(source_material, "uv1_scale"):
		var scale_variant: Variant = source_material.get("uv1_scale")
		if typeof(scale_variant) == TYPE_VECTOR3:
			var scale3: Vector3 = scale_variant
			uv_scale_value = Vector2(scale3.x, scale3.y)
		elif typeof(scale_variant) == TYPE_VECTOR2:
			uv_scale_value = scale_variant
	if _object_has_property(source_material, "uv1_offset"):
		var offset_variant: Variant = source_material.get("uv1_offset")
		if typeof(offset_variant) == TYPE_VECTOR3:
			var offset3: Vector3 = offset_variant
			uv_offset_value = Vector2(offset3.x, offset3.y)
		elif typeof(offset_variant) == TYPE_VECTOR2:
			uv_offset_value = offset_variant
	return {
		"scale": uv_scale_value,
		"offset": uv_offset_value
	}


func _sync_cloud_adapter_from_base(adapter_material: ShaderMaterial, source_material: Material) -> void:
	if adapter_material == null:
		return
	if source_material == null:
		return
	var albedo_data: Dictionary = _extract_base_material_albedo(source_material)
	var albedo_color_value: Color = Color.WHITE
	var color_variant: Variant = albedo_data.get("color", Color.WHITE)
	if typeof(color_variant) == TYPE_COLOR:
		albedo_color_value = color_variant
	var albedo_texture_value: Texture2D = null
	var texture_variant: Variant = albedo_data.get("texture", null)
	if texture_variant is Texture2D:
		albedo_texture_value = texture_variant as Texture2D
	var uv_data: Dictionary = _extract_base_material_uv(source_material)
	var uv_scale_value: Vector2 = Vector2.ONE
	var uv_offset_value: Vector2 = Vector2.ZERO
	var uv_scale_variant: Variant = uv_data.get("scale", Vector2.ONE)
	if typeof(uv_scale_variant) == TYPE_VECTOR2:
		uv_scale_value = uv_scale_variant
	var uv_offset_variant: Variant = uv_data.get("offset", Vector2.ZERO)
	if typeof(uv_offset_variant) == TYPE_VECTOR2:
		uv_offset_value = uv_offset_variant
	adapter_material.set_shader_parameter("albedo_color", albedo_color_value)
	adapter_material.set_shader_parameter("albedo_texture", albedo_texture_value)
	adapter_material.set_shader_parameter("material_uv_scale", uv_scale_value)
	adapter_material.set_shader_parameter("material_uv_offset", uv_offset_value)


func _update_cloud_runtime(delta: float) -> void:
	if _cloud_layer_rects.is_empty():
		return
	_cloud_scroll_uv += cloud_uv_scroll_speed * delta * cloud_time_scale
	for i in range(_cloud_layer_rects.size()):
		var rect: ColorRect = _cloud_layer_rects[i]
		if rect == null:
			continue
		if i >= cloud_layers.size():
			rect.visible = false
			continue
		var layer: DensetsuCloudLayer = cloud_layers[i] as DensetsuCloudLayer
		if layer == null:
			rect.visible = false
			continue
		if not _cloud_material_matches_source(rect.material, layer.material):
			rect.material = _build_cloud_canvas_material(layer.material)
		rect.visible = layer.enabled
		rect.modulate = Color(layer.tint.r, layer.tint.g, layer.tint.b, layer.tint.a * layer.opacity)
		var shader_material: ShaderMaterial = rect.material as ShaderMaterial
		if shader_material == null:
			continue
		if layer.material is BaseMaterial3D and _is_cloud_adapter_shader(shader_material.shader):
			_sync_cloud_adapter_from_base(shader_material, layer.material)
		var time_seconds: float = float(Time.get_ticks_msec()) * 0.001
		var effective_uv_offset: Vector2 = layer.uv_offset
		var shader_ref: Shader = shader_material.shader
		if shader_ref == null or not _shader_has_uniform(shader_ref, "uv_scroll"):
			effective_uv_offset += layer.uv_scroll * time_seconds
		_set_shader_parameter_if_present(shader_material, "time_seconds", time_seconds)
		_set_shader_parameter_if_present(shader_material, "uv_scale", layer.uv_scale)
		_set_shader_parameter_if_present(shader_material, "uv_offset", effective_uv_offset)
		_set_shader_parameter_if_present(shader_material, "uv_scroll", layer.uv_scroll)


func _shader_has_uniform(shader: Shader, param_name: String) -> bool:
	if shader == null:
		return false
	var key: String = str(shader.get_instance_id())
	var uniforms: PackedStringArray = PackedStringArray()
	if _cloud_shader_uniform_cache.has(key):
		uniforms = _cloud_shader_uniform_cache[key] as PackedStringArray
	else:
		var collected: PackedStringArray = PackedStringArray()
		var uniform_list: Array = shader.get_shader_uniform_list()
		for entry_any in uniform_list:
			if not (entry_any is Dictionary):
				continue
			var entry: Dictionary = entry_any as Dictionary
			var uniform_name: String = str(entry.get("name", ""))
			if uniform_name.is_empty():
				continue
			collected.append(uniform_name)
		_cloud_shader_uniform_cache[key] = collected
		uniforms = collected
	return uniforms.has(param_name)


func _set_shader_parameter_if_present(material: ShaderMaterial, param_name: String, value: Variant) -> void:
	if material == null:
		return
	var shader: Shader = material.shader
	if shader == null:
		return
	if _shader_has_uniform(shader, param_name):
		material.set_shader_parameter(param_name, value)


func _ensure_weather_tiers() -> void:
	_weather_root = get_node_or_null(WEATHER_ROOT_NODE_NAME) as Node3D
	if _weather_root == null:
		var created_root: Node3D = Node3D.new()
		created_root.name = WEATHER_ROOT_NODE_NAME
		add_child(created_root)
		if Engine.is_editor_hint():
			var edited_root: Node = get_tree().edited_scene_root
			if edited_root != null:
				created_root.owner = edited_root
		_weather_root = created_root

	_weather_near_tier = _ensure_weather_tier_node(WEATHER_NEAR_NODE_NAME)
	_weather_mid_tier = _ensure_weather_tier_node(WEATHER_MID_NODE_NAME)
	_weather_far_tier = _ensure_weather_tier_node(WEATHER_FAR_NODE_NAME)


func _ensure_weather_tier_node(node_name: String) -> Node3D:
	if _weather_root == null:
		return null
	var tier: Node3D = _weather_root.get_node_or_null(node_name) as Node3D
	if tier == null:
		var created: Node3D = Node3D.new()
		created.name = node_name
		_weather_root.add_child(created)
		if Engine.is_editor_hint():
			var edited_root: Node = get_tree().edited_scene_root
			if edited_root != null:
				created.owner = edited_root
		tier = created
	return tier


func _initialize_weather_rng() -> void:
	if weather_randomize_seed_on_ready:
		_weather_rng.randomize()
	else:
		_weather_rng.seed = int(weather_random_seed)
	_weather_auto_initialized = false
	_weather_elapsed_total_hours = _resolve_total_days_value(_resolve_day_of_year_value(), _get_time_hours()) * 24.0
	_weather_segment_start_hours = _weather_elapsed_total_hours
	_weather_segment_end_hours = _weather_elapsed_total_hours


func _update_weather_auto_selection(delta: float) -> void:
	if not weather_auto_enabled:
		return
	if Engine.is_editor_hint() and not weather_auto_in_editor:
		return

	var current_hours: float = _get_time_hours()
	if not _weather_auto_initialized:
		_weather_last_time_hours = current_hours
		_weather_hours_until_reroll = _get_next_weather_hold_hours()
		_weather_auto_initialized = true
		_weather_segment_start_hours = _weather_elapsed_total_hours
		_weather_segment_end_hours = _weather_segment_start_hours + _weather_hours_until_reroll
		if _get_weather_by_id(active_weather_id) == null:
			_roll_weather_now()
		return

	var elapsed_hours: float = _compute_elapsed_in_game_hours(current_hours, delta)
	_weather_last_time_hours = current_hours
	if elapsed_hours <= 0.0:
		return
	_weather_elapsed_total_hours += elapsed_hours
	_weather_hours_until_reroll -= elapsed_hours
	if _weather_hours_until_reroll > 0.0:
		return
	_roll_weather_now()
	_weather_hours_until_reroll = _get_next_weather_hold_hours()
	_weather_segment_start_hours = _weather_elapsed_total_hours
	_weather_segment_end_hours = _weather_segment_start_hours + _weather_hours_until_reroll


func _compute_elapsed_in_game_hours(current_hours: float, delta: float) -> float:
	if use_clock_time and _clock != null:
		return _forward_hours_24(_weather_last_time_hours, current_hours)
	return max(delta * (minutes_per_real_second_to_hours()), 0.0)


func minutes_per_real_second_to_hours() -> float:
	if _clock == null:
		return 1.0 / 3600.0
	return max(_clock.minutes_per_real_second, 0.0) / 60.0


func _get_next_weather_hold_hours() -> float:
	var min_hours: float = max(weather_auto_hold_min_hours, 0.01)
	var max_hours: float = max(weather_auto_hold_max_hours, min_hours)
	if is_equal_approx(min_hours, max_hours):
		return min_hours
	return _weather_rng.randf_range(min_hours, max_hours)


func _rebalance_weather_percentages_if_needed() -> void:
	if not Engine.is_editor_hint():
		return
	_rebalance_weather_group_percentages()
	_rebalance_weather_condition_percentages()


func _rebalance_weather_group_percentages() -> void:
	var groups: Array = []
	for group_any in weather_groups:
		var group: DensetsuWeatherGroup = group_any as DensetsuWeatherGroup
		if group == null:
			continue
		if group.group_id.strip_edges().is_empty():
			continue
		groups.append(group)
	_weather_group_percent_prev = _rebalance_auto_base_percent_bucket(groups, _weather_group_percent_prev)


func _rebalance_weather_condition_percentages() -> void:
	var buckets: Dictionary = {}
	for condition_any in weather_conditions:
		var condition: DensetsuWeatherCondition = condition_any as DensetsuWeatherCondition
		if condition == null:
			continue
		if condition.weather_id.strip_edges().is_empty():
			continue
		var bucket_id: String = condition.weather_group_id.strip_edges()
		if bucket_id.is_empty():
			bucket_id = "__ungrouped__"
		var bucket_items: Array = []
		if buckets.has(bucket_id):
			var existing_bucket: Variant = buckets.get(bucket_id)
			if existing_bucket is Array:
				bucket_items = existing_bucket as Array
		bucket_items.append(condition)
		buckets[bucket_id] = bucket_items

	var new_prev_buckets: Dictionary = {}
	for bucket_key_any in buckets.keys():
		var bucket_key: String = str(bucket_key_any)
		var bucket_variant: Variant = buckets.get(bucket_key, [])
		var bucket_resources: Array = []
		if bucket_variant is Array:
			bucket_resources = bucket_variant as Array
		var previous_bucket: Dictionary = {}
		if _weather_condition_percent_prev_buckets.has(bucket_key):
			var previous_variant: Variant = _weather_condition_percent_prev_buckets.get(bucket_key)
			if previous_variant is Dictionary:
				previous_bucket = previous_variant as Dictionary
		new_prev_buckets[bucket_key] = _rebalance_auto_base_percent_bucket(bucket_resources, previous_bucket)
	_weather_condition_percent_prev_buckets = new_prev_buckets


func _rebalance_auto_base_percent_bucket(resources: Array, previous_values: Dictionary) -> Dictionary:
	var tracked_resources: Array[Resource] = []
	var tracked_keys: PackedStringArray = PackedStringArray()
	var tracked_values: PackedFloat32Array = PackedFloat32Array()
	var total_value: float = 0.0
	var changed_index: int = -1
	var changed_delta: float = 0.0
	var previous_dict: Dictionary = previous_values

	for resource_any in resources:
		var res: Resource = resource_any as Resource
		if res == null:
			continue
		var raw_value: float = float(res.get("auto_base_weight"))
		var clamped_value: float = clampf(raw_value, 0.0, 100.0)
		if absf(raw_value - clamped_value) > 0.000001:
			res.set("auto_base_weight", clamped_value)
		var key: String = str(res.get_instance_id())
		var previous_value: float = clamped_value
		if previous_dict.has(key):
			previous_value = float(previous_dict.get(key))
		var delta: float = absf(clamped_value - previous_value)
		if delta > changed_delta:
			changed_delta = delta
			changed_index = tracked_resources.size()
		tracked_resources.append(res)
		tracked_keys.append(key)
		tracked_values.append(clamped_value)
		total_value += clamped_value

	var count: int = tracked_resources.size()
	var result: Dictionary = {}
	if count == 0:
		return result
	if count == 1:
		if absf(tracked_values[0] - 100.0) > 0.000001:
			tracked_resources[0].set("auto_base_weight", 100.0)
		result[tracked_keys[0]] = 100.0
		return result

	if absf(total_value - 100.0) > 0.0005:
		if changed_index >= 0 and changed_delta > 0.000001:
			var locked_value: float = clampf(tracked_values[changed_index], 0.0, 100.0)
			var remaining: float = max(100.0 - locked_value, 0.0)
			var share: float = remaining / float(count - 1)
			for i in range(count):
				if i == changed_index:
					tracked_values[i] = locked_value
				else:
					tracked_values[i] = share
		else:
			if total_value <= 0.000001:
				var even_share: float = 100.0 / float(count)
				for i in range(count):
					tracked_values[i] = even_share
			else:
				var scale: float = 100.0 / total_value
				for i in range(count):
					tracked_values[i] *= scale

	var recompute_sum: float = 0.0
	for i in range(count):
		recompute_sum += tracked_values[i]
	if count > 0:
		var correction: float = 100.0 - recompute_sum
		tracked_values[0] += correction

	for i in range(count):
		var final_value: float = clampf(tracked_values[i], 0.0, 100.0)
		if absf(float(tracked_resources[i].get("auto_base_weight")) - final_value) > 0.000001:
			tracked_resources[i].set("auto_base_weight", final_value)
		result[tracked_keys[i]] = final_value
	return result


func _get_in_game_delta_hours(delta: float) -> float:
	var d: float = max(delta, 0.0)
	if use_clock_time and _clock != null:
		return d * max(_clock.minutes_per_real_second, 0.0) / 60.0
	return d * minutes_per_real_second_to_hours()


func _start_weather_blend() -> void:
	var duration_hours: float = max(weather_blend, 0.0)
	if duration_hours <= 0.0001:
		_weather_blend_factor = 1.0
		_weather_blend_elapsed_hours = duration_hours
		_weather_blend_in_progress = false
		return
	_weather_blend_factor = 0.0
	_weather_blend_elapsed_hours = 0.0
	_weather_blend_in_progress = true


func _update_weather_blend_progress(delta: float) -> void:
	var duration_hours: float = max(weather_blend, 0.0)
	if duration_hours <= 0.0001:
		_weather_blend_factor = 1.0
		_weather_blend_in_progress = false
		return
	if not _weather_blend_in_progress:
		return
	_weather_blend_elapsed_hours += _get_in_game_delta_hours(delta)
	_weather_blend_factor = clampf(_weather_blend_elapsed_hours / duration_hours, 0.0, 1.0)
	if _weather_blend_factor >= 0.999999:
		_weather_blend_factor = 1.0
		_weather_blend_in_progress = false


func _roll_weather_now() -> void:
	var selected_group_id: String = _pick_weather_group_id()
	var selected_condition: DensetsuWeatherCondition = _pick_weather_condition(selected_group_id)
	if selected_condition == null:
		selected_condition = _pick_weather_condition("")
	if selected_condition == null:
		return
	active_weather_id = selected_condition.weather_id


func _pick_weather_group_id() -> String:
	var override_group_id: String = weather_group_override_id.strip_edges()
	if not override_group_id.is_empty():
		return override_group_id
	if not weather_use_groups:
		return ""
	if weather_groups.is_empty():
		return ""
	var season_index: int = _get_season_index_for_weather()
	var weighted_groups: Array[Dictionary] = []
	for group_any in weather_groups:
		var group: DensetsuWeatherGroup = group_any as DensetsuWeatherGroup
		if group == null:
			continue
		if not group.auto_enabled:
			continue
		var group_id_value: String = group.group_id.strip_edges()
		if group_id_value.is_empty():
			continue
		var season_mult: float = max(group.get_auto_season_multiplier(season_index), 0.0)
		var weight: float = max(group.auto_base_weight, 0.0) * season_mult
		if weight <= 0.0:
			continue
		weighted_groups.append({
			"id": group_id_value,
			"weight": weight
		})
	if weighted_groups.is_empty():
		return ""
	var picked: Dictionary = _pick_weighted_entry(weighted_groups)
	return str(picked.get("id", ""))


func _pick_weather_condition(group_id_value: String) -> DensetsuWeatherCondition:
	var weighted_conditions: Array[Dictionary] = []
	var season_index: int = _get_season_index_for_weather()
	var normalized_group_id: String = group_id_value.strip_edges()
	for condition_any in weather_conditions:
		var condition: DensetsuWeatherCondition = condition_any as DensetsuWeatherCondition
		if condition == null:
			continue
		if not condition.auto_enabled:
			continue
		if condition.weather_id.strip_edges().is_empty():
			continue
		if not normalized_group_id.is_empty() and condition.weather_group_id.strip_edges() != normalized_group_id:
			continue
		var season_mult: float = max(condition.get_auto_season_multiplier(season_index), 0.0)
		var weight: float = max(condition.auto_base_weight, 0.0) * season_mult
		if weight <= 0.0:
			continue
		weighted_conditions.append({
			"condition": condition,
			"weight": weight
		})
	if weighted_conditions.is_empty():
		return null
	var picked: Dictionary = _pick_weighted_entry(weighted_conditions)
	var picked_any: Variant = picked.get("condition", null)
	if picked_any is DensetsuWeatherCondition:
		return picked_any as DensetsuWeatherCondition
	return null


func _pick_weighted_entry(entries: Array[Dictionary]) -> Dictionary:
	var total_weight: float = 0.0
	for entry in entries:
		var entry_weight: float = float(entry.get("weight", 0.0))
		total_weight += max(entry_weight, 0.0)
	if total_weight <= 0.0:
		return {}
	var roll: float = _weather_rng.randf() * total_weight
	var accum: float = 0.0
	for entry in entries:
		var entry_weight2: float = max(float(entry.get("weight", 0.0)), 0.0)
		accum += entry_weight2
		if roll <= accum:
			return entry
	return entries[entries.size() - 1]


func _get_season_index_for_weather() -> int:
	if _debug_force_season_override:
		return clampi(_debug_forced_season_index, 0, 3)
	var day_of_year_value: int = int(round(_resolve_day_of_year_value()))
	var days_per_year_value: int = max(int(round(_get_days_per_year_safe())), 1)
	var spring_start: int = _scale_day_365_to_year(season_spring_start_day_365, days_per_year_value)
	var summer_start: int = _scale_day_365_to_year(season_summer_start_day_365, days_per_year_value)
	var autumn_start: int = _scale_day_365_to_year(season_autumn_start_day_365, days_per_year_value)
	var winter_start: int = _scale_day_365_to_year(season_winter_start_day_365, days_per_year_value)
	var t: int = clampi(day_of_year_value, 1, days_per_year_value)
	if _is_day_in_range_wrapped(t, spring_start, summer_start, days_per_year_value):
		return 0
	if _is_day_in_range_wrapped(t, summer_start, autumn_start, days_per_year_value):
		return 1
	if _is_day_in_range_wrapped(t, autumn_start, winter_start, days_per_year_value):
		return 2
	return 3


func _scale_day_365_to_year(day_365: int, year_days: int) -> int:
	var clamped_365: int = clampi(day_365, 1, 365)
	var scaled: int = int(round((float(clamped_365 - 1) / 364.0) * float(max(year_days - 1, 0)))) + 1
	return clampi(scaled, 1, max(year_days, 1))


func _is_day_in_range_wrapped(day_value: int, start_day: int, end_day: int, year_days: int) -> bool:
	var d: int = clampi(day_value, 1, year_days)
	var start_value: int = clampi(start_day, 1, year_days)
	var end_value: int = clampi(end_day, 1, year_days)
	if start_value == end_value:
		return true
	if start_value < end_value:
		return d >= start_value and d < end_value
	return d >= start_value or d < end_value


func _ensure_debug_ui() -> void:
	if not debug_ui_enabled:
		if _debug_ui_layer != null:
			_debug_ui_layer.visible = false
		return
	if _debug_ui_layer == null or not is_instance_valid(_debug_ui_layer):
		_build_debug_ui()
	if _debug_ui_layer != null:
		_debug_ui_layer.visible = true
	if _debug_ui_panel != null:
		_debug_ui_panel.position = debug_ui_offset


func _build_debug_ui() -> void:
	_debug_ui_layer = CanvasLayer.new()
	_debug_ui_layer.name = "_SkyDebugUI"
	_debug_ui_layer.layer = 80
	add_child(_debug_ui_layer)

	_debug_ui_panel = PanelContainer.new()
	_debug_ui_panel.name = "Panel"
	_debug_ui_panel.position = debug_ui_offset
	_debug_ui_panel.custom_minimum_size = Vector2(520.0, 320.0)
	_debug_ui_layer.add_child(_debug_ui_panel)

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.name = "RootVBox"
	_debug_ui_panel.add_child(root_vbox)

	var title: Label = Label.new()
	title.text = "Densetsu Sky Debug"
	root_vbox.add_child(title)

	var clock_row: HBoxContainer = HBoxContainer.new()
	root_vbox.add_child(clock_row)
	_debug_clock_label = Label.new()
	_debug_clock_label.text = "Clock --:--:--"
	_debug_clock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clock_row.add_child(_debug_clock_label)
	clock_row.add_child(_debug_make_button("Run/Pause", Callable(self, "_on_debug_toggle_clock_running")))
	clock_row.add_child(_debug_make_button("-1h", Callable(self, "_on_debug_adjust_minutes").bind(-60)))
	clock_row.add_child(_debug_make_button("+1h", Callable(self, "_on_debug_adjust_minutes").bind(60)))
	clock_row.add_child(_debug_make_button("-10m", Callable(self, "_on_debug_adjust_minutes").bind(-10)))
	clock_row.add_child(_debug_make_button("+10m", Callable(self, "_on_debug_adjust_minutes").bind(10)))

	var timescale_row: HBoxContainer = HBoxContainer.new()
	root_vbox.add_child(timescale_row)
	_debug_timescale_label = Label.new()
	_debug_timescale_label.text = "Time Scale 10.0 min/s"
	_debug_timescale_label.custom_minimum_size = Vector2(170.0, 0.0)
	timescale_row.add_child(_debug_timescale_label)
	_debug_timescale_slider = HSlider.new()
	_debug_timescale_slider.min_value = 0.0
	_debug_timescale_slider.max_value = 1200.0
	_debug_timescale_slider.step = 0.01
	_debug_timescale_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_debug_timescale_slider.value_changed.connect(Callable(self, "_on_debug_timescale_slider_changed"))
	timescale_row.add_child(_debug_timescale_slider)
	_debug_timescale_spin = SpinBox.new()
	_debug_timescale_spin.min_value = 0.0
	_debug_timescale_spin.max_value = 1200.0
	_debug_timescale_spin.step = 0.01
	_debug_timescale_spin.custom_minimum_size = Vector2(110.0, 0.0)
	_debug_timescale_spin.value_changed.connect(Callable(self, "_on_debug_timescale_spin_changed"))
	timescale_row.add_child(_debug_timescale_spin)

	var calendar_row: HBoxContainer = HBoxContainer.new()
	root_vbox.add_child(calendar_row)
	_debug_calendar_label = Label.new()
	_debug_calendar_label.text = "Date ----/--/--"
	_debug_calendar_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calendar_row.add_child(_debug_calendar_label)
	calendar_row.add_child(_debug_make_button("-1d", Callable(self, "_on_debug_adjust_days").bind(-1)))
	calendar_row.add_child(_debug_make_button("+1d", Callable(self, "_on_debug_adjust_days").bind(1)))
	calendar_row.add_child(_debug_make_button("-1m", Callable(self, "_on_debug_adjust_months").bind(-1)))
	calendar_row.add_child(_debug_make_button("+1m", Callable(self, "_on_debug_adjust_months").bind(1)))
	calendar_row.add_child(_debug_make_button("-1y", Callable(self, "_on_debug_adjust_years").bind(-1)))
	calendar_row.add_child(_debug_make_button("+1y", Callable(self, "_on_debug_adjust_years").bind(1)))

	var season_row: HBoxContainer = HBoxContainer.new()
	root_vbox.add_child(season_row)
	_debug_season_label = Label.new()
	_debug_season_label.text = "Season: --"
	_debug_season_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	season_row.add_child(_debug_season_label)
	season_row.add_child(_debug_make_button("<", Callable(self, "_on_debug_cycle_season").bind(-1)))
	season_row.add_child(_debug_make_button(">", Callable(self, "_on_debug_cycle_season").bind(1)))
	season_row.add_child(_debug_make_button("Auto", Callable(self, "_on_debug_season_auto")))
	season_row.add_child(_debug_make_button("Reroll", Callable(self, "_on_debug_force_weather_reroll")))

	var icon_row: HBoxContainer = HBoxContainer.new()
	root_vbox.add_child(icon_row)
	var icon_label: Label = Label.new()
	icon_label.text = "Weather Icon:"
	icon_row.add_child(icon_label)
	_debug_weather_icon = TextureRect.new()
	_debug_weather_icon.custom_minimum_size = Vector2(32.0, 32.0)
	_debug_weather_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_debug_weather_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_row.add_child(_debug_weather_icon)

	var stack_title: Label = Label.new()
	stack_title.text = "Weather Stack (double click to force)"
	root_vbox.add_child(stack_title)
	_debug_weather_stack_label = RichTextLabel.new()
	_debug_weather_stack_label.bbcode_enabled = true
	_debug_weather_stack_label.scroll_active = true
	_debug_weather_stack_label.custom_minimum_size = Vector2(500.0, 120.0)
	_debug_weather_stack_label.meta_clicked.connect(Callable(self, "_on_debug_weather_stack_meta_clicked"))
	root_vbox.add_child(_debug_weather_stack_label)

	var timeline_title: Label = Label.new()
	timeline_title.text = "Weather Timeline"
	root_vbox.add_child(timeline_title)
	_debug_timeline_bar = ProgressBar.new()
	_debug_timeline_bar.min_value = 0.0
	_debug_timeline_bar.max_value = 1.0
	_debug_timeline_bar.step = 0.001
	root_vbox.add_child(_debug_timeline_bar)
	_debug_timeline_label = Label.new()
	_debug_timeline_label.text = "Start --  Now --  End --"
	root_vbox.add_child(_debug_timeline_label)


func _debug_make_button(text_value: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	return button


func _on_debug_toggle_clock_running() -> void:
	clock_running = not clock_running
	if _clock != null:
		_clock.running = clock_running


func _on_debug_adjust_minutes(delta_minutes: int) -> void:
	if _clock != null:
		_clock.advance_minutes(delta_minutes)
		return
	manual_time_hours = _normalize_hours_24(manual_time_hours + float(delta_minutes) / 60.0)


func _on_debug_timescale_slider_changed(value: float) -> void:
	_on_debug_timescale_changed(value)


func _on_debug_timescale_spin_changed(value: float) -> void:
	_on_debug_timescale_changed(value)


func _on_debug_timescale_changed(value: float) -> void:
	if _debug_timescale_ui_syncing:
		return
	var clamped_value: float = clampf(value, 0.0, 1200.0)
	clock_minutes_per_real_second = clamped_value
	if _clock != null:
		_clock.minutes_per_real_second = clamped_value


func _on_debug_adjust_days(delta_days: int) -> void:
	if _clock == null:
		return
	_clock.advance_minutes(delta_days * 1440)


func _on_debug_adjust_months(delta_months: int) -> void:
	if _clock == null:
		return
	var month_count: int = max(_clock.month_lengths.size(), 1)
	var new_month: int = _clock.month + delta_months
	var new_year: int = _clock.year
	while new_month > month_count:
		new_month -= month_count
		new_year += 1
	while new_month < 1:
		new_month += month_count
		new_year = max(new_year - 1, 1)
	_clock.year = new_year
	_clock.month = new_month
	_clamp_clock_day_to_month()


func _on_debug_adjust_years(delta_years: int) -> void:
	if _clock == null:
		return
	_clock.year = max(_clock.year + delta_years, 1)
	_clamp_clock_day_to_month()


func _clamp_clock_day_to_month() -> void:
	if _clock == null:
		return
	var month_count: int = _clock.month_lengths.size()
	if month_count <= 0:
		_clock.day = clampi(_clock.day, 1, 30)
		return
	_clock.month = clampi(_clock.month, 1, month_count)
	var idx: int = _clock.month - 1
	var max_day: int = max(_clock.month_lengths[idx], 1)
	_clock.day = clampi(_clock.day, 1, max_day)


func _on_debug_cycle_season(direction: int) -> void:
	_debug_force_season_override = true
	_debug_forced_season_index = posmod(_debug_forced_season_index + direction, 4)


func _on_debug_season_auto() -> void:
	_debug_force_season_override = false


func _on_debug_force_weather_reroll() -> void:
	_roll_weather_now()
	if weather_auto_enabled:
		_weather_hours_until_reroll = _get_next_weather_hold_hours()
		_weather_segment_start_hours = _weather_elapsed_total_hours
		_weather_segment_end_hours = _weather_segment_start_hours + _weather_hours_until_reroll


func _on_debug_weather_stack_meta_clicked(meta: Variant) -> void:
	var raw_meta: String = str(meta)
	var prefix: String = "weather:"
	if not raw_meta.begins_with(prefix):
		return
	var weather_id_value: String = raw_meta.substr(prefix.length())
	if weather_id_value.is_empty():
		return
	var now_ms: int = Time.get_ticks_msec()
	var is_double_click: bool = weather_id_value == _debug_weather_stack_last_click_id and (now_ms - _debug_weather_stack_last_click_ms) <= 450
	_debug_weather_stack_last_click_id = weather_id_value
	_debug_weather_stack_last_click_ms = now_ms
	if not is_double_click:
		return
	_force_debug_weather(weather_id_value)
	_debug_weather_stack_last_click_id = ""
	_debug_weather_stack_last_click_ms = -1000000


func _force_debug_weather(weather_id_value: String) -> void:
	var target_weather: DensetsuWeatherCondition = _get_weather_by_id(weather_id_value)
	if target_weather == null:
		return
	active_weather_id = weather_id_value
	_update_active_weather()
	if weather_auto_enabled:
		_weather_hours_until_reroll = _get_next_weather_hold_hours()
		_weather_segment_start_hours = _weather_elapsed_total_hours
		_weather_segment_end_hours = _weather_segment_start_hours + _weather_hours_until_reroll


func _update_debug_ui() -> void:
	if not debug_ui_enabled:
		return
	if _debug_ui_layer == null:
		return
	_debug_ui_layer.visible = true
	if _debug_ui_panel != null:
		_debug_ui_panel.position = debug_ui_offset

	if _debug_clock_label != null:
		var running_text: String = "RUN"
		if not clock_running:
			running_text = "PAUSE"
		var rate_minutes_per_second: float = max(clock_minutes_per_real_second, 0.0)
		if _clock != null:
			rate_minutes_per_second = max(_clock.minutes_per_real_second, 0.0)
		if _clock != null:
			_debug_clock_label.text = "Clock %s  %02d:%02d:%02d  (%.1f min/s)" % [running_text, _clock.hour, _clock.minute, _clock.second, rate_minutes_per_second]
		else:
			var h: float = _normalize_hours_24(manual_time_hours)
			var hour_int: int = int(floor(h))
			var minute_int: int = int(floor((h - float(hour_int)) * 60.0))
			_debug_clock_label.text = "Clock %s  %02d:%02d  (%.1f min/s)" % [running_text, hour_int, minute_int, rate_minutes_per_second]

		if _debug_timescale_label != null:
			_debug_timescale_label.text = "Time Scale %.1f min/s" % rate_minutes_per_second
		_debug_timescale_ui_syncing = true
		if _debug_timescale_slider != null and absf(_debug_timescale_slider.value - rate_minutes_per_second) > 0.0001:
			_debug_timescale_slider.value = rate_minutes_per_second
		if _debug_timescale_spin != null and absf(_debug_timescale_spin.value - rate_minutes_per_second) > 0.0001:
			_debug_timescale_spin.value = rate_minutes_per_second
		_debug_timescale_ui_syncing = false

	if _debug_calendar_label != null:
		if _clock != null:
			_debug_calendar_label.text = "Date %04d-%02d-%02d" % [_clock.year, _clock.month, _clock.day]
		else:
			_debug_calendar_label.text = "Date (manual time mode)"

	var season_index: int = _get_season_index_for_weather()
	if _debug_season_label != null:
		var season_mode_text: String = "Auto"
		if _debug_force_season_override:
			season_mode_text = "Forced"
		_debug_season_label.text = "Season: %s (%s)" % [_season_name_from_index(season_index), season_mode_text]

	if _debug_weather_icon != null:
		var icon_tex: Texture2D = null
		if _active_weather != null:
			icon_tex = _active_weather.ui_icon
		_debug_weather_icon.visible = debug_ui_show_weather_icon and icon_tex != null
		_debug_weather_icon.texture = icon_tex

	if _debug_weather_stack_label != null:
		_debug_weather_stack_label.clear()
		_debug_weather_stack_label.append_text(_build_debug_weather_stack_bbcode(season_index))

	if _debug_timeline_bar != null and _debug_timeline_label != null:
		var start_hours: float = _weather_segment_start_hours
		var end_hours: float = _weather_segment_end_hours
		var now_hours: float = _weather_elapsed_total_hours
		if not weather_auto_enabled:
			now_hours = _resolve_total_days_value(_resolve_day_of_year_value(), _get_time_hours()) * 24.0
		var span: float = max(end_hours - start_hours, 0.0001)
		var progress: float = clampf((now_hours - start_hours) / span, 0.0, 1.0)
		if not weather_auto_enabled or end_hours <= start_hours:
			progress = 0.0
		_debug_timeline_bar.value = progress
		var active_id: String = active_weather_id
		if active_id.is_empty():
			active_id = "none"
		_debug_timeline_label.text = "Active: %s | Start %s | Now %s | End %s" % [
			active_id,
			_format_total_hours_for_debug(start_hours),
			_format_total_hours_for_debug(now_hours),
			_format_total_hours_for_debug(end_hours)
		]


func _build_debug_weather_stack_bbcode(season_index: int) -> String:
	if weather_conditions.is_empty():
		return "[color=#aaaaaa]No weather conditions configured.[/color]"
	var weights: Dictionary = {}
	var total_weight: float = 0.0
	for condition_any in weather_conditions:
		var condition: DensetsuWeatherCondition = condition_any as DensetsuWeatherCondition
		if condition == null:
			continue
		var w: float = _effective_auto_weight_for_condition(condition, season_index)
		weights[condition.weather_id] = w
		total_weight += max(w, 0.0)
	var lines: PackedStringArray = PackedStringArray()
	for condition_any in weather_conditions:
		var condition2: DensetsuWeatherCondition = condition_any as DensetsuWeatherCondition
		if condition2 == null:
			continue
		var id_value: String = condition2.weather_id
		var is_active: bool = id_value == active_weather_id
		var w2: float = float(weights.get(id_value, 0.0))
		var quota_percent: float = 0.0
		if total_weight > 0.0:
			quota_percent = (w2 / total_weight) * 100.0
		var marker: String = "  "
		if is_active:
			marker = "> "
		var line: String = "%s%s [grp:%s]  w=%.3f  q=%.2f%%" % [
			marker,
			id_value,
			condition2.weather_group_id,
			w2,
			quota_percent
		]
		var link_line: String = "[url=weather:%s]%s[/url]" % [id_value, line]
		if is_active:
			lines.append("[color=#7dd3fc]" + link_line + "[/color]")
		elif w2 <= 0.0:
			lines.append("[color=#777777]" + link_line + "[/color]")
		else:
			lines.append(link_line)
	return "\n".join(lines)


func _effective_auto_weight_for_condition(condition: DensetsuWeatherCondition, season_index: int) -> float:
	if condition == null:
		return 0.0
	if not condition.auto_enabled:
		return 0.0
	var season_mult: float = max(condition.get_auto_season_multiplier(season_index), 0.0)
	var condition_weight: float = max(condition.auto_base_weight, 0.0) * season_mult
	if condition_weight <= 0.0:
		return 0.0
	if not weather_auto_enabled:
		return condition_weight
	if weather_group_override_id.strip_edges() != "":
		if condition.weather_group_id.strip_edges() != weather_group_override_id.strip_edges():
			return 0.0
		return condition_weight
	if not weather_use_groups:
		return condition_weight
	if weather_groups.is_empty():
		return condition_weight
	var group_weight: float = _effective_auto_weight_for_group(condition.weather_group_id, season_index)
	if group_weight <= 0.0:
		return 0.0
	return condition_weight * group_weight


func _effective_auto_weight_for_group(group_id_value: String, season_index: int) -> float:
	var normalized_group: String = group_id_value.strip_edges()
	if normalized_group.is_empty():
		return 0.0
	for group_any in weather_groups:
		var group: DensetsuWeatherGroup = group_any as DensetsuWeatherGroup
		if group == null:
			continue
		if not group.auto_enabled:
			continue
		if group.group_id.strip_edges() != normalized_group:
			continue
		var season_mult: float = max(group.get_auto_season_multiplier(season_index), 0.0)
		return max(group.auto_base_weight, 0.0) * season_mult
	return 0.0


func _season_name_from_index(season_index: int) -> String:
	match season_index:
		0:
			return "Spring"
		1:
			return "Summer"
		2:
			return "Autumn"
		_:
			return "Winter"


func _format_total_hours_for_debug(total_hours: float) -> String:
	var safe_hours: float = max(total_hours, 0.0)
	var total_minutes: int = int(floor(safe_hours * 60.0))
	var total_days: int = total_minutes / (24 * 60)
	var minutes_in_day: int = total_minutes % (24 * 60)
	var hour_value: int = minutes_in_day / 60
	var minute_value: int = minutes_in_day % 60
	return "D%04d %02d:%02d" % [total_days + 1, hour_value, minute_value]


func _update_active_weather() -> void:
	var found: DensetsuWeatherCondition = _get_weather_by_id(active_weather_id)
	if found == _active_weather and _active_weather_id_cached == active_weather_id:
		return
	var had_previous_weather: bool = _active_weather != null or not _active_weather_id_cached.is_empty()
	_active_weather = found
	_active_weather_id_cached = active_weather_id
	if had_previous_weather:
		_start_weather_blend()
	else:
		_weather_blend_factor = 1.0
		_weather_blend_elapsed_hours = max(weather_blend, 0.0)
		_weather_blend_in_progress = false
	if not weather_auto_enabled:
		_weather_segment_start_hours = _weather_elapsed_total_hours
		_weather_segment_end_hours = _weather_segment_start_hours
	_assign_weather_particle_instances()
	_reset_thunder_runtime()


func _get_weather_by_id(id_value: String) -> DensetsuWeatherCondition:
	if id_value.is_empty():
		return null
	for condition_any in weather_conditions:
		var condition: DensetsuWeatherCondition = condition_any as DensetsuWeatherCondition
		if condition == null:
			continue
		if condition.weather_id == id_value:
			return condition
	return null


func _assign_weather_particle_instances() -> void:
	_weather_near_instance = _assign_weather_tier_instance(_weather_near_tier, _weather_near_instance, _get_weather_tier_scene(0))
	_weather_mid_instance = _assign_weather_tier_instance(_weather_mid_tier, _weather_mid_instance, _get_weather_tier_scene(1))
	_weather_far_instance = _assign_weather_tier_instance(_weather_far_tier, _weather_far_instance, _get_weather_tier_scene(2))


func _get_weather_tier_scene(tier_index: int) -> PackedScene:
	if _active_weather == null:
		return null
	if tier_index == 0:
		return _active_weather.near_particles_scene
	if tier_index == 1:
		return _active_weather.mid_particles_scene
	return _active_weather.far_particles_scene


func _assign_weather_tier_instance(parent_tier: Node3D, existing: Node, scene: PackedScene) -> Node:
	if parent_tier == null:
		return null
	if existing != null and not is_instance_valid(existing):
		existing = null

	var tier_children: Array[Node] = []
	for child_any in parent_tier.get_children():
		var child: Node = child_any as Node
		if child != null:
			tier_children.append(child)

	if scene == null:
		if existing != null:
			existing.queue_free()
		for child in tier_children:
			if child != existing:
				child.queue_free()
		return null

	var existing_scene_path: String = ""
	if existing != null and not existing.scene_file_path.is_empty():
		existing_scene_path = existing.scene_file_path
	var target_scene_path: String = scene.resource_path
	var reuse: Node = null
	if existing != null and existing_scene_path == target_scene_path:
		reuse = existing
	else:
		for child in tier_children:
			if child != null and not child.scene_file_path.is_empty() and child.scene_file_path == target_scene_path:
				reuse = child
				break

	if reuse == null:
		var created: Node = scene.instantiate()
		if created == null:
			return null
		parent_tier.add_child(created)
		if Engine.is_editor_hint():
			var edited_root: Node = get_tree().edited_scene_root
			if edited_root != null:
				created.owner = edited_root
		reuse = created

	for child in tier_children:
		if child != reuse:
			child.queue_free()
	if existing != null and existing != reuse:
		existing.queue_free()

	return reuse


func _update_weather_tiers() -> void:
	var camera: Camera3D = _resolve_weather_camera()
	if camera == null:
		if _weather_root != null:
			_weather_root.visible = false
		return
	if _weather_root != null:
		_weather_root.visible = true

	var cam_transform: Transform3D = camera.global_transform
	var forward: Vector3 = -cam_transform.basis.z.normalized()
	var origin: Vector3 = cam_transform.origin

	if _weather_near_tier != null:
		_weather_near_tier.global_position = origin + forward * weather_near_distance
	if _weather_mid_tier != null:
		_weather_mid_tier.global_position = origin + forward * weather_mid_distance
	if _weather_far_tier != null:
		_weather_far_tier.global_position = origin + forward * weather_far_distance

	var near_mult: float = weather_emission_multiplier
	var mid_mult: float = weather_emission_multiplier
	var far_mult: float = weather_emission_multiplier

	if _active_weather != null:
		near_mult *= _active_weather.near_emission_multiplier
		mid_mult *= _active_weather.mid_emission_multiplier
		far_mult *= _active_weather.far_emission_multiplier

	if _is_indoors:
		near_mult *= 0.8
		mid_mult *= 0.5
		if _active_weather != null and _active_weather.disable_far_indoors:
			far_mult = 0.0
		else:
			far_mult *= 0.2

	_apply_particles_state(_weather_near_instance, near_mult > 0.001, near_mult)
	_apply_particles_state(_weather_mid_instance, mid_mult > 0.001, mid_mult)
	_apply_particles_state(_weather_far_instance, far_mult > 0.001, far_mult)


func _resolve_weather_camera() -> Camera3D:
	if _weather_camera != null:
		return _weather_camera
	if not weather_camera_path.is_empty():
		_weather_camera = get_node_or_null(weather_camera_path) as Camera3D
		if _weather_camera != null:
			return _weather_camera
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return null
	return viewport.get_camera_3d()


func _apply_particles_state(node: Node, enabled: bool, emission_multiplier: float) -> void:
	if node == null:
		return
	if node is GPUParticles3D:
		var gpu: GPUParticles3D = node as GPUParticles3D
		gpu.emitting = enabled
		gpu.speed_scale = max(emission_multiplier, 0.0)
		if _object_has_property(gpu, "amount_ratio"):
			var ratio: float = clampf(emission_multiplier, 0.0, 1.0)
			gpu.set("amount_ratio", ratio)
	elif node is CPUParticles3D:
		var cpu: CPUParticles3D = node as CPUParticles3D
		cpu.emitting = enabled
		cpu.speed_scale = max(emission_multiplier, 0.0)

	for child_any in node.get_children():
		var child: Node = child_any as Node
		if child != null:
			_apply_particles_state(child, enabled, emission_multiplier)


func _update_thunder_and_lightning(delta: float) -> void:
	_update_lightning_bolt_visual(delta)
	var condition: DensetsuWeatherCondition = _active_weather
	if condition == null or not condition.thunder_enabled or _weather_blend_factor <= 0.0001:
		_reset_thunder_runtime()
		return
	if condition.lightning_draw_bolts:
		_ensure_lightning_overlay()

	if _thunder_current_pulse_time_left > 0.0:
		_thunder_current_pulse_time_left = max(_thunder_current_pulse_time_left - max(delta, 0.0), 0.0)
		var pulse_progress: float = 1.0
		if _thunder_current_pulse_duration > 0.000001:
			pulse_progress = 1.0 - (_thunder_current_pulse_time_left / _thunder_current_pulse_duration)
		pulse_progress = clampf(pulse_progress, 0.0, 1.0)
		# Fast rise, softer fall for a lightning-like pulse envelope.
		var rise: float = clampf(pulse_progress / 0.12, 0.0, 1.0)
		var fall: float = clampf((1.0 - pulse_progress) / 0.88, 0.0, 1.0)
		_thunder_current_pulse_intensity = min(rise, fall) * clampf(_weather_blend_factor, 0.0, 1.0)
		return

	_thunder_current_pulse_intensity = 0.0
	if _thunder_pulses_remaining > 0:
		_thunder_seconds_to_next_pulse -= max(delta, 0.0)
		if _thunder_seconds_to_next_pulse <= 0.0:
			_start_thunder_pulse(condition)
		return

	if _thunder_seconds_to_next_strike < 0.0:
		_schedule_next_thunder_strike(condition)
	_thunder_seconds_to_next_strike -= max(delta, 0.0)
	if _thunder_seconds_to_next_strike <= 0.0:
		_begin_thunder_strike(condition)


func _reset_thunder_runtime() -> void:
	_thunder_seconds_to_next_strike = -1.0
	_thunder_pulses_remaining = 0
	_thunder_seconds_to_next_pulse = 0.0
	_thunder_current_pulse_time_left = 0.0
	_thunder_current_pulse_duration = 0.0
	_thunder_current_pulse_energy_mult = 1.0
	_thunder_current_pulse_intensity = 0.0
	_thunder_current_color_lerp = 0.0
	_thunder_current_sky_tint_strength = 0.0
	_thunder_current_tint = Color(1.0, 1.0, 1.0, 1.0)
	_lightning_bolt_time_left = 0.0
	if _lightning_bolt_line != null:
		_lightning_bolt_line.visible = false


func _schedule_next_thunder_strike(condition: DensetsuWeatherCondition) -> void:
	if condition == null:
		_thunder_seconds_to_next_strike = 1.0e20
		return
	var strikes_per_minute: float = max(condition.lightning_strikes_per_minute * clampf(_weather_blend_factor, 0.0, 1.0), 0.0)
	if strikes_per_minute <= 0.000001:
		_thunder_seconds_to_next_strike = 1.0e20
		return
	var mean_interval_seconds: float = 60.0 / strikes_per_minute
	var min_interval: float = max(mean_interval_seconds * 0.45, 0.01)
	var max_interval: float = max(mean_interval_seconds * 1.55, min_interval)
	_thunder_seconds_to_next_strike = _weather_rng.randf_range(min_interval, max_interval)


func _begin_thunder_strike(condition: DensetsuWeatherCondition) -> void:
	if condition == null:
		return
	var pulse_min: int = max(condition.lightning_pulses_per_strike_min, 1)
	var pulse_max: int = max(condition.lightning_pulses_per_strike_max, pulse_min)
	_thunder_pulses_remaining = _weather_rng.randi_range(pulse_min, pulse_max)
	_start_thunder_pulse(condition)
	# Will be rescheduled after pulses complete.
	_thunder_seconds_to_next_strike = -1.0


func _start_thunder_pulse(condition: DensetsuWeatherCondition) -> void:
	if condition == null:
		return
	if _thunder_pulses_remaining <= 0:
		return
	_thunder_pulses_remaining -= 1
	var duration_min: float = max(condition.lightning_pulse_min_duration, 0.01)
	var duration_max: float = max(condition.lightning_pulse_max_duration, duration_min)
	_thunder_current_pulse_duration = _weather_rng.randf_range(duration_min, duration_max)
	_thunder_current_pulse_time_left = _thunder_current_pulse_duration
	var energy_min: float = max(condition.lightning_energy_multiplier_min, 1.0)
	var energy_max: float = max(condition.lightning_energy_multiplier_max, energy_min)
	_thunder_current_pulse_energy_mult = _weather_rng.randf_range(energy_min, energy_max)
	_thunder_current_color_lerp = clampf(condition.lightning_color_lerp * _weather_blend_factor, 0.0, 1.0)
	_thunder_current_sky_tint_strength = clampf(condition.lightning_sky_tint_strength * _weather_blend_factor, 0.0, 1.0)
	var pulse_tint: Color = condition.lightning_tint
	if condition.lightning_color_gradient != null:
		pulse_tint = condition.lightning_color_gradient.sample(_weather_rng.randf())
	_thunder_current_tint = pulse_tint
	_thunder_current_pulse_intensity = clampf(_weather_blend_factor, 0.0, 1.0)

	if condition.lightning_draw_bolts:
		_spawn_lightning_bolt(condition)

	if _thunder_pulses_remaining > 0:
		var gap_min: float = max(condition.lightning_pulse_gap_min, 0.01)
		var gap_max: float = max(condition.lightning_pulse_gap_max, gap_min)
		_thunder_seconds_to_next_pulse = _weather_rng.randf_range(gap_min, gap_max)
	else:
		_thunder_seconds_to_next_pulse = 0.0


func _ensure_lightning_overlay() -> void:
	if _lightning_overlay_layer == null or not is_instance_valid(_lightning_overlay_layer):
		var created_layer: CanvasLayer = CanvasLayer.new()
		created_layer.name = LIGHTNING_OVERLAY_LAYER_NODE_NAME
		created_layer.layer = 79
		add_child(created_layer)
		if Engine.is_editor_hint():
			var edited_root: Node = get_tree().edited_scene_root
			if edited_root != null:
				created_layer.owner = edited_root
		_lightning_overlay_layer = created_layer

	if _lightning_overlay_root == null or not is_instance_valid(_lightning_overlay_root):
		var created_root: Control = Control.new()
		created_root.name = LIGHTNING_OVERLAY_ROOT_NODE_NAME
		created_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		created_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		created_root.offset_left = 0.0
		created_root.offset_top = 0.0
		created_root.offset_right = 0.0
		created_root.offset_bottom = 0.0
		_lightning_overlay_layer.add_child(created_root)
		if Engine.is_editor_hint():
			var edited_root2: Node = get_tree().edited_scene_root
			if edited_root2 != null:
				created_root.owner = edited_root2
		_lightning_overlay_root = created_root

	if _lightning_bolt_line == null or not is_instance_valid(_lightning_bolt_line):
		var created_line: Line2D = Line2D.new()
		created_line.name = LIGHTNING_BOLT_NODE_NAME
		created_line.default_color = Color(1.0, 1.0, 1.0, 0.0)
		created_line.width = 3.0
		created_line.visible = false
		created_line.antialiased = true
		_lightning_overlay_root.add_child(created_line)
		if Engine.is_editor_hint():
			var edited_root3: Node = get_tree().edited_scene_root
			if edited_root3 != null:
				created_line.owner = edited_root3
		_lightning_bolt_line = created_line


func _spawn_lightning_bolt(condition: DensetsuWeatherCondition) -> void:
	if condition == null:
		return
	_ensure_lightning_overlay()
	if _lightning_bolt_line == null:
		return
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var visible_rect: Rect2 = viewport.get_visible_rect()
	var viewport_size: Vector2 = visible_rect.size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return

	var start_x: float = _weather_rng.randf_range(viewport_size.x * 0.08, viewport_size.x * 0.92)
	var end_x: float = start_x + _weather_rng.randf_range(-viewport_size.x * 0.25, viewport_size.x * 0.25)
	var start_y: float = -viewport_size.y * 0.05
	var end_y: float = _weather_rng.randf_range(viewport_size.y * 0.45, viewport_size.y * 0.92)
	var segment_count: int = clampi(condition.lightning_bolt_segments, 2, 64)
	var jitter_pixels: float = clampf(condition.lightning_bolt_jitter, 0.0, 1.0) * viewport_size.x * 0.35
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(segment_count + 1):
		var t: float = float(i) / float(segment_count)
		var x_value: float = lerpf(start_x, end_x, t)
		var y_value: float = lerpf(start_y, end_y, t)
		if i != 0 and i != segment_count:
			x_value += _weather_rng.randf_range(-jitter_pixels, jitter_pixels) * (1.0 - t * 0.7)
		points.append(Vector2(x_value, y_value))
	_lightning_bolt_line.points = points
	_lightning_bolt_line.width = max(condition.lightning_bolt_width, 1.0)
	_lightning_bolt_line.texture = condition.lightning_bolt_texture
	if condition.lightning_bolt_texture != null and _object_has_property(_lightning_bolt_line, "texture_mode"):
		_lightning_bolt_line.set("texture_mode", Line2D.LINE_TEXTURE_STRETCH)
	var alpha_value: float = clampf(condition.lightning_bolt_alpha * _weather_blend_factor, 0.0, 1.0)
	_lightning_bolt_base_color = Color(_thunder_current_tint.r, _thunder_current_tint.g, _thunder_current_tint.b, alpha_value)
	_lightning_bolt_line.default_color = _lightning_bolt_base_color
	_lightning_bolt_line.visible = true
	_lightning_bolt_lifetime = max(condition.lightning_bolt_lifetime, 0.01)
	_lightning_bolt_time_left = _lightning_bolt_lifetime


func _update_lightning_bolt_visual(delta: float) -> void:
	if _lightning_bolt_line == null:
		return
	if _lightning_bolt_time_left <= 0.0:
		_lightning_bolt_line.visible = false
		return
	_lightning_bolt_time_left = max(_lightning_bolt_time_left - max(delta, 0.0), 0.0)
	if _lightning_bolt_time_left <= 0.0:
		_lightning_bolt_line.visible = false
		return
	var life_ratio: float = 1.0
	if _lightning_bolt_lifetime > 0.000001:
		life_ratio = clampf(_lightning_bolt_time_left / _lightning_bolt_lifetime, 0.0, 1.0)
	var color_now: Color = _lightning_bolt_base_color
	color_now.a *= life_ratio
	_lightning_bolt_line.default_color = color_now
	_lightning_bolt_line.visible = true


func _object_has_property(obj: Object, property_name: String) -> bool:
	if obj == null:
		return false
	var plist: Array = obj.get_property_list()
	for prop_any in plist:
		if not (prop_any is Dictionary):
			continue
		var prop: Dictionary = prop_any as Dictionary
		var name_value: String = str(prop.get("name", ""))
		if name_value == property_name:
			return true
	return false


func _update_indoor_detection(delta: float) -> void:
	if not indoor_detection_enabled:
		_is_indoors = false
		return
	_indoor_accum += delta
	if _indoor_accum < indoor_check_interval:
		return
	_indoor_accum = 0.0

	var camera: Camera3D = _resolve_weather_camera()
	if camera == null:
		_is_indoors = false
		return
	var world: World3D = get_world_3d()
	if world == null:
		_is_indoors = false
		return
	var from: Vector3 = camera.global_position
	var to: Vector3 = from + Vector3.UP * indoor_check_height
	var params: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_areas = true
	params.collide_with_bodies = true
	var result: Dictionary = world.direct_space_state.intersect_ray(params)
	_is_indoors = not result.is_empty()


func _ensure_sky_material() -> void:
	if _world_environment == null:
		return
	_environment = _world_environment.environment
	if _environment == null:
		_environment = Environment.new()
		_world_environment.environment = _environment

	if _sky_shader == null:
		_sky_shader = load(SKY_SHADER_PATH) as Shader
		if _sky_shader == null and not _warned_missing_shader:
			push_warning("DensetsuSkySystem3D: missing sky shader: " + SKY_SHADER_PATH)
			_warned_missing_shader = true
			return
	if not _is_sky_shader_usable(_sky_shader):
		if not _warned_invalid_shader:
			push_warning("DensetsuSkySystem3D: shader failed validation/compile: " + SKY_SHADER_PATH)
			_warned_invalid_shader = true
		_apply_fallback_sky()
		return

	if _sky_material == null:
		_sky_material = ShaderMaterial.new()
	_sky_material.resource_local_to_scene = true
	if _sky_material.shader != _sky_shader:
		_sky_material.shader = _sky_shader

	if _sky == null:
		_sky = Sky.new()
	if _sky.sky_material != _sky_material:
		_sky.sky_material = _sky_material
	if _object_has_property(_sky, "process_mode"):
		_sky.set("process_mode", 1)

	if apply_sky_to_environment:
		if _environment.background_mode != Environment.BG_SKY:
			_environment.background_mode = Environment.BG_SKY
		if _environment.sky != _sky:
			_environment.sky = _sky


func _apply_fallback_sky() -> void:
	if _environment == null:
		return
	if _sky == null:
		_sky = Sky.new()
	if not (_sky.sky_material is ProceduralSkyMaterial):
		var fallback_material: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
		fallback_material.sky_top_color = Color(0.16, 0.25, 0.4, 1.0)
		fallback_material.sky_horizon_color = Color(0.45, 0.55, 0.7, 1.0)
		fallback_material.ground_horizon_color = Color(0.2, 0.2, 0.22, 1.0)
		fallback_material.ground_bottom_color = Color(0.08, 0.08, 0.1, 1.0)
		_sky.sky_material = fallback_material
	if apply_sky_to_environment:
		if _environment.background_mode != Environment.BG_SKY:
			_environment.background_mode = Environment.BG_SKY
		if _environment.sky != _sky:
			_environment.sky = _sky


func _capture_base_state() -> void:
	if _sun_light != null and not _base_sun_state_captured:
		var captured_sun_energy: float = max(_sun_light.light_energy, 0.0)
		if captured_sun_energy <= 0.000001:
			var min_sun_base: float = max(_safe_numeric_float(minimum_sun_base_energy, 1.0), 0.0)
			captured_sun_energy = max(_base_sun_energy, min_sun_base)
		_base_sun_energy = captured_sun_energy
		_base_sun_color = _sun_light.light_color
		_base_sun_state_captured = true
	if _moon_light != null and not _base_moon_state_captured:
		var captured_moon_energy: float = max(_moon_light.light_energy, 0.0)
		if captured_moon_energy <= 0.000001:
			var min_moon_base: float = max(_safe_numeric_float(minimum_moon_base_energy, 0.0), 0.0)
			captured_moon_energy = max(_base_moon_energy, min_moon_base)
		_base_moon_energy = captured_moon_energy
		_base_moon_color = _moon_light.light_color
		_base_moon_state_captured = true
	if _environment != null and not _base_state_captured:
		_base_fog_density = _environment.fog_density
		_base_volumetric_fog_density = _environment.volumetric_fog_density
		_base_fog_light_color = _environment.fog_light_color
		if _object_has_property(_environment, "fog_enabled"):
			_base_fog_enabled = bool(_environment.get("fog_enabled"))
		if _object_has_property(_environment, "volumetric_fog_enabled"):
			_base_volumetric_fog_enabled = bool(_environment.get("volumetric_fog_enabled"))
		_base_state_captured = true


func _apply_all() -> void:
	_update_celestial_state()
	_apply_sky_shader_parameters()
	_apply_environment_fog()
	_apply_directional_lights()


func _get_time_hours() -> float:
	if use_clock_time and _clock != null:
		return _clock.get_time_hours()
	return wrapf(manual_time_hours, 0.0, 24.0)


func _safe_numeric_float(value: Variant, fallback: float) -> float:
	var value_type: int = typeof(value)
	if value_type == TYPE_NIL:
		return fallback
	if value_type == TYPE_FLOAT or value_type == TYPE_INT:
		return float(value)
	return fallback


func _get_days_per_year_safe() -> float:
	return max(_safe_numeric_float(days_per_year, 365.0), 1.0)


func _get_manual_day_of_year_safe() -> int:
	var day_value: int = int(round(_safe_numeric_float(manual_day_of_year, 172.0)))
	return max(day_value, 1)


func _normalize_hours_24(value: float) -> float:
	return fposmod(value, 24.0)


func _add_hours_24(base_hours: float, delta_hours: float) -> float:
	return _normalize_hours_24(base_hours + delta_hours)


func _forward_hours_24(from_hours: float, to_hours: float) -> float:
	return fposmod(_normalize_hours_24(to_hours) - _normalize_hours_24(from_hours), 24.0)


func _is_time_in_window(time_hours_value: float, start_hours: float, end_hours: float) -> bool:
	var t: float = _normalize_hours_24(time_hours_value)
	var start_value: float = _normalize_hours_24(start_hours)
	var end_value: float = _normalize_hours_24(end_hours)
	if is_equal_approx(start_value, end_value):
		return true
	if start_value < end_value:
		return t >= start_value and t <= end_value
	return t >= start_value or t <= end_value


func _clamp_time_to_window(time_hours_value: float, start_hours: float, end_hours: float) -> float:
	var t: float = _normalize_hours_24(time_hours_value)
	var start_value: float = _normalize_hours_24(start_hours)
	var end_value: float = _normalize_hours_24(end_hours)
	if is_equal_approx(start_value, end_value):
		return t
	if _is_time_in_window(t, start_value, end_value):
		return t
	if start_value < end_value:
		var dist_to_start: float = absf(t - start_value)
		var dist_to_end: float = absf(t - end_value)
		if dist_to_start <= dist_to_end:
			return start_value
		return end_value
	var dist_to_start_wrap: float = min(absf(t - start_value), 24.0 - absf(t - start_value))
	var dist_to_end_wrap: float = min(absf(t - end_value), 24.0 - absf(t - end_value))
	if dist_to_start_wrap <= dist_to_end_wrap:
		return start_value
	return end_value


func _compute_window_visibility(time_hours_value: float, start_hours: float, end_hours: float, fade_hours: float) -> float:
	var t: float = _normalize_hours_24(time_hours_value)
	var start_value: float = _normalize_hours_24(start_hours)
	var end_value: float = _normalize_hours_24(end_hours)
	if not _is_time_in_window(t, start_value, end_value):
		return 0.0
	var fade_value: float = max(fade_hours, 0.0)
	if fade_value <= 0.0001:
		return 1.0
	var vis_start: float = 1.0
	var vis_end: float = 1.0
	if start_value < end_value:
		vis_start = clampf((t - start_value) / fade_value, 0.0, 1.0)
		vis_end = clampf((end_value - t) / fade_value, 0.0, 1.0)
	else:
		var start_dist: float = fposmod(t - start_value, 24.0)
		var end_dist: float = fposmod(end_value - t, 24.0)
		vis_start = clampf(start_dist / fade_value, 0.0, 1.0)
		vis_end = clampf(end_dist / fade_value, 0.0, 1.0)
	return min(vis_start, vis_end)


func _compute_moon_visibility(time_hours_value: float, sun_start: float, sun_end: float, fade_in_lead_hours: float, fade_out_lag_hours: float) -> float:
	var t: float = _normalize_hours_24(time_hours_value)
	var start_night: float = _normalize_hours_24(sun_end)
	var end_night: float = _normalize_hours_24(sun_start)
	var lead: float = max(fade_in_lead_hours, 0.0)
	var lag: float = max(fade_out_lag_hours, 0.0)

	# Fully visible during the core night window.
	var visibility: float = 0.0
	if _is_time_in_window(t, start_night, end_night):
		visibility = 1.0

	# Fade in before sunset: (sun_end - lead) -> sun_end.
	if lead > 0.0001:
		var fade_in_start: float = _add_hours_24(start_night, -lead)
		if _is_time_in_window(t, fade_in_start, start_night):
			var in_progress: float = _forward_hours_24(fade_in_start, t) / lead
			visibility = max(visibility, clampf(in_progress, 0.0, 1.0))
	else:
		if is_equal_approx(t, start_night):
			visibility = max(visibility, 1.0)

	# Fade out after sunrise: sun_start -> (sun_start + lag).
	if lag > 0.0001:
		var fade_out_end: float = _add_hours_24(end_night, lag)
		if _is_time_in_window(t, end_night, fade_out_end):
			var out_progress: float = _forward_hours_24(end_night, t) / lag
			visibility = max(visibility, clampf(1.0 - out_progress, 0.0, 1.0))
	else:
		if is_equal_approx(t, end_night):
			visibility = max(visibility, 1.0)

	return clampf(visibility, 0.0, 1.0)


func _update_celestial_state() -> void:
	var time_hours_value: float = _get_time_hours()
	var safe_sun_start: float = _normalize_hours_24(_safe_numeric_float(sun_active_start_hours, 4.5))
	var safe_sun_end: float = _normalize_hours_24(_safe_numeric_float(sun_active_end_hours, 22.0))
	var safe_sun_fade: float = max(_safe_numeric_float(sun_visibility_fade_hours, 0.25), 0.0)
	var fallback_moon_fade: float = max(_safe_numeric_float(moon_visibility_fade_hours, 1.25), 0.0)
	var safe_moon_lead: float = max(_safe_numeric_float(moon_fade_in_lead_hours, fallback_moon_fade), 0.0)
	var safe_moon_lag: float = max(_safe_numeric_float(moon_fade_out_lag_hours, fallback_moon_fade), 0.0)
	var sun_time_for_motion: float = time_hours_value
	if constrain_sun_motion_to_active_window:
		sun_time_for_motion = _clamp_time_to_window(time_hours_value, safe_sun_start, safe_sun_end)
	_computed_sun_visibility = _compute_window_visibility(time_hours_value, safe_sun_start, safe_sun_end, safe_sun_fade)
	_computed_moon_visibility = _compute_moon_visibility(time_hours_value, safe_sun_start, safe_sun_end, safe_moon_lead, safe_moon_lag)

	var day_of_year_value: float = _resolve_day_of_year_value()
	var total_days_value: float = _resolve_total_days_value(day_of_year_value, time_hours_value)
	_computed_day_of_year = day_of_year_value
	_computed_total_days = total_days_value

	var safe_days_per_year: float = _get_days_per_year_safe()
	var seasonal_angle: float = TAU * ((day_of_year_value - 81.0) / safe_days_per_year)
	var safe_axial_tilt_deg: float = _safe_numeric_float(axial_tilt_deg, 23.44)
	var declination_sun: float = deg_to_rad(safe_axial_tilt_deg) * sin(seasonal_angle)
	var hour_angle_sun_orbital: float = TAU * ((time_hours_value - 12.0) / 24.0)
	var orbital_sun_direction: Vector3 = _direction_from_declination_and_hour(declination_sun, hour_angle_sun_orbital)
	var hour_angle_sun: float = TAU * ((sun_time_for_motion - 12.0) / 24.0)
	_computed_sun_direction = _direction_from_declination_and_hour(declination_sun, hour_angle_sun)

	var safe_synodic: float = max(_safe_numeric_float(moon_synodic_days, 29.530588), 0.0001)
	var safe_phase_offset: float = _safe_numeric_float(moon_phase_offset_days, 0.0)
	var moon_age_days: float = fposmod(total_days_value + safe_phase_offset, safe_synodic)
	var moon_phase: float = moon_age_days / safe_synodic
	_computed_moon_phase = moon_phase
	if moon_inverse_of_sun:
		if moon_inverse_uses_unclamped_sun:
			_computed_moon_direction = -orbital_sun_direction
		else:
			_computed_moon_direction = -_computed_sun_direction
	else:
		var phase_angle: float = moon_phase * TAU
		var safe_moon_tilt_deg: float = _safe_numeric_float(moon_orbital_tilt_deg, 5.14)
		var declination_moon: float = declination_sun * cos(phase_angle) + deg_to_rad(safe_moon_tilt_deg) * sin(phase_angle * 1.05)
		declination_moon = clampf(declination_moon, -1.3962634, 1.3962634)
		var hour_angle_moon: float = TAU * ((time_hours_value - 0.0) / 24.0)
		_computed_moon_direction = _direction_from_declination_and_hour(declination_moon, hour_angle_moon)


func _direction_from_declination_and_hour(declination_rad: float, hour_angle_rad: float) -> Vector3:
	var safe_latitude_deg: float = clampf(_safe_numeric_float(latitude_deg, 35.0), -89.9, 89.9)
	var latitude_rad: float = deg_to_rad(safe_latitude_deg)
	var cos_decl: float = cos(declination_rad)
	var sin_decl: float = sin(declination_rad)
	var cos_hour: float = cos(hour_angle_rad)
	var sin_hour: float = sin(hour_angle_rad)
	# East = +X, Up = +Y, North/South = +/-Z (north = +Z).
	var east_component: float = -cos_decl * sin_hour
	var up_component: float = sin(latitude_rad) * sin_decl + cos(latitude_rad) * cos_decl * cos_hour
	var north_component: float = cos(latitude_rad) * sin_decl - sin(latitude_rad) * cos_decl * cos_hour
	var direction: Vector3 = Vector3(east_component, up_component, north_component)
	if direction.length_squared() <= 0.000001:
		return Vector3(0.0, 1.0, 0.0)
	return direction.normalized()


func _resolve_day_of_year_value() -> float:
	if use_clock_time and use_clock_calendar and _clock != null:
		return float(_get_clock_day_of_year(_clock))
	return float(clampi(_get_manual_day_of_year_safe(), 1, int(_get_days_per_year_safe())))


func _resolve_total_days_value(day_of_year_value: float, time_hours_value: float) -> float:
	var time_fraction: float = time_hours_value / 24.0
	var safe_days_per_year: float = _get_days_per_year_safe()
	if use_clock_time and use_clock_calendar and _clock != null:
		var year_index: int = max(_clock.year - 1, 0)
		return float(year_index) * safe_days_per_year + max(day_of_year_value - 1.0, 0.0) + time_fraction
	return max(day_of_year_value - 1.0, 0.0) + time_fraction


func _get_clock_day_of_year(clock: DensetsuSkyClock) -> int:
	if clock == null:
		return 1
	var month_lengths_local: PackedInt32Array = clock.month_lengths
	if month_lengths_local.is_empty():
		return clampi(clock.day, 1, 365)
	var month_index: int = clampi(clock.month - 1, 0, month_lengths_local.size() - 1)
	var day_of_year_value: int = 0
	for i in range(month_index):
		day_of_year_value += max(month_lengths_local[i], 1)
	var month_max_day: int = max(month_lengths_local[month_index], 1)
	day_of_year_value += clampi(clock.day, 1, month_max_day)
	return max(day_of_year_value, 1)


func _apply_sky_shader_parameters() -> void:
	if _sky_material == null:
		return
	_ensure_default_hour_gradient()
	var time_hours_value: float = _get_time_hours()

	var weather_override_color: Color = Color(1.0, 1.0, 1.0, 1.0)
	var weather_override_amount: float = 0.0
	var weather_shift_color: Color = Color(1.0, 1.0, 1.0, 1.0)
	var weather_shift_amount: float = 0.0
	var weather_cloud_multiplier: float = 1.0

	if _active_weather != null:
		weather_override_color = _active_weather.sky_override_color
		weather_override_amount = _active_weather.sky_override_amount * _weather_blend_factor
		weather_shift_color = _active_weather.sky_shift_color
		weather_shift_amount = _active_weather.sky_shift_amount * _weather_blend_factor
		weather_cloud_multiplier = lerpf(1.0, _active_weather.cloud_opacity_multiplier, _weather_blend_factor)
	if _thunder_current_pulse_intensity > 0.000001:
		var thunder_sky_mix: float = clampf(_thunder_current_sky_tint_strength * _thunder_current_pulse_intensity, 0.0, 1.0)
		weather_shift_color = weather_shift_color.lerp(_thunder_current_tint, thunder_sky_mix)
		weather_shift_amount = max(weather_shift_amount, thunder_sky_mix)

	var cloud_texture: Texture2D = null
	if _cloud_viewport != null:
		cloud_texture = _cloud_viewport.get_texture()
	var moon_texture_value: Texture2D = null
	var moon_surface_color_value: Color = Color(1.0, 1.0, 1.0, 1.0)
	var moon_surface_uv_scale_value: Vector2 = Vector2.ONE
	var moon_surface_uv_offset_value: Vector2 = Vector2.ZERO
	var has_direct_albedo: bool = false
	if moon_surface_material is BaseMaterial3D and moon_flat_sprite_mode:
		# Flat mode: pull directly from albedo for reliability.
		if _object_has_property(moon_surface_material, "albedo_color"):
			var albedo_color_value: Variant = moon_surface_material.get("albedo_color")
			if typeof(albedo_color_value) == TYPE_COLOR:
				moon_surface_color_value = albedo_color_value
		var albedo_tex: Texture2D = null
		if _object_has_property(moon_surface_material, "albedo_texture"):
			albedo_tex = moon_surface_material.get("albedo_texture") as Texture2D
		if albedo_tex == null and _object_has_property(moon_surface_material, "texture_albedo"):
			albedo_tex = moon_surface_material.get("texture_albedo") as Texture2D
		moon_texture_value = albedo_tex
		var moon_uv_data: Dictionary = _extract_base_material_uv(moon_surface_material)
		var moon_uv_scale_variant: Variant = moon_uv_data.get("scale", Vector2.ONE)
		if typeof(moon_uv_scale_variant) == TYPE_VECTOR2:
			moon_surface_uv_scale_value = moon_uv_scale_variant
		var moon_uv_offset_variant: Variant = moon_uv_data.get("offset", Vector2.ZERO)
		if typeof(moon_uv_offset_variant) == TYPE_VECTOR2:
			moon_surface_uv_offset_value = moon_uv_offset_variant
		has_direct_albedo = true
	# Otherwise prefer viewport output so non-standard material graphs can still render.
	if not has_direct_albedo and moon_surface_material != null and _moon_surface_viewport != null:
		moon_texture_value = _moon_surface_viewport.get_texture()

	_sky_material.set_shader_parameter("hour_gradient", hour_gradient)
	_sky_material.set_shader_parameter("time_hours", time_hours_value)
	_sky_material.set_shader_parameter("day_of_year", _computed_day_of_year)
	_sky_material.set_shader_parameter("days_per_year", _get_days_per_year_safe())
	_sky_material.set_shader_parameter("sun_direction", _computed_sun_direction)
	_sky_material.set_shader_parameter("moon_direction", _computed_moon_direction)
	_sky_material.set_shader_parameter("moon_phase", _computed_moon_phase)
	_sky_material.set_shader_parameter("sun_visibility", _computed_sun_visibility)
	_sky_material.set_shader_parameter("moon_visibility", _computed_moon_visibility)
	_sky_material.set_shader_parameter("horizon_shift_hours", horizon_shift_hours)
	_sky_material.set_shader_parameter("sky_intensity", sky_intensity)
	_sky_material.set_shader_parameter("horizon_exponent", horizon_exponent)
	_sky_material.set_shader_parameter("sun_tint", sun_tint)
	_sky_material.set_shader_parameter("sun_disk_size", sun_disk_size)
	_sky_material.set_shader_parameter("sun_glow_size", sun_glow_size)
	_sky_material.set_shader_parameter("sun_falloff", sun_falloff)
	_sky_material.set_shader_parameter("sun_brightness", sun_brightness)
	_sky_material.set_shader_parameter("moon_tint", moon_tint)
	_sky_material.set_shader_parameter("moon_disk_size", moon_disk_size)
	_sky_material.set_shader_parameter("moon_brightness", moon_brightness)
	_sky_material.set_shader_parameter("moon_phase_softness", moon_phase_softness)
	_sky_material.set_shader_parameter("moon_earthshine", moon_earthshine)
	_sky_material.set_shader_parameter("moon_lock_phase_orientation", moon_lock_phase_orientation)
	_sky_material.set_shader_parameter("moon_surface_texture", moon_texture_value)
	_sky_material.set_shader_parameter("moon_surface_color", moon_surface_color_value)
	_sky_material.set_shader_parameter("moon_surface_uv_scale", moon_surface_uv_scale_value)
	_sky_material.set_shader_parameter("moon_surface_uv_offset", moon_surface_uv_offset_value)
	_sky_material.set_shader_parameter("cloud_group_texture", cloud_texture)
	_sky_material.set_shader_parameter("cloud_group_opacity", cloud_group_opacity * weather_cloud_multiplier)
	_sky_material.set_shader_parameter("cloud_group_brightness", cloud_group_brightness)
	_sky_material.set_shader_parameter("cloud_group_contrast", cloud_group_contrast)
	_sky_material.set_shader_parameter("cloud_uv_offset", cloud_uv_offset + _cloud_scroll_uv)
	_sky_material.set_shader_parameter("cloud_seam_blend_width", cloud_seam_blend_width)
	var shader_fog_amount: float = 0.0
	if use_sky_shader_fog_overlay:
		shader_fog_amount = fog_shift_amount
	_sky_material.set_shader_parameter("fog_shift_color", fog_shift_color)
	_sky_material.set_shader_parameter("fog_shift_amount", shader_fog_amount)
	_sky_material.set_shader_parameter("weather_shift_color", weather_shift_color)
	_sky_material.set_shader_parameter("weather_shift_amount", weather_shift_amount)
	_sky_material.set_shader_parameter("weather_override_color", weather_override_color)
	_sky_material.set_shader_parameter("weather_override_amount", weather_override_amount)
	_sky_material.set_shader_parameter("weather_mask", 1.0)
	_sky_material.set_shader_parameter("stars_enabled", stars_enabled)
	_sky_material.set_shader_parameter("stars_density", stars_density)
	_sky_material.set_shader_parameter("stars_brightness", stars_brightness)
	_sky_material.set_shader_parameter("stars_size", stars_size)
	_sky_material.set_shader_parameter("stars_twinkle_speed", stars_twinkle_speed)
	_sky_material.set_shader_parameter("stars_seed", float(stars_seed))


func _is_sky_shader_usable(shader: Shader) -> bool:
	if shader == null:
		return false
	var uniform_list: Array = shader.get_shader_uniform_list()
	var has_time_hours: bool = false
	var has_hour_gradient: bool = false
	for entry_any in uniform_list:
		if not (entry_any is Dictionary):
			continue
		var entry: Dictionary = entry_any as Dictionary
		var uniform_name: String = str(entry.get("name", ""))
		if uniform_name == "time_hours":
			has_time_hours = true
		elif uniform_name == "hour_gradient":
			has_hour_gradient = true
		if has_time_hours and has_hour_gradient:
			return true
	return false


func _apply_environment_fog() -> void:
	if _environment == null:
		return
	if not _base_state_captured:
		return
	var base_fog_density_value: float = _base_fog_density
	var base_volumetric_fog_density_value: float = _base_volumetric_fog_density
	var base_fog_light_color_value: Color = _base_fog_light_color
	var base_fog_enabled_value: bool = _base_fog_enabled
	var base_volumetric_enabled_value: bool = _base_volumetric_fog_enabled
	if not use_captured_environment_fog_base:
		base_fog_density_value = max(base_environment_fog_density, 0.0)
		base_volumetric_fog_density_value = max(base_environment_volumetric_fog_density, 0.0)
		base_fog_light_color_value = base_environment_fog_light_color
		base_fog_enabled_value = base_environment_fog_enabled
		base_volumetric_enabled_value = base_environment_volumetric_fog_enabled

	var fog_density: float = base_fog_density_value
	var volumetric_fog_density: float = base_volumetric_fog_density_value
	var fog_light_color: Color = base_fog_light_color_value
	var has_weather_fog: bool = false
	var has_weather_volumetric: bool = false
	# Keep existing resource values but boost their effect globally.
	var offset_scale: float = max(weather_fog_offset_scale * 10.0, 0.0)
	var weather_fog_blend_factor: float = pow(clampf(_weather_blend_factor, 0.0, 1.0), max(weather_fog_blend_curve, 0.1))
	if apply_weather_to_environment_fog and _active_weather != null:
		var fog_offset_value: float = max(_active_weather.fog_density_offset, 0.0)
		var volumetric_offset_value: float = max(_active_weather.volumetric_fog_density_offset, 0.0)
		var weather_fog_delta: float = fog_offset_value * weather_fog_blend_factor * offset_scale
		var weather_volumetric_delta: float = volumetric_offset_value * weather_fog_blend_factor * offset_scale
		fog_density += weather_fog_delta
		volumetric_fog_density += weather_volumetric_delta
		var fog_color_blend: float = clampf(_active_weather.fog_color_override_amount * weather_fog_blend_factor, 0.0, 1.0)
		fog_light_color = fog_light_color.lerp(_active_weather.fog_color_override, fog_color_blend)
		has_weather_fog = fog_offset_value > 0.000001
		has_weather_volumetric = volumetric_offset_value > 0.000001
	var final_fog_density: float = max(fog_density, 0.0)
	var final_volumetric_fog_density: float = max(volumetric_fog_density, 0.0)
	final_fog_density = pow(final_fog_density, max(environment_fog_density_curve, 0.1))
	final_volumetric_fog_density = pow(final_volumetric_fog_density, max(environment_volumetric_fog_density_curve, 0.1))
	var soft_response: float = max(_safe_numeric_float(environment_fog_soft_cap_response, 2.5), 0.0001)
	var fog_soft_cap: float = max(_safe_numeric_float(environment_fog_density_soft_cap, 1.0), 0.0001)
	var volumetric_soft_cap: float = max(_safe_numeric_float(environment_volumetric_fog_density_soft_cap, 0.35), 0.0001)
	final_fog_density = fog_soft_cap * (1.0 - exp(-final_fog_density * soft_response / fog_soft_cap))
	final_volumetric_fog_density = volumetric_soft_cap * (1.0 - exp(-final_volumetric_fog_density * soft_response / volumetric_soft_cap))
	final_fog_density = clampf(final_fog_density, 0.0, fog_soft_cap)
	final_volumetric_fog_density = clampf(final_volumetric_fog_density, 0.0, volumetric_soft_cap)
	var fog_density_present: bool = final_fog_density > 0.000001
	var volumetric_density_present: bool = final_volumetric_fog_density > 0.000001
	if fog_density_present:
		fog_light_color = fog_light_color.lerp(fog_shift_color, clampf(fog_shift_amount, 0.0, 1.0))
	_environment.fog_density = final_fog_density
	_environment.volumetric_fog_density = final_volumetric_fog_density
	_environment.fog_light_color = fog_light_color
	if _object_has_property(_environment, "fog_enabled"):
		var fog_enabled_target: bool = base_fog_enabled_value and fog_density_present
		if weather_force_enable_environment_fog and has_weather_fog and fog_density_present:
			fog_enabled_target = true
		_environment.set("fog_enabled", fog_enabled_target)
	if _object_has_property(_environment, "volumetric_fog_enabled"):
		var volumetric_enabled_target: bool = base_volumetric_enabled_value and volumetric_density_present
		if weather_force_enable_volumetric_fog and has_weather_volumetric and volumetric_density_present:
			volumetric_enabled_target = true
		_environment.set("volumetric_fog_enabled", volumetric_enabled_target)


func _apply_directional_lights() -> void:
	_apply_sun_directional_light()
	_apply_moon_directional_light()


func _smooth_factor(speed: float, delta_seconds: float) -> float:
	if speed <= 0.0001:
		return 1.0
	return clampf(1.0 - exp(-speed * max(delta_seconds, 0.0)), 0.0, 1.0)


func _smooth_direction(current: Vector3, target: Vector3, blend: float) -> Vector3:
	if target.length_squared() <= 0.000001:
		return current
	if current.length_squared() <= 0.000001:
		return target.normalized()
	var mixed: Vector3 = current.lerp(target, clampf(blend, 0.0, 1.0))
	if mixed.length_squared() <= 0.000001:
		return target.normalized()
	return mixed.normalized()


func _apply_light_direction(light_node: DirectionalLight3D, direction_value: Vector3) -> void:
	if light_node == null:
		return
	var up_axis: Vector3 = Vector3.UP
	if absf(direction_value.dot(up_axis)) > 0.98:
		up_axis = Vector3(0.0, 0.0, 1.0)
	var look_target: Vector3 = light_node.global_position + direction_value
	light_node.look_at(look_target, up_axis)


func _apply_sun_directional_light() -> void:
	if _sun_light == null:
		return
	if not _base_sun_state_captured:
		return
	var dir_blend: float = _smooth_factor(light_direction_smooth_speed, _frame_delta_seconds)
	var energy_blend: float = _smooth_factor(light_energy_smooth_speed, _frame_delta_seconds)
	var color_blend: float = _smooth_factor(light_color_smooth_speed, _frame_delta_seconds)

	var weather_energy_mult: float = 1.0
	if _active_weather != null:
		weather_energy_mult = lerpf(1.0, _active_weather.sun_energy_multiplier, _weather_blend_factor)

	var target_energy: float = _base_sun_energy * sun_light_energy_multiplier * weather_energy_mult
	var sun_visibility_value: float = clampf(_computed_sun_visibility, 0.0, 1.0)
	if sun_light_use_visibility:
		target_energy *= sun_visibility_value
	var moon_dimming: float = 1.0 - clampf(_computed_moon_visibility, 0.0, 1.0) * clampf(sun_light_dim_by_moon, 0.0, 1.0)
	target_energy *= max(moon_dimming, 0.0)
	if _thunder_current_pulse_intensity > 0.000001:
		var thunder_energy_mult: float = lerpf(1.0, _thunder_current_pulse_energy_mult, _thunder_current_pulse_intensity)
		target_energy *= thunder_energy_mult
	if sun_visibility_value > 0.000001:
		var min_visible_energy_setting: float = max(_safe_numeric_float(sun_light_min_visible_energy, 0.2), 0.0)
		var min_visible_energy: float = min_visible_energy_setting * sun_visibility_value
		target_energy = max(target_energy, min_visible_energy)
	target_energy = max(target_energy, 0.0)

	var target_color: Color = Color(sun_tint.r, sun_tint.g, sun_tint.b, 1.0)
	if _thunder_current_pulse_intensity > 0.000001:
		var lightning_mix: float = clampf(_thunder_current_color_lerp * _thunder_current_pulse_intensity, 0.0, 1.0)
		target_color = target_color.lerp(_thunder_current_tint, lightning_mix)

	if not _sun_light_runtime_initialized:
		_sun_light_direction_smoothed = _computed_sun_direction
		_sun_light_energy_smoothed = target_energy
		_sun_light_color_smoothed = target_color
		_sun_light_runtime_initialized = true

	_sun_light_direction_smoothed = _smooth_direction(_sun_light_direction_smoothed, _computed_sun_direction, dir_blend)
	_sun_light_energy_smoothed = lerpf(_sun_light_energy_smoothed, target_energy, energy_blend)
	_sun_light_color_smoothed = _sun_light_color_smoothed.lerp(target_color, color_blend)

	if sync_sun_light_direction:
		_apply_light_direction(_sun_light, _sun_light_direction_smoothed)
	if sync_sun_light_energy:
		_sun_light.light_energy = _sun_light_energy_smoothed
	if sync_sun_light_color:
		_sun_light.light_color = _base_sun_color.lerp(_sun_light_color_smoothed, 1.0)
	if keep_synced_light_shadows_enabled and _object_has_property(_sun_light, "shadow_enabled"):
		_sun_light.set("shadow_enabled", true)


func _apply_moon_directional_light() -> void:
	if _moon_light == null:
		return
	if not _base_moon_state_captured:
		return
	var dir_blend: float = _smooth_factor(light_direction_smooth_speed, _frame_delta_seconds)
	var energy_blend: float = _smooth_factor(light_energy_smooth_speed, _frame_delta_seconds)
	var color_blend: float = _smooth_factor(light_color_smooth_speed, _frame_delta_seconds)

	var target_energy: float = _base_moon_energy * moon_light_energy_multiplier
	if moon_light_use_visibility:
		target_energy *= clampf(_computed_moon_visibility, 0.0, 1.0)
	if _thunder_current_pulse_intensity > 0.000001:
		var thunder_energy_mult: float = lerpf(1.0, _thunder_current_pulse_energy_mult, _thunder_current_pulse_intensity)
		target_energy *= thunder_energy_mult
	target_energy = max(target_energy, 0.0)

	var target_color: Color = Color(moon_tint.r, moon_tint.g, moon_tint.b, 1.0)
	if _thunder_current_pulse_intensity > 0.000001:
		var lightning_mix: float = clampf(_thunder_current_color_lerp * _thunder_current_pulse_intensity, 0.0, 1.0)
		target_color = target_color.lerp(_thunder_current_tint, lightning_mix)

	if not _moon_light_runtime_initialized:
		_moon_light_direction_smoothed = _computed_moon_direction
		_moon_light_energy_smoothed = target_energy
		_moon_light_color_smoothed = target_color
		_moon_light_runtime_initialized = true

	_moon_light_direction_smoothed = _smooth_direction(_moon_light_direction_smoothed, _computed_moon_direction, dir_blend)
	_moon_light_energy_smoothed = lerpf(_moon_light_energy_smoothed, target_energy, energy_blend)
	_moon_light_color_smoothed = _moon_light_color_smoothed.lerp(target_color, color_blend)

	if sync_moon_light_direction:
		_apply_light_direction(_moon_light, _moon_light_direction_smoothed)
	if sync_moon_light_energy:
		_moon_light.light_energy = _moon_light_energy_smoothed
	if sync_moon_light_color:
		_moon_light.light_color = _base_moon_color.lerp(_moon_light_color_smoothed, 1.0)
	if keep_synced_light_shadows_enabled and _object_has_property(_moon_light, "shadow_enabled"):
		_moon_light.set("shadow_enabled", true)
