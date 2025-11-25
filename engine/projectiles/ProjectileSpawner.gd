extends Node2D

@export var projectile_scene: PackedScene
@export var owner_path: NodePath
@export var fire_interval: float = 2.0
@export var speed: float = 300.0
@export var direction: float = -1.0

@onready var _timer: Timer = Timer.new()
@onready var _owner: Node = get_node_or_null(owner_path)

func _ready() -> void:
	if projectile_scene == null:
		return
	add_child(_timer)
	_timer.wait_time = fire_interval
	_timer.timeout.connect(_on_timeout)
	_timer.start()


func _on_timeout() -> void:
	var proj := projectile_scene.instantiate() as Area2D
	if proj == null:
		return
	if _owner and _owner.has_method("get_instance_id"):
		proj.owner_id = _owner.get_instance_id()
		if _owner.has_method("get_facing_dir"):
			direction = _owner.get_facing_dir()
	proj.global_position = global_position
	if "speed" in proj:
		proj.speed = speed
	proj.velocity = Vector2(speed * direction, 0)
	get_tree().current_scene.add_child(proj)
