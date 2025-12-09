extends Panel

const MARGIN := 10.0

@onready var _tabs: TabContainer = $Scroll/Tabs
@onready var _pos_x: LineEdit = $Scroll/Tabs/Transform/PosRow/PosX
@onready var _pos_y: LineEdit = $Scroll/Tabs/Transform/PosRow/PosY
@onready var _rot_deg: LineEdit = $Scroll/Tabs/Transform/RotScaleRow/RotDeg
@onready var _scale_x: LineEdit = $Scroll/Tabs/Transform/RotScaleRow/ScaleX
@onready var _scale_y: LineEdit = $Scroll/Tabs/Transform/RotScaleRow/ScaleY

@onready var _data_id: Label = $Scroll/Tabs/Data/DataSubTabs/TemplateTab/Type/DataId
@onready var _data_type: OptionButton = $Scroll/Tabs/Data/DataSubTabs/TemplateTab/Type/TypeRow/DataType
@onready var _open_data: Button = $Scroll/Tabs/Data/DataSubTabs/TemplateTab/Type/OpenData

@onready var _inst_tags: LineEdit = $Scroll/Tabs/Data/DataSubTabs/InstanceTab/Instance/TagsRow/Tags
@onready var _inst_sprite: LineEdit = $Scroll/Tabs/Data/DataSubTabs/InstanceTab/Instance/SpriteRow/SpriteOverride
@onready var _inst_sprite_load: Button = $Scroll/Tabs/Data/DataSubTabs/InstanceTab/Instance/SpriteRow/SpriteLoad
@onready var _inst_collision_mask: LineEdit = $Scroll/Tabs/Data/DataSubTabs/InstanceTab/Instance/CollisionRow/CollisionMask
@onready var _inst_no_proj: CheckBox = $Scroll/Tabs/Data/DataSubTabs/InstanceTab/Instance.get_node_or_null("NoProj")
@onready var _inst_layers_label: Label = $Scroll/Tabs/Data/DataSubTabs/InstanceTab/Instance/LayerNames
@onready var _inst_apply: Button = $Scroll/Tabs/Data/DataSubTabs/InstanceTab/Instance.get_node_or_null("InstanceApply")
@onready var _transform_timer: Timer = $TransformTimer
var _tele_fields: Dictionary = {}
var _tele_apply: Button = null
var _dynamic_sections: Dictionary = {}
var _base_width: float = 0.0
var _data_subtabs: TabContainer = null
var _template_tab: VBoxContainer = null
var _template_content: VBoxContainer = null
var _instance_tab: VBoxContainer = null
var _module_keys := {
	"enable_glide": ["glide_gravity_scale", "glide_max_fall_speed"],
	"enable_flight": ["flight_acceleration", "flight_max_speed", "flight_drag"],
	"enable_swim": ["swim_speed", "swim_drag", "swim_gravity_scale", "swim_jump_speed"],
	"enable_flap": ["max_flaps", "flap_impulse"],
}
var _subtab_prev: Button = null
var _subtab_next: Button = null
var _template_fields: Dictionary = {}
var _last_tab: int = 0
var _last_subtab: int = 0
var _data_subtab_connected: bool = false
var _inspector_state := {"tab": 0, "sub": 0}
const DYN_FIELDS := {
	"Actor": [
		{"key": "movement_id", "label": "Movement Id", "type": "string", "resource": false},
		{"key": "tags", "label": "Tags", "type": "string", "resource": false},
		{"key": "sprite", "label": "Sprite", "type": "string", "resource": true},
		{"key": "tint", "label": "Tint", "type": "color", "resource": false},
		{"key": "collision_mask", "label": "Collision Mask", "type": "int"},
	],
	"Movement": [
		{"key": "move_speed", "label": "Move Speed", "type": "float"},
		{"key": "acceleration", "label": "Acceleration", "type": "float"},
		{"key": "friction_ground", "label": "Ground Friction", "type": "float"},
		{"key": "friction_air", "label": "Air Friction", "type": "float"},
		{"key": "max_fall_speed", "label": "Max Fall Speed", "type": "float"},
		{"key": "slope_penalty", "label": "Slope Penalty", "type": "float"},
		{"key": "jump_speed", "label": "Jump Speed", "type": "float"},
		{"key": "air_jump_speed", "label": "Air Jump Speed", "type": "float"},
		{"key": "max_jumps", "label": "Max Jumps", "type": "int"},
		{"key": "coyote_time", "label": "Coyote Time", "type": "float"},
		{"key": "jump_buffer_time", "label": "Jump Buffer", "type": "float"},
		{"key": "min_jump_height", "label": "Min Jump Height", "type": "float"},
		{"key": "jump_release_gravity_scale", "label": "Release Gravity Scale", "type": "float"},
		{"key": "jump_release_cut", "label": "Release Cut", "type": "float"},
		{"key": "drop_through_time", "label": "Drop Through Time", "type": "float"},
		{"key": "wall_slide_gravity_scale", "label": "Wall Slide Gravity", "type": "float"},
		{"key": "wall_jump_speed_x", "label": "Wall Jump X", "type": "float"},
		{"key": "wall_jump_speed_y", "label": "Wall Jump Y", "type": "float"},
		{"key": "enable_glide", "label": "Enable Glide", "type": "bool"},
		{"key": "glide_gravity_scale", "label": "Glide Gravity", "type": "float"},
		{"key": "glide_max_fall_speed", "label": "Glide Max Fall", "type": "float"},
		{"key": "enable_flight", "label": "Enable Flight", "type": "bool"},
		{"key": "flight_acceleration", "label": "Flight Accel", "type": "float"},
		{"key": "flight_max_speed", "label": "Flight Max Speed", "type": "float"},
		{"key": "flight_drag", "label": "Flight Drag", "type": "float"},
		{"key": "enable_swim", "label": "Enable Swim", "type": "bool"},
		{"key": "swim_speed", "label": "Swim Speed", "type": "float"},
		{"key": "swim_drag", "label": "Swim Drag", "type": "float"},
		{"key": "swim_gravity_scale", "label": "Swim Gravity", "type": "float"},
		{"key": "swim_jump_speed", "label": "Swim Jump Speed", "type": "float"},
		{"key": "enable_flap", "label": "Enable Flap", "type": "bool"},
		{"key": "max_flaps", "label": "Max Flaps", "type": "int"},
		{"key": "flap_impulse", "label": "Flap Impulse", "type": "float"},
	],
	"Teleporter": [
		{"key": "exit_only", "label": "Exit Only", "type": "bool"},
		{"key": "activation_mode", "label": "Activation", "type": "string"},
		{"key": "activation_action", "label": "Action", "type": "string"},
		{"key": "destination_scene", "label": "Destination Scene", "type": "string"},
		{"key": "dropoff_mode", "label": "Dropoff Mode", "type": "string"},
		{"key": "dropoff_target", "label": "Dropoff Target", "type": "string"},
		{"key": "dropoff_margin", "label": "Dropoff Margin", "type": "float"},
	],
}

