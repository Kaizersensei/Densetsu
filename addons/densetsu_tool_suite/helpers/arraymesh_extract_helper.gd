@tool
extends EditorPlugin

const MESH_OBJ_HELPER_SCRIPT: Script = preload("res://addons/densetsu_tool_suite/helpers/mesh_obj_helper.gd")
var SUPPORTED_EXTS: PackedStringArray = PackedStringArray(["fbx", "glb", "gltf", "blend", "obj", "dae", "tres", "res"])
const OUT_SUBDIR: String = "_arraymeshes"
const OUTPUT_PER_FILE := 0
const OUTPUT_COMMON := 1
const MODE_BY_MESH := 0
const MODE_BY_MATERIAL := 1
const MODE_COMBINED := 2

var bake_transforms: bool = true
var overwrite_existing: bool = true
var use_subdir: bool = true
var _ctx_plugin: EditorContextMenuPlugin
var _mesh_obj_helper: RefCounted


class _ArrayMeshContextMenuPlugin:
	extends EditorContextMenuPlugin
	var _owner: EditorPlugin

	func _init(owner: EditorPlugin) -> void:
		_owner = owner

	func _popup_menu(paths: PackedStringArray) -> void:
		if paths.is_empty():
			return
		add_context_menu_item("Extract ArrayMeshes (Per File Folder)", Callable(_owner, "_on_extract_paths_from_context"))
		add_context_menu_item("Extract ArrayMeshes (Common Folder)", Callable(_owner, "_on_extract_paths_from_context_common"))
		add_context_menu_item("Extract Material Meshes (Per File Folder)", Callable(_owner, "_on_extract_material_paths_from_context"))
		add_context_menu_item("Extract Material Meshes (Common Folder)", Callable(_owner, "_on_extract_material_paths_from_context_common"))
		add_context_menu_item("Extract Combined ArrayMesh (Per File Folder)", Callable(_owner, "_on_extract_combined_paths_from_context"))
		add_context_menu_item("Extract Combined ArrayMesh (Common Folder)", Callable(_owner, "_on_extract_combined_paths_from_context_common"))


func _enter_tree() -> void:
	add_tool_menu_item("Extract ArrayMeshes (Selected)", _on_extract_selected)
	add_tool_menu_item("Extract ArrayMeshes (Common Folder)", _on_extract_selected_common)
	add_tool_menu_item("Extract Material Meshes (Selected)", _on_extract_selected_materials)
	add_tool_menu_item("Extract Material Meshes (Common Folder)", _on_extract_selected_materials_common)
	add_tool_menu_item("Extract Combined ArrayMesh (Selected)", _on_extract_selected_combined)
	add_tool_menu_item("Extract Combined ArrayMesh (Common Folder)", _on_extract_selected_combined_common)
	_ctx_plugin = _ArrayMeshContextMenuPlugin.new(self)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _ctx_plugin)


func _exit_tree() -> void:
	remove_tool_menu_item("Extract ArrayMeshes (Selected)")
	remove_tool_menu_item("Extract ArrayMeshes (Common Folder)")
	remove_tool_menu_item("Extract Material Meshes (Selected)")
	remove_tool_menu_item("Extract Material Meshes (Common Folder)")
	remove_tool_menu_item("Extract Combined ArrayMesh (Selected)")
	remove_tool_menu_item("Extract Combined ArrayMesh (Common Folder)")
	if _ctx_plugin:
		remove_context_menu_plugin(_ctx_plugin)
		_ctx_plugin = null


func _on_extract_selected() -> void:
	var paths: PackedStringArray = _get_filesystem_selection()
	_extract_paths(paths, MODE_BY_MESH, OUTPUT_PER_FILE)


func _on_extract_selected_common() -> void:
	var paths: PackedStringArray = _get_filesystem_selection()
	_extract_paths(paths, MODE_BY_MESH, OUTPUT_COMMON)


func _on_extract_paths_from_context(paths: PackedStringArray = PackedStringArray()) -> void:
	_extract_paths(paths, MODE_BY_MESH, OUTPUT_PER_FILE)


func _on_extract_paths_from_context_common(paths: PackedStringArray = PackedStringArray()) -> void:
	_extract_paths(paths, MODE_BY_MESH, OUTPUT_COMMON)


func _on_extract_selected_materials() -> void:
	var paths: PackedStringArray = _get_filesystem_selection()
	_extract_paths(paths, MODE_BY_MATERIAL, OUTPUT_PER_FILE)


