extends Node

class_name FSMState

func enter_state(_owner: Node, _ctx := {}) -> void:
	pass


func exit_state(_owner: Node, _ctx := {}) -> void:
	pass


func state_process(_owner: Node, _delta: float) -> void:
	pass


func state_physics(_owner: Node, _delta: float) -> void:
	pass