var _current_node: Node = null

func _ready() -> void:
	_ensure_data_tab()
	if _data_type:
		_data_type.item_selected.connect(_on_type_selected)
	if _transform_timer:
		_transform_timer.one_shot = true
	if _pos_x:
		_pos_x.text_submitted.connect(_on_transform_submitted)
	if _pos_y:
		_pos_y.text_submitted.connect(_on_transform_submitted)
	if _rot_deg:
		_rot_deg.text_submitted.connect(_on_transform_submitted)
	if _scale_x:
		_scale_x.text_submitted.connect(_on_transform_submitted)
	if _scale_y:
		_scale_y.text_submitted.connect(_on_transform_submitted)
	if _inst_apply:
		_inst_apply.pressed.connect(_apply_overrides)
	if _inst_sprite_load:
		_inst_sprite_load.pressed.connect(_browse_sprite)
	if _open_data:
		_open_data.pressed.connect(_open_in_data_panel)
	_setup_teleporter_controls()
	_base_width = size.x
	if _tabs:
		_tabs.tab_changed.connect(func(idx: int):
			_last_tab = idx
			_inspector_state["tab"] = idx
		)

func show_for(node: Node, viewport_rect: Rect2, ribbon_h: float, sidebar_w: float) -> void:
	if node == null:
		hide()
		return
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_current_node = node
	# reset scroll offsets to avoid overlay/bleed
	var scroll := get_node_or_null("Scroll") as ScrollContainer
	if scroll:
		scroll.set_v_scroll(0)
		scroll.set_h_scroll(0)
	if _tabs:
		var tab_idx := int(_inspector_state.get("tab", _last_tab))
		_tabs.current_tab = clamp(tab_idx, 0, max(0, _tabs.get_tab_count() - 1))
	_populate(node)
	if _data_subtabs:
		var sub_idx := int(_inspector_state.get("sub", _last_subtab))
		_data_subtabs.current_tab = clamp(sub_idx, 0, max(0, _data_subtabs.get_tab_count() - 1))
	var target := _get_screen_position(node, viewport_rect)
	if _base_width > 0.0:
		size.x = max(size.x, _base_width * 1.33)
	var w := size.x
	var h := size.y
	var min_x := sidebar_w + MARGIN
	var max_x := viewport_rect.size.x - w - MARGIN
	var min_y := ribbon_h + MARGIN
	var max_y := viewport_rect.size.y - h - MARGIN
	target.x = clamp(target.x, min_x, max_x)
	target.y = clamp(target.y, min_y, max_y)
	position = target


func show_sidebar(node: Node, viewport_rect: Rect2, ribbon_h: float) -> void:
	if node == null:
		hide()
		return
	_current_node = node
	var width: float = clamp(viewport_rect.size.x * 0.35, 360.0, 640.0)
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	size = Vector2(width, viewport_rect.size.y - ribbon_h)
	position = Vector2(viewport_rect.size.x - width, ribbon_h)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = true
	z_index = 1000
	_populate(node)


