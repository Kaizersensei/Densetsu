extends Node

signal editor_entered
signal editor_exited
signal selection_changed(node)

@export var toggle_action := "toggle_editor"
@export var toggle_cooldown := 0.2
@export var snap_enabled := false
@export var snap_size := 8.0
@export var zoom_step := 0.2
@export var zoom_min := 0.2
@export var zoom_max := 3.0
@export var camera_pan_speed := 400.0
@export var select_parent_action := "editor_select_parent"
var editor_mode := false
var editor_camera: Camera2D
var _game_camera: Camera2D
var _overlay: CanvasLayer
var _grid: Node2D
var _toggle_lock := 0.0
var _selected: Node
var _hovered: Node = null
var _dragging := false
var _drag_offset := Vector2.ZERO
var _highlight: Line2D
var _handles_layer: Node2D
var _handle_gizmos: Array = []
var _handle_positions: Array = []
var _rotation_handle_pos: Vector2 = Vector2.ZERO
var _drag_mode: String = ""
var _active_handle: int = -1
var _initial_transform: Transform2D
var _initial_scale: Vector2 = Vector2.ONE
var _initial_handle_local: Vector2 = Vector2.ZERO
var _initial_rotation: float = 0.0
var _initial_center: Vector2 = Vector2.ZERO
var _handle_hover_index: int = -1
var _inspector_dirty := false
var _stamp_prefab: String = ""
var _cursor_select: Resource
var _cursor_plus: Resource
var _cursor_cross: Resource
var _delete_mode := false
var _undo_stack: Array = []
var _redo_stack: Array = []
var _drag_start_state: Dictionary = {}
var _drag_start_node: Node2D
var _drag_start_screen: Vector2 = Vector2.ZERO
var _baseline_snapshot: PackedScene
var _save_path_primary := "res://editor_saves/last_scene.tscn"
var _save_path_fallback := "user://editor_save.tscn"
var _window_controller: Node = null
var _entity_popup: Control = null
var _entity_popup_state := {}
var _polygon_mode := false
var _active_polygon: Node = null
var _polygon_vertices: Array[Vector2] = []
var _poly_confirm_dialog: ConfirmationDialog = null
var _poly_drag_index := -1
var _poly_selected_index := -1
var _polygon_add_enabled := true
var _primary_player: Node2D = null
const HISTORY_TRANSFORM := "transform"
const HISTORY_CREATE := "create"
const HISTORY_DELETE := "delete"
var _last_pick_hits: Array = []
var _last_pick_pos: Vector2 = Vector2.ZERO
var _last_pick_cycle: int = 0
var show_hitboxes := false
const PREFAB_NAMES := {
	"solid": "Solid",
	"one_way": "One-Way",
	"water": "Water",
	"teleporter": "Teleporter",
	"deco": "Deco",
	"deco_solid": "Solid Deco",
	"trap": "Trap",
	"item": "Item",
	"actor": "Actor",
	"player": "Player",
	"enemy": "Enemy",
	"npc": "NPC",
	"spawner": "Actor Spawner",
}
const PREFAB_DEFAULT_DATA := {
	"player": "ACTOR_Player",
	"enemy": "ACTOR_Enemy",
	"npc": "ACTOR_NPC",
	"solid": "PLATFORM_SolidGround",
	"one_way": "PLATFORM_OneWay_Default",
	"water": "SCENERY_WaterVolume",
	"teleporter": "TELEPORTER_Default",
	"trap": "TRAP_Basic",
	"item": "ITEM_Floating",
	"deco": "SCENERY_Deco",
	"deco_solid": "SCENERY_DecoStatic",
	"spawner": "SPAWNER_Enemy",
}
var _data_editor: Node

func _ready() -> void:
	set_process_input(true)
	set_process_unhandled_input(true)
	set_process_unhandled_key_input(true)
	_ensure_toggle_action()
	_ensure_polygon_action()
	_ensure_hitbox_toggle_action()
	_ensure_editor_camera_actions()
	_ensure_select_parent_action()
	_sanitize_input_maps()
	print("EditorManager ready. Toggle action:", toggle_action)
	_overlay = preload("res://engine/editor/EditorOverlay.tscn").instantiate()
	_overlay.visible = false
	add_child(_overlay)
	if _overlay and _overlay.has_method("connect_inspector"):
		_overlay.connect_inspector(_on_inspector_changed)
	if _overlay and _overlay.has_method("connect_prefab_buttons"):
		_overlay.connect_prefab_buttons(_on_prefab_selected)
	_window_controller = _ensure_window_controller()
	if _window_controller:
		_window_controller.set("top_margin", _get_ribbon_height())
	if _overlay and _overlay.has_method("register_popups"):
		_overlay.register_popups(_window_controller)
	editor_camera = preload("res://engine/editor/EditorCamera2D.tscn").instantiate()
	editor_camera.enabled = false
	editor_camera.visible = false
	add_child(editor_camera)
	_grid = preload("res://engine/editor/GridOverlay.gd").new()
	_grid.visible = false
	add_child(_grid)
	_data_editor = preload("res://engine/editor/DataEditor.tscn").instantiate()
	_data_editor.visible = false
	if _overlay:
		_overlay.add_child(_data_editor)
	_entity_popup = preload("res://engine/editor/EntityInspectorPopup.tscn").instantiate()
	_entity_popup.visible = false
	if _overlay:
		_overlay.add_child(_entity_popup)
	_highlight = Line2D.new()
	_highlight.width = 1.5
	_highlight.default_color = Color(1, 0.8, 0.2, 0.8)
	_highlight.visible = false
	_highlight.z_index = 1000
	add_child(_highlight)
	_handles_layer = Node2D.new()
	_handles_layer.z_index = 2000
	_handles_layer.z_as_relative = false
	add_child(_handles_layer)
	_create_handle_gizmos()
	_cursor_select = preload("res://engine/editor/icons/cursor_select.png")
	_cursor_plus = preload("res://engine/editor/icons/cursor_plus.png")
	_cursor_cross = preload("res://engine/editor/icons/cursor_cross.png")
	_baseline_snapshot = _make_scene_snapshot()
	_connect_data_registry()
	_poly_confirm_dialog = ConfirmationDialog.new()
	_poly_confirm_dialog.dialog_text = "Polygon requires at least three points. Deleting this point will cancel polygon editing."
	_poly_confirm_dialog.ok_button_text = "Cancel and remove polygon"
	_poly_confirm_dialog.get_cancel_button().text = "Keep editing"
	_poly_confirm_dialog.visible = false
	add_child(_poly_confirm_dialog)
	if get_tree():
		get_tree().node_added.connect(_on_tree_node_added)
		get_tree().node_removed.connect(_on_tree_node_removed)
	_center_game_camera(true)
	_reapply_all_tints()
	_check_enter_editor_flag()


func _check_enter_editor_flag() -> void:
	var tree := get_tree()
	if tree == null:
		return
	if tree.has_meta("enter_editor_next") and tree.get_meta("enter_editor_next") == true:
		tree.set_meta("enter_editor_next", false)
		if not editor_mode:
			_toggle_editor()


func _capture_transform(n: Node2D) -> Dictionary:
	return {
		"position": n.position,
		"rotation": n.rotation,
		"scale": n.scale,
	}


func _transform_equals(a: Dictionary, b: Dictionary) -> bool:
	return a.get("position", Vector2.ZERO).is_equal_approx(b.get("position", Vector2.ZERO)) \
		and is_equal_approx(a.get("rotation", 0.0), b.get("rotation", 0.0)) \
		and a.get("scale", Vector2.ONE).is_equal_approx(b.get("scale", Vector2.ONE))


func _apply_transform_state(n: Node2D, state: Dictionary) -> void:
	if "position" in state:
		n.position = state["position"]
	if "rotation" in state:
		n.rotation = state["rotation"]
	if "scale" in state:
		n.scale = state["scale"]
	if n.has_method("reset_base_position"):
		n.reset_base_position()
	_update_highlight()
	if _overlay and _overlay.has_method("populate_inspector"):
		_overlay.populate_inspector(_selected)
	_reapply_tint(n)


func _pack_node(node: Node) -> PackedScene:
	if node == null:
		return null
	var owner_backup := {}
	_set_owner_recursive(node, node, owner_backup)
	var packed := PackedScene.new()
	var result := packed.pack(node)
	_restore_owner_recursive(owner_backup)
	if result == OK:
		return packed
	return null


func _set_owner_recursive(node: Node, owner: Node, backup: Dictionary) -> void:
	backup[node] = node.owner
	node.owner = owner
	for child in node.get_children():
		if child is Node:
			_set_owner_recursive(child, owner, backup)


func _restore_owner_recursive(backup: Dictionary) -> void:
	for key in backup.keys():
		var n: Node = key
		if n:
			n.owner = backup[key]


func _assign_owner_recursive(node: Node, owner: Node) -> void:
	if node == null or owner == null:
		return
	node.owner = owner
	for child in node.get_children():
		if child is Node:
			_assign_owner_recursive(child, owner)


func _push_history_entry(entry: Dictionary) -> void:
	if entry.is_empty():
		return
	_undo_stack.append(entry)
	_redo_stack.clear()


func _make_transform_entry(node: Node2D, before: Dictionary, after: Dictionary) -> Dictionary:
	if _transform_equals(before, after):
		return {}
	var entry: Dictionary = {
		"kind": HISTORY_TRANSFORM,
		"path": node.get_path(),
		"before": before,
		"after": after,
	}
	return entry


func _make_create_entry(node: Node) -> Dictionary:
	if node == null or node.get_parent() == null:
		return {}
	var packed := _pack_node(node)
	if packed == null:
		push_warning("Could not pack node for create history: %s" % node.name)
		return {}
	var entry: Dictionary = {
		"kind": HISTORY_CREATE,
		"path": node.get_path(),
		"parent_path": node.get_parent().get_path(),
		"index": node.get_index(),
		"name": node.name,
		"packed": packed,
	}
	return entry


func _make_delete_entry(node: Node) -> Dictionary:
	if node == null or node.get_parent() == null:
		return {}
	var packed := _pack_node(node)
	if packed == null:
		push_warning("Could not pack node for delete history: %s" % node.name)
		return {}
	var entry: Dictionary = {
		"kind": HISTORY_DELETE,
		"path": node.get_path(),
		"parent_path": node.get_parent().get_path(),
		"index": node.get_index(),
		"name": node.name,
		"packed": packed,
	}
	return entry


func _unhandled_input(event: InputEvent) -> void:
	# Global early guard: never let wheel events pass when pointer is over UI
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if _mouse_over_ui():
				return
			# Consume wheel entirely to prevent zoom
			if editor_mode:
				get_viewport().set_input_as_handled()
				return
	if event.is_action_pressed(toggle_action):
		if editor_mode:
			_exit_editor_mode()
		else:
			_enter_editor_mode()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		if event.keycode == KEY_F12 or event.physical_keycode == KEY_F12:
			_toggle_editor()
			get_viewport().set_input_as_handled()
	# Mouse wheel zoom is disabled per request


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_action):
		_toggle_editor()
		print("Editor toggle via _input; editor_mode now:", editor_mode)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_polygon_mode"):
		_polygon_mode = not _polygon_mode
		if not _polygon_mode:
			_finish_polygon()
		if _overlay:
			_overlay.call_deferred("_set_active_panel", "polygon" if _polygon_mode else "")
		print("Polygon mode:", _polygon_mode)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_hitboxes"):
		show_hitboxes = not show_hitboxes
		_set_hitboxes_visible(show_hitboxes)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		if event.keycode == KEY_F12 or event.physical_keycode == KEY_F12:
			_toggle_editor()
			print("Editor toggle via KEY_F12 fallback; editor_mode now:", editor_mode)
			get_viewport().set_input_as_handled()
		# Keyboard zoom with numpad +/- when not typing
		if editor_mode and editor_camera and (event.keycode == KEY_KP_SUBTRACT or event.keycode == KEY_PLUS or event.keycode == KEY_EQUAL) and event.pressed:
			if not _ui_blocking_input() and not _mouse_over_ui():
				_apply_keyboard_zoom(-0.1)
			get_viewport().set_input_as_handled()
		if editor_mode and editor_camera and (event.keycode == KEY_KP_ADD or event.keycode == KEY_MINUS) and event.pressed:
			if not _ui_blocking_input() and not _mouse_over_ui():
				_apply_keyboard_zoom(0.1)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(select_parent_action):
		_select_parent()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.keycode == KEY_DELETE:
		var focus := get_viewport().gui_get_focus_owner()
		if _inspector_visible():
			return
		if focus == null or not (focus is LineEdit or focus is TextEdit):
			_delete_selected()
			get_viewport().set_input_as_handled()
	if not editor_mode:
		return
	# Suppress editor hotkeys/camera while typing in inspector/UI fields
	if event is InputEventKey and event.pressed:
		var focus2 := get_viewport().gui_get_focus_owner()
		if _inspector_visible() or _mouse_over_ui():
			return
		if focus2 and (focus2 is LineEdit or focus2 is TextEdit or focus2 is OptionButton or focus2 is Button):
			return
	if event is InputEventMouseButton:
		if _inspector_visible() or _mouse_over_ui():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				return
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		if _dragging and _drag_mode == "pan" and editor_camera:
			var mp := get_viewport().get_mouse_position()
			var delta_screen := mp - _drag_start_screen
			var world_delta := delta_screen * editor_camera.zoom
			editor_camera.global_position = _initial_center - world_delta
		elif _dragging:
			_drag_selection()
		else:
			_update_hover_info()
	_update_snap_from_overlay()


