# Copyright © 2025 Cory Petkovsek, Roope Palmroos, and Contributors.
# Editor Plugin for Terrain3D
@tool
extends EditorPlugin


# Includes
const UI: Script = preload("res://addons/terrain_3d/src/ui.gd")
const RegionGizmo: Script = preload("res://addons/terrain_3d/src/region_gizmo.gd")
const ASSET_DOCK: String = "res://addons/terrain_3d/src/asset_dock.tscn"
const TERRAIN_TEXTURE_FILTER_LINEAR: int = 0
const DENSETSU_ENABLE_COMPLIANCE_PATH: String = "terrain3d/densetsu/enable_compliance_pass"
const DENSETSU_FORCE_LINEAR_FILTER_PATH: String = "terrain3d/densetsu/force_linear_texture_filter"
const DENSETSU_MIN_NORMAL_DEPTH_PATH: String = "terrain3d/densetsu/min_normal_depth"
const DENSETSU_REPAIR_IMPORTS_PATH: String = "terrain3d/densetsu/repair_texture_imports"
const DENSETSU_ENABLE_IMPORT_MIPMAPS_PATH: String = "terrain3d/densetsu/enable_import_mipmaps"
const DENSETSU_APPLY_ON_SELECTION_PATH: String = "terrain3d/densetsu/apply_on_selection"
const DENSETSU_FORCE_VRAM_COMPRESSION_PATH: String = "terrain3d/densetsu/force_vram_compression"
const DENSETSU_REIMPORT_BATCH_SIZE_PATH: String = "terrain3d/densetsu/reimport_batch_size"
const DENSETSU_DEFAULT_ENABLE_COMPLIANCE: bool = true
const DENSETSU_DEFAULT_FORCE_LINEAR_FILTER: bool = true
const DENSETSU_DEFAULT_MIN_NORMAL_DEPTH: float = 1.0
const DENSETSU_DEFAULT_REPAIR_IMPORTS: bool = true
const DENSETSU_DEFAULT_ENABLE_IMPORT_MIPMAPS: bool = true
const DENSETSU_DEFAULT_APPLY_ON_SELECTION: bool = false
const DENSETSU_DEFAULT_FORCE_VRAM_COMPRESSION: bool = true
const DENSETSU_DEFAULT_REIMPORT_BATCH_SIZE: int = 24

var modifier_ctrl: bool
var modifier_alt: bool
var modifier_shift: bool
var _last_modifiers: int = 0
var _input_mode: int = 0 # -1: camera move, 0: none, 1: operating
var rmb_release_time: int = 0
var _use_meta: bool = false

var terrain: Terrain3D
var _last_terrain: Terrain3D
var nav_region: NavigationRegion3D

var editor: Terrain3DEditor
var editor_settings: EditorSettings
var ui: Node # Terrain3DUI see Godot #75388
var asset_dock: PanelContainer
var region_gizmo: RegionGizmo
var current_region_position: Vector2
var mouse_global_position: Vector3 = Vector3.ZERO
var godot_editor_window: Window # The Godot Editor window
var _warned_missing_data_dirs: Dictionary = {}


func _init() -> void:
	if OS.get_name() == "macOS":
		_use_meta = true
	
	# Get the Godot Editor window. Structure is root:Window/EditorNode/Base Control
	godot_editor_window = EditorInterface.get_base_control().get_parent().get_parent()
	godot_editor_window.focus_entered.connect(_on_godot_focus_entered)

	
func _enter_tree() -> void:
	editor = Terrain3DEditor.new()
	setup_editor_settings()
	ui = UI.new()
	ui.plugin = self
	add_child(ui)

	region_gizmo = RegionGizmo.new()

	scene_changed.connect(_on_scene_changed)

	asset_dock = load(ASSET_DOCK).instantiate()
	asset_dock.initialize(self)


func _exit_tree() -> void:
	asset_dock.remove_dock(true)
	asset_dock.queue_free()
	ui.queue_free()
	editor.free()

	scene_changed.disconnect(_on_scene_changed)
	godot_editor_window.focus_entered.disconnect(_on_godot_focus_entered)


func _on_godot_focus_entered() -> void:
	_read_input()
	ui.update_decal()


