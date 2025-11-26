extends FSMState

func enter_state(owner: Node, _ctx := {}) -> void:
	var target := owner
	if owner and owner.has_method("get_root"):
		target = owner.get_root()
	if target and target.has_method("set_debug_state"):
		target.set_debug_state("Triggered")