func _enter_editor_mode() -> void:
	if editor_mode:
		return
	editor_mode = true
	if _baseline_snapshot == null:
		_baseline_snapshot = _make_scene_snapshot()
	_primary_player = _find_primary_player()
	_game_camera = _find_current_camera()
	var start_pos := Vector2.ZERO
	if _primary_player and is_instance_valid(_primary_player):
		start_pos = _primary_player.global_position
	elif _game_camera and is_instance_valid(_game_camera):
		start_pos = _game_camera.global_position
	if editor_camera:
		editor_camera.global_position = start_pos
		editor_camera.zoom = _game_camera.zoom if _game_camera else Vector2.ONE
		editor_camera.enabled = true
		editor_camera.visible = true
		editor_camera.process_mode = Node.PROCESS_MODE_ALWAYS
		editor_camera.make_current()
	if _game_camera:
		_game_camera.enabled = false
	if _grid and _grid is Node2D:
		_grid.visible = snap_enabled and snap_size > 0.0
		if "editor_camera" in _grid:
			_grid.editor_camera = editor_camera
		if "snap_size" in _grid:
			_grid.snap_size = snap_size
		if "enabled" in _grid:
			_grid.enabled = snap_enabled
	if _overlay:
		_overlay.visible = true
		if _overlay.has_method("set_editor_mode"):
			_overlay.set_editor_mode(true)
	_set_all_actors_passive()
	_set_hitboxes_visible(show_hitboxes)
	emit_signal("editor_entered")
	_set_cursor_select()


func _exit_editor_mode() -> void:
	if not editor_mode:
		return
	editor_mode = false
	_ensure_game_camera()
	if _game_camera:
		var player := _find_primary_player()
		if player:
			_game_camera.global_position = player.global_position
			_game_camera.enabled = true
			_game_camera.make_current()
			_show_footer_message("Camera centered on player")
		else:
			_show_footer_message("You must add a player to play the level")
	if editor_camera:
		editor_camera.enabled = false
		editor_camera.visible = false
	if _grid and _grid is Node2D:
		_grid.visible = false
		if "enabled" in _grid:
			_grid.enabled = false
	if _overlay:
		_overlay.visible = false
		if _overlay.has_method("set_editor_mode"):
			_overlay.set_editor_mode(false)
	set_selection(null)
	_hovered = null
	_active_handle = -1
	_dragging = false
	_handle_positions.clear()
	_set_handles_visible(false)
	if _highlight:
		_highlight.visible = false
	_poly_drag_index = -1
	_polygon_mode = false
	_clear_passive_flag()
	emit_signal("editor_exited")
	_set_cursor_select()


func _find_current_camera() -> Camera2D:
	for cam in get_tree().get_nodes_in_group("cameras"):
		if cam is Camera2D and cam.is_current():
			return cam
	for cam in get_tree().get_nodes_in_group("Camera2D"):
		if cam is Camera2D and cam.is_current():
			return cam
	# Fallback: traverse tree for current or first camera
	var stack := [get_tree().root]
	var first_cam: Camera2D = null
	while stack.size() > 0:
		var node = stack.pop_back()
		if node is Camera2D:
			if (node as Camera2D).is_current():
				return node as Camera2D
			if first_cam == null:
				first_cam = node as Camera2D
		for child in node.get_children():
			stack.append(child)
	return first_cam


func _find_primary_player() -> Node2D:
	if get_tree().current_scene == null:
		return null
	var stack: Array = [get_tree().current_scene]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		if n is Node2D:
			var nd := n as Node2D
			var meta_id := ""
			if nd.has_meta("data_id"):
				var mv = nd.get_meta("data_id")
				if mv is String:
					meta_id = mv
			if "data_id" in nd:
				var dv = nd.get("data_id")
				if dv is String:
					meta_id = dv
			if _is_player_node(nd):
				return nd
		for child in n.get_children():
			if child is Node:
				stack.append(child)
	return null


func _on_tree_node_added(n: Node) -> void:
	if _primary_player == null and _is_player_node(n):
		_primary_player = n as Node2D
		_center_game_camera(true)


func _on_tree_node_removed(n: Node) -> void:
	if n == _primary_player:
		_primary_player = _find_primary_player()
		_center_game_camera(true)


func _ensure_game_camera() -> void:
	if get_tree().current_scene == null:
		return
	if _game_camera and is_instance_valid(_game_camera):
		if not _game_camera.is_current():
			_game_camera.make_current()
		_game_camera.enabled = true
		return
	_game_camera = _find_current_camera()
	if _game_camera:
		_game_camera.enabled = true
		_game_camera.make_current()
		return
	# Create a simple camera if none exists
	var player := _find_primary_player()
	_game_camera = Camera2D.new()
	_game_camera.name = "GameCamera"
	_game_camera.position = player.global_position if player else Vector2.ZERO
	get_tree().current_scene.add_child(_game_camera)
	_game_camera.make_current()
	_show_footer_message("Created fallback game camera")


func _center_game_camera(show_msg: bool = false) -> void:
	_ensure_game_camera()
	if _game_camera == null:
		return
	if _primary_player == null:
		_primary_player = _find_primary_player()
	if _primary_player:
		_game_camera.global_position = _primary_player.global_position
		_game_camera.make_current()
		if show_msg:
			_show_footer_message("Camera centered on player")
	else:
		_game_camera.global_position = Vector2.ZERO
		_game_camera.make_current()
		if show_msg:
			_show_footer_message("You must add a player to play the level")


func _reapply_all_tints() -> void:
	if get_tree().current_scene == null:
		return
	var stack: Array = [get_tree().current_scene]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		_reapply_tint(n)
		for child in n.get_children():
			if child is Node:
				stack.append(child)


func _follow_primary_player() -> void:
	if _game_camera == null:
		return
	if _primary_player == null or not is_instance_valid(_primary_player):
		_primary_player = _find_primary_player()
	if _primary_player:
		_game_camera.global_position = _primary_player.global_position


func _set_all_actors_passive() -> void:
	for actor in get_tree().get_nodes_in_group("actors"):
		if actor.has_node("ActorInterface"):
			var iface = actor.get_node("ActorInterface")
			if iface and iface.has_method("set_active_state"):
				iface.set_active_state("passive")


func _clear_passive_flag() -> void:
	for actor in get_tree().get_nodes_in_group("actors"):
		if actor.has_node("ActorInterface"):
			var iface = actor.get_node("ActorInterface")
			if iface and iface.has_method("set_active_state"):
				iface.set_active_state("active")


func set_selection(node: Node) -> void:
	if node == null:
		_selected = null
		_dragging = false
		_drag_mode = ""
		_active_handle = -1
		_handle_hover_index = -1
		_handle_positions.clear()
		_set_handles_visible(false)
		if _highlight:
			_highlight.visible = false
		if _overlay and _overlay.has_method("set_selection_name"):
			_overlay.set_selection_name("None")
		Input.set_custom_mouse_cursor(null)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		_refresh_cursor()
		_update_hover_info()
		_update_entity_popup(true)
		return
	_selected = node
	_dragging = false
	_drag_mode = ""
	_active_handle = -1
	_apply_data_to_node(_selected)
	if _overlay and _overlay.has_method("set_selection_name"):
		var name: String = node.name if node else "None"
		_overlay.set_selection_name(name)
	_update_highlight()
	selection_changed.emit(node)
	_sync_data_panel(node)
	_update_entity_popup(true)
	if not _polygon_mode and _is_polygon_node(node):
		_polygon_mode = true
		if _overlay:
			_overlay.call_deferred("_set_active_panel", "polygon")


func _show_footer_message(msg: String) -> void:
	if _overlay and _overlay.has_method("set_footer"):
		_overlay.set_footer(msg)


func _toggle_editor() -> void:
	if _toggle_lock > 0.0:
		return
	_toggle_lock = toggle_cooldown
	set_process(true)
	if editor_mode:
		_exit_editor_mode()
	else:
		_enter_editor_mode()


func _process(delta: float) -> void:
	if _toggle_lock > 0.0:
		_toggle_lock = max(_toggle_lock - delta, 0.0)
	if not editor_mode:
		_follow_primary_player()
		return
	_handle_editor_camera_move(delta)
	if _dragging and _drag_mode != "pan":
		_drag_selection()
	elif _inspector_dirty and _overlay:
		if _overlay.has_method("populate_inspector"):
			_overlay.populate_inspector(_selected)
			_inspector_dirty = false
	# Keep highlight in sync even when physics or history move things
	if _selected:
		_update_highlight()
	_update_snap_from_overlay()


func _ensure_toggle_action() -> void:
	if not InputMap.has_action(toggle_action):
		InputMap.add_action(toggle_action)
		InputMap.action_add_event(toggle_action, InputEventKey.new())
	# Add F12 if not present
	var needs_f12 := true
	for ev in InputMap.action_get_events(toggle_action):
		if ev is InputEventKey and ev.keycode == KEY_F12:
			needs_f12 = false
			break
	if needs_f12:
		var ev := InputEventKey.new()
		ev.keycode = KEY_F12
		InputMap.action_add_event(toggle_action, ev)


func _ensure_hitbox_toggle_action() -> void:
	var action := "toggle_hitboxes"
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var has_binding := false
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and ev.keycode == KEY_H:
			has_binding = true
			break
	if not has_binding:
		var ev := InputEventKey.new()
		ev.keycode = KEY_H
		InputMap.action_add_event(action, ev)


func _ensure_editor_camera_actions() -> void:
	var cam_actions := {
		"editor_cam_left": [KEY_LEFT, KEY_A],
		"editor_cam_right": [KEY_RIGHT, KEY_D],
		"editor_cam_up": [KEY_UP, KEY_W],
		"editor_cam_down": [KEY_DOWN, KEY_S],
	}
	for action in cam_actions.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var allowed: Array = cam_actions[action]
		for keycode in allowed:
			var exists := false
			for ev in InputMap.action_get_events(action):
				if ev is InputEventKey and ev.keycode == keycode:
					exists = true
					break
			if not exists:
				var ev := InputEventKey.new()
				ev.keycode = keycode
				InputMap.action_add_event(action, ev)


func _ensure_select_parent_action() -> void:
	if not InputMap.has_action(select_parent_action):
		InputMap.add_action(select_parent_action)
	var has_key := false
	for ev in InputMap.action_get_events(select_parent_action):
		if ev is InputEventKey and ev.keycode == KEY_Q:
			has_key = true
			break
	if not has_key:
		var ev := InputEventKey.new()
		ev.keycode = KEY_Q
		InputMap.action_add_event(select_parent_action, ev)


func _sanitize_input_maps() -> void:
	# Restrict player move actions to WASD + arrow keys as intended
	_restrict_action_keys("move_left", [KEY_A, KEY_LEFT])
	_restrict_action_keys("move_right", [KEY_D, KEY_RIGHT])
	_restrict_action_keys("move_up", [KEY_W, KEY_UP])
	_restrict_action_keys("move_down", [KEY_S, KEY_DOWN])
	# Ensure editor camera actions only use arrows
	_restrict_action_keys("editor_cam_left", [KEY_LEFT])
	_restrict_action_keys("editor_cam_right", [KEY_RIGHT])
	_restrict_action_keys("editor_cam_up", [KEY_UP])
	_restrict_action_keys("editor_cam_down", [KEY_DOWN])
	# Polygon toggle binding
	_ensure_polygon_action()


func _sync_data_panel(node: Node) -> void:
	if _data_editor == null:
		return
	if not _data_editor.has_method("sync_from_node"):
		return
	var category := _infer_data_category(node)
	if category == "":
		return
	var data_id := _extract_data_id(node)
	_data_editor.call("sync_from_node", category, data_id)


