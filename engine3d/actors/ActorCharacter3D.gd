@tool
extends CharacterBody3D
class_name ActorCharacter3D

signal landed
signal jumped
signal direction_changed(dir: Vector3)
signal hurt(damage: int, source_id: int)

enum ActorRole {
	PLAYER,
	NPC,
	SCENERY,
}

enum ControllerType {
	NONE,
	PLAYER,
	AI,
	SCRIPTED,
}

enum CameraContext {
	SIMPLE_THIRD_PERSON,
}

const COLLIDER_KIND_NONE := 0
const COLLIDER_KIND_CAPSULE := 1
const COLLIDER_KIND_BOX := 2
const COLLIDER_KIND_CYLINDER := 3

@export_category("Entity Data")
@export_group("Identity")
@export var actor_data_id: String = ""
@export var actor_role: ActorRole = ActorRole.NPC
@export var actor_tags: PackedStringArray = PackedStringArray()
@export var faction_id: String = ""
@export var team: String = ""
@export var owner_id: int = -1

@export_group("Lifecycle")
@export var initial_state: String = ""
@export var active_state: String = "active"

@export_category("Controller")
@export var controller_type: ControllerType = ControllerType.NONE
@export var use_player_input: bool = false
@export var player_number: int = 1
@export var use_basic_movement: bool = true

@export_category("Camera Context")
@export var camera_context: CameraContext = CameraContext.SIMPLE_THIRD_PERSON

@export_category("Pivot")
@export var pivot_align_bottom: bool = true
@export var pivot_offset: Vector3 = Vector3.ZERO

@export_category("Movement Params")
@export_group("Base", "base_")
var _syncing_movement_proxy := false
var _movement_gravity := 0.0
var _movement_walk_speed := 0.0
var _movement_run_speed := 0.0
var _movement_acceleration := 0.0
var _movement_deceleration := 0.0
var _movement_turn_rate := 0.0
var _movement_turn_smooth := 0.0
var _movement_turn_invert := false
var _movement_max_slope_angle := 0.0
var _movement_step_height := 0.0
var _movement_step_snap_max_angle := 0.0
var _movement_step_sensor_distance := 0.0
var _movement_step_snap_smooth_speed := 0.0
var _movement_air_control := 0.0
var _movement_air_accel := 0.0
var _movement_air_decel := 0.0
var _movement_max_fall_speed := 0.0
var _movement_jump_speed := 0.0
var _movement_max_jumps := 0
var _movement_coyote_time := 0.0
var _movement_jump_buffer_time := 0.0
var _movement_jump_cut := 0.0
var _movement_double_jump_speed := 0.0
var _movement_double_jump_clamp_fall_speed := 0.0
var _movement_require_jump_release := false
var _movement_wall_jump_enabled := true
var _movement_wall_check_distance := 0.0
var _movement_wall_check_height := 0.0
var _movement_wall_slide_gravity_scale := 0.0
var _movement_wall_slide_max_fall_speed := 0.0
var _movement_wall_jump_up_speed := 0.0
var _movement_wall_jump_push_speed := 0.0
var _movement_wall_jump_lock_time := 0.0
var _movement_dash_speed := 0.0
var _movement_dash_time := 0.0
var _movement_dash_cooldown := 0.0
var _movement_dash_allow_air := false
var _movement_dash_allow_double_tap := false
var _movement_dash_double_tap_window := 0.0
var _movement_roll_speed := 0.0
var _movement_roll_time := 0.0
var _movement_roll_cooldown := 0.0
var _movement_crouch_height := 0.0
var _movement_crouch_speed := 0.0
var _movement_sneak_speed := 0.0
var _movement_drop_through_time := 0.0
var _movement_drop_through_layer := 0
var _movement_drop_through_speed := 0.0
var _movement_high_fall_speed := 0.0
var _movement_high_fall_time := 0.0
@export var base_gravity: float:
	get:
		return _movement_gravity
	set(value):
		_movement_gravity = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("gravity", value)
@export var base_walk_speed: float:
	get:
		return _movement_walk_speed
	set(value):
		_movement_walk_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("walk_speed", value)
@export var base_run_speed: float:
	get:
		return _movement_run_speed
	set(value):
		_movement_run_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("run_speed", value)
@export var base_acceleration: float:
	get:
		return _movement_acceleration
	set(value):
		_movement_acceleration = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("acceleration", value)
@export var base_deceleration: float:
	get:
		return _movement_deceleration
	set(value):
		_movement_deceleration = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("deceleration", value)

@export_group("Turning", "turn_")
@export var turn_rate: float:
	get:
		return _movement_turn_rate
	set(value):
		_movement_turn_rate = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("turn_rate", value)
@export var turn_smooth: float:
	get:
		return _movement_turn_smooth
	set(value):
		_movement_turn_smooth = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("turn_smooth", value)
@export var turn_invert: bool:
	get:
		return _movement_turn_invert
	set(value):
		_movement_turn_invert = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("turn_invert", value)

@export_group("Advanced", "advanced_")
@export var advanced_max_slope_angle: float:
	get:
		return _movement_max_slope_angle
	set(value):
		_movement_max_slope_angle = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("max_slope_angle", value)
@export var advanced_step_height: float:
	get:
		return _movement_step_height
	set(value):
		_movement_step_height = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("step_height", value)
@export var advanced_step_snap_max_angle: float:
	get:
		return _movement_step_snap_max_angle
	set(value):
		_movement_step_snap_max_angle = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("step_snap_max_angle", value)
@export var advanced_step_sensor_distance: float:
	get:
		return _movement_step_sensor_distance
	set(value):
		_movement_step_sensor_distance = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("step_sensor_distance", value)
@export var advanced_step_snap_smooth_speed: float:
	get:
		return _movement_step_snap_smooth_speed
	set(value):
		_movement_step_snap_smooth_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("step_snap_smooth_speed", value)
@export var advanced_air_control: float:
	get:
		return _movement_air_control
	set(value):
		_movement_air_control = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("air_control", value)
@export var advanced_air_accel: float:
	get:
		return _movement_air_accel
	set(value):
		_movement_air_accel = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("air_accel", value)
@export var advanced_air_decel: float:
	get:
		return _movement_air_decel
	set(value):
		_movement_air_decel = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("air_decel", value)
@export var advanced_max_fall_speed: float:
	get:
		return _movement_max_fall_speed
	set(value):
		_movement_max_fall_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("max_fall_speed", value)

@export_group("Jump", "jump_")
@export var jump_speed: float:
	get:
		return _movement_jump_speed
	set(value):
		_movement_jump_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("jump_speed", value)
@export var jump_double_speed: float:
	get:
		return _movement_double_jump_speed
	set(value):
		_movement_double_jump_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("double_jump_speed", value)
@export var jump_max_jumps: int:
	get:
		return _movement_max_jumps
	set(value):
		_movement_max_jumps = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("max_jumps", value)
@export var jump_coyote_time: float:
	get:
		return _movement_coyote_time
	set(value):
		_movement_coyote_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("coyote_time", value)
@export var jump_buffer_time: float:
	get:
		return _movement_jump_buffer_time
	set(value):
		_movement_jump_buffer_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("jump_buffer_time", value)
@export var jump_require_release: bool:
	get:
		return _movement_require_jump_release
	set(value):
		_movement_require_jump_release = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("require_jump_release", value)
@export var jump_double_clamp_fall_speed: float:
	get:
		return _movement_double_jump_clamp_fall_speed
	set(value):
		_movement_double_jump_clamp_fall_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("double_jump_clamp_fall_speed", value)
@export var jump_cut: float:
	get:
		return _movement_jump_cut
	set(value):
		_movement_jump_cut = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("jump_cut", value)

@export_group("Wall", "wall_")
@export var wall_jump_enabled: bool:
	get:
		return _movement_wall_jump_enabled
	set(value):
		_movement_wall_jump_enabled = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_jump_enabled", value)
@export var wall_check_distance: float:
	get:
		return _movement_wall_check_distance
	set(value):
		_movement_wall_check_distance = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_check_distance", value)
@export var wall_check_height: float:
	get:
		return _movement_wall_check_height
	set(value):
		_movement_wall_check_height = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_check_height", value)
@export var wall_slide_gravity_scale: float:
	get:
		return _movement_wall_slide_gravity_scale
	set(value):
		_movement_wall_slide_gravity_scale = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_slide_gravity_scale", value)
@export var wall_slide_max_fall_speed: float:
	get:
		return _movement_wall_slide_max_fall_speed
	set(value):
		_movement_wall_slide_max_fall_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_slide_max_fall_speed", value)
@export var wall_jump_up_speed: float:
	get:
		return _movement_wall_jump_up_speed
	set(value):
		_movement_wall_jump_up_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_jump_up_speed", value)
@export var wall_jump_push_speed: float:
	get:
		return _movement_wall_jump_push_speed
	set(value):
		_movement_wall_jump_push_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_jump_push_speed", value)
@export var wall_jump_lock_time: float:
	get:
		return _movement_wall_jump_lock_time
	set(value):
		_movement_wall_jump_lock_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_jump_lock_time", value)

@export_group("Dash", "dash_")
@export var dash_speed: float:
	get:
		return _movement_dash_speed
	set(value):
		_movement_dash_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("dash_speed", value)
@export var dash_time: float:
	get:
		return _movement_dash_time
	set(value):
		_movement_dash_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("dash_time", value)
@export var dash_cooldown: float:
	get:
		return _movement_dash_cooldown
	set(value):
		_movement_dash_cooldown = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("dash_cooldown", value)
@export var dash_allow_air: bool:
	get:
		return _movement_dash_allow_air
	set(value):
		_movement_dash_allow_air = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("dash_allow_air", value)
@export var dash_allow_double_tap: bool:
	get:
		return _movement_dash_allow_double_tap
	set(value):
		_movement_dash_allow_double_tap = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("dash_allow_double_tap", value)
@export var dash_double_tap_window: float:
	get:
		return _movement_dash_double_tap_window
	set(value):
		_movement_dash_double_tap_window = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("dash_double_tap_window", value)

@export_group("Roll", "roll_")
@export var roll_speed: float:
	get:
		return _movement_roll_speed
	set(value):
		_movement_roll_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("roll_speed", value)
@export var roll_time: float:
	get:
		return _movement_roll_time
	set(value):
		_movement_roll_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("roll_time", value)
