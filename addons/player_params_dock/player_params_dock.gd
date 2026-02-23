@tool
extends VBoxContainer

var _editor: EditorInterface
var _selection: EditorSelection
var _target: Node
var _params_node: Node
var _model_data: Resource
var _movement_data: Resource
var _anim_driver: Node
var _selected_animation_player: AnimationPlayer
var _updating_ui: bool = false
var _warned_non_template_edit: bool = false

var _scroll: ScrollContainer
var _root: VBoxContainer
var _search_input: LineEdit
var _search_query: String = ""

const _CATEGORY_ORDER: Array[String] = [
	"Entity",
	"Lifecycle",
	"Controller",
	"Camera",
	"Pivot",
	"Animation Offsets",
	"Movement/Base",
	"Movement/Turning",
	"Movement/Advanced",
	"Movement/Jump",
	"Movement/Wall",
	"Movement/Dash",
	"Movement/Roll",
	"Movement/Posture",
	"Movement/Drop Through",
	"Movement/Fall",
	"Data/Ids",
	"Data/Resources",
	"Editor Preview",
	"Model Data",
	"Anim Driver",
	"Other"
]


func setup(editor: EditorInterface) -> void:
	_editor = editor
	_selection = _editor.get_selection()
	_selection.selection_changed.connect(_on_selection_changed)
	_build_shell()
	_refresh_target()


func _exit_tree() -> void:
	if _selection and _selection.selection_changed.is_connected(_on_selection_changed):
		_selection.selection_changed.disconnect(_on_selection_changed)


func _build_shell() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var toolbar := HBoxContainer.new()
	toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(toolbar)

	_search_input = LineEdit.new()
	_search_input.placeholder_text = "Search parameters..."
	_search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_input.text_changed.connect(_on_search_text_changed)
	toolbar.add_child(_search_input)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_scroll)

	_root = VBoxContainer.new()
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_root)


func _clear_dynamic_rows() -> void:
	while _root.get_child_count() > 0:
		var child: Node = _root.get_child(0)
		_root.remove_child(child)
		child.queue_free()


func _on_selection_changed() -> void:
	_refresh_target()


func _refresh_target() -> void:
	_resolve_target_from_selection()
	_rebuild_ui_for_target()


func _resolve_target_from_selection() -> void:
	_target = null
	_params_node = null
	_model_data = null
	_movement_data = null
	_anim_driver = null
	_selected_animation_player = null

	var nodes: Array = _selection.get_selected_nodes()
	if nodes.size() != 1:
		return

	var selected: Node = nodes[0] as Node
	if selected == null:
		return

	if _looks_like_actor_player(selected):
		_target = selected
	elif selected is AnimationPlayer:
		_selected_animation_player = selected as AnimationPlayer
		_target = _find_actor_owner_from_node(selected)

	if _target == null:
		return

	_params_node = _target.get_node_or_null("ActorParams3D")
	if _params_node and _looks_like_params_node(_params_node) and _has_property(_params_node, "movement_data"):
		var mvp: Variant = _params_node.get("movement_data")
		if mvp is Resource:
			_movement_data = mvp
	if _movement_data == null and _has_property(_target, "movement_data"):
		var mv: Variant = _target.get("movement_data")
		if mv is Resource:
			_movement_data = mv

	if _params_node and _looks_like_params_node(_params_node) and _has_property(_params_node, "model_data"):
		var mdp: Variant = _params_node.get("model_data")
		if mdp is Resource:
			_model_data = mdp
	if _model_data == null and _has_property(_target, "model_data"):
		var md: Variant = _target.get("model_data")
		if md is Resource:
			_model_data = md

	_anim_driver = _target.get_node_or_null("AnimDriver3D")
	if _selected_animation_player == null:
		_selected_animation_player = _find_animation_player_for_target(_target)


