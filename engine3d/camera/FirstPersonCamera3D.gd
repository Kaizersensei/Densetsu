extends Camera3D
class_name FirstPersonCamera3D

enum OriginSource {
	NECK_BONE,
	COLLIDER,
}

@export_category("Target")
## NodePath to target.
@export var target_path: NodePath
## NodePath to skeleton.
@export var skeleton_path: NodePath
## Name for neck bone.
@export var neck_bone_name: String = "mixamorig_Neck"
## Offset for local.
@export var local_offset: Vector3 = Vector3(0.0, 0.0, 0.0)
## Use rest pose for origin.
@export var use_rest_pose_for_origin: bool = false
## Enable offset in bone space.
@export var offset_in_bone_space: bool = false
## Controls origin source.
@export var origin_source: OriginSource = OriginSource.COLLIDER
## NodePath to collider shape.
@export var collider_shape_path: NodePath = NodePath("CollisionShape3D")
## Offset for collider origin.
@export var collider_origin_offset: Vector3 = Vector3(0.0, 0.0, 0.0)

@export_category("Look")
## Controls yaw degrees.
@export var yaw_degrees: float = 0.0
## Controls pitch degrees.
@export var pitch_degrees: float = 0.0
## Speed for yaw.
@export var yaw_speed: float = 120.0
## Speed for pitch.
@export var pitch_speed: float = 120.0
## Minimum value for pitch.
@export var pitch_min: float = -80.0
## Maximum value for pitch.
@export var pitch_max: float = 80.0
## Enable invert yaw.
@export var invert_yaw: bool = false
## Enable invert pitch.
@export var invert_pitch: bool = false

@export_category("Movement")
## Enable movement forward invert.
@export var movement_forward_invert: bool = false
## Enable movement right invert.
@export var movement_right_invert: bool = false

@export_category("Neck Aim")
## Enable neck aim.
@export var neck_aim_enabled: bool = true
## Controls neck aim strength.
@export var neck_aim_strength: float = 0.6
## Controls neck yaw weight.
@export var neck_yaw_weight: float = 0.7
## Controls neck pitch weight.
@export var neck_pitch_weight: float = 0.6
## Controls neck max yaw degrees.
@export var neck_max_yaw_degrees: float = 45.0
## Controls neck max pitch degrees.
@export var neck_max_pitch_degrees: float = 45.0

@export_category("Aim")
## Enable write aim to target.
@export var write_aim_to_target: bool = true

@export_category("Collision")
## Enable collision.
@export var collision_enabled: bool = true
## Controls collision mask.
@export var collision_mask: int = 1
## Distance for collision min.
@export var collision_min_distance: float = 0.15
## Radius for collision.
@export var collision_radius: float = 0.05

var _cached_skeleton: Skeleton3D
var _last_neck_bone_idx := -1


func _process(delta: float) -> void:
	if not current:
		return
	var target := _get_target()
	if target == null:
		return
	_update_look(delta)
	_update_transform(target)


func sync_from_camera(from_camera: Camera3D) -> void:
	if from_camera == null:
		return
	var forward: Vector3 = -from_camera.global_transform.basis.z
	if forward.length() <= 0.001:
		return
	forward = forward.normalized()
	yaw_degrees = rad_to_deg(atan2(forward.x, forward.z))
	pitch_degrees = rad_to_deg(asin(clampf(forward.y, -1.0, 1.0)))
	pitch_degrees = clampf(pitch_degrees, pitch_min, pitch_max)
	# Guard against a 180-degree convention mismatch on context switch.
	var test_yaw: float = deg_to_rad(yaw_degrees)
	var test_pitch: float = deg_to_rad(pitch_degrees)
	var test_basis: Basis = Basis(Vector3.UP, test_yaw) * Basis(Vector3.RIGHT, test_pitch)
	var test_forward: Vector3 = -test_basis.z
	if test_forward.dot(forward) < 0.0:
		yaw_degrees = wrapf(yaw_degrees + 180.0, -180.0, 180.0)


func _get_target() -> Node3D:
	if target_path != NodePath(""):
		var node := get_node_or_null(target_path)
		if node is Node3D:
			return node
	var parent := get_parent()
	while parent:
		if parent is Node3D:
			return parent
		parent = parent.get_parent()
	return null


func _update_look(delta: float) -> void:
	var look_x := _get_action_strength("look_right") - _get_action_strength("look_left")
	var look_y := _get_action_strength("look_down") - _get_action_strength("look_up")
	if invert_yaw:
		look_x = -look_x
	if invert_pitch:
		look_y = -look_y
	if absf(look_x) > 0.001:
		yaw_degrees += look_x * yaw_speed * delta
	if absf(look_y) > 0.001:
		pitch_degrees += look_y * pitch_speed * delta
	yaw_degrees = wrapf(yaw_degrees, -180.0, 180.0)
	pitch_degrees = clampf(pitch_degrees, pitch_min, pitch_max)


func _update_transform(target: Node3D) -> void:
	var yaw := deg_to_rad(yaw_degrees)
	var pitch := deg_to_rad(pitch_degrees)
	var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	var neck := _get_neck_pose(target)
	var offset_basis := neck.basis if offset_in_bone_space else target.global_transform.basis
	var origin: Vector3 = _get_origin_position(target, neck)
	origin += offset_basis * local_offset
	if collision_enabled:
		origin = _apply_camera_collision(target, origin)
	global_transform = Transform3D(basis, origin)
	_write_aim(target, -basis.z)
	_apply_neck_aim(target, yaw, pitch)


