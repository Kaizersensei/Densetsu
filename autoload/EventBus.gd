extends Node

signal event_emitted(name, payload)

func emit_event(name: String, payload := {}) -> void:
	emit_signal("event_emitted", name, payload)