func _rebuild_ui_for_target() -> void:
	_updating_ui = true
	_clear_dynamic_rows()

	if _target == null:
		_updating_ui = false
		return

	var section_boxes: Dictionary = {}
	for category in _CATEGORY_ORDER:
		section_boxes[category] = _create_section_box(category)

	_build_object_rows(_target, "actor", section_boxes)
	if _movement_data:
		_build_object_rows(_movement_data, "movement", section_boxes)
	if _model_data:
		_build_object_rows(_model_data, "model", section_boxes)
	if _anim_driver:
		_build_object_rows(_anim_driver, "driver", section_boxes)

	_updating_ui = false


func _find_animation_player_for_target(actor: Node) -> AnimationPlayer:
	if actor == null:
		return null
	var model_root: Node = actor.get_node_or_null("VisualRoot/ModelRoot")
	if model_root == null:
		return actor.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var direct: AnimationPlayer = model_root.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if direct:
		return direct
	return model_root.find_child("AnimationPlayer", true, false) as AnimationPlayer


func _collect_player_animations(player: AnimationPlayer) -> Array[String]:
	var out: Array[String] = []
	if player == null:
		return out
	var names: PackedStringArray = player.get_animation_list()
	for n in names:
		var name: String = str(n)
		if name == "":
			continue
		out.append(_strip_library_prefix(name))
	out.sort()
	var dedup: Array[String] = []
	var seen: Dictionary = {}
	for item in out:
		if seen.has(item):
			continue
		seen[item] = true
		dedup.append(item)
	return dedup


func _strip_library_prefix(anim_name: String) -> String:
	var slash := anim_name.find("/")
	if slash == -1:
		return anim_name
	return anim_name.substr(slash + 1)


func _create_section_box(title: String) -> VBoxContainer:
	var sep := HSeparator.new()
	_root.add_child(sep)

	var label := Label.new()
	label.text = title
	label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	_root.add_child(label)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_child(box)
	return box


func _build_object_rows(obj: Object, source: String, section_boxes: Dictionary) -> void:
	var props: Array = obj.get_property_list()
	for item in props:
		var entry: Dictionary = item as Dictionary
		if entry.is_empty():
			continue
		if not _is_editable_entry(entry):
			continue

		var prop_name: String = str(entry.get("name", ""))
		if source == "actor" and _is_movement_proxy_property(prop_name):
			continue
		if not _matches_search(prop_name, source):
			continue
		var category: String = _category_for_property(prop_name, source)
		var parent: VBoxContainer = section_boxes.get(category, null) as VBoxContainer
		if parent == null:
			parent = section_boxes["Other"] as VBoxContainer
		_add_property_row(parent, obj, source, entry)


func _on_search_text_changed(text: String) -> void:
	_search_query = text.strip_edges().to_lower()
	_refresh_target()


func _matches_search(prop_name: String, source: String) -> bool:
	if _search_query == "":
		return true
	var hay_prop := prop_name.to_lower()
	if hay_prop.find(_search_query) != -1:
		return true
	var hay_label := _label_for_property(prop_name).to_lower()
	if hay_label.find(_search_query) != -1:
		return true
	if source == "model":
		return "model".find(_search_query) != -1
	if source == "driver":
		return "anim".find(_search_query) != -1 or "driver".find(_search_query) != -1
	if source == "movement":
		return "movement".find(_search_query) != -1 or "move".find(_search_query) != -1
	return false


func _is_editable_entry(entry: Dictionary) -> bool:
	var prop_name: String = str(entry.get("name", ""))
	if prop_name == "":
		return false
	if prop_name.begins_with("_"):
		return false
	if prop_name == "script":
		return false

	var usage: int = entry.get("usage", 0)
	if (usage & PROPERTY_USAGE_EDITOR) == 0:
		return false
	return true


