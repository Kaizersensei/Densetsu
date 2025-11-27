extends Node

signal editor_entered
signal editor_exited
signal selection_changed(node)

@export var toggle_action := "toggle_editor"
@export var toggle_cooldown := 0.2
@export var snap_enabled := false
@export var snap_size := 8.0
var editor_mode := false
var editor_camera: Camera2D
var _game_camera: Camera2D
var _overlay: CanvasLayer
var _grid: Node2D
var _toggle_lock := 0.0
var _selected: Node
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
const HISTORY_TRANSFORM := "transform"
const HISTORY_CREATE := "create"
const HISTORY_DELETE := "delete"

func _ready() -> void:
	set_process_input(true)
	set_process_unhandled_input(true)
	set_process_unhandled_key_input(true)
	_ensure_toggle_action()
	print("EditorManager ready. Toggle action:", toggle_action)
	_overlay = preload("res://engine/editor/EditorOverlay.tscn").instantiate()
	_overlay.visible = false
	add_child(_overlay)
	if _overlay and _overlay.has_method("connect_inspector"):
		_overlay.connect_inspector(_on_inspector_changed)
	if _overlay and _overlay.has_method("connect_prefab_buttons"):
		_overlay.connect_prefab_buttons(_on_prefab_selected)
	editor_camera = preload("res://engine/editor/EditorCamera2D.tscn").instantiate()
	editor_camera.enabled = false
	editor_camera.visible = false
	add_child(editor_camera)
	_grid = preload("res://engine/editor/GridOverlay.gd").new()
	_grid.visible = false
	add_child(_grid)
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


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_action):
		_toggle_editor()
		print("Editor toggle via _input; editor_mode now:", editor_mode)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		if event.keycode == KEY_F12 or event.physical_keycode == KEY_F12:
			_toggle_editor()
			print("Editor toggle via KEY_F12 fallback; editor_mode now:", editor_mode)
			get_viewport().set_input_as_handled()
	if not editor_mode:
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and _dragging:
		_drag_selection()
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
		editor_camera.make_current()
		editor_camera.enabled = true
		editor_camera.visible = true
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
	selection_changed.emit(node)
	_selected = node
	_dragging = false
	if _overlay and _overlay.has_method("set_selection_name"):
		var name: String = node.name if node else "None"
		_overlay.set_selection_name(name)
	if _overlay and _overlay.has_method("populate_inspector"):
		_overlay.populate_inspector(node)
	_update_highlight()


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
	if _dragging:
		_drag_selection()
	elif _inspector_dirty and _overlay:
		if _overlay.has_method("populate_inspector"):
			_overlay.populate_inspector(_selected)
			_inspector_dirty = false
	elif _selected and _selected is CharacterBody2D:
		_update_highlight()


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
	var space_state = get_viewport().get_world_2d().direct_space_state
	var pos = _get_mouse_world_pos()
	var params := PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collide_with_areas = true
	params.collide_with_bodies = true
	var results = space_state.intersect_point(params)
	for res in results:
		if res.has("collider") and res.collider:
			var collider: Node = res.collider
			# Prefer grouped "actors" nodes
			if collider.is_in_group("actors"):
				return collider
			if collider.get_parent() and collider.get_parent().is_in_group("actors"):
				return collider.get_parent()
			# Fallback: return the collider itself (solid/scenery)
			return collider
	# If nothing with colliders, try visuals (Sprite2D/Polygon2D)
	var visual := _pick_visual_node(pos)
	if visual:
		return visual
	return null


func _pick_visual_node(world_pos: Vector2) -> Node:
	var best: Node = null
	var best_dist: float = INF
	var stack: Array = [get_tree().root]
	while stack.size() > 0:
		var node = stack.pop_back()
		if node is Sprite2D:
			if _sprite_contains_point(node, world_pos):
				var d: float = node.global_position.distance_to(world_pos)
				if d < best_dist:
					best_dist = d
					best = node
		elif node is Polygon2D:
			if _polygon_contains_point(node, world_pos):
				var d: float = node.global_position.distance_to(world_pos)
				if d < best_dist:
					best_dist = d
					best = node
		for child in node.get_children():
			if child is Node:
				stack.append(child)
	return best


func _sprite_contains_point(sprite: Sprite2D, world_pos: Vector2) -> bool:
	if sprite.texture == null:
		return false
	var local := sprite.to_local(world_pos)
	var tex_size: Vector2 = sprite.texture.get_size() * sprite.scale
	if sprite.centered:
		var half := tex_size * 0.5
		return absf(local.x) <= half.x and absf(local.y) <= half.y
	else:
		return local.x >= 0.0 and local.y >= 0.0 and local.x <= tex_size.x and local.y <= tex_size.y