func _extract_data_id(node: Node) -> String:
	if node == null:
		return ""
	if node.has_meta("data_id"):
		var meta_val = node.get_meta("data_id")
		if meta_val is String:
			return meta_val
	if "data_id" in node:
		var v = node.get("data_id")
		if v is String:
			return v
	if "id" in node:
		var idv = node.get("id")
		if idv is String:
			return idv
	return node.name


func _infer_data_category(node: Node) -> String:
	if node == null:
		return ""
	if node.is_in_group("actors") or node.has_node("ActorInterface"):
		return "Actor"
	var lname := node.name.to_lower()
	if lname.find("spawner") != -1:
		return "Spawner"
	if lname.find("trap") != -1:
		return "Trap"
	if lname.find("item") != -1:
		return "Item"
	if lname.find("projectile") != -1:
		return "Projectile"
	if lname.find("platform") != -1 or lname.find("solid") != -1 or lname.find("slope") != -1 or lname.find("oneway") != -1 or lname.find("deco") != -1 or lname.find("scenery") != -1:
		return "Scenery"
	return ""


func _select_parent() -> void:
	if _selected and _selected.get_parent() and _selected.get_parent() is Node2D:
		var parent_nd: Node2D = _selected.get_parent()
		if _is_scene_root(parent_nd):
			return
		if _is_unselectable_node(parent_nd):
			return
		set_selection(parent_nd)


func _restrict_action_keys(action: String, allowed: Array) -> void:
	if not InputMap.has_action(action):
		return
	var to_remove: Array = []
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			var key: int = ev.keycode
			if not allowed.has(key):
				to_remove.append(ev)
	for ev in to_remove:
		InputMap.action_erase_event(action, ev)


func _update_snap_from_overlay() -> void:
	if _overlay and _overlay.has_method("get_snap_enabled"):
		snap_enabled = _overlay.get_snap_enabled()
	if _overlay and _overlay.has_method("get_snap_size"):
		snap_size = _overlay.get_snap_size()
	if _grid and _grid is Node2D:
		if "snap_size" in _grid:
			_grid.snap_size = snap_size
		if "enabled" in _grid:
			_grid.enabled = snap_enabled
		_grid.visible = snap_enabled and snap_size > 0.0


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if _mouse_over_ui():
		if _dragging and not event.pressed:
			_dragging = false
			_drag_mode = ""
			_drag_start_node = null
			_drag_start_state = {}
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_mode = ""
			_active_handle = -1
			var handled := _pick_handle_at_mouse()
			if handled != "":
				return
			if _polygon_mode:
				var idx := _polygon_pick_vertex(_get_mouse_world_pos())
				if idx >= 0:
					_poly_selected_index = idx
					_poly_drag_index = idx
					Input.set_default_cursor_shape(Input.CURSOR_DRAG)
					_dragging = true
					_drag_mode = "poly_point"
				elif _polygon_add_enabled:
					_add_polygon_vertex(_get_mouse_world_pos())
				else:
					_set_cursor_select()
				return
			if _delete_mode:
				_delete_at_mouse()
				return
			if _stamp_prefab != "":
				_place_prefab_at_mouse()
			else:
				var picked := _pick_node_at_mouse()
				set_selection(picked)
				if picked:
					_dragging = true
					_drag_offset = picked.global_position - _get_mouse_world_pos()
					if picked is Node2D:
						_drag_start_node = picked
						_drag_start_state = _capture_transform(picked)
				else:
					# Clicked empty space: clear selection
					set_selection(null)
	elif event.button_index == MOUSE_BUTTON_MIDDLE and editor_camera:
		# Pan camera only; do not move selection
		if event.pressed:
			_dragging = true
			_drag_mode = "pan"
			_drag_start_screen = get_viewport().get_mouse_position()
			_initial_center = editor_camera.global_position
		else:
			if _drag_mode == "pan":
				_dragging = false
				_drag_mode = ""
	else:
		if _dragging and _drag_start_node and is_instance_valid(_drag_start_node):
			var end_state := _capture_transform(_drag_start_node)
			var entry := _make_transform_entry(_drag_start_node, _drag_start_state, end_state)
			_push_history_entry(entry)
		_dragging = false
		_drag_mode = ""
		_active_handle = -1
		_drag_start_node = null
		_drag_start_state = {}
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if _polygon_mode:
			_delete_polygon_vertex()
			return
		_stamp_prefab = ""
		_delete_mode = false
		_set_cursor_select()
	if event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
		if _polygon_mode:
			_toggle_polygon_edit_mode()
		return
	if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if _poly_drag_index != -1 and _active_polygon:
			_inspector_dirty = true
		_poly_drag_index = -1
		_drag_mode = ""
		_dragging = false
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _pick_node_at_mouse() -> Node:
	var pos := _get_mouse_world_pos()
	# Reset cycling if mouse moved significantly
	if _last_pick_hits.size() == 0 or pos.distance_to(_last_pick_pos) > 0.5:
		_last_pick_hits = _gather_pick_candidates(pos)
		_last_pick_cycle = 0
		_last_pick_pos = pos
	if _last_pick_hits.size() == 0:
		return null
	var node: Node = _last_pick_hits[_last_pick_cycle % _last_pick_hits.size()]
	_last_pick_cycle += 1
	return node


func _pick_handle_at_mouse() -> String:
	if _handle_positions.is_empty():
		return ""
	var mouse := _get_mouse_world_pos()
	for i in range(min(8, _handle_positions.size())):
		if mouse.distance_to(_handle_positions[i]) <= 8.0:
			_active_handle = i
			_drag_mode = "scale"
			if _selected and _selected is Node2D:
				_initial_transform = (_selected as Node2D).global_transform
				_initial_scale = (_selected as Node2D).global_scale
				_initial_rotation = (_selected as Node2D).global_rotation
				_initial_center = _initial_transform.get_origin()
				_initial_handle_local = _handle_positions[i]
			_start_handle_drag()
			return "scale"
	if _handle_gizmos.size() > 8:
		if mouse.distance_to(_rotation_handle_pos) <= 12.0:
			_active_handle = 8
			_drag_mode = "rotate"
			if _selected and _selected is Node2D:
				_initial_transform = (_selected as Node2D).global_transform
				_initial_scale = (_selected as Node2D).global_scale
				_initial_rotation = (_selected as Node2D).global_rotation
				_initial_center = _initial_transform.get_origin()
			_start_handle_drag()
			return "rotate"
	return ""


func _start_handle_drag() -> void:
	if _selected == null or not (_selected is Node2D):
		return
	_dragging = true
	_drag_start_node = _selected
	_drag_start_state = _capture_transform(_selected as Node2D)


func _handle_under_mouse() -> int:
	if _handle_positions.is_empty():
		return -1
	var mouse := _get_mouse_world_pos()
	for i in range(min(8, _handle_positions.size())):
		if mouse.distance_to(_handle_positions[i]) <= 8.0:
			return i
	if _handle_gizmos.size() > 8:
		if mouse.distance_to(_rotation_handle_pos) <= 12.0:
			return 8
	return -1


func _cursor_shape_for_handle(idx: int) -> int:
	match idx:
		0, 4:
			return Input.CURSOR_FDIAGSIZE
		2, 6:
			return Input.CURSOR_BDIAGSIZE
		1, 5:
			return Input.CURSOR_VSIZE
		3, 7:
			return Input.CURSOR_HSIZE
		8:
			return Input.CURSOR_DRAG
		_:
			return Input.CURSOR_ARROW


func _refresh_cursor() -> void:
	# Restore custom cursor based on current mode when not hovering a handle
	if _delete_mode:
		_set_cursor_cross()
	elif _stamp_prefab != "":
		_set_cursor_plus()
	else:
		_set_cursor_select()


func _gather_pick_candidates(world_pos: Vector2) -> Array:
	var hits: Array = []
	var stack: Array = [get_tree().current_scene]
	while stack.size() > 0:
		var node_any: Node = stack.pop_back()
		# If we hit visual/collision helpers, pick the parent Node2D instead.
		if node_any is Sprite2D or node_any is Polygon2D or node_any is CollisionShape2D:
			var parent := node_any.get_parent()
			if parent is Node2D:
				var parent_nd: Node2D = parent
				if not _is_scene_root(parent_nd) and not _is_unselectable_node(parent_nd):
					var aabb_parent := _get_node_aabb(parent_nd)
					if aabb_parent.has_point(world_pos):
						hits.append(parent_nd)
			continue
		if node_any is Node2D:
			var n2d: Node2D = node_any as Node2D
			if n2d == _overlay or n2d == _grid or n2d == _highlight:
				continue
			if _is_scene_root(n2d):
				pass
			elif _is_unselectable_node(n2d):
				continue
			else:
				var aabb := _get_node_aabb(n2d)
				if aabb.has_point(world_pos):
					hits.append(n2d)
		for child in node_any.get_children():
			var child_node: Node = child
			if child_node:
				stack.append(child_node)
	# Sort: higher z_index first, then closer to click
	hits.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		if a.z_index == b.z_index:
			return a.global_position.distance_to(world_pos) < b.global_position.distance_to(world_pos)
		return a.z_index > b.z_index)
	return hits


func _get_node_aabb(node: Node2D) -> Rect2:
	# Prefer visual bounds
	if node is Sprite2D:
		var s := node as Sprite2D
		if s.texture:
			var size := s.texture.get_size() * s.scale
			var half := size * 0.5
			var pts := [
				Vector2(-half.x, -half.y),
				Vector2(half.x, -half.y),
				Vector2(half.x, half.y),
				Vector2(-half.x, half.y),
			]
			var world_pts := pts.map(func(p): return s.global_transform * p)
			return Rect2(world_pts[0], Vector2.ZERO).expand(world_pts[1]).expand(world_pts[2]).expand(world_pts[3])
	if node is Polygon2D:
		var p := node as Polygon2D
		if p.polygon.size() > 0:
			var world_pts: Array = []
			for v in p.polygon:
				world_pts.append(p.global_transform * v)
			var rect := Rect2(world_pts[0], Vector2.ZERO)
			for i in range(1, world_pts.size()):
				rect = rect.expand(world_pts[i])
			return rect
	# Fallback to collision shape bounds
	var cs := _find_collision_shape(node)
	if cs and cs.shape:
		if cs.shape is RectangleShape2D:
			var r := cs.shape as RectangleShape2D
			var half := r.size * 0.5
			var pts := [
				Vector2(-half.x, -half.y),
				Vector2(half.x, -half.y),
				Vector2(half.x, half.y),
				Vector2(-half.x, half.y),
			]
			var world_pts := pts.map(func(p): return cs.global_transform * p)
			var rect := Rect2(world_pts[0], Vector2.ZERO)
			for i in range(1, world_pts.size()):
				rect = rect.expand(world_pts[i])
			return rect
		elif cs.shape is ConvexPolygonShape2D:
			var poly := (cs.shape as ConvexPolygonShape2D).points
			if poly.size() > 0:
				var rect := Rect2(cs.global_transform * poly[0], Vector2.ZERO)
				for i in range(1, poly.size()):
					rect = rect.expand(cs.global_transform * poly[i])
				return rect
	# Default small box
	return Rect2(node.global_position - Vector2(8, 8), Vector2(16, 16))


func _drag_selection() -> void:
	if not _selected or not (_selected is Node2D):
		return
	if _polygon_mode and _active_polygon and _poly_drag_index >= 0:
		_drag_polygon_point()
		_refresh_inspector_sidebar()
		_reapply_tint(_selected)
		return
	if _drag_mode == "scale":
		_apply_handle_scale()
		_refresh_inspector_sidebar()
		_reapply_tint(_selected)
		return
	if _drag_mode == "rotate":
		_apply_handle_rotation()
		_refresh_inspector_sidebar()
		_reapply_tint(_selected)
		return
	var target := _get_mouse_world_pos() + _drag_offset
	if snap_enabled and snap_size > 0.0:
		target.x = snapped(target.x, snap_size)
		target.y = snapped(target.y, snap_size)
	_selected.global_position = target
	if _selected and _selected.has_method("reset_base_position"):
		_selected.reset_base_position()
	_update_highlight()


func _apply_handle_scale() -> void:
	if _selected == null or not (_selected is Node2D) or _active_handle < 0:
		return
	var n := _selected as Node2D
	var center := _initial_center
	var current := _get_mouse_world_pos()
	var from_center := _initial_handle_local - center
	var current_vec := current - center
	var new_scale := _initial_scale
	# Determine which axes to affect based on handle index
	var affect_x := true
	var affect_y := true
	match _active_handle:
		1, 5:
			affect_x = false
		3, 7:
			affect_y = false
		_:
			pass
	if affect_x and abs(from_center.x) > 0.001:
		new_scale.x = _initial_scale.x * (current_vec.x / from_center.x)
	if affect_y and abs(from_center.y) > 0.001:
		new_scale.y = _initial_scale.y * (current_vec.y / from_center.y)
	if snap_enabled and snap_size > 0.0:
		new_scale.x = snapped(new_scale.x, 0.05)
		new_scale.y = snapped(new_scale.y, 0.05)
	n.global_scale = new_scale
	_update_highlight()


