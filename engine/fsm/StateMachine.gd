extends Node

class_name StateMachine

@export var initial_state: String = ""
var current_state: String = ""
var previous_state: String = ""
var owner_ref: Node

var _states: Dictionary = {}

func _ready() -> void:
	if owner_ref == null:
		owner_ref = get_parent()
	_register_child_states()
	if initial_state != "":
		request_state(initial_state)


func _register_child_states() -> void:
	for child in get_children():
		if child is FSMState:
			register_state(child.name, child)


func register_state(name: String, state: Node) -> void:
	if not state:
		return
	_states[name] = state
	if state.get_parent() != self:
		add_child(state)


func request_state(name: String, ctx := {}, force: bool = false) -> void:
	if name == current_state and not force:
		return
	var next: Node = _states.get(name, null)
	if next == null:
		return
	var prev: Node = _states.get(current_state, null)
	if prev and prev.has_method("exit_state"):
		prev.exit_state(owner_ref, ctx)
	_log_transition(current_state, name, ctx)
	previous_state = current_state
	current_state = name
	if next.has_method("enter_state"):
		next.enter_state(owner_ref, ctx)


func state_process(delta: float) -> void:
	var state: Node = _states.get(current_state, null)
	if state and state.has_method("state_process"):
		state.state_process(owner_ref, delta)


func state_physics(delta: float) -> void:
	var state: Node = _states.get(current_state, null)
	if state and state.has_method("state_physics"):
		state.state_physics(owner_ref, delta)


func _log_transition(from_state: String, to_state: String, ctx: Dictionary) -> void:
	var actor_name := ""
	if owner_ref and owner_ref.has_method("get_name"):
		actor_name = str(owner_ref.name)
	print("FSM:", actor_name, "transition", from_state, "->", to_state, "ctx:", ctx)
