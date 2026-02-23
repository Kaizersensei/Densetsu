@tool
extends VBoxContainer

const ALL_COLLISION_LAYERS_MASK: int = 4294967295
const STATE_CFG_PATH: String = "user://densetsu_autocliff_state.cfg"
const STATE_SECTION: String = "autocliff"

var _editor_interface: EditorInterface

var _target_path_edit: LineEdit
var _output_name_edit: LineEdit
var _mesh_item_list: ItemList
var _status_label: Label
var _mesh_file_dialog: FileDialog

var _area_size_x_spin: SpinBox
var _area_size_z_spin: SpinBox
var _sample_spacing_spin: SpinBox
var _ray_height_spin: SpinBox
var _slope_min_spin: SpinBox
var _slope_max_spin: SpinBox
var _density_spin: SpinBox
var _bury_min_spin: SpinBox
var _bury_max_spin: SpinBox
var _scale_min_spin: SpinBox
var _scale_max_spin: SpinBox
var _yaw_jitter_spin: SpinBox
var _collision_mask_spin: SpinBox
var _clearance_radius_scale_spin: SpinBox
var _clearance_extra_spin: SpinBox
var _seed_spin: SpinBox

var _replace_existing_check: CheckBox
var _slope_order_check: CheckBox
var _use_multimesh_check: CheckBox
var _avoid_collider_overlap_check: CheckBox
var _clearance_check_areas_check: CheckBox

var _pool_resources: Array[Resource] = []
var _pool_kinds: Array[String] = [] # "mesh" | "scene"
var _pool_paths: Array[String] = []
var _state_loading: bool = false
var _save_queued: bool = false


func setup(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface
	_build_ui()
	_connect_persistence_signals()
	load_state()


func _build_ui() -> void:
	if get_child_count() > 0:
		return

	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)

	var root: VBoxContainer = VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(root)

	var title: Label = Label.new()
	title.text = "Densetsu Autocliff"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var target_row: HBoxContainer = HBoxContainer.new()
	root.add_child(target_row)

	var target_label: Label = Label.new()
	target_label.text = "Target Terrain3D"
	target_label.custom_minimum_size = Vector2(100.0, 0.0)
	target_row.add_child(target_label)

	_target_path_edit = LineEdit.new()
	_target_path_edit.placeholder_text = "Scene-relative Terrain3D path (e.g. World/Terrain3D)"
	_target_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_row.add_child(_target_path_edit)

	var use_selected_button: Button = Button.new()
	use_selected_button.text = "Use Selected"
	use_selected_button.pressed.connect(_on_use_selected_node_pressed)
	target_row.add_child(use_selected_button)

	var output_row: HBoxContainer = HBoxContainer.new()
	root.add_child(output_row)

	var output_label: Label = Label.new()
	output_label.text = "Output Root"
	output_label.custom_minimum_size = Vector2(100.0, 0.0)
	output_row.add_child(output_label)

	_output_name_edit = LineEdit.new()
	_output_name_edit.text = "Autocliff_Output"
	_output_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	output_row.add_child(_output_name_edit)

	var mesh_header: Label = Label.new()
	mesh_header.text = "Cliff Mesh Pool (ordered by slope when enabled)"
	root.add_child(mesh_header)

	_mesh_item_list = ItemList.new()
	_mesh_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mesh_item_list.custom_minimum_size = Vector2(0.0, 160.0)
	_mesh_item_list.select_mode = ItemList.SELECT_MULTI
	root.add_child(_mesh_item_list)

	var mesh_buttons: HBoxContainer = HBoxContainer.new()
	root.add_child(mesh_buttons)

	var add_files_button: Button = Button.new()
	add_files_button.text = "Add Mesh/Scene Files"
	add_files_button.pressed.connect(_on_add_mesh_files_pressed)
	mesh_buttons.add_child(add_files_button)

	var add_selected_mesh_button: Button = Button.new()
	add_selected_mesh_button.text = "Add Selected Node/Scene"
	add_selected_mesh_button.pressed.connect(_on_add_selected_node_mesh_pressed)
	mesh_buttons.add_child(add_selected_mesh_button)

	var remove_mesh_button: Button = Button.new()
	remove_mesh_button.text = "Remove Selected"
	remove_mesh_button.pressed.connect(_on_remove_selected_meshes_pressed)
	mesh_buttons.add_child(remove_mesh_button)

	var clear_mesh_button: Button = Button.new()
	clear_mesh_button.text = "Clear"
	clear_mesh_button.pressed.connect(_on_clear_meshes_pressed)
	mesh_buttons.add_child(clear_mesh_button)

	var params_label: Label = Label.new()
	params_label.text = "Sampling And Placement"
	root.add_child(params_label)

	_area_size_x_spin = _add_spin_row(root, "Area Size X", 1.0, 8192.0, 1.0, 256.0)
	_area_size_z_spin = _add_spin_row(root, "Area Size Z", 1.0, 8192.0, 1.0, 256.0)
	_sample_spacing_spin = _add_spin_row(root, "Sample Spacing", 0.25, 128.0, 0.25, 4.0)
	_ray_height_spin = _add_spin_row(root, "Ray Half Height", 1.0, 4096.0, 1.0, 400.0)
	_slope_min_spin = _add_spin_row(root, "Slope Min (deg)", 0.0, 89.9, 0.1, 38.0)
	_slope_max_spin = _add_spin_row(root, "Slope Max (deg)", 0.0, 89.9, 0.1, 85.0)
	_density_spin = _add_spin_row(root, "Density (0-1)", 0.0, 1.0, 0.01, 0.55)
	_bury_min_spin = _add_spin_row(root, "Bury Min", 0.0, 10.0, 0.01, 0.2)
	_bury_max_spin = _add_spin_row(root, "Bury Max", 0.0, 10.0, 0.01, 0.8)
	_scale_min_spin = _add_spin_row(root, "Scale Min", 0.01, 64.0, 0.01, 0.9)
	_scale_max_spin = _add_spin_row(root, "Scale Max", 0.01, 64.0, 0.01, 1.2)
	_yaw_jitter_spin = _add_spin_row(root, "Yaw Jitter (deg)", 0.0, 180.0, 0.5, 15.0)
	_collision_mask_spin = _add_spin_row(root, "Collision Mask", 1.0, 4294967295.0, 1.0, 4294967295.0)
	_clearance_radius_scale_spin = _add_spin_row(root, "Clearance Radius Scale", 0.05, 4.0, 0.01, 1.0)
	_clearance_extra_spin = _add_spin_row(root, "Clearance Extra", 0.0, 64.0, 0.01, 0.1)
	_seed_spin = _add_spin_row(root, "Seed", 0.0, 2147483647.0, 1.0, 1337.0)

	_replace_existing_check = _add_check_row(root, "Replace existing output with same name", true)
	_slope_order_check = _add_check_row(root, "Map slope to mesh list order", true)
	_use_multimesh_check = _add_check_row(root, "Use MultiMesh output (recommended)", true)
	_avoid_collider_overlap_check = _add_check_row(root, "Reject placements overlapping colliders", true)
	_clearance_check_areas_check = _add_check_row(root, "Treat Area3D as blockers", true)

	var actions: HBoxContainer = HBoxContainer.new()
	root.add_child(actions)

	var generate_button: Button = Button.new()
	generate_button.text = "Autocliff"
	generate_button.pressed.connect(_on_generate_pressed)
	actions.add_child(generate_button)

	var clear_button: Button = Button.new()
	clear_button.text = "Clear Generated"
	clear_button.pressed.connect(_on_clear_generated_pressed)
	actions.add_child(clear_button)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.text = "Ready."
	root.add_child(_status_label)

	_mesh_file_dialog = FileDialog.new()
	_mesh_file_dialog.title = "Add Cliff Mesh / Composite Scene Files"
	_mesh_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_mesh_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	_mesh_file_dialog.filters = PackedStringArray([
		"*.tscn ; Godot Scene",
		"*.scn ; Imported Packed Scene",
		"*.obj ; OBJ Mesh",
		"*.tres ; TRES Resource",
		"*.res ; RES Resource"
	])
	_mesh_file_dialog.files_selected.connect(_on_mesh_files_selected)
	add_child(_mesh_file_dialog)


