@tool
extends ActorCharacter3D
class_name ActorNPC3D

@export_category("Performance")
@export_group("NPC Budget")
## Include this NPC in global runtime budgeting.
@export var budget_managed: bool = true
## Keep this NPC always active regardless of distance budgets.
@export var budget_always_active: bool = false
## Keep animation playing even when runtime simulation is paused.
@export var budget_keep_animation_when_inactive: bool = false
## Allow cheap logic-only updates when this NPC is not visible.
@export var budget_allow_logic_only_hidden: bool = true
## Tick rate used by logic-only updates.
@export var budget_logic_only_tick_rate_hz: float = 6.0
## Move NPC transform during logic-only updates.
@export var budget_logic_only_move_enabled: bool = true

@export_category("Simple Wander")
## Enable simple random wander movement.
@export var simple_wander_enabled: bool = false:
	set(value):
		simple_wander_enabled = value
		_reset_wander_runtime()
## Speed used while moving in random direction.
@export var simple_wander_speed: float = 2.5
## Minimum duration (seconds) for wait/move phase.
@export var simple_wander_wait_min: float = 0.6
## Maximum duration (seconds) for wait/move phase.
@export var simple_wander_wait_max: float = 2.2

var _wander_initialized: bool = false
var _wander_is_waiting: bool = true
var _wander_phase_time_left: float = 0.0
var _wander_direction: Vector3 = Vector3.ZERO
var _wander_anim_state: String = ""
var _npc_runtime_active: bool = true
var _npc_animation_active: bool = true
var _npc_logic_only_active: bool = false
var _logic_only_accumulator: float = 0.0
var _screen_notifier: VisibleOnScreenNotifier3D
const _NPC_HIDDEN_PROPERTY_PREFIXES := [
	"camera_",
	"first_person_",
	"side_scroller_",
]
const _NPC_HIDDEN_PROPERTY_NAMES := [
	"allow_third_person",
	"allow_first_person",
	"allow_side_scroller",
	"camera_context",
]


func _ready() -> void:
	if Engine.is_editor_hint():
		notify_property_list_changed()
	actor_role = ActorCharacter3D.ActorRole.NPC
	controller_type = ActorCharacter3D.ControllerType.AI
	use_player_input = false
	allow_third_person = false
	allow_first_person = false
	allow_side_scroller = false
	suppress_root_motion = false
	ledge_enabled = false
	wall_jump_enabled = false
	_ensure_anim_driver_node()
	_reset_wander_runtime()
	super._ready()
	_configure_anim_driver_runtime()
	_ensure_screen_notifier()
	_register_with_budget_manager()
	set_npc_runtime_active(true)
	set_npc_animation_active(true)


func _exit_tree() -> void:
	_unregister_from_budget_manager()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		super._physics_process(delta)
		return
	if not _npc_runtime_active:
		return

	if not simple_wander_enabled:
		super._physics_process(delta)
		return

	_update_wander_phase(delta)
	_apply_wander_motion(delta)
	_update_wander_animation()


func _update_wander_phase(delta: float) -> void:
	if not _wander_initialized:
		_begin_wander_phase(true)
		_wander_initialized = true
	_wander_phase_time_left = maxf(0.0, _wander_phase_time_left - delta)
	if _wander_phase_time_left > 0.0:
		return
	_begin_wander_phase(not _wander_is_waiting)


func _begin_wander_phase(waiting: bool) -> void:
	_wander_is_waiting = waiting
	_wander_phase_time_left = _get_random_phase_duration()
	if _wander_is_waiting:
		_wander_direction = Vector3.ZERO
	else:
		_wander_direction = _get_random_horizontal_direction()


func _get_random_phase_duration() -> float:
	var min_time: float = maxf(0.05, simple_wander_wait_min)
	var max_time: float = maxf(min_time, simple_wander_wait_max)
	return randf_range(min_time, max_time)


func _get_random_horizontal_direction() -> Vector3:
	var dir: Vector3 = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	if dir.length_squared() < 0.0001:
		return Vector3.FORWARD
	return dir.normalized()


func _apply_wander_motion(delta: float) -> void:
	var gravity: float = 18.0
	var params_any: Variant = _get_movement_params()
	if params_any is MovementData3D:
		var params: MovementData3D = params_any as MovementData3D
		gravity = params.gravity

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if _wander_is_waiting:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var move_speed: float = maxf(0.0, simple_wander_speed)
		velocity.x = _wander_direction.x * move_speed
		velocity.z = _wander_direction.z * move_speed

	move_and_slide()