@export var roll_cooldown: float:
	get:
		return _movement_roll_cooldown
	set(value):
		_movement_roll_cooldown = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("roll_cooldown", value)

@export_group("Posture", "posture_")
@export var posture_crouch_toggle: bool = false
@export var posture_crouch_height: float:
	get:
		return _movement_crouch_height
	set(value):
		_movement_crouch_height = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("crouch_height", value)
@export var posture_crouch_speed: float:
	get:
		return _movement_crouch_speed
	set(value):
		_movement_crouch_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("crouch_speed", value)
@export var posture_sneak_speed: float:
	get:
		return _movement_sneak_speed
	set(value):
		_movement_sneak_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("sneak_speed", value)

@export_group("Drop Through", "drop_")
@export var drop_through_time: float:
	get:
		return _movement_drop_through_time
	set(value):
		_movement_drop_through_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("drop_through_time", value)
@export var drop_through_layer: int:
	get:
		return _movement_drop_through_layer
	set(value):
		_movement_drop_through_layer = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("drop_through_layer", value)
@export var drop_through_speed: float:
	get:
		return _movement_drop_through_speed
	set(value):
		_movement_drop_through_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("drop_through_speed", value)

@export_group("Fall", "fall_")
@export var fall_high_speed: float:
	get:
		return _movement_high_fall_speed
	set(value):
		_movement_high_fall_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("high_fall_speed", value)
@export var fall_high_time: float:
	get:
		return _movement_high_fall_time
	set(value):
		_movement_high_fall_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("high_fall_time", value)

@export_category("Data Overrides")
@export_group("Ids")
@export var movement_id: String = ""
@export var model_id: String = ""
@export var camera_id: String = ""
@export var stats_id: String = ""
@export var formulas_id: String = ""

@export_group("Resources")
var _movement_data: MovementData3D
var _model_data: ModelData3D
@export var movement_data: MovementData3D:
	get:
		return _movement_data
	set(value):
		_movement_data = value
		if _controller_ctx:
			_controller_ctx.movement = _get_movement_params()
		if Engine.is_editor_hint():
			_sync_movement_proxy_from_resource()
@export var model_data: ModelData3D:
	get:
		return _model_data
	set(value):
		_model_data = value
		if Engine.is_editor_hint() and is_inside_tree():
			_refresh_editor_model()
@export var camera_data: CameraRigData3D
@export var stats_data: StatsData
@export var formulas_data: StatsFormulaData

@export_category("Debug")
@export var debug_step_sensors: bool = false

@export_category("Editor")
var _preview_model_in_editor := false
@export var preview_model_in_editor: bool = false:
	get:
		return _preview_model_in_editor
	set(value):
		_preview_model_in_editor = value
		if Engine.is_editor_hint() and is_inside_tree():
			_refresh_editor_model()

@onready var _actor_interface: ActorInterface3D = $ActorInterface3D
@onready var _fsm: StateMachine = $StateMachine

var _input_source: IInputSource
var _controller_ctx: ControllerContext3D
var _anim_driver: AnimDriver3D
var _default_movement: MovementData3D = MovementData3D.new()
var _was_on_floor := false
var _last_move_dir := Vector3.ZERO
var aim_direction: Vector3 = Vector3.FORWARD
var controls_enabled := true
var can_move := 1
var alive := true
var restrained := false
var facing := 1
var input_x := 0.0
var input_y := 0.0
var in_air := false
var falling := false
var jumping := false
var jump_count := 0
var can_double_jump := true
var air_time := 0.0
var high_fall := false
var can_wall_jump := false
var wall_jumping := false
var wall_side := 0
var wall_jump_lock := 0.0
var dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := Vector3.ZERO
var roll_active := false
var roll_timer := 0.0
var roll_cooldown_timer := 0.0
var roll_direction := Vector3.ZERO
var crouching := false
var sneaking := false
var _crouch_toggle_state := false
var _crouch_applied := false
var _crouch_cached := false
var _crouch_collider_kind := COLLIDER_KIND_NONE
var _stand_capsule_height := 0.0
var _stand_capsule_radius := 0.0
var _stand_box_size := Vector3.ZERO
var _stand_cylinder_height := 0.0
var _stand_cylinder_radius := 0.0
var _collision_shape_node: CollisionShape3D
var falling_through := false
var drop_through_timer := 0.0
var _drop_through_masked := false
var speed_x := 0.0
var speed_y := 0.0
var speed_x_abs := 0.0
var speed_y_abs := 0.0
var moving_at_speed := false
var double_tap_left := false
var double_tap_right := false
var double_tap_timer_l := 0.0
var double_tap_timer_r := 0.0
var jump_released := true
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var _turn_velocity := 0.0
var _model_applied := false
var _debug_mesh: MeshInstance3D
var _visual_pivot_base := Vector3.ZERO
var _step_visual_offset := 0.0
var _step_sensor: Area3D
var _step_sensor_shape: CollisionShape3D
var _step_floor_cast: ShapeCast3D
var _debug_step_root: Node3D
var _debug_step_sensor_mesh: MeshInstance3D
var _debug_step_cast_mesh: MeshInstance3D
var _debug_step_hit_mesh: MeshInstance3D
var _debug_step_contact_mesh: MeshInstance3D
var _debug_step_up_mesh: MeshInstance3D
var _debug_step_forward_mesh: MeshInstance3D
var _debug_step_hit := Vector3.ZERO
var _debug_step_hit_valid := false
var _debug_step_has_overlap := false
var _debug_step_cast_hit := false
var _debug_step_contact_pos := Vector3.ZERO
var _debug_step_contact_valid := false
var _debug_step_contact_ok := false
var _debug_step_up_pos := Vector3.ZERO
var _debug_step_up_valid := false
var _debug_step_up_clear := false
var _debug_step_forward_pos := Vector3.ZERO
var _debug_step_forward_valid := false
var _debug_step_forward_clear := false
var _step_carry_pending := false
var _step_carry_velocity := Vector3.ZERO

func _ready() -> void:
	if Engine.is_editor_hint():
		_sync_movement_proxy_from_resource()
		_apply_pivot_defaults()
		_refresh_editor_model()
		return
	_apply_controller_defaults()
	_setup_input_source()
	_setup_controller_context()
	velocity = Vector3.ZERO
	if _actor_interface:
		_actor_interface.initialize(self)
		_apply_actor_tags()
		_actor_interface.set_active_state(active_state)
	_apply_data_ids()
	if model_id == "" and model_data:
		_apply_model_resource(model_data)
	elif model_data == null:
		_set_debug_mesh_visible(true)
	_apply_camera_override()
	_apply_pivot_defaults()
	_cache_crouch_collider()
	_link_fsm()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if use_basic_movement:
		_apply_basic_movement(delta)
	_tick_fsm(delta)
	if _actor_interface:
		_actor_interface.on_actor_physics(delta)


func apply_movement_data(id: String) -> void:
	movement_id = id
	var reg: Node = _registry()
	if reg and reg.has_method("get_resource_for_category"):
		var res = reg.get_resource_for_category("Movement3D", id)
		if res:
			movement_data = res
	if _controller_ctx:
		_controller_ctx.movement = _get_movement_params()
	_sync_movement_proxy_from_resource()


func apply_model_data(id: String) -> void:
	model_id = id
	var reg: Node = _registry()
	if reg and reg.has_method("get_resource_for_category"):
		var res = reg.get_resource_for_category("Model3D", id)
		if res:
			model_data = res
	if model_data:
		_apply_model_resource(model_data)
	else:
		_set_debug_mesh_visible(true)


func apply_camera_data(id: String) -> void:
	camera_id = id
	var reg: Node = _registry()
	if reg and reg.has_method("get_resource_for_category"):
		var res = reg.get_resource_for_category("CameraRig3D", id)
		if res:
			camera_data = res
	_apply_camera_override()
	if _controller_ctx:
		_controller_ctx.camera = _find_orbit_camera()


func _apply_controller_defaults() -> void:
	match controller_type:
		ControllerType.PLAYER:
			use_player_input = true
		ControllerType.AI, ControllerType.SCRIPTED, ControllerType.NONE:
			use_player_input = false


func _setup_input_source() -> void:
	if use_player_input or controller_type == ControllerType.PLAYER:
		_input_source = PlayerInputSource.new(player_number)
	else:
		_input_source = NullInputSource.new()
	if _controller_ctx:
		_controller_ctx.input = _input_source


func _setup_controller_context() -> void:
	_controller_ctx = ControllerContext3D.new()
	_controller_ctx.actor = self
	_controller_ctx.input = _get_input_source()
	_controller_ctx.movement = _get_movement_params()
	_controller_ctx.camera = _find_orbit_camera()
	_controller_ctx.anim = _find_anim_driver()


func _apply_actor_tags() -> void:
	if not _actor_interface:
		return
	for tag in actor_tags:
		_actor_interface.add_tag(tag)


func _link_fsm() -> void:
	if _fsm:
		_fsm.owner_ref = self
		var target_state := initial_state if initial_state != "" else _fsm.initial_state
		if target_state != "":
			_fsm.request_state(target_state)


func _tick_fsm(delta: float) -> void:
	if _controller_ctx:
		_controller_ctx.refresh()
	if _fsm:
		_fsm.state_physics(delta)
		_fsm.state_process(delta)


func _apply_basic_movement(delta: float) -> void:
	var params: MovementData3D = _get_movement_params()
	var input: IInputSource = _get_input_source()
	var on_floor := is_on_floor()
	_update_input_state(input, params, delta)
	_update_ground_air_state(on_floor, params, delta)
	_update_wall_state(params, delta)
	_update_drop_through(input, params, delta, on_floor)
	_update_dash(input, params, delta, on_floor)
	_update_roll(input, params, delta, on_floor)
	_update_posture(input, on_floor, params)
	var move := Vector2(input_x, input_y)
	if move.length() > 1.0:
		move = move.normalized()
	if camera_context == CameraContext.SIMPLE_THIRD_PERSON and not roll_active:
		_apply_simple_third_person_turn(move, Vector3.ZERO, params, delta)
	var move_dir := _get_move_direction(move)
	var desired := Vector3.ZERO
	if _movement_allowed():
		var target_speed := _get_target_speed(params, input)
		desired = move_dir * target_speed
	if roll_active:
		_apply_roll_velocity(params, on_floor)
	else:
		_apply_walk_velocity(desired, params, on_floor, delta)
		_apply_jump_logic(params, on_floor)
	_apply_gravity(params, on_floor, delta)
	if on_floor and velocity.y <= 0.0:
		_try_step_snap(params, move_dir, delta)
	_update_step_visual(params, delta)
	_update_speed_metrics(params)
	move_and_slide()
	_apply_step_momentum_carry()
	_update_landing_state()
	_update_move_dir(desired)
	if camera_context != CameraContext.SIMPLE_THIRD_PERSON and not roll_active:
		_apply_turning(move, move_dir, params, delta)