## EditorPlugin selection function call chain isn't consistent. Here's the map of calls:
## Assume we handle Terrain3D and NavigationRegion3D  
# Click Terrain3D: 					_handles(Terrain3D), _make_visible(true), _edit(Terrain3D)
# Deselect:							_make_visible(false), _edit(null)
# Click other node:					_handles(OtherNode)
# Click NavRegion3D:				_handles(NavReg3D), _make_visible(true), _edit(NavReg3D)
# Click NavRegion3D, Terrain3D:		_handles(Terrain3D), _edit(Terrain3D)
# Click Terrain3D, NavRegion3D:		_handles(NavReg3D), _edit(NavReg3D)
func _handles(p_object: Object) -> bool:
	if p_object is Terrain3D:
		return true
	elif p_object is NavigationRegion3D and is_instance_valid(_last_terrain):
		return true
	
	# Terrain3DObjects requires access to EditorUndoRedoManager. The only way to make sure it
	# always has it, is to pass it in here. _edit is NOT called if the node is cut and pasted.
	elif p_object is Terrain3DObjects:
		p_object.editor_setup(self)
	elif p_object is Node3D and p_object.get_parent() is Terrain3DObjects:
		p_object.get_parent().editor_setup(self)
	
	return false


func _make_visible(p_visible: bool, p_redraw: bool = false) -> void:
	if p_visible and is_selected():
		ui.set_visible(true)
		asset_dock.update_dock()
	else:
		ui.set_visible(false)


func _edit(p_object: Object) -> void:
	if !p_object:
		_clear()

	if p_object is Terrain3D:
		if p_object == terrain:
			return
		if bool(get_setting(DENSETSU_APPLY_ON_SELECTION_PATH, DENSETSU_DEFAULT_APPLY_ON_SELECTION)):
			_apply_densetsu_terrain_compliance_single(p_object)
		terrain = p_object
		_last_terrain = terrain
		terrain.set_plugin(self)
		terrain.set_editor(editor)
		editor.set_terrain(terrain)
		region_gizmo.set_node_3d(terrain)
		terrain.add_gizmo(region_gizmo)
		ui.set_visible(true)
		terrain.set_meta("_edit_lock_", true)

		# Get alerted when a new asset list is loaded
		if not terrain.assets_changed.is_connected(asset_dock.update_assets):
			terrain.assets_changed.connect(asset_dock.update_assets)
		asset_dock.update_assets()
		# Get alerted when the region map changes
		if not terrain.data.region_map_changed.is_connected(update_region_grid):
			terrain.data.region_map_changed.connect(update_region_grid)
		update_region_grid()
	else:
		_clear()

	if is_terrain_valid(_last_terrain):
		if p_object is NavigationRegion3D:
			ui.set_visible(true, true)
			nav_region = p_object
		else:
			nav_region = null

	
func _clear() -> void:
	if is_terrain_valid():
		_save_terrain_data(terrain)
		if terrain.data.region_map_changed.is_connected(update_region_grid):
			terrain.data.region_map_changed.disconnect(update_region_grid)
		
		terrain.clear_gizmos()
		terrain = null
		editor.set_terrain(null)
		
		ui.clear_picking()
		
	region_gizmo.clear()