func _populate(node: Node) -> void:
	_current_node = node
	var pos := Vector2.ZERO
	var rot := 0.0
	var scl := Vector2.ONE
	if node is Node2D:
		var n := node as Node2D
		pos = n.global_position
		rot = n.global_rotation
		scl = n.global_scale
	else:
		var collider := _find_collider(node)
		if collider:
			var xf := collider.get_global_transform()
			pos = xf.origin
			rot = xf.get_rotation()
			scl = Vector2(xf.x.length(), xf.y.length())
	if _pos_x:
		_pos_x.text = "%.2f" % pos.x
	if _pos_y:
		_pos_y.text = "%.2f" % pos.y
	if _rot_deg:
		_rot_deg.text = "%.2f" % rad_to_deg(rot)
	if _scale_x:
		_scale_x.text = "%.2f" % scl.x
	if _scale_y:
		_scale_y.text = "%.2f" % scl.y

	var data_id := _extract_data_id(node)
	var data_cat := _infer_data_category(node)
	# Remap legacy deco IDs into Scenery
	var upper_id := data_id.to_upper()
	if upper_id.begins_with("ACTOR_DECOSTATIC"):
		data_id = "SCENERY_DecoStatic"
		if "data_id" in node:
			node.set("data_id", data_id)
		else:
			node.set_meta("data_id", data_id)
	if upper_id.begins_with("ACTOR_DECO") and not upper_id.begins_with("ACTOR_DECOSTATIC"):
		data_id = "SCENERY_Deco"
		if "data_id" in node:
			node.set("data_id", data_id)
		else:
			node.set_meta("data_id", data_id)
	var data_res: Resource = null
	var type_options: Array = []
	if data_id != "" and data_cat == "":
		data_cat = _infer_category_from_id(data_id)
	if data_id != "" and data_cat != "":
		var reg = _get_registry()
		if reg:
			if reg.has_method("get_resource_for_category"):
				data_res = reg.get_resource_for_category(data_cat, data_id)
			if reg.has_method("get_ids"):
				type_options = reg.get_ids(data_cat)
		# Fallback defaults if registry missing or empty
		if type_options.is_empty() and data_cat == "Actor":
			type_options = ["BaseActor", "BaseActorPlayer", "BaseHostileActor", "BaseNPC"]
		if type_options.is_empty():
			type_options = [data_id]

	if _data_id:
		_data_id.text = "Data Id: " + (data_id if data_id != "" else _read_prop(node, "id", ""))
	_fill_type_options(type_options, data_id)
	# instance overrides (metadata-backed)
	if _inst_tags:
		var mtags := _read_meta(node, "instance_tags", "")
		if mtags == "" and "tags" in node:
			mtags = _read_prop(node, "tags", "")
		_inst_tags.text = mtags
	if _inst_sprite:
		_inst_sprite.text = _read_meta(node, "instance_sprite_override", "")
	if _inst_collision_mask:
		var mcol := _read_meta(node, "instance_collision_mask", "")
		if mcol == "" and "collision_mask" in node:
			mcol = _read_prop(node, "collision_mask", "")
		_inst_collision_mask.text = mcol
	if _inst_no_proj:
		_inst_no_proj.button_pressed = bool(node.get_meta("instance_no_projectile", false))
	if _inst_layers_label:
		_inst_layers_label.text = _format_layer_names()
		_inst_layers_label.visible = _inst_layers_label.text.strip_edges() != ""
	# no static data info label anymore
	_build_dynamic_sections(node, data_id, data_cat, data_res)
	_update_teleporter_fields(node)


func _get_screen_position(node: Node, viewport_rect: Rect2) -> Vector2:
	if node is CanvasItem:
		var ci := node as CanvasItem
		return ci.get_global_transform_with_canvas().origin
	return viewport_rect.size * 0.5


func _find_collider(node: Node) -> CollisionShape2D:
	if node is CollisionShape2D:
		if node.name.begins_with("Editor") or node.is_in_group("editor_only") or node.is_in_group("editor_selector"):
			return null
		return node
	for child in node.get_children():
		var cs := _find_collider(child)
		if cs:
			return cs
	return null


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
	var id_hint := ""
	if node.has_meta("data_id"):
		var mv = node.get_meta("data_id")
		if mv is String:
			id_hint = mv
	if "data_id" in node:
		var dv = node.get("data_id")
		if dv is String:
			id_hint = dv
	if id_hint != "":
		var cat := _infer_category_from_id(id_hint)
		if cat != "":
			return cat
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


func _fill_type_options(options: Array, current_id: String) -> void:
	if _data_type == null:
		return
	_data_type.clear()
	# Ensure current id appears first if provided
	if current_id != "":
		_data_type.add_item(current_id)
	# Add the rest, skipping duplicates
	for id in options:
		if not (id is String):
			continue
		var exists := false
		for i in range(_data_type.item_count):
			if _data_type.get_item_text(i) == id:
				exists = true
				break
		if exists:
			continue
		_data_type.add_item(id)
	if current_id != "":
		_data_type.select(0)
	elif _data_type.item_count > 0:
		_data_type.select(0)


func _on_type_selected(index: int) -> void:
	if _current_node == null or _data_type == null:
		return
	if index < 0 or index >= _data_type.item_count:
		return
	var id := _data_type.get_item_text(index)
	print("[Inspector] type selected ->", id)
	if "data_id" in _current_node:
		_current_node.set("data_id", id)
	elif "id" in _current_node:
		_current_node.set("id", id)
	else:
		_current_node.set_meta("data_id", id)
	var mgr := get_tree().root.get_node_or_null("EditorManager")
	print("[Inspector] manager found:", mgr != null, "cat:", _infer_category_from_id(id))
	if mgr and mgr.has_method("_sync_data_panel"):
		mgr.call("_sync_data_panel", _current_node)
	var cat := _infer_category_from_id(id)
	if mgr:
		if cat == "Actor" and mgr.has_method("_apply_actor_data_to_node"):
			mgr.call_deferred("_apply_actor_data_to_node", _current_node)
		elif mgr.has_method("_apply_data_to_node"):
			mgr.call_deferred("_apply_data_to_node", _current_node)
	_populate(_current_node)


func _apply_transform(which: String) -> void:
	if _current_node == null:
		return
	if not (_current_node is Node2D):
		return
	var n := _current_node as Node2D
	match which:
		"pos":
			if _pos_x and _pos_x.text != "":
				var px := float(_pos_x.text)
				n.position.x = px
			if _pos_y and _pos_y.text != "":
				var py := float(_pos_y.text)
				n.position.y = py
		"rot":
			if _rot_deg and _rot_deg.text != "":
				var r := deg_to_rad(float(_rot_deg.text))
				n.rotation = r
		"scale":
			if _scale_x and _scale_x.text != "":
				var sx := float(_scale_x.text)
				n.scale.x = sx
			if _scale_y and _scale_y.text != "":
				var sy := float(_scale_y.text)
				n.scale.y = sy
	# keep collider in sync so highlights follow
	var collider := _find_collider(n)
	if collider:
		collider.position = Vector2.ZERO
		collider.rotation = 0.0
		collider.scale = Vector2.ONE
	if n.has_method("reset_base_position"):
		n.reset_base_position()


