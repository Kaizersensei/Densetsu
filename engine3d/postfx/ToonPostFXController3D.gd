extends Node3D

const SOBEL_PASS_SCENE_PATH: String = "res://engine3d/postfx/SobelOutlineDepthPostFX3D.tscn"
const DEFAULT_TOON_SHADER_PATH: String = "res://shaders/stylized.gdshader"

@export_group("PostFX Chain")
## Child node path for the depth Sobel pass.
@export var sobel_pass_path: NodePath = NodePath("SobelDepthPass"):
	set(value):
		sobel_pass_path = value
		_resolve_sobel_pass()
## Auto-instantiates the Sobel depth pass child when missing.
@export var auto_create_sobel_pass: bool = true:
	set(value):
		auto_create_sobel_pass = value
		_resolve_sobel_pass()

@export_group("Sobel")
## Enables/disables the Sobel depth overlay pass.
@export var sobel_enabled: bool = true:
	set(value):
		sobel_enabled = value
		_apply_sobel_params()
## Pixel step multiplier used by the Sobel kernel.
@export_range(0.25, 4.0, 0.05) var thickness: float = 1.0:
	set(value):
		thickness = value
		_apply_sobel_params()
## Edge threshold for Sobel detection.
@export_range(0.0, 2.0, 0.01) var edge_threshold: float = 0.15:
	set(value):
		edge_threshold = value
		_apply_sobel_params()
## Soft transition range after threshold.
@export_range(0.001, 1.0, 0.001) var edge_softness: float = 0.08:
	set(value):
		edge_softness = value
		_apply_sobel_params()
## Global intensity multiplier for extracted edges.
@export_range(0.0, 8.0, 0.05) var edge_strength: float = 2.0:
	set(value):
		edge_strength = value
		_apply_sobel_params()

@export_group("Sobel Outline")
## Sobel edge tint color.
@export var outline_color: Color = Color(0.0, 0.0, 0.0, 1.0):
	set(value):
		outline_color = value
		_apply_sobel_params()
## Final opacity multiplier for outlines.
@export_range(0.0, 1.0, 0.01) var overlay_opacity: float = 1.0:
	set(value):
		overlay_opacity = value
		_apply_sobel_params()
## Baseline overlay tint independent of edge detection.
@export_range(0.0, 1.0, 0.01) var global_mix: float = 0.0:
	set(value):
		global_mix = value
		_apply_sobel_params()
## Shows raw Sobel edge mask as grayscale.
@export var preview_edges: bool = false:
	set(value):
		preview_edges = value
		_apply_sobel_params()
## Forces full-screen outline color tint for debugging.
@export_range(0.0, 1.0, 0.01) var debug_force_mix: float = 0.0:
	set(value):
		debug_force_mix = value
		_apply_sobel_params()

@export_group("Sobel Distance")
## Enables distance-based thickness scaling and outline fade.
@export var use_distance_controls: bool = true:
	set(value):
		use_distance_controls = value
		_apply_sobel_params()
## Inverts sampled depth if near/far behavior appears flipped.
@export var invert_depth: bool = false:
	set(value):
		invert_depth = value
		_apply_sobel_params()
## Start distance (meters) for thinning/fading.
@export_range(0.0, 10000.0, 0.1) var distance_start: float = 10.0:
	set(value):
		distance_start = value
		_apply_sobel_params()
## End distance (meters) where outlines are thinnest and faded out.
@export_range(0.1, 10000.0, 0.1) var distance_end: float = 100.0:
	set(value):
		distance_end = value
		_apply_sobel_params()
## Thickness multiplier near the camera.
@export_range(0.1, 8.0, 0.01) var near_thickness_multiplier: float = 2.0:
	set(value):
		near_thickness_multiplier = value
		_apply_sobel_params()
## Thickness multiplier at far distance.
@export_range(0.05, 4.0, 0.01) var far_thickness_multiplier: float = 0.5:
	set(value):
		far_thickness_multiplier = value
		_apply_sobel_params()