func _forward_3d_gui_input(p_viewport_camera: Camera3D, p_event: InputEvent) -> AfterGUIInput:
	if not is_terrain_valid():
		return AFTER_GUI_INPUT_PASS

	var continue_input: AfterGUIInput = _read_input(p_event)
	if continue_input != AFTER_GUI_INPUT_CUSTOM:
		return continue_input
	ui.update_decal()
	
	## Setup active camera & viewport
	# Always update this for all inputs, as the mouse position can move without
	# necessarily being a InputEventMouseMotion object. get_intersection() also
	# returns the last frame position, and should be updated more frequently.
	
	# Snap terrain to current camera 
	terrain.set_camera(p_viewport_camera)

	# Detect if viewport is set to half_resolution
	# Structure is: Node3DEditorViewportContainer/Node3DEditorViewport(4)/SubViewportContainer/SubViewport/Camera3D
	var editor_vpc: SubViewportContainer = p_viewport_camera.get_parent().get_parent()
	var full_resolution: bool = false if editor_vpc.stretch_shrink == 2 else true

	## Get mouse location on terrain
	# Project 2D mouse position to 3D position and direction
	var vp_mouse_pos: Vector2 = editor_vpc.get_local_mouse_position()
	var mouse_pos: Vector2 = vp_mouse_pos if full_resolution else vp_mouse_pos / 2
	var camera_pos: Vector3 = p_viewport_camera.project_ray_origin(mouse_pos)
	var camera_dir: Vector3 = p_viewport_camera.project_ray_normal(mouse_pos)

	# If region tool, grab mouse position without considering height
	if editor.get_tool() == Terrain3DEditor.REGION:
		var t = -Vector3(0, 1, 0).dot(camera_pos) / Vector3(0, 1, 0).dot(camera_dir)
		mouse_global_position = (camera_pos + t * camera_dir)
	else:
	#Else look for intersection with terrain
		var intersection_point: Vector3 = terrain.get_intersection(camera_pos, camera_dir, true)
		if intersection_point.z > 3.4e38 or is_nan(intersection_point.y): # max double or nan
			return AFTER_GUI_INPUT_PASS
		mouse_global_position = intersection_point
	
	## Handle mouse movement
	if p_event is InputEventMouseMotion:

		if _input_mode != -1: # Not cam rotation
			## Update region highlight
			var region_position: Vector2 = ( Vector2(mouse_global_position.x, mouse_global_position.z) \
				/ (terrain.get_region_size() * terrain.get_vertex_spacing()) ).floor()
			if current_region_position != region_position:
				current_region_position = region_position
				update_region_grid()

			if _input_mode > 0 and editor.is_operating():
				# Inject pressure - Relies on C++ set_brush_data() using same dictionary instance
				ui.brush_data["mouse_pressure"] = p_event.pressure

				editor.operate(mouse_global_position, p_viewport_camera.rotation.y)
				return AFTER_GUI_INPUT_STOP
			
		return AFTER_GUI_INPUT_PASS

	if p_event is InputEventMouseButton and _input_mode > 0:
		if p_event.is_pressed():
			# If picking
			if ui.is_picking():
				ui.pick(mouse_global_position)
				if not ui.operation_builder or not ui.operation_builder.is_ready():
					return AFTER_GUI_INPUT_STOP
			
			if modifier_ctrl and editor.get_tool() == Terrain3DEditor.HEIGHT:
				var height: float = terrain.data.get_height(mouse_global_position)
				ui.brush_data["height"] = height
				ui.tool_settings.set_setting("height", height)
				
			# If adjusting regions
			if editor.get_tool() == Terrain3DEditor.REGION:
				# Skip regions that already exist or don't
				var has_region: bool = terrain.data.has_regionp(mouse_global_position)
				var op: int = editor.get_operation()
				if	( has_region and op == Terrain3DEditor.ADD) or \
					( not has_region and op == Terrain3DEditor.SUBTRACT ):
					return AFTER_GUI_INPUT_STOP
			
			# If an automatic operation is ready to go (e.g. gradient)
			if ui.operation_builder and ui.operation_builder.is_ready():
				ui.operation_builder.apply_operation(editor, mouse_global_position, p_viewport_camera.rotation.y)
				return AFTER_GUI_INPUT_STOP
			
			# Mouse clicked, start editing
			editor.start_operation(mouse_global_position)
			editor.operate(mouse_global_position, p_viewport_camera.rotation.y)
			return AFTER_GUI_INPUT_STOP
		
		# _input_apply released, save undo data
		elif editor.is_operating():
			editor.stop_operation()
			_save_terrain_data(terrain)
			return AFTER_GUI_INPUT_STOP

	return AFTER_GUI_INPUT_PASS


func _read_input(p_event: InputEvent = null) -> AfterGUIInput:
	## Determine if user is moving camera or applying
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or \
		p_event is InputEventMouseButton and p_event.is_released() and \
		p_event.get_button_index() == MOUSE_BUTTON_LEFT:
			_input_mode = 1 
	else:
			_input_mode = 0
	
	match get_setting("editors/3d/navigation/navigation_scheme", 0):
		2, 1: # Modo, Maya
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or \
	 			( Input.is_key_pressed(KEY_ALT) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) ):
					_input_mode = -1 
			if p_event is InputEventMouseButton and p_event.is_released() and \
				( p_event.get_button_index() == MOUSE_BUTTON_RIGHT or \
				( Input.is_key_pressed(KEY_ALT) and p_event.get_button_index() == MOUSE_BUTTON_LEFT )):
					rmb_release_time = Time.get_ticks_msec()
		0, _: # Godot
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or \
				Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
					_input_mode = -1 
			if p_event is InputEventMouseButton and p_event.is_released() and \
				( p_event.get_button_index() == MOUSE_BUTTON_RIGHT or \
				p_event.get_button_index() == MOUSE_BUTTON_MIDDLE ):
					rmb_release_time = Time.get_ticks_msec()
	if _input_mode < 0:
		# Camera is moving, skip input
		return AFTER_GUI_INPUT_PASS

	## Determine modifiers pressed
	modifier_shift = Input.is_key_pressed(KEY_SHIFT)
	
	# Editor responds to modifier_ctrl so we must register touchscreen Invert 
	if _use_meta:
		modifier_ctrl = Input.is_key_pressed(KEY_META) || ui.inverted_input
	else:
		modifier_ctrl = Input.is_key_pressed(KEY_CTRL) || ui.inverted_input
	
	# Keybind enum: Alt,Space,Meta,Capslock
	var alt_key: int
	match get_setting("terrain3d/config/alt_key_bind", 0):
		3: alt_key = KEY_CAPSLOCK
		2: alt_key = KEY_META
		1: alt_key = KEY_SPACE
		0, _: alt_key = KEY_ALT
	modifier_alt = Input.is_key_pressed(alt_key)
	var current_mods: int = int(modifier_shift) | int(modifier_ctrl) << 1 | int(modifier_alt) << 2

	## Process Hotkeys
	if p_event is InputEventKey and \
			current_mods == 0 and \
			p_event.is_pressed() and \
			not p_event.is_echo() and \
			consume_hotkey(p_event.keycode):
		# Hotkey found, consume event, and stop input processing
		EditorInterface.get_editor_viewport_3d().set_input_as_handled()
		return AFTER_GUI_INPUT_STOP

	# Brush data is cleared on set_tool, or clicking textures in the asset dock
	# Update modifiers if changed or missing
	if  _last_modifiers != current_mods or not ui.brush_data.has("modifier_shift"):
		_last_modifiers = current_mods
		ui.brush_data["modifier_shift"] = modifier_shift
		ui.brush_data["modifier_ctrl"] = modifier_ctrl
		ui.brush_data["modifier_alt"] = modifier_alt
		ui.set_active_operation()

	## Continue processing input
	return AFTER_GUI_INPUT_CUSTOM


