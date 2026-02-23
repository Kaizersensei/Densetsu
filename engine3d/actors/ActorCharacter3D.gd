@tool
extends CharacterBody3D
class_name ActorCharacter3D

signal landed
signal jumped
signal direction_changed(dir: Vector3)
signal hurt(damage: int, source_id: int)

enum ActorRole {
	PLAYER,
	NPC,
	SCENERY,
}

enum ControllerType {
	NONE,
	PLAYER,
	AI,
	SCRIPTED,
}

enum CameraContext {
	SIMPLE_THIRD_PERSON,
	FIRST_PERSON,
	SIDE_SCROLLER,
}

enum SideScrollerAxes {
	YZ,
	XZ,
	XY,
}

enum CombatMode {
	UNARMED,
	ARMED,
	RANGED,
}

enum VisualBindingMode {
	INSTANCE_MODEL_SCENE,
	RESIDENT_MODEL,
}

const COLLIDER_KIND_NONE := 0
const COLLIDER_KIND_CAPSULE := 1
const COLLIDER_KIND_BOX := 2
const COLLIDER_KIND_CYLINDER := 3

@export_category("Entity Data")
@export_group("Identity")
## Identifier for actor data.
@export var actor_data_id: String = ""
## Controls actor role.
@export var actor_role: ActorRole = ActorRole.NPC
## Controls actor tags.
@export var actor_tags: PackedStringArray = PackedStringArray()
## Identifier for faction.
@export var faction_id: String = ""
## Controls team.
@export var team: String = ""
## Identifier for owner.
@export var owner_id: int = -1

@export_group("Lifecycle")
## State name for initial.
@export var initial_state: String = ""
## State name for active.
@export var active_state: String = "active"

@export_category("Controller")
## Controls controller type.
@export var controller_type: ControllerType = ControllerType.NONE
## Use player input.
@export var use_player_input: bool = false
## Controls player number.
@export var player_number: int = 1
## Use basic movement.
@export var use_basic_movement: bool = true
## Enable modifier actions bound to the run/sprint input.
@export var modifier_actions_enabled: bool = true
## Deadzone used to classify stick direction for modifier actions.
@export var modifier_direction_deadzone: float = 0.35
## Forward/back deadzone used when sprint has priority over directional modifier actions.
@export var modifier_forward_priority_deadzone: float = 0.2
## Degrees for modifier left/right turn step.
@export var modifier_turn_step_degrees: float = 90.0
## Degrees for modifier turn-around action.
@export var modifier_turn_around_degrees: float = 180.0
## Seconds to interpolate modifier left/right turn step.
@export var modifier_turn_step_interp_time: float = 0.12
## Seconds to interpolate modifier turn-around action.
@export var modifier_turn_around_interp_time: float = 0.18

@export_category("Animation Speed")
## Playback speed range for walk locomotion states.
@export var walk_anim_speed_range: Vector2 = Vector2(0.9, 1.15)
## Playback speed range for run/sprint locomotion states.
@export var run_anim_speed_range: Vector2 = Vector2(0.9, 1.2)

@export_category("Camera Context")
## Controls camera context.
@export var camera_context: CameraContext = CameraContext.SIMPLE_THIRD_PERSON
## Allow third person.
@export var allow_third_person: bool = true:
	set(value):
		allow_third_person = value
		_rebuild_camera_cycle()
## Allow first person.
@export var allow_first_person: bool = true:
	set(value):
		allow_first_person = value
		_rebuild_camera_cycle()
## Allow side scroller.
@export var allow_side_scroller: bool = true:
	set(value):
		allow_side_scroller = value
		_rebuild_camera_cycle()
## Controls camera params.
@export var camera_params: CameraParams3D:
	get:
		return _camera_params
	set(value):
		_camera_params = value
		if is_inside_tree():
			_apply_camera_params()

@export_category("Side Scroller")
## Controls side scroller axes.
@export var side_scroller_axes: SideScrollerAxes = SideScrollerAxes.XY
## Enable side scroller allow depth.
@export var side_scroller_allow_depth: bool = true
## Enable side scroller crouch uses side down.
@export var side_scroller_crouch_uses_side_down: bool = true
## Enable side scroller use camera space.
@export var side_scroller_use_camera_space: bool = true
## Enable side scroller plane lock.
@export var side_scroller_plane_lock: bool = true
## Controls side scroller depth deadzone.
@export var side_scroller_depth_deadzone: float = 0.1
## Enable side scroller face invert.
@export var side_scroller_face_invert: bool = false
## Enable side scroller invert depth.
@export var side_scroller_invert_depth: bool = false
## Enable side scroller disable turn.
@export var side_scroller_disable_turn: bool = false
## Enable side scroller rotate visual only.
@export var side_scroller_rotate_visual_only: bool = false

@export_category("First Person")
## Enable first person move relative to camera.
@export var first_person_move_relative_to_camera: bool = true
## Enable first person align actor to camera.
@export var first_person_align_actor_to_camera: bool = true
## Speed for first person align.
@export var first_person_align_speed: float = 12.0
## Enable first person invert forward.
@export var first_person_invert_forward: bool = true
## Enable first person invert strafe.
@export var first_person_invert_strafe: bool = false
## Enable first person flip camera forward axis.
@export var first_person_flip_camera_forward_axis: bool = true
## Enable first person flip camera right axis.
@export var first_person_flip_camera_right_axis: bool = false
## Controls first person to third person lerp time.
@export var first_person_to_third_person_lerp_time: float = 0.35
## Controls first person hide nodes.
@export var first_person_hide_nodes: PackedStringArray = PackedStringArray(["head", "neck", "bun", "fringe"])
## Controls first person hide materials.
@export var first_person_hide_materials: PackedStringArray = PackedStringArray(["hair", "face"])
## Enable first person use separate model.
@export var first_person_use_separate_model: bool = false
## Controls first person model scene.
@export var first_person_model_scene: PackedScene
## Controls first person model scale.
@export var first_person_model_scale: Vector3 = Vector3.ONE
## Material used for first person override material.
@export var first_person_override_material: Material
## Offset for first person small mode.
@export var first_person_small_mode_offset: Vector3 = Vector3.ZERO
## Controls first person small mode lerp time.
@export var first_person_small_mode_lerp_time: float = 0.1

@export_category("Pivot")
## Enable pivot align bottom.
@export var pivot_align_bottom: bool = true
## Offset for pivot.
@export var pivot_offset: Vector3 = Vector3.ZERO

@export_category("Movement Params")
@export_group("Base", "base_")
var _syncing_movement_proxy := false
var _movement_gravity := 0.0
var _movement_walk_speed := 0.0
var _movement_run_speed := 0.0
var _movement_sprint_enabled := true
var _movement_sprint_double_tap_window := 0.3
var _movement_sprint_boost_multiplier := 1.5
var _movement_sprint_boost_fade_time := 3.0
var _movement_acceleration := 0.0
var _movement_deceleration := 0.0
var _movement_move_deadzone := 0.0
var _movement_turn_rate := 0.0
var _movement_turn_smooth := 0.0
var _movement_turn_invert := false
var _movement_max_slope_angle := 0.0
var _movement_air_control := 0.0
var _movement_air_accel := 0.0
var _movement_air_decel := 0.0
var _movement_max_fall_speed := 0.0
var _movement_floor_leave_delay := 0.0
var _movement_jump_speed := 0.0
var _movement_max_jumps := 0
var _movement_coyote_time := 0.0
var _movement_jump_buffer_time := 0.0
var _movement_jump_cut := 0.0
var _movement_double_jump_speed := 0.0
var _movement_double_jump_clamp_fall_speed := 0.0
var _movement_require_jump_release := false
var _movement_wall_jump_enabled := true
var _movement_wall_check_distance := 0.0
var _movement_wall_check_height := 0.0
var _movement_wall_check_multi_ray := true
var _movement_wall_check_forward := true
var _movement_wall_check_diagonals := true
var _movement_wall_jump_up_speed := 0.0
var _movement_wall_jump_push_speed := 0.0
var _movement_wall_jump_no_input_time := 0.0
var _movement_wall_jump_duration := 0.0
var _movement_wall_jump_lock_time := 0.0
var _movement_dash_speed := 0.0
var _movement_dash_time := 0.0
var _movement_dash_cooldown := 0.0
var _movement_dash_allow_air := false
var _movement_dash_allow_double_tap := false
var _movement_dash_double_tap_window := 0.0
var _movement_roll_speed := 0.0
var _movement_roll_time := 0.0
var _movement_roll_cooldown := 0.0
var _movement_crouch_height := 0.0
var _movement_crouch_walk_height := 0.0
var _movement_crouch_transition_time := 0.15
var _movement_crouch_walk_transition_time := 0.15
var _movement_crouch_walk_move_threshold := 0.1
var _movement_roll_crouch_height := 0.0
var _movement_roll_crouch_transition_time := 0.0
var _movement_crouch_stand_transition_time := 0.15
var _movement_crouch_speed := 0.0
var _movement_sneak_speed := 0.0
var _movement_drop_through_time := 0.0
var _movement_drop_through_layer := 0
var _movement_drop_through_speed := 0.0
var _movement_high_fall_speed := 0.0
var _movement_high_fall_time := 0.0
## Controls base gravity.
@export var base_gravity: float:
	get:
		return _movement_gravity
	set(value):
		_movement_gravity = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("gravity", value)
## Speed for base walk.
@export var base_walk_speed: float:
	get:
		return _movement_walk_speed
	set(value):
		_movement_walk_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("walk_speed", value)
## Speed for base run.
@export var base_run_speed: float:
	get:
		return _movement_run_speed
	set(value):
		_movement_run_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("run_speed", value)
## Enable base sprint.
@export var base_sprint_enabled: bool:
	get:
		return _movement_sprint_enabled
	set(value):
		_movement_sprint_enabled = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("sprint_enabled", value)
## Controls base sprint double tap window.
@export var base_sprint_double_tap_window: float:
	get:
		return _movement_sprint_double_tap_window
	set(value):
		_movement_sprint_double_tap_window = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("sprint_double_tap_window", value)
## Controls base sprint boost multiplier.
@export var base_sprint_boost_multiplier: float:
	get:
		return _movement_sprint_boost_multiplier
	set(value):
		_movement_sprint_boost_multiplier = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("sprint_boost_multiplier", value)
## Controls base sprint boost fade time.
@export var base_sprint_boost_fade_time: float:
	get:
		return _movement_sprint_boost_fade_time
	set(value):
		_movement_sprint_boost_fade_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("sprint_boost_fade_time", value)
## Controls base acceleration.
@export var base_acceleration: float:
	get:
		return _movement_acceleration
	set(value):
		_movement_acceleration = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("acceleration", value)
## Controls base deceleration.
@export var base_deceleration: float:
	get:
		return _movement_deceleration
	set(value):
		_movement_deceleration = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("deceleration", value)
## Controls base move deadzone.
@export var base_move_deadzone: float:
	get:
		return _movement_move_deadzone
	set(value):
		_movement_move_deadzone = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("move_deadzone", value)

@export_group("Turning", "turn_")
## Controls turn rate.
@export var turn_rate: float:
	get:
		return _movement_turn_rate
	set(value):
		_movement_turn_rate = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("turn_rate", value)
## Controls turn smooth.
@export var turn_smooth: float:
	get:
		return _movement_turn_smooth
	set(value):
		_movement_turn_smooth = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("turn_smooth", value)
## Enable turn invert.
@export var turn_invert: bool:
	get:
		return _movement_turn_invert
	set(value):
		_movement_turn_invert = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("turn_invert", value)

@export_group("Advanced", "advanced_")
## Controls advanced max slope angle.
@export var advanced_max_slope_angle: float:
	get:
		return _movement_max_slope_angle
	set(value):
		_movement_max_slope_angle = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("max_slope_angle", value)
## Controls advanced air control.
@export var advanced_air_control: float:
	get:
		return _movement_air_control
	set(value):
		_movement_air_control = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("air_control", value)
## Controls advanced air accel.
@export var advanced_air_accel: float:
	get:
		return _movement_air_accel
	set(value):
		_movement_air_accel = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("air_accel", value)
## Controls advanced air decel.
@export var advanced_air_decel: float:
	get:
		return _movement_air_decel
	set(value):
		_movement_air_decel = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("air_decel", value)
## Speed for advanced max fall.
@export var advanced_max_fall_speed: float:
	get:
		return _movement_max_fall_speed
	set(value):
		_movement_max_fall_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("max_fall_speed", value)
## Controls advanced floor leave delay.
@export var advanced_floor_leave_delay: float:
	get:
		return _movement_floor_leave_delay
	set(value):
		_movement_floor_leave_delay = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("floor_leave_delay", value)

@export_group("Jump", "jump_")
## Speed for jump.
@export var jump_speed: float:
	get:
		return _movement_jump_speed
	set(value):
		_movement_jump_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("jump_speed", value)
## Speed for jump double.
@export var jump_double_speed: float:
	get:
		return _movement_double_jump_speed
	set(value):
		_movement_double_jump_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("double_jump_speed", value)
## Controls jump max jumps.
@export var jump_max_jumps: int:
	get:
		return _movement_max_jumps
	set(value):
		_movement_max_jumps = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("max_jumps", value)
## Controls jump coyote time.
@export var jump_coyote_time: float:
	get:
		return _movement_coyote_time
	set(value):
		_movement_coyote_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("coyote_time", value)
## Controls jump buffer time.
@export var jump_buffer_time: float:
	get:
		return _movement_jump_buffer_time
	set(value):
		_movement_jump_buffer_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("jump_buffer_time", value)
## Enable jump require release.
@export var jump_require_release: bool:
	get:
		return _movement_require_jump_release
	set(value):
		_movement_require_jump_release = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("require_jump_release", value)
## Speed for jump double clamp fall.
@export var jump_double_clamp_fall_speed: float:
	get:
		return _movement_double_jump_clamp_fall_speed
	set(value):
		_movement_double_jump_clamp_fall_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("double_jump_clamp_fall_speed", value)
## Controls jump cut.
@export var jump_cut: float:
	get:
		return _movement_jump_cut
	set(value):
		_movement_jump_cut = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("jump_cut", value)

@export_group("Wall", "wall_")
## Enable wall jump.
@export var wall_jump_enabled: bool:
	get:
		return _movement_wall_jump_enabled
	set(value):
		_movement_wall_jump_enabled = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_jump_enabled", value)
## Distance for wall check.
@export var wall_check_distance: float:
	get:
		return _movement_wall_check_distance
	set(value):
		_movement_wall_check_distance = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_check_distance", value)
## Height for wall check.
@export var wall_check_height: float:
	get:
		return _movement_wall_check_height
	set(value):
		_movement_wall_check_height = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_check_height", value)
## Enable wall check multi ray.
@export var wall_check_multi_ray: bool:
	get:
		return _movement_wall_check_multi_ray
	set(value):
		_movement_wall_check_multi_ray = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_check_multi_ray", value)
## Enable wall check forward.
@export var wall_check_forward: bool:
	get:
		return _movement_wall_check_forward
	set(value):
		_movement_wall_check_forward = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_check_forward", value)
## Enable wall check diagonals.
@export var wall_check_diagonals: bool:
	get:
		return _movement_wall_check_diagonals
	set(value):
		_movement_wall_check_diagonals = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_check_diagonals", value)
## Speed for wall jump up.
@export var wall_jump_up_speed: float:
	get:
		return _movement_wall_jump_up_speed
	set(value):
		_movement_wall_jump_up_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_jump_up_speed", value)
## Speed for wall jump push.
@export var wall_jump_push_speed: float:
	get:
		return _movement_wall_jump_push_speed
	set(value):
		_movement_wall_jump_push_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_jump_push_speed", value)
## Controls wall jump no input time.
@export var wall_jump_no_input_time: float:
	get:
		return _movement_wall_jump_no_input_time
	set(value):
		_movement_wall_jump_no_input_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_jump_no_input_time", value)
## Controls wall jump duration.
@export var wall_jump_duration: float:
	get:
		return _movement_wall_jump_duration
	set(value):
		_movement_wall_jump_duration = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_jump_duration", value)
## Controls wall jump lock time.
@export var wall_jump_lock_time: float:
	get:
		return _movement_wall_jump_lock_time
	set(value):
		_movement_wall_jump_lock_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("wall_jump_lock_time", value)

@export_group("Dash", "dash_")
## Speed for dash.
@export var dash_speed: float:
	get:
		return _movement_dash_speed
	set(value):
		_movement_dash_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("dash_speed", value)
## Controls dash time.
@export var dash_time: float:
	get:
		return _movement_dash_time
	set(value):
		_movement_dash_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("dash_time", value)
## Controls dash cooldown.
@export var dash_cooldown: float:
	get:
		return _movement_dash_cooldown
	set(value):
		_movement_dash_cooldown = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("dash_cooldown", value)
## Enable dash allow air.
@export var dash_allow_air: bool:
	get:
		return _movement_dash_allow_air
	set(value):
		_movement_dash_allow_air = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("dash_allow_air", value)
## Enable dash allow double tap.
@export var dash_allow_double_tap: bool:
	get:
		return _movement_dash_allow_double_tap
	set(value):
		_movement_dash_allow_double_tap = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("dash_allow_double_tap", value)
## Controls dash double tap window.
@export var dash_double_tap_window: float:
	get:
		return _movement_dash_double_tap_window
	set(value):
		_movement_dash_double_tap_window = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("dash_double_tap_window", value)

@export_group("Roll", "roll_")
## Speed for roll.
@export var roll_speed: float:
	get:
		return _movement_roll_speed
	set(value):
		_movement_roll_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("roll_speed", value)
## Controls roll time.
@export var roll_time: float:
	get:
		return _movement_roll_time
	set(value):
		_movement_roll_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("roll_time", value)
## Controls roll cooldown.
@export var roll_cooldown: float:
	get:
		return _movement_roll_cooldown
	set(value):
		_movement_roll_cooldown = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("roll_cooldown", value)

@export_group("Posture", "posture_")
## Enable posture crouch toggle.
@export var posture_crouch_toggle: bool = false
## Height for posture crouch.
@export var posture_crouch_height: float:
	get:
		return _movement_crouch_height
	set(value):
		_movement_crouch_height = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("crouch_height", value)
## Height for posture crouch walk.
@export var posture_crouch_walk_height: float:
	get:
		return _movement_crouch_walk_height
	set(value):
		_movement_crouch_walk_height = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("crouch_walk_height", value)
## Controls posture crouch walk transition time.
@export var posture_crouch_walk_transition_time: float:
	get:
		return _movement_crouch_walk_transition_time
	set(value):
		_movement_crouch_walk_transition_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("crouch_walk_transition_time", value)
## Controls posture crouch walk move threshold.
@export var posture_crouch_walk_move_threshold: float:
	get:
		return _movement_crouch_walk_move_threshold
	set(value):
		_movement_crouch_walk_move_threshold = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("crouch_walk_move_threshold", value)
## Height for posture roll crouch.
@export var posture_roll_crouch_height: float:
	get:
		return _movement_roll_crouch_height
	set(value):
		_movement_roll_crouch_height = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("roll_crouch_height", value)
## Controls posture roll crouch transition time.
@export var posture_roll_crouch_transition_time: float:
	get:
		return _movement_roll_crouch_transition_time
	set(value):
		_movement_roll_crouch_transition_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("roll_crouch_transition_time", value)
## Controls posture crouch stand transition time.
@export var posture_crouch_stand_transition_time: float:
	get:
		return _movement_crouch_stand_transition_time
	set(value):
		_movement_crouch_stand_transition_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("crouch_stand_transition_time", value)
## Controls posture crouch transition time.
@export var posture_crouch_transition_time: float:
	get:
		return _movement_crouch_transition_time
	set(value):
		_movement_crouch_transition_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("crouch_transition_time", value)
## Speed for posture crouch.
@export var posture_crouch_speed: float:
	get:
		return _movement_crouch_speed
	set(value):
		_movement_crouch_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("crouch_speed", value)
## Speed for posture sneak.
@export var posture_sneak_speed: float:
	get:
		return _movement_sneak_speed
	set(value):
		_movement_sneak_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("sneak_speed", value)

@export_group("Drop Through", "drop_")
## Controls drop through time.
@export var drop_through_time: float:
	get:
		return _movement_drop_through_time
	set(value):
		_movement_drop_through_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("drop_through_time", value)
## Controls drop through layer.
@export var drop_through_layer: int:
	get:
		return _movement_drop_through_layer
	set(value):
		_movement_drop_through_layer = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("drop_through_layer", value)
## Speed for drop through.
@export var drop_through_speed: float:
	get:
		return _movement_drop_through_speed
	set(value):
		_movement_drop_through_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("drop_through_speed", value)

@export_group("Fall", "fall_")
## Speed for fall high.
@export var fall_high_speed: float:
	get:
		return _movement_high_fall_speed
	set(value):
		_movement_high_fall_speed = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("high_fall_speed", value)
## Controls fall high time.
@export var fall_high_time: float:
	get:
		return _movement_high_fall_time
	set(value):
		_movement_high_fall_time = value
		if _syncing_movement_proxy:
			return
		_set_movement_value("high_fall_time", value)

@export_category("Data Overrides")
@export_group("Parameter Node")
## NodePath to params node.
@export var params_node_path: NodePath = NodePath("ActorParams3D")

@export_group("Ids")
## Identifier for movement.
@export var movement_id: String = ""
## Identifier for model.
@export var model_id: String = ""
## Identifier for camera.
@export var camera_id: String = ""
## Identifier for stats.
@export var stats_id: String = ""
## Identifier for formulas.
@export var formulas_id: String = ""

@export_group("Resources")
var _movement_data: MovementData3D
var _model_data: ModelData3D
var _visual_binding_mode: VisualBindingMode = VisualBindingMode.RESIDENT_MODEL
## Controls movement data.
@export var movement_data: MovementData3D:
	get:
		return _movement_data
	set(value):
		_movement_data = value
		var params_node: Node = _get_params_node()
		if params_node:
			_params_set(params_node, "movement_data", value)
		if _controller_ctx:
			_controller_ctx.movement = _get_movement_params()
		if Engine.is_editor_hint():
			_sync_movement_proxy_from_resource()
## Controls model data.
@export var model_data: ModelData3D:
	get:
		return _model_data
	set(value):
		_model_data = value
		var params_node: Node = _get_params_node()
		if params_node:
			_params_set(params_node, "model_data", value)
		if _model_data and not _pending_anim_state_offsets.is_empty() and "anim_state_offsets" in _model_data:
			_model_data.anim_state_offsets = _pending_anim_state_offsets
			_pending_anim_state_offsets = {}
		if Engine.is_editor_hint() and is_inside_tree() and _is_editing_own_scene_root():
			_queue_editor_model_refresh()
## Controls model binding mode.
@export var visual_binding_mode: VisualBindingMode:
	get:
		return _visual_binding_mode
	set(value):
		_visual_binding_mode = value
		if Engine.is_editor_hint() and is_inside_tree() and _is_editing_own_scene_root():
			_queue_editor_model_refresh(true)
## Enable resident mode source-change rebuild.
@export var resident_rebuild_on_source_change: bool = false
## Controls camera data.
@export var camera_data: CameraRigData3D
## Controls stats data.
@export var stats_data: StatsData
## Controls formulas data.
@export var formulas_data: StatsFormulaData

@export_category("Animation Offsets")
## Controls anim state offsets.
@export var anim_state_offsets: Dictionary:
	get:
		if model_data and "anim_state_offsets" in model_data:
			return model_data.anim_state_offsets
		return {}
	set(value):
		if model_data and "anim_state_offsets" in model_data:
			model_data.anim_state_offsets = value
			_pending_anim_state_offsets = {}
		else:
			_pending_anim_state_offsets = value

@export_category("Debug")
## Enable debug mode for wall checks.
@export var debug_wall_checks: bool = false
## Color used for debug wall ray color clear.
@export var debug_wall_ray_color_clear: Color = Color(0.2, 0.8, 1.0, 0.35)
## Color used for debug wall ray color hit.
@export var debug_wall_ray_color_hit: Color = Color(1.0, 0.3, 0.3, 0.45)
## Color used for debug wall best color.
@export var debug_wall_best_color: Color = Color(1.0, 0.9, 0.1, 0.7)
## Length for debug wall ray.
@export var debug_wall_ray_length: float = 0.0
## Enable debug mode for uncommanded motion.
@export var debug_uncommanded_motion: bool = false
## Controls debug uncommanded threshold.
@export var debug_uncommanded_threshold: float = 0.2

@export_category("Inventory")
## Controls inventory data.
@export var inventory_data: InventoryData