func _on_extract_selected_materials_common() -> void:
	var paths: PackedStringArray = _get_filesystem_selection()
	_extract_paths(paths, MODE_BY_MATERIAL, OUTPUT_COMMON)


func _on_extract_material_paths_from_context(paths: PackedStringArray = PackedStringArray()) -> void:
	_extract_paths(paths, MODE_BY_MATERIAL, OUTPUT_PER_FILE)


func _on_extract_material_paths_from_context_common(paths: PackedStringArray = PackedStringArray()) -> void:
	_extract_paths(paths, MODE_BY_MATERIAL, OUTPUT_COMMON)


func _on_extract_selected_combined() -> void:
	var paths: PackedStringArray = _get_filesystem_selection()
	_extract_paths(paths, MODE_COMBINED, OUTPUT_PER_FILE)


func _on_extract_selected_combined_common() -> void:
	var paths: PackedStringArray = _get_filesystem_selection()
	_extract_paths(paths, MODE_COMBINED, OUTPUT_COMMON)


func _on_extract_combined_paths_from_context(paths: PackedStringArray = PackedStringArray()) -> void:
	_extract_paths(paths, MODE_COMBINED, OUTPUT_PER_FILE)


func _on_extract_combined_paths_from_context_common(paths: PackedStringArray = PackedStringArray()) -> void:
	_extract_paths(paths, MODE_COMBINED, OUTPUT_COMMON)


func _extract_paths(paths: PackedStringArray, mode: int, output_mode: int) -> void:
	if paths.is_empty():
		push_warning("Select model files or folders in the FileSystem dock first.")
		return
	print("ArrayMesh extract: selected paths:", paths, "mode=", mode, "output_mode=", output_mode)
	var files: PackedStringArray = _expand_paths(paths)
	for path in files:
		if not _is_supported(path):
			print("ArrayMesh extract: skip unsupported:", path)
			continue
		_extract_from_file(path, mode, output_mode)


func _get_filesystem_selection() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var iface := get_editor_interface()
	if iface and iface.has_method("get_selected_paths"):
		var sel_any := iface.call("get_selected_paths")
		if sel_any is PackedStringArray:
			out = sel_any
		elif sel_any is Array:
			for p in sel_any:
				out.append(String(p))
	if out.size() > 0:
		return out
	var dock := iface.get_file_system_dock() if iface else null
	if dock == null:
		return out
	if dock.has_method("get_selected_paths"):
		var sel_paths: Variant = dock.get_selected_paths()
		if sel_paths is PackedStringArray:
			return sel_paths
		if sel_paths is Array:
			for p in sel_paths:
				out.append(String(p))
			return out
	if dock.has_method("get_selected_files"):
		var sel_files: Variant = dock.get_selected_files()
		if sel_files is PackedStringArray:
			return sel_files
		if sel_files is Array:
			for p in sel_files:
				out.append(String(p))
			return out
	if dock.has_method("get_selected_file"):
		var single: Variant = dock.get_selected_file()
		if single is String and single != "":
			out.append(single)
	return out


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
	if path == "":
		return false
	var abs := ProjectSettings.globalize_path(path)
	return DirAccess.dir_exists_absolute(abs)