func _apply_handle_rotation() -> void:
	if _selected == null or not (_selected is Node2D):
		return
	var n := _selected as Node2D
	var center := _initial_center
	var ang0 := (_initial_handle_local - center).angle()
	var ang1 := (_get_mouse_world_pos() - center).angle()
	var delta := ang1 - ang0
	n.global_rotation = _initial_rotation + delta
	if snap_enabled and snap_size > 0.0:
		var step := deg_to_rad(15.0)
		n.global_rotation = snapped(n.global_rotation, step)
	_update_highlight()
	_inspector_dirty = true


func _delete_at_mouse() -> void:
	var node := _pick_node_at_mouse()
	if node and node.get_parent():
		var entry := _make_delete_entry(node)
		if node == _selected:
			_selected = null
			_highlight.visible = false
		_push_history_entry(entry)
		node.queue_free()


func _delete_selected() -> void:
	if _selected == null or _selected.get_parent() == null:
		return
	var entry := _make_delete_entry(_selected)
	var to_free := _selected
	set_selection(null)
	_push_history_entry(entry)
	to_free.queue_free()


func _get_mouse_world_pos() -> Vector2:
	if editor_camera:
		return editor_camera.get_global_mouse_position()
	return get_viewport().get_mouse_position()


func _find_collision_shape(node: Node) -> CollisionShape2D:
	if node is CollisionShape2D:
		if node.name.begins_with("Editor") or node.is_in_group("editor_only") or node.is_in_group("editor_selector"):
			return null
		return node
	for child in node.get_children():
		var found := _find_collision_shape(child)
		if found:
			return found
	return null


func _is_unselectable_node(n: Node2D) -> bool:
	if n == _overlay or n == _grid or n == _highlight:
		return true
	if n.name == "DebugOverlay":
		return true
	if n.name.begins_with("Editor"):
		return true
	if n is Camera2D:
		return true
	if n.name == "SpriteRoot":
		return true
	if n.is_in_group("editor_only") or n.is_in_group("editor_selector"):
		return true
	var lname := n.name.to_lower()
	if lname == "damagearea":
		return true
	if lname.find("hitbox") != -1 or lname.find("hurtbox") != -1:
		return true
	if lname == "hitboxes":
		return true
	return false


func _is_player_node(n: Node) -> bool:
	if n == null or not (n is Node2D):
		return false
	var meta_id := ""
	if n.has_meta("data_id"):
		var mv = n.get_meta("data_id")
		if mv is String:
			meta_id = mv
	if "data_id" in n:
		var dv = n.get("data_id")
		if dv is String:
			meta_id = dv
	if meta_id.to_upper() == "ACTOR_PLAYER":
		return true
	return n.name.to_lower() == "player"


func _is_teleporter_node(n: Node) -> bool:
	if n == null:
		return false
	if n.get_class() == "Teleporter2D":
		return true
	return n.is_in_group("teleporters")


func _teleporter_needs_partner(n: Node2D) -> bool:
	if not _is_teleporter_node(n):
		return false
	if not ("dropoff_mode" in n):
		return false
	if n.dropoff_mode != "teleporter":
		return false
	var others: Array = []
	if get_tree() and get_tree().current_scene:
		others = get_tree().get_nodes_in_group("teleporters")
	return others.size() <= 1


func _is_scene_root(n: Node2D) -> bool:
	return get_tree().current_scene != null and n == get_tree().current_scene


func _set_hitboxes_visible(flag: bool) -> void:
	for node_any in get_tree().get_nodes_in_group("hitboxes"):
		if node_any is Node2D:
			node_any.visible = flag
	# Fallback: toggle by name
	var stack: Array = [get_tree().current_scene]
	while stack.size() > 0:
		var n: Node = stack.pop_back()
		if n is Node2D:
			var nd: Node2D = n
			var lname := nd.name.to_lower()
			if lname.find("hitbox") != -1 or lname == "hitboxes":
				nd.visible = flag
		for child in n.get_children():
			if child is Node:
				stack.append(child)


func _on_prefab_selected(kind: String, data: Variant = null) -> void:
	if kind == "undo":
		_undo()
		return
	if kind == "redo":
		_redo()
		return
	if kind == "save":
		_save_scene()
		return
	if kind == "save_path":
		_save_scene(String(data))
		return
	if kind == "load":
		_load_scene()
		return
	if kind == "load_path":
		_load_scene(String(data))
		return
	if kind == "reload":
		_reload_scene()
		return
	if kind == "data":
		_toggle_data_editor()
		return
	if kind == "polygon":
		_start_new_polygon()
		return
	if kind == "toggle_polygon":
		_polygon_mode = not _polygon_mode
		if not _polygon_mode:
			_finish_polygon()
		if _overlay:
			_overlay.call_deferred("_set_active_panel", "polygon" if _polygon_mode else "")
		return
	if kind == "edit_polygon":
		_edit_existing_polygon()
		return
	if kind == "use_polygon":
		_finish_polygon()
		_polygon_mode = false
		if _overlay:
			_overlay.call_deferred("_set_active_panel", "")
		return
	if kind == "cancel_polygon":
		if _active_polygon and _selected == _active_polygon:
			set_selection(null)
		if _active_polygon:
			if is_instance_valid(_active_polygon):
				_active_polygon.queue_free()
			_active_polygon = null
		_polygon_vertices.clear()
		_poly_drag_index = -1
		_poly_selected_index = -1
		_polygon_add_enabled = true
		_set_handles_visible(false)
		_update_polygon_visual_state()
		_polygon_mode = false
		if _overlay:
			_overlay.call_deferred("_set_active_panel", "")
		return
	if kind == "close_panels":
		if _overlay:
			_overlay.call_deferred("_set_active_panel", "")
		return
	if kind == "main_menu":
		_exit_editor_mode()
		var err := get_tree().change_scene_to_file("res://game/MainMenu.tscn")
		if err != OK:
			push_error("Failed to load main menu, err %d" % err)
		return
	if kind == "delete":
		_delete_mode = true
		_stamp_prefab = ""
		_set_cursor_cross()
		return
	_delete_mode = false
	_stamp_prefab = kind
	_set_cursor_plus()


func _place_prefab_at_mouse() -> void:
	var pos := _get_mouse_world_pos()
	var packed: PackedScene = _get_prefab_scene(_stamp_prefab)
	if packed == null:
		return
	var scene := packed.instantiate()
	if scene is Node2D:
		scene.global_position = pos
	if scene:
		var base := packed.resource_path.get_file().get_basename()
		var desired_name := base
		if PREFAB_NAMES.has(_stamp_prefab):
			desired_name = PREFAB_NAMES[_stamp_prefab]
		elif base != "":
			desired_name = base
		else:
			desired_name = _stamp_prefab.capitalize()
		if desired_name.begins_with("@") and scene.get_class() == "StaticBody2D" and _stamp_prefab == "solid":
			desired_name = "Solid"
		scene.name = desired_name
		print("Placed prefab:", _stamp_prefab, "assigned name:", scene.name)
		get_tree().current_scene.add_child(scene)
		if scene and PREFAB_DEFAULT_DATA.has(_stamp_prefab):
			var data_id: String = PREFAB_DEFAULT_DATA[_stamp_prefab]
			if "data_id" in scene:
				scene.set("data_id", data_id)
			elif "id" in scene:
				scene.set("id", data_id)
			else:
				scene.set_meta("data_id", data_id)
			_apply_data_to_node(scene)
			_apply_visual_for_prefab(scene, _stamp_prefab)
	if scene:
		# Reassert the desired name after parenting in case Godot altered it
		if PREFAB_NAMES.has(_stamp_prefab):
			scene.name = PREFAB_NAMES[_stamp_prefab]
		elif packed.resource_path.get_file().get_basename() != "":
			scene.name = packed.resource_path.get_file().get_basename()
	if scene:
		_assign_owner_recursive(scene, get_tree().current_scene)
	if scene and scene.has_method("reset_base_position"):
		scene.reset_base_position()
	var entry := _make_create_entry(scene)
	_push_history_entry(entry)
	set_selection(scene)
	_set_cursor_plus()


func _attach_actor_spawner(actor: Node) -> void:
	if actor == null or not (actor is Node):
		return
	var spawner := preload("res://engine/spawners/EnemySpawner.tscn").instantiate()
	spawner.owner_path = NodePath("..")
	spawner.projectile_scene = preload("res://engine/projectiles/EnemyProjectile2D.tscn")
	spawner.speed = 250.0
	spawner.direction = -1.0
	spawner.fire_interval = 2.0
	actor.add_child(spawner)


func _get_prefab_scene(kind: String) -> PackedScene:
	match kind:
		"player":
			return preload("res://engine/actors/ActorCharacter2D.tscn")
		"enemy":
			return preload("res://engine/actors/EnemyDummy.tscn")
		"npc":
			return preload("res://engine/actors/ActorCharacter2D.tscn")
		"deco":
			return preload("res://engine/decoration/ActorDeco2D.tscn")
		"deco_solid":
			return preload("res://engine/decoration/ActorDeco2D_Static.tscn")
		"trap":
			return preload("res://engine/traps/ActorTrap2D.tscn")
		"spawner":
			return preload("res://engine/spawners/EnemySpawner.tscn")
		"item":
			return preload("res://engine/items/ActorItem2D.tscn")
		"solid", "ground", "wall", "ceiling":
			return preload("res://engine/platforms/PlatformSolid.tscn")
		"one_way":
			return preload("res://engine/platforms/PlatformOneWay.tscn")
		"water":
			return preload("res://engine/platforms/WaterVolume.tscn")
		"teleporter":
			return preload("res://engine/teleport/Teleporter2D.tscn")
		_:
			return null


func _apply_visual_for_prefab(scene: Node, kind: String) -> void:
	if scene == null:
		return
	# If a data_id is present, try to pull a sprite override from the data resource
	var data_id := ""
	if "data_id" in scene:
		var v = scene.get("data_id")
		if v is String:
			data_id = v
	if data_id == "" and scene.has_meta("data_id"):
		var mv = scene.get_meta("data_id")
		if mv is String:
			data_id = mv
	if data_id != "" and Engine.has_singleton("DataRegistry"):
		var reg = Engine.get_singleton("DataRegistry")
		if reg and reg.has_method("get_resource_for_category"):
			var res = reg.get_resource_for_category("Actor", data_id)
			if res and "sprite" in res and res.sprite:
				var spr := scene.get_node_or_null("SpriteRoot/Sprite2D")
				if spr and spr is Sprite2D:
					spr.texture = res.sprite
					return
	if kind == "npc":
		var sprite := scene.get_node_or_null("SpriteRoot/Sprite2D")
		if sprite and sprite is Sprite2D:
			(sprite as Sprite2D).modulate = Color(0, 1, 0)
	if kind == "enemy":
		var sprite := scene.get_node_or_null("SpriteRoot/Sprite2D")
		if sprite and sprite is Sprite2D:
			(sprite as Sprite2D).modulate = Color(1, 0, 0)
	if kind == "player":
		var sprite := scene.get_node_or_null("SpriteRoot/Sprite2D")
		if sprite and sprite is Sprite2D:
			(sprite as Sprite2D).modulate = Color(0.2, 0.6, 1.0)