func _add_property_row(parent: VBoxContainer, obj: Object, source: String, entry: Dictionary) -> void:
	var prop_name: String = str(entry.get("name", ""))
	if source == "model" and prop_name == "anim_state_offsets":
		_add_anim_state_offsets_editor(parent, source, prop_name, obj)
		return
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)

	var label := Label.new()
	label.text = _label_for_property(prop_name)
	label.custom_minimum_size = Vector2(240, 0)
	row.add_child(label)

	var type_id: int = entry.get("type", TYPE_NIL)
	var hint_id: int = entry.get("hint", PROPERTY_HINT_NONE)
	var hint_text: String = str(entry.get("hint_string", ""))
	var value: Variant = obj.get(prop_name)

	if source == "model" and prop_name.ends_with("_state"):
		_add_animation_state_editor(row, source, prop_name, value)
		return

	if hint_id == PROPERTY_HINT_ENUM:
		_add_enum_editor(row, source, prop_name, value, hint_text)
		return

	match type_id:
		TYPE_BOOL:
			var cb := CheckBox.new()
			cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cb.button_pressed = value if value is bool else false
			cb.toggled.connect(_on_bool_changed.bind(source, prop_name))
			row.add_child(cb)
		TYPE_INT:
			var spin_i := SpinBox.new()
			_setup_numeric_spin(spin_i, hint_text, true)
			if value is int:
				spin_i.value = value
			elif value is float:
				spin_i.value = value
			else:
				spin_i.value = 0.0
			spin_i.value_changed.connect(_on_number_changed.bind(source, prop_name, true))
			row.add_child(spin_i)
		TYPE_FLOAT:
			var spin_f := SpinBox.new()
			_setup_numeric_spin(spin_f, hint_text, false)
			if value is float or value is int:
				spin_f.value = value
			else:
				spin_f.value = 0.0
			spin_f.value_changed.connect(_on_number_changed.bind(source, prop_name, false))
			row.add_child(spin_f)
		TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
			var line := LineEdit.new()
			line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.text = str(value)
			line.text_submitted.connect(_on_text_submitted.bind(source, prop_name))
			line.focus_exited.connect(_on_line_focus_exited.bind(line, source, prop_name))
			row.add_child(line)
		_:
			var readonly := Label.new()
			readonly.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			readonly.text = "[%s] %s" % [type_string(type_id), str(value)]
			readonly.modulate = Color(0.7, 0.7, 0.7)
			row.add_child(readonly)


func _add_anim_state_offsets_editor(parent: VBoxContainer, source: String, prop_name: String, obj: Object) -> void:
	var dict_any: Variant = obj.get(prop_name)
	if not (dict_any is Dictionary):
		return
	var offsets: Dictionary = dict_any as Dictionary
	var keys: Array[String] = []
	for k in offsets.keys():
		keys.append(str(k))
	keys.sort_custom(_sort_anim_state_keys)
	for key in keys:
		if not _matches_search(key, "model"):
			continue
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		parent.add_child(row)
		var label := Label.new()
		label.text = key
		label.custom_minimum_size = Vector2(240, 0)
		row.add_child(label)
		var btn := Button.new()
		btn.text = "Preview"
		btn.custom_minimum_size = Vector2(72, 0)
		btn.pressed.connect(_on_preview_anim_state_pressed.bind(key))
		row.add_child(btn)
		var spin := SpinBox.new()
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.allow_greater = true
		spin.allow_lesser = true
		spin.step = 0.01
		var value_any: Variant = offsets.get(key, 0.0)
		if value_any is float or value_any is int:
			spin.value = float(value_any)
		else:
			spin.value = 0.0
		spin.value_changed.connect(_on_anim_state_offset_changed.bind(source, prop_name, key))
		row.add_child(spin)


func _on_anim_state_offset_changed(v: float, source: String, prop_name: String, key: String) -> void:
	if _updating_ui:
		return
	var obj: Object = _source_object(source)
	if obj == null:
		return
	var current_any: Variant = obj.get(prop_name)
	if not (current_any is Dictionary):
		return
	var current: Dictionary = current_any as Dictionary
	var next: Dictionary = current.duplicate()
	next[key] = v
	_apply_property(source, prop_name, next)
	_force_save_model()
	_refresh_actor_offset(key)


