@tool
extends Resource
class_name DensetsuWeatherCondition

@export_group("Identity")
## Stable ID used by DensetsuSkySystem3D.active_weather_id.
@export var weather_id: String = "clear"
## Optional display label for tools/UI.
@export var display_name: String = "Clear"
## Optional UI icon for HUD/debug weather display.
@export var ui_icon: Texture2D
## Enables/disables this weather condition for automatic selection.
@export var auto_enabled: bool = true
## Optional weather group ID used by DensetsuSkySystem3D group-based selection.
@export var weather_group_id: String = "default"

@export_group("Auto Selection")
## Base chance percent used by automatic weather selection within its bucket.
@export_range(0.0, 100.0, 0.001) var auto_base_weight: float = 1.0
## Spring seasonal multiplier (day-based season selection).
@export_range(0.0, 100.0, 0.001) var auto_spring_weight: float = 1.0
## Summer seasonal multiplier.
@export_range(0.0, 100.0, 0.001) var auto_summer_weight: float = 1.0
## Autumn seasonal multiplier.
@export_range(0.0, 100.0, 0.001) var auto_autumn_weight: float = 1.0
## Winter seasonal multiplier.
@export_range(0.0, 100.0, 0.001) var auto_winter_weight: float = 1.0

@export_group("Sky Overrides")
## Blends sky color toward this color directly.
@export var sky_override_color: Color = Color(1.0, 1.0, 1.0, 1.0)
## Amount of direct sky color override.
@export_range(0.0, 1.0, 0.01) var sky_override_amount: float = 0.0
## Multiplies existing sky color with this tint.
@export var sky_shift_color: Color = Color(1.0, 1.0, 1.0, 1.0)
## Amount of tint shift applied to the sky.
@export_range(0.0, 1.0, 0.01) var sky_shift_amount: float = 0.0
## Cloud opacity multiplier for this weather condition.
@export_range(0.0, 3.0, 0.01) var cloud_opacity_multiplier: float = 1.0
## Sun light energy multiplier for this weather condition.
@export_range(0.0, 4.0, 0.01) var sun_energy_multiplier: float = 1.0

@export_group("Fog")
## Additive offset applied to Environment.fog_density (non-negative).
@export_range(0.0, 20.0, 0.001) var fog_density_offset: float = 0.0
## Additive offset applied to Environment.volumetric_fog_density (non-negative).
@export_range(0.0, 20.0, 0.001) var volumetric_fog_density_offset: float = 0.0
## Optional fog color override tint.
@export var fog_color_override: Color = Color(1.0, 1.0, 1.0, 1.0)
## Blend amount for fog color override.
@export_range(0.0, 1.0, 0.01) var fog_color_override_amount: float = 0.0

@export_group("Weather Particles")
## Near tier particle scene (camera-close precipitation/details).
@export var near_particles_scene: PackedScene
## Mid tier particle scene (primary visible weather volume).
@export var mid_particles_scene: PackedScene
## Far tier particle scene (distance fill).
@export var far_particles_scene: PackedScene
## Emission multiplier applied to near tier particles.
@export_range(0.0, 4.0, 0.01) var near_emission_multiplier: float = 1.0
## Emission multiplier applied to mid tier particles.
@export_range(0.0, 4.0, 0.01) var mid_emission_multiplier: float = 1.0
## Emission multiplier applied to far tier particles.
@export_range(0.0, 4.0, 0.01) var far_emission_multiplier: float = 1.0
## Disables far particles while indoors to reduce overdraw and leaks.
@export var disable_far_indoors: bool = true

@export_group("Thunder And Lightning")
## Enables thunder/lightning simulation for this weather condition.
@export var thunder_enabled: bool = false
## Average lightning strikes per minute while this weather is active.
@export_range(0.0, 60.0, 0.01) var lightning_strikes_per_minute: float = 0.6
## Minimum number of flash pulses per strike.
@export_range(1, 8, 1) var lightning_pulses_per_strike_min: int = 1
## Maximum number of flash pulses per strike.
@export_range(1, 8, 1) var lightning_pulses_per_strike_max: int = 3
## Minimum pulse duration (seconds).
@export_range(0.01, 1.0, 0.001) var lightning_pulse_min_duration: float = 0.04
## Maximum pulse duration (seconds).
@export_range(0.01, 1.0, 0.001) var lightning_pulse_max_duration: float = 0.12
## Minimum delay between pulses inside one strike.
@export_range(0.01, 1.0, 0.001) var lightning_pulse_gap_min: float = 0.04
## Maximum delay between pulses inside one strike.
@export_range(0.01, 1.0, 0.001) var lightning_pulse_gap_max: float = 0.18
## Minimum directional-light energy multiplier during a pulse.
@export_range(1.0, 128.0, 0.01) var lightning_energy_multiplier_min: float = 4.0
## Maximum directional-light energy multiplier during a pulse.
@export_range(1.0, 128.0, 0.01) var lightning_energy_multiplier_max: float = 12.0
## Flash tint used during lightning pulses.
@export var lightning_tint: Color = Color(1.0, 0.97, 0.93, 1.0)
## Optional gradient palette; each pulse picks a random color from this gradient.
@export var lightning_color_gradient: Gradient
## How strongly pulse tint pushes the directional light color toward lightning_tint.
@export_range(0.0, 1.0, 0.01) var lightning_color_lerp: float = 0.65
## How strongly pulse tint pushes sky tint during lightning flashes.
@export_range(0.0, 1.0, 0.01) var lightning_sky_tint_strength: float = 0.45
## Enables visible bolt rendering.
@export var lightning_draw_bolts: bool = true
## Optional bolt texture. If null, a procedural bolt line is generated.
@export var lightning_bolt_texture: Texture2D
## Bolt line width in screen pixels.
@export_range(1.0, 32.0, 0.1) var lightning_bolt_width: float = 3.0
## Number of segments for generated bolts.
@export_range(2, 64, 1) var lightning_bolt_segments: int = 12
## Horizontal randomization amount for generated bolt shape.
@export_range(0.0, 1.0, 0.001) var lightning_bolt_jitter: float = 0.18
## Bolt visible lifetime (seconds).
@export_range(0.01, 1.0, 0.001) var lightning_bolt_lifetime: float = 0.14
## Bolt alpha multiplier.
@export_range(0.0, 1.0, 0.01) var lightning_bolt_alpha: float = 0.85


func get_auto_season_multiplier(season_index: int) -> float:
	match season_index:
		0:
			return auto_spring_weight
		1:
			return auto_summer_weight
		2:
			return auto_autumn_weight
		_:
			return auto_winter_weight