@export_category("Combat")
## Enable combat.
@export var combat_enabled: bool = true
## Controls combat mode.
@export var combat_mode: CombatMode = CombatMode.UNARMED
## Input action name for combat lock time.
@export var combat_action_lock_time: float = 0.35

@export_category("Wall Jump")
@export_group("Debug")
## Enable debug mode for wall jump.
@export var debug_wall_jump: bool = false
## Controls debug wall jump interval.
@export var debug_wall_jump_interval: float = 0.2
## Enable debug mode for wall jump snapshot.
@export var debug_wall_jump_snapshot: bool = false
@export_group("Rotation")
## Enable wall jump rotate actor.
@export var wall_jump_rotate_actor: bool = false
## Controls wall jump turn blend time.
@export var wall_jump_turn_blend_time: float = 0.2
## Enable wall jump pre rotate.
@export var wall_jump_pre_rotate: bool = true
## Controls wall jump pre rotate time.
@export var wall_jump_pre_rotate_time: float = 0.12
## Enable wall jump pre rotate snap.
@export var wall_jump_pre_rotate_snap: bool = false
## Enable wall jump turn flip dir.
@export var wall_jump_turn_flip_dir: bool = false
## Enable wall jump restore yaw.
@export var wall_jump_restore_yaw: bool = false
## Controls wall jump restore time.
@export var wall_jump_restore_time: float = 0.25
## Enable wall jump align to camera on end.
@export var wall_jump_align_to_camera_on_end: bool = false
## Enable wall jump align to camera snap.
@export var wall_jump_align_to_camera_snap: bool = true
## Controls wall jump align to camera time.
@export var wall_jump_align_to_camera_time: float = 0.2
## Enable wall jump suppress root yaw.
@export var wall_jump_suppress_root_yaw: bool = true
## Controls wall jump root bone names.
@export var wall_jump_root_bone_names: PackedStringArray = PackedStringArray(["mixamorig_Hips", "mixamorig:hips", "Hips", "hips", "root"])
@export_group("Camera")
## Enable wall jump rotate camera.
@export var wall_jump_rotate_camera: bool = false
## Controls wall jump camera recenter time.
@export var wall_jump_camera_recenter_time: float = 0.2
## Controls wall jump camera focus time.
@export var wall_jump_camera_focus_time: float = 0.15
## Offset for wall jump camera focus.
@export var wall_jump_camera_focus_offset: float = 0.3
## Enable wall jump force recenter on end.
@export var wall_jump_force_recenter_on_end: bool = false
@export_group("Control")
## Controls wall jump control fix time.
@export var wall_jump_control_fix_time: float = 0.4
## Enable wall jump flip input by camera.
@export var wall_jump_flip_input_by_camera: bool = true
## Enable wall jump allow chain.
@export var wall_jump_allow_chain: bool = true

@export_category("Animation Root Motion")
## Enable suppress root motion.
@export var suppress_root_motion: bool = true
## Enable suppress root motion translation.
@export var suppress_root_motion_translation: bool = true
## Enable suppress root motion rotation.
@export var suppress_root_motion_rotation: bool = false
## Controls root motion bone names.
@export var root_motion_bone_names: PackedStringArray = PackedStringArray(["mixamorig_Hips", "mixamorig:hips", "Hips", "hips", "root"])

@export_category("Ledge")
# Enable/disable ledge grabbing logic.
## Enable ledge.
@export var ledge_enabled: bool = true
# Forward reach for wall check (meters).
## Distance for ledge grab.
@export var ledge_grab_distance: float = 0.45
# Height of wall check ray origin above actor (meters).
## Height for ledge grab.
@export var ledge_grab_height: float = 1.2
# Width of the grip detection box (meters).
## Width for ledge grab.
@export var ledge_grab_width: float = 0.4
# Depth of the grip detection box (meters).
## Controls ledge grab depth.
@export var ledge_grab_depth: float = 0.25
# Height of the clearance box above the ledge (meters).
## Height for ledge clearance.
@export var ledge_clearance_height: float = 0.5
# Depth of the clearance box beyond the wall (meters).
## Controls ledge clearance depth.
@export var ledge_clearance_depth: float = 0.3
# Downward ray distance to find ledge top (meters).
## Distance for ledge floor check.
@export var ledge_floor_check_distance: float = 0.8
# Max surface angle (degrees) treated as walkable; steeper becomes a ledge.
## Controls ledge max surface angle.
@export var ledge_max_surface_angle: float = 50.0
# Back offset from wall normal for hang position (meters).
## Offset for ledge hang back.
@export var ledge_hang_back_offset: float = 0.2
# Down offset from ledge top for hang position (meters).
## Offset for ledge hang down.
@export var ledge_hang_down_offset: float = 0.9
# Smooth snap time to ledge anchor (seconds).
## Controls ledge snap time.
@export var ledge_snap_time: float = 0.12
# How long the climb state lasts (seconds).
## Controls ledge climb duration.
@export var ledge_climb_duration: float = 0.5
# Vertical climb offset from ledge top (meters).
## Offset for ledge climb up.
@export var ledge_climb_up_offset: float = 1.0
# Forward climb offset away from wall (meters).
## Offset for ledge climb forward.
@export var ledge_climb_forward_offset: float = 0.2
# Additional forward/back offset while hanging (meters, along facing direction at grab).
## Offset for ledge hang z.
@export var ledge_hang_z_offset: float = 0.0
# Additional forward/back offset while climbing (meters, along facing direction at grab).
## Offset for ledge climb z.
@export var ledge_climb_z_offset: float = 0.0
# Small forward nudge applied at climb end to settle on top (meters).
## Controls ledge climb end forward nudge.
@export var ledge_climb_end_forward_nudge: float = 0.08
# Push away from wall when releasing ledge (meters/sec).
## Controls ledge release pushback.
@export var ledge_release_pushback: float = 1.0
# Rotate actor to face wall while holding/climbing.
## Enable ledge face wall.
@export var ledge_face_wall: bool = true
# When holding/climbing, snap rotation to face wall (no approach angle).
## Enable ledge face wall snap.
@export var ledge_face_wall_snap: bool = true
# Show ledge debug shapes and rays.
## Enable ledge debug.
@export var ledge_debug: bool = false

@export_category("Editor")
var _preview_model_in_editor := false
## Enable preview model in editor.
@export var preview_model_in_editor: bool = false:
	get:
		return _preview_model_in_editor
	set(value):
		_preview_model_in_editor = value
		if Engine.is_editor_hint() and is_inside_tree() and _is_editing_own_scene_root():
			set_process(true)
			_queue_editor_model_refresh()
## Enable cleanup + forced rebuild of editor preview on scene save.
@export var editor_cleanup_preview_on_save: bool = false

@onready var _actor_interface: ActorInterface3D = $ActorInterface3D
@onready var _fsm: StateMachine = $StateMachine

var _input_source: IInputSource
var _controller_ctx: ControllerContext3D
var _anim_driver: AnimDriver3D
var _default_movement: MovementData3D = MovementData3D.new()
var _camera_params: CameraParams3D
var _last_camera_context: CameraContext = CameraContext.SIMPLE_THIRD_PERSON
var _camera_cycle: Array = []
var _active_camera_trigger: CameraModeTrigger3D
var _was_on_floor := false
var _last_move_dir := Vector3.ZERO
var aim_direction: Vector3 = Vector3.FORWARD
var controls_enabled := true
var can_move := 1
var alive := true
var restrained := false
var facing := 1
var input_x := 0.0
var input_y := 0.0
var run_active := false
var sprint_active := false
var sprint_timer := 0.0
var _run_tap_timer := 0.0
var _run_tap_count := 0
var _modifier_turn_pending := false
var _modifier_turn_radians := 0.0
var _modifier_turn_pending_duration := 0.0
var _modifier_action_consumed := false
var _modifier_turn_active := false
var _modifier_turn_start_yaw := 0.0
var _modifier_turn_target_yaw := 0.0
var _modifier_turn_elapsed := 0.0
var _modifier_turn_duration := 0.0
var in_air := false
var falling := false
var jumping := false
var jump_count := 0
var can_double_jump := true
var air_time := 0.0
var high_fall := false
var can_wall_jump := false
var wall_jumping := false
var wall_side := 0
var wall_jump_lock := 0.0
var wall_jump_normal := Vector3.ZERO
var wall_jump_hit_point := Vector3.ZERO
var _wall_jump_no_input_timer := 0.0
var _wall_jump_force_timer := 0.0
var _wall_jump_force_total_time := 0.0
var _wall_jump_force_velocity := Vector3.ZERO
var _wall_jump_block_double_until_release := false
var _wall_jump_turn_dir := Vector3.ZERO
var _wall_jump_turn_yaw := 0.0
var _wall_jump_turn_active := false
var _wall_jump_camera_aim_suspended := false
var _wall_jump_debug_timer := 0.0
var _wall_jump_root_bone_idx := -1
var _wall_jump_turn_release_timer := 0.0
var _wall_jump_pre_yaw := 0.0
var _wall_jump_restore_timer := 0.0
var _wall_jump_post_align_timer := 0.0
var _wall_jump_post_align_yaw := 0.0
var _wall_jump_post_align_done := false
var _wall_jump_pre_rotating := false
var _wall_jump_pre_rotate_timer := 0.0
var _wall_jump_pre_rotate_target_yaw := 0.0
var _wall_jump_pending_velocity := Vector3.ZERO
var _wall_jump_control_fix_timer := 0.0
var _wall_jump_chain_requested := false
var _root_motion_bone_idx := -1
var _fp_hidden_materials: Dictionary = {}
var _fp_cam_base_offset_cached := false
var _fp_cam_base_offset := Vector3.ZERO
var _fp_cam_offset_current := Vector3.ZERO
var _side_scroller_plane_anchor := Vector3.ZERO
var _side_scroller_plane_anchor_set := false
var _debug_uncommanded_timer := 0.0
var _debug_last_pos_valid := false
var _debug_last_pos := Vector3.ZERO
var _debug_last_visual_pos := Vector3.ZERO
var ledge_holding := false
var ledge_climbing := false
var _ledge_anchor := Vector3.ZERO
var _ledge_top := Vector3.ZERO
var _ledge_wall_normal := Vector3.ZERO
var _ledge_face_yaw := 0.0
var _ledge_climb_timer := 0.0
var _ledge_forward_dir := Vector3.FORWARD
var _debug_ledge_root: Node3D
var _debug_ledge_grip: MeshInstance3D
var _debug_ledge_clear: MeshInstance3D
var _debug_ledge_ray: MeshInstance3D
var _debug_ledge_top: MeshInstance3D
var _debug_ledge_anchor: MeshInstance3D
var _debug_ledge_wall_normal: MeshInstance3D
var _debug_ledge_origin := Vector3.ZERO
var _debug_ledge_forward := Vector3.FORWARD
var _debug_ledge_top_pos := Vector3.ZERO
var _debug_ledge_anchor_pos := Vector3.ZERO
var _debug_ledge_wall_normal_dir := Vector3.ZERO
var _debug_ledge_hit := false
var _equipped_weapon: WeaponItem3D
var _combat_override_state := ""
var _combat_override_timer := 0.0
var _combat_blocking := false
var _first_person_model_active := false
var _cached_third_person_model_id := ""
var _cached_third_person_model_data: ModelData3D
var dashing := false
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var dash_direction := Vector3.ZERO
var roll_active := false
var roll_timer := 0.0
var roll_cooldown_timer := 0.0
var roll_direction := Vector3.ZERO
var roll_base_speed := 0.0
var crouching := false
var sneaking := false
var _crouch_toggle_state := false
var _crouch_applied := false
var _crouch_cached := false
var _crouch_collider_kind := COLLIDER_KIND_NONE
var _stand_capsule_height := 0.0
var _stand_capsule_radius := 0.0
var _stand_box_size := Vector3.ZERO
var _stand_cylinder_height := 0.0
var _stand_cylinder_radius := 0.0
var _crouch_target_total_height := 0.0
var _crouch_transition_speed := 0.0
var _collision_shape_node: CollisionShape3D
var falling_through := false
var drop_through_timer := 0.0
var _drop_through_masked := false
var speed_x := 0.0
var speed_y := 0.0
var speed_x_abs := 0.0
var speed_y_abs := 0.0
var moving_at_speed := false
var double_tap_left := false
var double_tap_right := false
var double_tap_timer_l := 0.0
var double_tap_timer_r := 0.0
var jump_released := true
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var _turn_velocity := 0.0
var _model_applied := false
var _debug_mesh: MeshInstance3D
var _visual_pivot_base := Vector3.ZERO
var _anim_floor_offset := 0.0
var _debug_wall_root: Node3D
var _debug_wall_left_mesh: MeshInstance3D
var _debug_wall_right_mesh: MeshInstance3D
var _debug_wall_left_hit_mesh: MeshInstance3D
var _debug_wall_right_hit_mesh: MeshInstance3D
var _debug_wall_best_hit_mesh: MeshInstance3D
var _debug_wall_best_ray_mesh: MeshInstance3D
var _debug_wall_left_origin := Vector3.ZERO
var _debug_wall_right_origin := Vector3.ZERO
var _debug_wall_left_dir := Vector3.ZERO
var _debug_wall_right_dir := Vector3.ZERO
var _debug_wall_left_hit := Vector3.ZERO
var _debug_wall_right_hit := Vector3.ZERO
var _debug_wall_best_hit := Vector3.ZERO
var _debug_wall_best_origin := Vector3.ZERO
var _debug_wall_best_dir := Vector3.ZERO
var _debug_wall_left_hit_valid := false
var _debug_wall_right_hit_valid := false
var _debug_wall_best_hit_valid := false
var _editor_proxy_synced := false
var _floor_leave_timer := 0.0
var _pending_anim_state_offsets: Dictionary = {}
var _editor_preview_refresh_queued := false
var _editor_preview_signature: String = ""
var _editor_preview_poll_timer := 0.0
var _resident_model_source_signature: String = ""


func _uses_actor_camera() -> bool:
	return false


func _ready() -> void:
	if Engine.is_editor_hint():
		# Only mirror from an explicit MovementData resource in editor.
		# Avoid pulling defaults from the internal fallback resource during script reload.
		var editor_data: MovementData3D = _get_movement_params()
		if editor_data != null and editor_data != _default_movement:
			_sync_movement_proxy_from_resource()
		_editor_proxy_synced = false
		set_process(true)
		_apply_pivot_defaults()
		if _is_editing_own_scene_root():
			_queue_editor_model_refresh(true)
		return
	_apply_camera_params()
	_rebuild_camera_cycle()
	_apply_controller_defaults()
	_setup_input_source()
	_setup_controller_context()
	_setup_inventory()
	velocity = Vector3.ZERO
	if _actor_interface:
		_actor_interface.initialize(self)
		_apply_actor_tags()
		_actor_interface.set_active_state(active_state)
	_apply_data_ids()
	_apply_camera_params()
	if not _model_applied:
		var apply_model := _get_model_data_for_apply()
		if apply_model:
			_apply_model_resource(apply_model)
		else:
			_set_debug_mesh_visible(true)
	_ensure_runtime_model_instance()
	_apply_camera_override()
	_apply_pivot_defaults()
	_set_active_camera()
	_cache_crouch_collider()
	_link_fsm()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if use_basic_movement:
		_apply_basic_movement(delta)
	_tick_fsm(delta)
	if _actor_interface:
		_actor_interface.on_actor_physics(delta)
	_apply_root_motion_suppress()
	if wall_jumping or _wall_jump_no_input_timer > 0.0:
		_apply_wall_jump_turn(_get_movement_params(), delta)


func _ensure_runtime_model_instance() -> void:
	if Engine.is_editor_hint():
		return
	var model_root := _ensure_model_root()
	if model_root == null:
		return
	if _has_model_geometry(model_root):
		return
	var data := _get_model_data_for_apply()
	if data:
		call_deferred("_apply_model_resource", data)
	else:
		_set_debug_mesh_visible(true)


func _has_model_geometry(root: Node) -> bool:
	if root == null:
		return false
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	return not meshes.is_empty()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	var keep_preview_polling: bool = preview_model_in_editor and _is_editing_own_scene_root()
	if _editor_proxy_synced and not keep_preview_polling:
		set_process(false)
		return
	var editor_data: MovementData3D = _get_movement_params()
	# On fresh project load, child nodes/resources can resolve a frame later.
	# Keep polling until a concrete movement resource is available.
	if not _editor_proxy_synced:
		if editor_data != null and editor_data != _default_movement:
			_sync_movement_proxy_from_resource()
			_editor_proxy_synced = true
			if not keep_preview_polling:
				set_process(false)
				return

	if keep_preview_polling:
		_editor_preview_poll_timer -= _delta
		if _editor_preview_poll_timer <= 0.0:
			_editor_preview_poll_timer = 0.25
			_queue_editor_model_refresh()


func apply_movement_data(id: String) -> void:
	movement_id = id
	var params_node: Node = _get_params_node()
	if params_node:
		_params_set(params_node, "movement_id", id)
	if params_node:
		var params_movement: Variant = _params_get(params_node, "movement_data")
		if params_movement is MovementData3D:
			movement_data = params_movement
	if _controller_ctx:
		_controller_ctx.movement = _get_movement_params()
	_sync_movement_proxy_from_resource()


func apply_model_data(id: String) -> void:
	model_id = id
	var params_node: Node = _get_params_node()
	if params_node:
		_params_set(params_node, "model_id", id)
	if model_data:
		_apply_model_resource(model_data)
	else:
		_set_debug_mesh_visible(true)


func apply_camera_data(id: String) -> void:
	camera_id = id
	var params_node: Node = _get_params_node()
	if params_node:
		_params_set(params_node, "camera_id", id)
	_apply_camera_override()
	if _controller_ctx:
		_controller_ctx.camera = _find_orbit_camera()


func _apply_controller_defaults() -> void:
	match controller_type:
		ControllerType.PLAYER:
			use_player_input = true
		ControllerType.AI, ControllerType.SCRIPTED, ControllerType.NONE:
			use_player_input = false


func _setup_input_source() -> void:
	if use_player_input or controller_type == ControllerType.PLAYER:
		_input_source = PlayerInputSource.new(player_number)
	else:
		_input_source = NullInputSource.new()
	if _controller_ctx:
		_controller_ctx.input = _input_source


func _setup_controller_context() -> void:
	_controller_ctx = ControllerContext3D.new()
	_controller_ctx.actor = self
	_controller_ctx.input = _get_input_source()
	_controller_ctx.movement = _get_movement_params()
	_controller_ctx.camera = _find_orbit_camera()
	_controller_ctx.anim = _find_anim_driver()


func _apply_actor_tags() -> void:
	if not _actor_interface:
		return
	for tag in actor_tags:
		_actor_interface.add_tag(tag)


func _link_fsm() -> void:
	if _fsm:
		_fsm.owner_ref = self
		var target_state := initial_state if initial_state != "" else _fsm.initial_state
		if target_state != "":
			_fsm.request_state(target_state)


func _tick_fsm(delta: float) -> void:
	if _controller_ctx:
		_controller_ctx.refresh()
	if _fsm:
		_fsm.state_physics(delta)
		_fsm.state_process(delta)


func _apply_basic_movement(delta: float) -> void:
	var params: MovementData3D = _get_movement_params()
	var input: IInputSource = _get_input_source()
	var on_floor := is_on_floor()
	if _wall_jump_pre_rotating:
		_update_wall_jump_pre_rotate(delta, params)
	_modifier_action_consumed = false
	_update_input_state(input, params, delta)
	_apply_modifier_turn_if_pending(delta)
	_update_combat_input(input, delta)
	if _wall_jump_no_input_timer > 0.0:
		_wall_jump_no_input_timer = maxf(0.0, _wall_jump_no_input_timer - delta)
	if _wall_jump_force_timer > 0.0:
		_wall_jump_force_timer = maxf(0.0, _wall_jump_force_timer - delta)
		var forced := _wall_jump_force_velocity
		var denom := maxf(_wall_jump_force_total_time, 0.001)
		var ratio := clampf(_wall_jump_force_timer / denom, 0.0, 1.0)
		var scale := ratio * ratio
		if forced.length() > 0.001:
			velocity.x = forced.x * scale
			velocity.z = forced.z * scale
	if wall_jumping and _wall_jump_force_timer <= 0.0:
		wall_jumping = false
		if (not on_floor) and (not jump_released):
			_wall_jump_block_double_until_release = true
		if _wall_jump_no_input_timer <= 0.0 or on_floor:
			_wall_jump_turn_dir = Vector3.ZERO
			_wall_jump_turn_active = false
	_update_sprint(input, params, delta)
	_update_ground_air_state(on_floor, params, delta)
	_update_wall_state(params, delta)
	_update_drop_through(input, params, delta, on_floor)
	_update_dash(input, params, delta, on_floor)
	_update_roll(input, params, delta, on_floor)
	_update_posture(input, on_floor, params)
	_update_crouch_transition(params, delta)
	if _update_ledge(input, params, delta):
		return
	var move := Vector2(input_x, input_y)
	if move.length() > 1.0:
		move = move.normalized()
	if camera_context == CameraContext.SIMPLE_THIRD_PERSON and not roll_active and not wall_jumping and _wall_jump_no_input_timer <= 0.0:
		_apply_simple_third_person_turn(move, Vector3.ZERO, params, delta)
	var move_dir := _get_move_direction(move)
	var desired := Vector3.ZERO
	if _movement_allowed():
		var target_speed := _get_target_speed(params, input)
		desired = move_dir * target_speed
	if roll_active:
		_apply_roll_velocity(params, on_floor)
	else:
		_apply_walk_velocity(desired, params, on_floor, delta)
		_apply_jump_logic(params, on_floor)
	_apply_gravity(params, on_floor, delta)
	_update_speed_metrics(params)
	_apply_side_scroller_velocity_lock()
	move_and_slide()
	_apply_side_scroller_plane_lock()
	if _uses_actor_camera():
		_update_first_person_camera_offset(params, delta)
	_update_landing_state()
	_update_move_dir(desired)
	_debug_uncommanded_motion_check(params, delta)
	if camera_context != CameraContext.SIMPLE_THIRD_PERSON and not roll_active and not wall_jumping and _wall_jump_no_input_timer <= 0.0:
		_apply_turning(move, move_dir, params, delta)
	if wall_jumping or _wall_jump_no_input_timer > 0.0:
		if wall_jump_rotate_actor:
			_apply_wall_jump_turn(params, delta)
			if wall_jump_suppress_root_yaw:
				_apply_wall_jump_root_yaw_suppress()
		if wall_jump_rotate_camera and camera_context != CameraContext.SIDE_SCROLLER:
			_set_camera_aim_enabled(false)
			_wall_jump_camera_aim_suspended = true
		if debug_wall_jump:
			_wall_jump_debug_timer = maxf(0.0, _wall_jump_debug_timer - delta)
			if _wall_jump_debug_timer <= 0.0:
				_wall_jump_debug_timer = maxf(0.05, debug_wall_jump_interval)
				print("WallJump dbg: active=", wall_jumping, " no_input=", _wall_jump_no_input_timer, " force=", _wall_jump_force_timer,
					" rot_y=", rad_to_deg(global_rotation.y), " target_y=", rad_to_deg(_wall_jump_turn_yaw),
					" turn_dir=", _wall_jump_turn_dir, " vel=", Vector3(velocity.x, 0.0, velocity.z))
	if _wall_jump_no_input_timer <= 0.0 and not wall_jumping:
		if _wall_jump_turn_active and _wall_jump_turn_release_timer <= 0.0:
			_wall_jump_turn_release_timer = maxf(wall_jump_turn_blend_time, 0.0)
		_wall_jump_turn_dir = Vector3.ZERO
		_wall_jump_turn_active = false
		var should_recenter := wall_jump_force_recenter_on_end or (wall_jump_rotate_camera and _wall_jump_camera_aim_suspended and camera_context != CameraContext.SIDE_SCROLLER)
		if should_recenter:
			if _wall_jump_camera_aim_suspended:
				_set_camera_aim_enabled(true)
				_wall_jump_camera_aim_suspended = false
			if camera_context != CameraContext.SIDE_SCROLLER:
				_request_wall_jump_camera_recenter()
		if wall_jump_restore_yaw and _wall_jump_restore_timer <= 0.0:
			_wall_jump_restore_timer = maxf(wall_jump_restore_time, 0.0)
		if _wall_jump_control_fix_timer <= 0.0:
			_wall_jump_control_fix_timer = maxf(wall_jump_control_fix_time, 0.0)
		if wall_jump_align_to_camera_on_end and not _wall_jump_post_align_done:
			var aim: Vector3 = _get_camera_aim_dir()
			if aim.length() > 0.001:
				_wall_jump_post_align_yaw = atan2(aim.x, aim.z)
				if wall_jump_align_to_camera_snap:
					rotation.y = _wall_jump_post_align_yaw
					_wall_jump_post_align_timer = 0.0
					_wall_jump_post_align_done = true
				elif _wall_jump_post_align_timer <= 0.0:
					_wall_jump_post_align_timer = maxf(wall_jump_align_to_camera_time, 0.0)
					_wall_jump_post_align_done = true
	if _wall_jump_turn_release_timer > 0.0:
		_wall_jump_turn_release_timer = maxf(0.0, _wall_jump_turn_release_timer - delta)
		if wall_jump_rotate_actor:
			var denom := maxf(wall_jump_turn_blend_time, 0.001)
			var t := clampf(delta / denom, 0.0, 1.0)
			rotation.y = lerp_angle(rotation.y, _wall_jump_turn_yaw, t)
			_clear_wall_jump_root_yaw_suppress()
	if _wall_jump_control_fix_timer > 0.0:
		_wall_jump_control_fix_timer = maxf(0.0, _wall_jump_control_fix_timer - delta)
	if wall_jump_restore_yaw and _wall_jump_restore_timer > 0.0:
		_wall_jump_restore_timer = maxf(0.0, _wall_jump_restore_timer - delta)
		var denom2 := maxf(wall_jump_restore_time, 0.001)
		var t2 := clampf(delta / denom2, 0.0, 1.0)
		rotation.y = lerp_angle(rotation.y, _wall_jump_pre_yaw, t2)
	if _wall_jump_post_align_timer > 0.0:
		_wall_jump_post_align_timer = maxf(0.0, _wall_jump_post_align_timer - delta)
		var denom3 := maxf(wall_jump_align_to_camera_time, 0.001)
		var t3 := clampf(delta / denom3, 0.0, 1.0)
		rotation.y = lerp_angle(rotation.y, _wall_jump_post_align_yaw, t3)


