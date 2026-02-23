@tool
extends Resource
class_name ModelData3D

@export_category("Identity")
## Controls id.
@export var id: String = ""
## Controls description.
@export var description: String = ""
## Controls tags.
@export var tags: PackedStringArray = PackedStringArray()

@export_category("Model")
## Controls scene.
@export var scene: PackedScene
## Controls mesh.
@export var mesh: Mesh
## Material used for material override.
@export var material_override: Material
## Controls scale.
@export var scale: Vector3 = Vector3.ONE

@export_category("Animation")
## NodePath to animation tree.
@export var animation_tree_path: NodePath
## NodePath to animation player.
@export var animation_player_path: NodePath
## Controls animation library.
@export var animation_library: AnimationLibrary
## Name for animation library.
@export var animation_library_name: StringName = &"biped"
## Controls anim state offsets.
@export var anim_state_offsets: Dictionary = {}

@export_category("Rendering")
## Enable force double sided.
@export var force_double_sided: bool = false

@export_category("Animation States")
## State name for anim idle.
@export var anim_idle_state: String = "idle"
## State name for anim idle turn left.
@export var anim_idle_turn_left_state: String = "left_turn"
## State name for anim idle turn right.
@export var anim_idle_turn_right_state: String = "right_turn"
## State name for anim walk.
@export var anim_walk_state: String = "walk"
## State name for anim walk turn left.
@export var anim_walk_turn_left_state: String = "left_turn"
## State name for anim walk turn right.
@export var anim_walk_turn_right_state: String = "right_turn"
## State name for anim run.
@export var anim_run_state: String = "run"
## State name for anim run turn left.
@export var anim_run_turn_left_state: String = "left_turn"
## State name for anim run turn right.
@export var anim_run_turn_right_state: String = "right_turn"
## State name for anim sprint.
@export var anim_sprint_state: String = "run"
## State name for anim sprint turn left.
@export var anim_sprint_turn_left_state: String = "left_turn"
## State name for anim sprint turn right.
@export var anim_sprint_turn_right_state: String = "right_turn"
## State name for anim jump.
@export var anim_jump_state: String = "jump"
## State name for anim fall.
@export var anim_fall_state: String = "fall"
## State name for anim double jump.
@export var anim_double_jump_state: String = "double_jump"
## State name for anim wall jump.
@export var anim_wall_jump_state: String = "wall_jump"
## State name for anim roll.
@export var anim_roll_state: String = "run"
## State name for anim crouch enter.
@export var anim_crouch_enter_state: String = "crouch_enter"
## State name for anim crouch idle.
@export var anim_crouch_idle_state: String = "idle"
## State name for anim crouch walk.
@export var anim_crouch_walk_state: String = "walk"
## State name for anim crouch turn.
@export var anim_crouch_turn_state: String = "crouch_turn"
## State name for anim crouch turn left.
@export var anim_crouch_turn_left_state: String = "crouch_turn"
## State name for anim crouch turn right.
@export var anim_crouch_turn_right_state: String = "crouch_turn"
## State name for anim crouch exit.
@export var anim_crouch_exit_state: String = "crouch_exit"
## State name for anim crouch aim.
@export var anim_crouch_aim_state: String = "crouch_aim"

