@tool
extends Control
class_name DensetsuLoadingGauge

@export_group("Progress")
## Target value (0-1). The displayed value smooths toward this.
@export_range(0.0, 1.0, 0.0001) var target_progress: float = 0.0:
	set(value):
		target_progress = clampf(value, 0.0, 1.0)
		if not animate_progress:
			_displayed_progress = target_progress
		queue_redraw()

## If disabled, bar snaps instantly to target_progress.
@export var animate_progress: bool = true
## Smoothing speed used when animate_progress is enabled.
@export_range(0.01, 60.0, 0.01) var progress_smooth_speed: float = 8.0

@export_group("Layout")
## Inner padding for the fill area.
@export var fill_padding: Vector2 = Vector2(3.0, 3.0)
## Corner radius used when no textures are provided.
@export_range(0.0, 128.0, 0.1) var corner_radius: float = 8.0
## Border width used when no textures are provided.
@export_range(0.0, 16.0, 0.1) var border_width: float = 1.0

@export_group("Colors")
## Background color for fallback vector rendering.
@export var background_color: Color = Color(0.08, 0.08, 0.08, 0.9)
## Container/frame color for fallback vector rendering.
@export var container_color: Color = Color(0.16, 0.16, 0.16, 0.95)
## Fill color for fallback vector rendering.
@export var fill_color: Color = Color(0.48, 0.78, 1.0, 1.0)
## Border color for fallback vector rendering.
@export var border_color: Color = Color(0.02, 0.02, 0.02, 1.0)

@export_group("Textures")
## Optional texture for the container. If null, fallback vector rendering is used.
@export var container_texture: Texture2D
## Optional texture for the fill. If null, fallback vector rendering is used.
@export var fill_texture: Texture2D

@export_group("Text")
## Draws a centered percentage label.
@export var show_percent_text: bool = true
## Color for the percentage text.
@export var percent_text_color: Color = Color(1.0, 1.0, 1.0, 1.0)

var _displayed_progress: float = 0.0


func _ready() -> void:
	_displayed_progress = clampf(target_progress, 0.0, 1.0)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var desired: float = clampf(target_progress, 0.0, 1.0)
	if not animate_progress:
		if not is_equal_approx(_displayed_progress, desired):
			_displayed_progress = desired
			queue_redraw()
		return

	if is_equal_approx(_displayed_progress, desired):
		return

	var blend: float = clampf(1.0 - exp(-progress_smooth_speed * maxf(delta, 0.0)), 0.0, 1.0)
	_displayed_progress = lerpf(_displayed_progress, desired, blend)
	if absf(_displayed_progress - desired) <= 0.0005:
		_displayed_progress = desired
	queue_redraw()


func _draw() -> void:
	var bar_rect: Rect2 = Rect2(Vector2.ZERO, size)
	if bar_rect.size.x <= 0.0 or bar_rect.size.y <= 0.0:
		return

	_draw_background(bar_rect)
	_draw_container(bar_rect)
	_draw_fill(bar_rect)
	if show_percent_text:
		_draw_percent_label(bar_rect)


func _draw_background(bar_rect: Rect2) -> void:
	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = background_color
	bg_style.corner_radius_top_left = int(corner_radius)
	bg_style.corner_radius_top_right = int(corner_radius)
	bg_style.corner_radius_bottom_left = int(corner_radius)
	bg_style.corner_radius_bottom_right = int(corner_radius)
	draw_style_box(bg_style, bar_rect)


func _draw_container(bar_rect: Rect2) -> void:
	if container_texture != null:
		draw_texture_rect(container_texture, bar_rect, false, container_color)
		return

	var frame_style: StyleBoxFlat = StyleBoxFlat.new()
	frame_style.bg_color = container_color
	frame_style.border_color = border_color
	frame_style.border_width_top = int(border_width)
	frame_style.border_width_bottom = int(border_width)
	frame_style.border_width_left = int(border_width)
	frame_style.border_width_right = int(border_width)
	frame_style.corner_radius_top_left = int(corner_radius)
	frame_style.corner_radius_top_right = int(corner_radius)
	frame_style.corner_radius_bottom_left = int(corner_radius)
	frame_style.corner_radius_bottom_right = int(corner_radius)
	draw_style_box(frame_style, bar_rect)


func _draw_fill(bar_rect: Rect2) -> void:
	var inner_rect: Rect2 = Rect2(
		bar_rect.position + fill_padding,
		Vector2(
			maxf(bar_rect.size.x - fill_padding.x * 2.0, 0.0),
			maxf(bar_rect.size.y - fill_padding.y * 2.0, 0.0)
		)
	)
	if inner_rect.size.x <= 0.0 or inner_rect.size.y <= 0.0:
		return

	var fill_width: float = inner_rect.size.x * clampf(_displayed_progress, 0.0, 1.0)
	if fill_width <= 0.0:
		return

	var fill_rect: Rect2 = Rect2(inner_rect.position, Vector2(fill_width, inner_rect.size.y))
	if fill_texture != null:
		draw_texture_rect(fill_texture, fill_rect, false, fill_color)
		return

	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.corner_radius_top_left = int(maxf(corner_radius - fill_padding.y, 0.0))
	fill_style.corner_radius_bottom_left = int(maxf(corner_radius - fill_padding.y, 0.0))
	if _displayed_progress >= 0.999:
		fill_style.corner_radius_top_right = int(maxf(corner_radius - fill_padding.y, 0.0))
		fill_style.corner_radius_bottom_right = int(maxf(corner_radius - fill_padding.y, 0.0))
	draw_style_box(fill_style, fill_rect)


func _draw_percent_label(bar_rect: Rect2) -> void:
	var percent_value: float = clampf(_displayed_progress * 100.0, 0.0, 100.0)
	var text_value: String = "%d%%" % int(round(percent_value))
	var font: Font = get_theme_font("font")
	if font == null:
		return
	var font_size: int = get_theme_font_size("font_size")
	if font_size <= 0:
		font_size = 14
	var text_size: Vector2 = font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var text_pos: Vector2 = Vector2(
		bar_rect.position.x + (bar_rect.size.x - text_size.x) * 0.5,
		bar_rect.position.y + (bar_rect.size.y + text_size.y) * 0.5 - 2.0
	)
	draw_string(font, text_pos, text_value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, percent_text_color)


func set_progress(value: float) -> void:
	target_progress = value


func get_displayed_progress() -> float:
	return _displayed_progress


func _get_minimum_size() -> Vector2:
	return Vector2(160.0, 24.0)