func _connect_persistence_signals() -> void:
	if _target_path_edit != null:
		if not _target_path_edit.text_changed.is_connected(_on_persist_text_changed):
			_target_path_edit.text_changed.connect(_on_persist_text_changed)
	if _output_name_edit != null:
		if not _output_name_edit.text_changed.is_connected(_on_persist_text_changed):
			_output_name_edit.text_changed.connect(_on_persist_text_changed)

	var spin_controls: Array[SpinBox] = [
		_area_size_x_spin, _area_size_z_spin, _sample_spacing_spin, _ray_height_spin,
		_slope_min_spin, _slope_max_spin, _density_spin, _bury_min_spin, _bury_max_spin,
		_scale_min_spin, _scale_max_spin, _yaw_jitter_spin, _collision_mask_spin,
		_clearance_radius_scale_spin, _clearance_extra_spin, _seed_spin
	]
	for spin: SpinBox in spin_controls:
		if spin == null:
			continue
		if not spin.value_changed.is_connected(_on_persist_value_changed):
			spin.value_changed.connect(_on_persist_value_changed)

	var checks: Array[CheckBox] = [
		_replace_existing_check, _slope_order_check, _use_multimesh_check,
		_avoid_collider_overlap_check, _clearance_check_areas_check
	]
	for check: CheckBox in checks:
		if check == null:
			continue
		if not check.toggled.is_connected(_on_persist_toggled):
			check.toggled.connect(_on_persist_toggled)


func _on_persist_text_changed(_value: String) -> void:
	_queue_save_state()


func _on_persist_value_changed(_value: float) -> void:
	_queue_save_state()


func _on_persist_toggled(_value: bool) -> void:
	_queue_save_state()


func _queue_save_state() -> void:
	if _state_loading:
		return
	if _save_queued:
		return
	_save_queued = true
	call_deferred("_save_state_deferred")


func _save_state_deferred() -> void:
	_save_queued = false
	save_state()