func _input_allowed() -> bool:
	return controls_enabled and alive and not restrained


func _movement_allowed() -> bool:
	if not _input_allowed():
		return false
	return can_move == 1 and not roll_active


func _update_input_state(input: IInputSource, params: MovementData3D, delta: float) -> void:
	if _input_allowed():
		if wall_jumping and wall_jump_allow_chain and input.is_jump_just_pressed():
			_wall_jump_chain_requested = true
		if _wall_jump_no_input_timer > 0.0 or _wall_jump_pre_rotating:
			input_x = 0.0
			input_y = 0.0
			jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
			return
		var move_vec: Vector2 = input.get_move_vector()
		if camera_context == CameraContext.SIDE_SCROLLER and input.has_method("get_side_scroller_vector"):
			move_vec = input.get_side_scroller_vector()
		var deadzone := 0.0
		if params:
			deadzone = params.move_deadzone
		if deadzone > 0.0 and move_vec.length() < deadzone:
			move_vec = Vector2.ZERO
		input_x = clampf(move_vec.x, -1.0, 1.0)
		input_y = clampf(move_vec.y, -1.0, 1.0)
		if _uses_actor_camera() and input.has_method("is_camera_toggle_just_pressed") and input.is_camera_toggle_just_pressed():
			_toggle_camera_context()
		_update_modifier_actions(input)
		if absf(input_x) > 0.01:
			facing = 1 if input_x > 0.0 else -1
		if can_move == 1 and input.is_jump_just_pressed():
			jump_buffer_timer = params.jump_buffer_time
		else:
			jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
		if input.is_jump_just_released():
			jump_released = true
			if velocity.y > 0.0 and params.jump_cut > 0.0 and params.jump_cut < 1.0:
				velocity.y *= params.jump_cut
	else:
		input_x = 0.0
		input_y = 0.0
		run_active = false
		_modifier_turn_pending = false
		_modifier_turn_pending_duration = 0.0
		_modifier_turn_active = false
		_modifier_turn_elapsed = 0.0
		_modifier_turn_duration = 0.0
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
		_wall_jump_chain_requested = false


func _update_modifier_actions(input: IInputSource) -> void:
	if input == null:
		return
	if not modifier_actions_enabled:
		return
	if camera_context != CameraContext.SIMPLE_THIRD_PERSON:
		return
	if not input.is_modifier_held():
		return
	if can_move != 1 or not controls_enabled or not alive or restrained:
		return
	if ledge_holding or ledge_climbing:
		return
	if roll_active or dashing or wall_jumping or _wall_jump_pre_rotating:
		return

	var abs_x: float = absf(input_x)
	var abs_y: float = absf(input_y)
	var direction_deadzone: float = clampf(modifier_direction_deadzone, 0.0, 1.0)
	var priority_deadzone: float = clampf(modifier_forward_priority_deadzone, 0.0, 1.0)
	var modifier_just_pressed: bool = input.is_modifier_just_pressed()

	# Explicit down+modifier turn-around action.
	var down_triggered: bool = input.is_move_down_just_pressed() or (modifier_just_pressed and input_y >= direction_deadzone and abs_x < direction_deadzone)
	if down_triggered:
		_queue_modifier_turn_deg(modifier_turn_around_degrees, modifier_turn_around_interp_time)
		return

	# Sprint gets priority whenever forward/back input is active.
	if abs_y >= priority_deadzone:
		return

	var left_triggered: bool = input.is_move_left_just_pressed() or (modifier_just_pressed and input_x <= -direction_deadzone)
	if left_triggered and abs_x >= direction_deadzone:
		_queue_modifier_turn_deg(-modifier_turn_step_degrees, modifier_turn_step_interp_time)
		return
	var right_triggered: bool = input.is_move_right_just_pressed() or (modifier_just_pressed and input_x >= direction_deadzone)
	if right_triggered and abs_x >= direction_deadzone:
		_queue_modifier_turn_deg(modifier_turn_step_degrees, modifier_turn_step_interp_time)


func _queue_modifier_turn_deg(turn_degrees: float, turn_duration: float = 0.0) -> void:
	if absf(turn_degrees) <= 0.001:
		return
	_modifier_turn_pending = true
	_modifier_turn_radians = deg_to_rad(turn_degrees)
	_modifier_turn_pending_duration = maxf(turn_duration, 0.0)
	_modifier_action_consumed = true


func _apply_modifier_turn_if_pending(delta: float) -> void:
	if _modifier_turn_pending:
		_modifier_turn_pending = false
		var turn_radians: float = _modifier_turn_radians
		var turn_duration: float = _modifier_turn_pending_duration
		_modifier_turn_radians = 0.0
		_modifier_turn_pending_duration = 0.0
		if absf(turn_radians) > 0.000001:
			var start_yaw: float = rotation.y
			var target_yaw: float = wrapf(start_yaw + turn_radians, -PI, PI)
			_turn_velocity = 0.0
			input_x = 0.0
			input_y = 0.0
			if turn_duration <= 0.0001:
				rotation.y = target_yaw
				_modifier_turn_active = false
				_finish_modifier_turn()
			else:
				_modifier_turn_active = true
				_modifier_turn_start_yaw = start_yaw
				_modifier_turn_target_yaw = target_yaw
				_modifier_turn_elapsed = 0.0
				_modifier_turn_duration = turn_duration

	if not _modifier_turn_active:
		return
	if _modifier_turn_duration <= 0.0001:
		rotation.y = _modifier_turn_target_yaw
		_modifier_turn_active = false
		_finish_modifier_turn()
		return
	_modifier_turn_elapsed = minf(_modifier_turn_elapsed + maxf(delta, 0.0), _modifier_turn_duration)
	var t: float = clampf(_modifier_turn_elapsed / _modifier_turn_duration, 0.0, 1.0)
	var eased_t: float = t * t * (3.0 - (2.0 * t))
	rotation.y = lerp_angle(_modifier_turn_start_yaw, _modifier_turn_target_yaw, eased_t)
	if t >= 0.9999:
		rotation.y = _modifier_turn_target_yaw
		_modifier_turn_active = false
		_finish_modifier_turn()


func _finish_modifier_turn() -> void:
	var forward: Vector3 = _get_forward_direction()
	if forward.length() > 0.001:
		_last_move_dir = forward
		direction_changed.emit(forward)


func _update_sprint(input: IInputSource, params: MovementData3D, delta: float) -> void:
	if params == null:
		sprint_active = false
		sprint_timer = 0.0
		_run_tap_timer = 0.0
		_run_tap_count = 0
		return
	_run_tap_timer = 0.0
	_run_tap_count = 0
	var moving: bool = Vector2(input_x, input_y).length() > 0.05
	var modifier_held: bool = input.is_modifier_held()
	var forward_back_moving: bool = absf(input_y) >= clampf(modifier_forward_priority_deadzone, 0.0, 1.0)
	var wants_sprint: bool = params.sprint_enabled and modifier_held and moving and forward_back_moving and (not _modifier_action_consumed)
	sprint_active = wants_sprint
	if sprint_active:
		sprint_timer = maxf(params.sprint_boost_fade_time, 0.01)
	else:
		sprint_timer = maxf(0.0, sprint_timer - delta)


func _update_double_tap(input: IInputSource, params: MovementData3D, delta: float) -> void:
	double_tap_left = false
	double_tap_right = false
	if params.dash_allow_double_tap and _input_allowed() and can_move == 1:
		if input.is_move_left_just_pressed():
			if double_tap_timer_l > 0.0:
				double_tap_left = true
			double_tap_timer_l = params.dash_double_tap_window
		if input.is_move_right_just_pressed():
			if double_tap_timer_r > 0.0:
				double_tap_right = true
			double_tap_timer_r = params.dash_double_tap_window
	double_tap_timer_l = maxf(0.0, double_tap_timer_l - delta)
	double_tap_timer_r = maxf(0.0, double_tap_timer_r - delta)


func _update_ground_air_state(on_floor: bool, params: MovementData3D, delta: float) -> void:
	if on_floor:
		_floor_leave_timer = 0.0
		in_air = false
		falling = false
		jumping = false
		air_time = 0.0
		high_fall = false
		jump_count = 0
		wall_jumping = false
		can_double_jump = params.max_jumps > 1
		coyote_timer = params.coyote_time
		if _wall_jump_block_double_until_release:
			_wall_jump_block_double_until_release = false
	else:
		_floor_leave_timer += delta
		var leave_delay: float = maxf(params.floor_leave_delay, 0.0)
		var allow_delay: bool = leave_delay > 0.0 and (not jumping) and velocity.y <= 0.0
		if allow_delay and _floor_leave_timer < leave_delay:
			in_air = false
			falling = false
			air_time = 0.0
			coyote_timer = params.coyote_time
			if wall_jump_lock > 0.0:
				wall_jump_lock = maxf(0.0, wall_jump_lock - delta)
			return
		in_air = true
		air_time += delta
		falling = velocity.y < -0.01
		coyote_timer = maxf(0.0, coyote_timer - delta)
	if wall_jump_lock > 0.0:
		wall_jump_lock = maxf(0.0, wall_jump_lock - delta)
	if _wall_jump_block_double_until_release and jump_released:
		_wall_jump_block_double_until_release = false


func _update_speed_metrics(params: MovementData3D) -> void:
	var horiz := Vector2(velocity.x, velocity.z)
	speed_x = horiz.length()
	speed_y = velocity.y
	speed_x_abs = absf(speed_x)
	speed_y_abs = absf(speed_y)
	var run_threshold := params.run_speed * 0.9
	moving_at_speed = speed_x_abs > run_threshold
	if params.high_fall_speed > 0.0 and params.high_fall_time > 0.0:
		if in_air and falling and speed_y_abs > params.high_fall_speed and air_time > params.high_fall_time:
			high_fall = true


func _update_wall_state(params: MovementData3D, _delta: float) -> void:
	can_wall_jump = false
	wall_side = 0
	wall_jump_normal = Vector3.ZERO
	_debug_wall_left_hit_valid = false
	_debug_wall_right_hit_valid = false
	_debug_wall_best_hit_valid = false
	if not params.wall_jump_enabled:
		_update_wall_debug(params, false, false)
		return
	if wall_jump_lock > 0.0 and not (wall_jumping and wall_jump_allow_chain):
		_update_wall_debug(params, false, false)
		return
	if not in_air and not (wall_jumping and wall_jump_allow_chain):
		_update_wall_debug(params, false, false)
		return
	if params.wall_check_distance <= 0.0:
		_update_wall_debug(params, false, false)
		return
	var origin := global_transform.origin + Vector3.UP * params.wall_check_height
	var left_dir := -global_transform.basis.x
	var right_dir := global_transform.basis.x
	var left_hit: Dictionary = _raycast_wall_hit(origin, left_dir, params.wall_check_distance)
	var left_hit_valid := not left_hit.is_empty()
	if left_hit_valid:
		var left_normal: Vector3 = left_hit.get("normal", Vector3.ZERO)
		if not _is_non_walkable_surface(left_normal, params):
			left_hit_valid = false
	var right_hit: Dictionary = _raycast_wall_hit(origin, right_dir, params.wall_check_distance)
	var right_hit_valid := not right_hit.is_empty()
	if right_hit_valid:
		var right_normal: Vector3 = right_hit.get("normal", Vector3.ZERO)
		if not _is_non_walkable_surface(right_normal, params):
			right_hit_valid = false
	_debug_wall_left_origin = origin
	_debug_wall_right_origin = origin
	_debug_wall_left_dir = left_dir
	_debug_wall_right_dir = right_dir
	_debug_wall_left_hit_valid = left_hit_valid
	_debug_wall_right_hit_valid = right_hit_valid
	if left_hit_valid:
		_debug_wall_left_hit = left_hit.position
	if right_hit_valid:
		_debug_wall_right_hit = right_hit.position
	var origins := _get_wall_check_origins(params)
	var dirs := _get_wall_check_directions(params)
	var best_hit := _find_wall_contact(origins, dirs, params.wall_check_distance, params)
	if not best_hit.is_empty():
		_debug_wall_best_hit_valid = true
		_debug_wall_best_hit = best_hit.position
		_debug_wall_best_origin = best_hit.origin
		_debug_wall_best_dir = best_hit.dir
		can_wall_jump = true
		wall_jump_normal = best_hit.normal
		wall_jump_hit_point = best_hit.position
		var right_axis := _get_right_direction()
		if right_axis.length() > 0.001 and wall_jump_normal.length() > 0.001:
			wall_side = -1 if wall_jump_normal.dot(right_axis) > 0.0 else 1
	_update_wall_debug(params, left_hit_valid, right_hit_valid)


func _update_drop_through(input: IInputSource, params: MovementData3D, delta: float, on_floor: bool) -> void:
	if not _input_allowed():
		_clear_drop_through(params)
		return
	if falling_through:
		drop_through_timer = maxf(0.0, drop_through_timer - delta)
		if drop_through_timer <= 0.0:
			_clear_drop_through(params)
		return
	if not on_floor:
		return
	if params.drop_through_layer <= 0 or params.drop_through_time <= 0.0:
		return
	if input.is_jump_just_pressed() and input_y > 0.5:
		falling_through = true
		drop_through_timer = params.drop_through_time
		jump_buffer_timer = 0.0
		_set_drop_through_mask(params, false)
		if params.drop_through_speed > 0.0:
			velocity.y = -params.drop_through_speed


func _clear_drop_through(params: MovementData3D) -> void:
	if not falling_through:
		return
	falling_through = false
	drop_through_timer = 0.0
	_set_drop_through_mask(params, true)


func _set_drop_through_mask(params: MovementData3D, enabled: bool) -> void:
	if params.drop_through_layer <= 0:
		return
	var layer := params.drop_through_layer
	set_collision_mask_value(layer, enabled)
	_drop_through_masked = not enabled


func _update_dash(input: IInputSource, params: MovementData3D, delta: float, on_floor: bool) -> void:
	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - delta)
	var dash_input := Vector2(input_x, input_y)
	var dash_held := input.is_dash_held()
	if dashing:
		dash_timer = maxf(0.0, dash_timer - delta)
		if dash_held and dash_input.length() > 0.01:
			var steer_dir := _move_vector_to_dir(Vector2(input_x, input_y))
			if steer_dir.length() > 0.01:
				dash_direction = steer_dir
		if dash_timer <= 0.0:
			if dash_held and dash_input.length() > 0.01:
				dash_timer = params.dash_time
			else:
				dashing = false
		return
	if not _input_allowed() or can_move != 1:
		return
	if dash_cooldown_timer > 0.0:
		return
	var want_dash := input.is_dash_just_pressed() or (dash_held and dash_input.length() > 0.01)
	if not want_dash:
		return
	if on_floor and input_y > 0.5:
		return
	if not params.dash_allow_air and not on_floor:
		return
	if dash_input.length() <= 0.01:
		return
	_start_dash(params, _move_vector_to_dir(Vector2(input_x, input_y)))


func _start_dash(params: MovementData3D, move_dir: Vector3) -> void:
	dashing = true
	dash_timer = params.dash_time
	dash_cooldown_timer = params.dash_cooldown
	roll_active = false
	if move_dir.length() > 0.01:
		dash_direction = move_dir
	else:
		dash_direction = _get_forward_direction()


func _apply_dash_velocity(params: MovementData3D, on_floor: bool) -> void:
	var dir := dash_direction
	if dir.length() <= 0.001:
		dir = _get_forward_direction()
	dir = dir.normalized()
	velocity.x = dir.x * params.dash_speed
	velocity.z = dir.z * params.dash_speed
	if on_floor:
		velocity.y = minf(velocity.y, 0.0)


func _update_roll(input: IInputSource, params: MovementData3D, delta: float, on_floor: bool) -> void:
	roll_cooldown_timer = maxf(0.0, roll_cooldown_timer - delta)
	if roll_active:
		roll_timer = maxf(0.0, roll_timer - delta)
		if roll_timer <= 0.0:
			roll_active = false
			roll_base_speed = 0.0
			if can_move == 0:
				can_move = 1
		return
	if not _input_allowed() or can_move != 1:
		return
	if roll_cooldown_timer > 0.0:
		return
	if not on_floor:
		return
	var move_mag := Vector2(input_x, input_y).length()
	var wants_roll := input.is_crouch_just_pressed() and move_mag > 0.2
	if not wants_roll:
		return
	_start_roll(params, _get_forward_direction())


func _update_posture(input: IInputSource, on_floor: bool, params: MovementData3D) -> void:
	if not _input_allowed():
		_apply_crouch_state(false, params, 0.0)
		crouching = false
		sneaking = false
		return
	var crouch_requested := false
	if camera_context == CameraContext.SIDE_SCROLLER:
		_crouch_toggle_state = false
		if side_scroller_crouch_uses_side_down:
			crouch_requested = input_y > 0.5
		else:
			crouch_requested = input.is_crouch_held()
	else:
		if posture_crouch_toggle:
			if input.is_crouch_just_pressed():
				_crouch_toggle_state = not _crouch_toggle_state
		else:
			_crouch_toggle_state = input.is_crouch_held()
		crouch_requested = _crouch_toggle_state or input.is_sneak_held()
	var wants_crouch := false
	if dashing or roll_active:
		wants_crouch = false
		sneaking = false
	else:
		# Keep crouch stable across tiny ground-contact drops caused by collider resizing/slope seams.
		var stable_grounded: bool = on_floor or coyote_timer > 0.0 or (not falling and velocity.y <= 0.05)
		wants_crouch = crouch_requested and (stable_grounded or crouching)
		sneaking = false
	if not wants_crouch and crouching:
		if not _can_stand_up(params):
			wants_crouch = true
	var move_mag := Vector2(input_x, input_y).length()
	_apply_crouch_state(wants_crouch, params, move_mag)
	crouching = wants_crouch


func _cache_crouch_collider() -> void:
	_ensure_crouch_cache()
	_crouch_target_total_height = _get_current_collider_total_height()
	_crouch_transition_speed = 0.0


func _apply_crouch_state(should_crouch: bool, params: MovementData3D, move_mag: float) -> void:
	var data: MovementData3D = params
	if data == null:
		data = _get_movement_params()
	_ensure_crouch_cache()
	if _crouch_collider_kind == COLLIDER_KIND_NONE:
		_crouch_applied = should_crouch
		return
	var target_height: float = _get_stand_total_height()
	var transition_time_override := 0.0
	if should_crouch:
		var desired_height := _get_crouch_desired_height(data, move_mag)
		transition_time_override = _get_crouch_transition_time(data, move_mag)
		target_height = _get_crouch_total_height_for_value(data, desired_height)
	else:
		transition_time_override = maxf(data.crouch_stand_transition_time, 0.0)
	if target_height <= 0.0:
		_crouch_applied = should_crouch
		return
	if _crouch_applied == should_crouch and absf(target_height - _crouch_target_total_height) <= 0.001:
		return
	var current_height: float = _get_current_collider_total_height()
	var transition_time: float = maxf(transition_time_override, 0.0)
	if current_height <= 0.0 or transition_time <= 0.0:
		_apply_collider_height(target_height)
		_apply_pivot_defaults()
		_crouch_target_total_height = target_height
		_crouch_transition_speed = 0.0
	else:
		_crouch_target_total_height = target_height
		_crouch_transition_speed = absf(target_height - current_height) / maxf(transition_time, 0.001)
	_crouch_applied = should_crouch


func _ensure_crouch_cache() -> void:
	var collision := _get_collision_shape_node()
	if collision == null or collision.shape == null:
		_collision_shape_node = collision
		_crouch_collider_kind = COLLIDER_KIND_NONE
		_crouch_cached = true
		return
	if _crouch_cached and _collision_shape_node == collision:
		return
	_collision_shape_node = collision
	_crouch_cached = true
	var shape: Shape3D = collision.shape
	if shape is CapsuleShape3D:
		var capsule := shape as CapsuleShape3D
		_crouch_collider_kind = COLLIDER_KIND_CAPSULE
		_stand_capsule_height = capsule.height
		_stand_capsule_radius = capsule.radius
	elif shape is BoxShape3D:
		var box := shape as BoxShape3D
		_crouch_collider_kind = COLLIDER_KIND_BOX
		_stand_box_size = box.size
	elif shape is CylinderShape3D:
		var cylinder := shape as CylinderShape3D
		_crouch_collider_kind = COLLIDER_KIND_CYLINDER
		_stand_cylinder_height = cylinder.height
		_stand_cylinder_radius = cylinder.radius
	else:
		_crouch_collider_kind = COLLIDER_KIND_NONE


func _can_stand_up(params: MovementData3D) -> bool:
	if params == null:
		return true
	_ensure_crouch_cache()
	if _crouch_collider_kind == COLLIDER_KIND_NONE:
		return true
	var collision := _collision_shape_node
	if collision == null or collision.shape == null:
		return true
	var stand_height: float = _get_stand_total_height()
	var current_height: float = _get_shape_height(collision.shape)
	if stand_height <= 0.0 or stand_height <= current_height + 0.001:
		return true
	var query_shape := _build_shape_for_height(stand_height)
	if query_shape == null:
		return true
	var world := get_world_3d()
	if world == null:
		return true
	var space := world.direct_space_state
	if space == null:
		return true
	var bottom := collision.global_transform.origin - Vector3.UP * (current_height * 0.5)
	var center := bottom + Vector3.UP * (stand_height * 0.5)
	var xform := collision.global_transform
	xform.origin = center
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = query_shape
	query.transform = xform
	query.collision_mask = collision_mask
	var exclude: Array = [get_rid()]
	var floor_obj: Object = _get_floor_collider()
	if floor_obj == null:
		floor_obj = _get_floor_collider_beneath()
	if floor_obj is CollisionObject3D:
		exclude.append((floor_obj as CollisionObject3D).get_rid())
	query.exclude = exclude
	query.collide_with_areas = false
	query.collide_with_bodies = true
	# Lift the stand-up probe slightly to avoid floor contact being treated as overhead block.
	query.transform.origin += Vector3.UP * 0.02
	var hits: Array = space.intersect_shape(query, 1)
	return hits.is_empty()


func _get_floor_collider() -> Object:
	var count: int = get_slide_collision_count()
	if count <= 0:
		return null
	var best_dot: float = 0.0
	var best: Object = null
	for i in range(count):
		var collision: KinematicCollision3D = get_slide_collision(i)
		if collision == null:
			continue
		var normal: Vector3 = collision.get_normal()
		var dot: float = normal.dot(Vector3.UP)
		if dot < 0.6:
			continue
		if dot > best_dot:
			best_dot = dot
			best = collision.get_collider()
	return best


