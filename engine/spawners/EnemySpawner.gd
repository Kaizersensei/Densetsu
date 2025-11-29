extends Area2D

@export var projectile_scene: PackedScene
@export var actor_scene: PackedScene
@export var owner_path: NodePath
@export var fire_interval: float = 2.0
@export var speed: float = 300.0
@export var direction: float = -1.0
@export var min_spawn: int = 1
@export var max_spawn: int = 3
@export var active_start_time: float = 0.0
@export var active_end_time: float = 9999.0
@export var spawn_on_start: bool = true
@export var show_in_game: bool = false
@export var team: String = ""
@export var spawner_data: Resource

@onready var _timer: Timer = Timer.new()
@onready var _owner: Node = get_node_or_null(owner_path)

func _ready() -> void:
	_apply_data()
	var in_editor_runtime := _is_editor_mode()
	if Engine.is_editor_hint() or in_editor_runtime:
		_set_visual_visible(true)
	else:
		_set_visual_visible(show_in_game)
	add_child(_timer)
	_timer.wait_time = fire_interval
	_timer.timeout.connect(_on_timeout)
	if spawn_on_start:
		_timer.start()


func _on_timeout() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now < active_start_time or now > active_end_time:
		return
	if projectile_scene:
		_spawn_projectile()
	elif actor_scene:
		_spawn_actor()


func _spawn_projectile() -> void:
	var proj := projectile_scene.instantiate()
	if proj == null:
		return
	if _owner and _owner.has_method("get_instance_id"):
		if "owner_id" in proj:
			proj.owner_id = _owner.get_instance_id()
		if _owner.has_method("get_facing_dir"):
			direction = _owner.get_facing_dir()
	if "global_position" in proj:
		proj.global_position = global_position
	if "speed" in proj:
		proj.speed = speed
	if "velocity" in proj:
		proj.velocity = Vector2(speed * direction, 0)
	get_tree().current_scene.add_child(proj)


func _spawn_actor() -> void:
	var lo: int = min(min_spawn, max_spawn)
	var hi: int = max(min_spawn, max_spawn)
	var count: int = randi_range(lo, hi)
	for i in range(count):
		var actor := actor_scene.instantiate()
		if actor and "global_position" in actor:
			actor.global_position = global_position
		if actor:
			get_tree().current_scene.add_child(actor)


func _set_visual_visible(flag: bool) -> void:
	for child in get_children():
		if child is Node2D and child.name in ["Visual", "Sprite2D", "Polygon2D"]:
			child.visible = flag


func _apply_data() -> void:
	if spawner_data:
		if "spawn_scene" in spawner_data:
			actor_scene = spawner_data.spawn_scene
		if "min_spawn" in spawner_data:
			min_spawn = spawner_data.min_spawn
		if "max_spawn" in spawner_data:
			max_spawn = spawner_data.max_spawn
		if "cooldown" in spawner_data:
			fire_interval = spawner_data.cooldown
		if "spawn_on_start" in spawner_data:
			spawn_on_start = spawner_data.spawn_on_start
		if "active_start_time" in spawner_data:
			active_start_time = spawner_data.active_start_time
		if "active_end_time" in spawner_data:
			active_end_time = spawner_data.active_end_time
		if "team" in spawner_data and "team" in self:
			team = spawner_data.team
		if "show_in_game" in spawner_data:
			show_in_game = spawner_data.show_in_game


func _is_editor_mode() -> bool:
	var mgr := get_tree().root.get_node_or_null("EditorManager")
	if mgr and "editor_mode" in mgr:
		return mgr.editor_mode
	return false