## Uses active viewport camera near/far clip values.
@export var auto_camera_clip: bool = true:
	set(value):
		auto_camera_clip = value
		_apply_sobel_params()
## Camera near clip when auto_camera_clip is disabled.
@export_range(0.001, 10.0, 0.001) var camera_near: float = 0.05:
	set(value):
		camera_near = value
		_apply_sobel_params()
## Camera far clip when auto_camera_clip is disabled.
@export_range(1.0, 10000.0, 1.0) var camera_far: float = 500.0:
	set(value):
		camera_far = value
		_apply_sobel_params()
## Offset added to camera near clip for overlay quad placement.
@export_range(0.01, 5.0, 0.01) var camera_plane_offset: float = 0.05:
	set(value):
		camera_plane_offset = value
		_apply_sobel_params()

@export_group("Toon Global")
## Enables global toon parameter overrides.
@export var toon_override_enabled: bool = true:
	set(value):
		toon_override_enabled = value
		if toon_override_enabled:
			_queue_toon_reapply()
		else:
			_restore_toon_overrides()
## Reapplies toon overrides automatically when nodes are added to the scene tree.
@export var auto_reapply_on_scene_change: bool = true
## Automatically applies toon overrides at ready.
@export var apply_toon_on_ready: bool = true
## Nodes in this group are skipped by global toon overrides.
@export var toon_exclude_group: StringName = &"toon_override_exempt"

@export_group("Toon Target")
## Restricts shader-material overrides to this shader path.
@export var target_toon_shader_path: String = DEFAULT_TOON_SHADER_PATH:
	set(value):
		target_toon_shader_path = value
		_queue_toon_reapply()
## Requires exact shader path match when applying shader-material overrides.
@export var strict_shader_path_match: bool = false:
	set(value):
		strict_shader_path_match = value
		_queue_toon_reapply()

@export_group("Toon StandardMaterial3D")
## Applies toon overrides to StandardMaterial3D resources.
@export var override_standard_materials: bool = true:
	set(value):
		override_standard_materials = value
		_queue_toon_reapply()
## Forces diffuse/specular toon modes on StandardMaterial3D.
@export var force_standard_toon_modes: bool = true:
	set(value):
		force_standard_toon_modes = value
		_queue_toon_reapply()
## Global StandardMaterial3D specular value.
@export_range(0.0, 1.0, 0.01) var standard_specular: float = 0.0:
	set(value):
		standard_specular = value
		_queue_toon_reapply()
## Enables StandardMaterial3D rim lighting globally.
@export var standard_rim_enabled: bool = false:
	set(value):
		standard_rim_enabled = value
		_queue_toon_reapply()
## Global StandardMaterial3D rim amount.
@export_range(0.0, 1.0, 0.01) var standard_rim: float = 0.12:
	set(value):
		standard_rim = value
		_queue_toon_reapply()
## Global StandardMaterial3D rim tint.
@export_range(0.0, 1.0, 0.01) var standard_rim_tint: float = 0.0:
	set(value):
		standard_rim_tint = value
		_queue_toon_reapply()

@export_group("Toon Stylized Shader")
## Applies stylized toon uniform overrides to ShaderMaterial resources.
@export var override_stylized_shader_materials: bool = true:
	set(value):
		override_stylized_shader_materials = value
		_queue_toon_reapply()
@export var stylized_use_stepped: bool = true:
	set(value):
		stylized_use_stepped = value
		_queue_toon_reapply()
@export_range(1.0, 16.0, 0.1) var stylized_steps: float = 3.0:
	set(value):
		stylized_steps = value
		_queue_toon_reapply()
@export_range(0.0, 1.0, 0.01) var stylized_step_smoothness: float = 0.3:
	set(value):
		stylized_step_smoothness = value
		_queue_toon_reapply()
@export var stylized_shadow_tint: Color = Color(0.0, 0.0, 0.0, 1.0):
	set(value):
		stylized_shadow_tint = value
		_queue_toon_reapply()
