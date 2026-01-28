@tool
extends Node

@export var enabled: bool = true
@export var actor_path: NodePath = NodePath("..")
@export var label_path: NodePath = NodePath("CanvasLayer/Panel/Label")
@export var update_interval: float = 0.2
@export var hotkey_enabled: bool = true
@export var toggle_keycode: int = 145
@export var toggle_action: StringName = &"debug_toggle"
@export var use_action_toggle: bool = true
@export var validate_tracks: bool = true
@export var validation_interval: float = 1.0
@export var show_animation_list: bool = false
@export var max_animation_list: int = 6
@export var show_movement: bool = true
@export var show_ids: bool = true
@export var show_actor_state: bool = true
@export var show_ctx: bool = true
@export var show_model_data: bool = true

var _actor: Node
var _label: Label
var _canvas: CanvasLayer
var _elapsed := 0.0
var _validate_elapsed := 0.0
var _hotkey_down := false
var _last_validation := {
	"tracks": 0,
	"missing_nodes": 0,
	"missing_bones": 0,
	"anim": "",
}


func _ready() -> void:
	_resolve_nodes()
	_set_overlay_visible(enabled)


func _unhandled_input(event: InputEvent) -> void:
	if not hotkey_enabled:
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			var code := key_event.keycode
			if code == toggle_keycode and toggle_keycode > 0:
				enabled = not enabled
				_set_overlay_visible(enabled)