# Returns true if hotkey matches and operation triggered
func consume_hotkey(keycode: int) -> bool:
	match keycode:
		KEY_1:
			terrain.material.set_show_region_grid(!terrain.material.get_show_region_grid())
		KEY_2:
			terrain.material.set_show_instancer_grid(!terrain.material.get_show_instancer_grid())
		KEY_3:
			terrain.material.set_show_vertex_grid(!terrain.material.get_show_vertex_grid())
		KEY_4:
			terrain.material.set_show_contours(!terrain.material.get_show_contours())
		KEY_E:
			ui.toolbar.get_button("AddRegion").set_pressed(true)
		KEY_R:
			ui.toolbar.get_button("Raise").set_pressed(true)
		KEY_H:
			ui.toolbar.get_button("Height").set_pressed(true)
		KEY_S:
			ui.toolbar.get_button("Slope").set_pressed(true)
		KEY_C:
			ui.toolbar.get_button("PaintColor").set_pressed(true)
		KEY_N:
			ui.toolbar.get_button("PaintNavigableArea").set_pressed(true)
		KEY_I:
			ui.toolbar.get_button("InstanceMeshes").set_pressed(true)
		KEY_X:
			ui.toolbar.get_button("AddHoles").set_pressed(true)
		KEY_W:
			ui.toolbar.get_button("PaintWetness").set_pressed(true)
		KEY_B:
			ui.toolbar.get_button("PaintTexture").set_pressed(true)
		KEY_V:
			ui.toolbar.get_button("SprayTexture").set_pressed(true)
		KEY_A:
			ui.toolbar.get_button("PaintAutoshader").set_pressed(true)
		_:
			return false
	return true


func update_region_grid() -> void:
	if not region_gizmo:
		return
	region_gizmo.set_hidden(not ui.visible)

	if is_terrain_valid():
		region_gizmo.show_rect = editor.get_tool() == Terrain3DEditor.REGION
		region_gizmo.use_secondary_color = editor.get_operation() == Terrain3DEditor.SUBTRACT
		region_gizmo.region_position = current_region_position
		region_gizmo.region_size = terrain.get_region_size() * terrain.get_vertex_spacing()
		region_gizmo.grid = terrain.get_data().get_region_locations()
		
		terrain.update_gizmos()
		return
		
	region_gizmo.show_rect = false
	region_gizmo.region_size = 1024
	region_gizmo.grid = [Vector2i.ZERO]


func _on_scene_changed(scene_root: Node) -> void:
	if not scene_root:
		return

	_apply_densetsu_terrain_compliance(scene_root)
		
	for node in scene_root.find_children("", "Terrain3DObjects"):
		node.editor_setup(self)

	asset_dock.update_assets()
	await get_tree().create_timer(2).timeout
	asset_dock.update_thumbnails()


func _build() -> bool:
	_save_all_terrain_data()
	return true


func _apply_changes() -> void:
	_save_all_terrain_data()


func _save_external_data() -> void:
	_save_all_terrain_data()