func _reset_wander_runtime() -> void:
	_wander_initialized = false
	_wander_is_waiting = true
	_wander_phase_time_left = 0.0
	_wander_direction = Vector3.ZERO
	_wander_anim_state = ""


func _update_wander_animation() -> void:
	var driver: AnimDriver3D = get_anim_driver()
	if driver == null:
		return
	var target_state: String = "idle"
	if not _wander_is_waiting:
		target_state = _get_wander_move_anim_state()
	if _wander_anim_state == target_state:
		return
	_wander_anim_state = target_state
	driver.set_state(target_state)


func _get_wander_move_anim_state() -> String:
	var params_any: Variant = _get_movement_params()
	if params_any is MovementData3D:
		var params: MovementData3D = params_any as MovementData3D
		var walk_speed: float = maxf(0.01, params.walk_speed)
		var run_threshold: float = walk_speed * 1.35
		if simple_wander_speed >= run_threshold:
			return "run"
	return "walk"


func _ensure_anim_driver_node() -> AnimDriver3D:
	var existing: Node = find_child("AnimDriver3D", true, false)
	if existing is AnimDriver3D:
		return existing as AnimDriver3D
	var driver: AnimDriver3D = AnimDriver3D.new()
	driver.name = "AnimDriver3D"
	add_child(driver)
	return driver


func _configure_anim_driver_runtime() -> void:
	var driver: AnimDriver3D = get_anim_driver()
	if driver == null:
		return
	driver.target_root_path = NodePath("../VisualRoot/ModelRoot")
	driver.idle_variant_enabled = false
	driver.refresh_targets()
	var model_root: Node = get_node_or_null("VisualRoot/ModelRoot")
	if model_root == null:
		return
	var anim_player: AnimationPlayer = model_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player == null:
		return
	var current_root: NodePath = anim_player.root_node
	var has_valid_root: bool = current_root != NodePath("") and anim_player.get_node_or_null(current_root) != null
	if not has_valid_root:
		var root_path: NodePath = anim_player.get_path_to(model_root)
		if root_path != NodePath(""):
			anim_player.root_node = root_path
	if "playback_active" in anim_player:
		anim_player.playback_active = true
	anim_player.active = true
	_apply_anim_driver_runtime_state()


func is_npc_runtime_active() -> bool:
	return _npc_runtime_active


func is_npc_animation_active() -> bool:
	return _npc_animation_active


func is_npc_logic_only_active() -> bool:
	return _npc_logic_only_active


func is_npc_budget_always_active() -> bool:
	return budget_always_active


func is_npc_screen_visible() -> bool:
	_ensure_screen_notifier()
	if _screen_notifier == null:
		return true
	return _screen_notifier.is_on_screen()


func is_npc_occluded_from(camera: Camera3D) -> bool:
	if camera == null:
		return false
	var world: World3D = get_world_3d()
	if world == null:
		return false
	var state: PhysicsDirectSpaceState3D = world.direct_space_state
	if state == null:
		return false
	var from: Vector3 = camera.global_position
	var to: Vector3 = global_position + Vector3.UP * 1.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.exclude = [self]
	var hit: Dictionary = state.intersect_ray(query)
	if hit.is_empty():
		return false
	var collider_any: Variant = hit.get("collider", null)
	if not (collider_any is Node):
		return false
	var collider_node: Node = collider_any as Node
	if collider_node == self:
		return false
	if self.is_ancestor_of(collider_node):
		return false
	if collider_node.is_ancestor_of(self):
		return false
	return true


func set_npc_runtime_active(active: bool) -> void:
	if Engine.is_editor_hint():
		return
	var desired: bool = active
	if not budget_managed:
		desired = true
	if budget_always_active:
		desired = true
	if desired and _npc_logic_only_active:
		_npc_logic_only_active = false
		_logic_only_accumulator = 0.0
	if _npc_runtime_active == desired:
		return
	_npc_runtime_active = desired
	set_physics_process(_npc_runtime_active)
	if not _npc_runtime_active:
		velocity = Vector3.ZERO
	_apply_anim_driver_runtime_state()


