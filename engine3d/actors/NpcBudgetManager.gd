@tool
extends Node

@export_category("NPC Budget")
## Enable distance-based NPC simulation budget.
@export var budget_enabled: bool = true
## Seconds between budget updates.
@export var update_interval_sec: float = 0.2
## Maximum number of NPCs that stay fully simulated.
@export var max_active_npcs: int = 32
## Maximum number of NPCs that keep animation playback active.
@export var max_animated_npcs: int = 20
## NPCs inside this radius are always active.
@export var always_active_distance: float = 24.0
## NPCs beyond this radius are deactivated.
@export var max_simulation_distance: float = 120.0
## Deactivate all NPCs when no current Camera3D exists.
@export var deactivate_without_camera: bool = false
## Print active/animated counts when they change.
@export var debug_print_counts: bool = false
## Enable screen visibility-based downgrade to logic-only updates.
@export var visibility_cull_enabled: bool = true
## Test simple line-of-sight occlusion using physics raycasts.
@export var occlusion_cull_enabled: bool = false
## Use logic-only updates instead of full simulation for hidden NPCs.
@export var offscreen_logic_only_enabled: bool = true
## Seconds between occlusion checks per NPC.
@export var occlusion_check_interval_sec: float = 0.5

var _tracked_npcs: Array[Node3D] = []
var _update_timer: float = 0.0
var _last_active_count: int = -1
var _last_animated_count: int = -1
var _all_active_applied: bool = false
var _occlusion_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


func register_npc(npc: Node3D) -> void:
	if npc == null:
		return
	if _tracked_npcs.has(npc):
		return
	_tracked_npcs.append(npc)


func unregister_npc(npc: Node3D) -> void:
	if npc == null:
		return
	var idx: int = _tracked_npcs.find(npc)
	if idx != -1:
		_tracked_npcs.remove_at(idx)
	_occlusion_cache.erase(npc.get_instance_id())


func force_refresh() -> void:
	_refresh_budget_now()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_prune_invalid_npcs()
	if _tracked_npcs.is_empty():
		return
	_tick_logic_only_npcs(delta)
	if not budget_enabled:
		if not _all_active_applied:
			_set_all_npcs_active(true, true)
			_all_active_applied = true
		return
	_all_active_applied = false
	_update_timer -= delta
	if _update_timer > 0.0:
		return
	_update_timer = maxf(0.05, update_interval_sec)
	_refresh_budget_now()


func _refresh_budget_now() -> void:
	if _tracked_npcs.is_empty():
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		if deactivate_without_camera:
			_set_all_npcs_active(false, false)
		else:
			_set_all_npcs_active(true, true)
		return

	var camera_pos: Vector3 = camera.global_position
	var always_active_sq: float = always_active_distance * always_active_distance
	var max_distance_sq: float = max_simulation_distance * max_simulation_distance

	var candidates: Array[Dictionary] = []
	for npc in _tracked_npcs:
		if npc == null or not is_instance_valid(npc):
			continue
		var distance_sq: float = camera_pos.distance_squared_to(npc.global_position)
		if distance_sq > max_distance_sq:
			continue
		var entry: Dictionary = {
			"npc": npc,
			"distance_sq": distance_sq
		}
		candidates.append(entry)

	candidates.sort_custom(Callable(self, "_sort_candidates_by_distance"))

	var active_budget_left: int = maxi(0, max_active_npcs)
	var anim_budget_left: int = maxi(0, max_animated_npcs)
	var active_count: int = 0
	var animated_count: int = 0
	var logic_only_count: int = 0
	var touched_ids: Dictionary = {}

	for entry_any in candidates:
		var entry: Dictionary = entry_any
		var npc_node: Node3D = entry.get("npc") as Node3D
		if npc_node == null:
			continue
		var distance_sq_value: float = float(entry.get("distance_sq", 0.0))
		var force_active: bool = distance_sq_value <= always_active_sq or _is_npc_always_active(npc_node)
		var runtime_active: bool = force_active or active_budget_left > 0
		if runtime_active and not force_active and active_budget_left > 0:
			active_budget_left -= 1
		var anim_active: bool = runtime_active and (force_active or anim_budget_left > 0)
		if anim_active and not force_active and anim_budget_left > 0:
			anim_budget_left -= 1

		var logic_only_active: bool = false
		if runtime_active and not force_active and offscreen_logic_only_enabled:
			var visible_for_budget: bool = _is_npc_visible_for_budget(npc_node, camera)
			if not visible_for_budget:
				logic_only_active = true
				runtime_active = false
				anim_active = false

		_apply_npc_runtime_state(npc_node, runtime_active, anim_active, logic_only_active)
		touched_ids[npc_node.get_instance_id()] = true
		if runtime_active:
			active_count += 1
		if anim_active:
			animated_count += 1
		if logic_only_active:
			logic_only_count += 1

	for npc_outside in _tracked_npcs:
		if npc_outside == null or not is_instance_valid(npc_outside):
			continue
		var instance_id: int = npc_outside.get_instance_id()
		if touched_ids.has(instance_id):
			continue
		var keep_active: bool = _is_npc_always_active(npc_outside)
		_apply_npc_runtime_state(npc_outside, keep_active, keep_active, false)
		if keep_active:
			active_count += 1
			animated_count += 1

	_log_counts_if_needed(active_count, animated_count, logic_only_count)


