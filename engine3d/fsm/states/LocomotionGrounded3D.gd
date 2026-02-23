extends FSMState
class_name LocomotionGrounded3D

const STATE_IDLE := "idle"
const STATE_IDLE_TURN_LEFT := "idle_turn_left"
const STATE_IDLE_TURN_RIGHT := "idle_turn_right"
const STATE_WALK := "walk"
const STATE_WALK_TURN_LEFT := "walk_turn_left"
const STATE_WALK_TURN_RIGHT := "walk_turn_right"
const STATE_RUN := "run"
const STATE_RUN_TURN_LEFT := "run_turn_left"
const STATE_RUN_TURN_RIGHT := "run_turn_right"
const STATE_SPRINT := "sprint"
const STATE_SPRINT_TURN_LEFT := "sprint_turn_left"
const STATE_SPRINT_TURN_RIGHT := "sprint_turn_right"
const STATE_ROLL := "roll"
const STATE_CROUCH_ENTER := "crouch_enter"
const STATE_CROUCH_IDLE := "crouch_idle"
const STATE_CROUCH_WALK := "crouch_walk"
const STATE_CROUCH_TURN := "crouch_turn"
const STATE_CROUCH_TURN_LEFT := "crouch_turn_left"
const STATE_CROUCH_TURN_RIGHT := "crouch_turn_right"
const STATE_CROUCH_EXIT := "crouch_exit"
const STATE_AIR := "LocomotionAir"
const AIR_GRACE_TIME := 0.08
const CROUCH_ENTER_TIME := 0.18
const CROUCH_EXIT_TIME := 0.18

var _air_grace := 0.0
var _crouch_prev := false
var _crouch_transition_timer := 0.0
var _crouch_transition_state := ""


func enter(owner: Node, _ctx := {}) -> void:
	_crouch_prev = false
	if owner and "crouching" in owner:
		_crouch_prev = owner.get("crouching")
	_crouch_transition_timer = 0.0
	_crouch_transition_state = ""
	_update_animation(owner, 0.0)


func state_physics(owner: Node, delta: float) -> void:
	if owner and owner.has_method("apply_basic_movement") and not _should_skip_basic(owner):
		owner.apply_basic_movement(delta)
	_update_animation(owner, delta)
	if owner and owner.has_method("is_on_floor"):
		if owner.is_on_floor():
			_air_grace = 0.0
		else:
			if _should_force_air(owner):
				_request_state(owner, STATE_AIR)
				return
			_air_grace += delta
			var air_grace_time: float = _get_air_grace_time(owner)
			if _air_grace >= air_grace_time:
				_request_state(owner, STATE_AIR)