func save_state() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value(STATE_SECTION, "target_path", _target_path_edit.text if _target_path_edit != null else "")
	cfg.set_value(STATE_SECTION, "output_name", _output_name_edit.text if _output_name_edit != null else "")

	_save_spin(cfg, "area_size_x", _area_size_x_spin)
	_save_spin(cfg, "area_size_z", _area_size_z_spin)
	_save_spin(cfg, "sample_spacing", _sample_spacing_spin)
	_save_spin(cfg, "ray_height", _ray_height_spin)
	_save_spin(cfg, "slope_min", _slope_min_spin)
	_save_spin(cfg, "slope_max", _slope_max_spin)
	_save_spin(cfg, "density", _density_spin)
	_save_spin(cfg, "bury_min", _bury_min_spin)
	_save_spin(cfg, "bury_max", _bury_max_spin)
	_save_spin(cfg, "scale_min", _scale_min_spin)
	_save_spin(cfg, "scale_max", _scale_max_spin)
	_save_spin(cfg, "yaw_jitter", _yaw_jitter_spin)
	_save_spin(cfg, "collision_mask", _collision_mask_spin)
	_save_spin(cfg, "clearance_radius_scale", _clearance_radius_scale_spin)
	_save_spin(cfg, "clearance_extra", _clearance_extra_spin)
	_save_spin(cfg, "seed", _seed_spin)

	_save_check(cfg, "replace_existing", _replace_existing_check)
	_save_check(cfg, "slope_order", _slope_order_check)
	_save_check(cfg, "use_multimesh", _use_multimesh_check)
	_save_check(cfg, "avoid_collider_overlap", _avoid_collider_overlap_check)
	_save_check(cfg, "clearance_check_areas", _clearance_check_areas_check)

	var pool_paths_to_save: PackedStringArray = PackedStringArray()
	var pool_kinds_to_save: PackedStringArray = PackedStringArray()
	for i: int in _pool_paths.size():
		var path: String = _pool_paths[i]
		var kind: String = _pool_kinds[i] if i < _pool_kinds.size() else ""
		if path.is_empty() or path.begins_with("<"):
			continue
		pool_paths_to_save.append(path)
		pool_kinds_to_save.append(kind)
	cfg.set_value(STATE_SECTION, "pool_paths", pool_paths_to_save)
	cfg.set_value(STATE_SECTION, "pool_kinds", pool_kinds_to_save)

	var err: Error = cfg.save(STATE_CFG_PATH)
	if err != OK:
		push_warning("Autocliff: failed to save state (%d)." % int(err))


func load_state() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(STATE_CFG_PATH)
	if err != OK:
		return
	_state_loading = true

	_set_line_edit_text(_target_path_edit, str(cfg.get_value(STATE_SECTION, "target_path", _target_path_edit.text if _target_path_edit != null else "")))
	_set_line_edit_text(_output_name_edit, str(cfg.get_value(STATE_SECTION, "output_name", _output_name_edit.text if _output_name_edit != null else "")))

	_load_spin(cfg, "area_size_x", _area_size_x_spin)
	_load_spin(cfg, "area_size_z", _area_size_z_spin)
	_load_spin(cfg, "sample_spacing", _sample_spacing_spin)
	_load_spin(cfg, "ray_height", _ray_height_spin)
	_load_spin(cfg, "slope_min", _slope_min_spin)
	_load_spin(cfg, "slope_max", _slope_max_spin)
	_load_spin(cfg, "density", _density_spin)
	_load_spin(cfg, "bury_min", _bury_min_spin)
	_load_spin(cfg, "bury_max", _bury_max_spin)
	_load_spin(cfg, "scale_min", _scale_min_spin)
	_load_spin(cfg, "scale_max", _scale_max_spin)
	_load_spin(cfg, "yaw_jitter", _yaw_jitter_spin)
	_load_spin(cfg, "collision_mask", _collision_mask_spin)
	_load_spin(cfg, "clearance_radius_scale", _clearance_radius_scale_spin)
	_load_spin(cfg, "clearance_extra", _clearance_extra_spin)
	_load_spin(cfg, "seed", _seed_spin)

	_load_check(cfg, "replace_existing", _replace_existing_check)
	_load_check(cfg, "slope_order", _slope_order_check)
	_load_check(cfg, "use_multimesh", _use_multimesh_check)
	_load_check(cfg, "avoid_collider_overlap", _avoid_collider_overlap_check)
	_load_check(cfg, "clearance_check_areas", _clearance_check_areas_check)

	_pool_resources.clear()
	_pool_kinds.clear()
	_pool_paths.clear()
	var saved_paths_variant: Variant = cfg.get_value(STATE_SECTION, "pool_paths", PackedStringArray())
	var saved_kinds_variant: Variant = cfg.get_value(STATE_SECTION, "pool_kinds", PackedStringArray())
	var saved_paths: PackedStringArray = saved_paths_variant if saved_paths_variant is PackedStringArray else PackedStringArray()
	var saved_kinds: PackedStringArray = saved_kinds_variant if saved_kinds_variant is PackedStringArray else PackedStringArray()
	for i_path: int in saved_paths.size():
		var res_path: String = saved_paths[i_path]
		if res_path.is_empty():
			continue
		var res: Resource = ResourceLoader.load(res_path)
		if res == null:
			continue
		var kind: String = "mesh"
		if i_path < saved_kinds.size():
			kind = String(saved_kinds[i_path])
		if kind == "scene":
			var ps: PackedScene = res as PackedScene
			if ps != null:
				_append_scene(ps, res_path)
				continue
		var mesh_res: Mesh = res as Mesh
		if mesh_res != null:
			_append_mesh(mesh_res, res_path)
	_state_loading = false
	_refresh_mesh_list()


func _save_spin(cfg: ConfigFile, key: String, spin: SpinBox) -> void:
	if spin == null:
		return
	cfg.set_value(STATE_SECTION, key, spin.value)


func _save_check(cfg: ConfigFile, key: String, check: CheckBox) -> void:
	if check == null:
		return
	cfg.set_value(STATE_SECTION, key, check.button_pressed)