func set_npc_animation_active(active: bool) -> void:
	if Engine.is_editor_hint():
		return
	var desired: bool = active
	if not budget_managed:
		desired = true
	if budget_always_active:
		desired = true
	if budget_keep_animation_when_inactive and not _npc_runtime_active:
		desired = true
	if _npc_animation_active == desired:
		return
	_npc_animation_active = desired
	_apply_anim_driver_runtime_state()


func set_npc_logic_only_active(active: bool) -> void:
	if Engine.is_editor_hint():
		return
	var desired: bool = active and budget_allow_logic_only_hidden
	if budget_always_active or not budget_managed:
		desired = false
	if _npc_logic_only_active == desired:
		return
	_npc_logic_only_active = desired
	_logic_only_accumulator = 0.0
	if _npc_logic_only_active:
		_npc_runtime_active = false
		velocity = Vector3.ZERO
		set_physics_process(false)
	_apply_anim_driver_runtime_state()


func _apply_anim_driver_runtime_state() -> void:
	if Engine.is_editor_hint():
		return
	var anim_should_run: bool = _npc_animation_active and (_npc_runtime_active or budget_keep_animation_when_inactive)
	if budget_always_active or not budget_managed:
		anim_should_run = true

	var driver: AnimDriver3D = get_anim_driver()
	if driver != null and driver.has_method("set_runtime_tick_enabled"):
		driver.call("set_runtime_tick_enabled", anim_should_run)

	var anim_player: AnimationPlayer = _find_model_animation_player()
	if anim_player == null:
		return
	if "playback_active" in anim_player:
		anim_player.playback_active = anim_should_run
	anim_player.active = anim_should_run


func _find_model_animation_player() -> AnimationPlayer:
	var model_root: Node = get_node_or_null("VisualRoot/ModelRoot")
	if model_root == null:
		return null
	return model_root.find_child("AnimationPlayer", true, false) as AnimationPlayer


func _tick_logic_only(delta: float) -> void:
	if not _npc_logic_only_active:
		return
	if not simple_wander_enabled:
		return
	var step: float = 1.0 / maxf(1.0, budget_logic_only_tick_rate_hz)
	_logic_only_accumulator += delta
	while _logic_only_accumulator >= step:
		_logic_only_accumulator -= step
		_update_wander_phase(step)
		if budget_logic_only_move_enabled and not _wander_is_waiting:
			var planar: Vector3 = _wander_direction * simple_wander_speed * step
			global_position += planar


func step_npc_logic_only(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_tick_logic_only(delta)


func _ensure_screen_notifier() -> void:
	if _screen_notifier != null and is_instance_valid(_screen_notifier):
		return
	var existing: Node = find_child("__NpcScreenNotifier", true, false)
	if existing is VisibleOnScreenNotifier3D:
		_screen_notifier = existing as VisibleOnScreenNotifier3D
		return
	var notifier: VisibleOnScreenNotifier3D = VisibleOnScreenNotifier3D.new()
	notifier.name = "__NpcScreenNotifier"
	notifier.aabb = AABB(Vector3(-0.6, 0.0, -0.6), Vector3(1.2, 2.2, 1.2))
	add_child(notifier)
	_screen_notifier = notifier


func _register_with_budget_manager() -> void:
	if Engine.is_editor_hint():
		return
	if not budget_managed:
		return
	var manager: Node = get_node_or_null("/root/NpcBudgetManager")
	if manager == null:
		return
	if manager.has_method("register_npc"):
		manager.call("register_npc", self)


func _unregister_from_budget_manager() -> void:
	if Engine.is_editor_hint():
		return
	var manager: Node = get_node_or_null("/root/NpcBudgetManager")
	if manager == null:
		return
	if manager.has_method("unregister_npc"):
		manager.call("unregister_npc", self)


func _validate_property(property: Dictionary) -> void:
	var prop_name: String = String(property.get("name", ""))
	for hidden_name in _NPC_HIDDEN_PROPERTY_NAMES:
		if prop_name == hidden_name:
			property["usage"] = PROPERTY_USAGE_NO_EDITOR
			return
	for hidden_prefix in _NPC_HIDDEN_PROPERTY_PREFIXES:
		if prop_name.begins_with(hidden_prefix):
			property["usage"] = PROPERTY_USAGE_NO_EDITOR
			return