@export_range(0.0, 1.0, 0.01) var stylized_shadow_tint_amount: float = 0.4:
	set(value):
		stylized_shadow_tint_amount = value
		_queue_toon_reapply()
@export_range(0.0, 1.0, 0.01) var stylized_specular: float = 0.0:
	set(value):
		stylized_specular = value
		_queue_toon_reapply()
@export var stylized_use_rim: bool = true:
	set(value):
		stylized_use_rim = value
		_queue_toon_reapply()
@export var stylized_rim_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		stylized_rim_color = value
		_queue_toon_reapply()
@export_range(0.0, 8.0, 0.01) var stylized_rim_amount: float = 2.0:
	set(value):
		stylized_rim_amount = value
		_queue_toon_reapply()
@export_range(0.0, 1.0, 0.01) var stylized_rim_smoothness: float = 0.2:
	set(value):
		stylized_rim_smoothness = value
		_queue_toon_reapply()
@export_range(0.0, 1.0, 0.01) var stylized_rim_mask_shadow: float = 1.0:
	set(value):
		stylized_rim_mask_shadow = value
		_queue_toon_reapply()
@export_range(0.0, 1.0, 0.01) var stylized_rim_blend: float = 1.0:
	set(value):
		stylized_rim_blend = value
		_queue_toon_reapply()

var _sobel_pass: Node = null
var _toon_apply_queued: bool = false
var _standard_backups: Dictionary = {}
var _shader_backups: Dictionary = {}
var _shader_uniform_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not visible:
		if _sobel_pass != null:
			_set_sobel_param("sobel_enabled", false)
		return
	_resolve_sobel_pass()
	_apply_sobel_params()
	_connect_tree_signals()
	if apply_toon_on_ready and toon_override_enabled:
		_apply_toon_overrides()


func _process(_delta: float) -> void:
	if not visible:
		return
	if _sobel_pass == null:
		_resolve_sobel_pass()
		_apply_sobel_params()
	if _toon_apply_queued:
		_toon_apply_queued = false
		_apply_toon_overrides()


func _exit_tree() -> void:
	_disconnect_tree_signals()
	_restore_toon_overrides()


func _notification(what: int) -> void:
	if what != NOTIFICATION_VISIBILITY_CHANGED:
		return
	if not is_inside_tree():
		return
	if visible:
		_resolve_sobel_pass()
		_apply_sobel_params()
		_connect_tree_signals()
		if toon_override_enabled:
			_queue_toon_reapply()
	else:
		_disconnect_tree_signals()
		if _sobel_pass != null:
			_set_sobel_param("sobel_enabled", false)
		_restore_toon_overrides()


func _resolve_sobel_pass() -> void:
	var target: Node = get_node_or_null(sobel_pass_path)
	if target == null and auto_create_sobel_pass:
		var packed: PackedScene = load(SOBEL_PASS_SCENE_PATH) as PackedScene
		if packed != null:
			target = packed.instantiate()
			var node_name: String = _node_name_from_path(sobel_pass_path)
			if node_name.is_empty():
				node_name = "SobelDepthPass"
			target.name = node_name
			add_child(target)
			if Engine.is_editor_hint():
				var edited_root: Node = get_tree().edited_scene_root
				if edited_root != null:
					target.owner = edited_root
	if target != _sobel_pass:
		_sobel_pass = target
		_apply_sobel_params()


func _node_name_from_path(path: NodePath) -> String:
	var text: String = String(path)
	if text.is_empty():
		return ""
	var parts: PackedStringArray = text.split("/")
	if parts.is_empty():
		return text
	return parts[parts.size() - 1]


