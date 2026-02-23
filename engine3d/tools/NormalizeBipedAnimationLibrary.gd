@tool
extends EditorScript

# Normalizes root motion translation and extracts per-clip floor offsets.

const INPUT_LIBRARY := "res://assets/characters/biped/anim/BipedAnimations_ActionAdventure.tres"
const OUTPUT_REPORT := "res://assets/characters/biped/anim/BipedAnimations_ActionAdventure_normalize_report.txt"
const MODEL_DATA_PATH := "res://data3d/models/MODEL_Player_Michio_ActionAdventure.tres"

const ZERO_ROOT_TRANSLATION := true
const KEEP_ROOT_Y := false

var ROOT_BONE_NAMES: PackedStringArray = PackedStringArray([
	"root",
	"hips",
	"pelvis",
	"armature",
	"mixamorig:hips",
	"mixamorig_hips",
])


func _run() -> void:
	if not ResourceLoader.exists(INPUT_LIBRARY):
		push_error("Missing library: " + INPUT_LIBRARY)
		return
	var lib := ResourceLoader.load(INPUT_LIBRARY)
	if lib == null or not (lib is AnimationLibrary):
		push_error("Invalid library: " + INPUT_LIBRARY)
		return
	var report: Array[String] = []
	report.append("Normalize Animation Library")
	report.append("Input: " + INPUT_LIBRARY)
	report.append("Zero root translation: " + str(ZERO_ROOT_TRANSLATION))
	report.append("Keep root Y: " + str(KEEP_ROOT_Y))
	var offsets := {}
	var names: PackedStringArray = lib.get_animation_list()
	for name in names:
		var anim: Animation = lib.get_animation(name)
		if anim == null:
			continue
		var root_track: int = _find_root_translation_track(anim)
		if root_track == -1:
			report.append("- NO ROOT: " + name)
			continue
		var key_count: int = anim.track_get_key_count(root_track)
		if key_count <= 0:
			report.append("- EMPTY ROOT: " + name)
			continue
		var min_y := 1.0e20
		for i in range(key_count):
			var value = anim.track_get_key_value(root_track, i)
			if value is Vector3:
				var v: Vector3 = value
				min_y = minf(min_y, v.y)
				if ZERO_ROOT_TRANSLATION:
					if KEEP_ROOT_Y:
						anim.track_set_key_value(root_track, i, Vector3(0.0, v.y, 0.0))
					else:
						anim.track_set_key_value(root_track, i, Vector3.ZERO)
		if min_y == 1.0e20:
			min_y = 0.0
		offsets[name] = -min_y
		report.append("- OK " + name + " offset=" + str(-min_y))
	var save_err := ResourceSaver.save(lib, INPUT_LIBRARY)
	if save_err != OK:
		push_error("Failed to save library: " + INPUT_LIBRARY)
		report.append("ERROR: Failed to save library.")
	else:
		report.append("Saved: " + INPUT_LIBRARY)
	_update_model_data_offsets(offsets, report)
	_write_report(report)
	print("Normalize library complete. Offsets:", offsets.size())


func _find_root_translation_track(anim: Animation) -> int:
	if anim == null:
		return -1
	for track_idx in anim.get_track_count():
		if anim.track_get_type(track_idx) != Animation.TYPE_POSITION_3D:
			continue
		var path := anim.track_get_path(track_idx)
		if _is_root_bone_path(path):
			return track_idx
	return -1


func _is_root_bone_path(path: NodePath) -> bool:
	var name := ""
	if path.get_subname_count() > 0:
		name = String(path.get_subname(0))
	else:
		name = String(path).get_file()
	name = _normalize_bone_name(name)
	for candidate in ROOT_BONE_NAMES:
		if name == _normalize_bone_name(candidate):
			return true
	return false


func _normalize_bone_name(name: String) -> String:
	var out := name.strip_edges().to_lower()
	out = out.replace(":", "_")
	return out


func _update_model_data_offsets(offsets: Dictionary, report: Array[String]) -> void:
	if offsets.is_empty():
		return
	if not ResourceLoader.exists(MODEL_DATA_PATH):
		report.append("WARN: Model data not found: " + MODEL_DATA_PATH)
		return
	var res := ResourceLoader.load(MODEL_DATA_PATH)
	if res == null:
		report.append("WARN: Failed to load model data: " + MODEL_DATA_PATH)
		return
	if "anim_floor_offsets" in res:
		res.anim_floor_offsets = offsets
		var save_err := ResourceSaver.save(res, MODEL_DATA_PATH)
		if save_err == OK:
			report.append("Updated model data offsets: " + MODEL_DATA_PATH)
		else:
			report.append("WARN: Failed to save model data: " + MODEL_DATA_PATH)


func _write_report(lines: Array[String]) -> void:
	var file := FileAccess.open(OUTPUT_REPORT, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write report: " + OUTPUT_REPORT)
		return
	for line in lines:
		file.store_line(line)
	file.close()