func _input_allowed() -> bool:
	return controls_enabled and alive and not restrained


func _movement_allowed() -> bool:
	if not _input_allowed():
		return false
	return can_move == 1 and not roll_active


func _update_input_state(input: IInputSource, params: MovementData3D, delta: float) -> void:
	if _input_allowed():
		var move_vec: Vector2 = input.get_move_vector()
		input_x = clampf(move_vec.x, -1.0, 1.0)
		input_y = clampf(move_vec.y, -1.0, 1.0)
		if absf(input_x) > 0.01:
			facing = 1 if input_x > 0.0 else -1
		if can_move == 1 and input.is_jump_just_pressed():
			jump_buffer_timer = params.jump_buffer_time
		else:
			jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
		if input.is_jump_just_released():
			jump_released = true
			if velocity.y > 0.0 and params.jump_cut > 0.0 and params.jump_cut < 1.0:
				velocity.y *= params.jump_cut
	else:
		input_x = 0.0
		input_y = 0.0
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)


func _update_double_tap(input: IInputSource, params: MovementData3D, delta: float) -> void:
	double_tap_left = false
	double_tap_right = false
	if params.dash_allow_double_tap and _input_allowed() and can_move == 1:
		if input.is_move_left_just_pressed():
			if double_tap_timer_l > 0.0:
				double_tap_left = true
			double_tap_timer_l = params.dash_double_tap_window
		if input.is_move_right_just_pressed():
			if double_tap_timer_r > 0.0:
				double_tap_right = true
			double_tap_timer_r = params.dash_double_tap_window
	double_tap_timer_l = maxf(0.0, double_tap_timer_l - delta)
	double_tap_timer_r = maxf(0.0, double_tap_timer_r - delta)


func _update_ground_air_state(on_floor: bool, params: MovementData3D, delta: float) -> void:
	if on_floor:
		in_air = false
		falling = false
		jumping = false
		air_time = 0.0
		high_fall = false
		jump_count = 0
		can_double_jump = params.max_jumps > 1
		coyote_timer = params.coyote_time
	else:
		in_air = true
		air_time += delta
		falling = velocity.y < -0.01
		coyote_timer = maxf(0.0, coyote_timer - delta)
	if wall_jump_lock > 0.0:
		wall_jump_lock = maxf(0.0, wall_jump_lock - delta)


func _update_speed_metrics(params: MovementData3D) -> void:
	var horiz := Vector2(velocity.x, velocity.z)
	speed_x = horiz.length()
	speed_y = velocity.y
	speed_x_abs = absf(speed_x)
	speed_y_abs = absf(speed_y)
	var run_threshold := params.run_speed * 0.9
	moving_at_speed = speed_x_abs > run_threshold
	if params.high_fall_speed > 0.0 and params.high_fall_time > 0.0:
		if in_air and falling and speed_y_abs > params.high_fall_speed and air_time > params.high_fall_time:
			high_fall = true


func _update_wall_state(params: MovementData3D, _delta: float) -> void:
	can_wall_jump = false
	wall_side = 0
	if not params.wall_jump_enabled:
		return
	if wall_jump_lock > 0.0:
		return
	if not in_air:
		return
	if params.wall_check_distance <= 0.0:
		return
	var origin := global_transform.origin + Vector3.UP * params.wall_check_height
	var left_dir := -global_transform.basis.x
	if _raycast_wall(origin, left_dir, params.wall_check_distance):
		can_wall_jump = true
		wall_side = -1
		return
	var right_dir := global_transform.basis.x
	if _raycast_wall(origin, right_dir, params.wall_check_distance):
		can_wall_jump = true
		wall_side = 1


func _update_drop_through(input: IInputSource, params: MovementData3D, delta: float, on_floor: bool) -> void:
	if not _input_allowed():
		_clear_drop_through(params)
		return
	if falling_through:
		drop_through_timer = maxf(0.0, drop_through_timer - delta)
		if drop_through_timer <= 0.0:
			_clear_drop_through(params)
		return
	if not on_floor:
		return
	if params.drop_through_layer <= 0 or params.drop_through_time <= 0.0:
		return
	if input.is_jump_just_pressed() and input_y > 0.5:
		falling_through = true
		drop_through_timer = params.drop_through_time
		jump_buffer_timer = 0.0
		_set_drop_through_mask(params, false)
		if params.drop_through_speed > 0.0:
			velocity.y = -params.drop_through_speed


func _clear_drop_through(params: MovementData3D) -> void:
	if not falling_through:
		return
	falling_through = false
	drop_through_timer = 0.0
	_set_drop_through_mask(params, true)


func _set_drop_through_mask(params: MovementData3D, enabled: bool) -> void:
	if params.drop_through_layer <= 0:
		return
	var layer := params.drop_through_layer
	set_collision_mask_value(layer, enabled)
	_drop_through_masked = not enabled


func _update_dash(input: IInputSource, params: MovementData3D, delta: float, on_floor: bool) -> void:
	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)
	var dash_input := Vector2(input_x, input_y)
	var dash_held := input.is_dash_held()
	if dashing:
		dash_timer = maxf(0.0, dash_timer - delta)
		if dash_held and dash_input.length() > 0.01:
			var steer_dir := _move_vector_to_dir(Vector2(input_x, input_y))
			if steer_dir.length() > 0.01:
				dash_direction = steer_dir
		if dash_timer <= 0.0:
			if dash_held and dash_input.length() > 0.01:
				dash_timer = params.dash_time
			else:
				dashing = false
		return
	if not _input_allowed() or can_move != 1:
		return
	if dash_cooldown_timer > 0.0:
		return
	var want_dash := input.is_dash_just_pressed() or (dash_held and dash_input.length() > 0.01)
	if not want_dash:
		return
	if on_floor and input_y > 0.5:
		return
	if not params.dash_allow_air and not on_floor:
		return
	if dash_input.length() <= 0.01:
		return
	_start_dash(params, _move_vector_to_dir(Vector2(input_x, input_y)))


func _start_dash(params: MovementData3D, move_dir: Vector3) -> void:
	dashing = true
	dash_timer = params.dash_time
	dash_cooldown_timer = params.dash_cooldown
	roll_active = false
	if move_dir.length() > 0.01:
		dash_direction = move_dir
	else:
		dash_direction = _get_forward_direction()


func _apply_dash_velocity(params: MovementData3D, on_floor: bool) -> void:
	var dir := dash_direction
	if dir.length() <= 0.001:
		dir = _get_forward_direction()
	dir = dir.normalized()
	velocity.x = dir.x * params.dash_speed
	velocity.z = dir.z * params.dash_speed
	if on_floor:
		velocity.y = minf(velocity.y, 0.0)


func _update_roll(input: IInputSource, params: MovementData3D, delta: float, on_floor: bool) -> void:
	roll_cooldown_timer = maxf(0.0, roll_cooldown_timer - delta)
	if roll_active:
		roll_timer = maxf(0.0, roll_timer - delta)
		if roll_timer <= 0.0:
			roll_active = false
			if can_move == 0:
				can_move = 1
		return
	if not _input_allowed() or can_move != 1:
		return
	if roll_cooldown_timer > 0.0:
		return
	if not on_floor:
		return
	var move_mag := Vector2(input_x, input_y).length()
	var wants_roll := input.is_crouch_just_pressed() and move_mag > 0.2
	if not wants_roll:
		return
	_start_roll(params, _get_forward_direction())


func _update_posture(input: IInputSource, on_floor: bool, params: MovementData3D) -> void:
	if not _input_allowed():
		_apply_crouch_state(false, params)
		crouching = false
		sneaking = false
		return
	if posture_crouch_toggle:
		if input.is_crouch_just_pressed():
			_crouch_toggle_state = not _crouch_toggle_state
	else:
		_crouch_toggle_state = input.is_crouch_held()
	var wants_crouch := false
	if dashing or roll_active:
		wants_crouch = false
		sneaking = false
	else:
		wants_crouch = _crouch_toggle_state and on_floor
		sneaking = input.is_sneak_held() and on_floor
	if not wants_crouch and crouching:
		if not _can_stand_up(params):
			wants_crouch = true
	_apply_crouch_state(wants_crouch, params)
	crouching = wants_crouch


func _cache_crouch_collider() -> void:
	_ensure_crouch_cache()


func _apply_crouch_state(should_crouch: bool, params: MovementData3D) -> void:
	var data: MovementData3D = params
	if data == null:
		data = _get_movement_params()
	if _crouch_applied == should_crouch:
		return
	_ensure_crouch_cache()
	if _crouch_collider_kind == COLLIDER_KIND_NONE:
		_crouch_applied = should_crouch
		return
	var target_height: float = _get_stand_total_height()
	if should_crouch:
		target_height = _get_crouch_total_height(data)
	if target_height <= 0.0:
		_crouch_applied = should_crouch
		return
	_apply_collider_height(target_height)
	_apply_pivot_defaults()
	_crouch_applied = should_crouch


func _ensure_crouch_cache() -> void:
	var collision := _get_collision_shape_node()
	if collision == null or collision.shape == null:
		_collision_shape_node = collision
		_crouch_collider_kind = COLLIDER_KIND_NONE
		_crouch_cached = true
		return
	if _crouch_cached and _collision_shape_node == collision:
		return
	_collision_shape_node = collision
	_crouch_cached = true
	var shape: Shape3D = collision.shape
	if shape is CapsuleShape3D:
		var capsule := shape as CapsuleShape3D
		_crouch_collider_kind = COLLIDER_KIND_CAPSULE
		_stand_capsule_height = capsule.height
		_stand_capsule_radius = capsule.radius
	elif shape is BoxShape3D:
		var box := shape as BoxShape3D
		_crouch_collider_kind = COLLIDER_KIND_BOX
		_stand_box_size = box.size
	elif shape is CylinderShape3D:
		var cylinder := shape as CylinderShape3D
		_crouch_collider_kind = COLLIDER_KIND_CYLINDER
		_stand_cylinder_height = cylinder.height
		_stand_cylinder_radius = cylinder.radius
	else:
		_crouch_collider_kind = COLLIDER_KIND_NONE