@export_group("Combat Unarmed", "combat_unarmed_")
## State name for combat unarmed idle.
@export var combat_unarmed_idle_state: String = "combat_unarmed_idle"
## State name for combat unarmed ready.
@export var combat_unarmed_ready_state: String = "combat_unarmed_ready"
## State name for combat unarmed attack light.
@export var combat_unarmed_attack_light_state: String = "combat_unarmed_attack_light"
## State name for combat unarmed attack heavy.
@export var combat_unarmed_attack_heavy_state: String = "combat_unarmed_attack_heavy"
## State name for combat unarmed attack combo.
@export var combat_unarmed_attack_combo_state: String = "combat_unarmed_attack_combo"
## State name for combat unarmed combo 01.
@export var combat_unarmed_combo_01_state: String = "combat_unarmed_combo_01"
## State name for combat unarmed combo 02.
@export var combat_unarmed_combo_02_state: String = "combat_unarmed_combo_02"
## State name for combat unarmed combo 03.
@export var combat_unarmed_combo_03_state: String = "combat_unarmed_combo_03"
## State name for combat unarmed combo 04.
@export var combat_unarmed_combo_04_state: String = "combat_unarmed_combo_04"
## State name for combat unarmed combo 05.
@export var combat_unarmed_combo_05_state: String = "combat_unarmed_combo_05"
## State name for combat unarmed combo 06.
@export var combat_unarmed_combo_06_state: String = "combat_unarmed_combo_06"
## State name for combat unarmed combo 07.
@export var combat_unarmed_combo_07_state: String = "combat_unarmed_combo_07"
## State name for combat unarmed combo 08.
@export var combat_unarmed_combo_08_state: String = "combat_unarmed_combo_08"
## State name for combat unarmed combo 09.
@export var combat_unarmed_combo_09_state: String = "combat_unarmed_combo_09"
## State name for combat unarmed combo 10.
@export var combat_unarmed_combo_10_state: String = "combat_unarmed_combo_10"
## State name for combat unarmed block.
@export var combat_unarmed_block_state: String = "combat_unarmed_block"
## State name for combat unarmed parry.
@export var combat_unarmed_parry_state: String = "combat_unarmed_parry"
## State name for combat unarmed throw.
@export var combat_unarmed_throw_state: String = "combat_unarmed_throw"
## State name for combat unarmed hit.
@export var combat_unarmed_hit_state: String = "combat_unarmed_hit"
## State name for combat unarmed ko.
@export var combat_unarmed_ko_state: String = "combat_unarmed_ko"
## State name for combat unarmed crouch attack light.
@export var combat_unarmed_crouch_attack_light_state: String = "combat_unarmed_crouch_attack_light"
## State name for combat unarmed crouch attack heavy.
@export var combat_unarmed_crouch_attack_heavy_state: String = "combat_unarmed_crouch_attack_heavy"

@export_group("Combat Armed", "combat_armed_")
## State name for combat armed idle.
@export var combat_armed_idle_state: String = "combat_armed_idle"
## State name for combat armed ready.
@export var combat_armed_ready_state: String = "combat_armed_ready"
## State name for combat armed attack light.
@export var combat_armed_attack_light_state: String = "combat_armed_attack_light"
## State name for combat armed attack heavy.
@export var combat_armed_attack_heavy_state: String = "combat_armed_attack_heavy"
## State name for combat armed attack combo.
@export var combat_armed_attack_combo_state: String = "combat_armed_attack_combo"
## State name for combat armed combo 01.
@export var combat_armed_combo_01_state: String = "combat_armed_combo_01"
## State name for combat armed combo 02.
@export var combat_armed_combo_02_state: String = "combat_armed_combo_02"
## State name for combat armed combo 03.
@export var combat_armed_combo_03_state: String = "combat_armed_combo_03"
## State name for combat armed combo 04.
@export var combat_armed_combo_04_state: String = "combat_armed_combo_04"
## State name for combat armed combo 05.
@export var combat_armed_combo_05_state: String = "combat_armed_combo_05"
## State name for combat armed combo 06.
@export var combat_armed_combo_06_state: String = "combat_armed_combo_06"
## State name for combat armed combo 07.
@export var combat_armed_combo_07_state: String = "combat_armed_combo_07"
## State name for combat armed combo 08.
@export var combat_armed_combo_08_state: String = "combat_armed_combo_08"
## State name for combat armed combo 09.
@export var combat_armed_combo_09_state: String = "combat_armed_combo_09"
## State name for combat armed combo 10.
@export var combat_armed_combo_10_state: String = "combat_armed_combo_10"
## State name for combat armed block.
@export var combat_armed_block_state: String = "combat_armed_block"
## State name for combat armed parry.
@export var combat_armed_parry_state: String = "combat_armed_parry"
## State name for combat armed throw.
@export var combat_armed_throw_state: String = "combat_armed_throw"
## State name for combat armed hit.
@export var combat_armed_hit_state: String = "combat_armed_hit"
## State name for combat armed ko.
@export var combat_armed_ko_state: String = "combat_armed_ko"
## State name for combat armed crouch attack light.
@export var combat_armed_crouch_attack_light_state: String = "combat_armed_crouch_attack_light"
## State name for combat armed crouch attack heavy.
@export var combat_armed_crouch_attack_heavy_state: String = "combat_armed_crouch_attack_heavy"
## State name for combat armed draw.
@export var combat_armed_draw_state: String = "combat_armed_draw"
## State name for combat armed sheath.
@export var combat_armed_sheath_state: String = "combat_armed_sheath"