func _load_spin(cfg: ConfigFile, key: String, spin: SpinBox) -> void:
	if spin == null:
		return
	if not cfg.has_section_key(STATE_SECTION, key):
		return
	spin.value = float(cfg.get_value(STATE_SECTION, key, spin.value))


func _load_check(cfg: ConfigFile, key: String, check: CheckBox) -> void:
	if check == null:
		return
	if not cfg.has_section_key(STATE_SECTION, key):
		return
	check.button_pressed = bool(cfg.get_value(STATE_SECTION, key, check.button_pressed))


func _set_line_edit_text(line_edit: LineEdit, value: String) -> void:
	if line_edit == null:
		return
	line_edit.text = value


func _add_spin_row(parent: VBoxContainer, label_text: String, min_val: float, max_val: float, step: float, default_val: float) -> SpinBox:
	var row: HBoxContainer = HBoxContainer.new()
	parent.add_child(row)

	var label: Label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150.0, 0.0)
	row.add_child(label)

	var spin: SpinBox = SpinBox.new()
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = step
	spin.value = default_val
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spin)
	return spin


func _add_check_row(parent: VBoxContainer, label_text: String, default_value: bool) -> CheckBox:
	var check: CheckBox = CheckBox.new()
	check.text = label_text
	check.button_pressed = default_value
	parent.add_child(check)
	return check


func _on_use_selected_node_pressed() -> void:
	var selected: Node3D = _get_first_selected_terrain_node()
	if selected == null:
		_set_status("Autocliff: select a Terrain3D node in the Scene tree first.", true)
		return
	var scene_root: Node = _editor_interface.get_edited_scene_root()
	if scene_root == null:
		_set_status("Autocliff: no edited scene root.", true)
		return
	var rel_path: NodePath = scene_root.get_path_to(selected)
	_target_path_edit.text = String(rel_path)
	if _output_name_edit.text.strip_edges().is_empty():
		_output_name_edit.text = "Autocliff_%s" % selected.name
	_set_status("Autocliff target set: %s" % _target_path_edit.text, false)


func _on_add_selected_node_mesh_pressed() -> void:
	var selected: Node3D = _get_first_selected_node3d()
	if selected == null:
		_set_status("Autocliff: select a MeshInstance3D or instanced scene root first.", true)
		return
	var scene_file_path: String = selected.scene_file_path
	if not scene_file_path.is_empty():
		var packed_scene: PackedScene = load(scene_file_path) as PackedScene
		if packed_scene != null:
			if _append_scene(packed_scene, scene_file_path):
				_set_status("Autocliff: added composite scene from selected node.", false)
			else:
				_set_status("Autocliff: selected scene already in pool.", false)
			return
	if not (selected is MeshInstance3D):
		_set_status("Autocliff: selected node is not a MeshInstance3D and has no source scene.", true)
		return
	var mesh_instance: MeshInstance3D = selected as MeshInstance3D
	var mesh: Mesh = mesh_instance.mesh
	if mesh == null:
		_set_status("Autocliff: selected MeshInstance3D has no mesh.", true)
		return
	var source_label: String = mesh.resource_path
	if source_label.is_empty():
		source_label = "<embedded_mesh:%s>" % selected.name
	_append_mesh(mesh, source_label)
	_set_status("Autocliff: added mesh from selected node.", false)


func _on_add_mesh_files_pressed() -> void:
	_mesh_file_dialog.popup_centered_ratio(0.5)


func _on_mesh_files_selected(paths: PackedStringArray) -> void:
	var added: int = 0
	var skipped: int = 0
	for path in paths:
		var resource: Resource = ResourceLoader.load(path)
		var packed_scene: PackedScene = resource as PackedScene
		if packed_scene != null:
			if _append_scene(packed_scene, path):
				added += 1
			else:
				skipped += 1
			continue
		var mesh: Mesh = resource as Mesh
		if mesh == null:
			skipped += 1
			continue
		if _append_mesh(mesh, path):
			added += 1
		else:
			skipped += 1
	_set_status("Autocliff: added %d mesh(es), skipped %d." % [added, skipped], false)


func _append_mesh(mesh: Mesh, source_label: String) -> bool:
	return _append_pool_entry(mesh, "mesh", source_label)


func _append_scene(scene: PackedScene, source_label: String) -> bool:
	return _append_pool_entry(scene, "scene", source_label)


func _append_pool_entry(resource: Resource, kind: String, source_label: String) -> bool:
	if resource == null:
		return false
	var i: int = 0
	while i < _pool_resources.size():
		if _pool_resources[i] == resource:
			return false
		if _pool_paths[i] == source_label and _pool_kinds[i] == kind:
			return false
		i += 1
	_pool_resources.append(resource)
	_pool_kinds.append(kind)
	_pool_paths.append(source_label)
	_refresh_mesh_list()
	_queue_save_state()
	return true


func _on_remove_selected_meshes_pressed() -> void:
	var selected_indices: PackedInt32Array = _mesh_item_list.get_selected_items()
	if selected_indices.is_empty():
		return
	var indices: Array[int] = []
	for idx in selected_indices:
		indices.append(idx)
	indices.sort()
	indices.reverse()
	for idx in indices:
		if idx >= 0 and idx < _pool_resources.size():
			_pool_resources.remove_at(idx)
			_pool_kinds.remove_at(idx)
			_pool_paths.remove_at(idx)
	_refresh_mesh_list()
	_set_status("Autocliff: removed selected pool entries.", false)
	_queue_save_state()


