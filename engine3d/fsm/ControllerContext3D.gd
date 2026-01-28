extends RefCounted
class_name ControllerContext3D

var actor: ActorCharacter3D
var input: IInputSource
var movement: MovementData3D
var camera: OrbitCamera3D
var anim: AnimDriver3D

var move_input: Vector2 = Vector2.ZERO
var is_running: bool = false
var on_floor: bool = false
var is_dashing: bool = false
var is_rolling: bool = false
var is_crouching: bool = false
var is_sneaking: bool = false


func refresh() -> void:
	if actor == null:
		return
	if input == null and actor.has_method("get_input_source"):
		input = actor.get_input_source()
	if movement == null and actor.has_method("get_movement_params"):
		movement = actor.get_movement_params()
	if camera == null and actor.has_method("get_orbit_camera"):
		camera = actor.get_orbit_camera()
	if anim == null and actor.has_method("get_anim_driver"):
		anim = actor.get_anim_driver()
	if input:
		move_input = input.get_move_vector()
		is_running = input.is_run_held()
	else:
		move_input = Vector2.ZERO
		is_running = false
	on_floor = actor.is_on_floor()
	is_dashing = actor.dashing
	is_rolling = actor.roll_active
	is_crouching = actor.crouching
	is_sneaking = actor.sneaking
