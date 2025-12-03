extends CharacterBody2D

signal landed
signal jumped
signal direction_changed(dir: float)
signal hurt(damage: int, source_id: int)

@onready var _hurtbox: Area2D = $Hurtbox
@onready var _actor_interface: ActorInterface = $ActorInterface

@export var use_player_input := true
@onready var _fsm: StateMachine = $StateMachine

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var move_speed := 140.0
# Jump speed tuned for ~4m apex at 64px/m (~2s airtime)
var jump_speed := -720.0
var air_jump_speed := -720.0
var acceleration := 900.0
var friction_ground := 900.0
var friction_air := 300.0
var max_fall_speed := 900.0
var coyote_time := 0.12
var jump_buffer_time := 0.12
var jump_release_gravity_scale := 2.0
var jump_release_cut := 0.35
var drop_through_time := 0.25
var wall_slide_gravity_scale := 0.4
var wall_jump_speed_x := 200.0
var wall_jump_speed_y := -320.0
var min_jump_height := 44.0 # ~0.7m at 64px/m
var debug_state: String = "idle"
var walk_threshold_pct := 0.25
var sprint_threshold_pct := 0.8
var slope_penalty := 0.5

var max_jumps: int = 2
var jump_count: int = 0
var jump_released_flag: bool = true

# Aerial modifiers (scaffolding; behavior toggled by these flags)
var enable_glide: bool = false
var glide_gravity_scale: float = 0.3
var glide_max_fall_speed: float = 300.0
var enable_flight: bool = false
var flight_acceleration: float = 600.0
var flight_max_speed: float = 400.0
var flight_drag: float = 8.0
var flight_active: bool = false
var glide_active: bool = false

var _move_input := 0.0
var _was_on_floor := false
var _last_dir := 0.0
var _jump_held := false
var _controller := preload("res://engine/actors/movement/BaselinePlatformController.gd").new()
var _jump_start_y: float = 0.0
var _jump_min_reached: bool = true

func _ready() -> void:
	_cache_nodes()
	_register_signals()
	velocity = Vector2.ZERO
	if _actor_interface:
		_actor_interface.initialize(self)
	_link_fsm()


func _physics_process(delta: float) -> void:
	if _is_editor_mode():
		velocity = Vector2.ZERO
		return
	var input := _gather_input()
	if input.get("jump_released", false):
		jump_released_flag = true
	_controller.step(self, input, delta)
	_tick_fsm(delta)
	if _actor_interface:
		_actor_interface.on_actor_physics(delta)
	_update_movement_state()


func _cache_nodes() -> void:
	if _hurtbox:
		_hurtbox.monitoring = true


func _register_signals() -> void:
	if _hurtbox:
		_hurtbox.area_entered.connect(_on_hurtbox_area_entered)


func set_move_input(dir: float) -> void:
	_move_input = clamp(dir, -1.0, 1.0)
	if sign(_move_input) != 0 and sign(_move_input) != sign(_last_dir):
		_last_dir = sign(_move_input)
		direction_changed.emit(_last_dir)


func _apply_gravity(delta: float) -> void:
	# handled in controller
	pass


func _apply_horizontal_accel(delta: float) -> void:
	# handled in controller
	pass


func _apply_friction(delta: float) -> void:
	# handled in controller
	pass


func _move_character() -> void:
	# handled in controller
	pass


func _check_landing() -> void:
	pass


func _on_hurtbox_area_entered(area: Area2D) -> void:
	var damage := 1
	var source_id := area.get_instance_id()
	print("Hurtbox hit by:", area, "source_id:", source_id)
	hurt.emit(damage, source_id)
	if _fsm:
		_fsm.request_state("Hurt", {"source": source_id}, true)


func _process_input(delta: float) -> void:
	var dir := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	set_move_input(dir)
	_jump_held = Input.is_action_pressed("jump")
	if Input.is_action_just_released("jump"):
		_jump_held = false


func get_facing_dir() -> float:
	return _last_dir if _last_dir != 0.0 else 1.0


func set_debug_state(state: String) -> void:
	debug_state = state


func get_debug_state() -> String:
	return debug_state


func _update_coyote_and_buffer(delta: float) -> void:
	# handled in controller
	pass


func _apply_jump_buffer() -> void:
	pass


func _apply_fall_speed_cap() -> void:
	pass


func jump() -> void:
	# controller handles jump
	pass


func _start_drop_through() -> void:
	# controller handles drop-through
	pass


func _update_movement_state() -> void:
	if _fsm == null:
		return
	if not is_on_floor():
		if velocity.y < 0.0:
			_fsm.request_state("Jump")
		else:
			_fsm.request_state("Fall")
		return

	if _fsm.current_state == "Land":
		if absf(_move_input) > 0.05:
			_fsm.request_state("Run")
		else:
			_fsm.request_state("Idle")
		return

	var speed_ratio := absf(velocity.x) / move_speed
	var downhill := _is_downhill()
	if speed_ratio >= sprint_threshold_pct and downhill:
		_fsm.request_state("Sprint")
	elif speed_ratio >= walk_threshold_pct:
		_fsm.request_state("Run")
	elif speed_ratio > 0.05:
		_fsm.request_state("Walk")
	else:
		_fsm.request_state("Idle")


func _slope_accel_scale(dir: float) -> float:
	return 1.0 # handled in controller


func _is_downhill() -> bool:
	if not is_on_floor():
		return false
	var n := get_floor_normal()
	return sign(velocity.x) != 0 and sign(n.x) == sign(velocity.x) and absf(n.x) > 0.01


func _update_drop_through(delta: float) -> void:
	# handled in controller
	pass


func _is_editor_mode() -> bool:
	var mgr := get_tree().root.get_node_or_null("EditorManager")
	if mgr and "editor_mode" in mgr:
		return mgr.editor_mode
	return false


func _gather_input() -> Dictionary:
	if not use_player_input:
		return {
			"dir": _move_input,
			"dir_y": 0.0,
			"jump_pressed": false,
			"jump_released": false,
			"jump_held": false,
			"down_pressed": false,
		}
	var dir := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var dir_y := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	set_move_input(dir)
	_jump_held = Input.is_action_pressed("jump")
	var jump_pressed := Input.is_action_just_pressed("jump")
	var jump_released := Input.is_action_just_released("jump")
	var down_pressed := Input.is_action_pressed("move_down")
	if jump_released:
		jump_released_flag = true
	return {
		"dir": dir,
		"dir_y": dir_y,
		"jump_pressed": jump_pressed,
		"jump_released": jump_released,
		"jump_held": _jump_held,
		"down_pressed": down_pressed,
	}


func _link_fsm() -> void:
	if _fsm:
		_fsm.owner_ref = self
		if _fsm.initial_state != "":
			_fsm.request_state(_fsm.initial_state)


func _tick_fsm(delta: float) -> void:
	if _fsm:
		_fsm.state_physics(delta)
		_fsm.state_process(delta)
		set_debug_state(str(_fsm.current_state))