func _save_all_terrain_data() -> void:
	var scene_root: Node = EditorInterface.get_edited_scene_root()
	if scene_root == null:
		return

	var terrains: Array = scene_root.find_children("", "Terrain3D", true, false)
	for node_variant: Variant in terrains:
		var terrain_node: Terrain3D = node_variant as Terrain3D
		_save_terrain_data(terrain_node)


func _save_terrain_data(terrain_node: Terrain3D) -> void:
	if terrain_node == null or terrain_node.data == null:
		return

	var dir_path: String = terrain_node.get_data_directory()
	if dir_path.is_empty():
		var key := str(terrain_node.get_path())
		if not _warned_missing_data_dirs.has(key):
			_warned_missing_data_dirs[key] = true
			push_warning("Terrain3D: data_directory is empty on %s. Terrain paint cannot be persisted." % key)
		return

	var global_dir: String = ProjectSettings.globalize_path(dir_path)
	if not DirAccess.dir_exists_absolute(global_dir):
		var mk_err: int = DirAccess.make_dir_recursive_absolute(global_dir)
		if mk_err != OK and mk_err != ERR_ALREADY_EXISTS:
			push_warning("Terrain3D: Failed creating data directory: %s (%s)" % [dir_path, error_string(mk_err)])
			return

	terrain_node.data.save_directory(dir_path)

		
func is_terrain_valid(p_terrain: Terrain3D = null) -> bool:
	var t: Terrain3D
	if p_terrain:
		t = p_terrain
	else:
		t = terrain
	if is_instance_valid(t) and t.is_inside_tree() and t.data:
		return true
	return false


func is_selected() -> bool:
	var selected: Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	for node in selected:
		if ( is_instance_valid(_last_terrain) and node.get_instance_id() == _last_terrain.get_instance_id() ) or \
			node is Terrain3D:
				return true
	return false	


func select_terrain() -> void:
	if is_instance_valid(_last_terrain) and is_terrain_valid(_last_terrain) and not is_selected():
		var es: EditorSelection = EditorInterface.get_selection()
		es.clear()
		es.add_node(_last_terrain)


## Editor Settings


func setup_editor_settings() -> void:
	editor_settings = EditorInterface.get_editor_settings()
	if not editor_settings.has_setting("terrain3d/config/alt_key_bind"):
		editor_settings.set("terrain3d/config/alt_key_bind", 0)
	if not editor_settings.has_setting(DENSETSU_ENABLE_COMPLIANCE_PATH):
		editor_settings.set(DENSETSU_ENABLE_COMPLIANCE_PATH, DENSETSU_DEFAULT_ENABLE_COMPLIANCE)
	if not editor_settings.has_setting(DENSETSU_FORCE_LINEAR_FILTER_PATH):
		editor_settings.set(DENSETSU_FORCE_LINEAR_FILTER_PATH, DENSETSU_DEFAULT_FORCE_LINEAR_FILTER)
	if not editor_settings.has_setting(DENSETSU_MIN_NORMAL_DEPTH_PATH):
		editor_settings.set(DENSETSU_MIN_NORMAL_DEPTH_PATH, DENSETSU_DEFAULT_MIN_NORMAL_DEPTH)
	if not editor_settings.has_setting(DENSETSU_REPAIR_IMPORTS_PATH):
		editor_settings.set(DENSETSU_REPAIR_IMPORTS_PATH, DENSETSU_DEFAULT_REPAIR_IMPORTS)
	if not editor_settings.has_setting(DENSETSU_ENABLE_IMPORT_MIPMAPS_PATH):
		editor_settings.set(DENSETSU_ENABLE_IMPORT_MIPMAPS_PATH, DENSETSU_DEFAULT_ENABLE_IMPORT_MIPMAPS)
	if not editor_settings.has_setting(DENSETSU_APPLY_ON_SELECTION_PATH):
		editor_settings.set(DENSETSU_APPLY_ON_SELECTION_PATH, DENSETSU_DEFAULT_APPLY_ON_SELECTION)
	if not editor_settings.has_setting(DENSETSU_FORCE_VRAM_COMPRESSION_PATH):
		editor_settings.set(DENSETSU_FORCE_VRAM_COMPRESSION_PATH, DENSETSU_DEFAULT_FORCE_VRAM_COMPRESSION)
	if not editor_settings.has_setting(DENSETSU_REIMPORT_BATCH_SIZE_PATH):
		editor_settings.set(DENSETSU_REIMPORT_BATCH_SIZE_PATH, DENSETSU_DEFAULT_REIMPORT_BATCH_SIZE)

	var property_info = {
		"name": "terrain3d/config/alt_key_bind",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Alt,Space,Meta,Capslock"
	}
	editor_settings.add_property_info(property_info)
	editor_settings.add_property_info({
		"name": DENSETSU_ENABLE_COMPLIANCE_PATH,
		"type": TYPE_BOOL
	})
	editor_settings.add_property_info({
		"name": DENSETSU_FORCE_LINEAR_FILTER_PATH,
		"type": TYPE_BOOL
	})
	editor_settings.add_property_info({
		"name": DENSETSU_MIN_NORMAL_DEPTH_PATH,
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "0.0,8.0,0.01"
	})
	editor_settings.add_property_info({
		"name": DENSETSU_REPAIR_IMPORTS_PATH,
		"type": TYPE_BOOL
	})
	editor_settings.add_property_info({
		"name": DENSETSU_ENABLE_IMPORT_MIPMAPS_PATH,
		"type": TYPE_BOOL
	})
	editor_settings.add_property_info({
		"name": DENSETSU_APPLY_ON_SELECTION_PATH,
		"type": TYPE_BOOL
	})
	editor_settings.add_property_info({
		"name": DENSETSU_FORCE_VRAM_COMPRESSION_PATH,
		"type": TYPE_BOOL
	})
	editor_settings.add_property_info({
		"name": DENSETSU_REIMPORT_BATCH_SIZE_PATH,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,128,1"
	})
	

