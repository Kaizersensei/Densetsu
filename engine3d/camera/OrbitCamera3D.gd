extends Camera3D
class_name OrbitCamera3D

enum CameraMode {
	FOLLOW,
	AIM,
	SHOULDER_LEFT,
	SHOULDER_RIGHT,
}

enum SideScrollerAxes {
	YZ,
	XZ,
	XY,
}

@export_category("Data")
## Controls camera data.
@export var camera_data: CameraRigData3D
## Enable apply data on ready.
@export var apply_data_on_ready: bool = true

@export_category("Target")
## NodePath to target.
@export var target_path: NodePath
## Height for follow.
@export var follow_height: float = 1.6
## Distance for follow.
@export var follow_distance: float = 6.0
## Controls follow smooth.
@export var follow_smooth: float = 5.0
## Use smoothing.
@export var use_smoothing: bool = true

@export_category("Orbit")
## Controls yaw degrees.
@export var yaw_degrees: float = 0.0
## Controls pitch degrees.
@export var pitch_degrees: float = -15.0
## Speed for yaw.
@export var yaw_speed: float = 120.0
## Speed for pitch.
@export var pitch_speed: float = 120.0
## Minimum value for pitch.
@export var pitch_min: float = -60.0
## Maximum value for pitch.
@export var pitch_max: float = 70.0
## Input action name for recenter.
@export var recenter_action: String = "camera_recenter"
## Automatically control recenter when moving.
@export var auto_recenter_when_moving: bool = true
## Speed for auto recenter.
@export var auto_recenter_speed: float = 45.0
## Controls auto recenter deadzone.
@export var auto_recenter_deadzone: float = 0.1
## Enable invert yaw.
@export var invert_yaw: bool = true
## Enable invert pitch.
@export var invert_pitch: bool = false

var _look_input := Vector2.ZERO

@export_category("Modes")
## Controls mode.
@export var mode: CameraMode = CameraMode.FOLLOW
## Speed for mode blend.
@export var mode_blend_speed: float = 6.0
## Distance for aim.
@export var aim_distance: float = 2.5
## Offset for shoulder.
@export var shoulder_offset: Vector3 = Vector3(0.5, 0.4, 0.0)
## Distance for min.
@export var min_distance: float = 2.0
## Distance for max.
@export var max_distance: float = 6.0
## Enable side scroller.
@export var side_scroller_enabled: bool = false
## Controls side scroller axes.
@export var side_scroller_axes: SideScrollerAxes = SideScrollerAxes.XY

var _mode_distance := 0.0
var _mode_offset := Vector3.ZERO
var _transition_from_active := false
var _transition_from_time_left := 0.0
var _transition_blend_speed_override := 0.0
var _recenter_override_time := 0.0
var _recenter_override_speed := 0.0
var _focus_active := false
var _focus_time_left := 0.0
var _focus_blend_speed := 0.0
var _focus_position := Vector3.ZERO

@export_category("Aim")
## Enable write aim to target.
@export var write_aim_to_target: bool = true
## Enable aim flatten.
@export var aim_flatten: bool = true

@export_category("Input")
## Enable input.
@export var input_enabled: bool = true

@export_category("Collision")
## Enable collision.
@export var collision_enabled: bool = true
## Controls collision mask.
@export var collision_mask: int = 1
## Controls collision margin.
@export var collision_margin: float = 0.2
## Radius for collision.
@export var collision_radius: float = 0.2
## Enable collision exclude target.
@export var collision_exclude_target: bool = true
## Enable collision hit from inside.
@export var collision_hit_from_inside: bool = true

var _collision_shape: SphereShape3D


func _ready() -> void:
	if apply_data_on_ready and camera_data:
		apply_camera_data(camera_data)


func _process(delta: float) -> void:
	if not current:
		return
	var target := _get_target()
	if target == null:
		return
	if input_enabled:
		_update_orbit_input(delta)
	else:
		_look_input = Vector2.ZERO
	_handle_recenter(target, delta)
	_update_camera_transform(target, delta)


