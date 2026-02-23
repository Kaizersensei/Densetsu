extends Node3D
class_name WeaponItem3D

## Controls item data.
@export var item_data: Resource
## Controls equipment data.
@export var equipment_data: Resource
## Controls weapon data.
@export var weapon_data: Resource

## Enable right handed.
@export var right_handed: bool = true
## Controls right hand bone.
@export var right_hand_bone: StringName = &"mixamorig_RightHand"
## Controls left hand bone.
@export var left_hand_bone: StringName = &"mixamorig_LeftHand"
## Controls sheath bone.
@export var sheath_bone: StringName = &"mixamorig_Spine"
## NodePath to skeleton.
@export var skeleton_path: NodePath
## Offset for extra.
@export var extra_offset: Vector3 = Vector3.ZERO
## Controls extra rotation degrees.
@export var extra_rotation_degrees: Vector3 = Vector3.ZERO
## Offset for sheath.
@export var sheath_offset: Vector3 = Vector3.ZERO
## Controls sheath rotation degrees.
@export var sheath_rotation_degrees: Vector3 = Vector3.ZERO
## Enable attach on ready.
@export var attach_on_ready: bool = true
## Enable show placeholder mesh.
@export var show_placeholder_mesh: bool = false
## Enable show placeholder collision.
@export var show_placeholder_collision: bool = false

var _attachment: BoneAttachment3D
var _sheathed := false


func _ready() -> void:
	_apply_placeholder_visibility()
	if attach_on_ready:
		call_deferred("_attach_to_skeleton")


func _attach_to_skeleton() -> void:
	var skeleton := _find_skeleton()
	if skeleton == null:
		return
	if _attachment == null or not is_instance_valid(_attachment) or _attachment.get_parent() != skeleton:
		_attachment = BoneAttachment3D.new()
		_attachment.name = "WeaponAttachment"
		skeleton.add_child(_attachment)
	_attachment.bone_name = _get_target_bone()
	if get_parent() != _attachment:
		reparent(_attachment, true)
	_apply_offsets()


func refresh_attachment() -> void:
	_attach_to_skeleton()


func set_sheathed(sheathed: bool) -> void:
	_sheathed = sheathed
	if _attachment:
		_attachment.bone_name = _get_target_bone()
	_apply_offsets()


func _apply_placeholder_visibility() -> void:
	var body := get_node_or_null("StaticBody3D") as Node
	if body == null:
		return
	var mesh := body.get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh:
		mesh.visible = show_placeholder_mesh
	var collision := body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision:
		collision.disabled = not show_placeholder_collision


func _apply_offsets() -> void:
	var offset := extra_offset
	var rot_deg := extra_rotation_degrees
	if _sheathed:
		offset = sheath_offset
		rot_deg = sheath_rotation_degrees
	position = offset
	rotation = Vector3(
		deg_to_rad(rot_deg.x),
		deg_to_rad(rot_deg.y),
		deg_to_rad(rot_deg.z)
	)


func _find_skeleton() -> Skeleton3D:
	if skeleton_path != NodePath("") and has_node(skeleton_path):
		var node := get_node(skeleton_path)
		if node is Skeleton3D:
			return node
	var root: Node = get_owner() if get_owner() else (get_tree().current_scene if get_tree() else null)
	if root:
		var skel := root.find_child("Skeleton3D", true, false)
		if skel is Skeleton3D:
			return skel
	return null


func _get_target_bone() -> StringName:
	if _sheathed:
		return sheath_bone
	return right_hand_bone if right_handed else left_hand_bone
