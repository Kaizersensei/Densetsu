extends Resource
class_name WeatherData

@export var id: String = ""
@export var description: String = ""
@export var tags: PackedStringArray = []
@export var precipitation_type: String = ""
@export var intensity: float = 0.0
@export var wind_speed: float = 0.0
@export var ambient_light: Color = Color(1, 1, 1, 1)
@export var particle_effect_id: String = ""
