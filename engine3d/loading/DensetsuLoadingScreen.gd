@tool
extends Node
class_name DensetsuLoadingScreen

signal loading_started(scene_path: String)
signal loading_progress(scene_path: String, progress: float)
signal loading_completed(scene_path: String, packed_scene: PackedScene)
signal loading_failed(scene_path: String, reason: String)

@export_group("Content Host")
## Path to the node that hosts arbitrary loading-screen content scenes.
@export var content_root_path: NodePath = NodePath("ContentRoot"):
	set(value):
		content_root_path = value
		_refresh_bindings()
## Optional scene instanced under ContentRoot (music/video/interactive showcase/minigame/etc).
@export var content_scene: PackedScene
## Instances content_scene automatically on ready.
@export var auto_instance_content_scene: bool = true
## Clears old content children before adding a new one.
@export var clear_content_before_instancing: bool = true

@export_group("Overlay Node Paths")
## Path to overlay canvas layer.
@export var overlay_canvas_path: NodePath = NodePath("Overlay"):
	set(value):
		overlay_canvas_path = value
		_refresh_bindings()
## Path to the panel that contains labels and gauge.
@export var loading_panel_path: NodePath = NodePath("Overlay/Root/LoadingPanel"):
	set(value):
		loading_panel_path = value
		_refresh_bindings()
## Path to the smooth loading gauge control.
@export var gauge_path: NodePath = NodePath("Overlay/Root/LoadingPanel/Margin/VBox/Gauge"):
	set(value):
		gauge_path = value
		_refresh_bindings()
## Path to status label.
@export var status_label_path: NodePath = NodePath("Overlay/Root/LoadingPanel/Margin/VBox/Status"):
	set(value):
		status_label_path = value
		_refresh_bindings()
## Path to details label.
@export var detail_label_path: NodePath = NodePath("Overlay/Root/LoadingPanel/Margin/VBox/Detail"):
	set(value):
		detail_label_path = value
		_refresh_bindings()

@export_group("Overlay Visibility")
## Shows/hides overlay canvas.
@export var overlay_visible: bool = true:
	set(value):
		overlay_visible = value
		_apply_overlay_settings()
## Shows/hides loading panel.
@export var loading_panel_visible: bool = true:
	set(value):
		loading_panel_visible = value
		_apply_overlay_settings()
## Tints the loading panel (alpha controls opacity).
@export var loading_panel_modulate: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		loading_panel_modulate = value
		_apply_overlay_settings()

@export_group("Panel Layout")
## Width/height of the loading panel when using the default centered-bottom anchor layout.
@export var loading_panel_size: Vector2 = Vector2(640.0, 96.0):
	set(value):
		loading_panel_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		_apply_panel_layout()
## Distance from bottom edge of the viewport to the panel.
@export_range(0.0, 4096.0, 1.0) var loading_panel_bottom_margin: float = 20.0:
	set(value):
		loading_panel_bottom_margin = maxf(value, 0.0)
		_apply_panel_layout()
## Optional minimum size for the panel.
@export var loading_panel_custom_minimum_size: Vector2 = Vector2.ZERO:
	set(value):
		loading_panel_custom_minimum_size = Vector2(maxf(value.x, 0.0), maxf(value.y, 0.0))
		_apply_panel_layout()

@export_group("Panel Style")
## Optional panel StyleBox override. Leave null to use scene/theme default.
@export var loading_panel_style_override: StyleBox:
	set(value):
		loading_panel_style_override = value
		_apply_panel_style()

@export_group("Status Text")
## Text shown when threaded loading starts.
@export var status_text_loading: String = "Loading..."
## Text shown when loading completes.
@export var status_text_complete: String = "Load complete"
## Prefix used when loading fails.
@export var status_text_failed_prefix: String = "Loading failed"

@export_group("Label Styling")
## Shows/hides the status label.
@export var status_label_visible: bool = true:
	set(value):
		status_label_visible = value
		_apply_label_settings()
## Tint for the status label.
@export var status_label_modulate: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		status_label_modulate = value
		_apply_label_settings()
## Shows/hides the detail label.
@export var detail_label_visible: bool = true:
	set(value):
		detail_label_visible = value
		_apply_label_settings()
