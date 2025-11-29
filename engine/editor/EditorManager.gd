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
var _baseline_snapshot: PackedScene
var _save_path_primary := "res://editor_saves/last_scene.tscn"
var _save_path_fallback := "user://editor_save.tscn"
var _window_controller: Node = null
var _entity_popup: Control = null
var _entity_popup_state := {}
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
	"slope_left": "Slope Left",
	"slope_right": "Slope Right",
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
}
var _data_editor: Node

func _ready() -> void:
	set_process_input(true)
	set_process_unhandled_input(true)
	set_process_unhandled_key_input(true)
	_ensure_toggle_action()
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
	_cursor_select = preload("res://engine/editor/icons/cursor_select.png")
	_cursor_plus = preload("res://engine/editor/icons/cursor_plus.png")
	_cursor_cross = preload("res://engine/editor/icons/cursor_cross.png")
	_baseline_snapshot = _make_scene_snapshot()


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
	# Handle zoom early to avoid UI consuming it
	if editor_mode and event is InputEventMouseButton and editor_camera:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var ctrl_down: bool = event.ctrl_pressed if "ctrl_pressed" in event else false
			var ctrl_key: bool = Input.is_key_pressed(KEY_CTRL)
			if not ctrl_down and not ctrl_key:
				return
			if _ui_blocking_input():
				return
			_handle_zoom(event)
			get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_action):
		_toggle_editor()
		print("Editor toggle via _input; editor_mode now:", editor_mode)
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
		elif event.is_action_pressed(select_parent_action):
			_select_parent()
			get_viewport().set_input_as_handled()
	if not editor_mode:
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		if _dragging:
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
	_game_camera = _find_current_camera()
	if editor_camera:
		editor_camera.global_position = _game_camera.global_position if _game_camera else Vector2.ZERO
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
	if _game_camera:
		_game_camera.enabled = true
		_game_camera.make_current()
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
	# Fallback: traverse tree for current camera
	var stack := [get_tree().root]
	while stack.size() > 0:
		var node = stack.pop_back()
		if node is Camera2D and node.is_current():
			return node
		for child in node.get_children():
			stack.append(child)
	return null


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
	_selected = node
	_dragging = false
	_apply_actor_data_to_node(_selected)
	if _overlay and _overlay.has_method("set_selection_name"):
		var name: String = node.name if node else "None"
		_overlay.set_selection_name(name)
	_update_highlight()
	selection_changed.emit(node)
	_sync_data_panel(node)
	_update_entity_popup(true)


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
		return
	_handle_editor_camera_move(delta)
	if _dragging:
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
		"editor_cam_left": KEY_LEFT,
		"editor_cam_right": KEY_RIGHT,
		"editor_cam_up": KEY_UP,
		"editor_cam_down": KEY_DOWN,
	}
	for action in cam_actions.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var keycode: int = cam_actions[action]
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
	if lname.find("platform") != -1 or lname.find("solid") != -1 or lname.find("slope") != -1 or lname.find("oneway") != -1:
		return "Platform"
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
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var ui_hit: Control = get_viewport().gui_get_hovered_control()
			if ui_hit != null:
				return
			if _delete_mode:
				_delete_at_mouse()
				return
			if _stamp_prefab != "":
				_place_prefab_at_mouse()
			else:
				var node := _pick_node_at_mouse()
				set_selection(node)
				if node:
					_dragging = true
					_drag_offset = node.global_position - _get_mouse_world_pos()
					if node is Node2D:
						_drag_start_node = node
						_drag_start_state = _capture_transform(node)
		else:
			if _dragging and _drag_start_node and is_instance_valid(_drag_start_node):
				var end_state := _capture_transform(_drag_start_node)
				var entry := _make_transform_entry(_drag_start_node, _drag_start_state, end_state)
				_push_history_entry(entry)
			_dragging = false
			_drag_start_node = null
			_drag_start_state = {}
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_stamp_prefab = ""
		_delete_mode = false
		_set_cursor_select()


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
	var target := _get_mouse_world_pos() + _drag_offset
	if snap_enabled and snap_size > 0.0:
		target.x = snapped(target.x, snap_size)
		target.y = snapped(target.y, snap_size)
	_selected.global_position = target
	if _selected and _selected.has_method("reset_base_position"):
		_selected.reset_base_position()
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
		_apply_actor_data_to_node(scene)
		_apply_visual_for_prefab(scene, _stamp_prefab)
	if scene:
		# Reassert the desired name after parenting in case Godot altered it
		if PREFAB_NAMES.has(_stamp_prefab):
			scene.name = PREFAB_NAMES[_stamp_prefab]
		elif packed.resource_path.get_file().get_basename() != "":
			scene.name = packed.resource_path.get_file().get_basename()
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
		"slope_left":
			return preload("res://engine/platforms/PlatformSlopeLeft.tscn")
		"slope_right":
			return preload("res://engine/platforms/PlatformSlopeRight.tscn")
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
	if node == null:
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
		return
	if not Engine.has_singleton("DataRegistry"):
		return
	var reg = Engine.get_singleton("DataRegistry")
	if reg == null or not reg.has_method("get_resource_for_category"):
		return
	var res = reg.get_resource_for_category("Actor", data_id)
	if res == null:
		return
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
	# Persist id/meta so UI and saves stay in sync
	if "data_id" in node:
		node.set("data_id", data_id)
	else:
		node.set_meta("data_id", data_id)