@export_group("Combat Ranged", "combat_ranged_")
## State name for combat ranged idle.
@export var combat_ranged_idle_state: String = "combat_ranged_idle"
## State name for combat ranged ready.
@export var combat_ranged_ready_state: String = "combat_ranged_ready"
## State name for combat ranged aim.
@export var combat_ranged_aim_state: String = "combat_ranged_aim"
## State name for combat ranged shoot.
@export var combat_ranged_shoot_state: String = "combat_ranged_shoot"
## State name for combat ranged charge.
@export var combat_ranged_charge_state: String = "combat_ranged_charge"
## State name for combat ranged alt shoot.
@export var combat_ranged_alt_shoot_state: String = "combat_ranged_alt_shoot"
## State name for combat ranged reload.
@export var combat_ranged_reload_state: String = "combat_ranged_reload"
## State name for combat ranged throw.
@export var combat_ranged_throw_state: String = "combat_ranged_throw"
## State name for combat ranged hit.
@export var combat_ranged_hit_state: String = "combat_ranged_hit"
## State name for combat ranged ko.
@export var combat_ranged_ko_state: String = "combat_ranged_ko"
## State name for combat ranged combo 01.
@export var combat_ranged_combo_01_state: String = "combat_ranged_combo_01"
## State name for combat ranged combo 02.
@export var combat_ranged_combo_02_state: String = "combat_ranged_combo_02"
## State name for combat ranged combo 03.
@export var combat_ranged_combo_03_state: String = "combat_ranged_combo_03"
## State name for combat ranged combo 04.
@export var combat_ranged_combo_04_state: String = "combat_ranged_combo_04"
## State name for combat ranged combo 05.
@export var combat_ranged_combo_05_state: String = "combat_ranged_combo_05"
## State name for combat ranged combo 06.
@export var combat_ranged_combo_06_state: String = "combat_ranged_combo_06"
## State name for combat ranged combo 07.
@export var combat_ranged_combo_07_state: String = "combat_ranged_combo_07"
## State name for combat ranged combo 08.
@export var combat_ranged_combo_08_state: String = "combat_ranged_combo_08"
## State name for combat ranged combo 09.
@export var combat_ranged_combo_09_state: String = "combat_ranged_combo_09"
## State name for combat ranged combo 10.
@export var combat_ranged_combo_10_state: String = "combat_ranged_combo_10"
## State name for combat ranged crouch attack light.
@export var combat_ranged_crouch_attack_light_state: String = "combat_ranged_crouch_attack_light"
## State name for combat ranged crouch attack heavy.
@export var combat_ranged_crouch_attack_heavy_state: String = "combat_ranged_crouch_attack_heavy"

@export_group("Interaction", "interact_")
## State name for interact talk.
@export var interact_talk_state: String = "interact_talk"
## State name for interact use.
@export var interact_use_state: String = "interact_use"
## State name for interact push.
@export var interact_push_state: String = "interact_push"
## State name for interact pull.
@export var interact_pull_state: String = "interact_pull"
## State name for interact pickup floor.
@export var interact_pickup_floor_state: String = "interact_pickup_floor"
## State name for interact pickup hip.
@export var interact_pickup_hip_state: String = "interact_pickup_hip"
## State name for interact pickup chest.
@export var interact_pickup_chest_state: String = "interact_pickup_chest"