func _get_floor_collider_beneath() -> Object:
	var collision: CollisionShape3D = _get_collision_shape_node()
	if collision == null or collision.shape == null:
		return null
	var world := get_world_3d()
	if world == null:
		return null
	var space := world.direct_space_state
	if space == null:
		return null
	var shape_height: float = _get_shape_height(collision.shape)
	var start: Vector3 = collision.global_transform.origin + Vector3.UP * 0.05
	var cast_len: float = maxf(0.3, shape_height * 0.6)
	var finish: Vector3 = start + Vector3.DOWN * cast_len
	var ray := PhysicsRayQueryParameters3D.create(start, finish)
	ray.exclude = [get_rid()]
	ray.collision_mask = collision_mask
	ray.collide_with_areas = false
	ray.collide_with_bodies = true
	var hit: Dictionary = space.intersect_ray(ray)
	if hit.is_empty():
		return null
	var collider: Variant = hit.get("collider", null)
	if collider is Object:
		return collider as Object
	return null


func _get_stand_total_height() -> float:
	match _crouch_collider_kind:
		COLLIDER_KIND_CAPSULE:
			return _stand_capsule_height + _stand_capsule_radius * 2.0
		COLLIDER_KIND_BOX:
			return _stand_box_size.y
		COLLIDER_KIND_CYLINDER:
			return _stand_cylinder_height
	return 0.0


func _get_crouch_desired_height(params: MovementData3D, move_mag: float) -> float:
	if roll_active:
		if params.roll_crouch_height > 0.0:
			return params.roll_crouch_height
		return params.crouch_height
	if move_mag > params.crouch_walk_move_threshold and params.crouch_walk_height > 0.0:
		return params.crouch_walk_height
	return params.crouch_height


func _get_crouch_transition_time(params: MovementData3D, move_mag: float) -> float:
	if roll_active:
		if params.roll_crouch_transition_time > 0.0:
			return params.roll_crouch_transition_time
		return params.crouch_transition_time
	if move_mag > params.crouch_walk_move_threshold and params.crouch_walk_transition_time > 0.0:
		return params.crouch_walk_transition_time
	return params.crouch_transition_time


func _get_crouch_total_height_for_value(params: MovementData3D, desired_height: float) -> float:
	var stand_height: float = _get_stand_total_height()
	if stand_height <= 0.0:
		return 0.0
	var target: float = desired_height
	if target <= 0.0:
		target = stand_height * 0.6
	elif target <= 1.0:
		# Treat 0..1 as a ratio of standing height for ergonomic tuning.
		target = stand_height * target
	var min_total_height: float = 0.1
	if _crouch_collider_kind == COLLIDER_KIND_CAPSULE:
		# Keep some cylinder section so the capsule does not collapse into a sphere.
		min_total_height = _stand_capsule_radius * 2.0 + 0.2
	target = clampf(target, min_total_height, stand_height)
	return target


func _apply_collider_height(target_height: float) -> void:
	var collision := _collision_shape_node
	if collision == null or collision.shape == null:
		return
	match _crouch_collider_kind:
		COLLIDER_KIND_CAPSULE:
			var capsule := collision.shape as CapsuleShape3D
			if capsule == null:
				return
			var cap_height: float = maxf(0.0, target_height - _stand_capsule_radius * 2.0)
			capsule.height = cap_height
		COLLIDER_KIND_BOX:
			var box := collision.shape as BoxShape3D
			if box == null:
				return
			var size := _stand_box_size
			size.y = target_height
			box.size = size
		COLLIDER_KIND_CYLINDER:
			var cylinder := collision.shape as CylinderShape3D
			if cylinder == null:
				return
			cylinder.height = target_height


func _build_shape_for_height(target_height: float) -> Shape3D:
	match _crouch_collider_kind:
		COLLIDER_KIND_CAPSULE:
			var capsule := CapsuleShape3D.new()
			capsule.radius = _stand_capsule_radius
			capsule.height = maxf(0.0, target_height - _stand_capsule_radius * 2.0)
			return capsule
		COLLIDER_KIND_BOX:
			var box := BoxShape3D.new()
			box.size = Vector3(_stand_box_size.x, target_height, _stand_box_size.z)
			return box
		COLLIDER_KIND_CYLINDER:
			var cylinder := CylinderShape3D.new()
			cylinder.radius = _stand_cylinder_radius
			cylinder.height = target_height
			return cylinder
	return null


func _get_current_collider_total_height() -> float:
	var collision := _collision_shape_node
	if collision == null or collision.shape == null:
		return 0.0
	return _get_shape_height(collision.shape)


func _get_collision_extents() -> Vector3:
	var collision := _get_collision_shape_node()
	if collision == null or collision.shape == null:
		return Vector3.ZERO
	var shape: Shape3D = collision.shape
	var scale: Vector3 = collision.global_transform.basis.get_scale()
	if shape is BoxShape3D:
		var box := shape as BoxShape3D
		return Vector3(box.size.x * 0.5 * scale.x, box.size.y * 0.5 * scale.y, box.size.z * 0.5 * scale.z)
	if shape is CapsuleShape3D:
		var capsule := shape as CapsuleShape3D
		var radius: float = capsule.radius * maxf(scale.x, scale.z)
		var half_height: float = (capsule.height * 0.5 + capsule.radius) * scale.y
		return Vector3(radius, half_height, radius)
	if shape is CylinderShape3D:
		var cylinder := shape as CylinderShape3D
		var radius2: float = cylinder.radius * maxf(scale.x, scale.z)
		var half_height2: float = cylinder.height * 0.5 * scale.y
		return Vector3(radius2, half_height2, radius2)
	if shape is SphereShape3D:
		var sphere := shape as SphereShape3D
		var max_scale: float = maxf(maxf(scale.x, scale.y), scale.z)
		var rad: float = sphere.radius * max_scale
		return Vector3(rad, rad, rad)
	return Vector3.ZERO


func _update_crouch_transition(params: MovementData3D, delta: float) -> void:
	if _crouch_target_total_height <= 0.0:
		return
	var current_height: float = _get_current_collider_total_height()
	if current_height <= 0.0:
		return
	if absf(current_height - _crouch_target_total_height) <= 0.001:
		_crouch_transition_speed = 0.0
		return
	var step: float = _crouch_transition_speed * delta
	if step <= 0.0:
		if params and params.crouch_transition_time > 0.0:
			step = absf(current_height - _crouch_target_total_height) / maxf(params.crouch_transition_time, 0.001) * delta
		else:
			step = absf(current_height - _crouch_target_total_height)
	var next_height: float = move_toward(current_height, _crouch_target_total_height, step)
	_apply_collider_height(next_height)
	_apply_pivot_defaults()


func _start_roll(params: MovementData3D, dir: Vector3) -> void:
	roll_active = true
	roll_timer = params.roll_time
	roll_cooldown_timer = params.roll_cooldown
	can_move = 0
	dashing = false
	jump_buffer_timer = 0.0
	jump_released = false
	roll_direction = dir.normalized() if dir.length() > 0.01 else _get_forward_direction()
	var current_speed: float = Vector2(velocity.x, velocity.z).length()
	roll_base_speed = maxf(params.roll_speed, current_speed)


func _apply_roll_velocity(params: MovementData3D, on_floor: bool) -> void:
	var dir := roll_direction
	if dir.length() <= 0.001:
		dir = _get_forward_direction()
	dir = dir.normalized()
	var roll_speed_value: float = params.roll_speed
	if roll_base_speed > roll_speed_value:
		roll_speed_value = roll_base_speed
	velocity.x = dir.x * roll_speed_value
	velocity.z = dir.z * roll_speed_value
	if on_floor:
		velocity.y = minf(velocity.y, 0.0)


func _get_target_speed(params: MovementData3D, _input: IInputSource) -> float:
	if crouching:
		run_active = false
		return maxf(params.crouch_speed, 0.0)
	var move_mag: float = clampf(Vector2(input_x, input_y).length(), 0.0, 1.0)
	var max_speed: float = maxf(maxf(params.run_speed, params.walk_speed), 0.0)
	var walk_speed: float = clampf(params.walk_speed, 0.0, max_speed)
	var speed: float = move_mag * max_speed
	run_active = speed > (walk_speed + 0.01)
	if sprint_active:
		var boost_mult: float = maxf(params.sprint_boost_multiplier, 1.0)
		if params.sprint_boost_fade_time > 0.0:
			var fade_t: float = clampf(sprint_timer / params.sprint_boost_fade_time, 0.0, 1.0)
			boost_mult = lerpf(1.0, boost_mult, fade_t)
		speed *= boost_mult
	if dashing:
		speed = maxf(speed, params.dash_speed)
	return speed


func _apply_walk_velocity(desired: Vector3, params: MovementData3D, on_floor: bool, delta: float) -> void:
	var accel := params.acceleration
	var decel := params.deceleration
	var control := 1.0
	if not on_floor:
		accel = params.air_accel
		decel = params.air_decel
		control = params.air_control
	var step := accel if desired.length() > 0.0 else decel
	step *= control
	velocity.x = move_toward(velocity.x, desired.x, step * delta)
	velocity.z = move_toward(velocity.z, desired.z, step * delta)
	if on_floor and crouching and params.crouch_speed > 0.0:
		var horiz := Vector2(velocity.x, velocity.z)
		var max_crouch: float = params.crouch_speed
		if horiz.length() > max_crouch:
			horiz = horiz.normalized() * max_crouch
			velocity.x = horiz.x
			velocity.z = horiz.y


func _get_collision_shape_node() -> CollisionShape3D:
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		return null
	if collision.shape:
		var shape: Shape3D = collision.shape
		if not shape.resource_local_to_scene:
			var dup: Shape3D = shape.duplicate()
			dup.resource_local_to_scene = true
			collision.shape = dup
	return collision


func _apply_jump_logic(params: MovementData3D, on_floor: bool) -> void:
	if can_move != 1 or not _input_allowed():
		return
	if params.wall_jump_enabled:
		if _wall_jump_block_double_until_release:
			if jump_released or on_floor:
				_wall_jump_block_double_until_release = false
			else:
				return
		var want_jump_now := _get_input_source().is_jump_just_pressed() or _wall_jump_chain_requested or jump_buffer_timer > 0.0
		if (not on_floor) and want_jump_now and (not can_wall_jump) and (not wall_jumping):
			if _try_wall_jump_chain(params):
				_wall_jump_chain_requested = false
				jump_buffer_timer = 0.0
				_start_wall_jump(params)
				return
		if can_wall_jump or wall_jumping:
			var want_chain := _wall_jump_chain_requested
			var want_jump := _get_input_source().is_jump_just_pressed() or want_chain or jump_buffer_timer > 0.0
			if wall_jumping and wall_jump_allow_chain and want_jump and not can_wall_jump:
				if _try_wall_jump_chain(params):
					_wall_jump_chain_requested = false
					jump_buffer_timer = 0.0
					_start_wall_jump(params)
					return
			if can_wall_jump and wall_side != 0 and want_jump:
				_wall_jump_chain_requested = false
				jump_buffer_timer = 0.0
				_start_wall_jump(params)
			return
	if jump_buffer_timer <= 0.0:
		return
	if on_floor or coyote_timer > 0.0:
		_start_jump(params.jump_speed)
		return
	if can_double_jump and jump_count < params.max_jumps and jump_released and not _wall_jump_block_double_until_release:
		var speed := params.double_jump_speed
		if speed <= 0.0:
			speed = params.jump_speed
		if params.double_jump_clamp_fall_speed > 0.0 and velocity.y < -params.double_jump_clamp_fall_speed:
			velocity.y = -params.double_jump_clamp_fall_speed
		_start_jump(speed)
		can_double_jump = false


func _start_jump(speed: float) -> void:
	velocity.y = speed
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	jump_released = false
	jump_count += 1
	jumping = true
	in_air = true
	jumped.emit()


func _start_wall_jump(params: MovementData3D) -> void:
	_wall_jump_pre_yaw = rotation.y
	var normal_copy := wall_jump_normal
	if normal_copy.length() <= 0.001:
		return
	var push_dir := normal_copy
	push_dir.y = 0.0
	if push_dir.length() <= 0.001:
		return
	push_dir = push_dir.normalized()
	var up_force := params.wall_jump_up_speed
	var back_force := params.wall_jump_push_speed
	var jump_vec := push_dir * back_force + Vector3.UP * up_force
	if jump_vec.length() <= 0.001:
		jump_vec = Vector3.UP * maxf(up_force, 0.01)
	_wall_jump_turn_dir = push_dir
	_wall_jump_turn_active = push_dir.length() > 0.001
	if _wall_jump_turn_active:
		_wall_jump_turn_yaw = _wall_jump_get_target_yaw(push_dir)
	_wall_jump_force_velocity = Vector3(jump_vec.x, 0.0, jump_vec.z)
	_wall_jump_no_input_timer = maxf(0.0, params.wall_jump_no_input_time)
	_wall_jump_force_timer = maxf(0.0, params.wall_jump_duration)
	_wall_jump_force_total_time = _wall_jump_force_timer
	_wall_jump_restore_timer = 0.0
	_wall_jump_post_align_timer = 0.0
	_wall_jump_post_align_done = false
	_wall_jump_block_double_until_release = false
	jump_released = false
	_wall_jump_control_fix_timer = 0.0
	if wall_jump_camera_focus_time > 0.0:
		var orbit := _find_orbit_camera()
		if orbit and orbit.has_method("focus_at_point"):
			var focus_pos := wall_jump_hit_point
			if wall_jump_normal.length() > 0.001:
				focus_pos = wall_jump_hit_point - wall_jump_normal.normalized() * wall_jump_camera_focus_offset
			orbit.call("focus_at_point", focus_pos, wall_jump_camera_focus_time)
	if debug_wall_jump_snapshot:
		_print_wall_jump_snapshot(params)
	if wall_jump_pre_rotate and push_dir.length() > 0.001:
		_wall_jump_pre_rotate_target_yaw = _wall_jump_get_target_yaw(push_dir)
		_wall_jump_pre_rotate_timer = maxf(wall_jump_pre_rotate_time, 0.0)
		_wall_jump_pre_rotating = true
		_wall_jump_pending_velocity = jump_vec
		wall_jumping = false
	else:
		velocity = jump_vec
		wall_jumping = true
	can_wall_jump = false
	wall_side = 0
	wall_jump_normal = Vector3.ZERO
	wall_jump_hit_point = Vector3.ZERO
	wall_jump_lock = params.wall_jump_lock_time
	jump_buffer_timer = 0.0
	coyote_timer = 0.0
	jump_released = false
	jump_count = 1
	jumping = true
	in_air = true
	jumped.emit()
	if _anim_driver:
		_anim_driver.set_state("wall_jump")
	if debug_wall_jump:
		print("WallJump start: normal=", normal_copy, " push_dir=", push_dir, " yaw=", rad_to_deg(_wall_jump_turn_yaw))

func _print_wall_jump_snapshot(params: MovementData3D) -> void:
	var orbit := _find_orbit_camera()
	var orbit_path := "<null>"
	if orbit:
		orbit_path = String(orbit.get_path())
	print("WallJump snapshot:",
		" enabled=", params.wall_jump_enabled,
		" up=", params.wall_jump_up_speed,
		" back=", params.wall_jump_push_speed,
		" no_input=", params.wall_jump_no_input_time,
		" duration=", params.wall_jump_duration,
		" lock=", params.wall_jump_lock_time,
		" rotate_actor=", wall_jump_rotate_actor,
		" rotate_camera=", wall_jump_rotate_camera,
		" pre_rotate=", wall_jump_pre_rotate,
		" pre_rotate_time=", wall_jump_pre_rotate_time,
		" flip_dir=", wall_jump_turn_flip_dir,
		" turn_blend=", wall_jump_turn_blend_time,
		" restore=", wall_jump_restore_yaw,
		" restore_time=", wall_jump_restore_time,
		" align_end=", wall_jump_align_to_camera_on_end,
		" align_time=", wall_jump_align_to_camera_time,
		" control_fix=", wall_jump_control_fix_time,
		" flip_input=", wall_jump_flip_input_by_camera,
		" allow_chain=", wall_jump_allow_chain,
		" cam_focus=", wall_jump_camera_focus_time,
		" cam_focus_offset=", wall_jump_camera_focus_offset,
		" cam_recenter=", wall_jump_camera_recenter_time,
		" force_recenter=", wall_jump_force_recenter_on_end,
		" orbit=", orbit_path)


func _apply_gravity(params: MovementData3D, on_floor: bool, delta: float) -> void:
	if on_floor:
		if velocity.y < 0.0:
			velocity.y = 0.0
		return
	var gravity_scale := 1.0
	velocity.y -= params.gravity * gravity_scale * delta
	if velocity.y < -params.max_fall_speed:
		velocity.y = -params.max_fall_speed


func _raycast_wall(origin: Vector3, direction: Vector3, distance: float) -> bool:
	if distance <= 0.0:
		return false
	var dir := direction
	dir.y = 0.0
	if dir.length() <= 0.001:
		return false
	dir = dir.normalized()
	var world := get_world_3d()
	if world == null:
		return false
	var space := world.direct_space_state
	if space == null:
		return false
	var params := PhysicsRayQueryParameters3D.create(origin, origin + dir * distance)
	params.collision_mask = collision_mask
	params.exclude = [self]
	var hit: Dictionary = space.intersect_ray(params)
	return not hit.is_empty()


func _raycast_wall_hit(origin: Vector3, direction: Vector3, distance: float) -> Dictionary:
	if distance <= 0.0:
		return {}
	var dir := direction
	dir.y = 0.0
	if dir.length() <= 0.001:
		return {}
	dir = dir.normalized()
	var world := get_world_3d()
	if world == null:
		return {}
	var space := world.direct_space_state
	if space == null:
		return {}
	var params := PhysicsRayQueryParameters3D.create(origin, origin + dir * distance)
	params.collision_mask = collision_mask
	params.exclude = [self]
	var hit: Dictionary = space.intersect_ray(params)
	return hit


func _get_wall_check_origins(params: MovementData3D) -> Array[Vector3]:
	var origins: Array[Vector3] = []
	var base := global_transform.origin
	var extents: Vector3 = _get_collision_extents()
	var check_height := maxf(params.wall_check_height, 0.0)
	var low := maxf(0.05, minf(check_height if check_height > 0.0 else 0.2, extents.y * 0.5))
	var high := maxf(check_height, extents.y * 0.9)
	origins.append(base + Vector3.UP * low)
	if absf(high - low) > 0.05:
		origins.append(base + Vector3.UP * high)
	return origins


func _get_wall_check_directions(params: MovementData3D) -> Array[Vector3]:
	var forward := -global_transform.basis.z
	if camera_context == CameraContext.FIRST_PERSON and first_person_move_relative_to_camera:
		var cam_forward := _get_first_person_aim_forward()
		if cam_forward.length() > 0.001:
			forward = cam_forward
	forward.y = 0.0
	if forward.length() <= 0.001:
		forward = Vector3.FORWARD
	else:
		forward = forward.normalized()
	var right := forward.cross(Vector3.UP)
	if right.length() <= 0.001:
		right = global_transform.basis.x
	right.y = 0.0
	if right.length() <= 0.001:
		right = Vector3.RIGHT
	else:
		right = right.normalized()
	var dirs: Array[Vector3] = [right, -right]
	var use_multi := true
	var allow_forward := true
	var allow_diagonals := true
	if params:
		use_multi = params.wall_check_multi_ray
		allow_forward = params.wall_check_forward
		allow_diagonals = params.wall_check_diagonals
	if use_multi and allow_forward:
		dirs.append(forward)
		dirs.append(-forward)
	if use_multi and allow_diagonals:
		var diag1 := forward + right
		if diag1.length() > 0.001:
			dirs.append(diag1.normalized())
		var diag2 := forward - right
		if diag2.length() > 0.001:
			dirs.append(diag2.normalized())
		var diag3 := -forward + right
		if diag3.length() > 0.001:
			dirs.append(diag3.normalized())
		var diag4 := -forward - right
		if diag4.length() > 0.001:
			dirs.append(diag4.normalized())
	return dirs


func _find_wall_contact(origins: Array[Vector3], dirs: Array[Vector3], distance: float, params: MovementData3D) -> Dictionary:
	var best: Dictionary = {}
	var best_dist: float = distance + 1.0
	for origin in origins:
		for dir in dirs:
			var hit: Dictionary = _raycast_wall_hit(origin, dir, distance)
			if hit.is_empty():
				continue
			var normal: Vector3 = hit.get("normal", Vector3.ZERO)
			if not _is_non_walkable_surface(normal, params):
				continue
			var pos: Vector3 = hit.get("position", origin + dir * distance)
			var dist: float = origin.distance_to(pos)
			if dist < best_dist:
				best_dist = dist
				best = {"normal": normal, "position": pos, "origin": origin, "dir": dir}
	return best


func _try_wall_jump_chain(params: MovementData3D) -> bool:
	if params == null:
		return false
	if params.wall_check_distance <= 0.0:
		return false
	var origins := _get_wall_check_origins(params)
	var dirs := _get_wall_check_directions(params)
	var best_hit := _find_wall_contact(origins, dirs, params.wall_check_distance, params)
	if best_hit.is_empty():
		return false
	can_wall_jump = true
	wall_jump_normal = best_hit.normal
	wall_jump_hit_point = best_hit.position
	var right_axis := _get_right_direction()
	if right_axis.length() > 0.001 and wall_jump_normal.length() > 0.001:
		wall_side = -1 if wall_jump_normal.dot(right_axis) > 0.0 else 1
	return wall_side != 0


func _is_non_walkable_surface(normal: Vector3, params: MovementData3D) -> bool:
	if normal == Vector3.ZERO:
		return false
	var slope_limit := 45.0
	if params:
		slope_limit = params.max_slope_angle
	if slope_limit <= 0.0:
		slope_limit = 45.0
	var angle := rad_to_deg(Vector3.UP.angle_to(normal))
	return angle > slope_limit


func _get_forward_direction() -> Vector3:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length() > 0.001:
		forward = forward.normalized()
	return forward


func _get_right_direction() -> Vector3:
	var right := global_transform.basis.x
	right.y = 0.0
	if right.length() > 0.001:
		right = right.normalized()
	return right


func _move_vector_to_dir(move: Vector2) -> Vector3:
	return _get_move_direction(move)


func _update_landing_state() -> void:
	var on_floor := is_on_floor()
	if on_floor and not _was_on_floor:
		landed.emit()
	_was_on_floor = on_floor


func _update_move_dir(desired: Vector3) -> void:
	var dir := Vector3(desired.x, 0.0, desired.z)
	if dir.length() > 0.01:
		dir = dir.normalized()
		if dir != _last_move_dir:
			_last_move_dir = dir
			direction_changed.emit(dir)


func _get_move_direction(move: Vector2) -> Vector3:
	var fixed_move := _apply_wall_jump_control_fix(move)
	match camera_context:
		CameraContext.SIMPLE_THIRD_PERSON:
			return _get_simple_third_person_direction(fixed_move)
		CameraContext.FIRST_PERSON:
			return _get_first_person_direction(fixed_move)
		CameraContext.SIDE_SCROLLER:
			return _get_side_scroller_direction(fixed_move)
	return _get_world_direction(fixed_move)


func _get_first_person_direction(move: Vector2) -> Vector3:
	if move.length() <= 0.001:
		return Vector3.ZERO
	var input_vec := Vector2(move.x, -move.y)
	var basis: Basis = global_transform.basis
	if first_person_move_relative_to_camera:
		var aim_forward := _get_first_person_aim_forward()
		var forward_from_aim := aim_forward
		forward_from_aim.y = 0.0
		if forward_from_aim.length() > 0.001:
			forward_from_aim = forward_from_aim.normalized()
			var right_from_aim := forward_from_aim.cross(Vector3.UP)
			if right_from_aim.length() > 0.001:
				right_from_aim = right_from_aim.normalized()
			if first_person_flip_camera_right_axis:
				right_from_aim = -right_from_aim
			var forward_sign := -1.0 if first_person_invert_forward else 1.0
			var strafe_sign := -1.0 if first_person_invert_strafe else 1.0
			var dir_from_aim := right_from_aim * (input_vec.x * strafe_sign) + forward_from_aim * (input_vec.y * forward_sign)
			if dir_from_aim.length() > 1.0:
				dir_from_aim = dir_from_aim.normalized()
			return dir_from_aim
	var forward: Vector3 = -basis.z
	var right: Vector3 = basis.x
	if first_person_invert_forward:
		forward = -forward
	if first_person_invert_strafe:
		right = -right
	forward.y = 0.0
	right.y = 0.0
	if forward.length() > 0.001:
		forward = forward.normalized()
	if right.length() > 0.001:
		right = right.normalized()
	var dir: Vector3 = right * input_vec.x + forward * input_vec.y
	if dir.length() > 1.0:
		dir = dir.normalized()
	return dir