func _update_orbit_input(delta: float) -> void:
	var look_x := _get_action_strength("look_right") - _get_action_strength("look_left")
	var look_y := _get_action_strength("look_down") - _get_action_strength("look_up")
	if invert_yaw:
		look_x = -look_x
	if invert_pitch:
		look_y = -look_y
	_look_input = Vector2(look_x, look_y)
	if absf(look_x) > 0.001:
		yaw_degrees += look_x * yaw_speed * delta
	if absf(look_y) > 0.001:
		pitch_degrees += look_y * pitch_speed * delta
	_normalize_yaw()
	pitch_degrees = clampf(pitch_degrees, pitch_min, pitch_max)


func _update_camera_transform(target: Node3D, delta: float) -> void:
	var target_distance := _get_mode_distance()
	var target_offset := _get_mode_offset(target)
	var blend_t := 1.0
	if mode_blend_speed > 0.0:
		blend_t = 1.0 - exp(-mode_blend_speed * delta)
	if _mode_distance <= 0.001:
		_mode_distance = target_distance
	_mode_distance = lerp(_mode_distance, target_distance, blend_t)
	_mode_offset = _mode_offset.lerp(target_offset, blend_t)
	var pivot := target.global_transform.origin + Vector3(0.0, follow_height, 0.0) + _mode_offset
	var desired_pos := Vector3.ZERO
	if side_scroller_enabled:
		var axis_dir := _get_side_scroller_axis_dir()
		desired_pos = pivot + axis_dir * _mode_distance
	else:
		var base_yaw := rad_to_deg(target.global_rotation.y)
		var yaw := deg_to_rad(base_yaw + yaw_degrees)
		var pitch := deg_to_rad(pitch_degrees)
		var dir := Vector3(
			sin(yaw) * cos(pitch),
			sin(pitch),
			cos(yaw) * cos(pitch)
		)
		desired_pos = pivot + dir * _mode_distance
	var resolved_pos := _resolve_collision(pivot, desired_pos, target)
	if _focus_active:
		_focus_time_left = maxf(0.0, _focus_time_left - delta)
		var t_focus := 1.0
		if _focus_blend_speed > 0.0:
			t_focus = 1.0 - exp(-_focus_blend_speed * delta)
		var focus_pos := _resolve_collision(pivot, _focus_position, target)
		resolved_pos = resolved_pos.lerp(focus_pos, t_focus)
		if _focus_time_left <= 0.0:
			_focus_active = false
	if use_smoothing:
		var blend_speed := follow_smooth
		if _transition_from_active:
			blend_speed = _transition_blend_speed_override
			_transition_from_time_left = maxf(0.0, _transition_from_time_left - delta)
			if _transition_from_time_left <= 0.0:
				_transition_from_active = false
		var t := 1.0 - exp(-blend_speed * delta)
		global_transform.origin = global_transform.origin.lerp(resolved_pos, t)
	else:
		global_transform.origin = resolved_pos
	look_at(pivot, Vector3.UP)
	if write_aim_to_target:
		_write_aim(target)


func _get_side_scroller_axis_dir() -> Vector3:
	match side_scroller_axes:
		SideScrollerAxes.XZ:
			return Vector3.UP
		SideScrollerAxes.XY:
			return Vector3.FORWARD
		_:
			return Vector3.RIGHT


func apply_camera_data(data: CameraRigData3D) -> void:
	if data == null:
		return
	camera_data = data
	follow_distance = data.follow_distance
	follow_height = data.follow_height
	follow_smooth = data.follow_smooth
	yaw_speed = data.yaw_sensitivity * 60.0
	pitch_speed = data.pitch_sensitivity * 60.0
	pitch_min = data.pitch_min
	pitch_max = data.pitch_max
	aim_distance = data.aim_distance
	shoulder_offset = data.shoulder_offset
	min_distance = data.min_distance
	max_distance = data.max_distance
	if "collision_enabled" in data:
		collision_enabled = data.collision_enabled
	if "collision_mask" in data:
		collision_mask = data.collision_mask
	if "collision_margin" in data:
		collision_margin = data.collision_margin
	if "collision_radius" in data:
		collision_radius = data.collision_radius
	_reset_mode_cache()


func set_mode(mode_id) -> void:
	mode = _coerce_mode(mode_id)


func get_mode_id() -> String:
	return _mode_to_string(mode)


