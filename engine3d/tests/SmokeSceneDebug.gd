extends Node3D

@export var actor_path: NodePath = NodePath("Actor")
@export var label_path: NodePath = NodePath("CanvasLayer/Panel/Label")
@export var scene_title: String = "Smoke Scene 3D"
@export var expected_movement_id: String = ""
@export var expected_camera_id: String = ""
@export var expected_model_id: String = ""
@export var show_aim: bool = true
@export var hide_when_anim_debug_present: bool = true

@onready var _actor: Node = get_node_or_null(actor_path)
@onready var _label: Label = get_node_or_null(label_path)


func _process(_delta: float) -> void:
	if hide_when_anim_debug_present and _has_anim_debug_overlay():
		_set_overlay_visible(false)
		return
	_set_overlay_visible(true)
	if _actor == null:
		_actor = get_node_or_null(actor_path)
	if _label == null:
		_label = get_node_or_null(label_path)
	if _actor == null or _label == null:
		return
	var pos := Vector3.ZERO
	var vel := Vector3.ZERO
	var on_floor := false
	if _actor is CharacterBody3D:
		var body := _actor as CharacterBody3D
		pos = body.global_transform.origin
		vel = body.velocity
		on_floor = body.is_on_floor()
	elif _actor is Node3D:
		pos = (_actor as Node3D).global_transform.origin
	if "velocity" in _actor:
		var v = _actor.get("velocity")
		if v is Vector3:
			vel = v
	if _actor.has_method("is_on_floor"):
		on_floor = _actor.is_on_floor()
	var movement_id := _get_id_prop("movement_id")
	var camera_id := _get_id_prop("camera_id")
	var model_id := _get_id_prop("model_id")
	var movement_res := _get_resource_id("movement_data")
	var camera_res := _get_resource_id("camera_data")
	var model_res := _get_resource_id("model_data")
	var aim_dir := Vector3.ZERO
	if show_aim and "aim_direction" in _actor:
		aim_dir = _actor.get("aim_direction")
	var lines: Array[String] = []
	lines.append(scene_title)
	lines.append("pos: (%.2f, %.2f, %.2f)" % [pos.x, pos.y, pos.z])
	lines.append("vel: (%.2f, %.2f, %.2f)" % [vel.x, vel.y, vel.z])
	lines.append("on_floor: %s" % str(on_floor))
	lines.append("movement_id: %s %s" % [movement_id, _status_tag(movement_id, expected_movement_id)])
	lines.append("movement_res: %s %s" % [movement_res, _status_tag(movement_res, expected_movement_id)])
	lines.append("camera_id: %s %s" % [camera_id, _status_tag(camera_id, expected_camera_id)])
	lines.append("camera_res: %s %s" % [camera_res, _status_tag(camera_res, expected_camera_id)])
	lines.append("model_id: %s %s" % [model_id, _status_tag(model_id, expected_model_id)])
	lines.append("model_res: %s %s" % [model_res, _status_tag(model_res, expected_model_id)])
	if show_aim:
		lines.append("aim: (%.2f, %.2f, %.2f)" % [aim_dir.x, aim_dir.y, aim_dir.z])
	_label.text = "\n".join(lines)


func _set_overlay_visible(visible: bool) -> void:
	var canvas := get_node_or_null("CanvasLayer") as CanvasLayer
	if canvas:
		canvas.visible = visible


func _has_anim_debug_overlay() -> bool:
	var root := get_tree().root
	if root == null:
		return false
	return root.find_child("AnimDebugOverlay", true, false) != null


func _get_id_prop(prop: String) -> String:
	if _actor == null:
		return ""
	if prop in _actor:
		return str(_actor.get(prop))
	return ""


func _get_resource_id(prop: String) -> String:
	if _actor == null:
		return ""
	if not (prop in _actor):
		return ""
	var res = _actor.get(prop)
	if res == null:
		return "null"
	if "id" in res:
		return str(res.id)
	if res is Resource and res.resource_path != "":
		return res.resource_path
	return res.get_class()


func _status_tag(value: String, expected: String) -> String:
	if expected == "":
		return "[OK]" if value != "" and value != "null" else "[missing]"
	return "[OK]" if value == expected else "[expected %s]" % expected
