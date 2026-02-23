extends IInputSource
class_name PlayerInputSource

var player_number: int = 1


func _init(p_player_number: int = 1) -> void:
	player_number = p_player_number


func get_move_vector() -> Vector2:
	var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return Vector2(x, y)


func get_side_scroller_vector() -> Vector2:
	var has_left := InputMap.has_action("side_left")
	var has_right := InputMap.has_action("side_right")
	var has_up := InputMap.has_action("side_up")
	var has_down := InputMap.has_action("side_down")
	if has_left or has_right or has_up or has_down:
		var x := 0.0
		var y := 0.0
		if has_right:
			x += Input.get_action_strength("side_right")
		if has_left:
			x -= Input.get_action_strength("side_left")
		if has_down:
			y += Input.get_action_strength("side_down")
		if has_up:
			y -= Input.get_action_strength("side_up")
		return Vector2(x, y)
	return get_move_vector()


func get_depth_axis() -> float:
	var depth := 0.0
	if InputMap.has_action("move_depth_out"):
		depth += Input.get_action_strength("move_depth_out")
	if InputMap.has_action("move_depth_in"):
		depth -= Input.get_action_strength("move_depth_in")
	return depth


func is_jump_pressed() -> bool:
	return Input.is_action_pressed("jump")


func is_jump_just_pressed() -> bool:
	return Input.is_action_just_pressed("jump")


func is_jump_just_released() -> bool:
	return Input.is_action_just_released("jump")


func is_run_held() -> bool:
	return Input.is_action_pressed("run")


func is_run_just_pressed() -> bool:
	return Input.is_action_just_pressed("run")


func is_modifier_held() -> bool:
	return is_run_held()


func is_modifier_just_pressed() -> bool:
	return is_run_just_pressed()


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


func is_attack_just_pressed() -> bool:
	if InputMap.has_action("attack"):
		return Input.is_action_just_pressed("attack")
	return false


func is_attack_held() -> bool:
	if InputMap.has_action("attack"):
		return Input.is_action_pressed("attack")
	return false


func is_block_held() -> bool:
	if InputMap.has_action("block"):
		return Input.is_action_pressed("block")
	return false


func is_weapon_toggle_just_pressed() -> bool:
	if InputMap.has_action("weapon_toggle"):
		return Input.is_action_just_pressed("weapon_toggle")
	return false


func is_ranged_just_pressed() -> bool:
	if InputMap.has_action("ranged_attack"):
		return Input.is_action_just_pressed("ranged_attack")
	return false


func is_move_left_just_pressed() -> bool:
	if InputMap.has_action("move_left"):
		return Input.is_action_just_pressed("move_left")
	return false


func is_move_right_just_pressed() -> bool:
	if InputMap.has_action("move_right"):
		return Input.is_action_just_pressed("move_right")
	return false


func is_move_up_just_pressed() -> bool:
	if InputMap.has_action("move_up"):
		return Input.is_action_just_pressed("move_up")
	return false


func is_move_down_just_pressed() -> bool:
	if InputMap.has_action("move_down"):
		return Input.is_action_just_pressed("move_down")
	return false


func is_camera_toggle_just_pressed() -> bool:
	if InputMap.has_action("camera_toggle"):
		return Input.is_action_just_pressed("camera_toggle")
	return false


func is_side_scroller_toggle_just_pressed() -> bool:
	if InputMap.has_action("side_scroller_toggle"):
		return Input.is_action_just_pressed("side_scroller_toggle")
	return false


func is_action_held() -> bool:
	if InputMap.has_action("action"):
		return Input.is_action_pressed("action")
	return false
