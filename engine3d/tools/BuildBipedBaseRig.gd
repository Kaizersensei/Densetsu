@tool
extends EditorScript

# Builds a reusable biped base scene from a single T-pose FBX rig.
# This is used as the character model source (armature + mesh).

const SOURCE_FBX := "res://temp/fbx animations/michio full.fbx"
const OUTPUT_SCENE := "res://assets/characters/biped/BipedBase.tscn"
const OUTPUT_REPORT := "res://assets/characters/biped/BipedBase_report.txt"


func _run() -> void:
	_ensure_output_dir()
	var report: Array[String] = []
	report.append("Biped Base Rig Build")
	report.append("Source FBX: " + SOURCE_FBX)
	report.append("Output Scene: " + OUTPUT_SCENE)
	if not ResourceLoader.exists(SOURCE_FBX):
		push_error("Missing source FBX: " + SOURCE_FBX)
		report.append("ERROR: Source FBX missing.")
		_write_report(report)
		return
	var scene_res := ResourceLoader.load(SOURCE_FBX)
	if scene_res == null or not (scene_res is PackedScene):
		push_error("Source FBX is not a PackedScene: " + SOURCE_FBX)
		report.append("ERROR: Source FBX not a PackedScene.")
		_write_report(report)
		return
	var inst := (scene_res as PackedScene).instantiate()
	if inst == null:
		push_error("Failed to instance source FBX.")
		report.append("ERROR: Failed to instance FBX.")
		_write_report(report)
		return
	inst.name = "BipedBase"
	_assign_owner_recursive(inst, inst)
	var packed := PackedScene.new()
	var pack_ok := packed.pack(inst)
	if not pack_ok:
		push_error("Failed to pack Biped base scene (attempt 1).")
		report.append("ERROR: Failed to pack scene (attempt 1).")
		var save_fallback := ResourceSaver.save(scene_res, OUTPUT_SCENE)
		if save_fallback != OK:
			push_error("Failed to save fallback scene: " + OUTPUT_SCENE)
			report.append("ERROR: Failed to save fallback scene.")
			_write_report(report)
			return
		report.append("Saved fallback: " + OUTPUT_SCENE)
		_write_report(report)
		print("Biped base rig build complete (fallback).")
		return
	var save_err := ResourceSaver.save(packed, OUTPUT_SCENE)
	if save_err != OK:
		push_error("Failed to save scene: " + OUTPUT_SCENE)
		report.append("ERROR: Failed to save scene.")
		_write_report(report)
		return
	report.append("Saved: " + OUTPUT_SCENE)
	_write_report(report)
	print("Biped base rig build complete.")


func _ensure_output_dir() -> void:
	var dir_path := OUTPUT_SCENE.get_base_dir()
	var abs_path := ProjectSettings.globalize_path(dir_path)
	DirAccess.make_dir_recursive_absolute(abs_path)


func _assign_owner_recursive(node: Node, owner: Node) -> void:
	if node == null:
		return
	if node != owner:
		node.owner = owner
	for child in node.get_children():
		_assign_owner_recursive(child, owner)


func _write_report(lines: Array[String]) -> void:
	var file := FileAccess.open(OUTPUT_REPORT, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write report: " + OUTPUT_REPORT)
		return
	for line in lines:
		file.store_line(line)
	file.close()