func _get_side_scroller_direction(move: Vector2) -> Vector3:
	var dir := Vector3.ZERO
	if absf(move.x) > 0.001:
		if side_scroller_use_camera_space:
			var basis := _get_side_scroller_camera_basis()
			var right := basis.x
			if right.length() > 0.001:
				right = right.normalized()
			dir += right * move.x
		else:
			var axis := _get_side_scroller_axis_dir()
			dir += axis * move.x
	if absf(move.y) > 0.001 and side_scroller_use_camera_space and side_scroller_allow_depth:
		var basis_z := _get_side_scroller_camera_basis()
		var forward := -basis_z.z
		if forward.length() > 0.001:
			forward = forward.normalized()
		var depth_sign := -1.0 if side_scroller_invert_depth else 1.0
		dir += forward * move.y * depth_sign
	if side_scroller_allow_depth:
		var depth_input := 0.0
		var src := _get_input_source()
		if src and src.has_method("get_depth_axis"):
			depth_input = src.get_depth_axis()
		if absf(depth_input) > 0.001:
			if side_scroller_use_camera_space:
				var basis_z := _get_side_scroller_camera_basis()
				var forward := -basis_z.z
				if forward.length() > 0.001:
					forward = forward.normalized()
				var depth_sign2 := -1.0 if side_scroller_invert_depth else 1.0
				dir += forward * depth_input * depth_sign2
			else:
				var depth_axis := _get_side_scroller_depth_axis_dir()
				var depth_sign3 := -1.0 if side_scroller_invert_depth else 1.0
				dir += depth_axis * depth_input * depth_sign3
	if dir.length() > 1.0:
		dir = dir.normalized()
	return dir


func _get_side_scroller_axis_dir() -> Vector3:
	var axes := _get_side_scroller_axes_mode()
	match axes:
		SideScrollerAxes.XZ:
			return Vector3.RIGHT
		SideScrollerAxes.XY:
			return Vector3.RIGHT
		_:
			return Vector3.FORWARD


func _get_side_scroller_depth_axis_dir() -> Vector3:
	var axes := _get_side_scroller_axes_mode()
	match axes:
		SideScrollerAxes.XZ:
			return Vector3.UP
		SideScrollerAxes.XY:
			return Vector3.FORWARD
		_:
			return Vector3.RIGHT


func _get_side_scroller_camera_basis() -> Basis:
	var cam: Node3D = _find_orbit_camera() as Node3D
	if cam == null:
		var vp_cam := get_viewport().get_camera_3d()
		if vp_cam and vp_cam is Node3D:
			cam = vp_cam
	if cam:
		return cam.global_transform.basis
	return global_transform.basis


func _get_side_scroller_depth_input() -> float:
	if not side_scroller_allow_depth:
		return 0.0
	var src := _get_input_source()
	if src and src.has_method("get_depth_axis"):
		return float(src.get_depth_axis())
	return 0.0


func _apply_side_scroller_plane_lock() -> void:
	if camera_context != CameraContext.SIDE_SCROLLER:
		_side_scroller_plane_anchor_set = false
		return
	if not side_scroller_plane_lock:
		return
	var normal := Vector3.ZERO
	if side_scroller_use_camera_space:
		normal = -_get_side_scroller_camera_basis().z
	else:
		normal = _get_side_scroller_depth_axis_dir()
	if normal.length() <= 0.001:
		return
	normal = normal.normalized()
	var depth_input := _get_side_scroller_depth_input()
	var depth_active := absf(depth_input) > side_scroller_depth_deadzone or absf(input_y) > side_scroller_depth_deadzone
	if depth_active:
		_side_scroller_plane_anchor = global_transform.origin
		_side_scroller_plane_anchor_set = true
		return
	if not _side_scroller_plane_anchor_set:
		_side_scroller_plane_anchor = global_transform.origin
		_side_scroller_plane_anchor_set = true
	# Remove any movement along the camera forward axis.
	var v := velocity
	velocity = v - normal * v.dot(normal)
	var pos := global_transform.origin
	var delta := pos - _side_scroller_plane_anchor
	pos -= normal * delta.dot(normal)
	global_transform.origin = pos


func _apply_side_scroller_velocity_lock() -> void:
	if camera_context != CameraContext.SIDE_SCROLLER:
		return
	if not side_scroller_plane_lock:
		return
	var normal := Vector3.ZERO
	if side_scroller_use_camera_space:
		normal = -_get_side_scroller_camera_basis().z
	else:
		normal = _get_side_scroller_depth_axis_dir()
	if normal.length() <= 0.001:
		return
	normal = normal.normalized()
	var depth_input := _get_side_scroller_depth_input()
	if absf(depth_input) > side_scroller_depth_deadzone:
		return
	velocity = velocity - normal * velocity.dot(normal)


func _get_side_scroller_axes_mode() -> SideScrollerAxes:
	if camera_context == CameraContext.SIDE_SCROLLER:
		var orbit := _find_orbit_camera()
		if orbit and "side_scroller_axes" in orbit:
			return orbit.get("side_scroller_axes")
	return side_scroller_axes


func _get_simple_third_person_direction(move: Vector2) -> Vector3:
	if move.length() <= 0.001:
		return Vector3.ZERO
	var input_vec := Vector2(move.x, -move.y)
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length() > 0.001:
		forward = forward.normalized()
	return forward * input_vec.y


func _apply_wall_jump_control_fix(move: Vector2) -> Vector2:
	if _wall_jump_control_fix_timer <= 0.0:
		return move
	if not wall_jump_flip_input_by_camera:
		return move
	if camera_context != CameraContext.SIMPLE_THIRD_PERSON:
		return move
	var cam := _find_orbit_camera() as Node3D
	if cam == null:
		return move
	var cam_forward := -cam.global_transform.basis.z
	cam_forward.y = 0.0
	var actor_forward := -global_transform.basis.z
	actor_forward.y = 0.0
	if cam_forward.length() <= 0.001 or actor_forward.length() <= 0.001:
		return move
	cam_forward = cam_forward.normalized()
	actor_forward = actor_forward.normalized()
	if cam_forward.dot(actor_forward) < 0.0:
		return Vector2(move.x, -move.y)
	return move


func _get_world_direction(move: Vector2) -> Vector3:
	if move.length() <= 0.001:
		return Vector3.ZERO
	var input_vec := Vector2(move.x, -move.y)
	var forward := Vector3.FORWARD
	var right := Vector3.RIGHT
	var dir := right * input_vec.x + forward * input_vec.y
	if dir.length() > 1.0:
		dir = dir.normalized()
	return dir


func _apply_turning(move: Vector2, move_dir: Vector3, params: MovementData3D, delta: float) -> void:
	match camera_context:
		CameraContext.SIMPLE_THIRD_PERSON:
			_apply_simple_third_person_turn(move, move_dir, params, delta)
		CameraContext.FIRST_PERSON:
			_apply_first_person_turn(move_dir, params, delta)
		CameraContext.SIDE_SCROLLER:
			_apply_side_scroller_turn(move_dir, params, delta)


func _apply_simple_third_person_turn(move: Vector2, move_dir: Vector3, params: MovementData3D, delta: float) -> void:
	if _modifier_turn_active or _modifier_turn_pending:
		return
	var dir := -1.0 if params.turn_invert else 1.0
	var desired_turn := move.x * params.turn_rate * dir
	var t := 1.0 - exp(-params.turn_smooth * delta)
	_turn_velocity = lerp(_turn_velocity, desired_turn, t)
	rotation.y += _turn_velocity * delta


func _apply_first_person_turn(move_dir: Vector3, params: MovementData3D, delta: float) -> void:
	var turn_rate := params.turn_rate
	if params.turn_smooth > 0.0:
		turn_rate = maxf(turn_rate, params.turn_smooth)
	if first_person_align_actor_to_camera:
		var look_dir := _get_first_person_aim_forward()
		look_dir.y = 0.0
		if look_dir.length() > 0.001:
			look_dir = look_dir.normalized()
			_rotate_towards(look_dir, maxf(turn_rate, first_person_align_speed), delta)
			return
	if move_dir.length() <= 0.001:
		return
	_rotate_towards(move_dir, turn_rate, delta)


func _apply_side_scroller_turn(move_dir: Vector3, params: MovementData3D, delta: float) -> void:
	if side_scroller_disable_turn:
		return
	var face_dir := Vector3(move_dir.x, 0.0, move_dir.z)
	if face_dir.length() <= 0.001:
		var vel_dir := Vector3(velocity.x, 0.0, velocity.z)
		if vel_dir.length() <= 0.001:
			return
		face_dir = vel_dir.normalized()
	if side_scroller_face_invert:
		face_dir = -face_dir
	if side_scroller_rotate_visual_only:
		var visual := get_node_or_null("VisualRoot") as Node3D
		if visual:
			_rotate_node_towards(visual, face_dir, params.turn_rate, delta)
			return
	_rotate_towards(face_dir, params.turn_rate, delta)


func _rotate_node_towards(node: Node3D, dir: Vector3, turn_rate: float, delta: float) -> void:
	if node == null:
		return
	var target_yaw := atan2(dir.x, dir.z)
	var current_yaw := node.rotation.y
	var t := 1.0 - exp(-turn_rate * delta)
	node.rotation.y = lerp_angle(current_yaw, target_yaw, t)


func _get_first_person_aim_forward() -> Vector3:
	var cam: Node3D = _find_first_person_camera() as Node3D
	if cam != null:
		var forward: Vector3 = -cam.global_transform.basis.z
		forward.y = 0.0
		if forward.length() > 0.001:
			if first_person_flip_camera_forward_axis:
				forward = -forward
			return forward.normalized()
	var aim: Vector3 = aim_direction
	aim.y = 0.0
	if aim.length() > 0.001:
		return aim.normalized()
	cam = _find_orbit_camera() as Node3D
	if cam != null:
		var orbit_forward: Vector3 = -cam.global_transform.basis.z
		orbit_forward.y = 0.0
		if orbit_forward.length() > 0.001:
			return orbit_forward.normalized()
	var actor_forward: Vector3 = -global_transform.basis.z
	actor_forward.y = 0.0
	if actor_forward.length() <= 0.001:
		return Vector3.FORWARD
	return actor_forward.normalized()


func _get_camera_aim_dir() -> Vector3:
	if camera_context == CameraContext.SIDE_SCROLLER:
		var forward := -global_transform.basis.z
		forward.y = 0.0
		if forward.length() > 0.001:
			return forward.normalized()
		return Vector3.FORWARD
	if camera_context == CameraContext.FIRST_PERSON:
		return _get_first_person_aim_forward()
	var cam: Node3D = _find_orbit_camera() as Node3D
	if cam != null:
		var forward: Vector3 = -cam.global_transform.basis.z
		forward.y = 0.0
		if forward.length() > 0.001:
			return forward.normalized()
	var aim: Vector3 = aim_direction
	aim.y = 0.0
	if aim.length() > 0.001:
		return aim.normalized()
	var actor_forward: Vector3 = -global_transform.basis.z
	actor_forward.y = 0.0
	if actor_forward.length() > 0.001:
		return actor_forward.normalized()
	return Vector3.FORWARD


func _rotate_towards(dir: Vector3, turn_rate: float, delta: float) -> void:
	var target_yaw := atan2(dir.x, dir.z)
	var current_yaw := rotation.y
	var t := 1.0 - exp(-turn_rate * delta)
	rotation.y = lerp_angle(current_yaw, target_yaw, t)


func _apply_wall_jump_turn(params: MovementData3D, delta: float) -> void:
	var turn_dir := _wall_jump_turn_dir
	if turn_dir.length() <= 0.01:
		turn_dir = Vector3(velocity.x, 0.0, velocity.z)
	if turn_dir.length() <= 0.01:
		return
	var target_yaw := _wall_jump_turn_yaw
	if not _wall_jump_turn_active:
		target_yaw = _wall_jump_get_target_yaw(turn_dir)
	var remaining := maxf(maxf(_wall_jump_no_input_timer, _wall_jump_force_timer), 0.001)
	var t := clampf(delta / remaining, 0.0, 1.0)
	global_rotation.y = lerp_angle(global_rotation.y, target_yaw, t)


func _wall_jump_get_target_yaw(dir: Vector3) -> float:
	var facing := dir
	if wall_jump_turn_flip_dir:
		facing = -facing
	return atan2(facing.x, facing.z)


func _update_wall_jump_pre_rotate(delta: float, params: MovementData3D) -> void:
	if not _wall_jump_pre_rotating:
		return
	if wall_jump_pre_rotate_snap:
		rotation.y = _wall_jump_pre_rotate_target_yaw
		_wall_jump_pre_rotate_timer = 0.0
	else:
		_wall_jump_pre_rotate_timer = maxf(0.0, _wall_jump_pre_rotate_timer - delta)
		var denom := maxf(wall_jump_pre_rotate_time, 0.001)
		var t := clampf(delta / denom, 0.0, 1.0)
		rotation.y = lerp_angle(rotation.y, _wall_jump_pre_rotate_target_yaw, t)
	if _wall_jump_pre_rotate_timer <= 0.0:
		_wall_jump_pre_rotating = false
		velocity = _wall_jump_pending_velocity
		wall_jumping = true
		_wall_jump_force_velocity = Vector3(_wall_jump_pending_velocity.x, 0.0, _wall_jump_pending_velocity.z)
		_wall_jump_force_total_time = maxf(_wall_jump_force_total_time, _wall_jump_force_timer)
		_wall_jump_pending_velocity = Vector3.ZERO
		if _anim_driver:
			_anim_driver.set_state("wall_jump")


func _apply_camera_override() -> void:
	if not _uses_actor_camera():
		return
	if camera_data == null:
		return
	var cam := _find_orbit_camera()
	if cam and cam.has_method("apply_camera_data"):
		cam.call("apply_camera_data", camera_data)


func _apply_camera_params() -> void:
	if not _uses_actor_camera():
		return
	if _camera_params == null:
		return
	allow_third_person = _camera_params.allow_third_person
	allow_first_person = _camera_params.allow_first_person
	allow_side_scroller = _camera_params.allow_side_scroller
	if _camera_params.apply_default_context:
		camera_context = _camera_params.default_context
	side_scroller_axes = _camera_params.side_scroller_axes
	side_scroller_allow_depth = _camera_params.side_scroller_allow_depth
	side_scroller_crouch_uses_side_down = _camera_params.side_scroller_crouch_uses_side_down
	side_scroller_use_camera_space = _camera_params.side_scroller_use_camera_space
	side_scroller_plane_lock = _camera_params.side_scroller_plane_lock
	side_scroller_depth_deadzone = _camera_params.side_scroller_depth_deadzone
	side_scroller_face_invert = _camera_params.side_scroller_face_invert
	side_scroller_invert_depth = _camera_params.side_scroller_invert_depth
	side_scroller_disable_turn = _camera_params.side_scroller_disable_turn
	if _camera_params.camera_rig:
		camera_data = _camera_params.camera_rig
		_apply_camera_override()
	if _camera_params.apply_orbit_mode:
		var orbit := _find_orbit_camera()
		if orbit and "camera_mode" in orbit:
			orbit.set("camera_mode", _camera_params.orbit_mode)


func _find_orbit_camera() -> Node:
	var direct := find_child("OrbitCamera3D", true, false)
	if direct is OrbitCamera3D:
		return direct
	var cam_named := find_child("Camera3D", true, false)
	if cam_named and cam_named is Camera3D and cam_named.has_method("apply_camera_data"):
		return cam_named
	var candidates := find_children("*", "Camera3D", true, false)
	for node in candidates:
		if node is Camera3D and node.has_method("apply_camera_data"):
			return node
	var parent := get_parent()
	if parent:
		var sibling := parent.get_node_or_null("Camera3D")
		if sibling and sibling is Camera3D and sibling.has_method("apply_camera_data"):
			return sibling
		var sib_orbit := parent.find_child("OrbitCamera3D", true, false)
		if sib_orbit and sib_orbit is Camera3D and sib_orbit.has_method("apply_camera_data"):
			return sib_orbit
	return null


func _find_first_person_camera() -> Node:
	var direct := find_child("FirstPersonCamera3D", true, false)
	if direct is FirstPersonCamera3D:
		return direct
	for child in get_children():
		if child is FirstPersonCamera3D:
			return child
	return null


func _toggle_camera_context() -> void:
	if not _uses_actor_camera():
		return
	if _camera_cycle.is_empty():
		_rebuild_camera_cycle()
	if _camera_cycle.is_empty():
		return
	var idx := _camera_cycle.find(camera_context)
	if idx < 0:
		camera_context = _camera_cycle[0]
	else:
		camera_context = _camera_cycle[(idx + 1) % _camera_cycle.size()]
	_set_active_camera()


func _toggle_side_scroller_context() -> void:
	if not _uses_actor_camera():
		return
	if not allow_side_scroller:
		return
	if camera_context == CameraContext.SIDE_SCROLLER:
		camera_context = _last_camera_context
	else:
		_last_camera_context = camera_context
		camera_context = CameraContext.SIDE_SCROLLER
	_set_active_camera()


func _set_active_camera() -> void:
	if not _uses_actor_camera():
		return
	var orbit := _find_orbit_camera()
	var first := _find_first_person_camera()
	if camera_context == CameraContext.FIRST_PERSON:
		if orbit and "side_scroller_enabled" in orbit:
			orbit.set("side_scroller_enabled", false)
		if first and orbit and first.has_method("sync_from_camera"):
			first.call("sync_from_camera", orbit)
		if first and first.has_method("make_current"):
			first.call("make_current")
		elif first and "current" in first:
			first.set("current", true)
	else:
		if orbit and "side_scroller_enabled" in orbit:
			orbit.set("side_scroller_enabled", camera_context == CameraContext.SIDE_SCROLLER)
		if orbit and "side_scroller_axes" in orbit:
			orbit.set("side_scroller_axes", side_scroller_axes)
		if orbit and "write_aim_to_target" in orbit:
			orbit.set("write_aim_to_target", camera_context != CameraContext.SIDE_SCROLLER)
		if orbit and "input_enabled" in orbit:
			orbit.set("input_enabled", camera_context != CameraContext.SIDE_SCROLLER)
		if orbit and "target_path" in orbit:
			var tp: NodePath = orbit.get("target_path")
			if tp == NodePath(""):
				if get_parent() and get_parent().has_node("Actor"):
					orbit.set("target_path", NodePath("../Actor"))
				else:
					orbit.set("target_path", NodePath(".."))
		if orbit and first and orbit.has_method("begin_transition_from_camera"):
			orbit.call("begin_transition_from_camera", first, first_person_to_third_person_lerp_time)
		if orbit and orbit.has_method("make_current"):
			orbit.call("make_current")
		elif orbit and "current" in orbit:
			orbit.set("current", true)
	if camera_context == CameraContext.SIDE_SCROLLER:
		_side_scroller_plane_anchor = global_transform.origin
		_side_scroller_plane_anchor_set = true
	else:
		_side_scroller_plane_anchor_set = false
	_set_first_person_visibility(camera_context == CameraContext.FIRST_PERSON)


func apply_camera_trigger(trigger: CameraModeTrigger3D) -> void:
	if not _uses_actor_camera():
		return
	if trigger == null or not trigger.enabled:
		return
	if trigger.ignore_if_active and trigger.force_camera_context and camera_context == trigger.camera_context:
		return
	var replace := false
	if _active_camera_trigger == null or not is_instance_valid(_active_camera_trigger):
		replace = true
	else:
		match trigger.priority_mode:
			CameraModeTrigger3D.PriorityMode.LAST:
				replace = true
			CameraModeTrigger3D.PriorityMode.CLOSEST:
				var cur_dist := global_transform.origin.distance_to(_active_camera_trigger.global_transform.origin)
				var new_dist := global_transform.origin.distance_to(trigger.global_transform.origin)
				if new_dist <= cur_dist:
					replace = true
	if not replace:
		return
	_active_camera_trigger = trigger
	if trigger.apply_allowed_modes:
		allow_third_person = trigger.allow_third_person
		allow_first_person = trigger.allow_first_person
		allow_side_scroller = trigger.allow_side_scroller
	if trigger.apply_side_scroller_settings:
		side_scroller_axes = trigger.side_scroller_axes
		side_scroller_allow_depth = trigger.side_scroller_allow_depth
		side_scroller_crouch_uses_side_down = trigger.side_scroller_crouch_uses_side_down
		side_scroller_use_camera_space = trigger.side_scroller_use_camera_space
		side_scroller_plane_lock = trigger.side_scroller_plane_lock
		side_scroller_depth_deadzone = trigger.side_scroller_depth_deadzone
		side_scroller_face_invert = trigger.side_scroller_face_invert
		side_scroller_invert_depth = trigger.side_scroller_invert_depth
		side_scroller_disable_turn = trigger.side_scroller_disable_turn
	if trigger.force_camera_context:
		camera_context = trigger.camera_context
	_rebuild_camera_cycle()
	_set_active_camera()
	if trigger.orbit_mode_override:
		var orbit := _find_orbit_camera()
		if orbit:
			if orbit.has_method("set_mode"):
				orbit.call("set_mode", trigger.orbit_mode)
			elif "mode" in orbit:
				orbit.set("mode", trigger.orbit_mode)


func _rebuild_camera_cycle() -> void:
	if not _uses_actor_camera():
		return
	_camera_cycle.clear()
	if allow_third_person:
		_camera_cycle.append(CameraContext.SIMPLE_THIRD_PERSON)
	if allow_first_person:
		_camera_cycle.append(CameraContext.FIRST_PERSON)
	if allow_side_scroller:
		_camera_cycle.append(CameraContext.SIDE_SCROLLER)
	if _camera_cycle.is_empty():
		_camera_cycle.append(camera_context)
	if not _camera_cycle.has(camera_context):
		camera_context = _camera_cycle[0]
		_set_active_camera()


func set_camera_mode_allowed(mode: int, allowed: bool) -> void:
	match mode:
		CameraContext.SIMPLE_THIRD_PERSON:
			allow_third_person = allowed
		CameraContext.FIRST_PERSON:
			allow_first_person = allowed
		CameraContext.SIDE_SCROLLER:
			allow_side_scroller = allowed
	_rebuild_camera_cycle()


func get_camera_mode_cycle() -> Array:
	return _camera_cycle.duplicate()


func _set_camera_aim_enabled(enabled: bool) -> void:
	if not _uses_actor_camera():
		return
	var orbit := _find_orbit_camera()
	if orbit and "write_aim_to_target" in orbit:
		orbit.set("write_aim_to_target", enabled)
	if orbit and "input_enabled" in orbit:
		orbit.set("input_enabled", enabled)
	var first := _find_first_person_camera()
	if first and "write_aim_to_target" in first:
		first.set("write_aim_to_target", enabled)


func _request_wall_jump_camera_recenter() -> void:
	if not _uses_actor_camera():
		return
	if camera_context != CameraContext.SIMPLE_THIRD_PERSON:
		return
	var orbit := _find_orbit_camera()
	if orbit and orbit.has_method("force_recenter"):
		orbit.call("snap_recenter")
		orbit.call("force_recenter", wall_jump_camera_recenter_time)


func _find_anim_driver() -> AnimDriver3D:
	var driver := find_child("AnimDriver3D", true, false)
	if driver is AnimDriver3D:
		return driver
	return null


func _setup_inventory() -> void:
	if inventory_data == null:
		return
	if inventory_data.equipped_weapon_scene:
		_equip_weapon_scene(inventory_data.equipped_weapon_scene)
		_set_weapon_sheathed(not inventory_data.weapon_drawn)


func _equip_weapon_scene(scene: PackedScene) -> void:
	if scene == null:
		return
	if _equipped_weapon and is_instance_valid(_equipped_weapon):
		_equipped_weapon.queue_free()
	var inst = scene.instantiate()
	if inst == null:
		return
	add_child(inst)
	if inst is WeaponItem3D:
		_equipped_weapon = inst
		_equipped_weapon.refresh_attachment()


func _set_weapon_sheathed(sheathed: bool) -> void:
	if _equipped_weapon and is_instance_valid(_equipped_weapon):
		_equipped_weapon.set_sheathed(sheathed)


func _get_combat_prefix() -> String:
	match combat_mode:
		CombatMode.ARMED:
			return "combat_armed_"
		CombatMode.RANGED:
			return "combat_ranged_"
	return "combat_unarmed_"


