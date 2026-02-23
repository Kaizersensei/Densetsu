@tool
extends EditorPlugin

const ROOT_SCRIPT := "res://engine3d/world/DensetsuStaticMesh3D.gd"

var overwrite_existing: bool = true
var _ctx_plugin: EditorContextMenuPlugin


class _DSMContextMenuPlugin:
	extends EditorContextMenuPlugin
	var _owner: EditorPlugin

	func _init(owner: EditorPlugin) -> void:
		_owner = owner

	func _popup_menu(paths: PackedStringArray) -> void:
		if paths.is_empty():
			return
		add_context_menu_item("Pack to Densetsu Static Mesh", Callable(_owner, "_on_pack_paths_from_context"))


func _enter_tree() -> void:
	add_tool_menu_item("Pack to Densetsu Static Mesh", _on_pack_selected_files)
	_ctx_plugin = _DSMContextMenuPlugin.new(self)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _ctx_plugin)


func _exit_tree() -> void:
	remove_tool_menu_item("Pack to Densetsu Static Mesh")
	if _ctx_plugin:
		remove_context_menu_plugin(_ctx_plugin)
		_ctx_plugin = null


func _on_pack_selected_files() -> void:
	var paths := _get_filesystem_selection()
	_pack_paths(paths)


func _on_pack_paths_from_context(paths: PackedStringArray = PackedStringArray()) -> void:
	_pack_paths(paths)


func _pack_paths(paths: PackedStringArray) -> void:
	if paths.is_empty():
		push_warning("Select model files in the FileSystem dock first.")
		return
	print("DSM pack: selected paths:", paths)
	for path in paths:
		if path.ends_with(".import") or path.ends_with(".uid"):
			continue
		print("DSM pack: processing:", path)
		_pack_resource_path(path)


func _get_filesystem_selection() -> PackedStringArray:
	var out := PackedStringArray()
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
		return PackedStringArray()
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
	return out


func _pack_resource_path(path: String) -> void:
	print("DSM pack: loading:", path)
	var res := ResourceLoader.load(path)
	if res == null:
		push_warning("Failed to load: " + path)
		return
	if res is PackedScene:
		print("DSM pack: resource is PackedScene")
		var inst: Node = res.instantiate()
		var meshes: Array = inst.find_children("*", "MeshInstance3D", true, false)
		if meshes.is_empty():
			inst.free()
			push_warning("No MeshInstance3D found in: " + path)
			return
		print("DSM pack: extracted mesh count:", meshes.size())
		var root := _create_root()
		root.name = "DSM_" + path.get_file().get_basename()
		if meshes.size() == 1:
			var mesh_data := _mesh_instance_to_data(meshes[0] as MeshInstance3D)
			if "mesh" in root:
				root.set("mesh", mesh_data.mesh)
			if "material_override" in root:
				root.set("material_override", mesh_data.material_override)
			if "surface_materials" in root:
				root.set("surface_materials", mesh_data.surface_materials)
			if root.has_method("_ensure_model"):
				root.call("_ensure_model")
			if root.has_method("_apply_all"):
				root.call("_apply_all")
		else:
			_create_mesh_children_from_scene(root, inst, meshes)
		inst.free()
		_save_packed(root, path)
		return
	if res is Mesh:
		print("DSM pack: resource is Mesh")
		var root := _create_root()
		root.name = "DSM_" + path.get_file().get_basename()
		if "mesh" in root:
			root.set("mesh", res)
		if root.has_method("_ensure_model"):
			root.call("_ensure_model")
		if root.has_method("_apply_all"):
			root.call("_apply_all")
		_save_packed(root, path)
		return
	push_warning("Unsupported resource type for: " + path)


func _mesh_instance_to_data(mi: MeshInstance3D) -> Dictionary:
	if mi == null:
		return {}
	var mats: Array[Material] = []
	if mi.mesh:
		var count := mi.mesh.get_surface_count()
		for i in range(count):
			var m := mi.get_surface_override_material(i)
			if m == null:
				m = mi.mesh.surface_get_material(i)
			mats.append(m)
	return {
		"mesh": mi.mesh,
		"material_override": mi.material_override,
		"surface_materials": mats
	}


func _create_mesh_children_from_scene(root: Node, inst: Node, meshes: Array) -> void:
	if root == null:
		return
	var inst3d := inst as Node3D
	for mesh_node in meshes:
		var mi := mesh_node as MeshInstance3D
		if mi == null:
			continue
		var child := MeshInstance3D.new()
		child.name = mi.name
		if inst3d:
			child.transform = inst3d.global_transform.affine_inverse() * mi.global_transform
		else:
			child.transform = mi.transform
		child.mesh = mi.mesh
		child.material_override = mi.material_override
		if mi.mesh:
			var count := mi.mesh.get_surface_count()
			for i in range(count):
				var m := mi.get_surface_override_material(i)
				if m == null:
					m = mi.mesh.surface_get_material(i)
				child.set_surface_override_material(i, m)
		root.add_child(child)
		child.owner = root


func _save_packed(root: Node, src_path: String) -> void:
	var out_path := _derive_output_path(src_path)
	if out_path == "":
		push_warning("Could not derive output path for: " + src_path)
		return
	var packed := PackedScene.new()
	var err_pack := packed.pack(root)
	if err_pack != OK:
		push_warning("Failed to pack scene for: " + src_path + " (err " + str(err_pack) + ")")
		return
	var err := ResourceSaver.save(packed, out_path)
	if err != OK:
		push_warning("Failed to save: " + out_path + " (err " + str(err) + ")")
	else:
		print("Packed:", out_path)




func _create_root() -> Node3D:
	var root := StaticBody3D.new()
	root.name = "DSM"
	var script := load(ROOT_SCRIPT)
	if script:
		root.set_script(script)
	return root


func _derive_output_path(src_path: String) -> String:
	if src_path == "":
		return ""
	var base_dir := src_path.get_base_dir()
	var base_name := src_path.get_file().get_basename()
	if base_name == "":
		base_name = "StaticMesh"
	var out := base_dir.path_join("DSM_" + base_name + ".tscn")
	if overwrite_existing:
		return out
	var idx := 1
	while ResourceLoader.exists(out):
		out = base_dir.path_join("DSM_" + base_name + "_" + str(idx) + ".tscn")
		idx += 1
	return out
