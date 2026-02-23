@tool
extends Node3D

const SHADER_PATH: String = "res://shaders/postfx/sobel_outline_depth_spatial.gdshader"

@export_group("Sobel")
## Enables/disables the Sobel depth overlay pass.
@export var sobel_enabled: bool = true:
	set(value):
		sobel_enabled = value
		_refresh_state()
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
## Global intensity multiplier for extracted edges.
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
## Final opacity multiplier for outlines.
@export_range(0.0, 1.0, 0.01) var overlay_opacity: float = 1.0:
	set(value):
		overlay_opacity = value
		_apply_shader_params()
## Baseline overlay tint independent of edge detection.
@export_range(0.0, 1.0, 0.01) var global_mix: float = 0.0:
	set(value):
		global_mix = value
		_apply_shader_params()
## Shows raw Sobel edge mask as grayscale.
@export var preview_edges: bool = false:
	set(value):
		preview_edges = value
		_apply_shader_params()
## Forces full-screen outline color tint for debugging.
@export_range(0.0, 1.0, 0.01) var debug_force_mix: float = 0.0:
	set(value):
		debug_force_mix = value
		_apply_shader_params()

@export_group("Distance Controls")
## Enables distance-based thickness scaling and outline fade.
@export var use_distance_controls: bool = true:
	set(value):
		use_distance_controls = value
		_apply_shader_params()
## Inverts sampled depth if near/far behavior appears flipped.
@export var invert_depth: bool = false:
	set(value):
		invert_depth = value
		_apply_shader_params()
## Start distance (meters) for thinning/fading.
@export_range(0.0, 10000.0, 0.1) var distance_start: float = 10.0:
	set(value):
		distance_start = value
		_apply_shader_params()
## End distance (meters) where outlines are thinnest and faded out.
@export_range(0.1, 10000.0, 0.1) var distance_end: float = 100.0:
	set(value):
		distance_end = value
		_apply_shader_params()
## Thickness multiplier near the camera.
@export_range(0.1, 8.0, 0.01) var near_thickness_multiplier: float = 2.0:
	set(value):
		near_thickness_multiplier = value
		_apply_shader_params()
## Thickness multiplier at far distance.
@export_range(0.05, 4.0, 0.01) var far_thickness_multiplier: float = 0.5:
	set(value):
		far_thickness_multiplier = value
		_apply_shader_params()
## Uses active viewport camera near/far clip values.
@export var auto_camera_clip: bool = true:
	set(value):
		auto_camera_clip = value
		_apply_shader_params()
## Camera near clip when auto_camera_clip is disabled.
@export_range(0.001, 10.0, 0.001) var camera_near: float = 0.05:
	set(value):
		camera_near = value
		_apply_shader_params()
## Camera far clip when auto_camera_clip is disabled.
@export_range(1.0, 10000.0, 1.0) var camera_far: float = 500.0:
	set(value):
		camera_far = value
		_apply_shader_params()

@export_group("Overlay Placement")
## Offset added to camera near clip for overlay quad placement.
@export_range(0.01, 5.0, 0.01) var camera_plane_offset: float = 0.05:
	set(value):
		camera_plane_offset = value
		_fit_overlay_to_camera(_get_active_camera())
## Updates camera-follow in deferred late frame to avoid one-frame lag.
@export var late_update_follow: bool = true

var _overlay_quad: MeshInstance3D
var _overlay_mesh: QuadMesh
var _overlay_material: ShaderMaterial
var _warned_missing_shader: bool = false
var _late_update_queued: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 10000
	visible = true
	_ensure_overlay()
	_refresh_state()


func _process(_delta: float) -> void:
	if not sobel_enabled or not visible:
		return
	if late_update_follow:
		if _late_update_queued:
			return
		_late_update_queued = true
		call_deferred("_late_update_overlay")
		return
	_update_overlay_immediate()


func _late_update_overlay() -> void:
	_late_update_queued = false
	_update_overlay_immediate()


func _update_overlay_immediate() -> void:
	_ensure_overlay()
	_refresh_state()
	if not sobel_enabled:
		return

	var camera: Camera3D = _get_active_camera()
	if camera == null:
		if _overlay_quad != null:
			_overlay_quad.visible = false
		return

	_fit_overlay_to_camera(camera)
	_apply_shader_params()


func _refresh_state() -> void:
	if _overlay_quad == null:
		return
	_overlay_quad.visible = sobel_enabled
	if not sobel_enabled:
		return
	_ensure_material()
	_apply_shader_params()


func _get_active_camera() -> Camera3D:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return null
	return viewport.get_camera_3d()