func _handle_recenter(target: Node3D, delta: float) -> void:
	if recenter_action == "":
		pass
	elif _is_action_just_pressed(recenter_action):
		yaw_degrees = 0.0
		_normalize_yaw()
	if _recenter_override_time > 0.0:
		_recenter_override_time = maxf(0.0, _recenter_override_time - delta)
		var speed := _recenter_override_speed if _recenter_override_speed > 0.0 else auto_recenter_speed
		yaw_degrees = move_toward(yaw_degrees, 0.0, speed * delta)
		_normalize_yaw()
		return
	if not auto_recenter_when_moving:
		return
	if _look_input.length() > 0.01:
		return
	if _is_target_moving(target):
		yaw_degrees = move_toward(yaw_degrees, 0.0, auto_recenter_speed * delta)
		_normalize_yaw()


func _is_action_just_pressed(action: String) -> bool:
	if not InputMap.has_action(action):
		return false
	return Input.is_action_just_pressed(action)


func _is_target_moving(target: Node3D) -> bool:
	if target is CharacterBody3D:
		var body := target as CharacterBody3D
		var horiz := Vector2(body.velocity.x, body.velocity.z)
		return horiz.length() > auto_recenter_deadzone
	if "velocity" in target:
		var vel = target.get("velocity")
		if vel is Vector3:
			var horiz2 := Vector2(vel.x, vel.z)
			return horiz2.length() > auto_recenter_deadzone
	return false


func _get_mode_distance() -> float:
	var distance := follow_distance
	match mode:
		CameraMode.AIM:
			distance = aim_distance
		CameraMode.SHOULDER_LEFT, CameraMode.SHOULDER_RIGHT:
			distance = aim_distance
	return clampf(distance, min_distance, max_distance)


func _get_mode_offset(target: Node3D) -> Vector3:
	if mode != CameraMode.SHOULDER_LEFT and mode != CameraMode.SHOULDER_RIGHT:
		return Vector3.ZERO
	if target == null:
		return Vector3.ZERO
	var side := -1.0 if mode == CameraMode.SHOULDER_LEFT else 1.0
	var right := target.global_transform.basis.x
	right.y = 0.0
	if right.length() > 0.001:
		right = right.normalized()
	var forward := -target.global_transform.basis.z
	forward.y = 0.0
	if forward.length() > 0.001:
		forward = forward.normalized()
	var offset := right * (shoulder_offset.x * side)
	offset += Vector3.UP * shoulder_offset.y
	offset += forward * shoulder_offset.z
	return offset


func _reset_mode_cache() -> void:
	_mode_distance = 0.0
	_mode_offset = Vector3.ZERO


func _normalize_yaw() -> void:
	yaw_degrees = wrapf(yaw_degrees, -180.0, 180.0)


func _coerce_mode(mode_id) -> CameraMode:
	if typeof(mode_id) == TYPE_INT:
		var v := int(mode_id)
		if v >= CameraMode.FOLLOW and v <= CameraMode.SHOULDER_RIGHT:
			return v
		return CameraMode.FOLLOW
	if typeof(mode_id) == TYPE_STRING:
		var key := String(mode_id).to_lower()
		match key:
			"follow", "default":
				return CameraMode.FOLLOW
			"aim":
				return CameraMode.AIM
			"shoulder_left", "left", "shoulderleft":
				return CameraMode.SHOULDER_LEFT
			"shoulder_right", "right", "shoulderright":
				return CameraMode.SHOULDER_RIGHT
	return mode


func _mode_to_string(value: CameraMode) -> String:
	match value:
		CameraMode.FOLLOW:
			return "follow"
		CameraMode.AIM:
			return "aim"
		CameraMode.SHOULDER_LEFT:
			return "shoulder_left"
		CameraMode.SHOULDER_RIGHT:
			return "shoulder_right"
	return "follow"


func _write_aim(target: Node3D) -> void:
	var aim_dir := -global_transform.basis.z
	if aim_flatten:
		aim_dir.y = 0.0
	if aim_dir.length() <= 0.001:
		return
	aim_dir = aim_dir.normalized()
	if target.has_method("set_aim_direction"):
		target.call("set_aim_direction", aim_dir)
	elif "aim_direction" in target:
		target.set("aim_direction", aim_dir)
	else:
		target.set_meta("aim_direction", aim_dir)