func _can_stand_up(params: MovementData3D) -> bool:
	if params == null:
		return true
	_ensure_crouch_cache()
	if _crouch_collider_kind == COLLIDER_KIND_NONE:
		return true
	var collision := _collision_shape_node
	if collision == null or collision.shape == null:
		return true
	var stand_height: float = _get_stand_total_height()
	var current_height: float = _get_shape_height(collision.shape)
	if stand_height <= 0.0 or stand_height <= current_height + 0.001:
		return true
	var query_shape := _build_shape_for_height(stand_height)
	if query_shape == null:
		return true
	var world := get_world_3d()
	if world == null:
		return true
	var space := world.direct_space_state
	if space == null:
		return true
	var bottom := collision.global_transform.origin - Vector3.UP * (current_height * 0.5)
	var center := bottom + Vector3.UP * (stand_height * 0.5)
	var xform := collision.global_transform
	xform.origin = center
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = query_shape
	query.transform = xform
	query.collision_mask = collision_mask
	query.exclude = [self]
	var hits: Array = space.intersect_shape(query, 1)
	return hits.is_empty()


func _get_stand_total_height() -> float:
	match _crouch_collider_kind:
		COLLIDER_KIND_CAPSULE:
			return _stand_capsule_height + _stand_capsule_radius * 2.0
		COLLIDER_KIND_BOX:
			return _stand_box_size.y
		COLLIDER_KIND_CYLINDER:
			return _stand_cylinder_height
	return 0.0


func _get_crouch_total_height(params: MovementData3D) -> float:
	var stand_height: float = _get_stand_total_height()
	if stand_height <= 0.0:
		return 0.0
	var target: float = params.crouch_height
	if target <= 0.0:
		target = stand_height * 0.6
	target = clampf(target, 0.1, stand_height)
	return target


func _apply_collider_height(target_height: float) -> void:
	var collision := _collision_shape_node
	if collision == null or collision.shape == null:
		return
	match _crouch_collider_kind:
		COLLIDER_KIND_CAPSULE:
			var capsule := collision.shape as CapsuleShape3D
			if capsule == null:
				return
			var cap_height: float = maxf(0.0, target_height - _stand_capsule_radius * 2.0)
			capsule.height = cap_height
		COLLIDER_KIND_BOX:
			var box := collision.shape as BoxShape3D
			if box == null:
				return
			var size := _stand_box_size
			size.y = target_height
			box.size = size
		COLLIDER_KIND_CYLINDER:
			var cylinder := collision.shape as CylinderShape3D
			if cylinder == null:
				return
			cylinder.height = target_height


func _build_shape_for_height(target_height: float) -> Shape3D:
	match _crouch_collider_kind:
		COLLIDER_KIND_CAPSULE:
			var capsule := CapsuleShape3D.new()
			capsule.radius = _stand_capsule_radius
			capsule.height = maxf(0.0, target_height - _stand_capsule_radius * 2.0)
			return capsule
		COLLIDER_KIND_BOX:
			var box := BoxShape3D.new()
			box.size = Vector3(_stand_box_size.x, target_height, _stand_box_size.z)
			return box
		COLLIDER_KIND_CYLINDER:
			var cylinder := CylinderShape3D.new()
			cylinder.radius = _stand_cylinder_radius
			cylinder.height = target_height
			return cylinder
	return null


func _start_roll(params: MovementData3D, dir: Vector3) -> void:
	roll_active = true
	roll_timer = params.roll_time
	roll_cooldown_timer = params.roll_cooldown
	can_move = 0
	dashing = false
	jump_buffer_timer = 0.0
	jump_released = false
	roll_direction = dir.normalized() if dir.length() > 0.01 else _get_forward_direction()


func _apply_roll_velocity(params: MovementData3D, on_floor: bool) -> void:
	var dir := roll_direction
	if dir.length() <= 0.001:
		dir = _get_forward_direction()
	dir = dir.normalized()
	velocity.x = dir.x * params.roll_speed
	velocity.z = dir.z * params.roll_speed
	if on_floor:
		velocity.y = minf(velocity.y, 0.0)


func _get_target_speed(params: MovementData3D, input: IInputSource) -> float:
	var speed := params.walk_speed
	if input.is_run_held():
		speed = params.run_speed
	if dashing:
		speed = maxf(speed, params.dash_speed)
	if sneaking:
		speed = minf(speed, params.sneak_speed)
	if crouching:
		speed = minf(speed, params.crouch_speed)
	return speed


func _apply_walk_velocity(desired: Vector3, params: MovementData3D, on_floor: bool, delta: float) -> void:
	var accel := params.acceleration
	var decel := params.deceleration
	var control := 1.0
	if not on_floor:
		accel = params.air_accel
		decel = params.air_decel
		control = params.air_control
	var step := accel if desired.length() > 0.0 else decel
	step *= control
	velocity.x = move_toward(velocity.x, desired.x, step * delta)
	velocity.z = move_toward(velocity.z, desired.z, step * delta)


func _try_step_snap(params: MovementData3D, move_dir: Vector3, delta: float) -> void:
	_debug_step_contact_valid = false
	_debug_step_up_valid = false
	_debug_step_forward_valid = false
	if params.step_height <= 0.0:
		return
	if params.step_sensor_distance <= 0.0:
		return
	if move_dir.length() <= 0.001:
		return
	var step_dir := move_dir
	var blocking_normal := _get_blocking_normal()
	if blocking_normal != Vector3.ZERO:
		step_dir = -blocking_normal
		step_dir.y = 0.0
		if step_dir.length() <= 0.001:
			step_dir = move_dir
		else:
			step_dir = step_dir.normalized()
	var step_info := _detect_step_ahead(params, step_dir)
	if step_info.is_empty():
		return
	var step_height: float = step_info.height
	if step_height <= 0.0:
		return
	var horiz_motion := Vector3(velocity.x, 0.0, velocity.z) * delta
	var horiz_len := horiz_motion.length()
	var contact_len := maxf(params.step_sensor_distance, 0.05)
	var contact_motion := step_dir.normalized() * contact_len
	_debug_step_contact_pos = global_transform.origin + contact_motion + Vector3.UP * 0.05
	_debug_step_contact_valid = true
	_debug_step_contact_ok = test_move(global_transform, contact_motion)
	if not _debug_step_contact_ok and _has_blocking_contact(step_dir):
		_debug_step_contact_ok = true
	var step_nudge := minf(params.step_sensor_distance, 0.08)
	var step_motion := step_dir.normalized() * step_nudge
	if _try_step_up(step_motion, step_height):
		_step_visual_offset -= step_height
		_step_carry_pending = true
		_step_carry_velocity = Vector3(velocity.x, 0.0, velocity.z)
	_update_step_debug(_step_sensor_shape.shape as BoxShape3D, _step_floor_cast.shape as BoxShape3D)


func _detect_step_ahead(params: MovementData3D, move_dir: Vector3) -> Dictionary:
	_ensure_step_sensors(params, move_dir)
	var forward := move_dir
	forward.y = 0.0
	if forward.length() <= 0.001:
		return {}
	forward = forward.normalized()
	_debug_step_hit_valid = false
	_debug_step_has_overlap = false
	_debug_step_cast_hit = false
	var overlaps: Array = _step_sensor.get_overlapping_bodies()
	var has_candidate := false
	for body in overlaps:
		if body == self:
			continue
		has_candidate = true
		break
	_debug_step_has_overlap = has_candidate
	_step_floor_cast.force_shapecast_update()
	_debug_step_cast_hit = _step_floor_cast.is_colliding()
	if not _debug_step_cast_hit:
		return {}
	var best_height: float = 0.0
	var found := false
	var best_hit := Vector3.ZERO
	var count := _step_floor_cast.get_collision_count()
	for i in range(count):
		var collider: Object = _step_floor_cast.get_collider(i)
		if collider == null or collider == self:
			continue
		var hit_pos: Vector3 = _step_floor_cast.get_collision_point(i)
		var step_delta: float = hit_pos.y - global_transform.origin.y
		if step_delta <= 0.02 or step_delta > params.step_height:
			continue
		var hit_normal: Vector3 = _step_floor_cast.get_collision_normal(i)
		var angle: float = rad_to_deg(Vector3.UP.angle_to(hit_normal))
		if params.step_snap_max_angle > 0.0 and angle > params.step_snap_max_angle:
			continue
		if step_delta > best_height:
			best_height = step_delta
			best_hit = hit_pos
			found = true
	if not found:
		return {}
	_debug_step_hit = best_hit
	_debug_step_hit_valid = true
	return {"height": best_height}


func _ensure_step_sensors(params: MovementData3D, move_dir: Vector3) -> void:
	if _step_sensor == null or not is_instance_valid(_step_sensor):
		_step_sensor = Area3D.new()
		_step_sensor.name = "StepSensor"
		_step_sensor.monitoring = true
		_step_sensor.monitorable = false
		_step_sensor.collision_layer = 0
		_step_sensor.collision_mask = collision_mask
		add_child(_step_sensor)
		_step_sensor_shape = CollisionShape3D.new()
		_step_sensor.add_child(_step_sensor_shape)
		_step_sensor_shape.shape = BoxShape3D.new()
	if _step_floor_cast == null or not is_instance_valid(_step_floor_cast):
		_step_floor_cast = ShapeCast3D.new()
		_step_floor_cast.name = "StepFloorCast"
		_step_floor_cast.enabled = true
		_step_floor_cast.collision_mask = collision_mask
		_step_floor_cast.exclude_parent = true
		var cast_shape := BoxShape3D.new()
		cast_shape.size = Vector3.ONE * 0.1
		_step_floor_cast.shape = cast_shape
		add_child(_step_floor_cast)
	var sensor_shape: BoxShape3D = _step_sensor_shape.shape as BoxShape3D
	if sensor_shape:
		var extents := _get_collision_extents()
		var depth := maxf(params.step_sensor_distance, 0.05)
		var height := maxf(params.step_height, 0.05)
		var width := maxf(extents.x * 2.0, 0.1)
		sensor_shape.size = Vector3(width, height, depth)
	var cast_shape: BoxShape3D = _step_floor_cast.shape as BoxShape3D
	if cast_shape and sensor_shape:
		cast_shape.size = Vector3(sensor_shape.size.x, 0.05, sensor_shape.size.z)
	var forward := move_dir
	forward.y = 0.0
	if forward.length() <= 0.001:
		forward = -global_transform.basis.z
		forward.y = 0.0
	forward = forward.normalized()
	var forward_extent := _get_collision_forward_extent()
	var sensor_depth := maxf(params.step_sensor_distance, 0.05)
	if sensor_shape:
		sensor_depth = sensor_shape.size.z
	var offset_distance := forward_extent + sensor_depth * 0.5
	var sensor_y := maxf(params.step_height * 0.5, 0.02)
	var sensor_pos := global_transform.origin + forward * offset_distance
	sensor_pos.y += sensor_y
	_step_sensor.global_position = sensor_pos
	_step_sensor.look_at(sensor_pos + forward, Vector3.UP)
	var cast_height := maxf(params.step_height, 0.05)
	_step_floor_cast.global_position = sensor_pos + Vector3.UP * cast_height
	_step_floor_cast.global_basis = _step_sensor.global_basis
	_step_floor_cast.target_position = Vector3.DOWN * (cast_height + 0.1)
	_update_step_debug(sensor_shape, cast_shape)


