extends Panel

const MARGIN := 10.0

@onready var _tabs: TabContainer = $Tabs
@onready var _transform_pos: Label = $Tabs/Transform/VBox/Pos
@onready var _transform_rot: Label = $Tabs/Transform/VBox/Rot
@onready var _transform_scale: Label = $Tabs/Transform/VBox/Scale

@onready var _data_id: Label = $Tabs/Data/VBox/DataId
@onready var _data_type: OptionButton = $Tabs/Data/VBox/TypeRow/DataType
@onready var _data_input: Label = $Tabs/Data/VBox/InputSource
@onready var _data_player: Label = $Tabs/Data/VBox/PlayerNum
@onready var _data_aggr: Label = $Tabs/Data/VBox/Aggressiveness
@onready var _data_behavior: Label = $Tabs/Data/VBox/BehaviorProfile
@onready var _data_stats: Label = $Tabs/Data/VBox/StatsId

@onready var _collision_layers: Label = $Tabs/Collision/VBox/Layers
@onready var _collision_mask: Label = $Tabs/Collision/VBox/Mask

@onready var _ai_profile: Label = $Tabs/AI/VBox/AIProfile
@onready var _ai_state: Label = $Tabs/AI/VBox/AIState

var _current_node: Node = null

func _ready() -> void:
	if _data_type:
		_data_type.item_selected.connect(_on_type_selected)

func show_for(node: Node, viewport_rect: Rect2, ribbon_h: float, sidebar_w: float) -> void:
	if node == null:
		hide()
		return
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_current_node = node
	_populate(node)
	var target := _get_screen_position(node, viewport_rect)
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
	var width: float = min(320.0, viewport_rect.size.x / 6.0)
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
	var collider := _find_collider(node)
	var xform_pos := Vector2.ZERO
	var xform_rot := 0.0
	var xform_scale := Vector2.ONE
	if collider:
		var xf := collider.get_global_transform()
		xform_pos = xf.origin
		xform_rot = xf.get_rotation()
		xform_scale = Vector2(xf.x.length(), xf.y.length())
	elif node is Node2D:
		var n := node as Node2D
		xform_pos = n.global_position
		xform_rot = n.global_rotation
		xform_scale = n.global_scale

	_transform_pos.text = "Pos: n/a"
	_transform_rot.text = "Rot: n/a"
	_transform_scale.text = "Scale: n/a"
	if collider or node is Node2D:
		_transform_pos.text = "Pos: %.2f, %.2f" % [xform_pos.x, xform_pos.y]
		_transform_rot.text = "Rot: %.2f" % rad_to_deg(xform_rot)
		_transform_scale.text = "Scale: %.2f, %.2f" % [xform_scale.x, xform_scale.y]

	var data_id := _extract_data_id(node)
	var data_cat := _infer_data_category(node)
	var data_res: Resource = null
	var type_options: Array = []
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

	_data_id.text = "Data Id: " + (data_id if data_id != "" else _read_prop(node, "id", ""))
	_fill_type_options(type_options, data_id)
	_data_input.text = "Input: " + _read_prop(node, "input_source", data_res.input_source if data_res and "input_source" in data_res else "")
	_data_player.text = "Player #: " + _read_prop(node, "player_number", data_res.player_number if data_res and "player_number" in data_res else "")
	_data_aggr.text = "Aggressiveness: " + _read_prop(node, "aggressiveness", data_res.aggressiveness if data_res and "aggressiveness" in data_res else "")
	_data_behavior.text = "Behavior: " + _read_prop(node, "behavior_profile_id", data_res.behavior_profile_id if data_res and "behavior_profile_id" in data_res else "")
	_data_stats.text = "Stats: " + _read_prop(node, "stats_id", "")

	_collision_layers.text = "Layers: " + _read_prop(node, "collision_layer", "")
	_collision_mask.text = "Mask: " + _read_prop(node, "collision_mask", "")

	_ai_profile.text = "AI Profile: " + _read_prop(node, "behavior_profile_id", "")
	_ai_state.text = "AI State: " + _read_prop(node, "ai_state_init", "")


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
	if "data_id" in _current_node:
		_current_node.set("data_id", id)
	elif "id" in _current_node:
		_current_node.set("id", id)
	else:
		_current_node.set_meta("data_id", id)
	var mgr := get_tree().root.get_node_or_null("EditorManager")
	if mgr and mgr.has_method("_sync_data_panel"):
		mgr.call("_sync_data_panel", _current_node)
	if mgr and mgr.has_method("_apply_actor_data_to_node"):
		mgr.call("_apply_actor_data_to_node", _current_node)


func _read_prop(node: Node, name: String, default_val: Variant) -> String:
	if name in node:
		var v = node.get(name)
		return str(v)
	return str(default_val)


func _get_registry():
	if Engine.has_singleton("DataRegistry"):
		return Engine.get_singleton("DataRegistry")
	if has_node("/root/DataRegistry"):
		return get_node("/root/DataRegistry")
	return null
