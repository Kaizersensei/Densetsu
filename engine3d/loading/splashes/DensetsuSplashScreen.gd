@tool
extends CanvasLayer
class_name DensetsuSplashScreen

signal finished

@export_group("Node Paths")
## Fullscreen root control.
@export var root_control_path: NodePath = NodePath("Root")
## Fullscreen background color node.
@export var background_color_rect_path: NodePath = NodePath("Root/BackgroundColor")
## Fullscreen background texture node.
@export var background_texture_rect_path: NodePath = NodePath("Root/BackgroundTexture")
## Center logo node.
@export var logo_texture_rect_path: NodePath = NodePath("Root/Center/Logo")
## Primary text label.
@export var title_label_path: NodePath = NodePath("Root/Center/Title")
## Secondary text label.
@export var subtitle_label_path: NodePath = NodePath("Root/Center/Subtitle")
## Optional skip hint label.
@export var skip_hint_label_path: NodePath = NodePath("Root/SkipHint")

@export_group("Playback")
## Starts playback automatically on ready (runtime only).
@export var auto_play: bool = true
## Allow input skip.
@export var allow_skip: bool = true
## Actions that can trigger skip.
@export var skip_actions: PackedStringArray = PackedStringArray(["ui_accept", "ui_cancel", "action"])
## Also allow key/button/touch input to skip.
@export var skip_with_any_input: bool = true
## Minimum display time before skip is accepted.
@export_range(0.0, 10.0, 0.01) var minimum_display_before_skip_seconds: float = 0.2

@export_group("Timing")
## Fade in duration.
@export_range(0.0, 10.0, 0.01) var fade_in_seconds: float = 0.5
## Hold duration after fade-in.
@export_range(0.0, 30.0, 0.01) var hold_seconds: float = 1.4
## Fade out duration.
@export_range(0.0, 10.0, 0.01) var fade_out_seconds: float = 0.5
## Fade-out duration used when skipping.
@export_range(0.0, 5.0, 0.01) var skip_fade_out_seconds: float = 0.12

@export_group("Visual")
## Background fill color.
@export var background_color: Color = Color(0.0, 0.0, 0.0, 1.0)
## Optional fullscreen background texture.
@export var background_texture: Texture2D
## Tint for background texture.
@export var background_texture_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)
## Optional logo texture.
@export var logo_texture: Texture2D
## Tint for logo.
@export var logo_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)
## Custom minimum size for logo control.
@export var logo_custom_minimum_size: Vector2 = Vector2(320.0, 180.0)

@export_group("Text")
## Main title text.
@export_multiline var title_text: String = "Densetsu"
## Secondary subtitle text.
@export_multiline var subtitle_text: String = ""
## Hide title if title_text is empty.
@export var hide_title_when_empty: bool = true
## Hide subtitle if subtitle_text is empty.
@export var hide_subtitle_when_empty: bool = true
## Title color/tint.
@export var title_modulate: Color = Color(1.0, 1.0, 1.0, 1.0)
## Subtitle color/tint.
@export var subtitle_modulate: Color = Color(0.85, 0.85, 0.85, 1.0)

@export_group("Skip Hint")
## Show skip hint label.
@export var show_skip_hint: bool = true
## Show skip hint only when skip is currently allowed.
@export var show_skip_hint_only_when_skippable: bool = true
## Text for skip hint.
@export var skip_hint_text: String = "Press any key to skip"
## Color/tint for skip hint.
@export var skip_hint_modulate: Color = Color(0.75, 0.75, 0.75, 1.0)

var _root_control: Control = null
var _background_color_rect: ColorRect = null
var _background_texture_rect: TextureRect = null
var _logo_texture_rect: TextureRect = null
var _title_label: Label = null
var _subtitle_label: Label = null
var _skip_hint_label: Label = null

var _playing: bool = false
var _skip_requested: bool = false
var _skip_allowed: bool = false
var _skip_unlock_left: float = 0.0


func _ready() -> void:
	_resolve_nodes()
	_apply_visuals()
	set_process_unhandled_input(true)
	set_process(true)
	if auto_play and not Engine.is_editor_hint():
		play()