func _on_clear_meshes_pressed() -> void:
	_pool_resources.clear()
	_pool_kinds.clear()
	_pool_paths.clear()
	_refresh_mesh_list()
	_set_status("Autocliff: cliff pool cleared.", false)
	_queue_save_state()


func _refresh_mesh_list() -> void:
	_mesh_item_list.clear()
	var i: int = 0
	while i < _pool_paths.size():
		var label: String = _pool_paths[i]
		if label.is_empty():
			label = "<entry_%d>" % i
		var kind: String = _pool_kinds[i] if i < _pool_kinds.size() else "?"
		var prefix: String = "[Mesh]"
		if kind == "scene":
			prefix = "[Scene]"
		_mesh_item_list.add_item("%d. %s %s" % [i + 1, prefix, label])
		i += 1


func _on_generate_pressed() -> void:
	if _editor_interface == null:
		_set_status("Autocliff: editor interface unavailable.", true)
		return
	var scene_root: Node = _editor_interface.get_edited_scene_root()
	if scene_root == null:
		_set_status("Autocliff: no edited scene.", true)
		return
	if _pool_resources.is_empty():
		_set_status("Autocliff: add one or more cliff meshes/scenes first.", true)
		return

	var target_path_text: String = _target_path_edit.text.strip_edges()
	if target_path_text.is_empty():
		_set_status("Autocliff: target path is empty.", true)
		return
	var target_any: Node = scene_root.get_node_or_null(NodePath(target_path_text))
	if target_any == null:
		_set_status("Autocliff: target path not found: %s" % target_path_text, true)
		return
	if not _is_terrain_node(target_any):
		_set_status("Autocliff: target must be Terrain3D. Got: %s" % target_any.get_class(), true)
		return
	var target_node: Node3D = target_any as Node3D
	if target_node == null:
		_set_status("Autocliff: Terrain3D target is not Node3D-compatible.", true)
		return

	var world: World3D = target_node.get_world_3d()
	if world == null:
		_set_status("Autocliff: target has no World3D.", true)
		return
	var space_state: PhysicsDirectSpaceState3D = world.direct_space_state
	if space_state == null:
		_set_status("Autocliff: no physics space available.", true)
		return

	var spacing: float = maxf(0.25, _sample_spacing_spin.value)
	var size_x: float = maxf(spacing, _area_size_x_spin.value)
	var size_z: float = maxf(spacing, _area_size_z_spin.value)
	var ray_height: float = maxf(1.0, _ray_height_spin.value)
	var slope_min: float = minf(_slope_min_spin.value, _slope_max_spin.value)
	var slope_max: float = maxf(_slope_min_spin.value, _slope_max_spin.value)
	var density: float = clampf(_density_spin.value, 0.0, 1.0)
	var bury_min: float = minf(_bury_min_spin.value, _bury_max_spin.value)
	var bury_max: float = maxf(_bury_min_spin.value, _bury_max_spin.value)
	var scale_min: float = minf(_scale_min_spin.value, _scale_max_spin.value)
	var scale_max: float = maxf(_scale_min_spin.value, _scale_max_spin.value)
	var yaw_jitter_deg: float = maxf(0.0, _yaw_jitter_spin.value)
	var collision_mask: int = int(_collision_mask_spin.value)
	var clearance_radius_scale: float = maxf(0.01, _clearance_radius_scale_spin.value)
	var clearance_extra: float = maxf(0.0, _clearance_extra_spin.value)
	var use_clearance_check: bool = _avoid_collider_overlap_check.button_pressed

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(_seed_spin.value)

	var x_count: int = int(floor(size_x / spacing)) + 1
	var z_count: int = int(floor(size_z / spacing)) + 1

	var buckets: Array = []
	var entry_clearance_radii: Array[float] = []
	var entry_count: int = _pool_resources.size()
	var mesh_idx: int = 0
	while mesh_idx < entry_count:
		buckets.append([])
		entry_clearance_radii.append(_estimate_pool_entry_clearance_radius(_pool_resources[mesh_idx], _pool_kinds[mesh_idx]))
		mesh_idx += 1

	var hit_count: int = 0
	var placed_count: int = 0
	var rejected_slope_count: int = 0
	var rejected_density_count: int = 0
	var rejected_collision_count: int = 0
	var target_center: Vector3 = target_node.global_transform.origin
	var clearance_shape: SphereShape3D = SphereShape3D.new()
	var clearance_query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	clearance_query.shape = clearance_shape
	clearance_query.collision_mask = ALL_COLLISION_LAYERS_MASK
	clearance_query.collide_with_bodies = true
	clearance_query.collide_with_areas = _clearance_check_areas_check.button_pressed
	clearance_query.margin = 0.0

	var xi: int = 0
	while xi < x_count:
		var x_t: float = 0.0
		if x_count > 1:
			x_t = float(xi) / float(x_count - 1)
		var x_offset: float = lerpf(-size_x * 0.5, size_x * 0.5, x_t)

		var zi: int = 0
		while zi < z_count:
			var z_t: float = 0.0
			if z_count > 1:
				z_t = float(zi) / float(z_count - 1)
			var z_offset: float = lerpf(-size_z * 0.5, size_z * 0.5, z_t)

			var sample_origin: Vector3 = target_center + Vector3(x_offset, 0.0, z_offset)
			var from_pos: Vector3 = sample_origin + Vector3.UP * ray_height
			var to_pos: Vector3 = sample_origin + Vector3.DOWN * ray_height

			var hit: Dictionary = _sample_surface(space_state, target_node, sample_origin, from_pos, to_pos, collision_mask)
			if hit.is_empty():
				zi += 1
				continue
			hit_count += 1

			var normal: Vector3 = hit.get("normal", Vector3.UP)
			if normal.length_squared() < 0.000001:
				zi += 1
				continue
			normal = normal.normalized()
			var slope_dot: float = clampf(normal.dot(Vector3.UP), -1.0, 1.0)
			var slope_deg: float = rad_to_deg(acos(slope_dot))
			if slope_deg < slope_min or slope_deg > slope_max:
				rejected_slope_count += 1
				zi += 1
				continue

			if rng.randf() > density:
				rejected_density_count += 1
				zi += 1
				continue

			var selected_mesh_index: int = 0
			if entry_count > 1 and _slope_order_check.button_pressed:
				var t: float = 0.0
				if absf(slope_max - slope_min) > 0.0001:
					t = clampf((slope_deg - slope_min) / (slope_max - slope_min), 0.0, 0.999999)
				selected_mesh_index = clampi(int(floor(t * float(entry_count))), 0, entry_count - 1)
			elif entry_count > 1:
				selected_mesh_index = rng.randi_range(0, entry_count - 1)

			var basis: Basis = _build_cliff_basis(normal, yaw_jitter_deg, rng)
			var random_scale: float = rng.randf_range(scale_min, scale_max)
			basis = basis.scaled(Vector3(random_scale, random_scale, random_scale))

			var bury_amount: float = rng.randf_range(bury_min, bury_max)
			var world_position: Vector3 = hit.get("position", sample_origin)
			var world_xf: Transform3D = Transform3D(basis, world_position - normal * bury_amount)

			if use_clearance_check:
				var base_radius: float = entry_clearance_radii[selected_mesh_index]
				var clearance_radius: float = maxf(0.01, base_radius * random_scale * clearance_radius_scale + clearance_extra)
				if _placement_overlaps_blocker(space_state, clearance_query, clearance_shape, world_xf.origin, clearance_radius, target_node):
					rejected_collision_count += 1
					zi += 1
					continue

			var bucket: Array = buckets[selected_mesh_index]
			bucket.append(world_xf)
			buckets[selected_mesh_index] = bucket
			placed_count += 1

			zi += 1
		xi += 1

	if placed_count == 0:
		_set_status(
			"Autocliff: no placements. Hits=%d, slope_reject=%d, density_reject=%d, collision_reject=%d. Try wider slope range, larger area, lower clearance, or higher density."
			% [hit_count, rejected_slope_count, rejected_density_count, rejected_collision_count],
			true
		)
		return

	var output_parent: Node = target_node.get_parent()
	if output_parent == null:
		output_parent = scene_root

	var output_name: String = _output_name_edit.text.strip_edges()
	if output_name.is_empty():
		output_name = "Autocliff_%s" % target_node.name
		_output_name_edit.text = output_name

	if _replace_existing_check.button_pressed:
		var existing_output: Node = output_parent.get_node_or_null(NodePath(output_name))
		if existing_output != null:
			existing_output.queue_free()

	var output_root: Node3D = Node3D.new()
	output_root.name = output_name
	output_parent.add_child(output_root)
	output_root.owner = scene_root
	output_root.global_position = target_center
	output_root.add_to_group("densetsu_autocliff")

	var output_inverse: Transform3D = output_root.global_transform.affine_inverse()

	var use_multimesh: bool = _use_multimesh_check.button_pressed
	mesh_idx = 0
	while mesh_idx < entry_count:
		var transforms: Array = buckets[mesh_idx]
		if transforms.is_empty():
			mesh_idx += 1
			continue
		var entry_kind: String = _pool_kinds[mesh_idx]
		var entry_res: Resource = _pool_resources[mesh_idx]
		var mesh: Mesh = entry_res as Mesh
		var packed_scene: PackedScene = entry_res as PackedScene
		if use_multimesh and entry_kind == "mesh" and mesh != null:
			var mm: MultiMesh = MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = mesh
			mm.instance_count = transforms.size()
			var t_idx: int = 0
			while t_idx < transforms.size():
				var world_xf: Transform3D = transforms[t_idx]
				var local_xf: Transform3D = output_inverse * world_xf
				mm.set_instance_transform(t_idx, local_xf)
				t_idx += 1

			var mm_instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
			mm_instance.name = "Cliff_MM_%d" % mesh_idx
			mm_instance.multimesh = mm
			output_root.add_child(mm_instance)
			mm_instance.owner = scene_root
		else:
			var t_idx_single: int = 0
			while t_idx_single < transforms.size():
				var single_world_xf: Transform3D = transforms[t_idx_single]
				var single_local_xf: Transform3D = output_inverse * single_world_xf
				if entry_kind == "scene" and packed_scene != null:
					var inst: Node = packed_scene.instantiate()
					var node3d_inst: Node3D = inst as Node3D
					if node3d_inst == null:
						t_idx_single += 1
						continue
					node3d_inst.name = "CliffScene_%d_%d" % [mesh_idx, t_idx_single]
					node3d_inst.transform = single_local_xf
					output_root.add_child(node3d_inst)
					node3d_inst.owner = scene_root
				else:
					var mesh_instance: MeshInstance3D = MeshInstance3D.new()
					mesh_instance.name = "Cliff_%d_%d" % [mesh_idx, t_idx_single]
					mesh_instance.mesh = mesh
					mesh_instance.transform = single_local_xf
					output_root.add_child(mesh_instance)
					mesh_instance.owner = scene_root
				t_idx_single += 1
		mesh_idx += 1

	_set_status(
		"Autocliff complete: %d placed from %d ray hits (%d x %d samples). Rejects slope=%d density=%d collision=%d."
		% [placed_count, hit_count, x_count, z_count, rejected_slope_count, rejected_density_count, rejected_collision_count],
		false
	)