func _update_step_debug(sensor_shape: BoxShape3D, cast_shape: BoxShape3D) -> void:
	if not debug_step_sensors:
		_set_step_debug_visible(false)
		return
	if _step_sensor == null or _step_floor_cast == null:
		_set_step_debug_visible(false)
		return
	_ensure_step_debug_nodes()
	_set_step_debug_visible(true)
	if _debug_step_sensor_mesh and sensor_shape:
		var sensor_mesh: BoxMesh = _debug_step_sensor_mesh.mesh as BoxMesh
		if sensor_mesh:
			sensor_mesh.size = sensor_shape.size
		var sensor_mat := _debug_step_sensor_mesh.material_override as StandardMaterial3D
		if sensor_mat:
			sensor_mat.albedo_color = Color(0.2, 1.0, 0.7, 0.25) if _debug_step_has_overlap else Color(0.2, 0.6, 0.6, 0.15)
		_debug_step_sensor_mesh.global_transform = _step_sensor.global_transform
	if _debug_step_cast_mesh and cast_shape:
		var cast_mesh: BoxMesh = _debug_step_cast_mesh.mesh as BoxMesh
		if cast_mesh:
			cast_mesh.size = cast_shape.size
		var cast_mat := _debug_step_cast_mesh.material_override as StandardMaterial3D
		if cast_mat:
			cast_mat.albedo_color = Color(0.7, 0.3, 1.0, 0.25) if _debug_step_cast_hit else Color(0.4, 0.3, 0.6, 0.15)
		_debug_step_cast_mesh.global_transform = _step_floor_cast.global_transform
	if _debug_step_hit_mesh:
		_debug_step_hit_mesh.visible = _debug_step_hit_valid
		if _debug_step_hit_valid:
			_debug_step_hit_mesh.global_position = _debug_step_hit
	_update_step_marker(_debug_step_contact_mesh, _debug_step_contact_valid, _debug_step_contact_pos, _debug_step_contact_ok)
	_update_step_marker(_debug_step_up_mesh, _debug_step_up_valid, _debug_step_up_pos, _debug_step_up_clear)
	_update_step_marker(_debug_step_forward_mesh, _debug_step_forward_valid, _debug_step_forward_pos, _debug_step_forward_clear)


func _ensure_step_debug_nodes() -> void:
	if _debug_step_root == null or not is_instance_valid(_debug_step_root):
		_debug_step_root = Node3D.new()
		_debug_step_root.name = "StepDebug"
		add_child(_debug_step_root)
	if _debug_step_sensor_mesh == null or not is_instance_valid(_debug_step_sensor_mesh):
		_debug_step_sensor_mesh = MeshInstance3D.new()
		_debug_step_sensor_mesh.name = "StepSensorDebug"
		var sensor_mesh := BoxMesh.new()
		_debug_step_sensor_mesh.mesh = sensor_mesh
		_debug_step_sensor_mesh.material_override = _make_debug_material(Color(0.2, 0.8, 1.0, 0.25))
		_debug_step_root.add_child(_debug_step_sensor_mesh)
	if _debug_step_cast_mesh == null or not is_instance_valid(_debug_step_cast_mesh):
		_debug_step_cast_mesh = MeshInstance3D.new()
		_debug_step_cast_mesh.name = "StepCastDebug"
		var cast_mesh := BoxMesh.new()
		_debug_step_cast_mesh.mesh = cast_mesh
		_debug_step_cast_mesh.material_override = _make_debug_material(Color(0.6, 0.3, 1.0, 0.25))
		_debug_step_root.add_child(_debug_step_cast_mesh)
	if _debug_step_hit_mesh == null or not is_instance_valid(_debug_step_hit_mesh):
		_debug_step_hit_mesh = MeshInstance3D.new()
		_debug_step_hit_mesh.name = "StepHitDebug"
		var hit_mesh := SphereMesh.new()
		hit_mesh.radius = 0.05
		hit_mesh.height = 0.1
		_debug_step_hit_mesh.mesh = hit_mesh
		_debug_step_hit_mesh.material_override = _make_debug_material(Color(1.0, 0.9, 0.2, 0.6))
		_debug_step_root.add_child(_debug_step_hit_mesh)
	if _debug_step_contact_mesh == null or not is_instance_valid(_debug_step_contact_mesh):
		_debug_step_contact_mesh = MeshInstance3D.new()
		_debug_step_contact_mesh.name = "StepContactDebug"
		var contact_mesh := SphereMesh.new()
		contact_mesh.radius = 0.045
		contact_mesh.height = 0.09
		_debug_step_contact_mesh.mesh = contact_mesh
		_debug_step_contact_mesh.material_override = _make_debug_material(Color(0.2, 1.0, 0.2, 0.6))
		_debug_step_root.add_child(_debug_step_contact_mesh)
	if _debug_step_up_mesh == null or not is_instance_valid(_debug_step_up_mesh):
		_debug_step_up_mesh = MeshInstance3D.new()
		_debug_step_up_mesh.name = "StepUpDebug"
		var up_mesh := SphereMesh.new()
		up_mesh.radius = 0.045
		up_mesh.height = 0.09
		_debug_step_up_mesh.mesh = up_mesh
		_debug_step_up_mesh.material_override = _make_debug_material(Color(0.2, 1.0, 0.2, 0.6))
		_debug_step_root.add_child(_debug_step_up_mesh)
	if _debug_step_forward_mesh == null or not is_instance_valid(_debug_step_forward_mesh):
		_debug_step_forward_mesh = MeshInstance3D.new()
		_debug_step_forward_mesh.name = "StepForwardDebug"
		var forward_mesh := SphereMesh.new()
		forward_mesh.radius = 0.045
		forward_mesh.height = 0.09
		_debug_step_forward_mesh.mesh = forward_mesh
		_debug_step_forward_mesh.material_override = _make_debug_material(Color(0.2, 1.0, 0.2, 0.6))
		_debug_step_root.add_child(_debug_step_forward_mesh)


func _set_step_debug_visible(visible: bool) -> void:
	if _debug_step_root and is_instance_valid(_debug_step_root):
		_debug_step_root.visible = visible


func _update_step_marker(mesh: MeshInstance3D, valid: bool, pos: Vector3, ok: bool) -> void:
	if mesh == null:
		return
	mesh.visible = valid
	if not valid:
		return
	mesh.global_position = pos
	var mat := mesh.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(0.2, 1.0, 0.2, 0.6) if ok else Color(1.0, 0.2, 0.2, 0.6)


func _make_debug_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	return mat


func _get_floor_collider() -> Object:
	var count: int = get_slide_collision_count()
	if count <= 0:
		return null
	var best_dot: float = 0.0
	var best: Object = null
	for i in range(count):
		var collision: KinematicCollision3D = get_slide_collision(i)
		if collision == null:
			continue
		var normal: Vector3 = collision.get_normal()
		var dot: float = normal.dot(Vector3.UP)
		if dot < 0.6:
			continue
		if dot > best_dot:
			best_dot = dot
			best = collision.get_collider()
	return best


func _has_blocking_contact(dir: Vector3) -> bool:
	var move_dir := dir
	move_dir.y = 0.0
	if move_dir.length() <= 0.001:
		return false
	move_dir = move_dir.normalized()
	var count: int = get_slide_collision_count()
	if count <= 0:
		return false
	for i in range(count):
		var collision: KinematicCollision3D = get_slide_collision(i)
		if collision == null:
			continue
		var normal: Vector3 = collision.get_normal()
		if normal.dot(Vector3.UP) > 0.6:
			continue
		return true
	return false


func _get_blocking_normal() -> Vector3:
	var count: int = get_slide_collision_count()
	if count <= 0:
		return Vector3.ZERO
	var best: Vector3 = Vector3.ZERO
	var best_score := -1.0
	for i in range(count):
		var collision: KinematicCollision3D = get_slide_collision(i)
		if collision == null:
			continue
		var normal: Vector3 = collision.get_normal()
		if normal.dot(Vector3.UP) > 0.6:
			continue
		var horiz := normal
		horiz.y = 0.0
		var score := horiz.length()
		if score > best_score:
			best_score = score
			best = normal
	return best


func _get_collision_shape_node() -> CollisionShape3D:
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		return null
	if collision.shape:
		var shape: Shape3D = collision.shape
		if not shape.resource_local_to_scene:
			var dup: Shape3D = shape.duplicate()
			dup.resource_local_to_scene = true
			collision.shape = dup
	return collision


func _get_collision_forward_extent() -> float:
	var collision: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		return 0.0
	var shape: Shape3D = collision.shape
	if shape == null:
		return 0.0
	var scale: Vector3 = collision.global_transform.basis.get_scale()
	if shape is BoxShape3D:
		var box: BoxShape3D = shape
		return box.size.z * 0.5 * scale.z
	if shape is CapsuleShape3D:
		var capsule: CapsuleShape3D = shape
		var radius: float = capsule.radius * maxf(scale.x, scale.z)
		return radius
	if shape is CylinderShape3D:
		var cylinder: CylinderShape3D = shape
		var radius2: float = cylinder.radius * maxf(scale.x, scale.z)
		return radius2
	if shape is SphereShape3D:
		var sphere: SphereShape3D = shape
		var radius3: float = sphere.radius * maxf(scale.x, scale.z)
		return radius3
	return 0.0


