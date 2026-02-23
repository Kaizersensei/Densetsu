extends RefCounted
class_name IInputSource


func get_move_vector() -> Vector2:
	return Vector2.ZERO


func get_side_scroller_vector() -> Vector2:
	return Vector2.ZERO


func get_depth_axis() -> float:
	return 0.0


func is_jump_pressed() -> bool:
	return false


func is_jump_just_pressed() -> bool:
	return false


func is_jump_just_released() -> bool:
	return false


func is_run_held() -> bool:
	return false


func is_run_just_pressed() -> bool:
	return false


func is_modifier_held() -> bool:
	return is_run_held()


func is_modifier_just_pressed() -> bool:
	return is_run_just_pressed()


func is_aim_held() -> bool:
	return false


func is_dash_just_pressed() -> bool:
	return false

func is_dash_held() -> bool:
	return false


func is_roll_just_pressed() -> bool:
	return false


func is_crouch_held() -> bool:
	return false

func is_crouch_just_pressed() -> bool:
	return false


func is_sneak_held() -> bool:
	return false

func is_attack_just_pressed() -> bool:
	return false

func is_attack_held() -> bool:
	return false

func is_block_held() -> bool:
	return false

func is_weapon_toggle_just_pressed() -> bool:
	return false

func is_ranged_just_pressed() -> bool:
	return false


func is_move_left_just_pressed() -> bool:
	return false


func is_move_right_just_pressed() -> bool:
	return false


func is_move_up_just_pressed() -> bool:
	return false


func is_move_down_just_pressed() -> bool:
	return false


func is_camera_toggle_just_pressed() -> bool:
	return false


func is_side_scroller_toggle_just_pressed() -> bool:
	return false


func is_action_held() -> bool:
	return false