func set_setting(p_str: String, p_value: Variant) -> void:
	editor_settings.set_setting(p_str, p_value)


func get_setting(p_str: String, p_default: Variant) -> Variant:
	if editor_settings.has_setting(p_str):
		return editor_settings.get_setting(p_str)
	else:
		return p_default


func has_setting(p_str: String) -> bool:
	return editor_settings.has_setting(p_str)


func erase_setting(p_str: String) -> void:
	editor_settings.erase(p_str)


func _apply_densetsu_terrain_compliance(scene_root: Node) -> void:
	var enabled: bool = bool(get_setting(DENSETSU_ENABLE_COMPLIANCE_PATH, DENSETSU_DEFAULT_ENABLE_COMPLIANCE))
	if not enabled:
		return

	var force_linear_filter: bool = bool(get_setting(DENSETSU_FORCE_LINEAR_FILTER_PATH, DENSETSU_DEFAULT_FORCE_LINEAR_FILTER))
	var min_normal_depth: float = float(get_setting(DENSETSU_MIN_NORMAL_DEPTH_PATH, DENSETSU_DEFAULT_MIN_NORMAL_DEPTH))
	min_normal_depth = max(min_normal_depth, 0.0)
	var repair_imports: bool = bool(get_setting(DENSETSU_REPAIR_IMPORTS_PATH, DENSETSU_DEFAULT_REPAIR_IMPORTS))
	var enable_import_mipmaps: bool = bool(get_setting(DENSETSU_ENABLE_IMPORT_MIPMAPS_PATH, DENSETSU_DEFAULT_ENABLE_IMPORT_MIPMAPS))
	var force_vram_compression: bool = bool(get_setting(DENSETSU_FORCE_VRAM_COMPRESSION_PATH, DENSETSU_DEFAULT_FORCE_VRAM_COMPRESSION))

	var terrains: Array = scene_root.find_children("", "Terrain3D", true, false)
	if terrains.is_empty():
		return

	var filter_changed: int = 0
	var normal_depth_changed: int = 0
	var import_file_changed: int = 0
	var reimport_paths_map: Dictionary = {}

	for node_variant: Variant in terrains:
		var terrain_node: Terrain3D = node_variant as Terrain3D
		if terrain_node == null:
			continue
		var summary: Dictionary = _apply_densetsu_terrain_compliance_to_node(terrain_node, force_linear_filter, min_normal_depth, repair_imports, enable_import_mipmaps, force_vram_compression, reimport_paths_map)
		filter_changed += int(summary.get("filter_changed", 0))
		normal_depth_changed += int(summary.get("normal_depth_changed", 0))
		import_file_changed += int(summary.get("import_file_changed", 0))

	if not reimport_paths_map.is_empty():
		var reimport_paths: PackedStringArray = PackedStringArray()
		for path_variant: Variant in reimport_paths_map.keys():
			var path: String = String(path_variant)
			if not path.is_empty():
				reimport_paths.append(path)
		if not reimport_paths.is_empty():
			_reimport_files_deferred(reimport_paths)

	if filter_changed > 0 or normal_depth_changed > 0 or import_file_changed > 0:
		print("Terrain3D Densetsu compliance: filter=", filter_changed, ", normal_depth=", normal_depth_changed, ", import_updates=", import_file_changed)