func _update_combat_input(input: IInputSource, delta: float) -> void:
	if not combat_enabled or input == null:
		_combat_blocking = false
		return
	if ledge_holding or ledge_climbing:
		return
	if input.is_weapon_toggle_just_pressed():
		var drawn := true
		if inventory_data:
			inventory_data.weapon_drawn = not inventory_data.weapon_drawn
			drawn = inventory_data.weapon_drawn
		_set_weapon_sheathed(not drawn)
		if combat_mode == CombatMode.ARMED:
			_combat_override_state = "combat_armed_draw" if drawn else "combat_armed_sheath"
			_combat_override_timer = combat_action_lock_time
	if _combat_override_timer > 0.0:
		_combat_override_timer = maxf(0.0, _combat_override_timer - delta)
	if combat_mode == CombatMode.RANGED:
		if input.is_ranged_just_pressed():
			_combat_override_state = _get_combat_prefix() + "shoot"
			_combat_override_timer = combat_action_lock_time
		_combat_blocking = false
		return
	_combat_blocking = input.is_block_held()
	if input.is_attack_just_pressed():
		_combat_override_state = _get_combat_prefix() + "attack_light"
		_combat_override_timer = combat_action_lock_time


func _get_combat_override_state() -> String:
	if _combat_blocking:
		return _get_combat_prefix() + "block"
	if _combat_override_timer > 0.0 and _combat_override_state != "":
		return _combat_override_state
	return ""


func set_aim_direction(dir: Vector3) -> void:
	if dir.length() <= 0.001:
		return
	aim_direction = dir.normalized()


func get_aim_direction() -> Vector3:
	return aim_direction


func _get_input_source() -> IInputSource:
	if _input_source == null:
		_input_source = NullInputSource.new()
	return _input_source


func _get_movement_params() -> MovementData3D:
	var params_node: Node = _get_params_node()
	if params_node:
		var mv: Variant = _params_get(params_node, "movement_data")
		if mv is MovementData3D:
			return mv
	if _movement_data:
		return _movement_data
	return _default_movement


func _ensure_movement_resource() -> MovementData3D:
	var params_node: Node = _get_params_node()
	if params_node:
		var mv: Variant = _params_get(params_node, "movement_data")
		if mv is MovementData3D:
			return mv
		var created := MovementData3D.new()
		_params_set(params_node, "movement_data", created)
		return created
	if _movement_data == null:
		_movement_data = MovementData3D.new()
	return _movement_data


func _set_movement_value(key: String, value) -> void:
	# Prevent scene-load serialization from writing proxy defaults back into shared resources.
	if Engine.is_editor_hint() and not is_inside_tree():
		return
	var data: MovementData3D = _ensure_movement_resource()
	data.set(key, value)
	if Engine.is_editor_hint():
		_save_resource_if_external(data)
	if _controller_ctx:
		_controller_ctx.movement = data


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		# Keep editor values stable unless a concrete MovementData resource is assigned.
		var editor_data: MovementData3D = _get_movement_params()
		if editor_data != null and editor_data != _default_movement:
			_sync_movement_proxy_from_resource()
	_rebuild_camera_cycle()


func _sync_movement_proxy_from_resource() -> void:
	var data: MovementData3D = _get_movement_params()
	if data == _default_movement:
		data = null
	if data == null:
		return
	_syncing_movement_proxy = true
	_movement_gravity = data.gravity
	_movement_walk_speed = data.walk_speed
	_movement_run_speed = data.run_speed
	_movement_sprint_enabled = data.sprint_enabled
	_movement_sprint_double_tap_window = data.sprint_double_tap_window
	_movement_sprint_boost_multiplier = data.sprint_boost_multiplier
	_movement_sprint_boost_fade_time = data.sprint_boost_fade_time
	_movement_acceleration = data.acceleration
	_movement_deceleration = data.deceleration
	_movement_move_deadzone = data.move_deadzone
	_movement_turn_rate = data.turn_rate
	_movement_turn_smooth = data.turn_smooth
	_movement_turn_invert = data.turn_invert
	_movement_max_slope_angle = data.max_slope_angle
	_movement_air_control = data.air_control
	_movement_air_accel = data.air_accel
	_movement_air_decel = data.air_decel
	_movement_max_fall_speed = data.max_fall_speed
	_movement_floor_leave_delay = data.floor_leave_delay
	_movement_jump_speed = data.jump_speed
	_movement_double_jump_speed = data.double_jump_speed
	_movement_max_jumps = data.max_jumps
	_movement_coyote_time = data.coyote_time
	_movement_jump_buffer_time = data.jump_buffer_time
	_movement_require_jump_release = data.require_jump_release
	_movement_double_jump_clamp_fall_speed = data.double_jump_clamp_fall_speed
	_movement_jump_cut = data.jump_cut
	_movement_wall_jump_enabled = data.wall_jump_enabled
	_movement_wall_check_distance = data.wall_check_distance
	_movement_wall_check_height = data.wall_check_height
	_movement_wall_check_multi_ray = data.wall_check_multi_ray
	_movement_wall_check_forward = data.wall_check_forward
	_movement_wall_check_diagonals = data.wall_check_diagonals
	_movement_wall_jump_up_speed = data.wall_jump_up_speed
	_movement_wall_jump_push_speed = data.wall_jump_push_speed
	_movement_wall_jump_no_input_time = data.wall_jump_no_input_time
	_movement_wall_jump_duration = data.wall_jump_duration
	_movement_wall_jump_lock_time = data.wall_jump_lock_time
	_movement_dash_speed = data.dash_speed
	_movement_dash_time = data.dash_time
	_movement_dash_cooldown = data.dash_cooldown
	_movement_dash_allow_air = data.dash_allow_air
	_movement_dash_allow_double_tap = data.dash_allow_double_tap
	_movement_dash_double_tap_window = data.dash_double_tap_window
	_movement_roll_speed = data.roll_speed
	_movement_roll_time = data.roll_time
	_movement_roll_cooldown = data.roll_cooldown
	_movement_crouch_height = data.crouch_height
	_movement_crouch_walk_height = data.crouch_walk_height
	_movement_crouch_transition_time = data.crouch_transition_time
	_movement_crouch_walk_transition_time = data.crouch_walk_transition_time
	_movement_crouch_walk_move_threshold = data.crouch_walk_move_threshold
	_movement_roll_crouch_height = data.roll_crouch_height
	_movement_roll_crouch_transition_time = data.roll_crouch_transition_time
	_movement_crouch_stand_transition_time = data.crouch_stand_transition_time
	_movement_crouch_speed = data.crouch_speed
	_movement_sneak_speed = data.sneak_speed
	_movement_drop_through_time = data.drop_through_time
	_movement_drop_through_layer = data.drop_through_layer
	_movement_drop_through_speed = data.drop_through_speed
	_movement_high_fall_speed = data.high_fall_speed
	_movement_high_fall_time = data.high_fall_time
	_syncing_movement_proxy = false
	if Engine.is_editor_hint():
		notify_property_list_changed()


func _refresh_editor_model() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	if not _is_editing_own_scene_root():
		return
	if not preview_model_in_editor:
		_set_model_visible(false)
		return
	var data := _get_model_data_for_apply()
	if data:
		var signature: String = _build_editor_preview_signature(data)
		var model_root: Node = _ensure_model_root()
		var has_geometry: bool = _has_model_geometry(model_root)
		if signature == _editor_preview_signature and has_geometry:
			_set_model_visible(true)
			_set_debug_mesh_visible(false)
			return
		_apply_model_resource(data)
		_editor_preview_signature = signature
		_set_model_visible(true)
	else:
		_editor_preview_signature = "__none__"
		_set_debug_mesh_visible(true)


func _queue_editor_model_refresh(force_rebuild: bool = false) -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	if not _is_editing_own_scene_root():
		return
	set_process(true)
	if force_rebuild:
		_editor_preview_signature = ""
	if _editor_preview_refresh_queued:
		return
	_editor_preview_refresh_queued = true
	call_deferred("_run_queued_editor_model_refresh")


func _run_queued_editor_model_refresh() -> void:
	_editor_preview_refresh_queued = false
	_refresh_editor_model()


func _build_editor_preview_signature(data: ModelData3D) -> String:
	if data == null:
		return "__null__"
	var scene_id: int = 0
	var mesh_id: int = 0
	var material_id: int = 0
	var anim_lib_id: int = 0
	var fp_scene_id: int = 0
	var fp_material_id: int = 0
	if data.scene != null:
		scene_id = data.scene.get_instance_id()
	if data.mesh != null:
		mesh_id = data.mesh.get_instance_id()
	if data.material_override != null:
		material_id = data.material_override.get_instance_id()
	if data.animation_library != null:
		anim_lib_id = data.animation_library.get_instance_id()
	if first_person_model_scene != null:
		fp_scene_id = first_person_model_scene.get_instance_id()
	if first_person_override_material != null:
		fp_material_id = first_person_override_material.get_instance_id()
	return "%d|%s|%d|%d|%d|%d|%s|%s|%s|%s|%s|%d|%d|%s|%s|%s|%s" % [
		data.get_instance_id(),
		data.resource_path,
		scene_id,
		mesh_id,
		material_id,
		anim_lib_id,
		str(data.scale),
		str(data.force_double_sided),
		str(camera_context),
		str(first_person_use_separate_model),
		str(first_person_hide_nodes),
		fp_scene_id,
		fp_material_id,
		str(first_person_hide_materials),
		model_id,
		str(visual_binding_mode),
		str(resident_rebuild_on_source_change),
	]


func _get_model_data_for_apply() -> ModelData3D:
	var params_node: Node = _get_params_node()
	if params_node:
		var params_model: Variant = _params_get(params_node, "model_data")
		if params_model is ModelData3D:
			return params_model
	if model_data:
		return model_data
	return null


func _set_model_visible(visible: bool) -> void:
	var model_root := _ensure_model_root()
	if model_root == null:
		return
	for child in model_root.get_children():
		_set_node_visibility(child, visible)


func _set_node_visibility(node: Node, visible: bool) -> void:
	if node is VisualInstance3D:
		(node as VisualInstance3D).visible = visible
	for child in node.get_children():
		_set_node_visibility(child, visible)


func _mark_preview_instance(node: Node) -> void:
	if node == null:
		return
	node.set_meta("_editor_preview", true)
	node.owner = self
	for child in node.get_children():
		_mark_preview_instance(child)


func _cleanup_preview_instances() -> void:
	if not Engine.is_editor_hint():
		return
	_editor_preview_signature = ""
	_resident_model_source_signature = ""
	var model_root := _ensure_model_root()
	if model_root == null:
		return
	for child in model_root.get_children():
		if child is AnimationPlayer:
			continue
		var is_preview: bool = child.has_meta("_editor_preview")
		if is_preview:
			child.free()
	# Avoid unresolved-track warnings on scene reload by clearing editor-only player bindings
	# before save; they are rebuilt from ModelData on _ready/_refresh_editor_model.
	var players := model_root.find_children("*", "AnimationPlayer", true, false)
	for item in players:
		var anim_player := item as AnimationPlayer
		if anim_player == null:
			continue
		anim_player.stop()
		anim_player.active = false
		anim_player.root_node = NodePath("")
		var libs: Array = anim_player.get_animation_library_list()
		for lib_name in libs:
			anim_player.remove_animation_library(lib_name)


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		var editor_mv: MovementData3D = _get_movement_params()
		if editor_mv != null and editor_mv != _default_movement:
			_save_resource_if_external(editor_mv)
		if editor_cleanup_preview_on_save and _is_editing_own_scene_root():
			_cleanup_preview_instances()
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		if editor_cleanup_preview_on_save and preview_model_in_editor and _is_editing_own_scene_root():
			_queue_editor_model_refresh(true)


func _is_editing_own_scene_root() -> bool:
	if not Engine.is_editor_hint():
		return false
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	return tree.edited_scene_root == self


func get_input_source() -> IInputSource:
	return _get_input_source()


func get_movement_params() -> MovementData3D:
	return _get_movement_params()


func get_locomotion_move_input() -> Vector2:
	if camera_context == CameraContext.SIDE_SCROLLER:
		var move := Vector2.ZERO
		var src := _get_input_source()
		if src:
			move = src.get_move_vector()
		if move.length() > 1.0:
			move = move.normalized()
		var dir := _get_side_scroller_direction(move)
		var horiz := Vector2(dir.x, dir.z)
		return Vector2(0.0, horiz.length())
	return Vector2(input_x, input_y)


func get_locomotion_anim_speed_scale(state_name: String = "") -> float:
	var params: MovementData3D = _get_movement_params()
	if params == null:
		return 1.0
	var walk_min: float = maxf(0.01, minf(walk_anim_speed_range.x, walk_anim_speed_range.y))
	var walk_max: float = maxf(walk_min, maxf(walk_anim_speed_range.x, walk_anim_speed_range.y))
	var run_min: float = maxf(0.01, minf(run_anim_speed_range.x, run_anim_speed_range.y))
	var run_max: float = maxf(run_min, maxf(run_anim_speed_range.x, run_anim_speed_range.y))
	var walk_speed: float = maxf(params.walk_speed, 0.01)
	var run_speed: float = maxf(params.run_speed, walk_speed + 0.01)
	var speed: float = maxf(0.0, speed_x_abs)
	var state_lc: String = state_name.to_lower()

	if state_lc.begins_with("walk"):
		var walk_t: float = clampf(speed / walk_speed, 0.0, 1.0)
		return lerpf(walk_min, walk_max, walk_t)

	if state_lc.begins_with("run") or state_lc.begins_with("sprint"):
		var run_span: float = maxf(run_speed - walk_speed, 0.01)
		var run_t: float = clampf((speed - walk_speed) / run_span, 0.0, 1.0)
		return lerpf(run_min, run_max, run_t)

	return 1.0


func get_orbit_camera() -> OrbitCamera3D:
	var cam := _find_orbit_camera()
	if cam is OrbitCamera3D:
		return cam
	return null


func get_anim_driver() -> AnimDriver3D:
	if _anim_driver == null:
		_anim_driver = _find_anim_driver()
	return _anim_driver


func get_controller_context() -> ControllerContext3D:
	return _controller_ctx


func resolve_anim_state(intent: String) -> String:
	var effective_model_data: ModelData3D = _get_model_data_for_apply()
	if effective_model_data and effective_model_data.has_method("resolve_state"):
		return effective_model_data.resolve_state(intent)
	return intent


func apply_basic_movement(delta: float) -> void:
	_apply_basic_movement(delta)


func _apply_data_ids() -> void:
	var params_node: Node = _get_params_node()
	if params_node:
		var params_movement: Variant = _params_get(params_node, "movement_data")
		var params_model: Variant = _params_get(params_node, "model_data")
		var params_camera: Variant = _params_get(params_node, "camera_data")
		var params_stats: Variant = _params_get(params_node, "stats_data")
		var params_formulas: Variant = _params_get(params_node, "formulas_data")
		if params_movement is MovementData3D:
			movement_data = params_movement
		if params_model is ModelData3D:
			model_data = params_model
		if params_camera is CameraRigData3D:
			camera_data = params_camera
		if params_stats is StatsData:
			stats_data = params_stats
		if params_formulas is StatsFormulaData:
			formulas_data = params_formulas
		if model_data:
			_apply_model_resource(model_data)
		if camera_data:
			_apply_camera_override()
		return
	# No params node: only use locally assigned resources.
	if model_data:
		_apply_model_resource(model_data)
	if camera_data:
		_apply_camera_override()


func _get_params_node() -> Node:
	var from_path: Node = null
	if params_node_path != NodePath(""):
		from_path = get_node_or_null(params_node_path)
	if _is_params_node(from_path):
		return from_path
	var default_node: Node = get_node_or_null("ActorParams3D")
	if _is_params_node(default_node):
		return default_node
	return null


func _is_params_node(node: Node) -> bool:
	if node == null:
		return false
	if node.name == "ActorParams3D":
		return true
	var script_obj: Variant = node.get_script()
	if script_obj is Script:
		var script_path: String = String((script_obj as Script).resource_path)
		if script_path.ends_with("ActorParams3D.gd"):
			return true
	return _node_has_property(node, "movement_data") and _node_has_property(node, "model_data")


func _node_has_property(node: Node, prop: String) -> bool:
	var plist: Array = node.get_property_list()
	for entry_any in plist:
		var entry: Dictionary = entry_any as Dictionary
		if entry.is_empty():
			continue
		if String(entry.get("name", "")) == prop:
			return true
	return false


func _params_get(node: Node, prop: String) -> Variant:
	if node == null:
		return null
	if not _node_has_property(node, prop):
		return null
	return node.get(prop)


func _params_set(node: Node, prop: String, value: Variant) -> void:
	if node == null:
		return
	if not _node_has_property(node, prop):
		return
	node.set(prop, value)


func _save_resource_if_external(res: Resource) -> void:
	if res == null:
		return
	var path: String = res.resource_path
	if path == "":
		return
	ResourceSaver.save(res, path)


func _registry():
	if Engine.has_singleton("DataRegistry"):
		return Engine.get_singleton("DataRegistry")
	if has_node("/root/DataRegistry"):
		return get_node("/root/DataRegistry")
	return null


func _apply_model_resource(data: ModelData3D) -> void:
	if data == null:
		_set_debug_mesh_visible(true)
		return
	_model_applied = true
	var model_root := _ensure_model_root()
	if model_root == null:
		return
	var binding_root: Node = null
	var used_resident_binding: bool = false
	if visual_binding_mode == VisualBindingMode.RESIDENT_MODEL:
		used_resident_binding = _apply_model_resource_resident(data, model_root)
		if used_resident_binding:
			binding_root = model_root
	if not used_resident_binding:
		_clear_model_root_children(model_root)
		model_root.scale = data.scale
		var instanced := false
		var inst_root: Node = null
		if data.scene:
			var inst: Node = data.scene.instantiate()
			if inst:
				inst_root = inst
				model_root.add_child(inst)
				instanced = _has_geometry(inst)
		elif data.mesh:
			var mesh_instance := MeshInstance3D.new()
			mesh_instance.mesh = data.mesh
			if data.material_override:
				mesh_instance.material_override = data.material_override
			model_root.add_child(mesh_instance)
			instanced = true
		_set_debug_mesh_visible(not instanced)
		_apply_pivot_defaults()
		if inst_root:
			if Engine.is_editor_hint() and preview_model_in_editor and get_tree() and get_tree().edited_scene_root == self:
				_mark_preview_instance(inst_root)
			_prune_model_animation_players(inst_root)
			_bind_mesh_skeletons(inst_root)
			var external_anim: AnimationPlayer = model_root.get_node_or_null("AnimationPlayer") as AnimationPlayer
			if external_anim:
				_bind_animation_library_to_player(data, external_anim, inst_root)
			else:
				_bind_animation_library(data, inst_root)
			if data.force_double_sided:
				_force_double_sided(inst_root)
		binding_root = inst_root
		_resident_model_source_signature = _build_model_source_signature(data)
	_finalize_model_apply(data, model_root, binding_root)


func _build_model_source_signature(data: ModelData3D) -> String:
	if data == null:
		return "__null__"
	var scene_id: int = 0
	var mesh_id: int = 0
	if data.scene != null:
		scene_id = data.scene.get_instance_id()
	if data.mesh != null:
		mesh_id = data.mesh.get_instance_id()
	return "%d|%s|%d|%d" % [data.get_instance_id(), data.resource_path, scene_id, mesh_id]


func _clear_model_root_children(model_root: Node) -> void:
	if model_root == null:
		return
	for child in model_root.get_children():
		if child is AnimationPlayer:
			continue
		_detach_and_free_node(child)


func _detach_and_free_node(node: Node) -> void:
	if node == null:
		return
	var parent: Node = node.get_parent()
	if parent != null:
		parent.remove_child(node)
	if Engine.is_editor_hint():
		node.free()
	else:
		node.queue_free()


func _apply_model_resource_resident(data: ModelData3D, model_root: Node) -> bool:
	if model_root == null:
		return false
	var has_geometry: bool = _has_model_geometry(model_root)
	var source_signature: String = _build_model_source_signature(data)
	if not has_geometry:
		_resident_model_source_signature = source_signature
		return false
	if _resident_model_source_signature == "":
		_resident_model_source_signature = source_signature
	elif source_signature != _resident_model_source_signature:
		# Keep existing in-scene geometry authoritative for scene-based sources
		# (for example FBX-backed PackedScene setups) to avoid forced re-instancing.
		var has_scene_source: bool = data.scene != null
		_resident_model_source_signature = source_signature
		if resident_rebuild_on_source_change and not has_scene_source:
			return false
	model_root.scale = data.scale
	if data.scene == null and data.mesh != null:
		_apply_resident_material_override(model_root, data.material_override)
	_bind_mesh_skeletons(model_root)
	var external_anim: AnimationPlayer = model_root.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if external_anim:
		_bind_animation_library_to_player(data, external_anim, model_root)
	else:
		_bind_animation_library(data, model_root)
	if data.force_double_sided:
		_force_double_sided(model_root)
	_set_debug_mesh_visible(false)
	_apply_pivot_defaults()
	return true


func _apply_resident_material_override(model_root: Node, material_override: Material) -> void:
	var meshes: Array = model_root.find_children("*", "MeshInstance3D", true, false)
	for mesh_node in meshes:
		var mesh_instance := mesh_node as MeshInstance3D
		if mesh_instance == null:
			continue
		mesh_instance.material_override = material_override


func _finalize_model_apply(data: ModelData3D, model_root: Node, binding_root: Node) -> void:
	_refresh_anim_driver()
	if _anim_driver:
		_anim_driver.animation_tree_path = data.animation_tree_path
		_anim_driver.animation_player_path = data.animation_player_path
		_anim_driver.animation_library_name = data.animation_library_name
		_sync_anim_driver_paths(model_root)
		_anim_driver.refresh_targets()
		if "debug_enabled" in _anim_driver and _anim_driver.debug_enabled:
			_anim_driver.debug_dump("model applied")
			var debug_root: Node = binding_root
			if debug_root == null:
				debug_root = model_root
			_debug_dump_model_binding(debug_root)
	_set_first_person_visibility(camera_context == CameraContext.FIRST_PERSON)


func _set_first_person_visibility(enabled: bool) -> void:
	var model_root := _ensure_model_root()
	if model_root == null:
		return
	if first_person_use_separate_model and first_person_model_scene != null:
		if enabled:
			_apply_first_person_model()
		else:
			_restore_third_person_model()
		return
	if first_person_hide_nodes.is_empty() and first_person_hide_materials.is_empty():
		return
	var targets: Array = model_root.find_children("*", "MeshInstance3D", true, false)
	for mesh in targets:
		var mi := mesh as MeshInstance3D
		if mi == null:
			continue
		var name_lc := mi.name.to_lower()
		var hide_all := false
		for key in first_person_hide_nodes:
			if key == "":
				continue
			if name_lc.find(key.to_lower()) >= 0:
				hide_all = true
				break
		var surface_indices: Array = []
		if not hide_all:
			surface_indices = _get_hide_surface_indices(mi)
		if hide_all or not surface_indices.is_empty():
			_set_mesh_transparent(mi, enabled, hide_all, surface_indices)


func _cache_third_person_model_source() -> void:
	_cached_third_person_model_data = model_data
	_cached_third_person_model_id = model_id


func _apply_first_person_model() -> void:
	if _first_person_model_active:
		return
	if first_person_model_scene == null:
		return
	_cache_third_person_model_source()
	var model_root := _ensure_model_root()
	if model_root == null:
		return
	model_root.visible = true
	for child in model_root.get_children():
		_detach_and_free_node(child)
	model_root.scale = first_person_model_scale
	var inst := first_person_model_scene.instantiate()
	var fp_anim_player: AnimationPlayer = null
	if inst:
		inst.name = "FirstPersonModel"
		model_root.add_child(inst)
		_bind_mesh_skeletons(inst)
		if not _has_geometry(inst):
			_set_debug_mesh_visible(true)
		else:
			_set_debug_mesh_visible(false)
			_set_node_visibility(inst, true)
		if model_data:
			fp_anim_player = _bind_animation_library_to_instance(inst, model_data)
			if model_data.force_double_sided:
				_force_double_sided(inst)
	_set_debug_mesh_visible(false)
	_apply_pivot_defaults()
	_refresh_anim_driver()
	if _anim_driver:
		_anim_driver.target_root_path = NodePath("../VisualRoot/ModelRoot")
		_anim_driver.animation_tree_path = NodePath("")
		_anim_driver.animation_player_path = NodePath("")
		if model_data:
			_anim_driver.animation_library_name = model_data.animation_library_name
		if fp_anim_player:
			_anim_driver.animation_player_path = model_root.get_path_to(fp_anim_player)
		_sync_anim_driver_paths(model_root)
		_anim_driver.refresh_targets()
	_first_person_model_active = true


