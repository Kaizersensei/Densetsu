extends Resource
class_name MovementData3D

@export_category("Identity")
## Controls id.
@export var id: String = ""
## Controls description.
@export var description: String = ""
## Controls tags.
@export var tags: PackedStringArray = PackedStringArray()

@export_category("Base Movement")
## Controls gravity.
@export var gravity: float = 9.8
## Speed for walk.
@export var walk_speed: float = 4.0
## Speed for run.
@export var run_speed: float = 6.5
## Enable sprint.
@export var sprint_enabled: bool = true
## Controls sprint double tap window.
@export var sprint_double_tap_window: float = 0.3
## Controls sprint boost multiplier.
@export var sprint_boost_multiplier: float = 1.5
## Controls sprint boost fade time.
@export var sprint_boost_fade_time: float = 3.0
## Controls acceleration.
@export var acceleration: float = 20.0
## Controls deceleration.
@export var deceleration: float = 20.0
## Controls move deadzone.
@export var move_deadzone: float = 0.15
## Controls turn rate.
@export var turn_rate: float = 3.0
## Controls turn smooth.
@export var turn_smooth: float = 8.0
## Enable turn invert.
@export var turn_invert: bool = true

@export_category("Advanced Movement")
## Controls max slope angle.
@export var max_slope_angle: float = 45.0
## Height for step.
@export var step_height: float = 0.3
## Controls step snap max angle.
@export var step_snap_max_angle: float = 10.0
## Distance for step sensor.
@export var step_sensor_distance: float = 0.2
## Speed for step snap smooth.
@export var step_snap_smooth_speed: float = 10.0
## Controls air control.
@export var air_control: float = 0.6
## Controls air accel.
@export var air_accel: float = 12.0
## Controls air decel.
@export var air_decel: float = 12.0
## Speed for max fall.
@export var max_fall_speed: float = 30.0
## Controls floor leave delay.
@export var floor_leave_delay: float = 0.5

@export_category("Jump")
## Speed for jump.
@export var jump_speed: float = 8.0
## Speed for double jump.
@export var double_jump_speed: float = 8.0
## Controls max jumps.
@export var max_jumps: int = 1
## Controls coyote time.
@export var coyote_time: float = 0.12
## Controls jump buffer time.
@export var jump_buffer_time: float = 0.12
## Enable require jump release.
@export var require_jump_release: bool = true
## Speed for double jump clamp fall.
@export var double_jump_clamp_fall_speed: float = 0.0
## Controls jump cut.
@export var jump_cut: float = 0.5

@export_category("Wall")
## Enable wall jump.
@export var wall_jump_enabled: bool = true
## Distance for wall check.
@export var wall_check_distance: float = 0.6
## Height for wall check.
@export var wall_check_height: float = 0.9
## Enable wall check multi ray.
@export var wall_check_multi_ray: bool = true
## Enable wall check forward.
@export var wall_check_forward: bool = true
## Enable wall check diagonals.
@export var wall_check_diagonals: bool = true
## Speed for wall jump up.
@export var wall_jump_up_speed: float = 7.0
## Speed for wall jump push.
@export var wall_jump_push_speed: float = 6.0
## Controls wall jump no input time.
@export var wall_jump_no_input_time: float = 0.2
## Controls wall jump duration.
@export var wall_jump_duration: float = 0.2
## Controls wall jump lock time.
@export var wall_jump_lock_time: float = 0.15

@export_category("Dash")
## Speed for dash.
@export var dash_speed: float = 10.0
## Controls dash time.
@export var dash_time: float = 0.2
## Controls dash cooldown.
@export var dash_cooldown: float = 0.1
## Enable dash allow air.
@export var dash_allow_air: bool = false
## Enable dash allow double tap.
@export var dash_allow_double_tap: bool = true
## Controls dash double tap window.
@export var dash_double_tap_window: float = 0.25

@export_category("Roll")
## Speed for roll.
@export var roll_speed: float = 7.0
## Controls roll time.
@export var roll_time: float = 0.35
## Controls roll cooldown.
@export var roll_cooldown: float = 0.2

@export_category("Posture")
## Height for crouch.
@export var crouch_height: float = 1.1
## Height for crouch walk.
@export var crouch_walk_height: float = 1.45
## Controls crouch transition time.
@export var crouch_transition_time: float = 0.15
## Controls crouch walk transition time.
@export var crouch_walk_transition_time: float = 0.15
## Controls crouch walk move threshold.
@export var crouch_walk_move_threshold: float = 0.1
## Height for roll crouch.
@export var roll_crouch_height: float = 0.0
## Controls roll crouch transition time.
@export var roll_crouch_transition_time: float = 0.0
## Controls crouch stand transition time.
@export var crouch_stand_transition_time: float = 0.15
## Speed for crouch.
@export var crouch_speed: float = 1.5
## Speed for sneak.
@export var sneak_speed: float = 2.5

@export_category("Drop Through")
## Controls drop through time.
@export var drop_through_time: float = 0.2
## Controls drop through layer.
@export var drop_through_layer: int = 0
## Speed for drop through.
@export var drop_through_speed: float = 2.0

@export_category("Fall")
## Speed for high fall.
@export var high_fall_speed: float = 12.0
## Controls high fall time.
@export var high_fall_time: float = 0.4
