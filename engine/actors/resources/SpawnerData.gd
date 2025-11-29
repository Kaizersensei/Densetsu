extends Resource
class_name SpawnerData
@export var id: String = ""
@export var spawn_scene: PackedScene
@export var min_spawn: int = 1
@export var max_spawn: int = 3
@export var cooldown: float = 2.0
@export var spawn_on_start: bool = true
@export var active_start_time: float = 0.0
@export var active_end_time: float = 9999.0
@export var team: String = ""
@export var show_in_game: bool = false
