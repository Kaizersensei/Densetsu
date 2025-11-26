extends FSMState

func enter_state(owner: Node, _ctx := {}) -> void:
	var target := _resolve_owner_root(owner)
	if target and target.has_method("set_debug_state"):
		target.set_debug_state("Land")


func _resolve_owner_root(owner: Node) -> Node:
	if owner == null:
		return null
	if owner.has_method("get_root"):
		return owner.get_root()
	return owner