func _get_collision_extents() -> Vector3:
	var collision: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		return Vector3.ZERO
	var shape: Shape3D = collision.shape
	if shape == null:
		return Vector3.ZERO
	var scale: Vector3 = collision.global_transform.basis.get_scale()
	if shape is BoxShape3D:
		var box: BoxShape3D = shape
		return Vector3(box.size.x * 0.5 * scale.x, box.size.y * 0.5 * scale.y, box.size.z * 0.5 * scale.z)
	if shape is CapsuleShape3D:
		var capsule: CapsuleShape3D = shape
		var radius: float = capsule.radius * maxf(scale.x, scale.z)
		var half_height: float = (capsule.height * 0.5 + capsule.radius) * scale.y
		return Vector3(radius, half_height, radius)
	if shape is CylinderShape3D:
		var cylinder: CylinderShape3D = shape
		var radius2: float = cylinder.radius * maxf(scale.x, scale.z)
		var half_height2: float = cylinder.height * 0.5 * scale.y
		return Vector3(radius2, half_height2, radius2)
	if shape is SphereShape3D:
		var sphere: SphereShape3D = shape
		var max_scale: float = maxf(maxf(scale.x, scale.y), scale.z)
		var rad: float = sphere.radius * max_scale
		return Vector3(rad, rad, rad)
	return Vector3.ZERO


func _update_step_visual(params: MovementData3D, delta: float) -> void:
	var speed := params.step_snap_smooth_speed
	if speed <= 0.0:
		_step_visual_offset = 0.0
	else:
		_step_visual_offset = move_toward(_step_visual_offset, 0.0, speed * delta)
	_apply_visual_offset()
	if debug_step_sensors:
		var sensor_shape: BoxShape3D = null
		var cast_shape: BoxShape3D = null
		if _step_sensor_shape:
			sensor_shape = _step_sensor_shape.shape as BoxShape3D
		if _step_floor_cast:
			cast_shape = _step_floor_cast.shape as BoxShape3D
		_update_step_debug(sensor_shape, cast_shape)


func _apply_jump_logic(params: MovementData3D, on_floor: bool) -> void:
	if can_move != 1 or not _input_allowed():
		return
	if jump_buffer_timer <= 0.0:
		return
	if on_floor or coyote_timer > 0.0:
		_start_jump(params.jump_speed)
		return
	if params.wall_jump_enabled and can_wall_jump and wall_side != 0:
		_start_wall_jump(params)
		return
	if can_double_jump and jump_count < params.max_jumps and (not params.require_jump_release or jump_released):
		var speed := params.double_jump_speed
		if speed <= 0.0:
			speed = params.jump_speed
		if params.double_jump_clamp_fall_speed > 0.0 and velocity.y < -params.double_jump_clamp_fall_speed:
			velocity.y = -params.double_jump_clamp_fall_speed
		_start_jump(speed)
		can_double_jump = false


func _start_jump(speed: float) -> void:
	velocity.y = speed
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	jump_released = false
	jump_count += 1
	jumping = true
	in_air = true
	jumped.emit()


func _start_wall_jump(params: MovementData3D) -> void:
	var push := _get_right_direction() * float(-wall_side)
	velocity.x = push.x * params.wall_jump_push_speed
	velocity.z = push.z * params.wall_jump_push_speed
	velocity.y = params.wall_jump_up_speed
	wall_jumping = true
	can_wall_jump = false
	wall_side = 0
	wall_jump_lock = params.wall_jump_lock_time
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	jump_released = false
	jump_count = 1
	jumping = true
	in_air = true
	jumped.emit()


func _apply_gravity(params: MovementData3D, on_floor: bool, delta: float) -> void:
	if on_floor:
		if velocity.y < 0.0:
			velocity.y = 0.0
		return
	var gravity_scale := 1.0
	if can_wall_jump and falling and params.wall_slide_gravity_scale > 0.0:
		gravity_scale = params.wall_slide_gravity_scale
	velocity.y -= params.gravity * gravity_scale * delta
	if can_wall_jump and params.wall_slide_max_fall_speed > 0.0:
		if velocity.y < -params.wall_slide_max_fall_speed:
			velocity.y = -params.wall_slide_max_fall_speed
	if velocity.y < -params.max_fall_speed:
		velocity.y = -params.max_fall_speed


func _raycast_wall(origin: Vector3, direction: Vector3, distance: float) -> bool:
	if distance <= 0.0:
		return false
	var dir := direction
	dir.y = 0.0
	if dir.length() <= 0.001:
		return false
	dir = dir.normalized()
	var world := get_world_3d()
	if world == null:
		return false
	var space := world.direct_space_state
	if space == null:
		return false
	var params := PhysicsRayQueryParameters3D.create(origin, origin + dir * distance)
	params.collision_mask = collision_mask
	params.exclude = [self]
	var hit: Dictionary = space.intersect_ray(params)
	return not hit.is_empty()


func _get_forward_direction() -> Vector3:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length() > 0.001:
		forward = forward.normalized()
	return forward


func _get_right_direction() -> Vector3:
	var right := global_transform.basis.x
	right.y = 0.0
	if right.length() > 0.001:
		right = right.normalized()
	return right


func _move_vector_to_dir(move: Vector2) -> Vector3:
	return _get_move_direction(move)


func _update_landing_state() -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		landed.emit()
	_was_on_floor = on_floor


func _update_move_dir(desired: Vector3) -> void:
	var dir := Vector3(desired.x, 0.0, desired.z)
	if dir.length() > 0.01:
		dir = dir.normalized()
		if dir != _last_move_dir:
			_last_move_dir = dir
			direction_changed.emit(dir)


func _get_move_direction(move: Vector2) -> Vector3:
	match camera_context:
		CameraContext.SIMPLE_THIRD_PERSON:
			return _get_simple_third_person_direction(move)
	return _get_world_direction(move)


func _get_simple_third_person_direction(move: Vector2) -> Vector3:
	if move.length() <= 0.001:
		return Vector3.ZERO
	var input_vec := Vector2(move.x, -move.y)
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length() > 0.001:
		forward = forward.normalized()
	return forward * input_vec.y


func _get_world_direction(move: Vector2) -> Vector3:
	if move.length() <= 0.001:
		return Vector3.ZERO
	var input_vec := Vector2(move.x, -move.y)
	var forward := Vector3.FORWARD
	var right := Vector3.RIGHT
	var dir := right * input_vec.x + forward * input_vec.y
	if dir.length() > 1.0:
		dir = dir.normalized()
	return dir


func _apply_turning(move: Vector2, move_dir: Vector3, params: MovementData3D, delta: float) -> void:
	match camera_context:
		CameraContext.SIMPLE_THIRD_PERSON:
			_apply_simple_third_person_turn(move, move_dir, params, delta)


func _apply_simple_third_person_turn(move: Vector2, move_dir: Vector3, params: MovementData3D, delta: float) -> void:
	var dir := -1.0 if params.turn_invert else 1.0
	var desired_turn := move.x * params.turn_rate * dir
	var t := 1.0 - exp(-params.turn_smooth * delta)
	_turn_velocity = lerp(_turn_velocity, desired_turn, t)
	rotation.y += _turn_velocity * delta


func _try_step_up(motion: Vector3, step_height: float) -> bool:
	if step_height <= 0.0:
		return false
	var horiz := Vector3(motion.x, 0.0, motion.z)
	if horiz.length() <= 0.001:
		return false
	_debug_step_up_pos = global_transform.origin + Vector3.UP * step_height
	_debug_step_up_valid = true
	_debug_step_forward_pos = _debug_step_up_pos + horiz
	_debug_step_forward_valid = true
	var from := global_transform
	var prev_margin := safe_margin
	safe_margin = 0.01
	if not test_move(from, horiz) and not _has_blocking_contact(horiz):
		safe_margin = prev_margin
		_debug_step_contact_ok = false
		return false
	var up := Vector3.UP * step_height
	var blocked_up := test_move(from, up)
	_debug_step_up_clear = not blocked_up
	if blocked_up:
		safe_margin = prev_margin
		return false
	var lifted := from
	lifted.origin += up
	var blocked_forward := test_move(lifted, horiz)
	_debug_step_forward_clear = not blocked_forward
	if blocked_forward:
		safe_margin = prev_margin
		return false
	global_transform = lifted
	safe_margin = prev_margin
	return true


func _rotate_towards(dir: Vector3, turn_rate: float, delta: float) -> void:
	var target_yaw := atan2(dir.x, dir.z)
	var current_yaw := rotation.y
	var t := 1.0 - exp(-turn_rate * delta)
	rotation.y = lerp_angle(current_yaw, target_yaw, t)


func _apply_camera_override() -> void:
	if camera_data == null:
		return
	var cam := _find_orbit_camera()
	if cam and cam.has_method("apply_camera_data"):
		cam.call("apply_camera_data", camera_data)


func _find_orbit_camera() -> Node:
	for child in get_children():
		if child is OrbitCamera3D:
			return child
	return null


func _find_anim_driver() -> AnimDriver3D:
	var driver := find_child("AnimDriver3D", true, false)
	if driver is AnimDriver3D:
		return driver
	return null


func set_aim_direction(dir: Vector3) -> void:
	if dir.length() <= 0.001:
		return
	aim_direction = dir.normalized()


func get_aim_direction() -> Vector3:
	return aim_direction


func _get_input_source() -> IInputSource:
	if _input_source == null:
		_input_source = NullInputSource.new()
	return _input_source


func _get_movement_params() -> MovementData3D:
	if _movement_data:
		return _movement_data
	return _default_movement


func _ensure_movement_resource() -> MovementData3D:
	if _movement_data == null:
		_movement_data = MovementData3D.new()
	return _movement_data


func _set_movement_value(key: String, value) -> void:
	var data: MovementData3D = _ensure_movement_resource()
	data.set(key, value)
	if _controller_ctx:
		_controller_ctx.movement = data


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_sync_movement_proxy_from_resource()