func _apply_camera_collision(target: Node3D, desired_origin: Vector3) -> Vector3:
	var world := get_world_3d()
	if world == null:
		return desired_origin
	var space := world.direct_space_state
	if space == null:
		return desired_origin
	var start := target.global_transform.origin
	var end := desired_origin
	if start.distance_to(end) <= 0.001:
		return desired_origin
	var query := PhysicsRayQueryParameters3D.create(start, end)
	query.collision_mask = collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var exclude: Array = []
	if target is CollisionObject3D:
		exclude.append((target as CollisionObject3D).get_rid())
	query.exclude = exclude
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return desired_origin
	var pos: Vector3 = hit.get("position", desired_origin)
	var normal: Vector3 = hit.get("normal", Vector3.ZERO)
	if normal.length() > 0.001:
		return pos + normal.normalized() * maxf(collision_min_distance, 0.0)
	return pos


func _get_origin_position(target: Node3D, neck: Transform3D) -> Vector3:
	if origin_source == OriginSource.COLLIDER:
		var collider_origin: Vector3 = _get_collider_origin(target)
		return collider_origin + target.global_transform.basis * collider_origin_offset
	return neck.origin


func _get_collider_origin(target: Node3D) -> Vector3:
	var collider := target.get_node_or_null(collider_shape_path) as CollisionShape3D
	if collider == null:
		collider = target.find_child("CollisionShape3D", true, false) as CollisionShape3D
	if collider == null or collider.shape == null:
		return target.global_transform.origin
	var shape: Shape3D = collider.shape
	var scale: Vector3 = collider.global_transform.basis.get_scale().abs()
	var y_offset: float = 0.0
	if shape is CapsuleShape3D:
		var capsule := shape as CapsuleShape3D
		y_offset = (capsule.height * 0.5 + capsule.radius) * scale.y
	elif shape is CylinderShape3D:
		var cylinder := shape as CylinderShape3D
		y_offset = cylinder.height * 0.5 * scale.y
	elif shape is SphereShape3D:
		var sphere := shape as SphereShape3D
		y_offset = sphere.radius * scale.y
	elif shape is BoxShape3D:
		var box := shape as BoxShape3D
		y_offset = box.size.y * 0.5 * scale.y
	return collider.global_transform.origin + Vector3.UP * y_offset

func _get_neck_pose(target: Node3D) -> Transform3D:
	var skeleton := _get_skeleton(target)
	if skeleton == null:
		return target.global_transform
	var bone_idx := skeleton.find_bone(neck_bone_name)
	if bone_idx < 0:
		return skeleton.global_transform
	var bone_pose := skeleton.get_bone_global_pose(bone_idx)
	if skeleton.has_method("get_bone_global_pose_no_override"):
		bone_pose = skeleton.call("get_bone_global_pose_no_override", bone_idx)
	if use_rest_pose_for_origin:
		var rest := skeleton.get_bone_rest(bone_idx)
		return skeleton.global_transform * rest
	return skeleton.global_transform * bone_pose


func _get_skeleton(target: Node3D) -> Skeleton3D:
	if _cached_skeleton != null and is_instance_valid(_cached_skeleton):
		return _cached_skeleton
	if skeleton_path != NodePath(""):
		var node := target.get_node_or_null(skeleton_path)
		if node is Skeleton3D:
			_cached_skeleton = node
			return _cached_skeleton
	var skel := target.find_child("Skeleton3D", true, false)
	if skel is Skeleton3D:
		_cached_skeleton = skel
	return _cached_skeleton


func _get_action_strength(action: String) -> float:
	if not InputMap.has_action(action):
		return 0.0
	return Input.get_action_strength(action)


func _write_aim(target: Node3D, dir: Vector3) -> void:
	if not write_aim_to_target:
		return
	var aim_dir := dir
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


func _apply_neck_aim(target: Node3D, yaw: float, pitch: float) -> void:
	var skeleton := _get_skeleton(target)
	if skeleton == null:
		return
	var bone_idx := skeleton.find_bone(neck_bone_name)
	if bone_idx < 0:
		return
	_last_neck_bone_idx = bone_idx
	if not neck_aim_enabled or neck_aim_strength <= 0.0:
		skeleton.set_bone_global_pose_override(bone_idx, Transform3D.IDENTITY, 0.0, false)
		return
	var pose := skeleton.get_bone_global_pose(bone_idx)
	var yaw_limit := deg_to_rad(neck_max_yaw_degrees)
	var pitch_limit := deg_to_rad(neck_max_pitch_degrees)
	var clamped_yaw := clampf(yaw, -yaw_limit, yaw_limit)
	var clamped_pitch := clampf(pitch, -pitch_limit, pitch_limit)
	var yaw_rot := Basis(Vector3.UP, clamped_yaw * neck_yaw_weight)
	var pitch_rot := Basis(Vector3.RIGHT, clamped_pitch * neck_pitch_weight)
	var rot := yaw_rot * pitch_rot
	pose.basis = rot * pose.basis
	skeleton.set_bone_global_pose_override(bone_idx, pose, neck_aim_strength, true)
