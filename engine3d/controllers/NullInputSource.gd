extends IInputSource
class_name NullInputSource


func is_dash_held() -> bool:
	return false

func is_crouch_just_pressed() -> bool:
	return false


func get_side_scroller_vector() -> Vector2:
	return Vector2.ZERO