func _build_cliff_basis(normal: Vector3, yaw_jitter_deg: float, rng: RandomNumberGenerator) -> Basis:
	var outward: Vector3 = normal.normalized()
	var downhill: Vector3 = Vector3.DOWN - outward * Vector3.DOWN.dot(outward)
	if downhill.length_squared() < 0.000001:
		downhill = outward.cross(Vector3.RIGHT)
	if downhill.length_squared() < 0.000001:
		downhill = outward.cross(Vector3.FORWARD)
	downhill = downhill.normalized()

	var x_axis: Vector3 = downhill.cross(outward)
	if x_axis.length_squared() < 0.000001:
		x_axis = outward.cross(Vector3.UP)
	if x_axis.length_squared() < 0.000001:
		x_axis = Vector3.RIGHT
	x_axis = x_axis.normalized()
	var y_axis: Vector3 = outward.cross(x_axis).normalized()

	var basis: Basis = Basis(x_axis, y_axis, outward).orthonormalized()
	if yaw_jitter_deg > 0.0:
		var yaw_rad: float = deg_to_rad(rng.randf_range(-yaw_jitter_deg, yaw_jitter_deg))
		var yaw_basis: Basis = Basis(outward, yaw_rad)
		basis = (yaw_basis * basis).orthonormalized()
	return basis


