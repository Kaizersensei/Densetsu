extends IInputSource
class_name PlayerInputSource

var player_number: int = 1


func _init(p_player_number: int = 1) -> void:
	player_number = p_player_number


func get_move_vector() -> Vector2:
	var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return Vector2(x, y)


func is_jump_pressed() -> bool:
	return Input.is_action_pressed("jump")


func is_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed("jump")


func is_jump_just_released() -> bool:
	return Input.is_action_just_released("jump")


func is_run_held() -> bool:
	return Input.is_action_pressed("run")


func is_aim_held() -> bool:
	if InputMap.has_action("aim"):
		return Input.is_action_pressed("aim")
	return false


func is_dash_just_pressed() -> bool:
	if InputMap.has_action("dash"):
		return Input.is_action_just_pressed("dash")
	return false

func is_dash_held() -> bool:
	if InputMap.has_action("dash"):
		return Input.is_action_pressed("dash")
	return false


func is_roll_just_pressed() -> bool:
	if InputMap.has_action("roll"):
		return Input.is_action_just_pressed("roll")
	return false


func is_crouch_held() -> bool:
	if InputMap.has_action("crouch"):
		return Input.is_action_pressed("crouch")
	return false

func is_crouch_just_pressed() -> bool:
	if InputMap.has_action("crouch"):
		return Input.is_action_just_pressed("crouch")
	return false


func is_sneak_held() -> bool:
	if InputMap.has_action("sneak"):
		return Input.is_action_pressed("sneak")
	return false


func is_move_left_just_pressed() -> bool:
	if InputMap.has_action("move_left"):
		return Input.is_action_just_pressed("move_left")
	return false


func is_move_right_just_pressed() -> bool:
	if InputMap.has_action("move_right"):
		return Input.is_action_just_pressed("move_right")
	return false