func _read_prop(node: Node, name: String, default_val: Variant) -> String:
	if name in node:
		var v = node.get(name)
		return str(v)
	return str(default_val)


func _read_meta(node: Node, key: String, default_val: Variant) -> String:
	if node.has_meta(key):
		var v = node.get_meta(key)
		return str(v)
	return str(default_val)


func _ensure_data_tab() -> void:
	if _tabs == null:
		return
	var tab := _tabs.get_node_or_null("Data")
	if tab == null:
		tab = VBoxContainer.new()
		tab.name = "Data"
		_tabs.add_child(tab)
		_tabs.set_tab_title(_tabs.get_tab_count() - 1, "Data")
	# Nested tab container for data subtabs
	_data_subtabs = tab.get_node_or_null("DataSubTabs") as TabContainer
	if _data_subtabs == null:
		return
	if _data_subtabs and not _data_subtab_connected:
		_data_subtabs.tab_changed.connect(_on_data_subtab_changed)
		_data_subtab_connected = true
	_template_tab = _data_subtabs.get_node_or_null("TemplateTab") as VBoxContainer
	_instance_tab = _data_subtabs.get_node_or_null("InstanceTab") as VBoxContainer
	if _template_tab == null or _instance_tab == null:
		return
	# Ensure a dedicated content container for template fields
	_template_content = _template_tab.get_node_or_null("TemplateContent") as VBoxContainer
	if _template_content == null:
		_template_content = VBoxContainer.new()
		_template_content.name = "TemplateContent"
		_template_content.add_theme_constant_override("separation", 6)
		_template_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_template_tab.add_child(_template_content)
	# Add a reset-overrides button if missing
	if _instance_tab and _instance_tab.get_node_or_null("ResetOverrides") == null:
		var reset_btn := Button.new()
		reset_btn.name = "ResetOverrides"
		reset_btn.text = "Reset Overrides"
		reset_btn.tooltip_text = "Clear all instance overrides and revert to template"
		reset_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		reset_btn.pressed.connect(_reset_instance_overrides)
		_instance_tab.add_child(reset_btn)
	var dyn := _template_tab.get_node_or_null("DynamicSections") as VBoxContainer
	if dyn == null:
		dyn = VBoxContainer.new()
		dyn.name = "DynamicSections"
		dyn.visible = true
		dyn.add_theme_constant_override("separation", 8)
		_template_tab.add_child(dyn)
	_setup_teleporter_controls()


func _build_data_debug_text(node: Node, data_id: String, data_cat: String, data_res: Resource) -> String:
	var lines: Array[String] = []
	lines.append("[b]Node:[/b] %s" % node.name)
	lines.append("[b]Category:[/b] %s" % data_cat)
	lines.append("[b]Data Id:[/b] %s" % data_id)
	if data_res:
		lines.append("[b]%s Fields[/b]" % data_cat)
		for prop in data_res.get_property_list():
			var n: String = prop.name
			if n == "resource_name" or n == "resource_path":
				continue
			var v = data_res.get(n)
			lines.append("  %s: %s" % [n, str(v)])
	if data_cat == "Actor" and data_res and "movement_id" in data_res:
		var mv_id: String = data_res.movement_id
		lines.append("[b]Movement Id:[/b] %s" % mv_id)
		var reg = _get_registry()
		if reg and mv_id != "" and reg.has_method("get_resource_for_category"):
			var mv_res = reg.get_resource_for_category("Movement", mv_id)
			if mv_res:
				lines.append("[b]Movement Fields[/b]")
				for prop in mv_res.get_property_list():
					var n2: String = prop.name
					if n2 == "resource_name" or n2 == "resource_path":
						continue
					var v2 = mv_res.get(n2)
					lines.append("  %s: %s" % [n2, str(v2)])
	return "\n".join(lines)


func _add_line_row(parent: VBoxContainer, label_text: String) -> LineEdit:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(120, 0)
	var le := LineEdit.new()
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	row.add_child(le)
	parent.add_child(row)
	return le


func _add_bool_row(parent: VBoxContainer, label_text: String) -> CheckBox:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(120, 0)
	var cb := CheckBox.new()
	row.add_child(lbl)
	row.add_child(cb)
	parent.add_child(row)
	return cb


func _add_option_row(parent: VBoxContainer, label_text: String, options: Array) -> OptionButton:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(120, 0)
	var ob := OptionButton.new()
	for i in range(options.size()):
		ob.add_item(options[i], i)
	row.add_child(lbl)
	row.add_child(ob)
	parent.add_child(row)
	return ob


func _setup_teleporter_controls() -> void:
	if _tele_fields.size() > 0:
		return
	if _tabs == null:
		return
	var parent := _instance_tab
	if parent == null:
		parent = _tabs.get_node_or_null("Data")
	if parent == null:
		return
	var box := parent.get_node_or_null("TeleporterBox") as VBoxContainer
	if box == null:
		box = VBoxContainer.new()
		box.name = "TeleporterBox"
		box.visible = false
		box.add_theme_constant_override("separation", 6)
		parent.add_child(box)
	_tele_fields["box"] = box
	_tele_fields["exit_only"] = _add_bool_row(box, "Exit Only")
	_tele_fields["activation_mode"] = _add_option_row(box, "Activation", ["collision", "input"])
	_tele_fields["activation_action"] = _add_line_row(box, "Action")
	_tele_fields["destination_scene"] = _add_line_row(box, "Destination Scene")
	_tele_fields["dropoff_mode"] = _add_option_row(box, "Dropoff Mode", ["teleporter", "left_edge", "right_edge"])
	_tele_fields["dropoff_target"] = _add_line_row(box, "Dropoff Target")
	_tele_fields["dropoff_margin"] = _add_line_row(box, "Dropoff Margin")
	_tele_apply = Button.new()
	_tele_apply.text = "Apply Teleporter"
	_tele_apply.theme = box.theme
	box.add_child(_tele_apply)
	_tele_apply.pressed.connect(_apply_teleporter)