func _sample_surface(
	space_state: PhysicsDirectSpaceState3D,
	target_node: Node3D,
	sample_origin: Vector3,
	from_pos: Vector3,
	to_pos: Vector3,
	collision_mask: int
) -> Dictionary:
	# Prefer Terrain3D data sampling for robust editor-time placement.
	if _is_terrain_node(target_node):
		var terrain_hit: Dictionary = _sample_terrain_data(target_node, sample_origin)
		if not terrain_hit.is_empty():
			return terrain_hit

	var safe_mask: int = collision_mask
	if safe_mask <= 0:
		safe_mask = ALL_COLLISION_LAYERS_MASK
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from_pos, to_pos, safe_mask)
	ray_query.collide_with_areas = true
	ray_query.collide_with_bodies = true
	var hit: Dictionary = space_state.intersect_ray(ray_query)
	if hit.is_empty():
		return {}
	var collider_obj: Object = hit.get("collider", null)
	if not _hit_matches_target(collider_obj, target_node):
		return {}
	return hit


func _estimate_pool_entry_clearance_radius(resource: Resource, kind: String) -> float:
	if kind == "scene":
		return _estimate_scene_clearance_radius(resource as PackedScene)
	return _estimate_mesh_clearance_radius(resource as Mesh)


func _estimate_mesh_clearance_radius(mesh: Mesh) -> float:
	if mesh == null:
		return 0.5
	var aabb: AABB = mesh.get_aabb()
	var extents: Vector3 = aabb.size * 0.5
	var radius: float = extents.length()
	if radius <= 0.001:
		radius = 0.5
	return radius


func _estimate_transformed_aabb_clearance_radius(xform: Transform3D, aabb: AABB) -> float:
	var extents: Vector3 = aabb.size * 0.5
	var local_center: Vector3 = aabb.position + extents
	var world_center: Vector3 = xform * local_center
	# Account for authored node scaling (and parent scaling) when estimating clearance.
	var b: Basis = xform.basis
	var axis_x_len: float = b.x.length()
	var axis_y_len: float = b.y.length()
	var axis_z_len: float = b.z.length()
	var scaled_radius: float = sqrt(
		pow(extents.x * axis_x_len, 2.0) +
		pow(extents.y * axis_y_len, 2.0) +
		pow(extents.z * axis_z_len, 2.0)
	)
	return world_center.length() + scaled_radius


func _estimate_scene_clearance_radius(scene: PackedScene) -> float:
	if scene == null:
		return 0.75
	var inst: Node = scene.instantiate()
	var root3d: Node3D = inst as Node3D
	if root3d == null:
		if is_instance_valid(inst):
			inst.free()
		return 0.75
	var max_radius: float = 0.0
	var stack: Array[Node] = [root3d]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for child in node.get_children():
			stack.append(child)

		var node3d: Node3D = node as Node3D
		if node3d == null:
			continue
		var node_pos: Vector3 = node3d.global_transform.origin

		var mesh_instance: MeshInstance3D = node3d as MeshInstance3D
		if mesh_instance != null and mesh_instance.mesh != null:
			var aabb: AABB = mesh_instance.mesh.get_aabb()
			var r: float = _estimate_transformed_aabb_clearance_radius(mesh_instance.global_transform, aabb)
			max_radius = maxf(max_radius, r)

		var collision_shape: CollisionShape3D = node3d as CollisionShape3D
		if collision_shape != null and collision_shape.shape != null:
			var debug_mesh: Mesh = collision_shape.shape.get_debug_mesh()
			if debug_mesh != null:
				var c_aabb: AABB = debug_mesh.get_aabb()
				var c_r: float = _estimate_transformed_aabb_clearance_radius(collision_shape.global_transform, c_aabb)
				max_radius = maxf(max_radius, c_r)
			else:
				max_radius = maxf(max_radius, node_pos.length() + 0.5)

	if is_instance_valid(root3d):
		root3d.free()
	if max_radius <= 0.001:
		max_radius = 0.75
	return max_radius