func _apply_densetsu_terrain_compliance_single(terrain_node: Terrain3D) -> void:
	var enabled: bool = bool(get_setting(DENSETSU_ENABLE_COMPLIANCE_PATH, DENSETSU_DEFAULT_ENABLE_COMPLIANCE))
	if not enabled or terrain_node == null:
		return

	var force_linear_filter: bool = bool(get_setting(DENSETSU_FORCE_LINEAR_FILTER_PATH, DENSETSU_DEFAULT_FORCE_LINEAR_FILTER))
	var min_normal_depth: float = float(get_setting(DENSETSU_MIN_NORMAL_DEPTH_PATH, DENSETSU_DEFAULT_MIN_NORMAL_DEPTH))
	min_normal_depth = max(min_normal_depth, 0.0)
	var repair_imports: bool = bool(get_setting(DENSETSU_REPAIR_IMPORTS_PATH, DENSETSU_DEFAULT_REPAIR_IMPORTS))
	var enable_import_mipmaps: bool = bool(get_setting(DENSETSU_ENABLE_IMPORT_MIPMAPS_PATH, DENSETSU_DEFAULT_ENABLE_IMPORT_MIPMAPS))
	var force_vram_compression: bool = bool(get_setting(DENSETSU_FORCE_VRAM_COMPRESSION_PATH, DENSETSU_DEFAULT_FORCE_VRAM_COMPRESSION))

	var reimport_paths_map: Dictionary = {}
	var summary: Dictionary = _apply_densetsu_terrain_compliance_to_node(terrain_node, force_linear_filter, min_normal_depth, repair_imports, enable_import_mipmaps, force_vram_compression, reimport_paths_map)

	if not reimport_paths_map.is_empty():
		var reimport_paths: PackedStringArray = PackedStringArray()
		for path_variant: Variant in reimport_paths_map.keys():
			var path: String = String(path_variant)
			if not path.is_empty():
				reimport_paths.append(path)
		if not reimport_paths.is_empty():
			_reimport_files_deferred(reimport_paths)

	var filter_changed: int = int(summary.get("filter_changed", 0))
	var normal_depth_changed: int = int(summary.get("normal_depth_changed", 0))
	var import_file_changed: int = int(summary.get("import_file_changed", 0))
	if filter_changed > 0 or normal_depth_changed > 0 or import_file_changed > 0:
		print("Terrain3D Densetsu compliance (selection): filter=", filter_changed, ", normal_depth=", normal_depth_changed, ", import_updates=", import_file_changed)


func _apply_densetsu_terrain_compliance_to_node(terrain_node: Terrain3D, force_linear_filter: bool, min_normal_depth: float, repair_imports: bool, enable_import_mipmaps: bool, force_vram_compression: bool, out_reimport_paths_map: Dictionary) -> Dictionary:
	var filter_changed: int = _apply_densetsu_filtering(terrain_node, force_linear_filter)
	var normal_depth_changed: int = _apply_densetsu_normal_depth(terrain_node, min_normal_depth)
	var import_file_changed: int = 0
	if repair_imports:
		import_file_changed = _repair_densetsu_terrain_imports(terrain_node, enable_import_mipmaps, force_vram_compression, out_reimport_paths_map)
	return {
		"filter_changed": filter_changed,
		"normal_depth_changed": normal_depth_changed,
		"import_file_changed": import_file_changed,
	}


func _apply_densetsu_filtering(terrain_node: Terrain3D, force_linear_filter: bool) -> int:
	if not force_linear_filter:
		return 0
	if terrain_node == null or terrain_node.material == null:
		return 0
	var material: Terrain3DMaterial = terrain_node.material
	if material.get_texture_filtering() != TERRAIN_TEXTURE_FILTER_LINEAR:
		material.set_texture_filtering(TERRAIN_TEXTURE_FILTER_LINEAR)
		return 1
	return 0


func _apply_densetsu_normal_depth(terrain_node: Terrain3D, min_normal_depth: float) -> int:
	if terrain_node == null or terrain_node.assets == null:
		return 0
	if not terrain_node.assets.has_method("get_texture_count") or not terrain_node.assets.has_method("get_texture"):
		return 0

	var changed_count: int = 0
	var texture_count: int = int(terrain_node.assets.get_texture_count())
	for i: int in range(texture_count):
		var texture_asset: Terrain3DTextureAsset = terrain_node.assets.get_texture(i)
		if texture_asset == null:
			continue
		if texture_asset.normal_texture != null and texture_asset.normal_depth < min_normal_depth:
			texture_asset.normal_depth = min_normal_depth
			changed_count += 1
	return changed_count