func _apply_actor_data_to_node(node: Node) -> void:
	var sm: Node = _get_scene_manager()
	if sm and sm.has_method("apply_actor_data"):
		sm.apply_actor_data(node)
		_apply_instance_overrides(node)
		if node == _selected:
			_update_highlight()
		return
	if node == null:
		print("[Editor] apply actor data skipped: node null")
		return
	var data_id := ""
	if "data_id" in node:
		var v = node.get("data_id")
		if v is String:
			data_id = v
	if data_id == "" and node.has_meta("data_id"):
		var mv = node.get_meta("data_id")
		if mv is String:
			data_id = mv
	if data_id == "":
		print("[Editor] apply actor data skipped: no data_id on", node.name)
		return
	if not Engine.has_singleton("DataRegistry"):
		print("[Editor] apply actor data skipped: no DataRegistry")
		return
	var reg = Engine.get_singleton("DataRegistry")
	if reg == null or not reg.has_method("get_resource_for_category"):
		print("[Editor] apply actor data skipped: registry missing get_resource_for_category")
		return
	var res = reg.get_resource_for_category("Actor", data_id)
	if res == null:
		print("[Editor] actor data missing for", data_id)
		return
	print("[Editor] apply actor data", data_id, "to", node.name)
	# Input source hint
	if "use_player_input" in node:
		var wants_player: bool = data_id == "ACTOR_Player"
		if "input_source" in res:
			wants_player = res.input_source == "Player"
		node.set("use_player_input", wants_player)
	if "player_number" in node and "player_number" in res:
		node.set("player_number", res.player_number)
	# Collision properties
	if "collision_layers" in res and "collision_layer" in node:
		node.set("collision_layer", res.collision_layers)
	if "collision_mask" in res and "collision_mask" in node:
		node.set("collision_mask", res.collision_mask)
	# Apply sprite override
	if "sprite" in res and res.sprite:
		var spr := node.get_node_or_null("SpriteRoot/Sprite2D")
		if spr and spr is Sprite2D:
			(spr as Sprite2D).texture = res.sprite
			if data_id == "ACTOR_NPC":
				(spr as Sprite2D).modulate = Color(0, 1, 0)
			elif data_id == "ACTOR_Enemy":
				(spr as Sprite2D).modulate = Color(1, 0, 0)
			elif data_id == "ACTOR_Player":
				(spr as Sprite2D).modulate = Color(0.2, 0.6, 1.0)
	# Apply collider shape override if provided
	if "collider_shape" in res and res.collider_shape:
		var cs := _find_collision_shape(node)
		if cs:
			cs.shape = res.collider_shape
	# Sync from scene template if provided (sprite/collider/poly)
	if "scene" in res and res.scene:
		_apply_scene_overrides(node, res.scene)
	# Persist id/meta so UI and saves stay in sync
	if "data_id" in node:
		node.set("data_id", data_id)
	else:
		node.set_meta("data_id", data_id)
	if node is Node2D and node.has_method("reset_base_position"):
		node.call("reset_base_position")


func _infer_category_from_id(data_id: String) -> String:
	var upper := data_id.to_upper()
	if upper.begins_with("ACTOR_"):
		return "Actor"
	if upper.begins_with("MOVEMENT_"):
		return "Movement"
	if upper.begins_with("SPAWNER_"):
		return "Spawner"
	if upper.begins_with("ITEM_"):
		return "Item"
	if upper.begins_with("PROJECTILE_"):
		return "Projectile"
	if upper.begins_with("TRAP_"):
		return "Trap"
	if upper.begins_with("SCENERY_"):
		return "Scenery"
	if upper.begins_with("PLATFORM_") or upper.begins_with("ACTOR_DECO"):
		return "Scenery"
	if upper.begins_with("TELEPORTER_"):
		return "Teleporter"
	if upper.begins_with("AIPROFILE_"):
		return "AIProfile"
	if upper.begins_with("FACTION_"):
		return "Faction"
	if upper.begins_with("LOOTTABLE_"):
		return "LootTable"
	if upper.begins_with("STATS_"):
		return "Stats"
	return ""


func _apply_scene_overrides(node: Node, scene: PackedScene) -> void:
	if node == null or scene == null:
		return
	var inst := scene.instantiate()
	if inst == null:
		return
	var tex: Texture2D = null
	var mod := Color(1, 1, 1, 1)
	var spr_inst: Sprite2D = inst.get_node_or_null("SpriteRoot/Sprite2D") as Sprite2D
	if spr_inst and spr_inst.texture:
		tex = spr_inst.texture
		mod = spr_inst.modulate
	var cs_inst := _find_collision_shape(inst)
	var shape: Shape2D = null
	if cs_inst and cs_inst.shape:
		shape = cs_inst.shape.duplicate()
	var poly: PackedVector2Array = PackedVector2Array()
	var poly_color := Color(1, 1, 1, 1)
	var poly_inst: Polygon2D = inst.get_node_or_null("Visual") as Polygon2D
	if poly_inst and poly_inst.polygon.size() > 0:
		poly = poly_inst.polygon.duplicate()
		poly_color = poly_inst.color
	inst.queue_free()
	if tex:
		var target_spr: Sprite2D = node.get_node_or_null("SpriteRoot/Sprite2D") as Sprite2D
		if target_spr:
			target_spr.texture = tex
			target_spr.modulate = mod
			target_spr.set_meta("editor_tint", mod)
		elif node is Sprite2D:
			(node as Sprite2D).texture = tex
			(node as Sprite2D).set_meta("editor_tint", mod)
	if shape:
		var target_cs := _find_collision_shape(node)
		if target_cs:
			target_cs.shape = shape
	if poly.size() > 0:
		var target_poly: Polygon2D = node.get_node_or_null("Visual") as Polygon2D
		if target_poly:
			target_poly.polygon = poly
			target_poly.color = poly_color
			target_poly.set_meta("editor_tint", poly_color)


# Generic apply for non-actor categories; best-effort visuals and collisions
func _apply_data_to_node(node: Node) -> void:
	var sm: Node = _get_scene_manager()
	if sm and sm.has_method("apply_data"):
		sm.apply_data(node)
		_apply_instance_overrides(node)
		_reapply_tint(node)
		if node == _selected:
			_update_highlight()
		return
	if node == null:
		print("[Editor] apply data skipped: node null")
		return
	var data_id := ""
	if "data_id" in node:
		var v = node.get("data_id")
		if v is String:
			data_id = v
	if data_id == "" and node.has_meta("data_id"):
		var mv = node.get_meta("data_id")
		if mv is String:
			data_id = mv
	if data_id == "":
		print("[Editor] apply data skipped: no data_id on", node.name)
		return
	if not Engine.has_singleton("DataRegistry"):
		print("[Editor] apply data skipped: no DataRegistry")
		return
	var reg = Engine.get_singleton("DataRegistry")
	if reg == null or not reg.has_method("get_resource_for_category"):
		print("[Editor] apply data skipped: registry missing get_resource_for_category")
		return
	var cat := _infer_category_from_id(data_id)
	if cat == "Actor":
		_apply_actor_data_to_node(node)
		return
	var res = reg.get_resource_for_category(cat, data_id)
	if res == null:
		print("[Editor] data missing for", data_id, "cat", cat)
		return
	print("[Editor] apply data", data_id, "cat", cat, "node", node.name)
	# platform visuals
	if "scene" in res and res.scene:
		_apply_scene_overrides(node, res.scene)
	# item visuals
	if cat == "Item":
		if "sprite" in res and res.sprite:
			var spr2 := node.get_node_or_null("SpriteRoot/Sprite2D") as Sprite2D
			if spr2:
				spr2.texture = res.sprite
			elif node is Sprite2D:
				(node as Sprite2D).texture = res.sprite
	# trap/projectile collision/spawner
	if cat in ["Trap", "Projectile", "Spawner"]:
		if "collision_layer" in res and "collision_layer" in node:
			node.set("collision_layer", res.collision_layer)
		if "collision_mask" in res and "collision_mask" in node:
			node.set("collision_mask", res.collision_mask)
	# teleporter props
	if cat == "Teleporter":
		if "exit_only" in res and "exit_only" in node:
			node.exit_only = res.exit_only
		if "activation_mode" in res and "activation_mode" in node:
			node.activation_mode = res.activation_mode
		if "activation_action" in res and "activation_action" in node:
			node.activation_action = res.activation_action
		if "destination_scene" in res and "destination_scene" in node:
			node.destination_scene = res.destination_scene
		if "dropoff_mode" in res and "dropoff_mode" in node:
			node.dropoff_mode = res.dropoff_mode
		if "dropoff_target" in res and "dropoff_target" in node:
			node.dropoff_target = res.dropoff_target
		if "dropoff_margin" in res and "dropoff_margin" in node:
			node.dropoff_margin = res.dropoff_margin
	# apply collision if present
	if "collision_layer" in res and "collision_layer" in node:
		node.set("collision_layer", res.collision_layer)
	if "collision_layers" in res and "collision_layer" in node:
		node.set("collision_layer", res.collision_layers)
	if "collision_mask" in res and "collision_mask" in node:
		node.set("collision_mask", res.collision_mask)
	# Apply tint override even if no explicit sprite assignment
	if "tint" in res and res.tint is Color:
		var col: Color = res.tint
		var spr_t := node.get_node_or_null("SpriteRoot/Sprite2D") as Sprite2D
		if spr_t:
			spr_t.modulate = col
			spr_t.set_meta("editor_tint", col)
		elif node is Sprite2D:
			(node as Sprite2D).modulate = col
			(node as Sprite2D).set_meta("editor_tint", col)
		var poly_t := node.get_node_or_null("Visual") as Polygon2D
		if poly_t:
			poly_t.color = col
			poly_t.set_meta("editor_tint", col)
		# if no direct visual, remember tint on the node for later restore
		if not spr_t and not (node is Sprite2D) and not poly_t:
			node.set_meta("editor_tint", col)
	# sprite/texture best-effort
	if "sprite" in res and res.sprite:
		var spr := node.get_node_or_null("SpriteRoot/Sprite2D")
		if spr and spr is Sprite2D:
			(spr as Sprite2D).texture = res.sprite
			if "tint" in res and res.tint is Color:
				(spr as Sprite2D).modulate = res.tint
				(spr as Sprite2D).set_meta("editor_tint", res.tint)
		elif node is Sprite2D:
			(node as Sprite2D).texture = res.sprite
			if "tint" in res and res.tint is Color:
				(node as Sprite2D).modulate = res.tint
				(node as Sprite2D).set_meta("editor_tint", res.tint)
	# persist data id
	if "data_id" in node:
		node.set("data_id", data_id)
	else:
		node.set_meta("data_id", data_id)
	if node is Node2D and node.has_method("reset_base_position"):
		node.call("reset_base_position")
	_apply_instance_overrides(node)
	if node == _selected:
		_update_highlight()


# Apply per-instance overrides stored on the node (meta or dictionary)
func _apply_instance_overrides(node: Node) -> void:
	if node == null:
		return
	var overrides: Dictionary = {}
	if node.has_meta("instance_overrides"):
		var ov = node.get_meta("instance_overrides")
		if ov is Dictionary:
			overrides = ov
	# legacy support
	if node.has_meta("instance_tags") and not overrides.has("tags"):
		overrides["tags"] = node.get_meta("instance_tags")
	if node.has_meta("instance_sprite_override") and not overrides.has("sprite"):
		overrides["sprite"] = node.get_meta("instance_sprite_override")
	if node.has_meta("instance_collision_mask") and not overrides.has("collision_mask"):
		overrides["collision_mask"] = node.get_meta("instance_collision_mask")
	if node.has_meta("instance_no_projectile") and not overrides.has("no_projectile"):
		overrides["no_projectile"] = node.get_meta("instance_no_projectile")

	# tags
	if overrides.has("tags"):
		var tags_val = overrides["tags"]
		node.set_meta("instance_tags", tags_val)
		if "tags" in node and tags_val is String:
			node.set("tags", tags_val)
	# sprite override
	if overrides.has("sprite"):
		var sp := str(overrides["sprite"])
		node.set_meta("instance_sprite_override", sp)
		_set_sprite_from_path(node, sp)
	# collision mask
	if overrides.has("collision_mask") and "collision_mask" in node:
		var cm_val = overrides["collision_mask"]
		if cm_val is int:
			node.set("collision_mask", cm_val)
			node.set_meta("instance_collision_mask", cm_val)
	# no projectile
	if overrides.has("no_projectile"):
		node.set_meta("instance_no_projectile", overrides["no_projectile"])
	# tint
	if overrides.has("tint"):
		var tint_col = overrides["tint"]
		if tint_col is Color:
			_apply_tint_value(node, tint_col)
	# resource overrides for teleporters etc.
	if overrides.has("destination_scene") and "destination_scene" in node:
		var pth := str(overrides["destination_scene"])
		if pth != "" and ResourceLoader.exists(pth):
			var ps := ResourceLoader.load(pth) as PackedScene
			node.destination_scene = ps
	# transform overrides
	if overrides.has("pos") and node is Node2D:
		var p = overrides["pos"]
		if p is Vector2:
			(node as Node2D).global_position = p
	if overrides.has("rot") and node is Node2D:
		var r = overrides["rot"]
		if r is float or r is int:
			(node as Node2D).global_rotation = float(r)
	if overrides.has("scale") and node is Node2D:
		var s = overrides["scale"]
		if s is Vector2:
			(node as Node2D).global_scale = s
	# teleporter-specific
	if overrides.has("exit_only") and "exit_only" in node:
		node.exit_only = bool(overrides["exit_only"])
	if overrides.has("activation_mode") and "activation_mode" in node:
		node.activation_mode = str(overrides["activation_mode"])
	if overrides.has("activation_action") and "activation_action" in node:
		node.activation_action = str(overrides["activation_action"])
	if overrides.has("destination_scene") and "destination_scene" in node:
		var pth := str(overrides["destination_scene"])
		if pth != "" and ResourceLoader.exists(pth):
			var ps2 := ResourceLoader.load(pth) as PackedScene
			node.destination_scene = ps2
	if overrides.has("dropoff_mode") and "dropoff_mode" in node:
		node.dropoff_mode = str(overrides["dropoff_mode"])
	if overrides.has("dropoff_target") and "dropoff_target" in node:
		node.dropoff_target = str(overrides["dropoff_target"])
	if overrides.has("dropoff_margin") and "dropoff_margin" in node:
		var dm = overrides["dropoff_margin"]
		if dm is float or dm is int:
			node.dropoff_margin = float(dm)
	# movement template override
	if overrides.has("movement_id") and "movement_id" in node:
		var mid := str(overrides["movement_id"])
		node.set("movement_id", mid)
		var sm: Node = _get_scene_manager()
		if sm and sm.has_method("_registry") and sm.has_method("_apply_movement"):
			var reg = sm._registry()
			if reg and reg.has_method("get_resource_for_category"):
				var mres = reg.get_resource_for_category("Movement", mid)
				if mres:
					sm._apply_movement(node, mres)
	# movement property overrides (per-field)
	var movement_keys := [
		"move_speed", "acceleration", "friction_ground", "friction_air", "max_fall_speed", "slope_penalty",
		"jump_speed", "air_jump_speed", "max_jumps", "coyote_time", "jump_buffer_time", "min_jump_height",
		"jump_release_gravity_scale", "jump_release_cut", "drop_through_time",
		"wall_slide_gravity_scale", "wall_jump_speed_x", "wall_jump_speed_y",
		"enable_glide", "glide_gravity_scale", "glide_max_fall_speed",
		"enable_flight", "flight_acceleration", "flight_max_speed", "flight_drag",
		"enable_swim", "swim_speed", "swim_drag", "swim_gravity_scale", "swim_jump_speed",
		"enable_flap", "max_flaps", "flap_impulse"
	]
	for mk in movement_keys:
		if overrides.has(mk) and mk in node:
			node.set(mk, overrides[mk])