func _build_dynamic_sections(node: Node, data_id: String, data_cat: String, data_res: Resource) -> void:
	if _data_subtabs == null:
		return
	# clear previous category tabs (keep Template/Instance at indices 0/1)
	for i in range(_data_subtabs.get_child_count() - 1, -1, -1):
		if i >= 2:
			var c := _data_subtabs.get_child(i)
			_data_subtabs.remove_child(c)
			c.queue_free()
	_dynamic_sections.clear()
	var reg = _get_registry()
	var entries: Array = []
	if data_cat != "":
		entries.append({"cat": data_cat, "id": data_id, "res": data_res})
	if data_cat == "Actor" and data_res and "movement_id" in data_res:
		var mv_id := str(data_res.movement_id)
		if mv_id != "":
			var mv_res = reg.get_resource_for_category("Movement", mv_id) if reg else null
			entries.append({"cat": "Movement", "id": mv_id, "res": mv_res})
	if data_cat == "Teleporter":
		# already handled via teleporter panel
		pass
	for entry in entries:
		var cat_name: String = entry["cat"]
		var cid: String = entry["id"]
		var cres: Resource = entry["res"]
		if cat_name == "" or cid == "" or cres == null:
			continue
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		box.name = "%sSection" % cat_name
		var header := Label.new()
		header.text = "%s: %s" % [cat_name, cid]
		header.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		box.add_child(header)
		var fields: Dictionary = {}
		if DYN_FIELDS.has(cat_name):
			for desc in DYN_FIELDS[cat_name]:
				var key: String = desc.get("key", "")
				var label_txt: String = desc.get("label", key)
				var ftype: String = desc.get("type", "string")
				var is_resource: bool = bool(desc.get("resource", false))
				if key == "":
					continue
				var cur_val = null
				if _current_node and _current_node.has_meta("instance_overrides"):
					var ov = _current_node.get_meta("instance_overrides")
					if ov is Dictionary and ov.has(key):
						cur_val = ov[key]
				if cur_val == null and _res_has_property(cres, key):
					cur_val = cres.get(key)
					if cur_val is Resource:
						cur_val = (cur_val as Resource).resource_path
				if cur_val == null and _current_node and key in _current_node:
					cur_val = _current_node.get(key)
				var ctrl: Control = null
				if ftype == "bool":
					var cb := CheckBox.new()
					cb.text = label_txt
					cb.button_pressed = bool(cur_val)
					cb.mouse_filter = Control.MOUSE_FILTER_STOP
					cb.toggled.connect(func(pressed: bool):
						_on_dynamic_field_changed(cat_name, key, pressed, ftype)
					)
					ctrl = cb
				elif is_resource and ftype == "string":
					var row := HBoxContainer.new()
					row.add_theme_constant_override("separation", 6)
					row.mouse_filter = Control.MOUSE_FILTER_STOP
					var lbl := Label.new()
					lbl.text = label_txt
					lbl.custom_minimum_size = Vector2(120, 0)
					var le := LineEdit.new()
					le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					le.mouse_filter = Control.MOUSE_FILTER_STOP
					if cur_val != null:
						le.text = str(cur_val)
					var browse := Button.new()
					browse.text = "Browse"
					browse.tooltip_text = "Select resource"
					browse.mouse_filter = Control.MOUSE_FILTER_STOP
					var captured_cat := cat_name
					var captured_key := key
					browse.pressed.connect(func():
						_browse_resource(le, captured_cat, captured_key)
					)
					le.text_submitted.connect(func(t: String):
						_on_dynamic_field_changed(cat_name, key, t, ftype)
					)
					le.focus_exited.connect(func():
						_on_dynamic_field_changed(cat_name, key, le.text, ftype)
					)
					row.add_child(lbl)
					row.add_child(le)
					row.add_child(browse)
					ctrl = row
				else:
					var row := HBoxContainer.new()
					row.add_theme_constant_override("separation", 6)
					row.mouse_filter = Control.MOUSE_FILTER_STOP
					var lbl := Label.new()
					lbl.text = label_txt
					lbl.custom_minimum_size = Vector2(120, 0)
					var le := LineEdit.new()
					le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					le.mouse_filter = Control.MOUSE_FILTER_STOP
					if cur_val != null:
						le.text = str(cur_val)
					le.text_submitted.connect(func(t: String):
						_on_dynamic_field_changed(cat_name, key, t, ftype)
					)
					le.focus_exited.connect(func():
						_on_dynamic_field_changed(cat_name, key, le.text, ftype)
					)
					row.add_child(lbl)
					row.add_child(le)
					ctrl = row
				if ctrl:
					box.add_child(ctrl)
				fields[key] = ctrl
		_data_subtabs.add_child(box)
		_data_subtabs.set_tab_title(_data_subtabs.get_tab_count() - 1, cat_name)
		_dynamic_sections[cat_name] = {"box": box, "fields": fields}
	if _dynamic_sections.size() > 0 and _base_width > 0.0:
		size.x = max(_base_width * 1.5, size.x)
	else:
		size.x = max(_base_width, size.x)
	var target_idx: int = int(clamp(_inspector_state.get("sub", _last_subtab), 0, max(0, _data_subtabs.get_tab_count() - 1)))
	_data_subtabs.current_tab = target_idx
	_shift_subtab(0)
	_build_template_fields(entries)
	_refresh_module_visibility()


