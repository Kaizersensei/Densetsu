extends FSMState
class_name LocomotionAir3D

const STATE_JUMP := "jump"
const STATE_DOUBLE_JUMP := "double_jump"
const STATE_FALL := "fall"
const STATE_GROUNDED := "LocomotionGrounded"
const LAND_VELOCITY_MAX := 1.0


func enter(owner: Node, _ctx := {}) -> void:
	_update_animation(owner)


func state_physics(owner: Node, delta: float) -> void:
	if owner and owner.has_method("apply_basic_movement") and not _should_skip_basic(owner):
		owner.apply_basic_movement(delta)
	_update_animation(owner)
	if owner and owner.has_method("is_on_floor") and owner.is_on_floor():
		if _get_vertical_velocity(owner) <= LAND_VELOCITY_MAX:
			_request_state(owner, STATE_GROUNDED)


func _update_animation(owner: Node) -> void:
	if owner == null:
		return
	var anim := _get_anim(owner)
	if anim == null:
		return
	if anim.has_method("set_playback_speed"):
		anim.call("set_playback_speed", 1.0)
	var combat_override := ""
	if owner and owner.has_method("_get_combat_override_state"):
		combat_override = owner._get_combat_override_state()
	if combat_override != "":
		anim.set_state(combat_override)
		return
	if "ledge_climbing" in owner:
		var lc: Variant = owner.get("ledge_climbing")
		if lc is bool and lc:
			anim.set_state("traversal_ledge_climb")
			return
	if "ledge_holding" in owner:
		var lh: Variant = owner.get("ledge_holding")
		if lh is bool and lh:
			anim.set_state("traversal_ledge_hold")
			return
	if "wall_jumping" in owner:
		var wj: Variant = owner.get("wall_jumping")
		if wj is bool and wj:
			anim.set_state("wall_jump")
			return
	var vel: Vector3 = Vector3.ZERO
	if "velocity" in owner:
		var v: Variant = owner.get("velocity")
		if v is Vector3:
			vel = v
	var target_state: String = STATE_FALL
	if vel.y > 0.2:
		target_state = STATE_DOUBLE_JUMP if _is_double_jump(owner) else STATE_JUMP
	anim.set_state(target_state)


func _is_double_jump(owner: Node) -> bool:
	if owner == null:
		return false
	if not ("jump_count" in owner):
		return false
	var jc: Variant = owner.get("jump_count")
	return jc is int and jc > 1


func _get_anim(owner: Node) -> AnimDriver3D:
	var ctx: ControllerContext3D = null
	if owner and owner.has_method("get_controller_context"):
		ctx = owner.get_controller_context()
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
