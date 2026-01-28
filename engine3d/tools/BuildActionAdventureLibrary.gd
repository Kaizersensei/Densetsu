@tool
extends EditorScript

# Builds a small AnimationLibrary from the Action Adventure pack only.

const INPUT_ROOT := "res://temp/fbx animations"
const OUTPUT_LIBRARY := "res://assets/characters/biped/anim/BipedAnimations_ActionAdventure.tres"
const OUTPUT_REPORT := "res://assets/characters/biped/anim/BipedAnimations_ActionAdventure_report.txt"
var PACK_FILTER: PackedStringArray = PackedStringArray(["Action Adventure Pack"])
const REFERENCE_RIG_SCENE := "res://temp/fbx animations/michio rigged.fbx"
const MODEL_DATA_PATH := "res://data3d/models/MODEL_Player_Michio_ActionAdventure.tres"

const INCLUDE_TPOSE := false
const STRIP_ROOT_TRANSLATION := true
const TRACK_PATH_PREFIX := "Armature/"

var SKIP_PATTERNS: PackedStringArray = PackedStringArray([
	"tpose",
	"t-pose",
	"t_pose",
])

var SKIP_FILES: PackedStringArray = PackedStringArray([
	"michio full",
	"michio rigged",
])

var ROOT_BONE_NAMES: PackedStringArray = PackedStringArray([
	"root",
	"hips",
	"pelvis",
	"armature",
	"mixamorig:hips",
	"mixamorig_hips",
])

var _skeleton_path := ""
var _bone_map := {}
var _node_paths := {}


func _run() -> void:
	_ensure_output_dir()
	_build_skeleton_cache()
	var lib := _load_or_create_library()
	if lib == null:
		push_error("Failed to create animation library.")
		return
	var files: Array[String] = []
	_collect_fbx(INPUT_ROOT, files)
	files.sort()
	var report: Array[String] = []
	report.append("Animation Library Build (Action Adventure)")
	report.append("Input root: " + INPUT_ROOT)
	report.append("Output library: " + OUTPUT_LIBRARY)
	report.append("Clips:")
	var added := 0
	for path in files:
		if _should_skip(path):
			report.append("- SKIP " + path)
			continue
		var scene_res := ResourceLoader.load(path)
		if scene_res == null or not (scene_res is PackedScene):
			report.append("- FAIL load " + path)
			continue
		var inst := (scene_res as PackedScene).instantiate()
		if inst == null:
			report.append("- FAIL instance " + path)
			continue
		var anim_player := _find_anim_player(inst)
		if anim_player == null:
			report.append("- FAIL no AnimationPlayer " + path)
			inst.free()
			continue
		var anim_names := anim_player.get_animation_list()
		if anim_names.is_empty():
			report.append("- FAIL no animations " + path)
			inst.free()
			continue
		for anim_name in anim_names:
			var anim := anim_player.get_animation(anim_name)
			if anim == null:
				continue
			var out_name := _build_anim_name(path, anim_name, anim_names.size())
			var out_anim: Animation = anim.duplicate()
			_sanitize_animation_tracks(out_anim)
			if STRIP_ROOT_TRANSLATION:
				_strip_root_translation(out_anim)
			if lib.has_animation(out_name):
				lib.remove_animation(out_name)
			lib.add_animation(out_name, out_anim)
			report.append("- ADD " + out_name + " <= " + path + " [" + anim_name + "]")
			added += 1
		inst.free()
	var save_err := ResourceSaver.save(lib, OUTPUT_LIBRARY)
	if save_err != OK:
		push_error("Failed to save AnimationLibrary: " + OUTPUT_LIBRARY)
		report.append("ERROR: Failed to save library.")
	else:
		report.append("Saved: " + OUTPUT_LIBRARY)
		report.append("Total animations added: " + str(added))
		_update_model_data_library(lib, report)
	_write_report(report)
	print("Action Adventure library build complete. Added: " + str(added))


func _load_or_create_library() -> AnimationLibrary:
	var lib: AnimationLibrary = null
	if ResourceLoader.exists(OUTPUT_LIBRARY):
		var existing := ResourceLoader.load(OUTPUT_LIBRARY)
		if existing is AnimationLibrary:
			lib = existing
	if lib == null:
		lib = AnimationLibrary.new()
	return lib