## Tint for the detail label.
@export var detail_label_modulate: Color = Color(0.75, 0.75, 0.75, 1.0):
	set(value):
		detail_label_modulate = value
		_apply_label_settings()

@export_group("Gauge Settings")
## Preview/idle progress when not actively loading a scene.
@export_range(0.0, 1.0, 0.0001) var gauge_preview_progress: float = 0.0:
	set(value):
		gauge_preview_progress = clampf(value, 0.0, 1.0)
		if not _request_active and not _load_finished:
			_set_progress(gauge_preview_progress)
## Optional minimum size for the gauge control.
@export var gauge_custom_minimum_size: Vector2 = Vector2(0.0, 28.0):
	set(value):
		gauge_custom_minimum_size = Vector2(maxf(value.x, 0.0), maxf(value.y, 0.0))
		_apply_gauge_settings()
## Enables smooth progress interpolation.
@export var gauge_animate_progress: bool = true:
	set(value):
		gauge_animate_progress = value
		_apply_gauge_settings()
## Smoothing speed for displayed progress.
@export_range(0.01, 60.0, 0.01) var gauge_progress_smooth_speed: float = 8.0:
	set(value):
		gauge_progress_smooth_speed = maxf(value, 0.01)
		_apply_gauge_settings()
## Inner fill padding.
@export var gauge_fill_padding: Vector2 = Vector2(3.0, 3.0):
	set(value):
		gauge_fill_padding = value
		_apply_gauge_settings()
## Corner radius for fallback rendering.
@export_range(0.0, 128.0, 0.1) var gauge_corner_radius: float = 8.0:
	set(value):
		gauge_corner_radius = maxf(value, 0.0)
		_apply_gauge_settings()
## Border width for fallback rendering.
@export_range(0.0, 16.0, 0.1) var gauge_border_width: float = 1.0:
	set(value):
		gauge_border_width = maxf(value, 0.0)
		_apply_gauge_settings()
## Background color for fallback rendering.
@export var gauge_background_color: Color = Color(0.08, 0.08, 0.08, 0.9):
	set(value):
		gauge_background_color = value
		_apply_gauge_settings()
## Container color for fallback rendering.
@export var gauge_container_color: Color = Color(0.16, 0.16, 0.16, 0.95):
	set(value):
		gauge_container_color = value
		_apply_gauge_settings()
## Fill color for fallback rendering.
@export var gauge_fill_color: Color = Color(0.48, 0.78, 1.0, 1.0):
	set(value):
		gauge_fill_color = value
		_apply_gauge_settings()
## Border color for fallback rendering.
@export var gauge_border_color: Color = Color(0.02, 0.02, 0.02, 1.0):
	set(value):
		gauge_border_color = value
		_apply_gauge_settings()
## Optional texture for container.
@export var gauge_container_texture: Texture2D:
	set(value):
		gauge_container_texture = value
		_apply_gauge_settings()
## Optional texture for fill.
@export var gauge_fill_texture: Texture2D:
	set(value):
		gauge_fill_texture = value
		_apply_gauge_settings()
## Shows percentage text over gauge.
@export var gauge_show_percent_text: bool = true:
	set(value):
		gauge_show_percent_text = value
		_apply_gauge_settings()
## Color for percentage text.
@export var gauge_percent_text_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		gauge_percent_text_color = value
		_apply_gauge_settings()

@export_group("Threaded Scene Load")
## Starts loading target_scene_path automatically.
@export var auto_start_scene_load: bool = false
## Scene to load asynchronously while this loading screen is active.
@export_file("*.tscn", "*.scn") var target_scene_path: String = ""
## Uses extra worker threads for faster background loading on large scenes.
@export var threaded_use_sub_threads: bool = true
## Changes to loaded scene automatically when complete.
@export var auto_switch_to_loaded_scene: bool = true
## Keeps loading screen visible for at least this amount of time.
@export_range(0.0, 30.0, 0.01) var minimum_visible_seconds: float = 0.0
## Updates status label while threaded loading runs.
@export var show_default_status_text: bool = true

var _content_root: Node = null
var _overlay_canvas: CanvasLayer = null
var _loading_panel: Control = null
var _gauge: DensetsuLoadingGauge = null
var _status_label: Label = null
var _detail_label: Label = null

