@tool
extends RefCounted

var SUPPORTED_MESH_RESOURCE_EXTS: PackedStringArray = PackedStringArray(["tres", "res"])
const SUPPORTED_OBJ_EXT: String = "obj"
const FLIP_V_TEXCOORD: bool = true
const FLIP_FACE_WINDING_FOR_OBJ: bool = true


func export_mesh_to_obj(mesh: Mesh, output_obj_path: String, object_name: String = "MeshExport") -> bool:
	if mesh == null:
		return false
	var mtl_file_name: String = output_obj_path.get_file().get_basename() + ".mtl"
	var export_data: Dictionary = _build_obj_and_mtl_text(mesh, object_name, mtl_file_name)
	var obj_text: String = str(export_data.get("obj", ""))
	if obj_text.is_empty():
		return false
	var mtl_text: String = str(export_data.get("mtl", ""))
	_ensure_output_dir(output_obj_path)
	var file: FileAccess = FileAccess.open(output_obj_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(obj_text)
	file.close()
	if not mtl_text.is_empty():
		var output_mtl_path: String = output_obj_path.get_base_dir().path_join(mtl_file_name)
		var mtl_file: FileAccess = FileAccess.open(output_mtl_path, FileAccess.WRITE)
		if mtl_file == null:
			return false
		mtl_file.store_string(mtl_text)
		mtl_file.close()
	return true


func convert_mesh_resource_paths_to_obj(paths: PackedStringArray, editor_iface: EditorInterface = null) -> Dictionary:
	var files: PackedStringArray = _expand_paths(paths)
	var converted: int = 0
	var skipped: int = 0
	var failed: int = 0
	var converted_paths: PackedStringArray = PackedStringArray()

	for file_path in files:
		var ext: String = file_path.get_extension().to_lower()
		if not SUPPORTED_MESH_RESOURCE_EXTS.has(ext):
			skipped += 1
			continue

		var res: Resource = ResourceLoader.load(file_path)
		if not (res is Mesh):
			skipped += 1
			continue

		var mesh: Mesh = res as Mesh
		var out_path: String = file_path.get_base_dir().path_join(file_path.get_file().get_basename() + ".obj")
		var ok: bool = export_mesh_to_obj(mesh, out_path, file_path.get_file().get_basename())
		if not ok:
			failed += 1
			continue
		_refresh_path(out_path, editor_iface)
		var mtl_path: String = out_path.get_base_dir().path_join(out_path.get_file().get_basename() + ".mtl")
		if FileAccess.file_exists(mtl_path):
			_refresh_path(mtl_path, editor_iface)
		converted += 1
		converted_paths.append(out_path)

	return {
		"ok": failed == 0 and converted > 0,
		"converted": converted,
		"failed": failed,
		"skipped": skipped,
		"paths": converted_paths
	}


func replace_scene_mesh_references_with_obj(obj_paths: PackedStringArray, editor_iface: EditorInterface = null) -> Dictionary:
	var mapping: Dictionary = {}
	for obj_path in obj_paths:
		var ext: String = obj_path.get_extension().to_lower()
		if ext != SUPPORTED_OBJ_EXT:
			continue
		var base_name: String = obj_path.get_file().get_basename().to_lower()
		if base_name.is_empty():
			continue
		mapping[base_name] = obj_path

	if mapping.is_empty():
		return {
			"ok": false,
			"error": "No OBJ files selected."
		}

	var scene_files: PackedStringArray = PackedStringArray()
	_collect_scene_files_recursive("res://", scene_files)

	var updated_scenes: int = 0
	var replacements: int = 0
	var failed: int = 0

	for scene_path in scene_files:
		var result: Dictionary = _replace_scene_paths(scene_path, mapping)
		var changed: bool = bool(result.get("changed", false))
		var count: int = int(result.get("count", 0))
		var ok: bool = bool(result.get("ok", false))
		if not ok:
			failed += 1
			continue
		if changed:
			updated_scenes += 1
			replacements += count
			_refresh_path(scene_path, editor_iface)

	return {
		"ok": failed == 0 and updated_scenes > 0,
		"updated_scenes": updated_scenes,
		"replacements": replacements,
		"failed": failed
	}


func replace_project_mesh_references_with_obj_auto(editor_iface: EditorInterface = null) -> Dictionary:
	return replace_project_mesh_references_with_obj_with_options(
		editor_iface,
		false,
		true,
		false,
		"res://",
		"res://"
	)


func replace_project_mesh_references_with_obj_with_options(
	editor_iface: EditorInterface = null,
	dry_run: bool = true,
	same_folder_only: bool = true,
	allow_basename_fallback: bool = false,
	root_dir: String = "res://",
	obj_root_dir: String = "res://"
) -> Dictionary:
	var target_scan_root: String = root_dir.strip_edges()
	if target_scan_root.is_empty():
		target_scan_root = "res://"
	if not target_scan_root.begins_with("res://"):
		target_scan_root = "res://"
	if not _is_dir(target_scan_root):
		return {
			"ok": false,
			"error": "Scan folder does not exist: " + target_scan_root
		}

	var obj_scan_root: String = obj_root_dir.strip_edges()
	if obj_scan_root.is_empty():
		obj_scan_root = "res://"
	if not obj_scan_root.begins_with("res://"):
		obj_scan_root = "res://"
	if not _is_dir(obj_scan_root):
		return {
			"ok": false,
			"error": "OBJ search folder does not exist: " + obj_scan_root
		}

	var obj_files: PackedStringArray = PackedStringArray()
	_collect_obj_files_recursive(obj_scan_root, obj_files)
	if obj_files.is_empty():
		return {
			"ok": false,
			"error": "No OBJ files found in scope: " + obj_scan_root,
			"scope_root": target_scan_root,
			"obj_scope_root": obj_scan_root
		}

	var obj_by_path_lower: Dictionary = {}
	var basename_to_objs: Dictionary = {}
	for obj_path in obj_files:
		obj_by_path_lower[obj_path.to_lower()] = obj_path
		var base_name: String = obj_path.get_file().get_basename().to_lower()
		if base_name.is_empty():
			continue
		if basename_to_objs.has(base_name):
			var list_existing: PackedStringArray = basename_to_objs[base_name]
			list_existing.append(obj_path)
			basename_to_objs[base_name] = list_existing
		else:
			var list_new: PackedStringArray = PackedStringArray()
			list_new.append(obj_path)
			basename_to_objs[base_name] = list_new

	if basename_to_objs.is_empty():
		return {
			"ok": false,
			"error": "No usable OBJ basenames found in scope.",
			"scope_root": target_scan_root,
			"obj_scope_root": obj_scan_root
		}

	var mesh_res_files: PackedStringArray = PackedStringArray()
	_collect_mesh_resource_files_recursive(obj_scan_root, mesh_res_files)
	var mesh_res_with_same_folder_obj: int = 0
	var mesh_res_obj_pair_set: Dictionary = {}
	for mesh_res_path in mesh_res_files:
		var candidate_obj: String = mesh_res_path.get_base_dir().path_join(mesh_res_path.get_file().get_basename() + ".obj")
		if obj_by_path_lower.has(candidate_obj.to_lower()):
			mesh_res_with_same_folder_obj += 1
			mesh_res_obj_pair_set[candidate_obj.to_lower()] = true
	var mesh_res_without_same_folder_obj: int = mesh_res_files.size() - mesh_res_with_same_folder_obj

	var duplicate_basenames: int = 0
	for key_any in basename_to_objs.keys():
		var key_name: String = str(key_any)
		var list_for_key: PackedStringArray = basename_to_objs[key_name]
		if list_for_key.size() > 1:
			duplicate_basenames += 1

	var target_files: PackedStringArray = PackedStringArray()
	_collect_project_text_resource_files_recursive(target_scan_root, target_files)
	if target_files.is_empty():
		return {
			"ok": false,
			"error": "No target text scene/resource files found in scope: " + target_scan_root,
			"scope_root": target_scan_root,
			"obj_scope_root": obj_scan_root,
			"scanned": 0,
			"updated_files": 0,
			"replacements": 0,
			"failed": 0,
			"obj_total": obj_files.size(),
			"obj_used": basename_to_objs.size(),
			"obj_duplicate_basenames": duplicate_basenames,
			"mesh_res_total_in_obj_scope": mesh_res_files.size(),
			"mesh_res_with_same_folder_obj": mesh_res_with_same_folder_obj,
			"mesh_res_without_same_folder_obj": mesh_res_without_same_folder_obj,
			"uid_cleanups": 0
		}

	var scanned: int = 0
	var updated: int = 0
	var replacements: int = 0
	var failed: int = 0
	var same_folder_matches: int = 0
	var fallback_matches: int = 0
	var uid_cleanups: int = 0
	var conflicts_missing_obj: int = 0
	var conflicts_ambiguous_fallback: int = 0
	var sample_limit: int = 64
	var conflict_samples: PackedStringArray = PackedStringArray()

	for resource_path in target_files:
		scanned += 1
		var result: Dictionary = _replace_project_resource_paths_with_obj_options(
			resource_path,
			obj_by_path_lower,
			basename_to_objs,
			mesh_res_obj_pair_set,
			dry_run,
			allow_basename_fallback and (not same_folder_only)
		)
		var ok: bool = bool(result.get("ok", false))
		var changed: bool = bool(result.get("changed", false))
		var count: int = int(result.get("count", 0))
		if not ok:
			failed += 1
			continue
		if changed:
			updated += 1
			replacements += count
			if not dry_run:
				_refresh_path(resource_path, editor_iface)
		same_folder_matches += int(result.get("same_folder_matches", 0))
		fallback_matches += int(result.get("fallback_matches", 0))
		uid_cleanups += int(result.get("uid_cleanups", 0))
		conflicts_missing_obj += int(result.get("conflicts_missing_obj", 0))
		conflicts_ambiguous_fallback += int(result.get("conflicts_ambiguous_fallback", 0))

		var sample_any: Variant = result.get("conflict_samples", PackedStringArray())
		if sample_any is PackedStringArray:
			var sample_list: PackedStringArray = sample_any
			for sample in sample_list:
				if conflict_samples.size() >= sample_limit:
					break
				conflict_samples.append(sample)

	return {
		"ok": failed == 0 and updated > 0,
		"dry_run": dry_run,
		"scope_root": target_scan_root,
		"obj_scope_root": obj_scan_root,
		"same_folder_only": same_folder_only,
		"allow_basename_fallback": allow_basename_fallback and (not same_folder_only),
		"scanned": scanned,
		"updated_files": updated,
		"replacements": replacements,
		"failed": failed,
		"obj_total": obj_files.size(),
		"obj_used": basename_to_objs.size(),
		"obj_duplicate_basenames": duplicate_basenames,
		"mesh_res_total_in_obj_scope": mesh_res_files.size(),
		"mesh_res_with_same_folder_obj": mesh_res_with_same_folder_obj,
		"mesh_res_without_same_folder_obj": mesh_res_without_same_folder_obj,
		"same_folder_matches": same_folder_matches,
		"fallback_matches": fallback_matches,
		"uid_cleanups": uid_cleanups,
		"conflicts_missing_obj": conflicts_missing_obj,
		"conflicts_ambiguous_fallback": conflicts_ambiguous_fallback,
		"conflict_samples": conflict_samples
	}


func _replace_project_resource_paths_with_obj_options(
	resource_path: String,
	obj_by_path_lower: Dictionary,
	basename_to_objs: Dictionary,
	mesh_res_obj_pair_set: Dictionary,
	dry_run: bool,
	allow_basename_fallback: bool
) -> Dictionary:
	var file: FileAccess = FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		return {"ok": false, "changed": false, "count": 0}
	var text: String = file.get_as_text()
	file.close()

	var had_newline: bool = text.ends_with("\n")
	var lines: PackedStringArray = text.split("\n")
	var changed: bool = false
	var count: int = 0
	var same_folder_matches: int = 0
	var fallback_matches: int = 0
	var uid_cleanups: int = 0
	var conflicts_missing_obj: int = 0
	var conflicts_ambiguous_fallback: int = 0
	var conflict_samples: PackedStringArray = PackedStringArray()
	var sample_limit: int = 8

	for i in range(lines.size()):
		var line: String = lines[i]
		var start_idx: int = line.find("path=\"")
		if start_idx < 0:
			continue
		var value_start: int = start_idx + 6
		var value_end: int = line.find("\"", value_start)
		if value_end <= value_start:
			continue
		var old_path: String = line.substr(value_start, value_end - value_start)
		var ext: String = old_path.get_extension().to_lower()
		if ext == "obj":
			var old_obj_key: String = old_path.to_lower()
			if mesh_res_obj_pair_set.has(old_obj_key):
				var cleaned_obj_line: String = _strip_uid_attribute(line)
				if cleaned_obj_line != line:
					lines[i] = cleaned_obj_line
					changed = true
					uid_cleanups += 1
			continue
		if ext != "tres" and ext != "res":
			continue

		var source_base_name: String = old_path.get_file().get_basename()
		if source_base_name.is_empty():
			continue
		var source_base_name_lc: String = source_base_name.to_lower()
		var same_folder_candidate: String = old_path.get_base_dir().path_join(source_base_name + ".obj")

		var replacement: String = ""
		var same_folder_key: String = same_folder_candidate.to_lower()
		if obj_by_path_lower.has(same_folder_key):
			replacement = str(obj_by_path_lower[same_folder_key])
			same_folder_matches += 1
		elif allow_basename_fallback:
			if basename_to_objs.has(source_base_name_lc):
				var fallback_paths: PackedStringArray = basename_to_objs[source_base_name_lc]
				if fallback_paths.size() == 1:
					replacement = fallback_paths[0]
					fallback_matches += 1
				else:
					conflicts_ambiguous_fallback += 1
					if conflict_samples.size() < sample_limit:
						conflict_samples.append(
							"%s :: %s -> ambiguous basename (%d OBJ matches)" % [
								resource_path,
								old_path,
								fallback_paths.size()
							]
						)
			else:
				conflicts_missing_obj += 1
				if conflict_samples.size() < sample_limit:
					conflict_samples.append(
						"%s :: %s -> missing OBJ in same folder and no basename fallback match" % [
							resource_path,
							old_path
						]
					)
		else:
			conflicts_missing_obj += 1
			if conflict_samples.size() < sample_limit:
				conflict_samples.append(
					"%s :: %s -> missing OBJ in same folder" % [resource_path, old_path]
				)

		if replacement.is_empty() or replacement == old_path:
			continue

		line = _replace_path_and_strip_uid(line, value_start, value_end, replacement)
		lines[i] = line
		changed = true
		count += 1

	if not changed:
		return {
			"ok": true,
			"changed": false,
			"count": 0,
			"same_folder_matches": same_folder_matches,
			"fallback_matches": fallback_matches,
			"uid_cleanups": uid_cleanups,
			"conflicts_missing_obj": conflicts_missing_obj,
			"conflicts_ambiguous_fallback": conflicts_ambiguous_fallback,
			"conflict_samples": conflict_samples
		}

	if dry_run:
		return {
			"ok": true,
			"changed": true,
			"count": count,
			"same_folder_matches": same_folder_matches,
			"fallback_matches": fallback_matches,
			"uid_cleanups": uid_cleanups,
			"conflicts_missing_obj": conflicts_missing_obj,
			"conflicts_ambiguous_fallback": conflicts_ambiguous_fallback,
			"conflict_samples": conflict_samples
		}

	var output: String = "\n".join(lines)
	if had_newline:
		output += "\n"

	var out_file: FileAccess = FileAccess.open(resource_path, FileAccess.WRITE)
	if out_file == null:
		return {"ok": false, "changed": false, "count": 0}
	out_file.store_string(output)
	out_file.close()
	return {
		"ok": true,
		"changed": true,
		"count": count,
		"same_folder_matches": same_folder_matches,
		"fallback_matches": fallback_matches,
		"uid_cleanups": uid_cleanups,
		"conflicts_missing_obj": conflicts_missing_obj,
		"conflicts_ambiguous_fallback": conflicts_ambiguous_fallback,
		"conflict_samples": conflict_samples
	}


func _replace_scene_paths(scene_path: String, mapping: Dictionary) -> Dictionary:
	var file: FileAccess = FileAccess.open(scene_path, FileAccess.READ)
	if file == null:
		return {"ok": false, "changed": false, "count": 0}
	var text: String = file.get_as_text()
	file.close()

	var had_newline: bool = text.ends_with("\n")
	var lines: PackedStringArray = text.split("\n")
	var changed: bool = false
	var count: int = 0

	for i in range(lines.size()):
		var line: String = lines[i]
		var start_idx: int = line.find("path=\"")
		if start_idx < 0:
			continue
		var value_start: int = start_idx + 6
		var value_end: int = line.find("\"", value_start)
		if value_end <= value_start:
			continue
		var old_path: String = line.substr(value_start, value_end - value_start)
		var ext: String = old_path.get_extension().to_lower()
		if ext != "tres" and ext != "res":
			continue
		var base_name: String = old_path.get_file().get_basename().to_lower()
		if not mapping.has(base_name):
			continue
		var new_path: String = str(mapping[base_name])
		if new_path == old_path:
			continue
		line = _replace_path_and_strip_uid(line, value_start, value_end, new_path)
		lines[i] = line
		changed = true
		count += 1

	if not changed:
		return {"ok": true, "changed": false, "count": 0}

	var output: String = "\n".join(lines)
	if had_newline:
		output += "\n"

	var out_file: FileAccess = FileAccess.open(scene_path, FileAccess.WRITE)
	if out_file == null:
		return {"ok": false, "changed": false, "count": 0}
	out_file.store_string(output)
	out_file.close()
	return {"ok": true, "changed": true, "count": count}


func _collect_scene_files_recursive(dir_path: String, out: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name.is_empty():
			break
		if name.begins_with("."):
			continue
		var full: String = dir_path.path_join(name)
		if dir.current_is_dir():
			if name == ".godot":
				continue
			_collect_scene_files_recursive(full, out)
		elif full.get_extension().to_lower() == "tscn":
			out.append(full)
	dir.list_dir_end()


func _collect_obj_files_recursive(dir_path: String, out: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name.is_empty():
			break
		if name.begins_with("."):
			continue
		var full: String = dir_path.path_join(name)
		if dir.current_is_dir():
			if name == ".godot":
				continue
			_collect_obj_files_recursive(full, out)
		elif full.get_extension().to_lower() == SUPPORTED_OBJ_EXT:
			out.append(full)
	dir.list_dir_end()


func _collect_project_text_resource_files_recursive(dir_path: String, out: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name.is_empty():
			break
		if name.begins_with("."):
			continue
		var full: String = dir_path.path_join(name)
		if dir.current_is_dir():
			if name == ".godot":
				continue
			_collect_project_text_resource_files_recursive(full, out)
		else:
			var ext: String = full.get_extension().to_lower()
			if ext == "tscn":
				out.append(full)
			elif (ext == "tres" or ext == "res") and _is_text_resource(full):
				out.append(full)
	dir.list_dir_end()


func _collect_mesh_resource_files_recursive(dir_path: String, out: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name.is_empty():
			break
		if name.begins_with("."):
			continue
		var full: String = dir_path.path_join(name)
		if dir.current_is_dir():
			if name == ".godot":
				continue
			_collect_mesh_resource_files_recursive(full, out)
		else:
			var ext: String = full.get_extension().to_lower()
			if ext == "tres" or ext == "res":
				out.append(full)
	dir.list_dir_end()


func _is_text_resource(path: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var sample: String = file.get_as_text().substr(0, 128)
	file.close()
	if sample.begins_with("[gd_resource") or sample.begins_with("[gd_scene") or sample.begins_with(";"):
		return true
	return false


func _expand_paths(paths: PackedStringArray) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for path in paths:
		if path.ends_with(".import") or path.ends_with(".uid"):
			continue
		if _is_dir(path):
			_collect_files_recursive(path, out)
		else:
			out.append(path)
	return out


func _is_dir(path: String) -> bool:
	if path.is_empty():
		return false
	var abs_path: String = ProjectSettings.globalize_path(path)
	return DirAccess.dir_exists_absolute(abs_path)


func _collect_files_recursive(dir_path: String, out: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name.is_empty():
			break
		if name.begins_with("."):
			continue
		var full: String = dir_path.path_join(name)
		if dir.current_is_dir():
			_collect_files_recursive(full, out)
		else:
			out.append(full)
	dir.list_dir_end()


func _refresh_path(path: String, editor_iface: EditorInterface) -> void:
	if editor_iface == null:
		return
	var fs: EditorFileSystem = editor_iface.get_resource_filesystem()
	if fs == null:
		return
	fs.update_file(path)


func _build_obj_text(mesh: Mesh, object_name: String) -> String:
	var export_data: Dictionary = _build_obj_and_mtl_text(mesh, object_name, "")
	return str(export_data.get("obj", ""))


func _build_obj_and_mtl_text(mesh: Mesh, object_name: String, mtl_file_name: String) -> Dictionary:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("# Densetsu Tool Suite OBJ Export")
	lines.append("o " + _sanitize_obj_name(object_name))

	var vertex_offset: int = 0
	var uv_offset: int = 0
	var normal_offset: int = 0
	var wrote_faces: bool = false
	var material_name_by_key: Dictionary = {}
	var used_material_names: Dictionary = {}
	var ordered_material_names: PackedStringArray = PackedStringArray()
	var ordered_materials: Array[Material] = []

	for surface_idx in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface_idx)
		if arrays.is_empty():
			continue

		var vertices: PackedVector3Array = _as_packed_vector3_array(_get_surface_array_slot(arrays, Mesh.ARRAY_VERTEX))
		if vertices.is_empty():
			continue

		var normals: PackedVector3Array = _as_packed_vector3_array(_get_surface_array_slot(arrays, Mesh.ARRAY_NORMAL))
		var uvs: PackedVector2Array = _as_packed_vector2_array(_get_surface_array_slot(arrays, Mesh.ARRAY_TEX_UV))
		var indices: PackedInt32Array = _as_packed_int32_array(_get_surface_array_slot(arrays, Mesh.ARRAY_INDEX))
		var primitive: int = _get_surface_primitive_type(mesh, surface_idx)
		var triangles: PackedInt32Array = _build_triangle_indices(primitive, vertices.size(), indices)
		if triangles.is_empty():
			continue

		var has_uv: bool = (not uvs.is_empty()) and (uvs.size() == vertices.size())
		var has_normal: bool = (not normals.is_empty()) and (normals.size() == vertices.size())
		var surface_material: Material = mesh.surface_get_material(surface_idx)
		var surface_material_name: String = _resolve_material_name(
			surface_material,
			surface_idx,
			material_name_by_key,
			used_material_names,
			ordered_material_names,
			ordered_materials
		)

		lines.append("g surface_%d" % surface_idx)
		lines.append("usemtl " + surface_material_name)
		for v in vertices:
			lines.append("v %.6f %.6f %.6f" % [v.x, v.y, v.z])
		if has_uv:
			for uv in uvs:
				var uv_y: float = 1.0 - uv.y if FLIP_V_TEXCOORD else uv.y
				lines.append("vt %.6f %.6f" % [uv.x, uv_y])
		if has_normal:
			for n in normals:
				lines.append("vn %.6f %.6f %.6f" % [n.x, n.y, n.z])

		for tri_idx in range(0, triangles.size(), 3):
			var a: int = triangles[tri_idx]
			var b: int = triangles[tri_idx + 1]
			var c: int = triangles[tri_idx + 2]
			if a < 0 or b < 0 or c < 0:
				continue
			if a >= vertices.size() or b >= vertices.size() or c >= vertices.size():
				continue
			var face_b: int = b
			var face_c: int = c
			# Godot surface winding is opposite to what most OBJ consumers treat as front-facing.
			# Swap b/c to preserve outward-facing surfaces after export.
			if FLIP_FACE_WINDING_FOR_OBJ:
				face_b = c
				face_c = b
			lines.append("f %s %s %s" % [
				_face_token(a, vertex_offset, uv_offset, normal_offset, has_uv, has_normal),
				_face_token(face_b, vertex_offset, uv_offset, normal_offset, has_uv, has_normal),
				_face_token(face_c, vertex_offset, uv_offset, normal_offset, has_uv, has_normal)
			])
			wrote_faces = true

		vertex_offset += vertices.size()
		if has_uv:
			uv_offset += uvs.size()
		if has_normal:
			normal_offset += normals.size()

	if not wrote_faces:
		return {
			"obj": "",
			"mtl": ""
		}

	var mtl_text: String = _build_mtl_text(ordered_material_names, ordered_materials)
	if not mtl_text.is_empty() and not mtl_file_name.is_empty():
		lines.insert(2, "mtllib " + _escape_mtl_path(mtl_file_name))

	return {
		"obj": "\n".join(lines) + "\n",
		"mtl": mtl_text
	}


func _resolve_material_name(
	material: Material,
	surface_idx: int,
	material_name_by_key: Dictionary,
	used_material_names: Dictionary,
	ordered_material_names: PackedStringArray,
	ordered_materials: Array[Material]
) -> String:
	var material_key: String = _material_key(material, surface_idx)
	if material_name_by_key.has(material_key):
		return str(material_name_by_key[material_key])

	var base_name: String = ""
	if material != null:
		if not material.resource_name.strip_edges().is_empty():
			base_name = material.resource_name.strip_edges()
		elif not material.resource_path.strip_edges().is_empty():
			base_name = material.resource_path.get_file().get_basename()
	if base_name.is_empty():
		base_name = "surface_%d" % surface_idx

	var sanitized_base: String = _sanitize_obj_name(base_name)
	if sanitized_base.is_empty():
		sanitized_base = "material"
	var unique_name: String = _ensure_unique_material_name(sanitized_base, used_material_names)
	material_name_by_key[material_key] = unique_name
	ordered_material_names.append(unique_name)
	ordered_materials.append(material)
	return unique_name


func _material_key(material: Material, surface_idx: int) -> String:
	if material == null:
		return "null_surface_%d" % surface_idx
	if not material.resource_path.strip_edges().is_empty():
		return "path:%s" % material.resource_path
	return "id:%d" % material.get_instance_id()


func _ensure_unique_material_name(base_name: String, used_material_names: Dictionary) -> String:
	var candidate: String = base_name
	var suffix: int = 1
	while used_material_names.has(candidate):
		candidate = "%s_%d" % [base_name, suffix]
		suffix += 1
	used_material_names[candidate] = true
	return candidate


func _build_mtl_text(material_names: PackedStringArray, materials: Array[Material]) -> String:
	if material_names.is_empty():
		return ""
	var lines: PackedStringArray = PackedStringArray()
	lines.append("# Densetsu Tool Suite MTL Export")
	for i in range(material_names.size()):
		lines.append("")
		var material_name: String = material_names[i]
		var material: Material = materials[i] if i < materials.size() else null
		_append_material_block(lines, material_name, material)
	return "\n".join(lines) + "\n"


func _append_material_block(lines: PackedStringArray, material_name: String, material: Material) -> void:
	lines.append("newmtl " + material_name)

	var kd: Color = Color(0.8, 0.8, 0.8, 1.0)
	var ks: Color = Color(0.04, 0.04, 0.04, 1.0)
	var ke: Color = Color(0.0, 0.0, 0.0, 1.0)
	var ns: float = 32.0
	var alpha: float = 1.0
	var illum: int = 2

	var map_kd: String = ""
	var map_ks: String = ""
	var map_bump: String = ""
	var map_ke: String = ""

	if material is BaseMaterial3D:
		var base_material: BaseMaterial3D = material as BaseMaterial3D
		kd = base_material.albedo_color
		alpha = clampf(kd.a, 0.0, 1.0)
		var metallic: float = _safe_get_float_property(base_material, "metallic", 0.0)
		var roughness: float = _safe_get_float_property(base_material, "roughness", 1.0)
		var specular_scalar: float = _safe_get_float_property(base_material, "metallic_specular", 0.5)
		var ks_scalar: float = clampf(max(metallic, specular_scalar * 0.25), 0.0, 1.0)
		ks = Color(ks_scalar, ks_scalar, ks_scalar, 1.0)
		ns = clampf((1.0 - roughness) * 1000.0, 1.0, 1000.0)

		var emission_enabled: bool = _safe_get_bool_property(base_material, "emission_enabled", false)
		if emission_enabled:
			ke = base_material.emission
			if ke.r > 0.0001 or ke.g > 0.0001 or ke.b > 0.0001:
				illum = 2

		map_kd = _texture_to_mtl_path(_safe_get_texture_property(base_material, "albedo_texture"))
		map_ks = _texture_to_mtl_path(_safe_get_texture_property(base_material, "orm_texture"))
		map_bump = _texture_to_mtl_path(_safe_get_texture_property(base_material, "normal_texture"))
		map_ke = _texture_to_mtl_path(_safe_get_texture_property(base_material, "emission_texture"))

	lines.append("Kd %.6f %.6f %.6f" % [kd.r, kd.g, kd.b])
	lines.append("Ks %.6f %.6f %.6f" % [ks.r, ks.g, ks.b])
	lines.append("Ns %.6f" % ns)
	lines.append("d %.6f" % alpha)
	lines.append("illum %d" % illum)
	if ke.r > 0.0001 or ke.g > 0.0001 or ke.b > 0.0001:
		lines.append("Ke %.6f %.6f %.6f" % [ke.r, ke.g, ke.b])
	if not map_kd.is_empty():
		lines.append("map_Kd " + _escape_mtl_path(map_kd))
	if not map_ks.is_empty():
		lines.append("map_Ks " + _escape_mtl_path(map_ks))
	if not map_bump.is_empty():
		lines.append("map_bump " + _escape_mtl_path(map_bump))
	if not map_ke.is_empty():
		lines.append("map_Ke " + _escape_mtl_path(map_ke))


func _safe_get_float_property(obj: Object, property_name: String, fallback: float) -> float:
	if obj == null:
		return fallback
	if not _object_has_property(obj, property_name):
		return fallback
	var value: Variant = obj.get(property_name)
	if value is float or value is int:
		return float(value)
	return fallback


func _safe_get_bool_property(obj: Object, property_name: String, fallback: bool) -> bool:
	if obj == null:
		return fallback
	if not _object_has_property(obj, property_name):
		return fallback
	var value: Variant = obj.get(property_name)
	if value is bool:
		return bool(value)
	return fallback


func _safe_get_texture_property(obj: Object, property_name: String) -> Texture2D:
	if obj == null:
		return null
	if not _object_has_property(obj, property_name):
		return null
	var value: Variant = obj.get(property_name)
	if value is Texture2D:
		return value as Texture2D
	return null


func _object_has_property(obj: Object, property_name: String) -> bool:
	if obj == null:
		return false
	var property_list: Array = obj.get_property_list()
	for prop_any in property_list:
		if prop_any is Dictionary:
			var prop: Dictionary = prop_any
			var name_any: Variant = prop.get("name", "")
			var name: String = str(name_any)
			if name == property_name:
				return true
	return false


func _texture_to_mtl_path(texture: Texture2D) -> String:
	if texture == null:
		return ""
	var res_path: String = texture.resource_path.strip_edges()
	if res_path.is_empty():
		return ""
	var normalized_path: String = res_path
	if res_path.begins_with("res://") or res_path.begins_with("user://"):
		normalized_path = ProjectSettings.globalize_path(res_path)
	return normalized_path.replace("\\", "/")


func _escape_mtl_path(path: String) -> String:
	return path.replace(" ", "\\ ")


func _get_surface_primitive_type(mesh: Mesh, surface_idx: int) -> int:
	if mesh.has_method("surface_get_primitive_type"):
		return int(mesh.call("surface_get_primitive_type", surface_idx))
	return Mesh.PRIMITIVE_TRIANGLES


func _build_triangle_indices(primitive: int, vertex_count: int, indices: PackedInt32Array) -> PackedInt32Array:
	var source: PackedInt32Array = PackedInt32Array()
	if indices.is_empty():
		source.resize(vertex_count)
		for i in range(vertex_count):
			source[i] = i
	else:
		source = indices

	var out: PackedInt32Array = PackedInt32Array()
	match primitive:
		Mesh.PRIMITIVE_TRIANGLES:
			var tri_end: int = source.size() - (source.size() % 3)
			for i in range(0, tri_end, 3):
				out.push_back(source[i])
				out.push_back(source[i + 1])
				out.push_back(source[i + 2])
		Mesh.PRIMITIVE_TRIANGLE_STRIP:
			for i in range(2, source.size()):
				var a: int = source[i - 2]
				var b: int = source[i - 1]
				var c: int = source[i]
				if a == b or b == c or a == c:
					continue
				if (i % 2) == 0:
					out.push_back(a)
					out.push_back(b)
					out.push_back(c)
				else:
					out.push_back(b)
					out.push_back(a)
					out.push_back(c)
		_:
			return PackedInt32Array()
	return out


func _get_surface_array_slot(arrays: Array, slot_index: int) -> Variant:
	if slot_index < 0 or slot_index >= arrays.size():
		return null
	return arrays[slot_index]


func _as_packed_vector3_array(value: Variant) -> PackedVector3Array:
	if value is PackedVector3Array:
		return value as PackedVector3Array
	return PackedVector3Array()


func _as_packed_vector2_array(value: Variant) -> PackedVector2Array:
	if value is PackedVector2Array:
		return value as PackedVector2Array
	return PackedVector2Array()


func _as_packed_int32_array(value: Variant) -> PackedInt32Array:
	if value is PackedInt32Array:
		return value as PackedInt32Array
	return PackedInt32Array()


func _face_token(local_index: int, vertex_offset: int, uv_offset: int, normal_offset: int, has_uv: bool, has_normal: bool) -> String:
	var v_idx: int = vertex_offset + local_index + 1
	if has_uv and has_normal:
		var t_idx: int = uv_offset + local_index + 1
		var n_idx: int = normal_offset + local_index + 1
		return "%d/%d/%d" % [v_idx, t_idx, n_idx]
	if has_uv:
		var uv_idx: int = uv_offset + local_index + 1
		return "%d/%d" % [v_idx, uv_idx]
	if has_normal:
		var normal_idx: int = normal_offset + local_index + 1
		return "%d//%d" % [v_idx, normal_idx]
	return str(v_idx)


func _sanitize_obj_name(value: String) -> String:
	var clean: String = value.strip_edges()
	if clean.is_empty():
		return "MeshExport"
	return clean.replace(" ", "_")


func _replace_path_and_strip_uid(line: String, value_start: int, value_end: int, new_path: String) -> String:
	var updated: String = line.substr(0, value_start) + new_path + line.substr(value_end)
	return _strip_uid_attribute(updated)


func _strip_uid_attribute(line: String) -> String:
	var uid_key: String = "uid=\""
	var uid_pos: int = line.find(uid_key)
	if uid_pos < 0:
		return line
	var attr_start: int = uid_pos
	if attr_start > 0 and line.substr(attr_start - 1, 1) == " ":
		attr_start -= 1
	var value_start: int = uid_pos + uid_key.length()
	var value_end: int = line.find("\"", value_start)
	if value_end < value_start:
		return line
	return line.substr(0, attr_start) + line.substr(value_end + 1)


func _ensure_output_dir(path: String) -> void:
	var dir_path: String = path.get_base_dir()
	if dir_path.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