func _set_sprite_from_path(node: Node, path: String) -> void:
	if path == "":
		return
	var tex := load(path)
	if tex == null:
		return
	if node is Sprite2D:
		(node as Sprite2D).texture = tex
		return
	var spr := node.get_node_or_null("SpriteRoot/Sprite2D")
	if spr and spr is Sprite2D:
		(spr as Sprite2D).texture = tex
		return
	for child in node.get_children():
		if child is Sprite2D:
			(child as Sprite2D).texture = tex
			return


func _apply_tint_value(node: Node, col: Color) -> void:
	var spr := node.get_node_or_null("SpriteRoot/Sprite2D") as Sprite2D
	if spr:
		spr.modulate = col
		spr.set_meta("editor_tint", col)
	elif node is Sprite2D:
		(node as Sprite2D).modulate = col
		(node as Sprite2D).set_meta("editor_tint", col)
	var poly := node.get_node_or_null("Visual") as Polygon2D
	if poly:
		poly.color = col
		poly.set_meta("editor_tint", col)
	if not spr and not (node is Sprite2D) and not poly:
		node.set_meta("editor_tint", col)


func _update_hover_info() -> void:
	if not editor_mode:
		return
	var txt := ""
	var click_hint := ""
	var mouse_pos := get_viewport().get_mouse_position()
	# If pointer is over UI, suppress scene hover info
	if _mouse_over_ui():
		if _overlay and _overlay.has_method("set_hover_info"):
			_overlay.call("set_hover_info", "", Vector2.ZERO)
		return
	var editor_rect := _editor_area_rect()
	if not editor_rect.has_point(mouse_pos):
		if _overlay and _overlay.has_method("set_hover_info"):
			_overlay.call("set_hover_info", "", Vector2.ZERO)
		return
	var node := _pick_node_at_mouse_top()
	_hovered = node
	_handle_hover_index = _handle_under_mouse()
	if _polygon_mode and _active_polygon:
		var idx := _polygon_pick_vertex(_get_mouse_world_pos())
		if idx >= 0:
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
		elif _poly_drag_index != -1:
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
		else:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		click_hint = "Click/drag vertices; Right-click delete; MMB toggles add/edit"
	elif _handle_hover_index >= 0:
		Input.set_custom_mouse_cursor(null)
		Input.set_default_cursor_shape(_cursor_shape_for_handle(_handle_hover_index))
		click_hint = "Drag handle to scale/rotate; Right-click deselect"
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		_refresh_cursor()
	if node and node is Node2D:
		var n := node as Node2D
		var data_id := _extract_data_id(n)
		var cat := _infer_data_category(n)
		var pos := n.global_position
		var rot := rad_to_deg(n.global_rotation)
		var sc := n.global_scale
		txt = "Sel:%s | Type:%s(%s) | Pos:%.1f,%.1f | Rot:%.1f | Scale:%.2f,%.2f" % [
			n.name, data_id, cat, pos.x, pos.y, rot, sc.x, sc.y
		]
		if _teleporter_needs_partner(n):
			txt += " | No teleporter in scene"
			_show_footer_message("Add another teleporter or set dropoff to edge.")
		if click_hint == "":
			if _delete_mode:
				click_hint = "Click to delete"
			elif _stamp_prefab != "":
				click_hint = "Click places prefab; Right-click cancels stamp"
			else:
				click_hint = "Click to select; Drag to move; Delete removes"
	elif click_hint == "":
		txt = "Hover: None"
		click_hint = "Click to place prefab or select entities"
	if _overlay and _overlay.has_method("set_hover_info"):
		var msg := txt
		if click_hint != "":
			msg = "%s | %s" % [txt, click_hint]
		_overlay.call("set_hover_info", msg, mouse_pos)
	_update_polygon_visual_state()
	_refresh_inspector_sidebar()
	_reapply_tint(_selected)


func _drag_polygon_point() -> void:
	if _active_polygon == null or _poly_drag_index < 0 or _poly_drag_index >= _polygon_vertices.size():
		return
	var target := _get_mouse_world_pos()
	if snap_enabled and snap_size > 0.0:
		target.x = snapped(target.x, snap_size)
		target.y = snapped(target.y, snap_size)
	if _active_polygon is Node2D:
		target = (_active_polygon as Node2D).to_local(target)
	_polygon_vertices[_poly_drag_index] = target
	if _active_polygon and _active_polygon.has_method("set_vertices"):
		_active_polygon.call("set_vertices", _polygon_vertices)
	_update_polygon_visual_state()
	_poly_selected_index = _poly_drag_index
	_reapply_tint(_active_polygon)


