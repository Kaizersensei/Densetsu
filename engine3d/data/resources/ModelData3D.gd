@tool
extends Resource
class_name ModelData3D

@export_category("Identity")
@export var id: String = ""
@export var description: String = ""
@export var tags: PackedStringArray = PackedStringArray()

@export_category("Model")
@export var scene: PackedScene
@export var mesh: Mesh
@export var material_override: Material
@export var scale: Vector3 = Vector3.ONE

@export_category("Animation")
@export var animation_tree_path: NodePath
@export var animation_player_path: NodePath
@export var animation_library: AnimationLibrary
@export var animation_library_name: StringName = &"biped"

@export_category("Rendering")
@export var force_double_sided: bool = false

@export_category("Animation States")
@export var anim_idle_state: String = "idle"
@export var anim_walk_state: String = "walk"
@export var anim_run_state: String = "run"
@export var anim_sprint_state: String = "run"
@export var anim_jump_state: String = "jump"
@export var anim_fall_state: String = "fall"
@export var anim_roll_state: String = "run"
@export var anim_crouch_idle_state: String = "idle"
@export var anim_crouch_walk_state: String = "walk"


func resolve_state(intent: String) -> String:
	match intent:
		"idle":
			return anim_idle_state
		"walk":
			return anim_walk_state
		"run":
			return anim_run_state
		"sprint":
			return anim_sprint_state
		"jump":
			return anim_jump_state
		"fall":
			return anim_fall_state
		"roll":
			return anim_roll_state
		"crouch":
			return anim_crouch_idle_state
		"crouch_idle":
			return anim_crouch_idle_state
		"crouch_walk":
			return anim_crouch_walk_state
	return intent
