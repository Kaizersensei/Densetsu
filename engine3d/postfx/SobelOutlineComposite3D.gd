@tool
extends CanvasLayer

const SOBEL_SHADER_PATH := "res://shaders/postfx/sobel_outline_from_viewport.gdshader"

@export_group("Sobel")
## Enables/disables the Sobel overlay pass.
@export var sobel_enabled: bool = true:
	set(value):
		sobel_enabled = value
		_refresh_overlay()
## Pixel step multiplier used by the Sobel kernel.
@export_range(0.25, 4.0, 0.05) var thickness: float = 1.0:
	set(value):
		thickness = value
		_apply_shader_params()
## Edge threshold for Sobel detection.
@export_range(0.0, 2.0, 0.01) var edge_threshold: float = 0.15:
	set(value):
		edge_threshold = value
		_apply_shader_params()
## Soft transition range after threshold.
@export_range(0.001, 1.0, 0.001) var edge_softness: float = 0.08:
	set(value):
		edge_softness = value
		_apply_shader_params()
## Global intensity multiplier for the extracted edge.
@export_range(0.0, 8.0, 0.05) var edge_strength: float = 2.0:
	set(value):
		edge_strength = value
		_apply_shader_params()

@export_group("Outline Color")
## Sobel edge tint color.
@export var outline_color: Color = Color(0.0, 0.0, 0.0, 1.0):
	set(value):
		outline_color = value
		_apply_shader_params()
## Final opacity of the Sobel overlay.
@export_range(0.0, 1.0, 0.01) var overlay_opacity: float = 1.0:
	set(value):
		overlay_opacity = value
		_apply_shader_params()
## Debug-only global tint mix to verify the post-process is active.
@export_range(0.0, 1.0, 0.01) var global_mix: float = 0.0:
	set(value):
		global_mix = value
		_apply_shader_params()
## Shows raw Sobel edge mask as grayscale.
@export var preview_edges: bool = false:
	set(value):
		preview_edges = value
		_apply_shader_params()
## Forces a full-screen tint to validate the post-process pass is active.
@export_range(0.0, 1.0, 0.01) var debug_force_mix: float = 0.0:
	set(value):
		debug_force_mix = value
		_apply_shader_params()
## Bypasses shader and paints a solid full-screen color to validate canvas layering.
@export var debug_solid_overlay: bool = false:
	set(value):
		debug_solid_overlay = value
		_refresh_overlay()

var _overlay: ColorRect
var _screen_copy: BackBufferCopy
var _warned_missing_shader: bool = false
var _warned_invalid_shader: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	_refresh_overlay()


func _process(_delta: float) -> void:
	if not sobel_enabled:
		if _overlay != null:
			_overlay.visible = false
		return
	if _overlay == null or (_overlay.material as ShaderMaterial) == null:
		_refresh_overlay()
	else:
		_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_apply_shader_params()

func _refresh_overlay() -> void:
	_ensure_screen_copy()
	_ensure_overlay()
	if _overlay == null:
		return
	if not sobel_enabled:
		_overlay.visible = false
		return
	if debug_solid_overlay:
		_overlay.material = null
		var solid_alpha: float = overlay_opacity
		if solid_alpha < 0.25:
			solid_alpha = 0.25
		_overlay.color = Color(outline_color.r, outline_color.g, outline_color.b, solid_alpha)
		_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_overlay.visible = true
		return

	var shader := load(SOBEL_SHADER_PATH) as Shader
	if shader == null:
		_overlay.visible = false
		if not _warned_missing_shader:
			push_warning("SobelOutlineComposite3D: missing shader: " + SOBEL_SHADER_PATH)
			_warned_missing_shader = true
		return
	if not _is_sobel_shader_usable(shader):
		_overlay.material = null
		_overlay.visible = false
		if not _warned_invalid_shader:
			push_warning("SobelOutlineComposite3D: shader failed validation/compile: " + SOBEL_SHADER_PATH)
			_warned_invalid_shader = true
		return

	var mat := _overlay.material as ShaderMaterial
	if mat == null:
		mat = ShaderMaterial.new()
		_overlay.material = mat
	mat.resource_local_to_scene = true
	mat.shader = shader
	_overlay.visible = true
	_overlay.color = Color.WHITE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_shader_params()


func _ensure_overlay() -> void:
	_overlay = get_node_or_null("Overlay") as ColorRect
	if _overlay != null:
		if _screen_copy != null and _screen_copy.get_parent() == self:
			move_child(_screen_copy, 0)
		return
	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.anchor_left = 0.0
	_overlay.anchor_top = 0.0
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.offset_left = 0.0
	_overlay.offset_top = 0.0
	_overlay.offset_right = 0.0
	_overlay.offset_bottom = 0.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color.WHITE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	if _screen_copy != null and _screen_copy.get_parent() == self:
		move_child(_screen_copy, 0)
	if Engine.is_editor_hint():
		_overlay.owner = get_tree().edited_scene_root


func _ensure_screen_copy() -> void:
	_screen_copy = get_node_or_null("ScreenCopy") as BackBufferCopy
	if _screen_copy == null:
		_screen_copy = BackBufferCopy.new()
		_screen_copy.name = "ScreenCopy"
		add_child(_screen_copy)
		if Engine.is_editor_hint():
			_screen_copy.owner = get_tree().edited_scene_root
	_screen_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	if _screen_copy.get_parent() == self:
		move_child(_screen_copy, 0)


func _apply_shader_params() -> void:
	if _overlay == null:
		return
	if debug_solid_overlay:
		_overlay.material = null
		var solid_alpha: float = overlay_opacity
		if solid_alpha < 0.25:
			solid_alpha = 0.25
		_overlay.color = Color(outline_color.r, outline_color.g, outline_color.b, solid_alpha)
		_overlay.visible = true
		return
	var mat := _overlay.material as ShaderMaterial
	if mat == null:
		_refresh_overlay()
		mat = _overlay.material as ShaderMaterial
		if mat == null:
			return
	_overlay.color = Color.WHITE
	mat.set_shader_parameter("outline_color", outline_color)
	mat.set_shader_parameter("edge_threshold", edge_threshold)
	mat.set_shader_parameter("edge_softness", edge_softness)
	mat.set_shader_parameter("edge_strength", edge_strength)
	mat.set_shader_parameter("thickness", thickness)
	mat.set_shader_parameter("overlay_opacity", overlay_opacity)
	mat.set_shader_parameter("global_mix", global_mix)
	mat.set_shader_parameter("preview_edges", preview_edges)
	mat.set_shader_parameter("debug_force_mix", debug_force_mix)


func _is_sobel_shader_usable(shader: Shader) -> bool:
	if shader == null:
		return false
	var uniform_list: Array = shader.get_shader_uniform_list()
	var has_outline_color: bool = false
	var has_edge_threshold: bool = false
	for entry_any in uniform_list:
		if not (entry_any is Dictionary):
			continue
		var entry: Dictionary = entry_any as Dictionary
		var uniform_name: String = str(entry.get("name", ""))
		if uniform_name == "outline_color":
			has_outline_color = true
		elif uniform_name == "edge_threshold":
			has_edge_threshold = true
		if has_outline_color and has_edge_threshold:
			return true
	return false