func _collect_fbx(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Missing input dir: " + dir_path)
		return
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue
		var full := dir_path.path_join(name)
		if dir.current_is_dir():
			if _is_pack_allowed(name):
				_collect_fbx(full, out)
			continue
		elif name.to_lower().ends_with(".fbx"):
			out.append(full)
	dir.list_dir_end()


func _is_pack_allowed(folder_name: String) -> bool:
	if PACK_FILTER.is_empty():
		return true
	for pack_name in PACK_FILTER:
		if folder_name == pack_name:
			return true
	return false


func _should_skip(path: String) -> bool:
	if INCLUDE_TPOSE:
		return false
	var name := path.get_file().get_basename().to_lower()
	for exact_name in SKIP_FILES:
		if name == exact_name:
			return true
	for pattern in SKIP_PATTERNS:
		if name.find(pattern) != -1:
			return true
	return false


func _build_anim_name(path: String, anim_name: String, anim_count: int) -> String:
	var rel := path.replace(INPUT_ROOT + "/", "")
	var pack_path := rel.get_base_dir()
	var pack_slug := _slug(pack_path)
	var clip_name := path.get_file().get_basename()
	var clip_slug := _slug(clip_name)
	if anim_count > 1 and anim_name != "":
		clip_slug = _slug(anim_name)
	var name := clip_slug
	if pack_slug != "":
		name = pack_slug + "__" + clip_slug
	if name == "":
		name = "anim_" + str(abs(path.hash()))
	return name


func _slug(value: String) -> String:
	var out := value.strip_edges().to_lower()
	out = out.replace("\\", "/")
	out = out.replace("/", "_")
	out = out.replace(" ", "_")
	out = out.replace("-", "_")
	out = out.replace("__", "_")
	return out


func _find_anim_player(root: Node) -> AnimationPlayer:
	if root == null:
		return null
	if root is AnimationPlayer:
		return root as AnimationPlayer
	var players := root.find_children("*", "AnimationPlayer", true, false)
	if players.size() > 0:
		return players[0] as AnimationPlayer
	return null


func _strip_root_translation(anim: Animation) -> void:
	if anim == null:
		return
	for track_idx in anim.get_track_count():
		if anim.track_get_type(track_idx) != Animation.TYPE_POSITION_3D:
			continue
		var path := anim.track_get_path(track_idx)
		if not _is_root_bone_path(path):
			continue
		var key_count := anim.track_get_key_count(track_idx)
		for i in range(key_count):
			var _t := anim.track_get_key_time(track_idx, i)
			anim.track_set_key_value(track_idx, i, Vector3.ZERO)
		break


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


func _sanitize_animation_tracks(anim: Animation) -> void:
	if anim == null:
		return
	for track_idx in range(anim.get_track_count() - 1, -1, -1):
		var path := anim.track_get_path(track_idx)
		var path_str := String(path)
		if path_str == "":
			continue
		var split_at := path_str.find(":")
		if split_at == -1:
			if not _node_exists(path_str):
				anim.remove_track(track_idx)
			continue
		var node_path := path_str.substr(0, split_at)
		var subname := path_str.substr(split_at + 1)
		if node_path.find("Skeleton3D") != -1:
			var bone_key := _normalize_bone_name(subname)
			if not _bone_map.has(bone_key):
				anim.remove_track(track_idx)
				continue
			var bone_name := String(_bone_map[bone_key])
			var target_path := _skeleton_path if _skeleton_path != "" else node_path
			anim.track_set_path(track_idx, NodePath(target_path + ":" + bone_name))
		else:
			if not _node_exists(node_path):
				anim.remove_track(track_idx)


func _ensure_output_dir() -> void:
	var dir_path := OUTPUT_LIBRARY.get_base_dir()
	var abs_path := ProjectSettings.globalize_path(dir_path)
	DirAccess.make_dir_recursive_absolute(abs_path)


func _write_report(lines: Array[String]) -> void:
	var file := FileAccess.open(OUTPUT_REPORT, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write report: " + OUTPUT_REPORT)
		return
	for line in lines:
		file.store_line(line)
	file.close()


func _update_model_data_library(lib: AnimationLibrary, report: Array[String]) -> void:
	if lib == null:
		return
	if not ResourceLoader.exists(MODEL_DATA_PATH):
		report.append("WARN: Model data not found: " + MODEL_DATA_PATH)
		return
	var res := ResourceLoader.load(MODEL_DATA_PATH)
	if res == null:
		report.append("WARN: Failed to load model data: " + MODEL_DATA_PATH)
		return
	if "animation_library" in res:
		res.animation_library = lib
		var save_err := ResourceSaver.save(res, MODEL_DATA_PATH)
		if save_err == OK:
			report.append("Updated model data library: " + MODEL_DATA_PATH)
		else:
			report.append("WARN: Failed to save model data: " + MODEL_DATA_PATH)


func _build_skeleton_cache() -> void:
	_skeleton_path = ""
	_bone_map.clear()
	_node_paths.clear()
	if not ResourceLoader.exists(REFERENCE_RIG_SCENE):
		push_warning("Reference rig not found: " + REFERENCE_RIG_SCENE)
		return
	var scene_res := ResourceLoader.load(REFERENCE_RIG_SCENE)
	if scene_res == null or not (scene_res is PackedScene):
		push_warning("Reference rig is not a PackedScene: " + REFERENCE_RIG_SCENE)
		return
	var inst := (scene_res as PackedScene).instantiate()
	if inst == null:
		push_warning("Failed to instance reference rig.")
		return
	var skeleton := inst.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton:
		_skeleton_path = String(inst.get_path_to(skeleton))
		for i in range(skeleton.get_bone_count()):
			var name := skeleton.get_bone_name(i)
			_bone_map[_normalize_bone_name(name)] = name
		_cache_node_paths(inst)
	inst.free()


func _cache_node_paths(root: Node) -> void:
	if root == null:
		return
	_node_paths[String(root.get_path())] = true
	for node in root.find_children("*", "", true, false):
		_node_paths[String(root.get_path_to(node))] = true


func _node_exists(path_str: String) -> bool:
	if _node_paths.is_empty():
		return true
	return _node_paths.has(path_str)


func _normalize_bone_name(name: String) -> String:
	var out := name.strip_edges().to_lower()
	out = out.replace(":", "_")
	return out
