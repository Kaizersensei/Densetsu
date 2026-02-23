@tool
extends EditorScript

# Exports a selected MeshInstance3D mesh (or fallback mesh resource) to OBJ.
# Use this to round-trip ArrayMesh data into external DCC tools for repair.

const MESH_OBJ_HELPER_SCRIPT: Script = preload("res://addons/densetsu_tool_suite/helpers/mesh_obj_helper.gd")
const SOURCE_MESH_RESOURCE := ""
const OUTPUT_OBJ_PATH := "res://temp/mesh_export.obj"
const FLIP_V_TEXCOORD := true
const FLIP_FACE_WINDING_FOR_OBJ := true
var _mesh_obj_helper: RefCounted


func _run() -> void:
	var source: Dictionary = _resolve_source_mesh()
	var mesh: Mesh = source.get("mesh", null) as Mesh
	if mesh == null:
		push_error("ExportMeshToObj: No mesh source found. Select a MeshInstance3D or set SOURCE_MESH_RESOURCE.")
		return

	var source_name: String = String(source.get("name", "MeshExport"))
	var export_mesh: Mesh = mesh
	var source_mesh_instance: MeshInstance3D = source.get("mesh_instance", null) as MeshInstance3D
	if source_mesh_instance != null:
		var with_overrides: ArrayMesh = _build_mesh_with_instance_materials(source_mesh_instance)
		if with_overrides != null and with_overrides.get_surface_count() > 0:
			export_mesh = with_overrides

	_ensure_output_dir(OUTPUT_OBJ_PATH)
	var helper: RefCounted = _get_mesh_obj_helper()
	if helper == null:
		push_error("ExportMeshToObj: Mesh OBJ helper unavailable.")
		return

	var ok: bool = bool(helper.call("export_mesh_to_obj", export_mesh, OUTPUT_OBJ_PATH, source_name))
	if not ok:
		push_error("ExportMeshToObj: Failed to export OBJ/MTL for: " + OUTPUT_OBJ_PATH)
		return

	_refresh_output_paths(OUTPUT_OBJ_PATH)
	var mtl_path: String = OUTPUT_OBJ_PATH.get_base_dir().path_join(OUTPUT_OBJ_PATH.get_file().get_basename() + ".mtl")
	if FileAccess.file_exists(mtl_path):
		print("ExportMeshToObj: exported ", export_mesh.get_surface_count(), " surfaces to ", OUTPUT_OBJ_PATH, " + ", mtl_path)
	else:
		print("ExportMeshToObj: exported ", export_mesh.get_surface_count(), " surfaces to ", OUTPUT_OBJ_PATH)


func _resolve_source_mesh() -> Dictionary:
	var out: Dictionary = {}

	var editor: EditorInterface = get_editor_interface()
	if editor != null and editor.get_selection() != null:
		var selected_nodes: Array = editor.get_selection().get_selected_nodes()
		for node in selected_nodes:
			if node is MeshInstance3D:
				var mesh_instance: MeshInstance3D = node as MeshInstance3D
				if mesh_instance.mesh != null:
					out["mesh"] = mesh_instance.mesh
					out["name"] = mesh_instance.name
					out["mesh_instance"] = mesh_instance
					out["source"] = "selected MeshInstance3D"
					return out

	if not SOURCE_MESH_RESOURCE.is_empty():
		if not ResourceLoader.exists(SOURCE_MESH_RESOURCE):
			push_warning("ExportMeshToObj: SOURCE_MESH_RESOURCE not found: " + SOURCE_MESH_RESOURCE)
			return out
		var res: Resource = ResourceLoader.load(SOURCE_MESH_RESOURCE)
		if res is Mesh:
			out["mesh"] = res
			out["name"] = SOURCE_MESH_RESOURCE.get_file().get_basename()
			out["source"] = "SOURCE_MESH_RESOURCE"
		else:
			push_warning("ExportMeshToObj: SOURCE_MESH_RESOURCE is not a Mesh: " + SOURCE_MESH_RESOURCE)

	return out


func _build_mesh_with_instance_materials(mesh_instance: MeshInstance3D) -> ArrayMesh:
	if mesh_instance == null or mesh_instance.mesh == null:
		return null
	var source_mesh: Mesh = mesh_instance.mesh
	var out_mesh: ArrayMesh = ArrayMesh.new()
	for i in range(source_mesh.get_surface_count()):
		var arrays: Array = source_mesh.surface_get_arrays(i)
		if arrays.is_empty():
			continue
		var blend_shapes: Array = source_mesh.surface_get_blend_shape_arrays(i)
		var primitive: int = Mesh.PRIMITIVE_TRIANGLES
		if source_mesh.has_method("surface_get_primitive_type"):
			primitive = int(source_mesh.call("surface_get_primitive_type", i))
		out_mesh.add_surface_from_arrays(primitive, arrays, blend_shapes)
		var mat: Material = mesh_instance.get_surface_override_material(i)
		if mat == null:
			mat = source_mesh.surface_get_material(i)
		if mat != null:
			out_mesh.surface_set_material(out_mesh.get_surface_count() - 1, mat)
	if mesh_instance.material_override != null:
		for i in range(out_mesh.get_surface_count()):
			out_mesh.surface_set_material(i, mesh_instance.material_override)
	return out_mesh