func _on_dynamic_field_changed(cat_name: String, key: String, raw_val, ftype: String) -> void:
	if _current_node == null:
		return
	var overrides: Dictionary = {}
	if _current_node.has_meta("instance_overrides"):
		var ov = _current_node.get_meta("instance_overrides")
		if ov is Dictionary:
			overrides = ov.duplicate()
	var conv = _convert_dynamic_value(raw_val, ftype)
	overrides[key] = conv
	_current_node.set_meta("instance_overrides", overrides)
	if key == "movement_id" and "movement_id" in _current_node:
		_current_node.set("movement_id", str(conv))
	if _current_node.has_method("set") and key in _current_node:
		_current_node.set(key, conv)
	# If we changed a resource path, try to apply it to visuals
	if key == "sprite":
		_try_apply_sprite(_current_node, str(conv))
	var mgr := get_tree().root.get_node_or_null("EditorManager")
	if mgr and mgr.has_method("_apply_instance_overrides"):
		mgr.call("_apply_instance_overrides", _current_node)
		if mgr.has_method("_apply_data_to_node"):
			mgr.call_deferred("_apply_data_to_node", _current_node)
	# Update module-dependent visibility
	if cat_name == "Movement" and key.begins_with("enable_"):
		_refresh_module_visibility()
	# avoid re-populating immediately; prevents clobbering edits


func _shift_subtab(delta: int) -> void:
	if _data_subtabs == null:
		return
	var count := _data_subtabs.get_tab_count()
	if count <= 1:
		return
	var idx: int = int(clamp(_data_subtabs.current_tab + delta, 0, count - 1))
	_data_subtabs.current_tab = idx
	_last_subtab = idx
	_inspector_state["sub"] = idx
	if _subtab_prev:
		_subtab_prev.disabled = idx <= 0
	if _subtab_next:
		_subtab_next.disabled = idx >= count - 1


func _refresh_module_visibility() -> void:
	if not _dynamic_sections.has("Movement"):
		return
	var fields: Dictionary = _dynamic_sections["Movement"].get("fields", {})
	for flag_key in _module_keys.keys():
		var on: bool = false
		if fields.has(flag_key) and fields[flag_key] is CheckBox:
			on = (fields[flag_key] as CheckBox).button_pressed
		for k in _module_keys[flag_key]:
			if fields.has(k) and fields[k] is Control:
				(fields[k] as Control).visible = on


func _on_data_subtab_changed(i: int) -> void:
	_last_subtab = i
	_inspector_state["sub"] = i


func _reset_instance_overrides() -> void:
	if _current_node == null:
		return
	if _current_node.has_meta("instance_overrides"):
		_current_node.remove_meta("instance_overrides")
	# legacy metas
	var legacy := ["instance_tags", "instance_sprite_override", "instance_collision_mask", "instance_no_projectile"]
	for m in legacy:
		if _current_node.has_meta(m):
			_current_node.remove_meta(m)
	var mgr := get_tree().root.get_node_or_null("EditorManager")
	if mgr:
		if mgr.has_method("_apply_data_to_node"):
			mgr.call_deferred("_apply_data_to_node", _current_node)
		elif mgr.has_method("_apply_actor_data_to_node"):
			mgr.call_deferred("_apply_actor_data_to_node", _current_node)
	_populate(_current_node)


func _convert_dynamic_value(raw_val, ftype: String):
	match ftype:
		"bool":
			if raw_val is bool:
				return raw_val
			return str(raw_val).to_lower() in ["1", "true", "yes", "on"]
		"int":
			return int(raw_val)
		"float":
			return float(raw_val)
		"color":
			return Color.from_string(str(raw_val), Color.WHITE)
		_:
			return str(raw_val)


func _build_template_fields(entries: Array) -> void:
	# Clear previous template fields (but keep static widgets like DataInfo)
	if _template_content:
		for child in _template_content.get_children():
			_template_content.remove_child(child)
			child.queue_free()
	_template_fields.clear()
	if _template_tab == null:
		return
	if _template_content == null:
		_template_content = _template_tab.get_node_or_null("TemplateContent") as VBoxContainer
		if _template_content == null:
			_template_content = VBoxContainer.new()
			_template_content.name = "TemplateContent"
			_template_content.add_theme_constant_override("separation", 6)
			_template_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_template_tab.add_child(_template_content)
	if entries.is_empty():
		return
	for entry_raw in entries:
		var entry: Dictionary = entry_raw as Dictionary
		var cat_name: String = entry.get("cat", "")
		var cres: Resource = entry.get("res", null)
		var cid: String = entry.get("id", "")
		if cat_name == "" or cres == null or cid == "":
			continue
		if not DYN_FIELDS.has(cat_name):
			continue
		var header := Label.new()
		header.text = "%s: %s" % [cat_name, cid]
		header.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		_template_content.add_child(header)
		var descs: Array = DYN_FIELDS[cat_name] as Array
		for desc_raw in descs:
			var desc: Dictionary = desc_raw as Dictionary
			var key: String = desc.get("key", "")
			var label_txt: String = desc.get("label", key)
			if key == "":
				continue
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			var lbl := Label.new()
			lbl.text = label_txt
			lbl.custom_minimum_size = Vector2(120, 0)
			var val := Label.new()
			var v = ""
			if _res_has_property(cres, key):
				var rv = cres.get(key)
				if rv is Resource:
					v = (rv as Resource).resource_path
				else:
					v = str(rv)
			val.text = v
			row.add_child(lbl)
			row.add_child(val)
			_template_content.add_child(row)
			_template_fields[key] = {"row": row, "label": val}


func _res_has_property(res: Resource, key: String) -> bool:
	if res == null:
		return false
	for prop in res.get_property_list():
		if prop.name == key:
			return true
	return false