func _sort_anim_state_keys(a: String, b: String) -> bool:
	var pa := _anim_state_priority(a)
	var pb := _anim_state_priority(b)
	if pa != pb:
		return pa < pb
	return a < b


func _anim_state_priority(key: String) -> int:
	var k := key
	if k.begins_with("combat_"):
		if k.find("_crouch_") != -1:
			return 30
		return 20
	if k.begins_with("crouch"):
		return 10
	if k.begins_with("interact_"):
		return 40
	if k.begins_with("traversal_"):
		return 50
	return 0


func _force_save_model() -> void:
	if _model_data == null:
		return
	if _is_playing_scene():
		return
	if _model_data is Resource:
		var res: Resource = _model_data as Resource
		if res.resource_local_to_scene:
			_persist_edited_scene_if_needed("actor")
		elif res.resource_path != "":
			ResourceSaver.save(res)


func _ensure_local_resource(obj: Object, prop_name: String) -> Object:
	if not (obj is Resource):
		return obj
	var res: Resource = obj as Resource
	if res.resource_local_to_scene:
		return obj
	var dup := res.duplicate()
	if dup is Resource:
		var dup_res: Resource = dup as Resource
		dup_res.resource_local_to_scene = true
		if _params_node and _has_property(_params_node, prop_name):
			_params_node.set(prop_name, dup_res)
		if _target and _has_property(_target, prop_name):
			_target.set(prop_name, dup_res)
		if prop_name == "model_data":
			_model_data = dup_res
		if prop_name == "movement_data":
			_movement_data = dup_res
		return dup_res
	return obj


func _refresh_actor_offset(state_name: String) -> void:
	if _target == null:
		return
	if not _target.has_method("set_anim_floor_offset"):
		return
	if not _target.has_method("get_anim_floor_offset"):
		return
	if _anim_driver != null and _anim_driver.has_method("get_current_state"):
		var current: String = str(_anim_driver.call("get_current_state"))
		if current != "" and current != state_name:
			return
	var offset_any: Variant = _target.call("get_anim_floor_offset", state_name, "")
	if offset_any is float or offset_any is int:
		_target.call("set_anim_floor_offset", float(offset_any))


func _is_playing_scene() -> bool:
	if _editor == null:
		return false
	if _editor.has_method("is_playing_scene"):
		return bool(_editor.call("is_playing_scene"))
	if _editor.has_method("get_playing_scene"):
		return _editor.call("get_playing_scene") != null
	return false


func _on_preview_anim_state_pressed(state_name: String) -> void:
	if _selected_animation_player == null:
		_selected_animation_player = _find_animation_player_for_target(_target)
	if _selected_animation_player == null:
		push_warning("Player Params Dock: no AnimationPlayer found for preview.")
		return
	var clip := state_name
	if _model_data and "resolve_state" in _model_data:
		clip = str(_model_data.call("resolve_state", state_name))
	if clip == "":
		return
	if _anim_driver != null and _anim_driver.has_method("set_state"):
		_anim_driver.call("set_state", state_name)
		_select_animation_clip_in_player(state_name)
		call_deferred("_focus_animation_player")
		return
	push_warning("Player Params Dock: AnimDriver3D not found; preview requires runtime state mapping.")


func _focus_animation_player() -> void:
	if _selected_animation_player == null:
		_selected_animation_player = _find_animation_player_for_target(_target)
	if _selected_animation_player == null or _editor == null:
		return
	var sel := _editor.get_selection()
	if sel == null:
		return
	sel.clear()
	sel.add_node(_selected_animation_player)