func _apply_sobel_params() -> void:
	if _sobel_pass == null:
		return
	var effective_sobel_enabled: bool = sobel_enabled and visible
	_set_sobel_param("sobel_enabled", effective_sobel_enabled)
	_set_sobel_param("thickness", thickness)
	_set_sobel_param("edge_threshold", edge_threshold)
	_set_sobel_param("edge_softness", edge_softness)
	_set_sobel_param("edge_strength", edge_strength)
	_set_sobel_param("outline_color", outline_color)
	_set_sobel_param("overlay_opacity", overlay_opacity)
	_set_sobel_param("global_mix", global_mix)
	_set_sobel_param("preview_edges", preview_edges)
	_set_sobel_param("debug_force_mix", debug_force_mix)
	_set_sobel_param("use_distance_controls", use_distance_controls)
	_set_sobel_param("invert_depth", invert_depth)
	_set_sobel_param("distance_start", distance_start)
	_set_sobel_param("distance_end", distance_end)
	_set_sobel_param("near_thickness_multiplier", near_thickness_multiplier)
	_set_sobel_param("far_thickness_multiplier", far_thickness_multiplier)
	_set_sobel_param("auto_camera_clip", auto_camera_clip)
	_set_sobel_param("camera_near", camera_near)
	_set_sobel_param("camera_far", camera_far)
	_set_sobel_param("camera_plane_offset", camera_plane_offset)


func _set_sobel_param(property_name: String, value: Variant) -> void:
	if _sobel_pass == null:
		return
	_sobel_pass.set(property_name, value)


func _connect_tree_signals() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	if not tree.node_added.is_connected(_on_tree_node_added):
		tree.node_added.connect(_on_tree_node_added)


func _disconnect_tree_signals() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	if tree.node_added.is_connected(_on_tree_node_added):
		tree.node_added.disconnect(_on_tree_node_added)


func _on_tree_node_added(node: Node) -> void:
	if not visible:
		return
	if not auto_reapply_on_scene_change:
		return
	if not toon_override_enabled:
		return
	if node == self or is_ancestor_of(node):
		return
	_queue_toon_reapply()


func _queue_toon_reapply() -> void:
	if not visible:
		return
	if not toon_override_enabled:
		return
	_toon_apply_queued = true


func _apply_toon_overrides() -> void:
	if not visible:
		return
	if not toon_override_enabled:
		_restore_toon_overrides()
		return

	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var root: Node = tree.current_scene
	if root == null:
		root = tree.root
	if root == null:
		return

	_apply_toon_recursive(root)


func _apply_toon_recursive(node: Node) -> void:
	if node == self or is_ancestor_of(node):
		return
	if not toon_exclude_group.is_empty() and node.is_in_group(toon_exclude_group):
		return

	var mesh_instance: MeshInstance3D = node as MeshInstance3D
	if mesh_instance != null:
		_apply_to_mesh_instance(mesh_instance)

	var csg: CSGShape3D = node as CSGShape3D
	if csg != null:
		_apply_to_csg_shape(csg)

	var multi_mesh_instance: MultiMeshInstance3D = node as MultiMeshInstance3D
	if multi_mesh_instance != null:
		_apply_to_multi_mesh_instance(multi_mesh_instance)

	var children: Array = node.get_children()
	for child_value in children:
		var child: Node = child_value as Node
		if child != null:
			_apply_toon_recursive(child)


func _apply_to_mesh_instance(mesh_instance: MeshInstance3D) -> void:
	var override_material: Material = mesh_instance.material_override
	if override_material != null:
		_apply_to_material(override_material)

	var mesh: Mesh = mesh_instance.mesh
	if mesh == null:
		return
	var surface_count: int = mesh.get_surface_count()
	for surface_index in range(surface_count):
		var material: Material = mesh_instance.get_active_material(surface_index)
		if material != null:
			_apply_to_material(material)


func _apply_to_csg_shape(csg_shape: CSGShape3D) -> void:
	var material: Material = csg_shape.material
	if material != null:
		_apply_to_material(material)


func _apply_to_multi_mesh_instance(multi_mesh_instance: MultiMeshInstance3D) -> void:
	var override_material: Material = multi_mesh_instance.material_override
	if override_material != null:
		_apply_to_material(override_material)
	var multimesh: MultiMesh = multi_mesh_instance.multimesh
	if multimesh == null:
		return
	var mesh: Mesh = multimesh.mesh
	if mesh == null:
		return
	var surface_count: int = mesh.get_surface_count()
	for surface_index in range(surface_count):
		var material: Material = mesh.surface_get_material(surface_index)
		if material != null:
			_apply_to_material(material)


