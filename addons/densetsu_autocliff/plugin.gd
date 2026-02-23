@tool
extends EditorPlugin

var _dock: Control


func _enter_tree() -> void:
	var dock_script: Script = load("res://addons/densetsu_autocliff/autocliff_dock.gd") as Script
	if dock_script == null:
		push_warning("Autocliff: failed to load dock script.")
		return
	_dock = dock_script.new()
	if _dock == null:
		push_warning("Autocliff: failed to instantiate dock.")
		return
	_dock.name = "Autocliff"
	if _dock.has_method("setup"):
		_dock.call("setup", get_editor_interface())
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree() -> void:
	if _dock == null:
		return
	if _dock.has_method("save_state"):
		_dock.call("save_state")
	remove_control_from_docks(_dock)
	_dock.queue_free()
	_dock = null