func _sort_candidates_by_distance(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("distance_sq", 0.0)) < float(b.get("distance_sq", 0.0))


func _is_npc_always_active(npc: Node3D) -> bool:
	if npc == null:
		return false
	if not npc.has_method("is_npc_budget_always_active"):
		return false
	var result_any: Variant = npc.call("is_npc_budget_always_active")
	if result_any is bool:
		return bool(result_any)
	return false


func _apply_npc_runtime_state(npc: Node3D, runtime_active: bool, anim_active: bool, logic_only_active: bool) -> void:
	if npc == null:
		return
	if npc.has_method("set_npc_logic_only_active"):
		npc.call("set_npc_logic_only_active", logic_only_active)
	if npc.has_method("set_npc_runtime_active"):
		npc.call("set_npc_runtime_active", runtime_active)
	if npc.has_method("set_npc_animation_active"):
		npc.call("set_npc_animation_active", anim_active)


func _set_all_npcs_active(runtime_active: bool, anim_active: bool) -> void:
	var active_count: int = 0
	var animated_count: int = 0
	for npc in _tracked_npcs:
		if npc == null or not is_instance_valid(npc):
			continue
		_apply_npc_runtime_state(npc, runtime_active, anim_active, false)
		if runtime_active:
			active_count += 1
		if anim_active:
			animated_count += 1
	_log_counts_if_needed(active_count, animated_count, 0)


func _prune_invalid_npcs() -> void:
	for i in range(_tracked_npcs.size() - 1, -1, -1):
		var npc: Node3D = _tracked_npcs[i]
		if npc == null or not is_instance_valid(npc):
			_tracked_npcs.remove_at(i)


func _tick_logic_only_npcs(delta: float) -> void:
	for npc in _tracked_npcs:
		if npc == null or not is_instance_valid(npc):
			continue
		if not npc.has_method("is_npc_logic_only_active"):
			continue
		var logic_only_any: Variant = npc.call("is_npc_logic_only_active")
		if not (logic_only_any is bool) or not bool(logic_only_any):
			continue
		if npc.has_method("step_npc_logic_only"):
			npc.call("step_npc_logic_only", delta)


func _log_counts_if_needed(active_count: int, animated_count: int, logic_only_count: int) -> void:
	if not debug_print_counts:
		return
	if active_count == _last_active_count and animated_count == _last_animated_count:
		return
	_last_active_count = active_count
	_last_animated_count = animated_count
	print(
		"NpcBudgetManager active=", active_count,
		" animated=", animated_count,
		" logic_only=", logic_only_count,
		" tracked=", _tracked_npcs.size()
	)


func _is_npc_visible_for_budget(npc: Node3D, camera: Camera3D) -> bool:
	if not visibility_cull_enabled:
		return true
	if npc == null:
		return false
	var screen_visible: bool = true
	if npc.has_method("is_npc_screen_visible"):
		var result_any: Variant = npc.call("is_npc_screen_visible")
		if result_any is bool:
			screen_visible = bool(result_any)
	if not screen_visible:
		return false
	if not occlusion_cull_enabled:
		return true
	return not _is_npc_occluded_cached(npc, camera)


func _is_npc_occluded_cached(npc: Node3D, camera: Camera3D) -> bool:
	if npc == null or camera == null:
		return false
	var key: int = npc.get_instance_id()
	var entry_any: Variant = _occlusion_cache.get(key, null)
	var now_sec: float = Time.get_ticks_msec() * 0.001
	if entry_any is Dictionary:
		var entry: Dictionary = entry_any
		var next_time: float = float(entry.get("next_time", -1.0))
		if next_time > now_sec:
			var cached_value: Variant = entry.get("occluded", false)
			if cached_value is bool:
				return bool(cached_value)
	var occluded: bool = false
	if npc.has_method("is_npc_occluded_from"):
		var occluded_any: Variant = npc.call("is_npc_occluded_from", camera)
		if occluded_any is bool:
			occluded = bool(occluded_any)
	_occlusion_cache[key] = {
		"occluded": occluded,
		"next_time": now_sec + maxf(0.05, occlusion_check_interval_sec)
	}
	return occluded