func _placement_overlaps_blocker(
	space_state: PhysicsDirectSpaceState3D,
	query: PhysicsShapeQueryParameters3D,
	sphere: SphereShape3D,
	world_position: Vector3,
	radius: float,
	target_node: Node3D
) -> bool:
	sphere.radius = maxf(0.01, radius)
	query.transform = Transform3D(Basis.IDENTITY, world_position)
	var hits: Array = space_state.intersect_shape(query, 16)
	if hits.is_empty():
		return false
	for hit_variant: Variant in hits:
		if not (hit_variant is Dictionary):
			continue
		var hit: Dictionary = hit_variant as Dictionary
		var collider_obj: Object = hit.get("collider", null)
		if collider_obj == null:
			continue
		if _hit_matches_target(collider_obj, target_node):
			continue
		return true
	return false


func _sample_terrain_data(target_node: Node3D, sample_origin: Vector3) -> Dictionary:
	var terrain_data: Object = target_node.get("data") as Object
	if terrain_data == null:
		return {}
	if not terrain_data.has_method("get_height"):
		return {}
	var height_variant: Variant = terrain_data.call("get_height", sample_origin)
	var height_value: float = NAN
	var height_type: int = typeof(height_variant)
	if height_type == TYPE_FLOAT or height_type == TYPE_INT:
		height_value = float(height_variant)
	if is_nan(height_value):
		return {}

	var normal_value: Vector3 = Vector3.UP
	if terrain_data.has_method("get_normal"):
		var normal_variant: Variant = terrain_data.call("get_normal", sample_origin)
		if typeof(normal_variant) == TYPE_VECTOR3:
			normal_value = normal_variant
	if normal_value.length_squared() <= 0.000001:
		normal_value = Vector3.UP
	else:
		normal_value = normal_value.normalized()

	return {
		"position": Vector3(sample_origin.x, height_value, sample_origin.z),
		"normal": normal_value,
		"collider": target_node
	}


func _hit_matches_target(collider_obj: Object, target: Node3D) -> bool:
	if _is_collider_under_target(collider_obj, target):
		return true
	if _is_terrain_node(target):
		# Terrain3D can use internal collision wrappers not parented under the target node.
		return true
	return false


func _is_collider_under_target(collider_obj: Object, target: Node3D) -> bool:
	var node: Node = collider_obj as Node
	if node == null:
		return false
	var current: Node = node
	while current != null:
		if current == target:
			return true
		current = current.get_parent()
	return false


func _on_clear_generated_pressed() -> void:
	if _editor_interface == null:
		return
	var scene_root: Node = _editor_interface.get_edited_scene_root()
	if scene_root == null:
		return
	var target_path_text: String = _target_path_edit.text.strip_edges()
	if target_path_text.is_empty():
		_set_status("Autocliff: target path is empty.", true)
		return
	var target_any: Node = scene_root.get_node_or_null(NodePath(target_path_text))
	if target_any == null:
		_set_status("Autocliff: target path not found.", true)
		return
	if not _is_terrain_node(target_any):
		_set_status("Autocliff: target must be Terrain3D.", true)
		return
	var target_node: Node3D = target_any as Node3D
	if target_node == null:
		_set_status("Autocliff: Terrain3D target is not Node3D-compatible.", true)
		return
	var output_parent: Node = target_node.get_parent()
	if output_parent == null:
		output_parent = scene_root
	var output_name: String = _output_name_edit.text.strip_edges()
	if output_name.is_empty():
		output_name = "Autocliff_%s" % target_node.name
	var existing_output: Node = output_parent.get_node_or_null(NodePath(output_name))
	if existing_output == null:
		_set_status("Autocliff: no generated node found to clear.", true)
		return
	existing_output.queue_free()
	_set_status("Autocliff: cleared generated node '%s'." % output_name, false)


func _get_first_selected_node3d() -> Node3D:
	if _editor_interface == null:
		return null
	var selection: EditorSelection = _editor_interface.get_selection()
	if selection == null:
		return null
	var selected_nodes: Array = selection.get_selected_nodes()
	for item in selected_nodes:
		var node3d: Node3D = item as Node3D
		if node3d != null:
			return node3d
	return null


func _get_first_selected_terrain_node() -> Node3D:
	if _editor_interface == null:
		return null
	var selection: EditorSelection = _editor_interface.get_selection()
	if selection == null:
		return null
	var selected_nodes: Array = selection.get_selected_nodes()
	for item in selected_nodes:
		var node: Node = item as Node
		if node == null:
			continue
		if _is_terrain_node(node):
			return node as Node3D
	return null


func _is_terrain_node(node: Node) -> bool:
	if node == null:
		return false
	return node.is_class("Terrain3D")


func _set_status(message: String, is_error: bool) -> void:
	if _status_label == null:
		return
	if is_error:
		_status_label.text = "ERROR: " + message
	else:
		_status_label.text = message
