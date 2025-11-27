extends Camera2D

@export var pan_speed := 400.0
@export var zoom_step := 0.1
@export var min_zoom := 0.2
@export var max_zoom := 3.0
@export var accel_multiplier := 2.5

func _process(delta: float) -> void:
	if not is_current():
		return
	var dir := Vector2.ZERO
	dir.x = _strength("editor_cam_right") - _strength("editor_cam_left")
	dir.y = _strength("editor_cam_down") - _strength("editor_cam_up")
	if dir != Vector2.ZERO:
		dir = dir.normalized()
	var speed := pan_speed
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= accel_multiplier
	global_position += dir * speed * delta
	_update_zoom()


func _update_zoom() -> void:
	var z := zoom
	if _just("camera_zoom_in"):
		z -= Vector2(zoom_step, zoom_step)
	if _just("camera_zoom_out"):
		z += Vector2(zoom_step, zoom_step)
	z.x = clamp(z.x, min_zoom, max_zoom)
	z.y = clamp(z.y, min_zoom, max_zoom)
	zoom = z


func _strength(action: String) -> float:
	if InputMap.has_action(action):
		return Input.get_action_strength(action)
	return 0.0


func _just(action: String) -> bool:
	return InputMap.has_action(action) and Input.is_action_just_pressed(action)