func _apply_to_material(material: Material) -> void:
	if material == null:
		return

	var standard_material: StandardMaterial3D = material as StandardMaterial3D
	if standard_material != null:
		_apply_to_standard_material(standard_material)
		return

	var shader_material: ShaderMaterial = material as ShaderMaterial
	if shader_material != null:
		_apply_to_shader_material(shader_material)


func _apply_to_standard_material(material: StandardMaterial3D) -> void:
	if not override_standard_materials:
		return

	var material_id: int = material.get_instance_id()
	if not _standard_backups.has(material_id):
		var backup: Dictionary = {}
		_backup_property_if_present(material, backup, "diffuse_mode")
		_backup_property_if_present(material, backup, "specular_mode")
		_backup_property_if_present(material, backup, "specular")
		_backup_property_if_present(material, backup, "metallic_specular")
		_backup_property_if_present(material, backup, "rim_enabled")
		_backup_property_if_present(material, backup, "rim")
		_backup_property_if_present(material, backup, "rim_tint")
		_standard_backups[material_id] = backup

	if force_standard_toon_modes:
		_set_property_if_present(material, "diffuse_mode", BaseMaterial3D.DIFFUSE_TOON)
		_set_property_if_present(material, "specular_mode", BaseMaterial3D.SPECULAR_TOON)

	var wrote_specular: bool = _set_property_if_present(material, "specular", standard_specular)
	if not wrote_specular:
		_set_property_if_present(material, "metallic_specular", standard_specular)

	_set_property_if_present(material, "rim_enabled", standard_rim_enabled)
	_set_property_if_present(material, "rim", standard_rim)
	_set_property_if_present(material, "rim_tint", standard_rim_tint)


func _apply_to_shader_material(material: ShaderMaterial) -> void:
	if not override_stylized_shader_materials:
		return

	var shader: Shader = material.shader
	if shader == null:
		return
	if not _is_target_toon_shader(shader):
		return

	var uniform_map: Dictionary = _get_shader_uniform_map(shader)
	if uniform_map.is_empty():
		return

	var material_id: int = material.get_instance_id()
	if not _shader_backups.has(material_id):
		var backup: Dictionary = {}
		_backup_uniform_if_present(material, uniform_map, backup, "use_stepped")
		_backup_uniform_if_present(material, uniform_map, backup, "steps")
		_backup_uniform_if_present(material, uniform_map, backup, "step_smoothness")
		_backup_uniform_if_present(material, uniform_map, backup, "shadow_tint")
		_backup_uniform_if_present(material, uniform_map, backup, "shadow_tint_amount")
		_backup_uniform_if_present(material, uniform_map, backup, "specular")
		_backup_uniform_if_present(material, uniform_map, backup, "use_rim")
		_backup_uniform_if_present(material, uniform_map, backup, "rim_color")
		_backup_uniform_if_present(material, uniform_map, backup, "rim_amount")
		_backup_uniform_if_present(material, uniform_map, backup, "rim_smoothness")
		_backup_uniform_if_present(material, uniform_map, backup, "rim_mask_shadow")
		_backup_uniform_if_present(material, uniform_map, backup, "rim_blend")
		_shader_backups[material_id] = backup

	_set_uniform_if_present(material, uniform_map, "use_stepped", stylized_use_stepped)
	_set_uniform_if_present(material, uniform_map, "steps", stylized_steps)
	_set_uniform_if_present(material, uniform_map, "step_smoothness", stylized_step_smoothness)
	_set_uniform_if_present(material, uniform_map, "shadow_tint", stylized_shadow_tint)
	_set_uniform_if_present(material, uniform_map, "shadow_tint_amount", stylized_shadow_tint_amount)
	_set_uniform_if_present(material, uniform_map, "specular", stylized_specular)
	_set_uniform_if_present(material, uniform_map, "use_rim", stylized_use_rim)
	_set_uniform_if_present(material, uniform_map, "rim_color", stylized_rim_color)
	_set_uniform_if_present(material, uniform_map, "rim_amount", stylized_rim_amount)
	_set_uniform_if_present(material, uniform_map, "rim_smoothness", stylized_rim_smoothness)
	_set_uniform_if_present(material, uniform_map, "rim_mask_shadow", stylized_rim_mask_shadow)
	_set_uniform_if_present(material, uniform_map, "rim_blend", stylized_rim_blend)