func _get_mesh_obj_helper() -> RefCounted:
	if _mesh_obj_helper == null and MESH_OBJ_HELPER_SCRIPT != null:
		_mesh_obj_helper = MESH_OBJ_HELPER_SCRIPT.new()
	return _mesh_obj_helper


func _build_obj_text(mesh: Mesh, object_name: String) -> String:
	var lines := PackedStringArray()
	lines.append("# ExportMeshToObj (Godot)")
	lines.append("o " + _sanitize_obj_name(object_name))

	var vertex_offset := 0
	var uv_offset := 0
	var normal_offset := 0
	var wrote_faces := false

	for surface_idx in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface_idx)
		if arrays.is_empty():
			continue

		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if vertices.is_empty():
			continue

		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var primitive: int = int(mesh.surface_get_primitive_type(surface_idx))
		var triangles := _build_triangle_indices(primitive, vertices.size(), indices)

		if triangles.is_empty():
			push_warning("ExportMeshToObj: Surface %d skipped (unsupported primitive or no triangle data)." % surface_idx)
			continue

		var has_uv := not uvs.is_empty() and uvs.size() == vertices.size()
		var has_normal := not normals.is_empty() and normals.size() == vertices.size()
		if not uvs.is_empty() and not has_uv:
			push_warning("ExportMeshToObj: Surface %d UV count mismatch. UVs ignored." % surface_idx)
		if not normals.is_empty() and not has_normal:
			push_warning("ExportMeshToObj: Surface %d normal count mismatch. Normals ignored." % surface_idx)

		lines.append("g surface_%d" % surface_idx)
		for v in vertices:
			lines.append("v %.6f %.6f %.6f" % [v.x, v.y, v.z])
		if has_uv:
			for uv in uvs:
				var uv_y := 1.0 - uv.y if FLIP_V_TEXCOORD else uv.y
				lines.append("vt %.6f %.6f" % [uv.x, uv_y])
		if has_normal:
			for n in normals:
				lines.append("vn %.6f %.6f %.6f" % [n.x, n.y, n.z])

		for tri_idx in range(0, triangles.size(), 3):
			var a := triangles[tri_idx]
			var b := triangles[tri_idx + 1]
			var c := triangles[tri_idx + 2]
			if a < 0 or b < 0 or c < 0:
				continue
			if a >= vertices.size() or b >= vertices.size() or c >= vertices.size():
				continue
			var face_b := b
			var face_c := c
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
		return ""
	return "\n".join(lines) + "\n"


func _build_triangle_indices(primitive: int, vertex_count: int, indices: PackedInt32Array) -> PackedInt32Array:
	var source := PackedInt32Array()
	if indices.is_empty():
		source.resize(vertex_count)
		for i in range(vertex_count):
			source[i] = i
	else:
		source = indices

	var out := PackedInt32Array()
	match primitive:
		Mesh.PRIMITIVE_TRIANGLES:
			var end := source.size() - (source.size() % 3)
			for i in range(0, end, 3):
				out.push_back(source[i])
				out.push_back(source[i + 1])
				out.push_back(source[i + 2])
		Mesh.PRIMITIVE_TRIANGLE_STRIP:
			for i in range(2, source.size()):
				var a := source[i - 2]
				var b := source[i - 1]
				var c := source[i]
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
			# Lines/points are not exported as faces in this tool.
			return PackedInt32Array()

	return out


func _face_token(local_index: int, vertex_offset: int, uv_offset: int, normal_offset: int, has_uv: bool, has_normal: bool) -> String:
	var v_idx := vertex_offset + local_index + 1
	if has_uv and has_normal:
		var t_idx := uv_offset + local_index + 1
		var n_idx := normal_offset + local_index + 1
		return "%d/%d/%d" % [v_idx, t_idx, n_idx]
	if has_uv:
		var t_only := uv_offset + local_index + 1
		return "%d/%d" % [v_idx, t_only]
	if has_normal:
		var n_only := normal_offset + local_index + 1
		return "%d//%d" % [v_idx, n_only]
	return str(v_idx)


func _sanitize_obj_name(value: String) -> String:
	var clean := value.strip_edges()
	if clean.is_empty():
		return "MeshExport"
	return clean.replace(" ", "_")


func _ensure_output_dir(path: String) -> void:
	var dir_path := path.get_base_dir()
	if dir_path.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))


func _refresh_output_paths(obj_path: String) -> void:
	var editor: EditorInterface = get_editor_interface()
	if editor == null:
		return
	var fs: EditorFileSystem = editor.get_resource_filesystem()
	if fs == null:
		return
	fs.update_file(obj_path)
	var mtl_path: String = obj_path.get_base_dir().path_join(obj_path.get_file().get_basename() + ".mtl")
	if FileAccess.file_exists(mtl_path):
		fs.update_file(mtl_path)
