extends Resource
class_name MovementData3D

@export_category("Identity")
@export var id: String = ""
@export var description: String = ""
@export var tags: PackedStringArray = PackedStringArray()

@export_category("Base Movement")
@export var gravity: float = 9.8
@export var walk_speed: float = 4.0
@export var run_speed: float = 6.5
@export var acceleration: float = 20.0
@export var deceleration: float = 20.0
@export var turn_rate: float = 3.0
@export var turn_smooth: float = 8.0
@export var turn_invert: bool = true

@export_category("Advanced Movement")
@export var max_slope_angle: float = 45.0
@export var step_height: float = 0.3
@export var step_snap_max_angle: float = 10.0
@export var step_sensor_distance: float = 0.2
@export var step_snap_smooth_speed: float = 10.0
@export var air_control: float = 0.6
@export var air_accel: float = 12.0
@export var air_decel: float = 12.0
@export var max_fall_speed: float = 30.0

@export_category("Jump")
@export var jump_speed: float = 8.0
@export var double_jump_speed: float = 8.0
@export var max_jumps: int = 1
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12
@export var require_jump_release: bool = true
@export var double_jump_clamp_fall_speed: float = 0.0
@export var jump_cut: float = 0.5

@export_category("Wall")
@export var wall_jump_enabled: bool = true
@export var wall_check_distance: float = 0.6
@export var wall_check_height: float = 0.9
@export var wall_slide_gravity_scale: float = 0.4
@export var wall_slide_max_fall_speed: float = 6.0
@export var wall_jump_up_speed: float = 7.0
@export var wall_jump_push_speed: float = 6.0
@export var wall_jump_lock_time: float = 0.15

@export_category("Dash")
@export var dash_speed: float = 10.0
@export var dash_time: float = 0.2
@export var dash_cooldown: float = 0.1
@export var dash_allow_air: bool = false
@export var dash_allow_double_tap: bool = true
@export var dash_double_tap_window: float = 0.25

@export_category("Roll")
@export var roll_speed: float = 7.0
@export var roll_time: float = 0.35
@export var roll_cooldown: float = 0.2

@export_category("Posture")
@export var crouch_height: float = 1.1
@export var crouch_speed: float = 1.5
@export var sneak_speed: float = 2.5

@export_category("Drop Through")
@export var drop_through_time: float = 0.2
@export var drop_through_layer: int = 0
@export var drop_through_speed: float = 2.0

@export_category("Fall")
@export var high_fall_speed: float = 12.0
@export var high_fall_time: float = 0.4