func _sync_movement_proxy_from_resource() -> void:
	var data := _get_movement_params()
	_syncing_movement_proxy = true
	_movement_gravity = data.gravity
	_movement_walk_speed = data.walk_speed
	_movement_run_speed = data.run_speed
	_movement_acceleration = data.acceleration
	_movement_deceleration = data.deceleration
	_movement_turn_rate = data.turn_rate
	_movement_turn_smooth = data.turn_smooth
	_movement_turn_invert = data.turn_invert
	_movement_max_slope_angle = data.max_slope_angle
	_movement_step_height = data.step_height
	_movement_step_snap_max_angle = data.step_snap_max_angle
	_movement_step_sensor_distance = data.step_sensor_distance
	_movement_step_snap_smooth_speed = data.step_snap_smooth_speed
	_movement_air_control = data.air_control
	_movement_air_accel = data.air_accel
	_movement_air_decel = data.air_decel
	_movement_max_fall_speed = data.max_fall_speed
	_movement_jump_speed = data.jump_speed
	_movement_double_jump_speed = data.double_jump_speed
	_movement_max_jumps = data.max_jumps
	_movement_coyote_time = data.coyote_time
	_movement_jump_buffer_time = data.jump_buffer_time
	_movement_require_jump_release = data.require_jump_release
	_movement_double_jump_clamp_fall_speed = data.double_jump_clamp_fall_speed
	_movement_jump_cut = data.jump_cut
	_movement_wall_jump_enabled = data.wall_jump_enabled
	_movement_wall_check_distance = data.wall_check_distance
	_movement_wall_check_height = data.wall_check_height
	_movement_wall_slide_gravity_scale = data.wall_slide_gravity_scale
	_movement_wall_slide_max_fall_speed = data.wall_slide_max_fall_speed
	_movement_wall_jump_up_speed = data.wall_jump_up_speed
	_movement_wall_jump_push_speed = data.wall_jump_push_speed
	_movement_wall_jump_lock_time = data.wall_jump_lock_time
	_movement_dash_speed = data.dash_speed
	_movement_dash_time = data.dash_time
	_movement_dash_cooldown = data.dash_cooldown
	_movement_dash_allow_air = data.dash_allow_air
	_movement_dash_allow_double_tap = data.dash_allow_double_tap
	_movement_dash_double_tap_window = data.dash_double_tap_window
	_movement_roll_speed = data.roll_speed
	_movement_roll_time = data.roll_time
	_movement_roll_cooldown = data.roll_cooldown
	_movement_crouch_height = data.crouch_height
	_movement_crouch_speed = data.crouch_speed
	_movement_sneak_speed = data.sneak_speed
	_movement_drop_through_time = data.drop_through_time
	_movement_drop_through_layer = data.drop_through_layer
	_movement_drop_through_speed = data.drop_through_speed
	_movement_high_fall_speed = data.high_fall_speed
	_movement_high_fall_time = data.high_fall_time
	_syncing_movement_proxy = false
	if Engine.is_editor_hint():
		notify_property_list_changed()


func _refresh_editor_model() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	if not preview_model_in_editor:
		_set_model_visible(false)
		return
	var data := _get_model_data_for_apply()
	if data:
		_apply_model_resource(data)
		_set_model_visible(true)
	else:
		_set_debug_mesh_visible(true)


func _get_model_data_for_apply() -> ModelData3D:
	if model_data:
		return model_data
	if model_id == "":
		return null
	var reg: Node = _registry()
	if reg and reg.has_method("get_resource_for_category"):
		var res = reg.get_resource_for_category("Model3D", model_id)
		if res is ModelData3D:
			return res
	return null


func _set_model_visible(visible: bool) -> void:
	var model_root := _ensure_model_root()
	if model_root == null:
		return
	for child in model_root.get_children():
		_set_node_visibility(child, visible)


func _set_node_visibility(node: Node, visible: bool) -> void:
	if node is VisualInstance3D:
		(node as VisualInstance3D).visible = visible
	for child in node.get_children():
		_set_node_visibility(child, visible)


func _mark_preview_instance(node: Node) -> void:
	if node == null:
		return
	node.set_meta("_editor_preview", true)
	node.owner = self
	for child in node.get_children():
		_mark_preview_instance(child)


func _cleanup_preview_instances() -> void:
	if not Engine.is_editor_hint():
		return
	var model_root := _ensure_model_root()
	if model_root == null:
		return
	for child in model_root.get_children():
		if child is AnimationPlayer:
			continue
		var is_preview := child.has_meta("_editor_preview") or child.owner == self
		if is_preview:
			child.free()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		_cleanup_preview_instances()
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		if preview_model_in_editor:
			call_deferred("_refresh_editor_model")


func get_input_source() -> IInputSource:
	return _get_input_source()


func get_movement_params() -> MovementData3D:
	return _get_movement_params()


func get_orbit_camera() -> OrbitCamera3D:
	var cam := _find_orbit_camera()
	if cam is OrbitCamera3D:
		return cam
	return null


func get_anim_driver() -> AnimDriver3D:
	if _anim_driver == null:
		_anim_driver = _find_anim_driver()
	return _anim_driver


func get_controller_context() -> ControllerContext3D:
	return _controller_ctx


func resolve_anim_state(intent: String) -> String:
	if model_data and model_data.has_method("resolve_state"):
		return model_data.resolve_state(intent)
	return intent


func apply_basic_movement(delta: float) -> void:
	_apply_basic_movement(delta)


func _apply_data_ids() -> void:
	if movement_id != "":
		apply_movement_data(movement_id)
	if camera_id != "":
		apply_camera_data(camera_id)
	if model_id != "":
		apply_model_data(model_id)


func _registry():
	if Engine.has_singleton("DataRegistry"):
		return Engine.get_singleton("DataRegistry")
	if has_node("/root/DataRegistry"):
		return get_node("/root/DataRegistry")
	return null


func _apply_model_resource(data: ModelData3D) -> void:
	if data == null:
		_set_debug_mesh_visible(true)
		return
	_model_applied = true
	var model_root := _ensure_model_root()
	if model_root == null:
		return
	for child in model_root.get_children():
		if child is AnimationPlayer:
			continue
		if Engine.is_editor_hint():
			child.free()
		else:
			child.queue_free()
	model_root.scale = data.scale
	var instanced := false
	var inst_root: Node = null
	if data.scene:
		var inst := data.scene.instantiate()
		if inst:
			inst_root = inst
			model_root.add_child(inst)
			instanced = _has_geometry(inst)
	elif data.mesh:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = data.mesh
		if data.material_override:
			mesh_instance.material_override = data.material_override
		model_root.add_child(mesh_instance)
		instanced = true
	_set_debug_mesh_visible(not instanced)
	_apply_pivot_defaults()
	if inst_root:
		if Engine.is_editor_hint() and preview_model_in_editor and get_tree() and get_tree().edited_scene_root == self:
			_mark_preview_instance(inst_root)
		_prune_model_animation_players(inst_root)
		_bind_mesh_skeletons(inst_root)
		var external_anim := model_root.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if external_anim:
			_bind_animation_library_to_player(data, external_anim, inst_root)
		else:
			_bind_animation_library(data, inst_root)
		if data.force_double_sided:
			_force_double_sided(inst_root)
	_refresh_anim_driver()
	if _anim_driver:
		_anim_driver.animation_tree_path = data.animation_tree_path
		_anim_driver.animation_player_path = data.animation_player_path
		_anim_driver.animation_library_name = data.animation_library_name
		_sync_anim_driver_paths(model_root)
		_anim_driver.refresh_targets()
		if "debug_enabled" in _anim_driver and _anim_driver.debug_enabled:
			_anim_driver.debug_dump("model applied")
			_debug_dump_model_binding(inst_root)


func _ensure_visual_root() -> Node3D:
	var root := get_node_or_null("VisualRoot")
	if root == null:
		root = Node3D.new()
		root.name = "VisualRoot"
		add_child(root)
	return root


func _ensure_model_root() -> Node3D:
	var visual_root := _ensure_visual_root()
	if visual_root == null:
		return null
	var model_root := visual_root.get_node_or_null("ModelRoot")
	if model_root == null:
		model_root = Node3D.new()
		model_root.name = "ModelRoot"
		visual_root.add_child(model_root)
	return model_root


func _refresh_anim_driver() -> void:
	_anim_driver = _find_anim_driver()
	if _anim_driver and _anim_driver.has_method("refresh_targets"):
		_anim_driver.refresh_targets()
	if _controller_ctx:
		_controller_ctx.anim = _anim_driver


func _sync_anim_driver_paths(model_root: Node) -> void:
	if _anim_driver == null or model_root == null:
		return
	if _anim_driver.target_root_path == NodePath(""):
		_anim_driver.target_root_path = NodePath("VisualRoot/ModelRoot")
	if _anim_driver.animation_player_path == NodePath(""):
		var anim_player := model_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim_player:
			_anim_driver.animation_player_path = model_root.get_path_to(anim_player)
	if _anim_driver.animation_tree_path == NodePath(""):
		var anim_tree := model_root.find_child("AnimationTree", true, false) as AnimationTree
		if anim_tree:
			_anim_driver.animation_tree_path = model_root.get_path_to(anim_tree)


func _bind_animation_library(data: ModelData3D, root: Node) -> void:
	if data == null or data.animation_library == null or root == null:
		return
	var anim_player: AnimationPlayer = null
	if data.animation_player_path != NodePath(""):
		anim_player = root.get_node_or_null(data.animation_player_path) as AnimationPlayer
	if anim_player == null:
		anim_player = root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player == null:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		root.add_child(anim_player)
	var lib_name := data.animation_library_name
	if lib_name == StringName():
		lib_name = &"biped"
	if anim_player.has_method("has_animation_library") and anim_player.has_animation_library(lib_name):
		anim_player.remove_animation_library(lib_name)
	var lib := data.animation_library
	lib = _maybe_remap_library_for_root(lib, root)
	anim_player.add_animation_library(lib_name, lib)
	_configure_animation_player(anim_player)


func _bind_animation_library_to_player(data: ModelData3D, anim_player: AnimationPlayer, root: Node) -> void:
	if data == null or data.animation_library == null or anim_player == null:
		return
	var lib_name := data.animation_library_name
	if lib_name == StringName():
		lib_name = &"biped"
	if anim_player.has_method("has_animation_library") and anim_player.has_animation_library(lib_name):
		anim_player.remove_animation_library(lib_name)
	var lib := data.animation_library
	if root:
		lib = _maybe_remap_library_for_root(lib, root)
	anim_player.add_animation_library(lib_name, lib)
	if root:
		var root_path := anim_player.get_path_to(root)
		if root_path != NodePath(""):
			anim_player.root_node = root_path
	_configure_animation_player(anim_player)