func _select_animation_clip_in_player(state_name: String) -> void:
	if _selected_animation_player == null:
		_selected_animation_player = _find_animation_player_for_target(_target)
	if _selected_animation_player == null:
		return
	var clip := state_name
	if _model_data and "resolve_state" in _model_data:
		clip = str(_model_data.call("resolve_state", state_name))
	if clip == "":
		return
	if not _selected_animation_player.has_animation(clip):
		var prefixed := "biped/" + clip
		if _selected_animation_player.has_animation(prefixed):
			clip = prefixed
	if _selected_animation_player.has_animation(clip):
		_selected_animation_player.current_animation = clip
		_selected_animation_player.stop()


 


func _add_enum_editor(row: HBoxContainer, source: String, prop_name: String, value: Variant, hint_text: String) -> void:
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var enum_items: PackedStringArray = hint_text.split(",")
	for i in range(enum_items.size()):
		option.add_item(enum_items[i].strip_edges(), i)

	var selected: int = 0
	if value is int:
		selected = value
	if selected >= 0 and selected < option.item_count:
		option.select(selected)

	option.item_selected.connect(_on_enum_selected.bind(source, prop_name))
	row.add_child(option)


func _add_animation_state_editor(row: HBoxContainer, source: String, prop_name: String, value: Variant) -> void:
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.add_item("")
	option.set_item_metadata(0, "")
	var current_value: String = _strip_library_prefix(str(value))
	var anim_names: Array[String] = _collect_player_animations(_selected_animation_player)
	if current_value != "" and not anim_names.has(current_value):
		anim_names.append(current_value)
	for anim_name in anim_names:
		option.add_item(anim_name)
		option.set_item_metadata(option.item_count - 1, anim_name)
	var selected_idx: int = 0
	for i in range(option.item_count):
		var meta: Variant = option.get_item_metadata(i)
		if str(meta) == current_value:
			selected_idx = i
			break
	option.select(selected_idx)
	option.item_selected.connect(_on_animation_state_selected.bind(option, source, prop_name))
	row.add_child(option)


func _on_animation_state_selected(idx: int, option: OptionButton, source: String, prop_name: String) -> void:
	if idx < 0:
		return
	var value_any: Variant = option.get_item_metadata(idx)
	_apply_property(source, prop_name, str(value_any))


func _setup_numeric_spin(spin: SpinBox, hint_text: String, is_int: bool) -> void:
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.allow_greater = true
	spin.allow_lesser = true
	spin.step = 1.0 if is_int else 0.01
	spin.rounded = is_int

	if hint_text == "":
		return

	var parts: PackedStringArray = hint_text.split(",")
	if parts.size() >= 1 and parts[0] != "":
		spin.min_value = parts[0].to_float()
	if parts.size() >= 2 and parts[1] != "":
		spin.max_value = parts[1].to_float()
	if parts.size() >= 3 and parts[2] != "":
		spin.step = parts[2].to_float()


func _on_bool_changed(v: bool, source: String, prop_name: String) -> void:
	_apply_property(source, prop_name, v)


func _on_number_changed(v: float, source: String, prop_name: String, as_int: bool) -> void:
	if as_int:
		_apply_property(source, prop_name, roundi(v))
	else:
		_apply_property(source, prop_name, v)


func _on_enum_selected(idx: int, source: String, prop_name: String) -> void:
	_apply_property(source, prop_name, idx)


func _on_text_submitted(v: String, source: String, prop_name: String) -> void:
	_apply_property(source, prop_name, v)


func _on_line_focus_exited(line: LineEdit, source: String, prop_name: String) -> void:
	if _updating_ui:
		return
	_apply_property(source, prop_name, line.text)


