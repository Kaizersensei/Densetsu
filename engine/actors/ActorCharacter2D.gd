extends CharacterBody2D

signal landed
signal jumped
signal direction_changed(dir: float)
signal hurt(damage: int, source_id: int)

@onready var _hurtbox: Area2D = $Hurtbox

@export var use_player_input := true

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var move_speed := 140.0
var jump_speed := -320.0
var acceleration := 900.0
var friction_ground := 900.0
var friction_air := 300.0
var max_fall_speed := 900.0
var coyote_time := 0.12
var jump_buffer_time := 0.12
var jump_release_gravity_scale := 2.0
var drop_through_time := 0.25

var _move_input := 0.0
var _was_on_floor := false
var _last_dir := 0.0
var _coyote_timer := 0.0
var _jump_buffer := 0.0
var _jump_held := false
var _drop_timer := 0.0
var _dropping_through := false

func _ready() -> void:
	_cache_nodes()
	_register_signals()
	velocity = Vector2.ZERO
	ActorInterface.initialize(self)


func _physics_process(delta: float) -> void:
	if use_player_input:
		_process_input(delta)
	_update_drop_through(delta)
	_update_coyote_and_buffer(delta)
	_apply_gravity(delta)
	_apply_horizontal_accel(delta)
	_apply_friction(delta)
	_apply_jump_buffer()
	_apply_fall_speed_cap()
	_move_character()
	ActorInterface.post_physics(self)
	_check_landing()


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
	if not is_on_floor():
		var g := gravity
		if velocity.y < 0.0 and not _jump_held:
			g *= jump_release_gravity_scale
		velocity.y += g * delta


func _apply_horizontal_accel(delta: float) -> void:
	if _move_input != 0.0:
		velocity.x = move_toward(velocity.x, _move_input * move_speed, acceleration * delta)


func _apply_friction(delta: float) -> void:
	if _move_input == 0.0:
		var f := friction_ground if is_on_floor() else friction_air
		velocity.x = move_toward(velocity.x, 0.0, f * delta)


func _move_character() -> void:
	move_and_slide()


func _check_landing() -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		landed.emit()
	_was_on_floor = on_floor


func _on_hurtbox_area_entered(area: Area2D) -> void:
	var damage := 1
	var source_id := area.get_instance_id()
	print("Hurtbox hit by:", area, "source_id:", source_id)
	hurt.emit(damage, source_id)


func _process_input(delta: float) -> void:
	var dir := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	set_move_input(dir)
	_jump_held = Input.is_action_pressed("jump")
	if Input.is_action_pressed("move_down") and Input.is_action_just_pressed("jump") and is_on_floor():
		_start_drop_through()
	elif Input.is_action_just_pressed("jump"):
		_jump_buffer = jump_buffer_time
	if Input.is_action_just_released("jump"):
		_jump_held = false


func get_facing_dir() -> float:
	return _last_dir if _last_dir != 0.0 else 1.0


func _update_coyote_and_buffer(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)

	if _jump_buffer > 0.0:
		_jump_buffer = max(_jump_buffer - delta, 0.0)


func _apply_jump_buffer() -> void:
	if _jump_buffer > 0.0 and (is_on_floor() or _coyote_timer > 0.0):
		_jump_buffer = 0.0
		jump()


func _apply_fall_speed_cap() -> void:
	if velocity.y > max_fall_speed:
		velocity.y = max_fall_speed


func jump() -> void:
	if _can_jump():
		velocity.y = jump_speed
		_coyote_timer = 0.0
		jumped.emit()


func _can_jump() -> bool:
	return is_on_floor() or _coyote_timer > 0.0


func _start_drop_through() -> void:
	if _dropping_through:
		return
	_dropping_through = true
	_drop_timer = drop_through_time
	set_collision_mask_value(8, false)
	if velocity.y < 0.0:
		velocity.y = 0.0
	velocity.y += 50.0


func _update_drop_through(delta: float) -> void:
	if _drop_timer > 0.0:
		_drop_timer -= delta
		if _drop_timer <= 0.0:
			_dropping_through = false
			set_collision_mask_value(8, true)
