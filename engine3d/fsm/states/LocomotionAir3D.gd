extends FSMState
class_name LocomotionAir3D

const STATE_JUMP := "jump"
const STATE_FALL := "fall"
const STATE_GROUNDED := "LocomotionGrounded"


func enter(owner: Node, _ctx := {}) -> void:
	_update_animation(owner)


func state_physics(owner: Node, delta: float) -> void:
	if owner and owner.has_method("apply_basic_movement") and not _should_skip_basic(owner):
		owner.apply_basic_movement(delta)
	_update_animation(owner)
	if owner and owner.has_method("is_on_floor") and owner.is_on_floor():
		_request_state(owner, STATE_GROUNDED)


func _update_animation(owner: Node) -> void:
	if owner == null:
		return
	var anim := _get_anim(owner)
	if anim == null:
		return
	var vel := Vector3.ZERO
	if "velocity" in owner:
		vel = owner.get("velocity")
	var target_state := STATE_FALL
	if vel.y > 0.0:
		target_state = STATE_JUMP
	anim.set_state(_resolve_anim_state(owner, target_state))


func _get_anim(owner: Node) -> AnimDriver3D:
	var ctx: ControllerContext3D = null
	if owner and owner.has_method("get_controller_context"):
		ctx = owner.get_controller_context()
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