func _get_target() -> Node3D:
	if target_path != NodePath(""):
		var node := get_node_or_null(target_path)
		if node is Node3D:
			return node
	var parent := get_parent()
	if parent:
		var sibling := parent.get_node_or_null("Actor")
		if sibling is Node3D:
			return sibling
	if parent is Node3D:
		return parent
	var current := parent
	while current:
		if current is Node3D:
			var n3d := current as Node3D
			if n3d.has_method("set_aim_direction") or n3d.has_method("get_controller_context"):
				return n3d
		current = current.get_parent()
	if parent:
		var fallback := parent.get_node_or_null("Actor")
		if fallback is Node3D:
			return fallback
	return null


func _get_action_strength(action: String) -> float:
	if InputMap.has_action(action):
		return Input.get_action_strength(action)
	return 0.0


func begin_transition_from_camera(from_camera: Node3D, duration: float = 0.35) -> void:
	if from_camera == null:
		return
	global_transform = from_camera.global_transform
	if duration <= 0.0:
		_transition_from_active = false
		_transition_from_time_left = 0.0
		_transition_blend_speed_override = follow_smooth
		return
	_transition_from_active = true
	_transition_from_time_left = duration
	_transition_blend_speed_override = maxf(0.001, 4.6 / duration)


func force_recenter(duration: float = 0.2, speed: float = 180.0) -> void:
	_recenter_override_time = maxf(0.0, duration)
	_recenter_override_speed = speed
	if _recenter_override_time <= 0.0:
		yaw_degrees = 0.0
		_normalize_yaw()


func snap_recenter() -> void:
	yaw_degrees = 0.0
	_normalize_yaw()
	_look_input = Vector2.ZERO


func focus_at_point(position: Vector3, duration: float = 0.15, blend_speed: float = 0.0) -> void:
	_focus_position = position
	_focus_time_left = maxf(0.0, duration)
	if blend_speed > 0.0:
		_focus_blend_speed = blend_speed
	elif _focus_time_left > 0.0:
		_focus_blend_speed = maxf(0.001, 4.6 / _focus_time_left)
	else:
		_focus_blend_speed = 0.0
	_focus_active = _focus_time_left > 0.0


func _resolve_collision(pivot: Vector3, desired: Vector3, target: Node3D) -> Vector3:
	if not collision_enabled:
		return desired
	var to_desired := desired - pivot
	var dist := to_desired.length()
	if dist <= 0.001:
		return desired
	var world := get_world_3d()
	if world == null:
		return desired
	var space := world.direct_space_state
	if space == null:
		return desired
	var exclude: Array = [self]
	if collision_exclude_target and target:
		exclude.append(target)
	var safe_dist := dist
	var shape := _get_collision_shape()
	if shape:
		var params := PhysicsShapeQueryParameters3D.new()
		params.shape = shape
		params.transform = Transform3D(Basis(), pivot)
		params.motion = to_desired
		params.collision_mask = collision_mask
		params.exclude = exclude
		params.collide_with_bodies = true
		params.collide_with_areas = true
		var cast := space.cast_motion(params)
		if cast.size() >= 1:
			var safe_frac := cast[0]
			safe_dist = dist * safe_frac
	else:
		var ray_params := PhysicsRayQueryParameters3D.create(pivot, desired)
		ray_params.collision_mask = collision_mask
		ray_params.hit_from_inside = collision_hit_from_inside
		ray_params.exclude = exclude
		var hit := space.intersect_ray(ray_params)
		if not hit.is_empty():
			var hit_pos: Vector3 = hit.position
			var hit_dist := pivot.distance_to(hit_pos)
			safe_dist = maxf(0.0, hit_dist - collision_margin)
	if safe_dist < min_distance and dist > min_distance:
		safe_dist = min_distance if safe_dist >= min_distance else safe_dist
	if safe_dist > max_distance:
		safe_dist = max_distance
	var dir := to_desired / dist
	return pivot + dir * safe_dist


func _get_collision_shape() -> SphereShape3D:
	if _collision_shape == null:
		_collision_shape = SphereShape3D.new()
	_collision_shape.radius = maxf(0.01, collision_radius)
	return _collision_shape
