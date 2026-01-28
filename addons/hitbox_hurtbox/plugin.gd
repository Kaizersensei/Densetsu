@tool
extends EditorPlugin

func _enter_tree() -> void:
	# Scripts are globally available via class_name; nothing else to register.
	pass


func _exit_tree() -> void:
	pass