var _active_request_path: String = ""
var _request_active: bool = false
var _min_visible_left: float = 0.0
var _loaded_scene: PackedScene = null
var _load_finished: bool = false


func _ready() -> void:
	_resolve_nodes()
	_apply_overlay_settings()
	_apply_panel_layout()
	_apply_panel_style()
	_apply_label_settings()
	_apply_gauge_settings()
	_set_progress(gauge_preview_progress)
	_min_visible_left = maxf(minimum_visible_seconds, 0.0)

	if auto_instance_content_scene and content_scene != null:
		set_content_scene(content_scene)

	if auto_start_scene_load and not target_scene_path.strip_edges().is_empty():
		begin_load_scene(target_scene_path)

	set_process(true)


func _process(delta: float) -> void:
	if _min_visible_left > 0.0:
		_min_visible_left = maxf(0.0, _min_visible_left - maxf(delta, 0.0))

	if _request_active:
		_poll_threaded_load()
		return

	if _load_finished and _loaded_scene != null and auto_switch_to_loaded_scene and _min_visible_left <= 0.0:
		var scene_to_switch: PackedScene = _loaded_scene
		_loaded_scene = null
		_load_finished = false
		var change_error: int = get_tree().change_scene_to_packed(scene_to_switch)
		if change_error != OK:
			_set_status("Load complete, but scene switch failed.")
			_set_detail("Error code: %d" % change_error)


func _resolve_nodes() -> void:
	_content_root = get_node_or_null(content_root_path)
	_overlay_canvas = get_node_or_null(overlay_canvas_path) as CanvasLayer
	_loading_panel = get_node_or_null(loading_panel_path) as Control
	_gauge = get_node_or_null(gauge_path) as DensetsuLoadingGauge
	_status_label = get_node_or_null(status_label_path) as Label
	_detail_label = get_node_or_null(detail_label_path) as Label


func _apply_overlay_settings() -> void:
	if _overlay_canvas != null:
		_overlay_canvas.visible = overlay_visible
	if _loading_panel != null:
		_loading_panel.visible = loading_panel_visible
		_loading_panel.modulate = loading_panel_modulate


func _apply_panel_layout() -> void:
	if _loading_panel == null:
		return
	var panel_width: float = maxf(loading_panel_size.x, 1.0)
	var panel_height: float = maxf(loading_panel_size.y, 1.0)
	var half_width: float = panel_width * 0.5
	_loading_panel.offset_left = -half_width
	_loading_panel.offset_right = half_width
	_loading_panel.offset_bottom = -loading_panel_bottom_margin
	_loading_panel.offset_top = _loading_panel.offset_bottom - panel_height
	_loading_panel.custom_minimum_size = loading_panel_custom_minimum_size


func _apply_panel_style() -> void:
	if _loading_panel == null:
		return
	if loading_panel_style_override == null:
		_loading_panel.remove_theme_stylebox_override("panel")
		return
	_loading_panel.add_theme_stylebox_override("panel", loading_panel_style_override)


func _apply_label_settings() -> void:
	if _status_label != null:
		_status_label.visible = status_label_visible
		_status_label.modulate = status_label_modulate
	if _detail_label != null:
		_detail_label.visible = detail_label_visible
		_detail_label.modulate = detail_label_modulate


func _apply_gauge_settings() -> void:
	if _gauge == null:
		return
	_gauge.custom_minimum_size = gauge_custom_minimum_size
	_gauge.animate_progress = gauge_animate_progress
	_gauge.progress_smooth_speed = gauge_progress_smooth_speed
	_gauge.fill_padding = gauge_fill_padding
	_gauge.corner_radius = gauge_corner_radius
	_gauge.border_width = gauge_border_width
	_gauge.background_color = gauge_background_color
	_gauge.container_color = gauge_container_color
	_gauge.fill_color = gauge_fill_color
	_gauge.border_color = gauge_border_color
	_gauge.container_texture = gauge_container_texture
	_gauge.fill_texture = gauge_fill_texture
	_gauge.show_percent_text = gauge_show_percent_text
	_gauge.percent_text_color = gauge_percent_text_color
	if not _request_active and not _load_finished:
		_gauge.set_progress(gauge_preview_progress)
	_gauge.queue_redraw()