func _reapply_tint(node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var data_id := _extract_data_id(node)
	if data_id == "":
		return
	var col: Color = Color.WHITE
	var has_tint := false
	if Engine.has_singleton("DataRegistry"):
		var reg = Engine.get_singleton("DataRegistry")
		if reg and reg.has_method("get_resource_for_category"):
			var cat := _infer_category_from_id(data_id)
			var res = reg.get_resource_for_category(cat, data_id)
			if res and "tint" in res and res.tint is Color:
				col = res.tint
				has_tint = true
	# Fallback to stored editor tint if resource is missing or lacks tint
	if not has_tint:
		var spr_meta := node.get_node_or_null("SpriteRoot/Sprite2D") as Sprite2D
		if spr_meta and spr_meta.has_meta("editor_tint"):
			col = spr_meta.get_meta("editor_tint") as Color
			has_tint = true
		elif node is Sprite2D and node.has_meta("editor_tint"):
			col = node.get_meta("editor_tint") as Color
			has_tint = true
		var poly_meta := node.get_node_or_null("Visual") as Polygon2D
		if not has_tint and poly_meta and poly_meta.has_meta("editor_tint"):
			col = poly_meta.get_meta("editor_tint") as Color
			has_tint = true
		if not has_tint and node.has_meta("editor_tint"):
			var ndcol = node.get_meta("editor_tint")
			if ndcol is Color:
				col = ndcol
				has_tint = true
	if not has_tint:
		return
	var spr := node.get_node_or_null("SpriteRoot/Sprite2D") as Sprite2D
	if spr:
		spr.modulate = col
	elif node is Sprite2D:
		(node as Sprite2D).modulate = col
	var poly := node.get_node_or_null("Visual") as Polygon2D
	if poly:
		poly.color = col


func _refresh_inspector_sidebar() -> void:
	if _overlay == null:
		return
	var mgr := self
	if mgr.has_method("_update_entity_popup"):
		mgr.call_deferred("_update_entity_popup", false)


func _pick_node_at_mouse_top() -> Node:
	var pos := _get_mouse_world_pos()
	var hits := _gather_pick_candidates(pos)
	if hits.size() > 0:
		return hits[0]
	return null


func _set_cursor_cross() -> void:
	if _cursor_cross:
		# Hotspot at green center dot in the provided graphic
		Input.set_custom_mouse_cursor(_cursor_cross, Input.CURSOR_ARROW, Vector2(12, 12))


func _set_cursor_select() -> void:
	if _cursor_select:
		# Hotspot at green tip in the provided graphic (top-left)
		Input.set_custom_mouse_cursor(_cursor_select, Input.CURSOR_ARROW, Vector2(2, 2))
	else:
		Input.set_custom_mouse_cursor(null)


func _set_cursor_plus() -> void:
	if _cursor_plus:
		# Hotspot at green center dot in the provided graphic
		Input.set_custom_mouse_cursor(_cursor_plus, Input.CURSOR_ARROW, Vector2(12, 12))
	else:
		Input.set_custom_mouse_cursor(null)


func _update_highlight() -> void:
	if not _highlight:
		return
	if _selected and _selected is Node2D:
		var n := _selected as Node2D
		var points := _get_highlight_points(n)
		_highlight.global_position = Vector2.ZERO
		_highlight.points = points
		_highlight.visible = true
		_update_handles()
	else:
		_highlight.visible = false
		_set_handles_visible(false)
	_update_hover_info()
	_update_polygon_visual_state()
	_reapply_tint(_selected)


func _create_handle_gizmos() -> void:
	_handle_gizmos.clear()
	for i in range(8):
		var ln := Line2D.new()
		ln.width = 2.0
		ln.default_color = Color.WHITE
		ln.points = [
			Vector2(-4, -4), Vector2(4, -4),
			Vector2(4, 4), Vector2(-4, 4),
			Vector2(-4, -4)
		]
		ln.visible = false
		_handle_gizmos.append(ln)
		_handles_layer.add_child(ln)
	var rot_ln := Line2D.new()
	rot_ln.width = 2.0
	rot_ln.default_color = Color(1, 1, 1, 0.8)
	var circle := PackedVector2Array()
	var radius := 8.0
	for a in range(0, 360, 30):
		var rad := deg_to_rad(a)
		circle.append(Vector2(cos(rad), sin(rad)) * radius)
	circle.append(circle[0])
	rot_ln.points = circle
	rot_ln.visible = false
	_handle_gizmos.append(rot_ln) # index 8
	_handles_layer.add_child(rot_ln)


func _update_handles() -> void:
	if _selected == null or not (_selected is Node2D):
		_set_handles_visible(false)
		return
	var n := _selected as Node2D
	var local_rect := _get_local_bounds(n)
	var handle_margin := 0.0
	if n is Polygon2D or n.get_node_or_null("Visual") is Polygon2D or n is PolygonTerrain2D:
		handle_margin = 16.0
	local_rect = local_rect.grow(handle_margin)
	var corners_local := [
		local_rect.position,
		local_rect.position + Vector2(local_rect.size.x, 0),
		local_rect.position + local_rect.size,
		local_rect.position + Vector2(0, local_rect.size.y),
	]
	var corners_world: Array[Vector2] = []
	for c in corners_local:
		corners_world.append(n.global_transform * c)
	var centers_world := [
		(corners_world[0] + corners_world[1]) * 0.5,
		(corners_world[1] + corners_world[2]) * 0.5,
		(corners_world[2] + corners_world[3]) * 0.5,
		(corners_world[3] + corners_world[0]) * 0.5,
	]
	_handle_positions = [
		corners_world[0], centers_world[0], corners_world[1],
		centers_world[1], corners_world[2], centers_world[2],
		corners_world[3], centers_world[3],
	]
	var center_world := n.global_transform * (local_rect.position + local_rect.size * 0.5)
	var up := n.global_transform.basis_xform(Vector2.UP).normalized()
	var radius := local_rect.size.length() * 0.6 + 32.0
	_rotation_handle_pos = center_world + up * radius
	for i in range(_handle_gizmos.size()):
		_handle_gizmos[i].visible = false
	for i in range(min(8, _handle_positions.size())):
		var ln: Line2D = _handle_gizmos[i]
		ln.global_position = _handle_positions[i]
		ln.visible = true
	if _handle_gizmos.size() > 8:
		var rot_ln: Line2D = _handle_gizmos[8]
		rot_ln.global_position = _rotation_handle_pos
		rot_ln.visible = true
	_set_handles_visible(true)


func _set_handles_visible(visible: bool) -> void:
	for giz in _handle_gizmos:
		if giz and giz is CanvasItem:
			(giz as CanvasItem).visible = visible


func _update_entity_popup(force: bool) -> void:
	if _entity_popup == null:
		return
	var panels_open := false
	if _overlay:
		for name in ["SavePanel", "LoadPanel", "DataEditor"]:
			var p := _overlay.get_node_or_null(name)
			if p and p.visible:
				panels_open = true
				break
	var key := {
		"selected": _selected,
		"panels_open": panels_open,
	}
	if not force and _entity_popup_state == key:
		return
	_entity_popup_state = key
	if panels_open or _selected == null:
		_entity_popup.hide()
		return
	var ribbon_h: float = 40.0
	if _overlay:
		var rib := _overlay.get_node_or_null("Ribbon")
		if rib and rib is Control:
			ribbon_h = (rib as Control).size.y
	var rect := get_viewport().get_visible_rect()
	if _entity_popup.has_method("show_sidebar"):
		_entity_popup.call("show_sidebar", _selected, rect, ribbon_h)


func _get_highlight_points(n: Node2D) -> PackedVector2Array:
	var pts := PackedVector2Array()
	# Use visual geometry if available
	if n is Sprite2D:
		var s := n as Sprite2D
		if s.texture:
			var size := s.texture.get_size() * s.scale
			var half := size * 0.5
			var local_points := [
				Vector2(-half.x, -half.y),
				Vector2(half.x, -half.y),
				Vector2(half.x, half.y),
				Vector2(-half.x, half.y),
				Vector2(-half.x, -half.y),
			]
			for p in local_points:
				pts.append(s.global_transform * p)
			return pts
	if n is Polygon2D:
		var p := n as Polygon2D
		if p.polygon.size() > 0:
			for v in p.polygon:
				pts.append(p.global_transform * v)
			pts.append(p.global_transform * p.polygon[0])
			return pts
	# Fallback to collision shape
	var cs := _find_collision_shape(n)
	if cs and cs.shape:
		if cs.shape is RectangleShape2D:
			var rect := cs.shape as RectangleShape2D
			var half := rect.size * 0.5
			var local_points := [
				Vector2(-half.x, -half.y),
				Vector2(half.x, -half.y),
				Vector2(half.x, half.y),
				Vector2(-half.x, half.y),
				Vector2(-half.x, -half.y),
			]
			for p in local_points:
				pts.append(cs.global_transform * p)
			return pts
		elif cs.shape is ConvexPolygonShape2D:
			var poly := (cs.shape as ConvexPolygonShape2D).points
			for p in poly:
				pts.append(cs.global_transform * p)
			if poly.size() > 0:
				pts.append(cs.global_transform * poly[0])
			return pts
	# Default tiny box
	var half := Vector2(8, 8)
	var local_points := [
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
		Vector2(-half.x, -half.y),
	]
	for p in local_points:
		pts.append(n.global_transform * p)
	return pts


func _update_polygon_visual_state() -> void:
	if _active_polygon == null or not is_instance_valid(_active_polygon):
		return
	var show_pts := _polygon_mode
	if _active_polygon.has_method("set_show_points"):
		_active_polygon.call("set_show_points", show_pts)
	if _active_polygon.has_method("set_active_vertex_index"):
		var idx := -1
		if show_pts:
			if _poly_drag_index != -1:
				idx = _poly_drag_index
			else:
				var hover_idx := _polygon_pick_vertex(_get_mouse_world_pos())
				if hover_idx != -1:
					idx = hover_idx
				elif _poly_selected_index != -1:
					idx = _poly_selected_index
		_active_polygon.call("set_active_vertex_index", idx)
	_reapply_tint(_active_polygon)


func _get_local_bounds(node: Node2D) -> Rect2:
	# Derive bounds from world AABB so child offsets are respected, then convert back to local.
	var aabb := _get_node_aabb(node)
	var corners := [
		aabb.position,
		aabb.position + Vector2(aabb.size.x, 0),
		aabb.position + aabb.size,
		aabb.position + Vector2(0, aabb.size.y),
	]
	var minv := node.to_local(corners[0])
	var maxv := minv
	for c in corners:
		var local := node.to_local(c)
		minv = minv.min(local)
		maxv = maxv.max(local)
	return Rect2(minv, maxv - minv)


# Polygon helpers
func _ensure_polygon_action() -> void:
	var action := "toggle_polygon_mode"
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if InputMap.action_get_events(action).is_empty():
		var ev := InputEventKey.new()
		ev.keycode = KEY_F10
		InputMap.action_add_event(action, ev)


func _add_polygon_vertex(pos: Vector2) -> void:
	if not _polygon_add_enabled:
		return
	if snap_enabled and snap_size > 0.0:
		pos = Vector2(snapped(pos.x, snap_size), snapped(pos.y, snap_size))
	if _active_polygon == null:
		var poly_scene := preload("res://engine/terrain/PolygonTerrain2D.tscn")
		_active_polygon = poly_scene.instantiate()
		_active_polygon.name = "PolygonTerrain"
		get_tree().current_scene.add_child(_active_polygon)
		_assign_owner_recursive(_active_polygon, get_tree().current_scene)
		if _active_polygon is Node2D:
			(_active_polygon as Node2D).global_position = pos
		_polygon_vertices = [
			Vector2(-32, 18.475),
			Vector2(32, 18.475),
			Vector2(0, -36.95),
		]
		_poly_selected_index = 0
		set_selection(_active_polygon)
		var entry := _make_create_entry(_active_polygon)
		_push_history_entry(entry)
		if _active_polygon and _active_polygon.has_method("set_vertices"):
			_active_polygon.call("set_vertices", _polygon_vertices)
		_update_polygon_visual_state()
		return
	if _active_polygon is Node2D:
		var local := (_active_polygon as Node2D).to_local(pos)
		var insert_at := _poly_selected_index
		if insert_at >= 0 and insert_at < _polygon_vertices.size():
			_polygon_vertices.insert(insert_at + 1, local)
			_poly_selected_index = insert_at + 1
		else:
			_polygon_vertices.append(local)
			_poly_selected_index = _polygon_vertices.size() - 1
	else:
		var insert_at2 := _poly_selected_index
		if insert_at2 >= 0 and insert_at2 < _polygon_vertices.size():
			_polygon_vertices.insert(insert_at2 + 1, pos)
			_poly_selected_index = insert_at2 + 1
		else:
			_polygon_vertices.append(pos)
			_poly_selected_index = _polygon_vertices.size() - 1
	if _active_polygon and _active_polygon.has_method("set_vertices"):
		_active_polygon.call("set_vertices", _polygon_vertices)
	_inspector_dirty = true
	_update_polygon_visual_state()


func _start_new_polygon() -> void:
	_finish_polygon()
	_polygon_mode = true
	if _overlay:
		_overlay.call_deferred("_set_active_panel", "polygon")
	var start_pos := editor_camera.global_position if editor_camera else _get_mouse_world_pos()
	_add_polygon_vertex(start_pos)


func _finish_polygon() -> void:
	if _active_polygon and not is_instance_valid(_active_polygon):
		_active_polygon = null
	if _active_polygon and _active_polygon.has_method("set_vertices"):
		if _polygon_vertices.size() >= 3:
			_active_polygon.call("set_vertices", _polygon_vertices)
		else:
			if _selected == _active_polygon:
				set_selection(null)
			_active_polygon.queue_free()
			_active_polygon = null
	if _active_polygon and _active_polygon.has_method("set_show_points"):
		_active_polygon.call("set_show_points", false)
	if _active_polygon:
		_assign_owner_recursive(_active_polygon, get_tree().current_scene)
	_active_polygon = null
	_polygon_vertices.clear()
	_poly_drag_index = -1
	_poly_selected_index = -1
	_polygon_add_enabled = true
	_update_highlight()
	_set_handles_visible(false)
	if _overlay:
		_overlay.call_deferred("_set_active_panel", "")


func _delete_polygon_vertex() -> void:
	if _active_polygon == null or _polygon_vertices.is_empty():
		return
	var mouse := _get_mouse_world_pos()
	var nearest := 0
	var best := 1e20
	for i in range(_polygon_vertices.size()):
		var world_pt := _polygon_vertices[i]
		if _active_polygon is Node2D:
			world_pt = (_active_polygon as Node2D).to_global(world_pt)
		var d := mouse.distance_to(world_pt)
		if d < best:
			best = d
			nearest = i
	if _polygon_vertices.size() <= 3:
		if _poly_confirm_dialog:
			_poly_confirm_dialog.dialog_text = "Polygon requires at least three points. Deleting this point will cancel polygon editing."
			_poly_confirm_dialog.ok_button_text = "Cancel and remove polygon"
			_poly_confirm_dialog.get_cancel_button().text = "Keep editing"
			if _poly_confirm_dialog.is_connected("confirmed", Callable(self, "_on_polygon_delete_confirmed")):
				_poly_confirm_dialog.confirmed.disconnect(Callable(self, "_on_polygon_delete_confirmed"))
			_poly_confirm_dialog.confirmed.connect(Callable(self, "_on_polygon_delete_confirmed"), ConnectFlags.CONNECT_ONE_SHOT)
			_poly_confirm_dialog.popup_centered()
		return
	_polygon_vertices.remove_at(nearest)
	if _poly_selected_index >= _polygon_vertices.size():
		_poly_selected_index = _polygon_vertices.size() - 1
	if _active_polygon and _active_polygon.has_method("set_vertices"):
		_active_polygon.call("set_vertices", _polygon_vertices)
	_inspector_dirty = true
	_update_polygon_visual_state()


func _polygon_pick_vertex(world_pos: Vector2) -> int:
	if _active_polygon == null:
		return -1
	var closest := -1
	var best := 1e20
	for i in range(_polygon_vertices.size()):
		var wp := _polygon_vertices[i]
		if _active_polygon is Node2D:
			wp = (_active_polygon as Node2D).to_global(wp)
		var d := world_pos.distance_to(wp)
		if d < best and d <= 10.0:
			best = d
			closest = i
	return closest


func _on_polygon_delete_confirmed() -> void:
	if _active_polygon:
		_active_polygon.queue_free()
	_finish_polygon()
	_polygon_mode = false
	_update_polygon_visual_state()
	_set_handles_visible(false)
	_highlight.visible = false


func _edit_existing_polygon() -> void:
	var target := _selected
	if target == null or not _is_polygon_node(target):
		var pick := _pick_node_at_mouse_top()
		if pick and _is_polygon_node(pick):
			target = pick
	if target == null or not _is_polygon_node(target):
		_show_footer_message("Select a polygon to edit")
		return
	_finish_polygon()
	_active_polygon = target
	_polygon_vertices.clear()
	if target is PolygonTerrain2D:
		for v in (target as PolygonTerrain2D).vertices:
			_polygon_vertices.append(v)
	elif target is Polygon2D:
		for v in (target as Polygon2D).polygon:
			_polygon_vertices.append(v)
	if _polygon_vertices.is_empty():
		_show_footer_message("Polygon has no vertices")
		return
	_polygon_mode = true
	_poly_selected_index = -1
	_poly_drag_index = -1
	set_selection(target)
	_update_polygon_visual_state()
	if _overlay:
		_overlay.call_deferred("_set_active_panel", "polygon")
	_show_footer_message("Editing polygon")


func _is_polygon_node(n: Node) -> bool:
	if n == null:
		return false
	# Only treat our dedicated polygon terrain nodes as polygon-edit targets.
	if n is PolygonTerrain2D:
		return true
	# Optional metadata escape hatch if we ever need to flag a node explicitly.
	if n.has_meta("is_polygon_entity") and n.get_meta("is_polygon_entity") == true:
		return true
	return false


func _toggle_polygon_edit_mode() -> void:
	# Middle mouse toggles between add/drag intent by flipping selection state
	if not _polygon_mode:
		_edit_existing_polygon()
		_polygon_add_enabled = true
		return
	if _active_polygon == null:
		_edit_existing_polygon()
		_polygon_add_enabled = true
	else:
		# Toggle add ability off/on while staying in polygon mode
		_polygon_add_enabled = not _polygon_add_enabled
		var msg := "Polygon edit: add %s" % ( "enabled" if _polygon_add_enabled else "disabled (selection/drag only)")
		_show_footer_message(msg)

func _on_inspector_changed(value: String) -> void:
	if _selected == null or not (_selected is Node2D):
		return
	var n := _selected as Node2D
	var before := _capture_transform(n)
	match value:
		"pos_x":
			n.position.x = float(_overlay._pos_x.text)
		"pos_y":
			n.position.y = float(_overlay._pos_y.text)
		"rot":
			var ang := deg_to_rad(float(_overlay._rot.text))
			n.rotation = ang
		"scale_x":
			n.scale.x = float(_overlay._scale_x.text)
		"scale_y":
			n.scale.y = float(_overlay._scale_y.text)
		"rot_reset":
			n.rotation = 0.0
		"scale_x_reset":
			n.scale.x = 1.0
		"scale_y_reset":
			n.scale.y = 1.0
		"proj_collide":
			if "allow_projectile_collision" in n:
				n.set("allow_projectile_collision", _overlay._proj_collide.button_pressed)
	var after := _capture_transform(n)
	var entry := _make_transform_entry(n, before, after)
	_push_history_entry(entry)
	_inspector_dirty = false
	_update_highlight()
	if _selected and _selected.has_method("reset_base_position"):
		_selected.reset_base_position()
	if _overlay and _overlay.has_method("populate_inspector"):
		_overlay.populate_inspector(_selected)
	_reapply_tint(_selected)


func _apply_history_entry(entry: Dictionary, undo: bool) -> void:
	var kind: String = entry.get("kind", "")
	if kind == HISTORY_TRANSFORM:
		var node_path: NodePath = entry.get("path", NodePath("")) as NodePath
		var node := get_tree().current_scene.get_node_or_null(node_path)
		if node and node is Node2D:
			var state: Dictionary
			if undo:
				state = entry.get("before", {}) as Dictionary
			else:
				state = entry.get("after", {}) as Dictionary
			_selected = node
			_apply_transform_state(node, state)
	elif kind == HISTORY_CREATE:
		if undo:
			var node_path: NodePath = entry.get("path", NodePath("")) as NodePath
			var node := get_tree().current_scene.get_node_or_null(node_path)
			if node:
				if node == _selected:
					set_selection(null)
				node.queue_free()
		else:
			var parent_path: NodePath = entry.get("parent_path", NodePath("")) as NodePath
			var parent := get_tree().current_scene.get_node_or_null(parent_path)
			var packed: PackedScene = entry.get("packed") as PackedScene
			if parent and packed:
				var inst := packed.instantiate()
				if inst:
					inst.name = entry.get("name", inst.name)
					parent.add_child(inst)
					var idx: int = clamp(int(entry.get("index", parent.get_child_count())), 0, parent.get_child_count() - 1)
					parent.move_child(inst, idx)
					if inst.get_owner() == null:
						inst.set_owner(parent.get_owner())
					if inst.has_method("reset_base_position"):
						inst.reset_base_position()
					set_selection(inst)
	elif kind == HISTORY_DELETE:
		if undo:
			var parent_path: NodePath = entry.get("parent_path", NodePath("")) as NodePath
			var parent := get_tree().current_scene.get_node_or_null(parent_path)
			var packed: PackedScene = entry.get("packed") as PackedScene
			if parent and packed:
				var inst := packed.instantiate()
				if inst:
					inst.name = entry.get("name", inst.name)
					parent.add_child(inst)
					var idx: int = clamp(int(entry.get("index", parent.get_child_count())), 0, parent.get_child_count() - 1)
					parent.move_child(inst, idx)
					if inst.get_owner() == null:
						inst.set_owner(parent.get_owner())
					if inst.has_method("reset_base_position"):
						inst.reset_base_position()
					set_selection(inst)
		else:
			var node_path_del: NodePath = entry.get("path", NodePath("")) as NodePath
			var to_del := get_tree().current_scene.get_node_or_null(node_path_del)
			if to_del:
				if to_del == _selected:
					set_selection(null)
				to_del.queue_free()


func _undo() -> void:
	if _undo_stack.is_empty():
		return
	var entry: Dictionary = _undo_stack.pop_back() as Dictionary
	_apply_history_entry(entry, true)
	_redo_stack.append(entry)


func _redo() -> void:
	if _redo_stack.is_empty():
		return
	var entry: Dictionary = _redo_stack.pop_back() as Dictionary
	_apply_history_entry(entry, false)
	_undo_stack.append(entry)


func _make_scene_snapshot() -> PackedScene:
	var packed := PackedScene.new()
	if get_tree().current_scene and packed.pack(get_tree().current_scene) == OK:
		return packed
	return null


func _replace_current_scene(snapshot: PackedScene) -> void:
	if snapshot == null:
		return
	var inst := snapshot.instantiate()
	if inst == null:
		return
	var tree := get_tree()
	var old_scene := tree.current_scene
	tree.root.add_child(inst)
	tree.current_scene = inst
	if old_scene:
		old_scene.queue_free()
	set_selection(null)
	_undo_stack.clear()
	_redo_stack.clear()


func _save_scene(path_override: String = "") -> void:
	var snap := _make_scene_snapshot()
	if snap == null:
		print("Save skipped: unable to snapshot scene.")
		return
	var save_path := path_override.strip_edges()
	if save_path == "":
		save_path = _save_path_primary
	if save_path.begins_with("res://editor_saves") == false:
		DirAccess.make_dir_recursive_absolute("res://editor_saves")
	var save_err := ResourceSaver.save(snap, save_path)
	if save_err != OK:
		push_warning("Failed to save to %s (err %d); trying fallback." % [save_path, save_err])
		save_err = ResourceSaver.save(snap, _save_path_fallback)
		if save_err != OK:
			push_error("Save failed to %s and fallback %s (err %d)" % [save_path, _save_path_fallback, save_err])
			return
		else:
			print("Scene saved to fallback", _save_path_fallback)
	else:
		print("Scene saved to", save_path)
	_baseline_snapshot = snap


func _load_scene(path_override: String = "") -> void:
	var packed: PackedScene = null
	var load_path := path_override.strip_edges()
	if load_path != "":
		if ResourceLoader.exists(load_path):
			packed = ResourceLoader.load(load_path)
	else:
		if ResourceLoader.exists(_save_path_primary):
			packed = ResourceLoader.load(_save_path_primary)
		elif ResourceLoader.exists(_save_path_fallback):
			packed = ResourceLoader.load(_save_path_fallback)
	if packed:
		_replace_current_scene(packed)
		_baseline_snapshot = _make_scene_snapshot()
	else:
		push_warning("No saved scene found at %s%s%s" % [_save_path_primary, " or " if _save_path_fallback != "" else "", _save_path_fallback])


func _reload_scene() -> void:
	var scene := get_tree().current_scene
	var path := ""
	if scene:
		# scene_file_path is the stable way to get the packed scene path for a running scene
		if "scene_file_path" in scene and scene.scene_file_path != "":
			path = scene.scene_file_path
	if path != "":
		var packed := ResourceLoader.load(path) as PackedScene
		if packed:
			get_tree().change_scene_to_packed(packed)
			_baseline_snapshot = _make_scene_snapshot()
			return
	# fallback to baseline snapshot if no path
	if _baseline_snapshot == null:
		_baseline_snapshot = _make_scene_snapshot()
	_replace_current_scene(_baseline_snapshot)


func _handle_zoom(event: InputEventMouseButton) -> void:
	if editor_camera == null:
		return
	# mouse wheel zoom disabled


func _toggle_data_editor() -> void:
	if _overlay and _overlay.has_method("_set_active_panel"):
		var next := "data"
		var data_panel := get_node_or_null("EditorOverlay/DataEditor")
		if data_panel and data_panel.visible:
			next = ""
		_overlay.call("_set_active_panel", next)


func _handle_editor_camera_move(delta: float) -> void:
	if editor_camera == null:
		return
	# Block camera movement when typing or UI focused
	var focus := get_viewport().gui_get_focus_owner()
	if _inspector_visible() or (focus and (focus is LineEdit or focus is TextEdit or focus is OptionButton or focus is Button)):
		return
	var dir := Vector2.ZERO
	dir.x = Input.get_action_strength("editor_cam_right") - Input.get_action_strength("editor_cam_left")
	dir.y = Input.get_action_strength("editor_cam_down") - Input.get_action_strength("editor_cam_up")
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		editor_camera.global_position += dir * camera_pan_speed * delta


func _apply_keyboard_zoom(delta_factor: float) -> void:
	if editor_camera == null:
		return
	var target := editor_camera.zoom * (1.0 + delta_factor)
	target.x = clamp(target.x, zoom_min, zoom_max)
	target.y = clamp(target.y, zoom_min, zoom_max)
	editor_camera.zoom = target
	editor_camera.queue_redraw()
	_update_snap_from_overlay()


func _ui_blocking_input() -> bool:
	if _window_controller and _window_controller.has_method("is_any_open"):
		return _window_controller.call("is_any_open")
	return false


func _ensure_window_controller() -> Node:
	var node := get_tree().root.get_node_or_null("WindowController")
	if node:
		return node
	var ctrl := preload("res://engine/editor/WindowController.gd").new()
	ctrl.name = "WindowController"
	get_tree().root.add_child(ctrl)
	return ctrl

# Called when overlay closes all panels
func _overlay_closed() -> void:
	# No open panels, exit editor mode back to play
	if editor_mode:
		_toggle_editor()


func _maximize_window(win: Node) -> void:
	if win == null or not (win is Window):
		return
	var w := win as Window
	var rect := get_viewport().get_visible_rect()
	w.size = rect.size
	w.position = rect.position


func _get_ribbon_height() -> float:
	if _overlay:
		var rib := _overlay.get_node_or_null("Ribbon")
		if rib and rib is Control:
			return (rib as Control).size.y
	return 0.0


# Scene manager helper
func _get_scene_manager():
	if Engine.has_singleton("SceneManager"):
		return Engine.get_singleton("SceneManager")
	if has_node("/root/SceneManager"):
		return get_node("/root/SceneManager")
	return null


func _inspector_visible() -> bool:
	return _entity_popup != null and _entity_popup.visible


func _mouse_over_ui() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered:
		return true
	var mp := get_viewport().get_mouse_position()
	if _entity_popup and _entity_popup.visible and _entity_popup is Control:
		if (_entity_popup as Control).get_global_rect().has_point(mp):
			return true
	if _overlay and _overlay.has_method("is_mouse_over_ui"):
		if _overlay.call("is_mouse_over_ui"):
			return true
		# Fallback: check common overlay panels' rects
		for name in ["DataEditor", "SavePanel", "LoadPanel", "MainMenu", "PolygonOverlay", "PolygonToolbar", "Footer", "Ribbon", "SidebarLeft", "Inspector", "HoverTip", "ModalBlocker"]:
			var panel := _overlay.get_node_or_null(name)
			if panel and panel is Control and panel.visible:
				if (panel as Control).get_global_rect().has_point(mp):
					return true
	return false


func _editor_area_rect() -> Rect2:
	var vr := get_viewport().get_visible_rect()
	var left := 0.0
	var right := vr.size.x
	var top := 0.0
	var bottom := vr.size.y
	if _overlay:
		var rib := _overlay.get_node_or_null("Ribbon") as Control
		if rib:
			top = max(top, rib.size.y)
		var side := _overlay.get_node_or_null("SidebarLeft") as Control
		if side:
			left = max(left, side.size.x)
		var foot := _overlay.get_node_or_null("Footer") as Control
		if foot and foot.visible:
			bottom = min(bottom, foot.global_position.y)
		var insp := _overlay.get_node_or_null("Inspector") as Control
		if insp and insp.visible:
			right = min(right, insp.global_position.x)
	return Rect2(Vector2(left, top), Vector2(max(0.0, right - left), max(0.0, bottom - top)))


# Registry helper (fallback for legacy paths)
func _get_registry():
	if Engine.has_singleton("DataRegistry"):
		return Engine.get_singleton("DataRegistry")
	if has_node("/root/DataRegistry"):
		return get_node("/root/DataRegistry")
	return null


func _connect_data_registry() -> void:
	var reg: Node = _get_registry()
	if reg == null:
		return
	if reg.has_signal("data_changed"):
		var cb := Callable(self, "_on_data_changed")
		if not reg.is_connected("data_changed", cb):
			reg.connect("data_changed", cb)


func _on_data_changed() -> void:
	# Reapply data to all nodes that carry a data_id so scene instances reflect latest changes.
	if not get_tree().current_scene:
		return
	var stack: Array = [get_tree().current_scene]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n:
			if n.has_meta("data_id") or ("data_id" in n):
				_apply_data_to_node(n)
			for child in n.get_children():
				if child is Node:
					stack.append(child)
