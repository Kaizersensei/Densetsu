@tool
extends RefCounted

const MODE_CENTER_MASS := 0
const MODE_CENTER_BOTTOM := 1
const MESH_OBJ_HELPER_SCRIPT: Script = preload("res://addons/densetsu_tool_suite/helpers/mesh_obj_helper.gd")

const SUPPORTED_EXTS := [
	"obj", "fbx", "glb", "gltf", "blend", "dae", "tres", "res", "tscn"
]
var _mesh_obj_helper: RefCounted


func reassign_pivot_paths(paths: PackedStringArray, mode: int, editor_iface: EditorInterface = null) -> Dictionary:
	if paths.is_empty():
		return {
			"ok": false,
			"error": "No paths selected."
		}

	var files := _expand_paths(paths)
	var processed: int = 0
	var failed: int = 0

	for file_path in files:
		if not _is_supported_path(file_path):
			continue
		var ok := _process_resource(file_path, mode, editor_iface)
		if ok:
			processed += 1
		else:
			failed += 1

	return {
		"ok": processed > 0 and failed == 0,
		"processed": processed,
		"failed": failed
	}


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
	return DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path))


func _collect_files_recursive(dir_path: String, out: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if name.begins_with("."):
			continue
		var full := dir_path.path_join(name)
		if dir.current_is_dir():
			_collect_files_recursive(full, out)
		else:
			out.append(full)
	dir.list_dir_end()


func _is_supported_path(path: String) -> bool:
	if path.is_empty():
		return false
	return SUPPORTED_EXTS.has(path.get_extension().to_lower())


func _process_resource(file_path: String, mode: int, editor_iface: EditorInterface) -> bool:
	var res := ResourceLoader.load(file_path)
	if res == null:
		push_warning("Pivot Reassign: failed to load %s" % file_path)
		return false

	var ext := file_path.get_extension().to_lower()
	if res is PackedScene:
		var inst := (res as PackedScene).instantiate()
		var ok := _process_scene_meshes(inst, file_path, mode, ext, editor_iface)
		inst.free()
		return ok

	if res is Mesh:
		return _process_mesh_resource(res as Mesh, file_path, mode, "mesh", ext, editor_iface)

	push_warning("Pivot Reassign: unsupported resource type %s" % file_path)
	return false


func _process_scene_meshes(inst: Node, file_path: String, mode: int, src_ext: String, editor_iface: EditorInterface) -> bool:
	var meshes: Array = inst.find_children("*", "MeshInstance3D", true, false)
	if meshes.is_empty():
		push_warning("Pivot Reassign: no MeshInstance3D in %s" % file_path)
		return false

	var ok_any := false
	for node in meshes:
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var ok := _process_mesh_resource(mi.mesh, file_path, mode, mi.name, src_ext, editor_iface, mi)
		ok_any = ok_any or ok
	return ok_any


func _process_mesh_resource(mesh: Mesh, file_path: String, mode: int, mesh_name: String, src_ext: String, editor_iface: EditorInterface, source_mesh_instance: MeshInstance3D = null) -> bool:
	var pivot := _compute_pivot(mesh, mode)
	if src_ext == "obj":
		var rewrote := _rewrite_obj_vertices(file_path, pivot)
		if rewrote:
			_refresh_path(file_path, editor_iface, true)
			print("Pivot Reassign: rewrote OBJ in place ", file_path)
		else:
			push_warning("Pivot Reassign: failed to rewrite OBJ %s" % file_path)
		return rewrote

	var adjusted := _offset_mesh(mesh, pivot, source_mesh_instance)
	if adjusted == null:
		push_warning("Pivot Reassign: failed to offset mesh %s" % file_path)
		return false

	var out_path := _make_output_path(file_path, mesh_name)
	var helper: RefCounted = _get_mesh_obj_helper()
	if helper == null:
		push_warning("Pivot Reassign: OBJ helper unavailable.")
		return false
	var ok: bool = bool(helper.call("export_mesh_to_obj", adjusted, out_path, mesh_name))
	if not ok:
		push_warning("Pivot Reassign: failed to save OBJ %s" % out_path)
		return false

	_refresh_path(out_path, editor_iface, false)
	var mtl_path: String = out_path.get_base_dir().path_join(out_path.get_file().get_basename() + ".mtl")
	if FileAccess.file_exists(mtl_path):
		_refresh_path(mtl_path, editor_iface, false)
	print("Pivot Reassign: saved adjusted OBJ ", out_path)
	return true


func _refresh_path(path: String, editor_iface: EditorInterface, reimport: bool) -> void:
	if editor_iface == null:
		return
	var fs := editor_iface.get_resource_filesystem()
	if fs == null:
		return
	fs.update_file(path)
	if reimport:
		fs.reimport_files(PackedStringArray([path]))


func _compute_pivot(mesh: Mesh, mode: int) -> Vector3:
	match mode:
		MODE_CENTER_MASS:
			return _compute_center_mass(mesh)
		MODE_CENTER_BOTTOM:
			return _compute_center_bottom(mesh)
		_:
			return _compute_center_mass(mesh)


func _compute_center_mass(mesh: Mesh) -> Vector3:
	var total := Vector3.ZERO
	var count: int = 0
	for i in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(i)
		if arrays.is_empty():
			continue
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for v in verts:
			total += v
			count += 1
	if count == 0:
		return Vector3.ZERO
	return total / float(count)


func _compute_center_bottom(mesh: Mesh) -> Vector3:
	var total_xz := Vector3.ZERO
	var count: int = 0
	var min_y := INF
	for i in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(i)
		if arrays.is_empty():
			continue
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for v in verts:
			total_xz += Vector3(v.x, 0.0, v.z)
			count += 1
			if v.y < min_y:
				min_y = v.y
	if count == 0:
		return Vector3.ZERO
	var avg_xz := total_xz / float(count)
	return Vector3(avg_xz.x, min_y, avg_xz.z)


func _offset_mesh(mesh: Mesh, pivot: Vector3, source_mesh_instance: MeshInstance3D = null) -> ArrayMesh:
	var out := ArrayMesh.new()
	for i in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(i)
		if arrays.is_empty():
			continue
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for v in range(verts.size()):
			verts[v] -= pivot
		arrays[Mesh.ARRAY_VERTEX] = verts
		var blend_shapes: Array = mesh.surface_get_blend_shape_arrays(i)
		out.add_surface_from_arrays(mesh.surface_get_primitive_type(i), arrays, blend_shapes)
		var mat: Material = null
		if source_mesh_instance != null:
			mat = source_mesh_instance.get_surface_override_material(i)
		if mat == null:
			mat = mesh.surface_get_material(i)
		if mat != null:
			out.surface_set_material(out.get_surface_count() - 1, mat)
	if source_mesh_instance != null and source_mesh_instance.material_override != null:
		for i in range(out.get_surface_count()):
			out.surface_set_material(i, source_mesh_instance.material_override)
	return out


func _make_output_path(file_path: String, mesh_name: String) -> String:
	var base_dir := file_path.get_base_dir()
	var base_name := file_path.get_file().get_basename()
	var safe_mesh := _sanitize(mesh_name)
	if safe_mesh.is_empty():
		safe_mesh = "mesh"
	return base_dir.path_join("%s_%s_pivot.obj" % [base_name, safe_mesh])


func _get_mesh_obj_helper() -> RefCounted:
	if _mesh_obj_helper == null and MESH_OBJ_HELPER_SCRIPT != null:
		_mesh_obj_helper = MESH_OBJ_HELPER_SCRIPT.new()
	return _mesh_obj_helper


func _sanitize(text: String) -> String:
	var out := text.replace(" ", "_")
	out = out.replace("/", "_")
	out = out.replace("\\", "_")
	out = out.replace(":", "_")
	out = out.replace(".", "_")
	return out


func _rewrite_obj_vertices(file_path: String, pivot: Vector3) -> bool:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return false
	var lines := file.get_as_text().split("\n")
	file.close()

	var new_lines: Array[String] = []
	for line in lines:
		if line.begins_with("v "):
			var parts := line.split(" ", true)
			if parts.size() >= 4:
				var v := Vector3(parts[1].to_float(), parts[2].to_float(), parts[3].to_float())
				v -= pivot
				new_lines.append("v %f %f %f" % [v.x, v.y, v.z])
				continue
		new_lines.append(line)

	var output_file := FileAccess.open(file_path, FileAccess.WRITE)
	if output_file == null:
		return false
	for new_line in new_lines:
		output_file.store_line(new_line)
	output_file.close()
	return true