func _ensure_overlay() -> void:
	_overlay_quad = get_node_or_null("OverlayQuad") as MeshInstance3D
	if _overlay_quad == null:
		_overlay_quad = MeshInstance3D.new()
		_overlay_quad.name = "OverlayQuad"
		add_child(_overlay_quad)
		if Engine.is_editor_hint():
			_overlay_quad.owner = get_tree().edited_scene_root

	# Keep world-space transform independent from parent scaling/shear.
	_overlay_quad.top_level = true

	_overlay_mesh = _overlay_quad.mesh as QuadMesh
	if _overlay_mesh == null:
		_overlay_mesh = QuadMesh.new()
		_overlay_mesh.size = Vector2(2.0, 2.0)
		_overlay_quad.mesh = _overlay_mesh

	_overlay_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_overlay_quad.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	_overlay_quad.extra_cull_margin = 1000000.0


func _ensure_material() -> void:
	if _overlay_quad == null:
		return
	var shader: Shader = load(SHADER_PATH) as Shader
	if shader == null:
		_overlay_quad.visible = false
		if not _warned_missing_shader:
			push_warning("SobelOutlineDepthPostFX3D: missing shader: " + SHADER_PATH)
			_warned_missing_shader = true
		return

	_overlay_material = _overlay_quad.material_override as ShaderMaterial
	if _overlay_material == null:
		_overlay_material = ShaderMaterial.new()
		_overlay_quad.material_override = _overlay_material
	_overlay_material.resource_local_to_scene = true
	_overlay_material.shader = shader
	_overlay_material.render_priority = 127


func _fit_overlay_to_camera(camera: Camera3D) -> void:
	if camera == null:
		return
	if _overlay_mesh == null or _overlay_quad == null:
		return

	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var viewport_size: Vector2 = viewport.get_visible_rect().size
	var distance: float = max(camera.near + camera_plane_offset, 0.01)

	var center_uv: Vector2 = viewport_size * 0.5
	var left_world: Vector3 = camera.project_position(Vector2(0.0, center_uv.y), distance)
	var right_world: Vector3 = camera.project_position(Vector2(viewport_size.x, center_uv.y), distance)
	var top_world: Vector3 = camera.project_position(Vector2(center_uv.x, 0.0), distance)
	var bottom_world: Vector3 = camera.project_position(Vector2(center_uv.x, viewport_size.y), distance)
	var center_world: Vector3 = camera.project_position(center_uv, distance)

	var quad_width: float = left_world.distance_to(right_world)
	var quad_height: float = top_world.distance_to(bottom_world)

	_overlay_mesh.size = Vector2(quad_width, quad_height)

	var cam_xf: Transform3D = _get_effective_camera_transform(camera)
	_overlay_quad.global_transform = Transform3D(cam_xf.basis.orthonormalized(), center_world)


func _get_effective_camera_transform(camera: Camera3D) -> Transform3D:
	if camera.has_method("get_camera_transform"):
		var xf_variant: Variant = camera.call("get_camera_transform")
		if xf_variant is Transform3D:
			return xf_variant
	return camera.global_transform


func _apply_shader_params() -> void:
	if _overlay_material == null:
		return
	var near_clip: float = camera_near
	var far_clip: float = camera_far
	if auto_camera_clip:
		var cam: Camera3D = _get_active_camera()
		if cam != null:
			near_clip = cam.near
			far_clip = cam.far

	var viewport: Viewport = get_viewport()
	var viewport_size: Vector2 = Vector2(1920.0, 1080.0)
	if viewport != null:
		viewport_size = viewport.get_visible_rect().size
	var texel_size: Vector2 = Vector2(1.0 / max(viewport_size.x, 1.0), 1.0 / max(viewport_size.y, 1.0))

	var dist_end: float = distance_end
	if dist_end <= distance_start:
		dist_end = distance_start + 0.1

	_overlay_material.set_shader_parameter("outline_color", outline_color)
	_overlay_material.set_shader_parameter("edge_threshold", edge_threshold)
	_overlay_material.set_shader_parameter("edge_softness", edge_softness)
	_overlay_material.set_shader_parameter("edge_strength", edge_strength)
	_overlay_material.set_shader_parameter("thickness", thickness)
	_overlay_material.set_shader_parameter("overlay_opacity", overlay_opacity)
	_overlay_material.set_shader_parameter("global_mix", global_mix)
	_overlay_material.set_shader_parameter("preview_edges", preview_edges)
	_overlay_material.set_shader_parameter("debug_force_mix", debug_force_mix)
	_overlay_material.set_shader_parameter("use_distance_controls", use_distance_controls)
	_overlay_material.set_shader_parameter("invert_depth", invert_depth)
	_overlay_material.set_shader_parameter("camera_near", near_clip)
	_overlay_material.set_shader_parameter("camera_far", far_clip)
	_overlay_material.set_shader_parameter("near_thickness_multiplier", near_thickness_multiplier)
	_overlay_material.set_shader_parameter("far_thickness_multiplier", far_thickness_multiplier)
	_overlay_material.set_shader_parameter("distance_start", distance_start)
	_overlay_material.set_shader_parameter("distance_end", dist_end)
	_overlay_material.set_shader_parameter("screen_texel_size", texel_size)