func _refresh_bindings() -> void:
	_resolve_nodes()
	_apply_overlay_settings()
	_apply_panel_layout()
	_apply_panel_style()
	_apply_label_settings()
	_apply_gauge_settings()


func begin_load_scene(scene_path: String) -> void:
	var normalized_path: String = scene_path.strip_edges()
	if normalized_path.is_empty():
		emit_signal("loading_failed", scene_path, "Empty scene path.")
		_set_status(status_text_failed_prefix)
		_set_detail("Scene path is empty.")
		return

	_active_request_path = normalized_path
	_loaded_scene = null
	_load_finished = false

	var request_error: int = ResourceLoader.load_threaded_request(_active_request_path, "PackedScene", threaded_use_sub_threads)
	if request_error != OK:
		_request_active = false
		emit_signal("loading_failed", _active_request_path, "Threaded request failed.")
		_set_status(status_text_failed_prefix)
		_set_detail("Request error code: %d" % request_error)
		return

	_request_active = true
	_set_progress(0.0)
	if show_default_status_text:
		_set_status(status_text_loading)
		_set_detail(_active_request_path)
	emit_signal("loading_started", _active_request_path)


func _poll_threaded_load() -> void:
	if _active_request_path.is_empty():
		_request_active = false
		return

	var progress: Array = []
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(_active_request_path, progress)

	var progress_value: float = 0.0
	if not progress.is_empty():
		var raw_value: Variant = progress[0]
		if typeof(raw_value) == TYPE_FLOAT or typeof(raw_value) == TYPE_INT:
			progress_value = clampf(float(raw_value), 0.0, 1.0)
	_set_progress(progress_value)
	emit_signal("loading_progress", _active_request_path, progress_value)

	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return

	_request_active = false

	if status != ResourceLoader.THREAD_LOAD_LOADED:
		emit_signal("loading_failed", _active_request_path, "Threaded load failed.")
		_set_status(status_text_failed_prefix)
		_set_detail("Status code: %d" % int(status))
		return

	var loaded_resource: Resource = ResourceLoader.load_threaded_get(_active_request_path)
	var loaded_scene: PackedScene = loaded_resource as PackedScene
	if loaded_scene == null:
		emit_signal("loading_failed", _active_request_path, "Loaded resource is not PackedScene.")
		_set_status(status_text_failed_prefix)
		_set_detail("Resource was not a PackedScene.")
		return

	_loaded_scene = loaded_scene
	_load_finished = true
	_set_progress(1.0)
	if show_default_status_text:
		_set_status(status_text_complete)
		_set_detail(_active_request_path)
	emit_signal("loading_completed", _active_request_path, _loaded_scene)


func set_progress(progress_value: float) -> void:
	_set_progress(progress_value)


func _set_progress(progress_value: float) -> void:
	var clamped: float = clampf(progress_value, 0.0, 1.0)
	if _gauge != null:
		_gauge.set_progress(clamped)
	if _detail_label != null and not _request_active and not _load_finished:
		_detail_label.text = "%d%%" % int(round(clamped * 100.0))


func set_content_scene(scene_to_instance: PackedScene) -> Node:
	if _content_root == null:
		_resolve_nodes()
	if _content_root == null:
		return null

	if clear_content_before_instancing:
		var children: Array[Node] = []
		for child_any in _content_root.get_children():
			var child_node: Node = child_any as Node
			if child_node != null:
				children.append(child_node)
		for child_node in children:
			_content_root.remove_child(child_node)
			child_node.queue_free()

	if scene_to_instance == null:
		return null

	var instance: Node = scene_to_instance.instantiate()
	_content_root.add_child(instance)
	return instance


func add_content_node(content_node: Node) -> void:
	if content_node == null:
		return
	if _content_root == null:
		_resolve_nodes()
	if _content_root == null:
		return
	_content_root.add_child(content_node)


func _set_status(text_value: String) -> void:
	if _status_label != null:
		_status_label.text = text_value


func _set_detail(text_value: String) -> void:
	if _detail_label != null:
		_detail_label.text = text_value