func _apply_property(source: String, prop_name: String, new_value: Variant) -> void:
	if _updating_ui:
		return

	var obj: Object = _source_object(source)
	if obj == null:
		return
	if source == "model":
		obj = _ensure_local_resource(obj, "model_data")
	if source == "movement":
		obj = _ensure_local_resource(obj, "movement_data")

	var old_value: Variant = obj.get(prop_name)
	if old_value == new_value:
		return

	var undo: EditorUndoRedoManager = _editor.get_editor_undo_redo()
	if undo != null:
		undo.create_action("Set %s.%s" % [source, prop_name])
		undo.add_do_property(obj, prop_name, new_value)
		undo.add_undo_property(obj, prop_name, old_value)
		undo.commit_action()
	else:
		obj.set(prop_name, new_value)

	if (source == "model" or source == "movement") and obj is Resource:
		var res: Resource = obj as Resource
		if res.resource_local_to_scene:
			_persist_edited_scene_if_needed("actor")
		elif res.resource_path != "":
			ResourceSaver.save(res)
	_persist_actor_side_effects(source, prop_name)
	_persist_edited_scene_if_needed(source)
	_refresh_target()


func _persist_actor_side_effects(source: String, prop_name: String) -> void:
	if source != "actor":
		return
	if _target == null:
		return
	if not _is_movement_proxy_property(prop_name):
		return
	var movement_res_any: Variant = null
	var params_node: Node = _target.get_node_or_null("ActorParams3D")
	if params_node != null and _has_property(params_node, "movement_data"):
		movement_res_any = params_node.get("movement_data")
	elif _has_property(_target, "movement_data"):
		movement_res_any = _target.get("movement_data")
	if not (movement_res_any is Resource):
		return
	var movement_res: Resource = movement_res_any as Resource
	if movement_res.resource_path == "":
		return
	ResourceSaver.save(movement_res)


func _persist_edited_scene_if_needed(source: String) -> void:
	if source != "actor":
		return
	if _editor == null:
		return
	var edited_root: Node = _editor.get_edited_scene_root()
	if edited_root == null or _target == null:
		return
	var in_template_tree: bool = (_target == edited_root) or edited_root.is_ancestor_of(_target)
	if not in_template_tree:
		if not _warned_non_template_edit:
			_warned_non_template_edit = true
			push_warning("Player Params Dock: selection is not in edited scene template; changes may be runtime-only.")
		return
	var scene_path: String = edited_root.scene_file_path
	if scene_path == "":
		return
	var packed := PackedScene.new()
	var pack_err: int = packed.pack(edited_root)
	if pack_err != OK:
		push_warning("Player Params Dock: failed to pack edited scene for save.")
		return
	var save_err: int = ResourceSaver.save(packed, scene_path)
	if save_err != OK:
		push_warning("Player Params Dock: failed to save edited scene template.")


func _is_movement_proxy_property(prop_name: String) -> bool:
	return (
		prop_name.begins_with("base_")
		or prop_name.begins_with("turn_")
		or prop_name.begins_with("advanced_")
		or prop_name.begins_with("jump_")
		or prop_name.begins_with("wall_")
		or prop_name.begins_with("dash_")
		or prop_name.begins_with("roll_")
		or prop_name.begins_with("posture_")
		or prop_name.begins_with("drop_")
		or prop_name.begins_with("fall_")
	)


func _source_object(source: String) -> Object:
	match source:
		"actor":
			return _target
		"model":
			return _model_data
		"movement":
			return _movement_data
		"driver":
			return _anim_driver
	return null


func _looks_like_actor_player(node: Node) -> bool:
	if not _has_property(node, "base_walk_speed"):
		return false
	if _has_property(node, "actor_role"):
		var role: Variant = node.get("actor_role")
		if role is int:
			return role == 0
	return true


func _find_actor_owner_from_node(node: Node) -> Node:
	var current: Node = node
	while current:
		if _looks_like_actor_player(current):
			return current
		current = current.get_parent()
	return null


func _has_property(node: Node, prop: String) -> bool:
	var list: Array = node.get_property_list()
	for entry_any in list:
		var entry: Dictionary = entry_any as Dictionary
		if str(entry.get("name", "")) == prop:
			return true
	return false


func _looks_like_params_node(node: Node) -> bool:
	if node == null:
		return false
	if node.name == "ActorParams3D":
		return true
	var s: Variant = node.get_script()
	if s is Script:
		var p: String = String((s as Script).resource_path)
		if p.ends_with("ActorParams3D.gd"):
			return true
	return _has_property(node, "movement_data") and _has_property(node, "model_data")