func _polygon_contains_point(poly: Polygon2D, world_pos: Vector2) -> bool:
	var local := poly.to_local(world_pos)
	return Geometry2D.is_point_in_polygon(local, poly.polygon)


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
		return node
	for child in node.get_children():
		var found := _find_collision_shape(child)
		if found:
			return found
	return null


func _on_prefab_selected(kind: String) -> void:
	if kind == "undo":
		_undo()
		return
	if kind == "redo":
		_redo()
		return
	if kind == "save":
		_save_scene()
		return
	if kind == "load":
		_load_scene()
		return
	if kind == "reload":
		_reload_scene()
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
	get_tree().current_scene.add_child(scene)
	if _stamp_prefab == "enemy":
		_attach_enemy_spawner(scene)
	if scene and scene.has_method("reset_base_position"):
		scene.reset_base_position()
	var entry := _make_create_entry(scene)
	_push_history_entry(entry)
	set_selection(scene)
	_set_cursor_plus()


func _attach_enemy_spawner(enemy: Node) -> void:
	if enemy == null or not (enemy is Node):
		return
	var spawner := preload("res://engine/projectiles/ProjectileSpawner.tscn").instantiate()
	spawner.owner_path = NodePath("..")
	spawner.projectile_scene = preload("res://engine/projectiles/EnemyProjectile2D.tscn")
	spawner.speed = 250.0
	spawner.direction = -1.0
	spawner.fire_interval = 2.0
	enemy.add_child(spawner)


func _get_prefab_scene(kind: String) -> PackedScene:
	match kind:
		"player":
			return preload("res://engine/actors/ActorCharacter2D.tscn")
		"enemy":
			return preload("res://engine/actors/EnemyDummy.tscn")
		"deco":
			return preload("res://engine/decoration/ActorDeco2D.tscn")
		"deco_solid":
			return preload("res://engine/decoration/ActorDeco2D_Static.tscn")
		"trap":
			return preload("res://engine/traps/ActorTrap2D.tscn")
		"item":
			return preload("res://engine/items/ActorItem2D.tscn")
		"ground":
			return preload("res://engine/platforms/PlatformGround.tscn")
		"wall":
			return preload("res://engine/platforms/PlatformWall.tscn")
		"one_way":
			return preload("res://engine/platforms/PlatformOneWay.tscn")
		"slope_left":
			return preload("res://engine/platforms/PlatformSlopeLeft.tscn")
		"slope_right":
			return preload("res://engine/platforms/PlatformSlopeRight.tscn")
		_:
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
		var cs := _find_collision_shape(n)
		var points := PackedVector2Array()
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
					points.append(cs.global_transform * p)
			elif cs.shape is ConvexPolygonShape2D:
				var poly := (cs.shape as ConvexPolygonShape2D).points
				for p in poly:
					points.append(cs.global_transform * p)
				if poly.size() > 0:
					points.append(cs.global_transform * poly[0])
		if points.size() == 0:
			var half := Vector2(8, 8)
			var local_points := [
				Vector2(-half.x, -half.y),
				Vector2(half.x, -half.y),
				Vector2(half.x, half.y),
				Vector2(-half.x, half.y),
				Vector2(-half.x, -half.y),
			]
			for p in local_points:
				points.append(n.global_transform * p)
		_highlight.global_position = Vector2.ZERO
		_highlight.points = points
		_highlight.visible = true
	else:
		_highlight.visible = false


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
			var sx := float(_overlay._scale_x.text)
			n.scale.x = sx
		"scale_y":
			var sy := float(_overlay._scale_y.text)
			n.scale.y = sy
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


func _save_scene() -> void:
	var snap := _make_scene_snapshot()
	if snap == null:
		print("Save skipped: unable to snapshot scene.")
		return
	var path := "user://editor_save.tscn"
	var err := ResourceSaver.save(snap, path)
	if err != OK:
		push_error("Failed to save scene to %s (err %d)" % [path, err])
	else:
		print("Scene saved to", path)
		_baseline_snapshot = snap


func _load_scene() -> void:
	var path := "user://editor_save.tscn"
	if not ResourceLoader.exists(path):
		push_warning("No saved scene found at %s" % path)
		return
	var packed: PackedScene = ResourceLoader.load(path)
	if packed:
		_replace_current_scene(packed)
		_baseline_snapshot = _make_scene_snapshot()


func _reload_scene() -> void:
	if _baseline_snapshot == null:
		_baseline_snapshot = _make_scene_snapshot()
	_replace_current_scene(_baseline_snapshot)