func _apply_overrides() -> void:
	if _current_node == null:
		return
	var overrides: Dictionary = {}
	if _current_node.has_meta("instance_overrides"):
		var ov = _current_node.get_meta("instance_overrides")
		if ov is Dictionary:
			overrides = ov.duplicate()
	if _inst_tags:
		_current_node.set_meta("instance_tags", _inst_tags.text.strip_edges())
		overrides["tags"] = _inst_tags.text.strip_edges()
	if _inst_collision_mask and _inst_collision_mask.text.strip_edges() != "":
		_current_node.set_meta("instance_collision_mask", _inst_collision_mask.text.strip_edges())
		if "collision_mask" in _current_node:
			_current_node.set("collision_mask", int(_inst_collision_mask.text))
		overrides["collision_mask"] = int(_inst_collision_mask.text)
	if _inst_no_proj:
		_current_node.set_meta("instance_no_projectile", _inst_no_proj.button_pressed)
		overrides["no_projectile"] = _inst_no_proj.button_pressed
	if _inst_sprite and _inst_sprite.text.strip_edges() != "":
		_current_node.set_meta("instance_sprite_override", _inst_sprite.text.strip_edges())
		_try_apply_sprite(_current_node, _inst_sprite.text.strip_edges())
		overrides["sprite"] = _inst_sprite.text.strip_edges()
	else:
		if _current_node.has_meta("instance_sprite_override"):
			_current_node.remove_meta("instance_sprite_override")
			overrides.erase("sprite")
	overrides.erase("pos")
	overrides.erase("rot")
	overrides.erase("scale")
	if overrides.size() > 0:
		_current_node.set_meta("instance_overrides", overrides)
	elif _current_node.has_meta("instance_overrides"):
		_current_node.remove_meta("instance_overrides")
	var mgr := get_tree().root.get_node_or_null("EditorManager")
	if mgr and mgr.has_method("_apply_instance_overrides"):
		mgr.call("_apply_instance_overrides", _current_node)
	_populate(_current_node)


func _apply_teleporter() -> void:
	if _current_node == null:
		return
	if not ("exit_only" in _current_node):
		return
	var overrides: Dictionary = {}
	if _current_node.has_meta("instance_overrides"):
		var ov = _current_node.get_meta("instance_overrides")
		if ov is Dictionary:
			overrides = ov.duplicate()
	if _tele_fields.has("exit_only") and _tele_fields["exit_only"] is CheckBox:
		var exit_only_val := (_tele_fields["exit_only"] as CheckBox).button_pressed
		_current_node.exit_only = exit_only_val
		overrides["exit_only"] = exit_only_val
	if _tele_fields.has("activation_mode") and _tele_fields["activation_mode"] is OptionButton:
		var ob := _tele_fields["activation_mode"] as OptionButton
		var act := ob.get_item_text(ob.selected)
		_current_node.activation_mode = act
		overrides["activation_mode"] = act
	if _tele_fields.has("activation_action") and _tele_fields["activation_action"] is LineEdit:
		var act_action := (_tele_fields["activation_action"] as LineEdit).text.strip_edges()
		_current_node.activation_action = act_action
		overrides["activation_action"] = act_action
	if _tele_fields.has("destination_scene") and _tele_fields["destination_scene"] is LineEdit:
		var path := (_tele_fields["destination_scene"] as LineEdit).text.strip_edges()
		if path != "" and ResourceLoader.exists(path):
			var ps := ResourceLoader.load(path) as PackedScene
			_current_node.destination_scene = ps
			overrides["destination_scene"] = path
	if _tele_fields.has("dropoff_mode") and _tele_fields["dropoff_mode"] is OptionButton:
		var ob2 := _tele_fields["dropoff_mode"] as OptionButton
		var dom := ob2.get_item_text(ob2.selected)
		_current_node.dropoff_mode = dom
		overrides["dropoff_mode"] = dom
	if _tele_fields.has("dropoff_target") and _tele_fields["dropoff_target"] is LineEdit:
		var dt := (_tele_fields["dropoff_target"] as LineEdit).text.strip_edges()
		_current_node.dropoff_target = dt
		overrides["dropoff_target"] = dt
	if _tele_fields.has("dropoff_margin") and _tele_fields["dropoff_margin"] is LineEdit:
		var txt := (_tele_fields["dropoff_margin"] as LineEdit).text.strip_edges()
		if txt != "":
			_current_node.dropoff_margin = float(txt)
			overrides["dropoff_margin"] = float(txt)
	if overrides.size() > 0:
		_current_node.set_meta("instance_overrides", overrides)
	elif _current_node.has_meta("instance_overrides"):
		_current_node.remove_meta("instance_overrides")
	var mgr := get_tree().root.get_node_or_null("EditorManager")
	if mgr and mgr.has_method("_apply_instance_overrides"):
		mgr.call("_apply_instance_overrides", _current_node)
	_populate(_current_node)


func _is_teleporter_node(node: Node) -> bool:
	if node == null:
		return false
	if node is Teleporter2D:
		return true
	if node.is_in_group("teleporters"):
		return true
	# duck-type on properties
	return ("exit_only" in node) and ("dropoff_mode" in node) and ("activation_mode" in node)


