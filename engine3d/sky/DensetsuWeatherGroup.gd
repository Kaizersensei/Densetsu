@tool
extends Resource
class_name DensetsuWeatherGroup

@export_group("Identity")
## Stable ID matched against DensetsuWeatherCondition.weather_group_id.
@export var group_id: String = "default"
## Optional display label for tools/UI.
@export var display_name: String = "Default"
## Enables/disables this group in automatic selection.
@export var auto_enabled: bool = true

@export_group("Auto Selection")
## Base chance percent for selecting this group.
@export_range(0.0, 100.0, 0.001) var auto_base_weight: float = 1.0
## Spring seasonal multiplier (day-based season selection).
@export_range(0.0, 100.0, 0.001) var auto_spring_weight: float = 1.0
## Summer seasonal multiplier.
@export_range(0.0, 100.0, 0.001) var auto_summer_weight: float = 1.0
## Autumn seasonal multiplier.
@export_range(0.0, 100.0, 0.001) var auto_autumn_weight: float = 1.0
## Winter seasonal multiplier.
@export_range(0.0, 100.0, 0.001) var auto_winter_weight: float = 1.0


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
