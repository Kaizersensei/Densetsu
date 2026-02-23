@tool
extends "res://engine3d/actors/ActorNPC3D.gd"
class_name AnimalNPC3D

@export_category("Animal Animation")
## Enable automatic state-to-animation mapping from imported clips.
@export var auto_map_animation_states: bool = true
## Run automatic mapping while editing scenes.
@export var auto_map_in_editor: bool = true
## Fall back to first animation clip when no keyword match exists.
@export var auto_map_fallback_to_first: bool = true
## Print mapping diagnostics.
@export var auto_map_debug: bool = false

var _auto_state_map: Dictionary = {}
var _auto_map_ready: bool = false
var _auto_map_attempts: int = 0
var _auto_map_retry_timer: float = 0.0


func _ready() -> void:
	super._ready()
	if not auto_map_animation_states:
		set_process(false)
		return
	set_process(true)
	call_deferred("_refresh_auto_state_map")


func _process(_delta: float) -> void:
	if not auto_map_animation_states:
		set_process(false)
		return
	if not is_npc_runtime_active():
		return
	if Engine.is_editor_hint() and not auto_map_in_editor:
		set_process(false)
		return
	if _auto_map_ready:
		set_process(false)
		return
	_auto_map_retry_timer -= _delta
	if _auto_map_retry_timer > 0.0:
		return
	_auto_map_retry_timer = 0.2
	_auto_map_attempts += 1
	if _auto_map_attempts > 8:
		set_process(false)
		return
	_refresh_auto_state_map()


func resolve_anim_state(intent: String) -> String:
	if auto_map_animation_states and _auto_state_map.has(intent):
		var mapped: Variant = _auto_state_map[intent]
		if mapped is String and String(mapped) != "":
			return String(mapped)
	return super.resolve_anim_state(intent)


func _refresh_auto_state_map() -> void:
	if Engine.is_editor_hint() and not auto_map_in_editor:
		return
	var anim_player: AnimationPlayer = _find_model_animation_player()
	if anim_player == null:
		return
	_ensure_animation_player_config(anim_player)
	var animations: PackedStringArray = anim_player.get_animation_list()
	if animations.is_empty():
		return
	_auto_state_map = _build_auto_state_map(animations)
	if _auto_state_map.is_empty():
		return
	_auto_map_ready = true
	if auto_map_debug:
		print("AnimalNPC3D auto map for ", name, ": ", _auto_state_map)


func _find_model_animation_player() -> AnimationPlayer:
	var model_root: Node = get_node_or_null("VisualRoot/ModelRoot")
	if model_root == null:
		return null
	return model_root.find_child("AnimationPlayer", true, false) as AnimationPlayer


func _ensure_animation_player_config(anim_player: AnimationPlayer) -> void:
	if anim_player == null:
		return
	var model_root: Node = get_node_or_null("VisualRoot/ModelRoot")
	if model_root != null:
		var current_root: NodePath = anim_player.root_node
		var valid_root: bool = current_root != NodePath("") and anim_player.get_node_or_null(current_root) != null
		if not valid_root:
			var root_path: NodePath = anim_player.get_path_to(model_root)
			if root_path != NodePath(""):
				anim_player.root_node = root_path
	if "playback_active" in anim_player:
		anim_player.playback_active = true
	anim_player.active = true