func _update_teleporter_fields(node: Node) -> void:
	if not _tele_fields.has("box"):
		return
	var box := _tele_fields["box"] as VBoxContainer
	if box == null:
		return
	if not _is_teleporter_node(node):
		box.visible = false
		return
	box.visible = true
	if _tele_fields.has("exit_only") and _tele_fields["exit_only"] is CheckBox:
		var exit_val = _read_prop(node, "exit_only", false)
		var exit_bool := false
		if exit_val is bool:
			exit_bool = exit_val
		elif exit_val is String:
			exit_bool = exit_val.to_lower() in ["1", "true", "yes", "on"]
		else:
			exit_bool = bool(exit_val)
		(_tele_fields["exit_only"] as CheckBox).button_pressed = exit_bool
	if _tele_fields.has("activation_mode") and _tele_fields["activation_mode"] is OptionButton:
		var ob := _tele_fields["activation_mode"] as OptionButton
		var mode: String = str(_read_prop(node, "activation_mode", "collision"))
		for i in range(ob.item_count):
			if ob.get_item_text(i) == mode:
				ob.select(i)
				break
	if _tele_fields.has("activation_action") and _tele_fields["activation_action"] is LineEdit:
		(_tele_fields["activation_action"] as LineEdit).text = str(_read_prop(node, "activation_action", "interact"))
	if _tele_fields.has("destination_scene") and _tele_fields["destination_scene"] is LineEdit:
		var path := ""
		if "destination_scene" in node:
			var ps = node.get("destination_scene")
			if ps is PackedScene:
				path = ps.resource_path
		(_tele_fields["destination_scene"] as LineEdit).text = path
	if _tele_fields.has("dropoff_mode") and _tele_fields["dropoff_mode"] is OptionButton:
		var ob2 := _tele_fields["dropoff_mode"] as OptionButton
		var mode2: String = str(_read_prop(node, "dropoff_mode", "teleporter"))
		for i2 in range(ob2.item_count):
			if ob2.get_item_text(i2) == mode2:
				ob2.select(i2)
				break
	if _tele_fields.has("dropoff_target") and _tele_fields["dropoff_target"] is LineEdit:
		(_tele_fields["dropoff_target"] as LineEdit).text = str(_read_prop(node, "dropoff_target", ""))
	if _tele_fields.has("dropoff_margin") and _tele_fields["dropoff_margin"] is LineEdit:
		(_tele_fields["dropoff_margin"] as LineEdit).text = "%.2f" % float(_read_prop(node, "dropoff_margin", 0.0))


func _try_apply_sprite(node: Node, path: String) -> void:
	var tex := load(path)
	if tex == null:
		return
	# try common sprite locations
	if node is Sprite2D:
		(node as Sprite2D).texture = tex
		return
	var spr := node.get_node_or_null("SpriteRoot/Sprite2D")
	if spr and spr is Sprite2D:
		spr.texture = tex
		return
	for child in node.get_children():
		if child is Sprite2D:
			(child as Sprite2D).texture = tex
			return


func _browse_sprite() -> void:
	var fd := FileDialog.new()
	fd.access = FileDialog.ACCESS_RESOURCES
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.filters = PackedStringArray(["*.png,*.webp,*.tres ; Textures"])
	fd.file_selected.connect(func(p):
		if _inst_sprite:
			_inst_sprite.text = p
		_apply_overrides()
	)
	add_child(fd)
	fd.popup_centered()


func _browse_resource(target: LineEdit, cat_name: String, key: String) -> void:
	var fd := FileDialog.new()
	fd.access = FileDialog.ACCESS_RESOURCES
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.filters = PackedStringArray(["*.tscn,*.tres,*.png,*.webp ; Resources"])
	fd.file_selected.connect(func(p):
		if target:
			target.text = p
		_on_dynamic_field_changed(cat_name, key, p, "string")
	)
	add_child(fd)
	fd.popup_centered()


func _open_in_data_panel() -> void:
	if _current_node == null:
		return
	var mgr := get_tree().root.get_node_or_null("EditorManager")
	if mgr:
		if mgr.has_method("_sync_data_panel"):
			mgr.call("_sync_data_panel", _current_node)
		# Also show the data panel
		if mgr.has_method("_toggle_data_editor"):
			mgr.call("_toggle_data_editor")


func _schedule_transform(_unused: String = "") -> void:
	_apply_transform("pos")
	_apply_transform("rot")
	_apply_transform("scale")


func _apply_all_transforms() -> void:
	_apply_transform("pos")
	_apply_transform("rot")
	_apply_transform("scale")


func _on_transform_submitted(_text: String) -> void:
	_apply_all_transforms()


func _format_layer_names() -> String:
	var parts: Array[String] = []
	for i in range(1, 21):
		var name_key: String = "layer_names/2d_physics/layer_%d" % i
		var label_val = ProjectSettings.get_setting(name_key, "")
		if label_val is String:
			var label_str: String = label_val
			if label_str != "":
				parts.append("%d:%s" % [i, label_str])
	if parts.is_empty():
		return "Layers: (unnamed)"
	return "Layers: " + ", ".join(parts)


func _get_registry():
	if Engine.has_singleton("DataRegistry"):
		return Engine.get_singleton("DataRegistry")
	if has_node("/root/DataRegistry"):
		return get_node("/root/DataRegistry")
	return null


func _infer_category_from_id(data_id: String) -> String:
	var upper := data_id.to_upper()
	if upper.begins_with("ACTOR_"):
		return "Actor"
	if upper.begins_with("SCENERY_") or upper.begins_with("PLATFORM_") or upper.begins_with("ACTOR_DECO"):
		return "Scenery"
	if upper.begins_with("SPAWNER_"):
		return "Spawner"
	if upper.begins_with("ITEM_"):
		return "Item"
	if upper.begins_with("PROJECTILE_"):
		return "Projectile"
	if upper.begins_with("TRAP_"):
		return "Trap"
	if upper.begins_with("AIPROFILE_"):
		return "AIProfile"
	if upper.begins_with("FACTION_"):
		return "Faction"
	if upper.begins_with("LOOTTABLE_"):
		return "LootTable"
	if upper.begins_with("STATS_"):
		return "Stats"
	return ""
