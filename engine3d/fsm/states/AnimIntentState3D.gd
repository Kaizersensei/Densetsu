extends FSMState
class_name AnimIntentState3D

## Controls anim intent.
@export var anim_intent: String = ""
## Enable refresh each physics.
@export var refresh_each_physics: bool = true


func enter_state(owner: Node, _ctx := {}) -> void:
	_apply_intent(owner)


func state_physics(owner: Node, _delta: float) -> void:
	if refresh_each_physics:
		_apply_intent(owner)


func _apply_intent(owner: Node) -> void:
	if owner == null:
		return
	if anim_intent == "":
		return
	var anim := _get_anim(owner)
	if anim == null:
		return
	anim.set_state(anim_intent)


func _get_anim(owner: Node) -> AnimDriver3D:
	if owner and owner.has_method("get_anim_driver"):
		return owner.get_anim_driver()
	return null