func _collect_files_recursive(dir_path: String, out: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
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
			_collect_files_recursive(full, out)
		else:
			out.append(full)
	dir.list_dir_end()


func _is_supported(path: String) -> bool:
	var ext := path.get_extension().to_lower()
	return SUPPORTED_EXTS.has(ext)


func _extract_from_file(path: String, mode: int, output_mode: int) -> void:
	print("ArrayMesh extract: loading:", path)
	var ext := path.get_extension().to_lower()
	var res := ResourceLoader.load(path)
	if res == null:
		push_warning("Failed to load: " + path)
		print("ArrayMesh extract: load returned null for:", path)
		var fallback := _try_load_imported_resource(path)
		if fallback == null:
			print("ArrayMesh extract: no fallback import resource found for:", path)
			return
		print("ArrayMesh extract: using imported fallback for:", path)
		res = fallback
	var base_dir := path.get_base_dir()
	var out_dir := base_dir
	if use_subdir:
		if output_mode == OUTPUT_COMMON:
			out_dir = base_dir.path_join(OUT_SUBDIR)
		else:
			out_dir = base_dir.path_join(_sanitize(path.get_file().get_basename()))
		_ensure_dir(out_dir)
	print("ArrayMesh extract: out_dir:", out_dir)
	if res is PackedScene:
		var inst: Node = res.instantiate()
		_extract_from_scene(inst, path, out_dir, mode)
		inst.free()
		return
	if res is Mesh:
		var mesh := res as Mesh
		if mode == MODE_BY_MATERIAL:
			_extract_mesh_by_material(mesh, path.get_file().get_basename(), out_dir, null, Transform3D.IDENTITY)
		elif mode == MODE_COMBINED:
			_extract_mesh_combined(mesh, path.get_file().get_basename(), out_dir, null, Transform3D.IDENTITY)
		else:
			var out_mesh := _mesh_to_arraymesh(mesh, Transform3D.IDENTITY, null)
			var out_name := _make_out_name(path.get_file().get_basename(), "mesh")
			_save_mesh(out_mesh, out_dir.path_join(out_name + ".obj"))
		return
	push_warning("Unsupported resource type for: " + path)


func _try_load_imported_resource(src_path: String) -> Resource:
	var import_path := src_path + ".import"
	if not FileAccess.file_exists(import_path):
		return null
	var cfg := ConfigFile.new()
	var err := cfg.load(import_path)
	if err != OK:
		return null
	var remap_path := cfg.get_value("remap", "path", "")
	if remap_path is String and String(remap_path) != "":
		return ResourceLoader.load(String(remap_path))
	var dest_files := cfg.get_value("remap", "dest_files", PackedStringArray())
	if dest_files is PackedStringArray and dest_files.size() > 0:
		return ResourceLoader.load(dest_files[0])
	if dest_files is Array and dest_files.size() > 0:
		return ResourceLoader.load(String(dest_files[0]))
	return null


func _extract_from_scene(inst: Node, src_path: String, out_dir: String, mode: int) -> void:
	var meshes: Array = inst.find_children("*", "MeshInstance3D", true, false)
	if meshes.is_empty():
		push_warning("No MeshInstance3D found in: " + src_path)
		return
	var base := src_path.get_file().get_basename()
	if mode == MODE_COMBINED:
		_extract_scene_combined(meshes, inst, base, out_dir)
		return
	var idx := 0
	for node in meshes:
		var mi := node as MeshInstance3D
		if mi == null:
			continue
		if mi.mesh == null:
			continue
		var local_xform := Transform3D.IDENTITY
		if bake_transforms and mi is Node3D:
			local_xform = _get_local_to_root(mi, inst)
		if mode == MODE_BY_MATERIAL:
			_extract_mesh_by_material(mi.mesh, base, out_dir, mi, local_xform)
		else:
			var out_mesh := _mesh_to_arraymesh(mi.mesh, local_xform, mi)
			var name := _make_out_name(base, mi.name)
			if meshes.size() > 1:
				name += "__" + str(idx)
			idx += 1
			_save_mesh(out_mesh, out_dir.path_join(name + ".obj"))


func _mesh_to_arraymesh(mesh: Mesh, xf: Transform3D, mi: MeshInstance3D) -> ArrayMesh:
	var out := ArrayMesh.new()
	var surface_count := mesh.get_surface_count()
	var normal_basis := xf.basis
	if xf.basis.determinant() != 0.0:
		normal_basis = xf.basis.inverse().transposed()
	for i in range(surface_count):
		var arrays: Array = mesh.surface_get_arrays(i)
		if arrays.is_empty():
			continue
		var verts := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var norms := arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
		var tangents := arrays[Mesh.ARRAY_TANGENT] as PackedFloat32Array
		if bake_transforms:
			for v in range(verts.size()):
				verts[v] = xf * verts[v]
			if norms.size() > 0:
				for n in range(norms.size()):
					norms[n] = (normal_basis * norms[n]).normalized()
			if tangents.size() > 0:
				var t := 0
				while t + 3 < tangents.size():
					var tv := Vector3(tangents[t], tangents[t + 1], tangents[t + 2])
					tv = (normal_basis * tv).normalized()
					tangents[t] = tv.x
					tangents[t + 1] = tv.y
					tangents[t + 2] = tv.z
					t += 4
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = norms
		arrays[Mesh.ARRAY_TANGENT] = tangents
		var blend_shapes: Array = mesh.surface_get_blend_shape_arrays(i)
		out.add_surface_from_arrays(mesh.surface_get_primitive_type(i), arrays, blend_shapes)
		var mat: Material = null
		if mi:
			mat = mi.get_surface_override_material(i)
			if mat == null and mi.material_override != null:
				mat = mi.material_override
		if mat == null:
			mat = mesh.surface_get_material(i)
		if mat != null:
			out.surface_set_material(out.get_surface_count() - 1, mat)
	if mi and mi.material_override and out.get_surface_count() > 0:
		for i in range(out.get_surface_count()):
			out.surface_set_material(i, mi.material_override)
	return out


func _extract_scene_combined(meshes: Array, root: Node, base: String, out_dir: String) -> void:
	var out := ArrayMesh.new()
	var groups: Array[String] = []
	for node in meshes:
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var local_xf := Transform3D.IDENTITY
		if bake_transforms and mi is Node3D:
			local_xf = _get_local_to_root(mi, root)
		_append_mesh_surfaces(out, mi.mesh, local_xf, mi, mi.name, groups)
	if out.get_surface_count() <= 0:
		push_warning("Combined extract produced no surfaces for: " + base)
		return
	out.set_meta("surface_groups", groups)
	var out_name := _make_out_name(base, "combined")
	_save_mesh(out, out_dir.path_join(out_name + ".obj"))


func _extract_mesh_combined(mesh: Mesh, base: String, out_dir: String, mi: MeshInstance3D, xf: Transform3D) -> void:
	var out := ArrayMesh.new()
	var groups: Array[String] = []
	_append_mesh_surfaces(out, mesh, xf, mi, "mesh", groups)
	if out.get_surface_count() <= 0:
		return
	out.set_meta("surface_groups", groups)
	var out_name := _make_out_name(base, "combined")
	_save_mesh(out, out_dir.path_join(out_name + ".obj"))


func _append_mesh_surfaces(out: ArrayMesh, mesh: Mesh, xf: Transform3D, mi: MeshInstance3D, group_name: String, groups: Array[String]) -> void:
	var surface_count := mesh.get_surface_count()
	var normal_basis := xf.basis
	if xf.basis.determinant() != 0.0:
		normal_basis = xf.basis.inverse().transposed()
	for i in range(surface_count):
		var arrays: Array = mesh.surface_get_arrays(i)
		if arrays.is_empty():
			continue
		var verts := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var norms := arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
		var tangents := arrays[Mesh.ARRAY_TANGENT] as PackedFloat32Array
		if bake_transforms:
			for v in range(verts.size()):
				verts[v] = xf * verts[v]
			if norms.size() > 0:
				for n in range(norms.size()):
					norms[n] = (normal_basis * norms[n]).normalized()
			if tangents.size() > 0:
				var t := 0
				while t + 3 < tangents.size():
					var tv := Vector3(tangents[t], tangents[t + 1], tangents[t + 2])
					tv = (normal_basis * tv).normalized()
					tangents[t] = tv.x
					tangents[t + 1] = tv.y
					tangents[t + 2] = tv.z
					t += 4
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = norms
		arrays[Mesh.ARRAY_TANGENT] = tangents
		var blend_shapes: Array = mesh.surface_get_blend_shape_arrays(i)
		out.add_surface_from_arrays(mesh.surface_get_primitive_type(i), arrays, blend_shapes)
		var mat: Material = null
		if mi:
			mat = mi.get_surface_override_material(i)
			if mat == null and mi.material_override != null:
				mat = mi.material_override
		if mat == null:
			mat = mesh.surface_get_material(i)
		if mat != null:
			out.surface_set_material(out.get_surface_count() - 1, mat)
		groups.append(group_name)
	if mi and mi.material_override and out.get_surface_count() > 0:
		for i in range(out.get_surface_count()):
			out.surface_set_material(i, mi.material_override)


func _extract_mesh_by_material(mesh: Mesh, base: String, out_dir: String, mi: MeshInstance3D, xf: Transform3D) -> void:
	var surface_count := mesh.get_surface_count()
	if surface_count <= 0:
		return
	var normal_basis := xf.basis
	if xf.basis.determinant() != 0.0:
		normal_basis = xf.basis.inverse().transposed()
	var by_label: Dictionary = {}
	var label_order: Array[String] = []
	for i in range(surface_count):
		var arrays: Array = mesh.surface_get_arrays(i)
		if arrays.is_empty():
			continue
		var verts := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		var norms := arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
		var tangents := arrays[Mesh.ARRAY_TANGENT] as PackedFloat32Array
		if bake_transforms:
			for v in range(verts.size()):
				verts[v] = xf * verts[v]
			if norms.size() > 0:
				for n in range(norms.size()):
					norms[n] = (normal_basis * norms[n]).normalized()
			if tangents.size() > 0:
				var t := 0
				while t + 3 < tangents.size():
					var tv := Vector3(tangents[t], tangents[t + 1], tangents[t + 2])
					tv = (normal_basis * tv).normalized()
					tangents[t] = tv.x
					tangents[t + 1] = tv.y
					tangents[t + 2] = tv.z
					t += 4
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = norms
		arrays[Mesh.ARRAY_TANGENT] = tangents
		var mat: Material = null
		if mi:
			mat = mi.get_surface_override_material(i)
			if mat == null and mi.material_override != null:
				mat = mi.material_override
		if mat == null:
			mat = mesh.surface_get_material(i)
		var label := _material_label(mat, i)
		var out_mesh: ArrayMesh = by_label.get(label, null)
		if out_mesh == null:
			out_mesh = ArrayMesh.new()
			by_label[label] = out_mesh
			label_order.append(label)
		var blend_shapes: Array = mesh.surface_get_blend_shape_arrays(i)
		out_mesh.add_surface_from_arrays(mesh.surface_get_primitive_type(i), arrays, blend_shapes)
		if mat != null:
			out_mesh.surface_set_material(out_mesh.get_surface_count() - 1, mat)
	for label in label_order:
		var out: ArrayMesh = by_label[label]
		var name := _make_out_name(base, label)
		_save_mesh(out, out_dir.path_join(name + ".obj"))


func _material_label(mat: Material, idx: int) -> String:
	if mat != null:
		if mat.resource_name != "":
			return mat.resource_name
		if mat.resource_path != "":
			return mat.resource_path.get_file().get_basename()
	return "mat_" + str(idx)


func _get_local_to_root(node: Node, root: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var current: Node = node
	while current and current != root:
		if current is Node3D:
			xf = (current as Node3D).transform * xf
		current = current.get_parent()
	return xf


func _make_out_name(base: String, mesh_name: String) -> String:
	var safe_base := _sanitize(base)
	var safe_mesh := _sanitize(mesh_name)
	if safe_mesh == "":
		safe_mesh = "mesh"
	return safe_base + "_" + safe_mesh


func _sanitize(text: String) -> String:
	var out := text.replace(" ", "_")
	out = out.replace("/", "_")
	out = out.replace("\\", "_")
	out = out.replace(":", "_")
	out = out.replace(".", "-")
	return out


func _ensure_dir(path: String) -> void:
	var abs := ProjectSettings.globalize_path(path)
	if DirAccess.dir_exists_absolute(abs):
		return
	DirAccess.make_dir_recursive_absolute(abs)


func _save_mesh(mesh: ArrayMesh, path: String) -> void:
	if mesh == null:
		return
	if not overwrite_existing and FileAccess.file_exists(path):
		print("ArrayMesh extract: exists, skip:", path)
		return
	var obj_path: String = path
	if obj_path.get_extension().to_lower() != "obj":
		obj_path = obj_path.get_base_dir().path_join(obj_path.get_file().get_basename() + ".obj")
	print("ArrayMesh extract: saving OBJ:", obj_path)
	var helper: RefCounted = _get_mesh_obj_helper()
	if helper == null:
		push_warning("ArrayMesh extract: OBJ helper unavailable.")
		return
	var ok: bool = bool(helper.call("export_mesh_to_obj", mesh, obj_path, obj_path.get_file().get_basename()))
	if not ok:
		push_warning("Failed to save OBJ: " + obj_path)
		return
	_refresh_output_path(obj_path)
	var mtl_path: String = obj_path.get_base_dir().path_join(obj_path.get_file().get_basename() + ".mtl")
	if FileAccess.file_exists(mtl_path):
		_refresh_output_path(mtl_path)
	print("ArrayMesh extract: saved:", obj_path)


func _get_mesh_obj_helper() -> RefCounted:
	if _mesh_obj_helper == null and MESH_OBJ_HELPER_SCRIPT != null:
		_mesh_obj_helper = MESH_OBJ_HELPER_SCRIPT.new()
	return _mesh_obj_helper


func _refresh_output_path(path: String) -> void:
	var iface: EditorInterface = get_editor_interface()
	if iface == null:
		return
	var fs: EditorFileSystem = iface.get_resource_filesystem()
	if fs == null:
		return
	fs.update_file(path)