func _update_animation(owner: Node, delta: float) -> void:
	if owner == null:
		return
	var ctx: ControllerContext3D = _get_ctx(owner)
	if ctx:
		ctx.refresh()
	var move := Vector2.ZERO
	var running := false
	var sprinting := false
	var dashing := false
	var rolling := false
	var crouching := false
	var speed_x_abs := 0.0
	if owner and owner.has_method("get_locomotion_move_input"):
		move = owner.get_locomotion_move_input()
	elif ctx:
		move = ctx.move_input
		running = ctx.is_running
		sprinting = ctx.is_sprinting
		dashing = ctx.is_dashing
		rolling = ctx.is_rolling
		crouching = ctx.is_crouching
	elif owner and owner.has_method("get_input_source"):
		var input = owner.get_input_source()
		if input:
			move = input.get_move_vector()
			if "run_active" in owner:
				running = owner.get("run_active")
			else:
				running = input.is_run_held()
	if owner:
		if "dashing" in owner:
			dashing = owner.get("dashing")
		if "sprint_active" in owner:
			sprinting = owner.get("sprint_active")
		if "roll_active" in owner:
			rolling = owner.get("roll_active")
		if "crouching" in owner:
			crouching = owner.get("crouching")
		if "speed_x_abs" in owner:
			speed_x_abs = owner.get("speed_x_abs")
	if ctx and ctx.movement:
		var run_threshold := ctx.movement.run_speed * 0.9
		if speed_x_abs > run_threshold:
			running = true
	if crouching != _crouch_prev:
		_crouch_prev = crouching
		_crouch_transition_timer = CROUCH_ENTER_TIME if crouching else CROUCH_EXIT_TIME
		_crouch_transition_state = STATE_CROUCH_ENTER if crouching else STATE_CROUCH_EXIT
	if _crouch_transition_timer > 0.0:
		_crouch_transition_timer = maxf(0.0, _crouch_transition_timer - delta)
	var forward_input := absf(move.y) > 0.05
	var moving_input := forward_input
	var move_len := move.length()
	if move_len > 0.05 and ctx and ctx.movement:
		var walk_thresh := ctx.movement.walk_speed * 0.3
		if speed_x_abs > walk_thresh:
			forward_input = true
	var turn_left := move.x < -0.15
	var turn_right := move.x > 0.15
	var turn_input := turn_left or turn_right
	if forward_input and ctx and ctx.movement:
		var run_speed := ctx.movement.run_speed
		if run_speed > 0.0 and speed_x_abs > run_speed * 0.75:
			running = true
	var target_state := STATE_IDLE
	if rolling:
		target_state = STATE_ROLL
	elif _crouch_transition_timer > 0.0 and _crouch_transition_state != "":
		target_state = _crouch_transition_state
	elif crouching:
		if forward_input:
			target_state = STATE_CROUCH_WALK
		elif turn_input:
			target_state = STATE_CROUCH_TURN_LEFT if turn_left else STATE_CROUCH_TURN_RIGHT
		else:
			target_state = STATE_CROUCH_IDLE
	elif sprinting or dashing:
		if turn_left:
			target_state = STATE_SPRINT_TURN_LEFT
		elif turn_right:
			target_state = STATE_SPRINT_TURN_RIGHT
		else:
			target_state = STATE_SPRINT
	elif forward_input:
		if running:
			target_state = STATE_RUN
		else:
			target_state = STATE_WALK
	elif turn_input and not forward_input:
		target_state = STATE_IDLE_TURN_LEFT if turn_left else STATE_IDLE_TURN_RIGHT
	var anim := _get_anim(owner, ctx)
	if anim:
		var combat_override := ""
		if owner and owner.has_method("_get_combat_override_state"):
			combat_override = owner._get_combat_override_state()
		var playback_speed: float = 1.0
		if combat_override != "":
			anim.set_state(combat_override)
		else:
			anim.set_state(target_state)
			if owner and owner.has_method("get_locomotion_anim_speed_scale"):
				var speed_any: Variant = owner.call("get_locomotion_anim_speed_scale", target_state)
				if speed_any is float:
					playback_speed = float(speed_any)
		if anim.has_method("set_playback_speed"):
			anim.call("set_playback_speed", playback_speed)


func _get_ctx(owner: Node) -> ControllerContext3D:
	if owner and owner.has_method("get_controller_context"):
		return owner.get_controller_context()
	return null


func _get_anim(owner: Node, ctx: ControllerContext3D) -> AnimDriver3D:
	if ctx and ctx.anim:
		return ctx.anim
	if owner and owner.has_method("get_anim_driver"):
		return owner.get_anim_driver()
	return null




func _get_vertical_velocity(owner: Node) -> float:
	if owner and "velocity" in owner:
		var vel = owner.get("velocity")
		if vel is Vector3:
			return vel.y
	return 0.0


func _get_air_grace_time(owner: Node) -> float:
	var ctx: ControllerContext3D = _get_ctx(owner)
	if ctx and ctx.movement:
		return maxf(ctx.movement.floor_leave_delay, 0.0)
	return AIR_GRACE_TIME


func _should_force_air(owner: Node) -> bool:
	if owner == null:
		return false
	if "jumping" in owner and owner.get("jumping"):
		return true
	if "in_air" in owner and owner.get("in_air"):
		return true
	if "velocity" in owner:
		var vel = owner.get("velocity")
		if vel is Vector3 and vel.y > 0.01:
			return true
	return false


func _request_state(owner: Node, state_name: String) -> void:
	if owner == null:
		return
	var sm := owner.get_node_or_null("StateMachine")
	if sm and sm.has_method("request_state"):
		sm.request_state(state_name)


func _should_skip_basic(owner: Node) -> bool:
	if owner == null:
		return true
	if "use_basic_movement" in owner and owner.get("use_basic_movement") == true:
		return true
	return false
