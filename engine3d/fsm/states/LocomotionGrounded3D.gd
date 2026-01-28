extends FSMState
class_name LocomotionGrounded3D

const STATE_IDLE := "idle"
const STATE_WALK := "walk"
const STATE_RUN := "run"
const STATE_SPRINT := "sprint"
const STATE_ROLL := "roll"
const STATE_CROUCH_IDLE := "crouch_idle"
const STATE_CROUCH_WALK := "crouch_walk"
const STATE_AIR := "LocomotionAir"


func enter(owner: Node, _ctx := {}) -> void:
	_update_animation(owner)


func state_physics(owner: Node, delta: float) -> void:
	if owner and owner.has_method("apply_basic_movement") and not _should_skip_basic(owner):
		owner.apply_basic_movement(delta)
	_update_animation(owner)
	if owner and owner.has_method("is_on_floor") and not owner.is_on_floor():
		_request_state(owner, STATE_AIR)


func _update_animation(owner: Node) -> void:
	if owner == null:
		return
	var ctx: ControllerContext3D = _get_ctx(owner)
	if ctx:
		ctx.refresh()
	var move := Vector2.ZERO
	var running := false
	var dashing := false
	var rolling := false
	var crouching := false
	var sneaking := false
	if ctx:
		move = ctx.move_input
		running = ctx.is_running
		dashing = ctx.is_dashing
		rolling = ctx.is_rolling
		crouching = ctx.is_crouching
		sneaking = ctx.is_sneaking
	elif owner and owner.has_method("get_input_source"):
		var input = owner.get_input_source()
		if input:
			move = input.get_move_vector()
			running = input.is_run_held()
	if owner:
		if "dashing" in owner:
			dashing = owner.get("dashing")
		if "roll_active" in owner:
			rolling = owner.get("roll_active")
		if "crouching" in owner:
			crouching = owner.get("crouching")
		if "sneaking" in owner:
			sneaking = owner.get("sneaking")
	var forward_input := absf(move.y) > 0.05
	var target_state := STATE_IDLE
	if rolling:
		target_state = STATE_ROLL
	elif dashing:
		target_state = STATE_SPRINT
	elif crouching or sneaking:
		target_state = STATE_CROUCH_WALK if forward_input else STATE_CROUCH_IDLE
	elif forward_input:
		target_state = STATE_RUN if running else STATE_WALK
	var anim := _get_anim(owner, ctx)
	if anim:
		anim.set_state(_resolve_anim_state(owner, target_state))


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


func _resolve_anim_state(owner: Node, intent: String) -> String:
	if owner and owner.has_method("resolve_anim_state"):
		return owner.resolve_anim_state(intent)
	return intent


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