func _configure_animation_player(anim_player: AnimationPlayer) -> void:
	if anim_player == null:
		return
	if "playback_process_mode" in anim_player:
		anim_player.playback_process_mode = AnimationPlayer.ANIMATION_PROCESS_IDLE
	if "playback_active" in anim_player:
		anim_player.playback_active = true
	anim_player.active = true
	var current_root := anim_player.root_node
	var has_valid_root := current_root != NodePath("")
	if has_valid_root and anim_player.get_node_or_null(current_root) == null:
		has_valid_root = false
	if not has_valid_root:
		var root_path := _find_anim_root_path(anim_player)
		if root_path != NodePath(""):
			anim_player.root_node = root_path


func _bind_mesh_skeletons(root: Node) -> void:
	if root == null:
		return
	var skeleton := _find_primary_skeleton(root)
	if skeleton == null:
		return
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	for mesh in meshes:
		var mi := mesh as MeshInstance3D
		if mi == null:
			continue
		var path := mi.get_path_to(skeleton)
		if mi.skeleton != path:
			mi.skeleton = path
		if mi.skin == null:
			var skin := _get_skeleton_skin(skeleton)
			if skin:
				mi.skin = skin


func _prune_model_animation_players(root: Node) -> void:
	if root == null:
		return
	var players := root.find_children("*", "AnimationPlayer", true, false)
	for child in players:
		var anim := child as AnimationPlayer
		if anim == null:
			continue
		if Engine.is_editor_hint():
			anim.free()
		else:
			anim.queue_free()


func _find_primary_skeleton(root: Node) -> Skeleton3D:
	var skeletons := root.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return null
	var best: Skeleton3D = null
	var best_bones := -1
	for skel in skeletons:
		var s := skel as Skeleton3D
		if s == null:
			continue
		var count := s.get_bone_count()
		if count > best_bones:
			best_bones = count
			best = s
	return best


func _get_skeleton_skin(skeleton: Skeleton3D) -> Skin:
	if skeleton == null:
		return null
	if skeleton.has_method("get_skin"):
		var existing = skeleton.call("get_skin")
		if existing is Skin:
			return existing
	if skeleton.has_method("create_skin_from_rest"):
		var created = skeleton.call("create_skin_from_rest")
		if created is Skin:
			if skeleton.has_method("set_skin"):
				skeleton.call("set_skin", created)
			return created
	return null


func _debug_dump_model_binding(root: Node) -> void:
	if root == null:
		return
	var verbose := false
	if _anim_driver and "debug_verbose" in _anim_driver:
		verbose = _anim_driver.debug_verbose
	print("Model binding debug")
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	print("- mesh_count:", meshes.size())
	var max_items: int = meshes.size()
	if not verbose and max_items > 5:
		max_items = 5
	for i in range(max_items):
		var mi := meshes[i] as MeshInstance3D
		if mi == null:
			continue
		var skel_path := mi.skeleton
		var skel_ok := false
		if skel_path != NodePath(""):
			var skel_node := mi.get_node_or_null(skel_path)
			skel_ok = skel_node is Skeleton3D
		var has_skin := mi.skin != null
		var surf_count := 0
		if mi.mesh:
			surf_count = mi.mesh.get_surface_count()
		print("- mesh:", mi.get_path(), "skeleton:", String(skel_path), "skeleton_ok:", skel_ok, "skin:", has_skin, "surfaces:", surf_count)


func _find_anim_root_path(anim_player: AnimationPlayer) -> NodePath:
	if anim_player == null:
		return NodePath("")
	var current: Node = anim_player
	while current:
		if current.get_node_or_null("Armature/Skeleton3D"):
			return anim_player.get_path_to(current)
		var skel := current.find_child("Skeleton3D", true, false)
		if skel:
			return anim_player.get_path_to(current)
		current = current.get_parent()
	return NodePath("")


func _requires_library_remap(root: Node) -> bool:
	if root == null:
		return false
	if root.get_node_or_null("Armature/Skeleton3D"):
		return false
	var skel := root.find_child("Skeleton3D", true, false)
	return skel != null


func _library_uses_armature_paths(lib: AnimationLibrary) -> bool:
	if lib == null:
		return false
	var names := lib.get_animation_list()
	var max_anims: int = min(names.size(), 5)
	for i in range(max_anims):
		var anim := lib.get_animation(names[i])
		if anim == null:
			continue
		var track_count := anim.get_track_count()
		var max_tracks: int = min(track_count, 20)
		var saw_armature := false
		var saw_skeleton := false
		for t in range(max_tracks):
			var path := String(anim.track_get_path(t))
			if path.begins_with("Armature/"):
				saw_armature = true
			elif path.begins_with("Skeleton3D"):
				saw_skeleton = true
			if saw_armature and saw_skeleton:
				break
		if saw_armature:
			return true
		if saw_skeleton:
			return false
	return false


func _get_library_track_prefix(lib: AnimationLibrary) -> String:
	if lib == null:
		return ""
	var names := lib.get_animation_list()
	var max_anims: int = min(names.size(), 5)
	for i in range(max_anims):
		var anim := lib.get_animation(names[i])
		if anim == null:
			continue
		var track_count := anim.get_track_count()
		var max_tracks: int = min(track_count, 30)
		for t in range(max_tracks):
			var path_str := String(anim.track_get_path(t))
			if path_str.find(":") == -1:
				continue
			if path_str.find("Skeleton3D") == -1:
				continue
			var colon := path_str.find(":")
			if colon > 0:
				return path_str.substr(0, colon)
	return ""


func _maybe_remap_library_for_root(lib: AnimationLibrary, root: Node) -> AnimationLibrary:
	if lib == null or root == null:
		return lib
	var prefix := _get_library_track_prefix(lib)
	if prefix == "":
		return lib
	var skeleton := _find_primary_skeleton(root)
	if skeleton == null:
		return lib
	var target_prefix := String(root.get_path_to(skeleton))
	if target_prefix == "" or target_prefix == prefix:
		return lib
	return _remap_animation_library(lib, prefix, target_prefix)


func _remap_animation_library(lib: AnimationLibrary, from_prefix: String, to_prefix: String) -> AnimationLibrary:
	if lib == null:
		return null
	var out := AnimationLibrary.new()
	var names := lib.get_animation_list()
	for name in names:
		var anim := lib.get_animation(name)
		if anim == null:
			continue
		var dup: Animation = anim.duplicate()
		_retarget_animation_paths(dup, from_prefix, to_prefix)
		out.add_animation(name, dup)
	return out


func _retarget_animation_paths(anim: Animation, from_prefix: String, to_prefix: String) -> void:
	if anim == null or from_prefix == "" or to_prefix == "":
		return
	for track_idx in range(anim.get_track_count()):
		var path := anim.track_get_path(track_idx)
		var path_str := String(path)
		if path_str.begins_with(from_prefix):
			var rest := path_str.substr(from_prefix.length())
			anim.track_set_path(track_idx, NodePath(to_prefix + rest))


func _force_double_sided(root: Node) -> void:
	if root == null:
		return
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	for mesh in meshes:
		var mi := mesh as MeshInstance3D
		if mi == null:
			continue
		if mi.material_override:
			var mat := mi.material_override.duplicate()
			_apply_double_sided_material(mat)
			mi.material_override = mat
		if mi.mesh:
			var surface_count := mi.mesh.get_surface_count()
			for i in range(surface_count):
				var mat2 := mi.mesh.surface_get_material(i)
				if mat2 == null:
					continue
				var dup := mat2.duplicate()
				_apply_double_sided_material(dup)
				mi.set_surface_override_material(i, dup)


func _apply_double_sided_material(mat: Material) -> void:
	if mat == null:
		return
	if mat is BaseMaterial3D:
		(mat as BaseMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	elif "cull_mode" in mat:
		mat.set("cull_mode", BaseMaterial3D.CULL_DISABLED)


func _set_debug_mesh_visible(show: bool) -> void:
	var model_root := _ensure_model_root()
	if model_root == null:
		return
	if show:
		if _debug_mesh == null or not is_instance_valid(_debug_mesh):
			_debug_mesh = MeshInstance3D.new()
			_debug_mesh.name = "DebugMesh"
			var box := BoxMesh.new()
			box.size = Vector3(0.6, 1.2, 0.6)
			_debug_mesh.mesh = box
			model_root.add_child(_debug_mesh)
		_debug_mesh.visible = true
	elif _debug_mesh and is_instance_valid(_debug_mesh):
		_debug_mesh.visible = false


func _apply_pivot_defaults() -> void:
	if not pivot_align_bottom:
		_apply_visual_pivot_offset(pivot_offset)
		return
	var collision: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	var offset := pivot_offset
	if collision:
		var shape: Shape3D = collision.shape
		var height := _get_shape_height(shape)
		if height > 0.0:
			offset.y = height * 0.5 + pivot_offset.y
			collision.position = Vector3(pivot_offset.x, offset.y, pivot_offset.z)
	_apply_visual_pivot_offset(offset)


func _apply_visual_pivot_offset(offset: Vector3) -> void:
	_visual_pivot_base = offset
	_apply_visual_offset()


func _apply_visual_offset() -> void:
	var visual_root := get_node_or_null("VisualRoot")
	var offset := _visual_pivot_base + Vector3(0.0, _step_visual_offset, 0.0)
	if visual_root and visual_root is Node3D:
		visual_root.position = offset
		return
	for child in get_children():
		if child is MeshInstance3D:
			child.position = offset


func _get_shape_height(shape: Shape3D) -> float:
	if shape == null:
		return 0.0
	if shape is BoxShape3D:
		return shape.size.y
	if shape is CapsuleShape3D:
		return shape.height + shape.radius * 2.0
	if shape is CylinderShape3D:
		return shape.height
	if shape is SphereShape3D:
		return shape.radius * 2.0
	return 0.0


func _apply_step_momentum_carry() -> void:
	if not _step_carry_pending:
		return
	_step_carry_pending = false
	var input_mag := Vector2(input_x, input_y).length()
	if input_mag <= 0.01:
		return
	var current := Vector2(velocity.x, velocity.z)
	var carry := Vector2(_step_carry_velocity.x, _step_carry_velocity.z)
	if carry.length() <= 0.01:
		return
	if current.length() + 0.01 < carry.length():
		var dir := carry.normalized()
		velocity.x = dir.x * carry.length()
		velocity.z = dir.y * carry.length()


func _has_geometry(node: Node) -> bool:
	if node is GeometryInstance3D:
		return true
	for child in node.get_children():
		if _has_geometry(child):
			return true
	return false
