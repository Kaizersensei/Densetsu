@tool
extends EditorPlugin

var _dock: Control


func _enter_tree() -> void:
	var dock_script: Script = load("res://addons/player_params_dock/player_params_dock.gd") as Script
	if dock_script == null:
		return
	_dock = dock_script.new()
	_dock.name = "Player Params"
	if _dock.has_method("setup"):
		_dock.call("setup", get_editor_interface())
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree() -> void:
	if _dock == null:
		return
	remove_control_from_docks(_dock)
	_dock.queue_free()
	_dock = null
