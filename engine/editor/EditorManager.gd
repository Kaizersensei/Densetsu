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
			if _stamp_prefab != "":
				_place_prefab_at_mouse()
			else:
				var node := _pick_node_at_mouse()
				set_selection(node)
				if node:
					_dragging = true
					_drag_offset = node.global_position - _get_mouse_world_pos()
		else:
			_dragging = false
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_stamp_prefab = ""


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
	_update_highlight()
	_inspector_dirty = true


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
	_stamp_prefab = kind


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
	set_selection(scene)
	_stamp_prefab = ""


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
		"trap":
			return preload("res://engine/traps/ActorTrap2D.tscn")
		"item":
			return preload("res://engine/items/ActorItem2D.tscn")
		"ground":
			return preload("res://engine/platforms/PlatformGround.tscn")
		"wall":
			return preload("res://engine/platforms/PlatformWall.tscn")
		"slope_left":
			return preload("res://engine/platforms/PlatformSlopeLeft.tscn")
		"slope_right":
			return preload("res://engine/platforms/PlatformSlopeRight.tscn")
		_:
			return null


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
	_inspector_dirty = false
	_update_highlight()
	if _overlay and _overlay.has_method("populate_inspector"):
		_overlay.populate_inspector(_selected)