func play() -> void:
	if _playing:
		return
	_playing = true
	_skip_requested = false
	_skip_unlock_left = 0.0
	if allow_skip:
		_skip_unlock_left = maxf(minimum_display_before_skip_seconds, 0.0)
		_skip_allowed = is_zero_approx(_skip_unlock_left)
	else:
		_skip_allowed = false
	_apply_visuals()

	if _root_control != null:
		_root_control.visible = true
		var root_modulate: Color = _root_control.modulate
		root_modulate.a = 0.0
		_root_control.modulate = root_modulate

	if fade_in_seconds > 0.0 and _root_control != null:
		var fade_in_tween: Tween = create_tween()
		fade_in_tween.tween_property(_root_control, "modulate:a", 1.0, fade_in_seconds)
		await fade_in_tween.finished
	elif _root_control != null:
		var shown_modulate: Color = _root_control.modulate
		shown_modulate.a = 1.0
		_root_control.modulate = shown_modulate

	await _wait_or_skip(hold_seconds)

	var fade_out_time: float = fade_out_seconds
	if _skip_requested:
		fade_out_time = skip_fade_out_seconds

	if fade_out_time > 0.0 and _root_control != null:
		var fade_out_tween: Tween = create_tween()
		fade_out_tween.tween_property(_root_control, "modulate:a", 0.0, fade_out_time)
		await fade_out_tween.finished
	elif _root_control != null:
		var hidden_modulate: Color = _root_control.modulate
		hidden_modulate.a = 0.0
		_root_control.modulate = hidden_modulate

	_playing = false
	emit_signal("finished")


func _process(delta: float) -> void:
	if not _playing:
		return
	if not allow_skip:
		return
	if _skip_allowed:
		return
	_skip_unlock_left = maxf(_skip_unlock_left - maxf(delta, 0.0), 0.0)
	if is_zero_approx(_skip_unlock_left):
		_skip_allowed = true
		_update_skip_hint_visibility()


func _wait_or_skip(duration_seconds: float) -> void:
	if duration_seconds <= 0.0:
		return
	var elapsed: float = 0.0
	while elapsed < duration_seconds:
		if _skip_requested:
			return
		await get_tree().process_frame
		var delta: float = get_process_delta_time()
		elapsed += maxf(delta, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if not _playing:
		return
	if not allow_skip:
		return
	if not _skip_allowed:
		return
	if _is_skip_event(event):
		_skip_requested = true
		get_viewport().set_input_as_handled()


func _is_skip_event(event: InputEvent) -> bool:
	for action_value in skip_actions:
		var action_name: String = str(action_value)
		if action_name.is_empty():
			continue
		if InputMap.has_action(action_name) and event.is_action_pressed(action_name, true):
			return true

	if not skip_with_any_input:
		return false

	var key_event: InputEventKey = event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo:
		return true

	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event != null and mouse_event.pressed:
		return true

	var joy_event: InputEventJoypadButton = event as InputEventJoypadButton
	if joy_event != null and joy_event.pressed:
		return true

	var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
	if touch_event != null and touch_event.pressed:
		return true

	return false


func _resolve_nodes() -> void:
	_root_control = get_node_or_null(root_control_path) as Control
	_background_color_rect = get_node_or_null(background_color_rect_path) as ColorRect
	_background_texture_rect = get_node_or_null(background_texture_rect_path) as TextureRect
	_logo_texture_rect = get_node_or_null(logo_texture_rect_path) as TextureRect
	_title_label = get_node_or_null(title_label_path) as Label
	_subtitle_label = get_node_or_null(subtitle_label_path) as Label
	_skip_hint_label = get_node_or_null(skip_hint_label_path) as Label


func _apply_visuals() -> void:
	if _background_color_rect != null:
		_background_color_rect.color = background_color

	if _background_texture_rect != null:
		_background_texture_rect.texture = background_texture
		_background_texture_rect.modulate = background_texture_modulate
		_background_texture_rect.visible = background_texture != null

	if _logo_texture_rect != null:
		_logo_texture_rect.texture = logo_texture
		_logo_texture_rect.modulate = logo_modulate
		_logo_texture_rect.custom_minimum_size = logo_custom_minimum_size
		_logo_texture_rect.visible = logo_texture != null

	if _title_label != null:
		_title_label.text = title_text
		_title_label.modulate = title_modulate
		_title_label.visible = (not hide_title_when_empty) or (not title_text.strip_edges().is_empty())

	if _subtitle_label != null:
		_subtitle_label.text = subtitle_text
		_subtitle_label.modulate = subtitle_modulate
		_subtitle_label.visible = (not hide_subtitle_when_empty) or (not subtitle_text.strip_edges().is_empty())

	if _skip_hint_label != null:
		_skip_hint_label.text = skip_hint_text
		_skip_hint_label.modulate = skip_hint_modulate
		_update_skip_hint_visibility()


func _update_skip_hint_visibility() -> void:
	if _skip_hint_label == null:
		return
	var visible_now: bool = show_skip_hint
	if show_skip_hint_only_when_skippable:
		visible_now = visible_now and allow_skip and _skip_allowed
	_skip_hint_label.visible = visible_now
