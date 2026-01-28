extends RefCounted
class_name IInputSource


func get_move_vector() -> Vector2:
	return Vector2.ZERO


func is_jump_pressed() -> bool:
	return false


func is_jump_just_pressed() -> bool:
	return false


func is_jump_just_released() -> bool:
	return false


func is_run_held() -> bool:
	return false


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


func is_move_left_just_pressed() -> bool:
	return false


func is_move_right_just_pressed() -> bool:
	return false