func _restore_third_person_model() -> void:
	if not _first_person_model_active:
		return
	_first_person_model_active = false
	if _cached_third_person_model_data:
		_apply_model_resource(_cached_third_person_model_data)
	elif _cached_third_person_model_id != "":
		apply_model_data(_cached_third_person_model_id)


func _bind_animation_library_to_instance(root: Node, data: ModelData3D) -> AnimationPlayer:
	if data == null or data.animation_library == null or root == null:
		return null
	var anim_player := root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player == null:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		root.add_child(anim_player)
	var lib_name := data.animation_library_name
	if lib_name == StringName():
		lib_name = &"biped"
	var lib := data.animation_library
	var desired_prefix := ""
	var skel := _find_primary_skeleton(root)
	if skel:
		desired_prefix = String(anim_player.get_path_to(skel))
	var source_prefix := _guess_anim_skeleton_prefix(lib)
	if source_prefix == "":
		source_prefix = "Armature/Skeleton3D"
	if desired_prefix != "" and source_prefix != desired_prefix:
		lib = _remap_animation_library(lib, source_prefix, desired_prefix)
	if anim_player.has_animation_library(lib_name):
		anim_player.remove_animation_library(lib_name)
	anim_player.add_animation_library(lib_name, lib)
	anim_player.root_node = anim_player.get_path_to(root)
	_configure_animation_player(anim_player)
	return anim_player


func _update_first_person_camera_offset(params: MovementData3D, delta: float) -> void:
	if camera_context != CameraContext.FIRST_PERSON:
		return
	var cam := _find_first_person_camera() as FirstPersonCamera3D
	if cam == null:
		return
	if not _fp_cam_base_offset_cached:
		_fp_cam_base_offset = cam.collider_origin_offset
		_fp_cam_offset_current = _fp_cam_base_offset
		_fp_cam_base_offset_cached = true
	var small_mode := roll_active or crouching
	var target := _fp_cam_base_offset
	if small_mode:
		target = _fp_cam_base_offset + first_person_small_mode_offset
	var lerp_time := maxf(first_person_small_mode_lerp_time, 0.0)
	if lerp_time <= 0.0 or delta <= 0.0:
		_fp_cam_offset_current = target
	else:
		var t := 1.0 - exp(-delta / maxf(lerp_time, 0.001))
		_fp_cam_offset_current = _fp_cam_offset_current.lerp(target, t)
	cam.collider_origin_offset = _fp_cam_offset_current


func _update_ledge(input: IInputSource, params: MovementData3D, delta: float) -> bool:
	if not ledge_enabled:
		ledge_holding = false
		ledge_climbing = false
		return false
	if not _input_allowed() or not alive or restrained:
		ledge_holding = false
		ledge_climbing = false
		return false
	if (ledge_holding or ledge_climbing):
		if not input.is_action_held():
			ledge_holding = false
			ledge_climbing = false
			_ledge_climb_timer = 0.0
			return false
		if is_on_floor():
			ledge_holding = false
			ledge_climbing = false
			_ledge_climb_timer = 0.0
			return false
	if ledge_climbing:
		can_move = 0
		_ledge_climb_timer = maxf(0.0, _ledge_climb_timer - delta)
		if _ledge_climb_timer <= 0.0:
			ledge_climbing = false
			if can_move == 0:
				can_move = 1
			# place on top
			var climb_target := _ledge_top + Vector3.UP * ledge_climb_up_offset + _ledge_wall_normal * (ledge_climb_forward_offset + ledge_climb_end_forward_nudge) + _ledge_forward_dir * ledge_climb_z_offset
			global_transform.origin = climb_target
			velocity = Vector3.ZERO
		else:
			velocity = Vector3.ZERO
			var total := maxf(ledge_climb_duration, 0.001)
			var t := 1.0 - (_ledge_climb_timer / total)
			var nudge_scale := clampf((t - 0.5) / 0.5, 0.0, 1.0)
			var climb_target := _ledge_top + Vector3.UP * ledge_climb_up_offset + _ledge_wall_normal * (ledge_climb_forward_offset + ledge_climb_end_forward_nudge * nudge_scale) + _ledge_forward_dir * ledge_climb_z_offset
			global_transform.origin = _ledge_anchor.lerp(climb_target, t)
			if ledge_face_wall:
				var target_yaw := _ledge_face_yaw
				var new_yaw := lerp_angle(rotation.y, target_yaw, t)
				rotation.y = new_yaw
		return true
	if ledge_holding:
		if not input.is_action_held():
			ledge_holding = false
			if ledge_release_pushback > 0.0 and _ledge_wall_normal.length() > 0.001:
				var push_dir := _ledge_wall_normal.normalized()
				velocity = Vector3(push_dir.x * ledge_release_pushback, velocity.y, push_dir.z * ledge_release_pushback)
			return false
		if input_y < -0.3:
			ledge_holding = false
			ledge_climbing = true
			_ledge_climb_timer = maxf(ledge_climb_duration, 0.0)
			velocity = Vector3.ZERO
			if _anim_driver:
				_anim_driver.set_state("traversal_ledge_climb")
			_update_ledge_snap(delta)
			return true
		velocity = Vector3.ZERO
		_update_ledge_snap(delta)
		if _anim_driver:
			_anim_driver.set_state("traversal_ledge_hold")
		return true
	# detect ledge
	if not in_air:
		return false
	# Require action held to begin ledge detection/grab.
	if not input.is_action_held():
		_update_ledge_debug(false)
		return false
	var ledge_hit := _detect_ledge(params)
	if ledge_hit.is_empty():
		_update_ledge_debug(false)
		return false
	_update_ledge_debug(true)
	_ledge_wall_normal = ledge_hit.normal
	_ledge_top = ledge_hit.top
	_ledge_anchor = ledge_hit.anchor
	_ledge_face_yaw = _ledge_get_face_yaw(_ledge_wall_normal)
	_ledge_forward_dir = _debug_ledge_forward
	if input.is_action_held():
		ledge_holding = true
		velocity = Vector3.ZERO
		_update_ledge_snap(delta)
		if _anim_driver:
			_anim_driver.set_state("traversal_ledge_hold")
		return true
	return false


func _update_ledge_snap(delta: float) -> void:
	var t := 1.0
	if ledge_snap_time > 0.0:
		t = 1.0 - exp(-delta / maxf(ledge_snap_time, 0.001))
	global_transform.origin = global_transform.origin.lerp(_ledge_anchor, t)
	if ledge_face_wall:
		var target_yaw := _ledge_face_yaw
		if ledge_face_wall_snap and ledge_holding and not ledge_climbing:
			rotation.y = target_yaw
		else:
			var new_yaw := lerp_angle(rotation.y, target_yaw, t)
			rotation.y = new_yaw


func _detect_ledge(params: MovementData3D) -> Dictionary:
	var world := get_world_3d()
	if world == null:
		return {}
	var space := world.direct_space_state
	if space == null:
		return {}
	var forward := _get_forward_direction()
	if forward.length() <= 0.001:
		forward = -global_transform.basis.z
	forward.y = 0.0
	if forward.length() <= 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var origin := global_transform.origin + Vector3.UP * ledge_grab_height
	_debug_ledge_origin = origin
	_debug_ledge_forward = forward
	# wall hit
	var wall_params := PhysicsRayQueryParameters3D.create(origin, origin + forward * (ledge_grab_distance + 0.1))
	wall_params.collision_mask = collision_mask
	wall_params.exclude = [get_rid()]
	var wall_hit := space.intersect_ray(wall_params)
	if wall_hit.is_empty():
		return {}
	var wall_normal: Vector3 = wall_hit.get("normal", Vector3.ZERO)
	if wall_normal.length() <= 0.001:
		return {}
	if not _is_non_walkable_surface(wall_normal, params):
		return {}
	# top floor check
	var top_origin := origin + forward * (ledge_grab_distance + ledge_clearance_depth * 0.5) + Vector3.UP * ledge_clearance_height
	var top_params := PhysicsRayQueryParameters3D.create(top_origin, top_origin + Vector3.DOWN * ledge_floor_check_distance)
	top_params.collision_mask = collision_mask
	top_params.exclude = [get_rid()]
	var top_hit := space.intersect_ray(top_params)
	if top_hit.is_empty():
		return {}
	var top_normal: Vector3 = top_hit.get("normal", Vector3.ZERO)
	if top_normal.length() <= 0.001:
		return {}
	var angle := rad_to_deg(Vector3.UP.angle_to(top_normal))
	if angle > ledge_max_surface_angle:
		return {}
	# clearance check
	var clearance_shape := BoxShape3D.new()
	clearance_shape.size = Vector3(ledge_grab_width, ledge_clearance_height, ledge_clearance_depth)
	var clearance_xform := Transform3D(Basis.IDENTITY, origin + forward * ledge_grab_distance + Vector3.UP * (ledge_clearance_height * 0.5))
	var clearance_query := PhysicsShapeQueryParameters3D.new()
	clearance_query.shape = clearance_shape
	clearance_query.transform = clearance_xform
	clearance_query.collision_mask = collision_mask
	clearance_query.exclude = [get_rid()]
	clearance_query.collide_with_areas = false
	clearance_query.collide_with_bodies = true
	var clearance_hits: Array = space.intersect_shape(clearance_query, 1)
	if not clearance_hits.is_empty():
		return {}
	var top_pos: Vector3 = top_hit.get("position", origin + Vector3.UP * ledge_clearance_height)
	var anchor := top_pos - wall_normal.normalized() * ledge_hang_back_offset - Vector3.UP * ledge_hang_down_offset + forward * ledge_hang_z_offset
	_debug_ledge_top_pos = top_pos
	_debug_ledge_anchor_pos = anchor
	_debug_ledge_wall_normal_dir = wall_normal.normalized()
	_debug_ledge_hit = true
	return {"normal": wall_normal, "top": top_pos, "anchor": anchor}


func _ledge_get_face_yaw(wall_normal: Vector3) -> float:
	if wall_normal.length() <= 0.001:
		return rotation.y
	var face_dir := -wall_normal
	face_dir.y = 0.0
	if face_dir.length() <= 0.001:
		return rotation.y
	face_dir = face_dir.normalized()
	return atan2(face_dir.x, face_dir.z)


func _update_ledge_debug(hit: bool) -> void:
	if not ledge_debug:
		_set_ledge_debug_visible(false)
		return
	_ensure_ledge_debug_nodes()
	_set_ledge_debug_visible(true)
	var forward := _debug_ledge_forward
	if forward.length() <= 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var grip_center := _debug_ledge_origin + forward * (ledge_grab_distance * 0.5)
	var grip_size := Vector3(ledge_grab_width, ledge_grab_height, ledge_grab_depth)
	_update_debug_box(_debug_ledge_grip, grip_center, forward, grip_size, Color(0.2, 0.8, 1.0, 0.25))
	var clear_center := _debug_ledge_origin + forward * (ledge_grab_distance + ledge_clearance_depth * 0.5) + Vector3.UP * (ledge_clearance_height * 0.5)
	var clear_size := Vector3(ledge_grab_width, ledge_clearance_height, ledge_clearance_depth)
	_update_debug_box(_debug_ledge_clear, clear_center, forward, clear_size, Color(0.2, 1.0, 0.6, 0.2))
	var ray_len := maxf(ledge_grab_distance, 0.05)
	_update_debug_ray(_debug_ledge_ray, _debug_ledge_origin, forward, ray_len, Color(1.0, 0.6, 0.2, 0.35))
	_update_debug_marker(_debug_ledge_top, _debug_ledge_top_pos, hit, Color(1.0, 0.9, 0.2, 0.6))
	_update_debug_marker(_debug_ledge_anchor, _debug_ledge_anchor_pos, hit, Color(0.2, 1.0, 0.2, 0.6))
	if _debug_ledge_wall_normal:
		_update_debug_ray(_debug_ledge_wall_normal, _debug_ledge_top_pos, _debug_ledge_wall_normal_dir, 0.4, Color(1.0, 0.2, 0.2, 0.6))


func _ensure_ledge_debug_nodes() -> void:
	if _debug_ledge_root == null or not is_instance_valid(_debug_ledge_root):
		_debug_ledge_root = Node3D.new()
		_debug_ledge_root.name = "LedgeDebug"
		add_child(_debug_ledge_root)
	if _debug_ledge_grip == null or not is_instance_valid(_debug_ledge_grip):
		_debug_ledge_grip = _make_debug_box("LedgeGripDebug", Color(0.2, 0.8, 1.0, 0.25))
		_debug_ledge_root.add_child(_debug_ledge_grip)
	if _debug_ledge_clear == null or not is_instance_valid(_debug_ledge_clear):
		_debug_ledge_clear = _make_debug_box("LedgeClearDebug", Color(0.2, 1.0, 0.6, 0.2))
		_debug_ledge_root.add_child(_debug_ledge_clear)
	if _debug_ledge_ray == null or not is_instance_valid(_debug_ledge_ray):
		_debug_ledge_ray = _make_debug_box("LedgeRayDebug", Color(1.0, 0.6, 0.2, 0.35))
		_debug_ledge_root.add_child(_debug_ledge_ray)
	if _debug_ledge_top == null or not is_instance_valid(_debug_ledge_top):
		_debug_ledge_top = _make_debug_sphere("LedgeTopDebug", Color(1.0, 0.9, 0.2, 0.6))
		_debug_ledge_root.add_child(_debug_ledge_top)
	if _debug_ledge_anchor == null or not is_instance_valid(_debug_ledge_anchor):
		_debug_ledge_anchor = _make_debug_sphere("LedgeAnchorDebug", Color(0.2, 1.0, 0.2, 0.6))
		_debug_ledge_root.add_child(_debug_ledge_anchor)
	if _debug_ledge_wall_normal == null or not is_instance_valid(_debug_ledge_wall_normal):
		_debug_ledge_wall_normal = _make_debug_box("LedgeNormalDebug", Color(1.0, 0.2, 0.2, 0.6))
		_debug_ledge_root.add_child(_debug_ledge_wall_normal)


func _set_ledge_debug_visible(visible: bool) -> void:
	if _debug_ledge_root and is_instance_valid(_debug_ledge_root):
		_debug_ledge_root.visible = visible