func _label_for_property(prop_name: String) -> String:
	var text := prop_name.replace("_", " ")
	return text.capitalize()


func _category_for_property(prop_name: String, source: String) -> String:
	if source == "model":
		if prop_name == "anim_state_offsets":
			return "Animation Offsets"
		return "Model Data"
	if source == "movement":
		if prop_name in ["id", "description", "tags"]:
			return "Data/Resources"
		if prop_name in ["gravity", "walk_speed", "run_speed", "sprint_enabled", "sprint_double_tap_window", "sprint_boost_multiplier", "sprint_boost_fade_time", "acceleration", "deceleration", "turn_rate", "turn_smooth", "turn_invert"]:
			return "Movement/Base"
		if prop_name in ["max_slope_angle", "step_height", "step_snap_max_angle", "step_sensor_distance", "step_snap_smooth_speed", "air_control", "air_accel", "air_decel", "max_fall_speed", "floor_leave_delay"]:
			return "Movement/Advanced"
		if prop_name in ["jump_speed", "double_jump_speed", "max_jumps", "coyote_time", "jump_buffer_time", "require_jump_release", "double_jump_clamp_fall_speed", "jump_cut"]:
			return "Movement/Jump"
		if prop_name in ["wall_min_slide_angle", "wall_jump_enabled", "wall_check_distance", "wall_check_height", "wall_slide_gravity_scale", "wall_slide_max_fall_speed", "wall_jump_up_speed", "wall_jump_push_speed", "wall_jump_lock_time"]:
			return "Movement/Wall"
		if prop_name in ["dash_speed", "dash_time", "dash_cooldown", "dash_allow_air", "dash_allow_double_tap", "dash_double_tap_window"]:
			return "Movement/Dash"
		if prop_name in ["roll_speed", "roll_time", "roll_cooldown"]:
			return "Movement/Roll"
		if prop_name in ["crouch_height", "crouch_transition_time", "crouch_speed", "sneak_speed"]:
			return "Movement/Posture"
		if prop_name in ["drop_through_time", "drop_through_layer", "drop_through_speed"]:
			return "Movement/Drop Through"
		if prop_name in ["high_fall_speed", "high_fall_time"]:
			return "Movement/Fall"
		return "Movement/Base"
	if source == "driver":
		return "Anim Driver"

	if prop_name.begins_with("actor_") or prop_name in ["faction_id", "team", "owner_id"]:
		return "Entity"
	if prop_name in ["initial_state", "active_state"]:
		return "Lifecycle"
	if prop_name.begins_with("controller_") or prop_name in ["use_player_input", "player_number", "use_basic_movement"]:
		return "Controller"
	if prop_name == "camera_context" or prop_name.begins_with("first_person_"):
		return "Camera"
	if prop_name.begins_with("pivot_"):
		return "Pivot"
	if prop_name.begins_with("base_"):
		return "Movement/Base"
	if prop_name.begins_with("turn_"):
		return "Movement/Turning"
	if prop_name.begins_with("advanced_"):
		return "Movement/Advanced"
	if prop_name.begins_with("jump_"):
		return "Movement/Jump"
	if prop_name.begins_with("wall_"):
		return "Movement/Wall"
	if prop_name.begins_with("dash_"):
		return "Movement/Dash"
	if prop_name.begins_with("roll_"):
		return "Movement/Roll"
	if prop_name.begins_with("posture_"):
		return "Movement/Posture"
	if prop_name.begins_with("drop_"):
		return "Movement/Drop Through"
	if prop_name.begins_with("fall_"):
		return "Movement/Fall"
	if prop_name.ends_with("_id"):
		return "Data/Ids"
	if prop_name.ends_with("_data"):
		return "Data/Resources"
	if prop_name.begins_with("preview_"):
		return "Editor Preview"
	return "Other"