@export_group("Traversal", "traversal_")
## State name for traversal ledge grab.
@export var traversal_ledge_grab_state: String = "traversal_ledge_grab"
## State name for traversal ledge hold.
@export var traversal_ledge_hold_state: String = "traversal_ledge_hold"
## State name for traversal ledge climb.
@export var traversal_ledge_climb_state: String = "traversal_ledge_climb"
## State name for traversal ledge shimmy.
@export var traversal_ledge_shimmy_state: String = "traversal_ledge_shimmy"
## State name for traversal wall jump.
@export var traversal_wall_jump_state: String = "traversal_wall_jump"
## State name for traversal double jump.
@export var traversal_double_jump_state: String = "traversal_double_jump"


func resolve_state(intent: String) -> String:
	match intent:
		"idle":
			return anim_idle_state
		"idle_turn_left":
			return anim_idle_turn_left_state
		"idle_turn_right":
			return anim_idle_turn_right_state
		"walk":
			return anim_walk_state
		"walk_turn_left":
			return anim_walk_turn_left_state
		"walk_turn_right":
			return anim_walk_turn_right_state
		"run":
			return anim_run_state
		"run_turn_left":
			return anim_run_turn_left_state
		"run_turn_right":
			return anim_run_turn_right_state
		"sprint":
			return anim_sprint_state
		"sprint_turn_left":
			return anim_sprint_turn_left_state
		"sprint_turn_right":
			return anim_sprint_turn_right_state
		"jump":
			return anim_jump_state
		"fall":
			return anim_fall_state
		"double_jump":
			return anim_double_jump_state
		"wall_jump":
			return anim_wall_jump_state
		"roll":
			return anim_roll_state
		"crouch_enter":
			return anim_crouch_enter_state
		"crouch":
			return anim_crouch_idle_state
		"crouch_idle":
			return anim_crouch_idle_state
		"crouch_walk":
			return anim_crouch_walk_state
		"crouch_turn":
			return anim_crouch_turn_state
		"crouch_turn_left":
			return anim_crouch_turn_left_state
		"crouch_turn_right":
			return anim_crouch_turn_right_state
		"crouch_exit", "stand_up":
			return anim_crouch_exit_state
		"crouch_aim":
			return anim_crouch_aim_state
		"combat_unarmed_idle":
			return combat_unarmed_idle_state
		"combat_unarmed_ready":
			return combat_unarmed_ready_state
		"combat_unarmed_attack_light":
			return combat_unarmed_attack_light_state
		"combat_unarmed_attack_heavy":
			return combat_unarmed_attack_heavy_state
		"combat_unarmed_attack_combo":
			return combat_unarmed_attack_combo_state
		"combat_unarmed_combo_01":
			return combat_unarmed_combo_01_state
		"combat_unarmed_combo_02":
			return combat_unarmed_combo_02_state
		"combat_unarmed_combo_03":
			return combat_unarmed_combo_03_state
		"combat_unarmed_combo_04":
			return combat_unarmed_combo_04_state
		"combat_unarmed_combo_05":
			return combat_unarmed_combo_05_state
		"combat_unarmed_combo_06":
			return combat_unarmed_combo_06_state
		"combat_unarmed_combo_07":
			return combat_unarmed_combo_07_state
		"combat_unarmed_combo_08":
			return combat_unarmed_combo_08_state
		"combat_unarmed_combo_09":
			return combat_unarmed_combo_09_state
		"combat_unarmed_combo_10":
			return combat_unarmed_combo_10_state
		"combat_unarmed_block":
			return combat_unarmed_block_state
		"combat_unarmed_parry":
			return combat_unarmed_parry_state
		"combat_unarmed_throw":
			return combat_unarmed_throw_state
		"combat_unarmed_hit":
			return combat_unarmed_hit_state
		"combat_unarmed_ko":
			return combat_unarmed_ko_state
		"combat_unarmed_crouch_attack_light":
			return combat_unarmed_crouch_attack_light_state
		"combat_unarmed_crouch_attack_heavy":
			return combat_unarmed_crouch_attack_heavy_state
		"combat_armed_idle":
			return combat_armed_idle_state
		"combat_armed_ready":
			return combat_armed_ready_state
		"combat_armed_attack_light":
			return combat_armed_attack_light_state
		"combat_armed_attack_heavy":
			return combat_armed_attack_heavy_state
		"combat_armed_attack_combo":
			return combat_armed_attack_combo_state
		"combat_armed_combo_01":
			return combat_armed_combo_01_state
		"combat_armed_combo_02":
			return combat_armed_combo_02_state
		"combat_armed_combo_03":
			return combat_armed_combo_03_state
		"combat_armed_combo_04":
			return combat_armed_combo_04_state
		"combat_armed_combo_05":
			return combat_armed_combo_05_state
		"combat_armed_combo_06":
			return combat_armed_combo_06_state
		"combat_armed_combo_07":
			return combat_armed_combo_07_state
		"combat_armed_combo_08":
			return combat_armed_combo_08_state
		"combat_armed_combo_09":
			return combat_armed_combo_09_state
		"combat_armed_combo_10":
			return combat_armed_combo_10_state
		"combat_armed_block":
			return combat_armed_block_state
		"combat_armed_parry":
			return combat_armed_parry_state
		"combat_armed_throw":
			return combat_armed_throw_state
		"combat_armed_hit":
			return combat_armed_hit_state
		"combat_armed_ko":
			return combat_armed_ko_state
		"combat_armed_crouch_attack_light":
			return combat_armed_crouch_attack_light_state
		"combat_armed_crouch_attack_heavy":
			return combat_armed_crouch_attack_heavy_state
		"combat_armed_draw":
			return combat_armed_draw_state
		"combat_armed_sheath":
			return combat_armed_sheath_state
		"combat_ranged_idle":
			return combat_ranged_idle_state
		"combat_ranged_ready":
			return combat_ranged_ready_state
		"combat_ranged_aim":
			return combat_ranged_aim_state
		"combat_ranged_shoot":
			return combat_ranged_shoot_state
		"combat_ranged_charge":
			return combat_ranged_charge_state
		"combat_ranged_alt_shoot":
			return combat_ranged_alt_shoot_state
		"combat_ranged_reload":
			return combat_ranged_reload_state
		"combat_ranged_throw":
			return combat_ranged_throw_state
		"combat_ranged_hit":
			return combat_ranged_hit_state
		"combat_ranged_ko":
			return combat_ranged_ko_state
		"combat_ranged_combo_01":
			return combat_ranged_combo_01_state
		"combat_ranged_combo_02":
			return combat_ranged_combo_02_state
		"combat_ranged_combo_03":
			return combat_ranged_combo_03_state
		"combat_ranged_combo_04":
			return combat_ranged_combo_04_state
		"combat_ranged_combo_05":
			return combat_ranged_combo_05_state
		"combat_ranged_combo_06":
			return combat_ranged_combo_06_state
		"combat_ranged_combo_07":
			return combat_ranged_combo_07_state
		"combat_ranged_combo_08":
			return combat_ranged_combo_08_state
		"combat_ranged_combo_09":
			return combat_ranged_combo_09_state
		"combat_ranged_combo_10":
			return combat_ranged_combo_10_state
		"combat_ranged_crouch_attack_light":
			return combat_ranged_crouch_attack_light_state
		"combat_ranged_crouch_attack_heavy":
			return combat_ranged_crouch_attack_heavy_state
		"interact_talk":
			return interact_talk_state
		"interact_use":
			return interact_use_state
		"interact_push":
			return interact_push_state
		"interact_pull":
			return interact_pull_state
		"interact_pickup_floor":
			return interact_pickup_floor_state
		"interact_pickup_hip":
			return interact_pickup_hip_state
		"interact_pickup_chest":
			return interact_pickup_chest_state
		"traversal_ledge_grab":
			return traversal_ledge_grab_state
		"traversal_ledge_hold":
			return traversal_ledge_hold_state
		"traversal_ledge_climb":
			return traversal_ledge_climb_state
		"traversal_ledge_shimmy":
			return traversal_ledge_shimmy_state
		"traversal_wall_jump":
			return traversal_wall_jump_state
		"traversal_double_jump":
			return traversal_double_jump_state
	return intent


func get_anim_state_offset(state_name: String) -> float:
	if anim_state_offsets.is_empty():
		return 0.0
	if anim_state_offsets.has(state_name):
		return float(anim_state_offsets[state_name])
	return 0.0
