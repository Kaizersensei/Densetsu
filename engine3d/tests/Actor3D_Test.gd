extends Node3D

@onready var _actor: CharacterBody3D = $Actor
@onready var _label: Label = $CanvasLayer/Panel/Label
@onready var _canvas: CanvasLayer = $CanvasLayer


func _process(_delta: float) -> void:
	if _has_anim_debug_overlay():
		if _canvas:
			_canvas.visible = false
		return
	if not _actor or not _label:
		return
	var pos := _actor.global_transform.origin
	var vel := _actor.velocity
	var on_floor := _actor.is_on_floor()
	var movement_id := ""
	var model_id := ""
	var camera_id := ""
	var aim_dir := Vector3.ZERO
	if _actor.has_method("apply_movement_data"):
		movement_id = str(_actor.get("movement_id"))
		model_id = str(_actor.get("model_id"))
		camera_id = str(_actor.get("camera_id"))
	if "aim_direction" in _actor:
		aim_dir = _actor.get("aim_direction")
	_label.text = "Actor3D_Test\npos: (%.2f, %.2f, %.2f)\nvel: (%.2f, %.2f, %.2f)\non_floor: %s\nmovement_id: %s\nmodel_id: %s\ncamera_id: %s" % [
		pos.x, pos.y, pos.z,
		vel.x, vel.y, vel.z,
		str(on_floor),
		movement_id,
		model_id,
		camera_id,
	] + "\naim: (%.2f, %.2f, %.2f)" % [aim_dir.x, aim_dir.y, aim_dir.z]


func _has_anim_debug_overlay() -> bool:
	var root := get_tree().root
	if root == null:
		return false
	return root.find_child("AnimDebugOverlay", true, false) != null
