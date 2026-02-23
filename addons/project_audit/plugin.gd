@tool
extends EditorPlugin

const DockScene := preload("res://addons/project_audit/unused_files_dock.tscn")

var _dock: Control


func _enter_tree() -> void:
	_dock = DockScene.instantiate()
	_dock.set_editor_interface(get_editor_interface())
	add_control_to_bottom_panel(_dock, "Project Audit")


func _exit_tree() -> void:
	if _dock:
		remove_control_from_bottom_panel(_dock)
		_dock.queue_free()
		_dock = null