func _repair_densetsu_terrain_imports(terrain_node: Terrain3D, enable_mipmaps: bool, force_vram_compression: bool, out_reimport_paths_map: Dictionary) -> int:
	if terrain_node == null or terrain_node.assets == null:
		return 0
	if not terrain_node.assets.has_method("get_texture_count") or not terrain_node.assets.has_method("get_texture"):
		return 0

	var changed_count: int = 0
	var texture_count: int = int(terrain_node.assets.get_texture_count())
	for i: int in range(texture_count):
		var texture_asset: Terrain3DTextureAsset = terrain_node.assets.get_texture(i)
		if texture_asset == null:
			continue
		if texture_asset.albedo_texture != null:
			var albedo_path: String = texture_asset.albedo_texture.resource_path
			if _ensure_texture_import_settings(albedo_path, false, enable_mipmaps, force_vram_compression):
				out_reimport_paths_map[albedo_path] = true
				changed_count += 1
		if texture_asset.normal_texture != null:
			var normal_path: String = texture_asset.normal_texture.resource_path
			if _ensure_texture_import_settings(normal_path, true, enable_mipmaps, force_vram_compression):
				out_reimport_paths_map[normal_path] = true
				changed_count += 1
	return changed_count


func _ensure_texture_import_settings(texture_path: String, is_normal_map: bool, enable_mipmaps: bool, force_vram_compression: bool) -> bool:
	if texture_path.is_empty() or texture_path.begins_with("res://.godot/"):
		return false
	var import_path: String = texture_path + ".import"
	if not FileAccess.file_exists(import_path):
		return false

	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load(import_path)
	if err != OK:
		push_warning("Terrain3D Densetsu compliance: failed reading import file %s (%s)" % [import_path, error_string(err)])
		return false

	var changed: bool = false
	var current_source: String = str(cfg.get_value("deps", "source_file", ""))
	if current_source != texture_path:
		cfg.set_value("deps", "source_file", texture_path)
		changed = true

	if enable_mipmaps:
		if not bool(cfg.get_value("params", "mipmaps/generate", false)):
			cfg.set_value("params", "mipmaps/generate", true)
			changed = true
		var mip_limit: int = int(cfg.get_value("params", "mipmaps/limit", -1))
		if mip_limit != -1:
			cfg.set_value("params", "mipmaps/limit", -1)
			changed = true

	if force_vram_compression:
		var compress_mode: int = int(cfg.get_value("params", "compress/mode", 2))
		if compress_mode != 2:
			cfg.set_value("params", "compress/mode", 2)
			changed = true

	var compress_to: int = int(cfg.get_value("params", "detect_3d/compress_to", 1))
	if compress_to != 1:
		cfg.set_value("params", "detect_3d/compress_to", 1)
		changed = true

	var normal_mode_target: int = 2 if is_normal_map else 0
	var current_normal_mode: int = int(cfg.get_value("params", "compress/normal_map", normal_mode_target))
	if current_normal_mode != normal_mode_target:
		cfg.set_value("params", "compress/normal_map", normal_mode_target)
		changed = true

	if not changed:
		return false

	err = cfg.save(import_path)
	if err != OK:
		push_warning("Terrain3D Densetsu compliance: failed writing import file %s (%s)" % [import_path, error_string(err)])
		return false

	return true


func _reimport_files_deferred(paths: PackedStringArray) -> void:
	call_deferred("_reimport_files_now", paths)


func _reimport_files_now(paths: PackedStringArray) -> void:
	if paths.is_empty():
		return
	var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	if fs == null:
		return
	var unique_paths: PackedStringArray = PackedStringArray()
	var seen: Dictionary = {}
	for path: String in paths:
		if path.is_empty() or seen.has(path):
			continue
		seen[path] = true
		unique_paths.append(path)
	if unique_paths.is_empty():
		return

	var batch_size: int = int(get_setting(DENSETSU_REIMPORT_BATCH_SIZE_PATH, DENSETSU_DEFAULT_REIMPORT_BATCH_SIZE))
	batch_size = maxi(batch_size, 1)

	var start: int = 0
	while start < unique_paths.size():
		var end: int = mini(start + batch_size, unique_paths.size())
		var batch: PackedStringArray = PackedStringArray()
		for i: int in range(start, end):
			batch.append(unique_paths[i])
		fs.reimport_files(batch)
		start = end
		if start < unique_paths.size():
			await get_tree().process_frame