func _process(delta: float) -> void:
	_check_hotkey()
	if not enabled:
		_set_overlay_visible(false)
		return
	_elapsed += delta
	_validate_elapsed += delta
	if _elapsed < update_interval:
		return
	_elapsed = 0.0
	_resolve_nodes()
	if _label == null:
		return
	_set_overlay_visible(true)
	var actor := _actor
	var lines: Array[String] = []
	lines.append("Anim Debug")
	lines.append("actor: %s" % _safe_node_path(actor))
	if actor == null:
		_label.text = "\n".join(lines)
		return
	var fsm := _find_fsm(actor)
	if fsm:
		var current_state := _get_prop_string(fsm, "current_state")
		var previous_state := _get_prop_string(fsm, "previous_state")
		lines.append("fsm: %s (prev %s)" % [current_state, previous_state])
	if show_movement:
		var pos := Vector3.ZERO
		var vel := Vector3.ZERO
		var on_floor := false
		if actor is CharacterBody3D:
			var body := actor as CharacterBody3D
			pos = body.global_transform.origin
			vel = body.velocity
			on_floor = body.is_on_floor()
		elif actor is Node3D:
			pos = (actor as Node3D).global_transform.origin
		if "velocity" in actor:
			var v = actor.get("velocity")
			if v is Vector3:
				vel = v
		if actor.has_method("is_on_floor"):
			on_floor = actor.is_on_floor()
		lines.append("pos: (%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z])
		lines.append("vel: (%.2f, %.2f, %.2f)" % [vel.x, vel.y, vel.z])
		lines.append("on_floor: %s" % str(on_floor))
	if show_actor_state:
		var jumping := _get_prop_bool(actor, "jumping")
		var falling := _get_prop_bool(actor, "falling")
		var in_air := _get_prop_bool(actor, "in_air")
		var jump_count := _get_prop_int(actor, "jump_count")
		var coyote := _get_prop_float(actor, "coyote_timer")
		var dash := _get_prop_bool(actor, "dashing")
		var roll := _get_prop_bool(actor, "roll_active")
		var crouch := _get_prop_bool(actor, "crouching")
		var sneak := _get_prop_bool(actor, "sneaking")
		lines.append("state: jump=%s fall=%s air=%s jumps=%d coyote=%.2f" % [str(jumping), str(falling), str(in_air), jump_count, coyote])
		lines.append("state: dash=%s roll=%s crouch=%s sneak=%s" % [str(dash), str(roll), str(crouch), str(sneak)])
	if show_ctx:
		var ctx := _get_controller_context(actor)
		if ctx:
			var move_input := _get_prop_vector2(ctx, "move_input")
			var running := _get_prop_bool(ctx, "is_running")
			var ctx_floor := _get_prop_bool(ctx, "on_floor")
			var ctx_dash := _get_prop_bool(ctx, "is_dashing")
			var ctx_roll := _get_prop_bool(ctx, "is_rolling")
			var ctx_crouch := _get_prop_bool(ctx, "is_crouching")
			var ctx_sneak := _get_prop_bool(ctx, "is_sneaking")
			lines.append("ctx: move=(%.2f, %.2f) run=%s floor=%s" % [move_input.x, move_input.y, str(running), str(ctx_floor)])
			lines.append("ctx: dash=%s roll=%s crouch=%s sneak=%s" % [str(ctx_dash), str(ctx_roll), str(ctx_crouch), str(ctx_sneak)])
	var anim_driver := _find_anim_driver(actor)
	lines.append("anim_driver: %s" % _safe_node_path(anim_driver))
	var target_root_path := _get_prop_nodepath(anim_driver, "target_root_path")
	var target_root := _resolve_path_from(anim_driver, target_root_path)
	lines.append("target_root: %s -> %s" % [String(target_root_path), _safe_node_path(target_root)])
	var anim_player_path := _get_prop_nodepath(anim_driver, "animation_player_path")
	var anim_player := _resolve_anim_player(anim_driver, target_root, anim_player_path)
	lines.append("anim_player_path: %s -> %s" % [String(anim_player_path), _safe_node_path(anim_player)])
	var anim_tree_path := _get_prop_nodepath(anim_driver, "animation_tree_path")
	var anim_tree := _resolve_anim_tree(anim_driver, target_root, anim_tree_path)
	lines.append("anim_tree_path: %s -> %s" % [String(anim_tree_path), _safe_node_path(anim_tree)])
	var library_name := _get_prop_string(anim_driver, "animation_library_name")
	lines.append("library_name: %s" % library_name)
	var last_state := _get_prop_string(anim_driver, "_last_state")
	if last_state != "":
		lines.append("last_state: %s" % last_state)
	if anim_player:
		var root_node := anim_player.root_node
		var root_resolved := anim_player.get_node_or_null(root_node) if root_node != NodePath("") else null
		lines.append("anim_current: %s (playing %s)" % [anim_player.current_animation, str(anim_player.is_playing())])
		lines.append("anim_root_node: %s -> %s" % [String(root_node), _safe_node_path(root_resolved)])
		var lib_list := []
		if anim_player.has_method("get_animation_library_list"):
			lib_list = anim_player.get_animation_library_list()
		lines.append("anim_libs: %s" % str(lib_list))
		lines.append("anim_count: %d" % anim_player.get_animation_list().size())
		if show_animation_list:
			var anims := anim_player.get_animation_list()
			var sample: Array[String] = []
			for i in range(min(max_animation_list, anims.size())):
				sample.append(anims[i])
			lines.append("anim_sample: %s" % ", ".join(sample))
		if validate_tracks and _validate_elapsed >= validation_interval:
			_validate_elapsed = 0.0
			_last_validation = _validate_current_animation(anim_player)
	if validate_tracks and _last_validation["anim"] != "":
		lines.append("tracks: %d missing_nodes: %d missing_bones: %d" % [
			int(_last_validation["tracks"]),
			int(_last_validation["missing_nodes"]),
			int(_last_validation["missing_bones"]),
		])
	if show_ids:
		var movement_id := _get_prop_string(actor, "movement_id")
		var camera_id := _get_prop_string(actor, "camera_id")
		var model_id := _get_prop_string(actor, "model_id")
		lines.append("ids: move=%s camera=%s model=%s" % [movement_id, camera_id, model_id])
		lines.append("res: move=%s camera=%s model=%s" % [
			_get_resource_id(actor, "movement_data"),
			_get_resource_id(actor, "camera_data"),
			_get_resource_id(actor, "model_data"),
		])
	var aim_dir := _get_prop_vector3(actor, "aim_direction")
	if aim_dir != Vector3.ZERO:
		lines.append("aim: (%.2f, %.2f, %.2f)" % [aim_dir.x, aim_dir.y, aim_dir.z])
	var model_root := actor.get_node_or_null("VisualRoot/ModelRoot")
	lines.append("model_root: %s" % _safe_node_path(model_root))
	if show_model_data:
		var model_data := _get_prop_object(actor, "model_data")
		if model_data:
			lines.append("model_id: %s" % _get_prop_string(model_data, "id"))
			lines.append("model_scene: %s" % _get_prop_res_path(model_data, "scene"))
			lines.append("model_library: %s" % _get_prop_res_path(model_data, "animation_library"))
			lines.append("model_anim_player_path: %s" % String(_get_prop_nodepath(model_data, "animation_player_path")))
	if model_root:
		var skeletons := model_root.find_children("*", "Skeleton3D", true, false)
		if skeletons.size() > 0:
			var primary := _pick_primary_skeleton(skeletons)
			lines.append("skeletons: %d primary_bones: %d" % [skeletons.size(), primary.get_bone_count() if primary else 0])
	_label.text = "\n".join(lines)


func _check_hotkey() -> void:
	if not hotkey_enabled:
		return
	if use_action_toggle and toggle_action != StringName() and InputMap.has_action(String(toggle_action)):
		if Input.is_action_just_pressed(toggle_action):
			enabled = not enabled
			_set_overlay_visible(enabled)
			return
	if toggle_keycode <= 0:
		return
	var pressed := Input.is_key_pressed(toggle_keycode)
	if pressed and not _hotkey_down:
		enabled = not enabled
		_set_overlay_visible(enabled)
	_hotkey_down = pressed


func _resolve_nodes() -> void:
	if _actor == null or not is_instance_valid(_actor):
		if actor_path == NodePath(""):
			_actor = get_parent()
		else:
			_actor = get_node_or_null(actor_path)
	if _label == null or not is_instance_valid(_label):
		_label = get_node_or_null(label_path) as Label
	if _canvas == null or not is_instance_valid(_canvas):
		_canvas = get_node_or_null("CanvasLayer") as CanvasLayer


func _set_overlay_visible(visible: bool) -> void:
	if _canvas == null:
		_canvas = get_node_or_null("CanvasLayer") as CanvasLayer
	if _canvas:
		_canvas.visible = visible


func _find_fsm(actor: Node) -> Node:
	if actor == null:
		return null
	return actor.get_node_or_null("StateMachine")


func _find_anim_driver(actor: Node) -> AnimDriver3D:
	if actor == null:
		return null
	if actor.has_method("get_anim_driver"):
		var driver = actor.call("get_anim_driver")
		if driver is AnimDriver3D:
			return driver
	var found := actor.find_child("AnimDriver3D", true, false)
	if found is AnimDriver3D:
		return found
	return null


func _get_controller_context(actor: Node) -> Object:
	if actor == null:
		return null
	if actor.has_method("get_controller_context"):
		return actor.call("get_controller_context")
	return null


func _resolve_anim_player(driver: Node, target_root: Node, path: NodePath) -> AnimationPlayer:
	if target_root and path != NodePath(""):
		var node := target_root.get_node_or_null(path)
		if node is AnimationPlayer:
			return node
	if driver and path != NodePath(""):
		var node2 := _resolve_path_from(driver, path)
		if node2 is AnimationPlayer:
			return node2
	if target_root:
		var found := target_root.find_child("AnimationPlayer", true, false)
		if found is AnimationPlayer:
			return found
	if driver:
		var found2 := driver.find_child("AnimationPlayer", true, false)
		if found2 is AnimationPlayer:
			return found2
	return null


func _resolve_anim_tree(driver: Node, target_root: Node, path: NodePath) -> AnimationTree:
	if target_root and path != NodePath(""):
		var node := target_root.get_node_or_null(path)
		if node is AnimationTree:
			return node
	if driver and path != NodePath(""):
		var node2 := _resolve_path_from(driver, path)
		if node2 is AnimationTree:
			return node2
	if target_root:
		var found := target_root.find_child("AnimationTree", true, false)
		if found is AnimationTree:
			return found
	if driver:
		var found2 := driver.find_child("AnimationTree", true, false)
		if found2 is AnimationTree:
			return found2
	return null


func _resolve_path_from(start: Node, path: NodePath) -> Node:
	if start == null or path == NodePath(""):
		return null
	var node := start.get_node_or_null(path)
	if node:
		return node
	var parent := start.get_parent()
	while parent:
		node = parent.get_node_or_null(path)
		if node:
			return node
		parent = parent.get_parent()
	return null


func _validate_current_animation(anim_player: AnimationPlayer) -> Dictionary:
	var result := {
		"tracks": 0,
		"missing_nodes": 0,
		"missing_bones": 0,
		"anim": "",
	}
	if anim_player == null:
		return result
	var anim_name := anim_player.current_animation
	if anim_name == "":
		return result
	var anim := anim_player.get_animation(anim_name)
	if anim == null:
		return result
	result["anim"] = anim_name
	var root: Node = anim_player
	if anim_player.root_node != NodePath(""):
		var root_candidate := anim_player.get_node_or_null(anim_player.root_node)
		if root_candidate:
			root = root_candidate
	var tracks := anim.get_track_count()
	result["tracks"] = tracks
	var missing_nodes := 0
	var missing_bones := 0
	for track_idx in range(tracks):
		var path := anim.track_get_path(track_idx)
		var node_path := NodePath(path.get_concatenated_names())
		var node: Node = null
		if root:
			node = root.get_node_or_null(node_path)
		if node == null:
			missing_nodes += 1
			continue
		if node is Skeleton3D and path.get_subname_count() > 0:
			var bone_name := String(path.get_subname(0))
			if (node as Skeleton3D).find_bone(bone_name) == -1:
				missing_bones += 1
	result["missing_nodes"] = missing_nodes
	result["missing_bones"] = missing_bones
	return result


func _pick_primary_skeleton(skeletons: Array) -> Skeleton3D:
	var best: Skeleton3D = null
	var best_bones := -1
	for skel in skeletons:
		var s := skel as Skeleton3D
		if s == null:
			continue
		var count := s.get_bone_count()
		if count > best_bones:
			best_bones = count
			best = s
	return best


func _get_prop_string(obj: Object, prop: String) -> String:
	if obj == null:
		return ""
	if prop in obj:
		return str(obj.get(prop))
	return ""


func _get_prop_bool(obj: Object, prop: String) -> bool:
	if obj == null:
		return false
	if prop in obj:
		return bool(obj.get(prop))
	return false


func _get_prop_int(obj: Object, prop: String) -> int:
	if obj == null:
		return 0
	if prop in obj:
		return int(obj.get(prop))
	return 0


func _get_prop_float(obj: Object, prop: String) -> float:
	if obj == null:
		return 0.0
	if prop in obj:
		return float(obj.get(prop))
	return 0.0


func _get_prop_nodepath(obj: Object, prop: String) -> NodePath:
	if obj == null:
		return NodePath("")
	if prop in obj:
		var value = obj.get(prop)
		if value is NodePath:
			return value
	return NodePath("")


func _get_prop_object(obj: Object, prop: String) -> Object:
	if obj == null:
		return null
	if prop in obj:
		return obj.get(prop)
	return null


func _get_prop_vector2(obj: Object, prop: String) -> Vector2:
	if obj == null:
		return Vector2.ZERO
	if prop in obj:
		var value = obj.get(prop)
		if value is Vector2:
			return value
	return Vector2.ZERO


func _get_prop_vector3(obj: Object, prop: String) -> Vector3:
	if obj == null:
		return Vector3.ZERO
	if prop in obj:
		var value = obj.get(prop)
		if value is Vector3:
			return value
	return Vector3.ZERO


func _get_resource_id(obj: Object, prop: String) -> String:
	if obj == null:
		return ""
	if not (prop in obj):
		return ""
	var res = obj.get(prop)
	if res == null:
		return "null"
	if "id" in res:
		return str(res.id)
	if res is Resource and res.resource_path != "":
		return res.resource_path
	return res.get_class()


func _get_prop_res_path(obj: Object, prop: String) -> String:
	if obj == null:
		return ""
	if not (prop in obj):
		return ""
	var value = obj.get(prop)
	if value == null:
		return "null"
	if value is Resource:
		var res := value as Resource
		if res.resource_path != "":
			return res.resource_path
		return res.get_class()
	return str(value)


func _safe_node_path(node: Node) -> String:
	if node == null:
		return "<null>"
	if not is_instance_valid(node):
		return "<freed>"
	return String(node.get_path())