func _update_hover_info() -> void:
	if not editor_mode:
		return
	var node := _pick_node_at_mouse_top()
	_hovered = node
	if node and _overlay and _overlay.has_method("set_hover_info"):
		var name := node.name
		var data_id := ""
		if "data_id" in node:
			var v = node.get("data_id")
			if v is String:
				data_id = v
		elif node.has_meta("data_id"):
			var mv = node.get_meta("data_id")
			if mv is String:
				data_id = mv
		var input := "None"
		if "input_source" in node:
			input = str(node.get("input_source"))
		var pos := Vector2.ZERO
		if node is Node2D:
			pos = (node as Node2D).global_position
		var txt := "Hover: %s | ID: %s | Input: %s | X: %.1f Y: %.1f" % [name, data_id, input, pos.x, pos.y]
		var screen_pos := get_viewport().get_mouse_position() + Vector2(12, 12)
		if _overlay.has_method("set_hover_info"):
			_overlay.call("set_hover_info", txt)
		if _overlay.has_node("HoverTip"):
			var tip := _overlay.get_node("HoverTip")
			if tip and tip is Control:
				(tip as Control).position = screen_pos
	elif _overlay and _overlay.has_method("set_hover_info"):
		_overlay.call("set_hover_info", "Hover: None")


func _pick_node_at_mouse_top() -> Node:
	var pos := _get_mouse_world_pos()
	var hits := _gather_pick_candidates(pos)
	if hits.size() > 0:
		return hits[0]
	return null


func _set_cursor_cross() -> void:
	if _cursor_cross:
		Input.set_custom_mouse_cursor(_cursor_cross, Input.CURSOR_ARROW, Vector2(8, 8))


func _set_cursor_select() -> void:
	if _cursor_select:
		Input.set_custom_mouse_cursor(_cursor_select, Input.CURSOR_ARROW, Vector2(8, 8))
	else:
		Input.set_custom_mouse_cursor(null)


func _set_cursor_plus() -> void:
	if _cursor_plus:
		Input.set_custom_mouse_cursor(_cursor_plus, Input.CURSOR_ARROW, Vector2(8, 8))
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
	else:
		_highlight.visible = false
	_update_hover_info()


func _update_entity_popup(force: bool) -> void:
	if _entity_popup == null:
		return
	var panels_open := false
	if _overlay:
		for name in ["SavePanel", "LoadPanel", "TemplatePanel", "DataEditor"]:
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
	if _baseline_snapshot == null:
		_baseline_snapshot = _make_scene_snapshot()
	_replace_current_scene(_baseline_snapshot)


func _handle_zoom(event: InputEventMouseButton) -> void:
	if editor_camera == null:
		return
	var factor := 1.0 - zoom_step if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 + zoom_step
	var target := editor_camera.zoom * factor
	target.x = clamp(target.x, zoom_min, zoom_max)
	target.y = clamp(target.y, zoom_min, zoom_max)
	editor_camera.zoom = target
	editor_camera.queue_redraw()
	if _overlay and _overlay.has_method("update"):
		_overlay.update()
	_update_snap_from_overlay()
	print("Zoom applied. Button:", event.button_index, "New zoom:", editor_camera.zoom, "is_current:", editor_camera.is_current())


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
	var dir := Vector2.ZERO
	if Input.is_action_pressed("editor_cam_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("editor_cam_right"):
		dir.x += 1.0
	if Input.is_action_pressed("editor_cam_up"):
		dir.y -= 1.0
	if Input.is_action_pressed("editor_cam_down"):
		dir.y += 1.0
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		editor_camera.global_position += dir * camera_pan_speed * delta


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