func _is_target_toon_shader(shader: Shader) -> bool:
	if strict_shader_path_match:
		return shader.resource_path == target_toon_shader_path
	var uniform_map: Dictionary = _get_shader_uniform_map(shader)
	return uniform_map.has("use_stepped") and uniform_map.has("steps")


func _get_shader_uniform_map(shader: Shader) -> Dictionary:
	var shader_id: int = shader.get_instance_id()
	if _shader_uniform_cache.has(shader_id):
		var cached: Variant = _shader_uniform_cache[shader_id]
		if cached is Dictionary:
			return cached
		return {}

	var uniform_map: Dictionary = {}
	var uniform_list: Array = shader.get_shader_uniform_list(true)
	for entry_value in uniform_list:
		var entry: Dictionary = entry_value as Dictionary
		if entry.is_empty():
			continue
		var uniform_name: String = str(entry.get("name", ""))
		if not uniform_name.is_empty():
			uniform_map[uniform_name] = true

	_shader_uniform_cache[shader_id] = uniform_map
	return uniform_map


func _backup_uniform_if_present(material: ShaderMaterial, uniform_map: Dictionary, backup: Dictionary, uniform_name: String) -> void:
	if not uniform_map.has(uniform_name):
		return
	var current_value: Variant = material.get_shader_parameter(uniform_name)
	backup[uniform_name] = current_value


func _set_uniform_if_present(material: ShaderMaterial, uniform_map: Dictionary, uniform_name: String, value: Variant) -> void:
	if not uniform_map.has(uniform_name):
		return
	material.set_shader_parameter(uniform_name, value)


func _object_has_property(object: Object, property_name: String) -> bool:
	var properties: Array = object.get_property_list()
	for property_info_value in properties:
		var property_info: Dictionary = property_info_value as Dictionary
		if property_info.is_empty():
			continue
		if str(property_info.get("name", "")) == property_name:
			return true
	return false


func _backup_property_if_present(object: Object, backup: Dictionary, property_name: String) -> void:
	if not _object_has_property(object, property_name):
		return
	backup[property_name] = object.get(property_name)


func _set_property_if_present(object: Object, property_name: String, value: Variant) -> bool:
	if not _object_has_property(object, property_name):
		return false
	object.set(property_name, value)
	return true


func _restore_toon_overrides() -> void:
	for material_id_value in _standard_backups.keys():
		var material_id: int = int(material_id_value)
		var object_ref: Object = instance_from_id(material_id)
		var material: StandardMaterial3D = object_ref as StandardMaterial3D
		if material == null:
			continue
		var backup_value: Variant = _standard_backups[material_id_value]
		var backup: Dictionary = backup_value as Dictionary
		for property_name_value in backup.keys():
			var property_name: String = str(property_name_value)
			var property_value: Variant = backup[property_name_value]
			_set_property_if_present(material, property_name, property_value)

	for material_id_value in _shader_backups.keys():
		var material_id: int = int(material_id_value)
		var object_ref: Object = instance_from_id(material_id)
		var material: ShaderMaterial = object_ref as ShaderMaterial
		if material == null:
			continue
		var backup_value: Variant = _shader_backups[material_id_value]
		var backup: Dictionary = backup_value as Dictionary
		for uniform_name_value in backup.keys():
			var uniform_name: String = str(uniform_name_value)
			var uniform_value: Variant = backup[uniform_name_value]
			material.set_shader_parameter(uniform_name, uniform_value)

	_standard_backups.clear()
	_shader_backups.clear()
	_shader_uniform_cache.clear()