func _build_auto_state_map(animations: PackedStringArray) -> Dictionary:
	var map: Dictionary = {}
	var fallback: String = ""
	if auto_map_fallback_to_first and animations.size() > 0:
		fallback = String(animations[0])

	var idle: String = _pick_animation(animations, ["idle", "stand", "rest"], fallback)
	var walk: String = _pick_animation(animations, ["walk", "stroll", "move"], idle)
	var run: String = _pick_animation(animations, ["run", "sprint", "gallop", "trot"], walk)
	var jump: String = _pick_animation(animations, ["jump", "hop", "leap"], run)
	var fall: String = _pick_animation(animations, ["fall", "air", "land"], jump)
	var attack: String = _pick_animation(animations, ["attack", "bite", "hit", "combat"], idle)
	var hurt: String = _pick_animation(animations, ["hurt", "hit", "damage"], idle)
	var death: String = _pick_animation(animations, ["death", "die", "dead", "ko"], idle)

	_assign_if_valid(map, "idle", idle)
	_assign_if_valid(map, "idle_turn_left", idle)
	_assign_if_valid(map, "idle_turn_right", idle)
	_assign_if_valid(map, "walk", walk)
	_assign_if_valid(map, "walk_turn_left", walk)
	_assign_if_valid(map, "walk_turn_right", walk)
	_assign_if_valid(map, "run", run)
	_assign_if_valid(map, "run_turn_left", run)
	_assign_if_valid(map, "run_turn_right", run)
	_assign_if_valid(map, "sprint", run)
	_assign_if_valid(map, "sprint_turn_left", run)
	_assign_if_valid(map, "sprint_turn_right", run)
	_assign_if_valid(map, "jump", jump)
	_assign_if_valid(map, "fall", fall)
	_assign_if_valid(map, "double_jump", jump)
	_assign_if_valid(map, "wall_jump", jump)
	_assign_if_valid(map, "roll", run)
	_assign_if_valid(map, "crouch", idle)
	_assign_if_valid(map, "crouch_idle", idle)
	_assign_if_valid(map, "crouch_walk", walk)
	_assign_if_valid(map, "crouch_enter", idle)
	_assign_if_valid(map, "crouch_exit", idle)
	_assign_if_valid(map, "combat_unarmed_idle", idle)
	_assign_if_valid(map, "combat_unarmed_ready", idle)
	_assign_if_valid(map, "combat_unarmed_attack_light", attack)
	_assign_if_valid(map, "combat_unarmed_attack_heavy", attack)
	_assign_if_valid(map, "combat_unarmed_hit", hurt)
	_assign_if_valid(map, "combat_unarmed_ko", death)
	_assign_if_valid(map, "combat_armed_idle", idle)
	_assign_if_valid(map, "combat_armed_ready", idle)
	_assign_if_valid(map, "combat_armed_attack_light", attack)
	_assign_if_valid(map, "combat_armed_attack_heavy", attack)
	_assign_if_valid(map, "combat_armed_hit", hurt)
	_assign_if_valid(map, "combat_armed_ko", death)
	_assign_if_valid(map, "combat_ranged_idle", idle)
	_assign_if_valid(map, "combat_ranged_ready", idle)
	_assign_if_valid(map, "combat_ranged_shoot", attack)
	_assign_if_valid(map, "combat_ranged_hit", hurt)
	_assign_if_valid(map, "combat_ranged_ko", death)
	_assign_if_valid(map, "interact_talk", idle)
	_assign_if_valid(map, "interact_use", idle)
	_assign_if_valid(map, "interact_push", walk)
	_assign_if_valid(map, "interact_pull", walk)
	_assign_if_valid(map, "interact_pickup_floor", idle)
	_assign_if_valid(map, "interact_pickup_hip", idle)
	_assign_if_valid(map, "interact_pickup_chest", idle)
	_assign_if_valid(map, "traversal_ledge_grab", idle)
	_assign_if_valid(map, "traversal_ledge_hold", idle)
	_assign_if_valid(map, "traversal_ledge_climb", walk)
	_assign_if_valid(map, "traversal_ledge_shimmy", walk)
	_assign_if_valid(map, "traversal_wall_jump", jump)
	_assign_if_valid(map, "traversal_double_jump", jump)

	return map


func _pick_animation(animations: PackedStringArray, keywords: Array[String], fallback: String) -> String:
	for anim_name in animations:
		var name_str: String = String(anim_name)
		var name_lc: String = name_str.to_lower()
		for keyword in keywords:
			if name_lc.find(keyword) != -1:
				return name_str
	return fallback


func _assign_if_valid(map: Dictionary, intent: String, animation_name: String) -> void:
	if animation_name == "":
		return
	map[intent] = animation_name