func _make_debug_box(name: String, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := BoxMesh.new()
	node.mesh = mesh
	node.material_override = _make_debug_material(color)
	return node


func _make_debug_sphere(name: String, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	node.mesh = mesh
	node.material_override = _make_debug_material(color)
	return node


func _update_debug_box(node: MeshInstance3D, center: Vector3, forward: Vector3, size: Vector3, color: Color) -> void:
	if node == null:
		return
	var mesh := node.mesh as BoxMesh
	if mesh:
		mesh.size = size
	var mat := node.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = color
	node.global_position = center
	node.look_at(center + forward, Vector3.UP)


func _update_debug_ray(node: MeshInstance3D, origin: Vector3, dir: Vector3, length: float, color: Color) -> void:
	if node == null:
		return
	var mesh := node.mesh as BoxMesh
	if mesh:
		mesh.size = Vector3(0.02, 0.02, length)
	var mat := node.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = color
	var center := origin + dir.normalized() * (length * 0.5)
	node.global_position = center
	node.look_at(center + dir, Vector3.UP)


func _update_debug_marker(node: MeshInstance3D, pos: Vector3, visible: bool, color: Color) -> void:
	if node == null:
		return
	node.visible = visible
	if not visible:
		return
	node.global_position = pos
	var mat := node.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = color


func _guess_anim_skeleton_prefix(lib: AnimationLibrary) -> String:
	if lib == null:
		return ""
	var names := lib.get_animation_list()
	for name in names:
		var anim := lib.get_animation(name)
		if anim == null:
			continue
		var track_count := anim.get_track_count()
		for i in range(track_count):
			var path := String(anim.track_get_path(i))
			var idx := path.find("Skeleton3D")
			if idx >= 0:
				return path.substr(0, idx + "Skeleton3D".length())
	return ""


func _set_mesh_transparent(mesh: MeshInstance3D, transparent: bool, hide_all: bool, surface_indices: Array) -> void:
	if mesh == null:
		return
	if transparent:
		if not _fp_hidden_materials.has(mesh):
			var entry := {
				"override": mesh.material_override,
				"surfaces": []
			}
			if mesh.mesh:
				var surf_count := mesh.mesh.get_surface_count()
				for i in range(surf_count):
					entry.surfaces.append(mesh.get_surface_override_material(i))
			_fp_hidden_materials[mesh] = entry
		if hide_all:
			if first_person_override_material:
				mesh.material_override = first_person_override_material
			elif mesh.material_override:
				var dup := mesh.material_override.duplicate()
				_apply_transparent_material(dup)
				mesh.material_override = dup
		if mesh.mesh:
			var count := mesh.mesh.get_surface_count()
			var apply_all := hide_all or surface_indices.is_empty()
			for i in range(count):
				if not apply_all and not surface_indices.has(i):
					continue
				if first_person_override_material:
					mesh.set_surface_override_material(i, first_person_override_material)
				else:
					var mat := mesh.get_surface_override_material(i)
					if mat == null:
						mat = mesh.mesh.surface_get_material(i)
					if mat == null:
						continue
					var dup2 := mat.duplicate()
					_apply_transparent_material(dup2)
					mesh.set_surface_override_material(i, dup2)
	else:
		if not _fp_hidden_materials.has(mesh):
			return
		var entry2: Dictionary = _fp_hidden_materials[mesh]
		var original_override: Material = null
		if entry2.get("override") is Material:
			original_override = entry2.get("override")
		mesh.material_override = original_override
		var surfaces: Array = []
		var raw_surfaces: Variant = entry2.get("surfaces")
		if raw_surfaces is Array:
			surfaces = raw_surfaces
		if mesh.mesh:
			var surf_count2 := mesh.mesh.get_surface_count()
			for i2 in range(surf_count2):
				var original_mat: Material = null
				if i2 < surfaces.size() and surfaces[i2] is Material:
					original_mat = surfaces[i2]
				mesh.set_surface_override_material(i2, original_mat)
		_fp_hidden_materials.erase(mesh)


func _apply_transparent_material(mat: Material) -> void:
	if mat == null:
		return
	if mat is BaseMaterial3D:
		var base: BaseMaterial3D = mat as BaseMaterial3D
		base.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var col: Color = base.albedo_color
		col.a = 0.0
		base.albedo_color = col
	elif "transparency" in mat and "albedo_color" in mat:
		mat.set("transparency", BaseMaterial3D.TRANSPARENCY_ALPHA)
		var col2: Color = Color(0.0, 0.0, 0.0, 0.0)
		var raw_col: Variant = mat.get("albedo_color")
		if raw_col is Color:
			col2 = raw_col
			col2.a = 0.0
			mat.set("albedo_color", col2)


func _get_hide_surface_indices(mesh: MeshInstance3D) -> Array:
	var indices: Array = []
	if mesh == null or mesh.mesh == null:
		return indices
	if first_person_hide_materials.is_empty():
		return indices
	var keys := first_person_hide_materials
	var mesh_name_lc := mesh.name.to_lower()
	var surf_count := mesh.mesh.get_surface_count()
	for key in keys:
		if key == "":
			continue
		var key_str := String(key)
		if key_str.find("/") >= 0:
			var parts := key_str.split("/", false)
			if parts.size() >= 2:
				var mesh_key := parts[0].strip_edges().to_lower()
				var id_key := parts[1].strip_edges().to_lower()
				if mesh_key == "" or mesh_name_lc.find(mesh_key) >= 0:
					if id_key == "any":
						for i in range(surf_count):
							if not indices.has(i):
								indices.append(i)
						continue
					var idx := int(id_key)
					if idx >= 0 and idx < surf_count and not indices.has(idx):
						indices.append(idx)
			continue
		var key_lc := key.to_lower()
		for i2 in range(surf_count):
			var mat := mesh.get_surface_override_material(i2)
			if mat == null:
				mat = mesh.mesh.surface_get_material(i2)
			if mat == null:
				continue
			if _material_name_matches(mat, PackedStringArray([key_lc])):
				if not indices.has(i2):
					indices.append(i2)
	return indices


func _apply_wall_jump_root_yaw_suppress() -> void:
	var skeleton := _find_primary_skeleton(_ensure_model_root())
	if skeleton == null:
		return
	if _wall_jump_root_bone_idx < 0:
		_wall_jump_root_bone_idx = _find_root_bone_index(skeleton)
	if _wall_jump_root_bone_idx < 0:
		return
	var pose: Transform3D
	if skeleton.has_method("get_bone_global_pose_no_override"):
		pose = skeleton.call("get_bone_global_pose_no_override", _wall_jump_root_bone_idx)
	else:
		pose = skeleton.get_bone_global_pose(_wall_jump_root_bone_idx)
	var forward := -pose.basis.z
	forward.y = 0.0
	if forward.length() <= 0.001:
		return
	forward = forward.normalized()
	var yaw := atan2(forward.x, forward.z)
	pose.basis = Basis(Vector3.UP, -yaw) * pose.basis
	skeleton.set_bone_global_pose_override(_wall_jump_root_bone_idx, pose, 1.0, true)


func _clear_wall_jump_root_yaw_suppress() -> void:
	if _wall_jump_root_bone_idx < 0:
		return
	var skeleton := _find_primary_skeleton(_ensure_model_root())
	if skeleton == null:
		return
	skeleton.set_bone_global_pose_override(_wall_jump_root_bone_idx, Transform3D.IDENTITY, 0.0, false)


func _apply_root_motion_suppress() -> void:
	if not suppress_root_motion:
		_clear_root_motion_suppress()
		return
	var skeleton := _find_primary_skeleton(_ensure_model_root())
	if skeleton == null:
		return
	if _root_motion_bone_idx < 0:
		_root_motion_bone_idx = _find_root_motion_bone_index(skeleton)
	if _root_motion_bone_idx < 0:
		return
	var base: Transform3D
	if skeleton.has_method("get_bone_global_pose_no_override"):
		base = skeleton.call("get_bone_global_pose_no_override", _root_motion_bone_idx)
	else:
		base = skeleton.get_bone_global_pose(_root_motion_bone_idx)
	var pose := skeleton.get_bone_global_pose(_root_motion_bone_idx)
	if suppress_root_motion_translation:
		pose.origin = base.origin
	if suppress_root_motion_rotation:
		pose.basis = base.basis
	skeleton.set_bone_global_pose_override(_root_motion_bone_idx, pose, 1.0, true)


func _clear_root_motion_suppress() -> void:
	if _root_motion_bone_idx < 0:
		return
	var skeleton := _find_primary_skeleton(_ensure_model_root())
	if skeleton == null:
		return
	skeleton.set_bone_global_pose_override(_root_motion_bone_idx, Transform3D.IDENTITY, 0.0, false)


func _find_root_motion_bone_index(skeleton: Skeleton3D) -> int:
	if skeleton == null:
		return -1
	for name in root_motion_bone_names:
		var idx := skeleton.find_bone(String(name))
		if idx >= 0:
			return idx
	# Fallback to wall-jump list if custom list fails.
	for name in wall_jump_root_bone_names:
		var idx2 := skeleton.find_bone(String(name))
		if idx2 >= 0:
			return idx2
	return -1


func _find_root_bone_index(skeleton: Skeleton3D) -> int:
	if skeleton == null:
		return -1
	for name in wall_jump_root_bone_names:
		if name == "":
			continue
		var idx := skeleton.find_bone(name)
		if idx >= 0:
			return idx
	return -1


func _material_name_matches(mat: Material, keys: PackedStringArray) -> bool:
	if mat == null:
		return false
	var mat_name := mat.resource_name.to_lower()
	for key in keys:
		if key == "":
			continue
		if mat_name.find(key.to_lower()) >= 0:
			return true
	return false


func _ensure_visual_root() -> Node3D:
	var root := get_node_or_null("VisualRoot")
	if root == null:
		root = Node3D.new()
		root.name = "VisualRoot"
		add_child(root)
	if root.top_level:
		root.top_level = false
	return root


func _ensure_model_root() -> Node3D:
	var visual_root := _ensure_visual_root()
	if visual_root == null:
		return null
	var model_root := visual_root.get_node_or_null("ModelRoot")
	if model_root == null:
		model_root = Node3D.new()
		model_root.name = "ModelRoot"
		visual_root.add_child(model_root)
	if model_root.top_level:
		model_root.top_level = false
	return model_root


func _refresh_anim_driver() -> void:
	_anim_driver = _find_anim_driver()
	if _anim_driver and _anim_driver.has_method("refresh_targets"):
		_anim_driver.refresh_targets()
	if _controller_ctx:
		_controller_ctx.anim = _anim_driver


func _sync_anim_driver_paths(model_root: Node) -> void:
	if _anim_driver == null or model_root == null:
		return
	if _anim_driver.target_root_path == NodePath(""):
		_anim_driver.target_root_path = NodePath("../VisualRoot/ModelRoot")
	if _anim_driver.animation_player_path == NodePath(""):
		var anim_player := model_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if anim_player:
			_anim_driver.animation_player_path = model_root.get_path_to(anim_player)
	if _anim_driver.animation_tree_path == NodePath(""):
		var anim_tree := model_root.find_child("AnimationTree", true, false) as AnimationTree
		if anim_tree:
			_anim_driver.animation_tree_path = model_root.get_path_to(anim_tree)


func _bind_animation_library(data: ModelData3D, root: Node) -> void:
	if data == null or data.animation_library == null or root == null:
		return
	var anim_player: AnimationPlayer = null
	if data.animation_player_path != NodePath(""):
		anim_player = root.get_node_or_null(data.animation_player_path) as AnimationPlayer
	if anim_player == null:
		anim_player = root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player == null:
		anim_player = AnimationPlayer.new()
		anim_player.name = "AnimationPlayer"
		root.add_child(anim_player)
	_clear_animation_player_libraries(anim_player)
	var lib_name := data.animation_library_name
	if lib_name == StringName():
		lib_name = &"biped"
	var lib := data.animation_library
	lib = _maybe_remap_library_for_root(lib, root)
	anim_player.add_animation_library(lib_name, lib)
	_configure_animation_player(anim_player)


func _bind_animation_library_to_player(data: ModelData3D, anim_player: AnimationPlayer, root: Node) -> void:
	if data == null or data.animation_library == null or anim_player == null:
		return
	_clear_animation_player_libraries(anim_player)
	var lib_name := data.animation_library_name
	if lib_name == StringName():
		lib_name = &"biped"
	var lib := data.animation_library
	if root:
		lib = _maybe_remap_library_for_root(lib, root)
	anim_player.add_animation_library(lib_name, lib)
	if root:
		var root_path := anim_player.get_path_to(root)
		if root_path != NodePath(""):
			anim_player.root_node = root_path
	_configure_animation_player(anim_player)


func _clear_animation_player_libraries(anim_player: AnimationPlayer) -> void:
	if anim_player == null:
		return
	anim_player.stop()
	var libs: Array = anim_player.get_animation_library_list()
	for lib in libs:
		anim_player.remove_animation_library(lib)


func _configure_animation_player(anim_player: AnimationPlayer) -> void:
	if anim_player == null:
		return
	if "playback_process_mode" in anim_player:
		anim_player.playback_process_mode = AnimationPlayer.ANIMATION_PROCESS_IDLE
	if "playback_active" in anim_player:
		anim_player.playback_active = true
	anim_player.active = true
	var current_root := anim_player.root_node
	var has_valid_root := current_root != NodePath("")
	if has_valid_root:
		var root_node := anim_player.get_node_or_null(current_root)
		if root_node == null:
			has_valid_root = false
		else:
			var direct_armature := root_node.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
			var direct_skel := root_node.get_node_or_null("Skeleton3D") as Skeleton3D
			if direct_armature == null and direct_skel == null:
				var any_skel := root_node.find_child("Skeleton3D", true, false) as Skeleton3D
				if any_skel:
					has_valid_root = false
				else:
					has_valid_root = false
	if not has_valid_root:
		var root_path := _find_anim_root_path(anim_player)
		if root_path != NodePath(""):
			anim_player.root_node = root_path


func _bind_mesh_skeletons(root: Node) -> void:
	if root == null:
		return
	var skeleton := _find_primary_skeleton(root)
	if skeleton == null:
		return
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	for mesh in meshes:
		var mi := mesh as MeshInstance3D
		if mi == null:
			continue
		var path := mi.get_path_to(skeleton)
		if mi.skeleton != path:
			mi.skeleton = path
		if mi.skin == null:
			var skin := _get_skeleton_skin(skeleton)
			if skin:
				mi.skin = skin


func _prune_model_animation_players(root: Node) -> void:
	if root == null:
		return
	var players := root.find_children("*", "AnimationPlayer", true, false)
	for child in players:
		var anim := child as AnimationPlayer
		if anim == null:
			continue
		_detach_and_free_node(anim)


func _find_primary_skeleton(root: Node) -> Skeleton3D:
	var skeletons := root.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return null
	var best: Skeleton3D = null
	var best_bones := -1
	for skel in skeletons:
		var s := skel as Skeleton3D
		if s == null:
			continue
		var count := s.get_bone_count()
		if count > best_bones:
			best_bones = count
			best = s
	return best


func _get_skeleton_skin(skeleton: Skeleton3D) -> Skin:
	if skeleton == null:
		return null
	if skeleton.has_method("get_skin"):
		var existing = skeleton.call("get_skin")
		if existing is Skin:
			return existing
	if skeleton.has_method("create_skin_from_rest"):
		var created = skeleton.call("create_skin_from_rest")
		if created is Skin:
			if skeleton.has_method("set_skin"):
				skeleton.call("set_skin", created)
			return created
	return null


func _debug_dump_model_binding(root: Node) -> void:
	if root == null:
		return
	var verbose := false
	if _anim_driver and "debug_verbose" in _anim_driver:
		verbose = _anim_driver.debug_verbose
	print("Model binding debug")
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	print("- mesh_count:", meshes.size())
	var max_items: int = meshes.size()
	if not verbose and max_items > 5:
		max_items = 5
	for i in range(max_items):
		var mi := meshes[i] as MeshInstance3D
		if mi == null:
			continue
		var skel_path := mi.skeleton
		var skel_ok := false
		if skel_path != NodePath(""):
			var skel_node := mi.get_node_or_null(skel_path)
			skel_ok = skel_node is Skeleton3D
		var has_skin := mi.skin != null
		var surf_count := 0
		if mi.mesh:
			surf_count = mi.mesh.get_surface_count()
		print("- mesh:", mi.get_path(), "skeleton:", String(skel_path), "skeleton_ok:", skel_ok, "skin:", has_skin, "surfaces:", surf_count)


func _find_anim_root_path(anim_player: AnimationPlayer) -> NodePath:
	if anim_player == null:
		return NodePath("")
	var current: Node = anim_player
	while current:
		if current.get_node_or_null("Armature/Skeleton3D"):
			return anim_player.get_path_to(current)
		var direct_skel := current.get_node_or_null("Skeleton3D") as Skeleton3D
		if direct_skel:
			return anim_player.get_path_to(current)
		var skel := current.find_child("Skeleton3D", true, false) as Skeleton3D
		if skel and skel.get_parent():
			return anim_player.get_path_to(skel.get_parent())
		current = current.get_parent()
	return NodePath("")


func _requires_library_remap(root: Node) -> bool:
	if root == null:
		return false
	if root.get_node_or_null("Armature/Skeleton3D"):
		return false
	var skel := root.find_child("Skeleton3D", true, false)
	return skel != null


func _library_uses_armature_paths(lib: AnimationLibrary) -> bool:
	if lib == null:
		return false
	var names := lib.get_animation_list()
	var max_anims: int = min(names.size(), 5)
	for i in range(max_anims):
		var anim := lib.get_animation(names[i])
		if anim == null:
			continue
		var track_count := anim.get_track_count()
		var max_tracks: int = min(track_count, 20)
		var saw_armature := false
		var saw_skeleton := false
		for t in range(max_tracks):
			var path := String(anim.track_get_path(t))
			if path.begins_with("Armature/"):
				saw_armature = true
			elif path.begins_with("Skeleton3D"):
				saw_skeleton = true
			if saw_armature and saw_skeleton:
				break
		if saw_armature:
			return true
		if saw_skeleton:
			return false
	return false


func _get_library_track_prefix(lib: AnimationLibrary) -> String:
	if lib == null:
		return ""
	var names := lib.get_animation_list()
	var max_anims: int = min(names.size(), 5)
	for i in range(max_anims):
		var anim := lib.get_animation(names[i])
		if anim == null:
			continue
		var track_count := anim.get_track_count()
		var max_tracks: int = min(track_count, 30)
		for t in range(max_tracks):
			var path_str := String(anim.track_get_path(t))
			if path_str.find(":") == -1:
				continue
			if path_str.find("Skeleton3D") == -1:
				continue
			var colon := path_str.find(":")
			if colon > 0:
				return path_str.substr(0, colon)
	return ""


func _maybe_remap_library_for_root(lib: AnimationLibrary, root: Node) -> AnimationLibrary:
	if lib == null or root == null:
		return lib
	var prefix := _get_library_track_prefix(lib)
	var out := lib
	var skeleton := _find_primary_skeleton(root)
	if skeleton == null:
		return lib
	if prefix != "":
		var target_prefix := String(root.get_path_to(skeleton))
		if target_prefix != "" and target_prefix != prefix:
			out = _remap_animation_library(out, prefix, target_prefix)
	if suppress_root_motion and (suppress_root_motion_translation or suppress_root_motion_rotation):
		out = _strip_root_transform_tracks(out, root)
	return out


func _remap_animation_library(lib: AnimationLibrary, from_prefix: String, to_prefix: String) -> AnimationLibrary:
	if lib == null:
		return null
	var out := AnimationLibrary.new()
	var names := lib.get_animation_list()
	for name in names:
		var anim := lib.get_animation(name)
		if anim == null:
			continue
		var dup: Animation = anim.duplicate()
		_retarget_animation_paths(dup, from_prefix, to_prefix)
		out.add_animation(name, dup)
	return out


func _strip_root_transform_tracks(lib: AnimationLibrary, root: Node) -> AnimationLibrary:
	if lib == null or root == null:
		return lib
	var out := AnimationLibrary.new()
	var names := lib.get_animation_list()
	for name in names:
		var anim := lib.get_animation(name)
		if anim == null:
			continue
		var dup: Animation = anim.duplicate()
		_remove_non_skeleton_transform_tracks(dup, root)
		out.add_animation(name, dup)
	return out


func _remove_non_skeleton_transform_tracks(anim: Animation, root: Node) -> void:
	if anim == null or root == null:
		return
	for track_idx in range(anim.get_track_count() - 1, -1, -1):
		var track_type := anim.track_get_type(track_idx)
		if track_type != Animation.TYPE_POSITION_3D \
			and track_type != Animation.TYPE_ROTATION_3D \
			and track_type != Animation.TYPE_SCALE_3D:
			continue
		var node_path := anim.track_get_path(track_idx)
		var path_str := String(node_path)
		var node_only_str := path_str
		var colon := path_str.find(":")
		if colon >= 0:
			node_only_str = path_str.substr(0, colon)
		var node_only := NodePath(node_only_str)
		var node := root.get_node_or_null(node_only)
		if node == null:
			continue
		if node is Skeleton3D:
			continue
		anim.remove_track(track_idx)


func _retarget_animation_paths(anim: Animation, from_prefix: String, to_prefix: String) -> void:
	if anim == null or from_prefix == "" or to_prefix == "":
		return
	for track_idx in range(anim.get_track_count()):
		var path := anim.track_get_path(track_idx)
		var path_str := String(path)
		if path_str.begins_with(from_prefix):
			var rest := path_str.substr(from_prefix.length())
			anim.track_set_path(track_idx, NodePath(to_prefix + rest))


func _force_double_sided(root: Node) -> void:
	if root == null:
		return
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	for mesh in meshes:
		var mi := mesh as MeshInstance3D
		if mi == null:
			continue
		if mi.material_override:
			var mat := mi.material_override.duplicate()
			_apply_double_sided_material(mat)
			mi.material_override = mat
		if mi.mesh:
			var surface_count := mi.mesh.get_surface_count()
			for i in range(surface_count):
				var mat2 := mi.mesh.surface_get_material(i)
				if mat2 == null:
					continue
				var dup := mat2.duplicate()
				_apply_double_sided_material(dup)
				mi.set_surface_override_material(i, dup)


func _apply_double_sided_material(mat: Material) -> void:
	if mat == null:
		return
	if mat is BaseMaterial3D:
		(mat as BaseMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	elif "cull_mode" in mat:
		mat.set("cull_mode", BaseMaterial3D.CULL_DISABLED)


func _set_debug_mesh_visible(show: bool) -> void:
	var model_root := _ensure_model_root()
	if model_root == null:
		return
	if show:
		if _debug_mesh == null or not is_instance_valid(_debug_mesh):
			_debug_mesh = MeshInstance3D.new()
			_debug_mesh.name = "DebugMesh"
			var box := BoxMesh.new()
			box.size = Vector3(0.6, 1.2, 0.6)
			_debug_mesh.mesh = box
			model_root.add_child(_debug_mesh)
		_debug_mesh.visible = true
	elif _debug_mesh and is_instance_valid(_debug_mesh):
		_debug_mesh.visible = false


func _apply_pivot_defaults() -> void:
	if not pivot_align_bottom:
		_apply_visual_pivot_offset(pivot_offset)
		return
	var collision: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	var offset := pivot_offset
	if collision:
		var shape: Shape3D = collision.shape
		var height := _get_shape_height(shape)
		if height > 0.0:
			offset.y = height * 0.5 + pivot_offset.y
			collision.position = Vector3(pivot_offset.x, offset.y, pivot_offset.z)
	_apply_visual_pivot_offset(offset)


func _apply_visual_pivot_offset(offset: Vector3) -> void:
	_visual_pivot_base = offset
	_apply_visual_offset()


func _apply_visual_offset() -> void:
	var visual_root := get_node_or_null("VisualRoot")
	var offset := _visual_pivot_base + Vector3(0.0, _anim_floor_offset, 0.0)
	if visual_root and visual_root is Node3D:
		visual_root.position = offset
		return
	for child in get_children():
		if child is MeshInstance3D:
			child.position = offset


func set_anim_floor_offset(offset: float) -> void:
	_anim_floor_offset = offset
	_apply_visual_offset()


func get_anim_floor_offset(state_name: String, anim_name: String = "") -> float:
	if model_data and "anim_state_offsets" in model_data:
		var state_offsets = model_data.anim_state_offsets
		if state_offsets is Dictionary and state_offsets.has(state_name):
			return float(state_offsets[state_name])
		if state_name == "stand_up" and state_offsets is Dictionary and state_offsets.has("crouch_exit"):
			return float(state_offsets["crouch_exit"])
		if state_name == "crouch_exit" and state_offsets is Dictionary and state_offsets.has("stand_up"):
			return float(state_offsets["stand_up"])
		if anim_name != "" and state_offsets is Dictionary and state_offsets.has(anim_name):
			return float(state_offsets[anim_name])
	return 0.0


func _strip_anim_prefix(name: String) -> String:
	var idx := name.rfind("/")
	if idx != -1:
		return name.substr(idx + 1)
	return name


func _get_shape_height(shape: Shape3D) -> float:
	if shape == null:
		return 0.0
	if shape is BoxShape3D:
		return shape.size.y
	if shape is CapsuleShape3D:
		return shape.height + shape.radius * 2.0
	if shape is CylinderShape3D:
		return shape.height
	if shape is SphereShape3D:
		return shape.radius * 2.0
	return 0.0


func _update_wall_debug(params: MovementData3D, left_hit: bool, right_hit: bool) -> void:
	if not debug_wall_checks:
		_set_wall_debug_visible(false)
		return
	_ensure_wall_debug_nodes()
	_set_wall_debug_visible(true)
	var ray_len := debug_wall_ray_length
	if ray_len <= 0.0 and params:
		ray_len = maxf(0.2, params.wall_check_distance)
	var left_len := ray_len
	var right_len := ray_len
	var left_color := debug_wall_ray_color_hit if left_hit else debug_wall_ray_color_clear
	var right_color := debug_wall_ray_color_hit if right_hit else debug_wall_ray_color_clear
	_update_wall_ray(_debug_wall_left_mesh, _debug_wall_left_origin, _debug_wall_left_dir, left_len, left_color)
	_update_wall_ray(_debug_wall_right_mesh, _debug_wall_right_origin, _debug_wall_right_dir, right_len, right_color)
	if _debug_wall_left_hit_mesh:
		_debug_wall_left_hit_mesh.visible = left_hit
		if left_hit:
			_debug_wall_left_hit_mesh.global_position = _debug_wall_left_hit
	if _debug_wall_right_hit_mesh:
		_debug_wall_right_hit_mesh.visible = right_hit
		if right_hit:
			_debug_wall_right_hit_mesh.global_position = _debug_wall_right_hit
	if _debug_wall_best_hit_mesh:
		_debug_wall_best_hit_mesh.visible = _debug_wall_best_hit_valid
		if _debug_wall_best_hit_valid:
			_debug_wall_best_hit_mesh.global_position = _debug_wall_best_hit
	if _debug_wall_best_ray_mesh:
		_debug_wall_best_ray_mesh.visible = _debug_wall_best_hit_valid
		if _debug_wall_best_hit_valid:
			var best_ray_len := _debug_wall_best_origin.distance_to(_debug_wall_best_hit)
			_update_wall_ray(_debug_wall_best_ray_mesh, _debug_wall_best_origin, _debug_wall_best_dir, best_ray_len, debug_wall_best_color)


func _ensure_wall_debug_nodes() -> void:
	if _debug_wall_root == null or not is_instance_valid(_debug_wall_root):
		_debug_wall_root = Node3D.new()
		_debug_wall_root.name = "WallDebug"
		add_child(_debug_wall_root)
	if _debug_wall_left_mesh == null or not is_instance_valid(_debug_wall_left_mesh):
		_debug_wall_left_mesh = MeshInstance3D.new()
		_debug_wall_left_mesh.name = "WallRayLeft"
		_debug_wall_left_mesh.mesh = BoxMesh.new()
		_debug_wall_left_mesh.material_override = _make_debug_material(debug_wall_ray_color_clear)
		_debug_wall_root.add_child(_debug_wall_left_mesh)
	if _debug_wall_right_mesh == null or not is_instance_valid(_debug_wall_right_mesh):
		_debug_wall_right_mesh = MeshInstance3D.new()
		_debug_wall_right_mesh.name = "WallRayRight"
		_debug_wall_right_mesh.mesh = BoxMesh.new()
		_debug_wall_right_mesh.material_override = _make_debug_material(debug_wall_ray_color_clear)
		_debug_wall_root.add_child(_debug_wall_right_mesh)
	if _debug_wall_left_hit_mesh == null or not is_instance_valid(_debug_wall_left_hit_mesh):
		_debug_wall_left_hit_mesh = MeshInstance3D.new()
		_debug_wall_left_hit_mesh.name = "WallHitLeft"
		var hit_mesh := SphereMesh.new()
		hit_mesh.radius = 0.04
		hit_mesh.height = 0.08
		_debug_wall_left_hit_mesh.mesh = hit_mesh
		_debug_wall_left_hit_mesh.material_override = _make_debug_material(debug_wall_ray_color_hit)
		_debug_wall_root.add_child(_debug_wall_left_hit_mesh)
	if _debug_wall_right_hit_mesh == null or not is_instance_valid(_debug_wall_right_hit_mesh):
		_debug_wall_right_hit_mesh = MeshInstance3D.new()
		_debug_wall_right_hit_mesh.name = "WallHitRight"
		var hit_mesh2 := SphereMesh.new()
		hit_mesh2.radius = 0.04
		hit_mesh2.height = 0.08
		_debug_wall_right_hit_mesh.mesh = hit_mesh2
		_debug_wall_right_hit_mesh.material_override = _make_debug_material(debug_wall_ray_color_hit)
		_debug_wall_root.add_child(_debug_wall_right_hit_mesh)
	if _debug_wall_best_hit_mesh == null or not is_instance_valid(_debug_wall_best_hit_mesh):
		_debug_wall_best_hit_mesh = MeshInstance3D.new()
		_debug_wall_best_hit_mesh.name = "WallHitBest"
		var best_mesh := SphereMesh.new()
		best_mesh.radius = 0.06
		best_mesh.height = 0.12
		_debug_wall_best_hit_mesh.mesh = best_mesh
		_debug_wall_best_hit_mesh.material_override = _make_debug_material(debug_wall_best_color)
		_debug_wall_root.add_child(_debug_wall_best_hit_mesh)
	if _debug_wall_best_ray_mesh == null or not is_instance_valid(_debug_wall_best_ray_mesh):
		_debug_wall_best_ray_mesh = MeshInstance3D.new()
		_debug_wall_best_ray_mesh.name = "WallRayBest"
		_debug_wall_best_ray_mesh.mesh = BoxMesh.new()
		_debug_wall_best_ray_mesh.material_override = _make_debug_material(debug_wall_best_color)
		_debug_wall_root.add_child(_debug_wall_best_ray_mesh)


func _set_wall_debug_visible(visible: bool) -> void:
	if _debug_wall_root and is_instance_valid(_debug_wall_root):
		_debug_wall_root.visible = visible


func _update_wall_ray(mesh: MeshInstance3D, origin: Vector3, direction: Vector3, length: float, color: Color) -> void:
	if mesh == null:
		return
	var dir := direction
	dir.y = 0.0
	if dir.length() <= 0.001:
		dir = -global_transform.basis.z
	dir = dir.normalized()
	var size := Vector3(0.03, 0.03, maxf(0.05, length))
	var box := mesh.mesh as BoxMesh
	if box:
		box.size = size
	var mat := mesh.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = color
	var pos := origin + dir * (size.z * 0.5)
	mesh.global_position = pos
	mesh.look_at(pos + dir, Vector3.UP)


func _debug_uncommanded_motion_check(params: MovementData3D, delta: float) -> void:
	if not debug_uncommanded_motion:
		_debug_uncommanded_timer = 0.0
		_debug_last_pos_valid = false
		return
	if params == null:
		return
	var input_vec: Vector2 = Vector2(input_x, input_y)
	var src: IInputSource = _get_input_source()
	var raw: Vector2 = Vector2.ZERO
	var action_held := false
	if src:
		raw = src.get_move_vector()
		action_held = src.is_action_held()
	var horiz: Vector2 = Vector2(velocity.x, velocity.z)
	_debug_uncommanded_timer += delta
	if _debug_uncommanded_timer < 0.25:
		return
	_debug_uncommanded_timer = 0.0
	var pos: Vector3 = global_transform.origin
	var visual_root: Node3D = get_node_or_null("VisualRoot") as Node3D
	var visual_pos: Vector3 = pos
	if visual_root:
		visual_pos = visual_root.global_transform.origin
	var pos_delta: Vector3 = Vector3.ZERO
	var visual_delta: Vector3 = Vector3.ZERO
	if _debug_last_pos_valid:
		pos_delta = pos - _debug_last_pos
		visual_delta = visual_pos - _debug_last_visual_pos
	_debug_last_pos = pos
	_debug_last_visual_pos = visual_pos
	_debug_last_pos_valid = true
	var input_len: float = input_vec.length()
	var deadzone: float = params.move_deadzone
	var uncommanded: bool = horiz.length() > debug_uncommanded_threshold and input_len <= deadzone
	var src_name: String = ""
	if src:
		var script: Script = src.get_script()
		if script:
			src_name = script.get_global_name()
		if src_name == "":
			src_name = src.get_class()
	print("Motion dbg:",
		"uncommanded=", uncommanded,
		"input_raw=", raw,
		"input_src=", src_name if src_name != "" else "<null>",
		"action=", action_held,
		"in_len=", input_len,
		"deadzone=", deadzone,
		"vel=", velocity,
		"pos_delta=", pos_delta,
		"visual_delta=", visual_delta,
		"ledge_hold=", ledge_holding,
		"ledge_climb=", ledge_climbing,
		"on_floor=", is_on_floor(),
		"dash=", dashing,
		"roll=", roll_active,
		"sprint=", sprint_active,
		"wall_jump=", wall_jumping,
		"wall_force=", _wall_jump_force_timer,
		"wall_no_input=", _wall_jump_no_input_timer,
		"jumping=", jumping,
		"in_air=", in_air,
		"falling=", falling,
		"crouch=", crouching,
		"sneak=", sneaking,
		"cam_ctx=", camera_context)


func _make_debug_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	return mat


func _has_geometry(node: Node) -> bool:
	if node is GeometryInstance3D:
		return true
	for child in node.get_children():
		if _has_geometry(child):
			return true
	return false
