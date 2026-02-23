@tool
extends EditorScript

# Rebuilds the InputMap with a sane default set for 3D testing.
# This overwrites existing events for the listed actions.

const DEFAULT_DEADZONE := 0.5

func _run() -> void:
	print("RebuildInputMap: starting")
	_define_actions()
	_write_project_settings()
	InputMap.load_from_project_settings()
	var save_err := ProjectSettings.save()
	print("RebuildInputMap: save result=", save_err, " (OK=0)")
	print("RebuildInputMap: has input/move_left=", ProjectSettings.has_setting("input/move_left"))
	if ProjectSettings.has_setting("input/move_left"):
		print("RebuildInputMap: input/move_left=", ProjectSettings.get_setting("input/move_left"))
	print("RebuildInputMap: done.")

func _define_actions() -> void:
	_actions.clear()
	# Core locomotion
	_reset_action("move_left", DEFAULT_DEADZONE)
	_add_key("move_left", KEY_A)
	_add_key("move_left", KEY_LEFT)
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)

	_reset_action("move_right", DEFAULT_DEADZONE)
	_add_key("move_right", KEY_D)
	_add_key("move_right", KEY_RIGHT)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)

	_reset_action("move_up", DEFAULT_DEADZONE)
	_add_key("move_up", KEY_W)
	_add_key("move_up", KEY_UP)
	_add_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)

	_reset_action("move_down", DEFAULT_DEADZONE)
	_add_key("move_down", KEY_S)
	_add_key("move_down", KEY_DOWN)
	_add_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)

	# Side-scroller aliases (defaults mirror move_*)
	_reset_action("side_left", DEFAULT_DEADZONE)
	_add_key("side_left", KEY_A)
	_add_key("side_left", KEY_LEFT)
	_add_joy_axis("side_left", JOY_AXIS_LEFT_X, -1.0)

	_reset_action("side_right", DEFAULT_DEADZONE)
	_add_key("side_right", KEY_D)
	_add_key("side_right", KEY_RIGHT)
	_add_joy_axis("side_right", JOY_AXIS_LEFT_X, 1.0)

	_reset_action("side_up", DEFAULT_DEADZONE)
	_add_key("side_up", KEY_W)
	_add_key("side_up", KEY_UP)
	_add_joy_axis("side_up", JOY_AXIS_LEFT_Y, -1.0)

	_reset_action("side_down", DEFAULT_DEADZONE)
	_add_key("side_down", KEY_S)
	_add_key("side_down", KEY_DOWN)
	_add_joy_axis("side_down", JOY_AXIS_LEFT_Y, 1.0)

	# Depth (optional)
	_reset_action("move_depth_in", DEFAULT_DEADZONE)
	_add_key("move_depth_in", KEY_PAGEUP)
	_reset_action("move_depth_out", DEFAULT_DEADZONE)
	_add_key("move_depth_out", KEY_PAGEDOWN)

	# Jump / Run
	_reset_action("jump", DEFAULT_DEADZONE)
	_add_key("jump", KEY_SPACE)
	_add_joy_button("jump", JOY_BUTTON_A)

	_reset_action("run", DEFAULT_DEADZONE)
	_add_key("run", KEY_SHIFT)
	_add_joy_axis("run", JOY_AXIS_TRIGGER_RIGHT, 1.0)

	# Camera look
	_reset_action("look_left", DEFAULT_DEADZONE)
	_add_joy_axis("look_left", JOY_AXIS_RIGHT_X, -1.0)
	_reset_action("look_right", DEFAULT_DEADZONE)
	_add_joy_axis("look_right", JOY_AXIS_RIGHT_X, 1.0)
	_reset_action("look_up", DEFAULT_DEADZONE)
	_add_joy_axis("look_up", JOY_AXIS_RIGHT_Y, -1.0)
	_reset_action("look_down", DEFAULT_DEADZONE)
	_add_joy_axis("look_down", JOY_AXIS_RIGHT_Y, 1.0)

	_reset_action("camera_toggle", DEFAULT_DEADZONE)
	_add_key("camera_toggle", KEY_TAB)
	_add_joy_button("camera_toggle", JOY_BUTTON_RIGHT_STICK)

	_reset_action("camera_recenter", DEFAULT_DEADZONE)
	_add_key("camera_recenter", KEY_C)

	_reset_action("side_scroller_toggle", DEFAULT_DEADZONE)
	_add_key("side_scroller_toggle", KEY_F1)

	# Combat / interaction (defaults; adjust in editor as needed)
	_reset_action("action", DEFAULT_DEADZONE)
	_add_key("action", KEY_E)
	_add_joy_button("action", JOY_BUTTON_B)

	_reset_action("attack", DEFAULT_DEADZONE)
	_add_key("attack", KEY_F)
	_add_joy_button("attack", JOY_BUTTON_X)

	_reset_action("block", DEFAULT_DEADZONE)
	_add_key("block", KEY_G)
	_add_joy_button("block", JOY_BUTTON_LEFT_SHOULDER)

	_reset_action("weapon_toggle", DEFAULT_DEADZONE)
	_add_key("weapon_toggle", KEY_T)
	_add_joy_button("weapon_toggle", JOY_BUTTON_Y)

	_reset_action("ranged_attack", DEFAULT_DEADZONE)
	_add_key("ranged_attack", KEY_Y)
	_add_joy_button("ranged_attack", JOY_BUTTON_RIGHT_SHOULDER)

	_reset_action("aim", DEFAULT_DEADZONE)
	_add_mouse_button("aim", MOUSE_BUTTON_RIGHT)

	_reset_action("dash", DEFAULT_DEADZONE)
	_add_key("dash", KEY_Q)

	_reset_action("roll", DEFAULT_DEADZONE)
	_add_key("roll", KEY_R)

	_reset_action("crouch", DEFAULT_DEADZONE)
	_add_key("crouch", KEY_CTRL)

	_reset_action("sneak", DEFAULT_DEADZONE)
	_add_key("sneak", KEY_ALT)

var _actions: Dictionary = {}

func _reset_action(action: String, deadzone: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)
	InputMap.action_erase_events(action)
	InputMap.action_set_deadzone(action, deadzone)
	_actions[action] = {
		"deadzone": deadzone,
		"events": []
	}

func _add_key(action: String, keycode: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action, ev)
	_actions[action]["events"].append(ev)

func _add_mouse_button(action: String, button_index: int) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button_index
	InputMap.action_add_event(action, ev)
	_actions[action]["events"].append(ev)

func _add_joy_button(action: String, button: int) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
	_actions[action]["events"].append(ev)

func _add_joy_axis(action: String, axis: int, value: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)
	_actions[action]["events"].append(ev)

func _write_project_settings() -> void:
	# Overwrite input map section explicitly so project.godot gets [input] entries.
	for action in _actions.keys():
		ProjectSettings.set_setting("input/" + String(action), _actions[action])
	print("RebuildInputMap: wrote ", _actions.size(), " actions to ProjectSettings")
