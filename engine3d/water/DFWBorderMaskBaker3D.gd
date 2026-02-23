@tool
extends Node3D

const DFW_SHADER_PATH: String = "res://shaders/dfw/dfw_flowing_water.gdshader"
const DEFAULT_CACHE_DIR: String = "res://temp/dfw_border_masks"
const BYTE_INTERIOR: int = 255
const BYTE_BORDER: int = 0
const BYTE_OCCUPIED: int = 255
const BYTE_EMPTY: int = 0

@export_group("Target")
## Optional explicit water mesh target. If empty, the parent MeshInstance3D is used.
@export_node_path("MeshInstance3D") var target_mesh_path: NodePath
## Surface index to rasterize. -1 processes all triangle surfaces.
@export_range(-1, 128, 1) var target_surface_index: int = -1
## Automatically assigns the generated mask to DFW materials on the target mesh.
@export var auto_assign_to_dfw_materials: bool = true
## If enabled, only surface override materials are edited (safer for shared mesh resources).
@export var assign_surface_overrides_only: bool = true
## Sets `use_border = true` on assigned DFW materials after baking.
@export var force_enable_border: bool = true
## Sets `border_mask_invert = false` on assigned DFW materials after baking.
@export var force_disable_border_invert: bool = true

@export_group("Collision Sampling (Basic)")
## Physics layers to treat as shoreline blockers. If this is wrong, the bake will miss borders.
@export_flags_3d_physics var collision_mask: int = 1
## Uses Terrain3D data API sampling (height query) in addition to physics collisions.
## Recommended when shorelines are Terrain3D and collision wrappers are unreliable in-editor.
@export var detect_terrain3d_via_data_api: bool = true
## Optional explicit Terrain3D node. If empty, the baker auto-finds Terrain3D nodes in the edited scene.
@export_node_path("Node3D") var terrain3d_target_path: NodePath
## Horizontal probe radius in world units around each sampled water point.
## Increase this if borders are missed. Too high can catch nearby clutter.
@export_range(0.001, 8.0, 0.001) var probe_radius_xz: float = 0.12
## Vertical half-height of the contact band (rays cast from +Y to -Y through this range).
## Increase this if terrain/colliders are above/below the water surface more than expected.
@export_range(0.001, 8.0, 0.001) var contact_band_half_height: float = 0.12
## Probe quality controls how many rays are tested per sampled pixel.
## Higher values detect more borders but cost more bake time.
@export_enum("Center Only", "Cardinal 4", "Cardinal + Diagonal 8") var probe_quality: int = 1
## Limits baking to a circular XZ area around the water mesh origin (world-space).
## Strongly recommended for giant planes (10km water sheets, etc.).
@export var use_max_bake_distance_from_center: bool = false
## Maximum XZ distance from the target mesh center to evaluate collision sampling.
## This is in world units, not percent.
@export_range(0.1, 100000.0, 0.1) var max_bake_distance_from_center: float = 250.0
## Crops the baked mask to the circular bake area and projects it from world XZ.
## This makes the texture "zoom in" to the active area instead of stretching over the entire water UVs.
@export var crop_mask_to_bake_radius: bool = true

@export_group("Collision Sampling (Advanced)")
## Static-only phase: ignores dynamic/kinematic bodies in this pass.
@export var static_bodies_only: bool = true
## Also considers Area3D as blockers (usually leave off unless your level uses areas for hard boundaries).
@export var include_areas: bool = false
## Extra XZ push from the mesh center before probing. Use only if borders look slightly inside the geometry.
@export_range(0.0, 1.0, 0.0005) var sample_position_bias: float = 0.0

@export_group("Mask Output")
## Output texture width in pixels.
@export_range(16, 4096, 1) var mask_width: int = 512
## Output texture height in pixels.
@export_range(16, 4096, 1) var mask_height: int = 512
## Expands detected border pixels outward by this many pixels.
## If the result is "mostly white with tiny black dots", increase this first.
@export_range(0, 64, 1) var border_expand_px: int = 2
## Box blur radius applied after expansion (0 disables blur).
## Small blur helps DFW cell-center sampling pick up the border gradient.
@export_range(0, 32, 1) var blur_radius_px: int = 1
## Saves the generated mask to disk as PNG cache.
@export var save_png_cache: bool = true
## Loads and reuses an existing valid cache before rebuilding.
@export var use_existing_cache_if_valid: bool = true
## Cache path for the generated border mask PNG. Empty = auto path under temp/.
@export_file("*.png") var cache_png_path: String = ""

@export_group("Debug")
## Prints a detailed generation summary in the editor output.
@export var debug_log_summary: bool = true
## Writes an additional unblurred/undilated mask PNG next to the cache for inspection.
@export var debug_write_raw_mask_png: bool = false
## Allows assigning a just-generated in-memory texture even if PNG import is not ready yet.
@export var debug_assign_in_memory_texture_fallback: bool = true
## Stores the latest generation report for quick troubleshooting.
@export_multiline var last_report: String = ""

@export_group("Actions")
## Inspector action: builds (or loads cache) and assigns a border mask.
@export var generate_border_mask_now: bool = false:
	set(value):
		generate_border_mask_now = false
		if not value:
			return
		if not Engine.is_editor_hint():
			return
		call_deferred("_editor_generate_border_mask")
## Inspector action: reassigns the cached texture to DFW materials without rebuilding.
@export var assign_cached_mask_now: bool = false:
	set(value):
		assign_cached_mask_now = false
		if not value:
			return
		if not Engine.is_editor_hint():
			return
		call_deferred("_editor_assign_cached_mask")

var _is_generating: bool = false
var _pending_generate: bool = false
var _pending_assign_cache: bool = false
var _last_bake_world_rect_origin_xz: Vector2 = Vector2.ZERO
var _last_bake_world_rect_size_xz: Vector2 = Vector2.ONE
var _last_bake_world_crop_valid: bool = false


func _editor_generate_border_mask() -> void:
	if _is_generating:
		_pending_generate = true
		return
	_is_generating = true
	var report_lines: PackedStringArray = PackedStringArray()
	var ok: bool = _generate_or_load_and_assign(report_lines)
	_is_generating = false
	last_report = "\n".join(report_lines)
	if debug_log_summary:
		print(last_report)
	if not ok:
		push_warning("DFW Border Mask Baker: generation failed. See last_report.")
	if _pending_generate:
		_pending_generate = false
		call_deferred("_editor_generate_border_mask")
	elif _pending_assign_cache:
		_pending_assign_cache = false
		call_deferred("_editor_assign_cached_mask")


func _editor_assign_cached_mask() -> void:
	if _is_generating:
		_pending_assign_cache = true
		return
	var report_lines: PackedStringArray = PackedStringArray()
	var target: MeshInstance3D = _get_target_mesh_instance()
	if target == null:
		report_lines.append("DFW Border Mask Baker: target mesh not found.")
		last_report = "\n".join(report_lines)
		push_warning("DFW Border Mask Baker: target mesh not found.")
		return
	var cache_path: String = _resolve_cache_png_path(target)
	var tex: Texture2D = _load_texture_if_valid(cache_path)
	if tex == null:
		report_lines.append("DFW Border Mask Baker: cache texture not found or invalid: %s" % cache_path)
		last_report = "\n".join(report_lines)
		push_warning("DFW Border Mask Baker: cache texture not found or invalid.")
		return
	var assigned_count: int = 0
	if auto_assign_to_dfw_materials:
		assigned_count = _assign_mask_to_target_materials(target, tex, report_lines)
	report_lines.append("Cache Path: %s" % cache_path)
	report_lines.append("Assigned Materials: %d" % assigned_count)
	last_report = "\n".join(report_lines)
	if debug_log_summary:
		print(last_report)


func _generate_or_load_and_assign(report_lines: PackedStringArray) -> bool:
	var target: MeshInstance3D = _get_target_mesh_instance()
	if target == null:
		report_lines.append("DFW Border Mask Baker: target mesh not found. Set target_mesh_path or parent under a MeshInstance3D.")
		return false
	if target.mesh == null:
		report_lines.append("DFW Border Mask Baker: target mesh instance has no Mesh resource.")
		return false

	var cache_path: String = _resolve_cache_png_path(target)
	var tex_from_cache: Texture2D = null
	if use_existing_cache_if_valid:
		tex_from_cache = _load_texture_if_valid(cache_path)
		if tex_from_cache != null:
			report_lines.append("DFW Border Mask Baker: using existing cache.")
			report_lines.append("Cache Path: %s" % cache_path)
			if auto_assign_to_dfw_materials:
				var cache_assign_count: int = _assign_mask_to_target_materials(target, tex_from_cache, report_lines)
				report_lines.append("Assigned Materials: %d" % cache_assign_count)
			return true
		if FileAccess.file_exists(cache_path):
			report_lines.append("DFW Border Mask Baker: cache exists but is invalid/unloadable. Rebuilding.")

	var image: Image = _build_border_mask_image(target, report_lines)
	if image == null:
		return false
	if image.is_empty():
		report_lines.append("DFW Border Mask Baker: generated image is empty.")
		return false

	var raw_image: Image = null
	if debug_write_raw_mask_png:
		raw_image = image.duplicate()

	if border_expand_px > 0:
		var expanded_data: PackedByteArray = _dilate_black_pixels(image.get_data(), image.get_width(), image.get_height(), border_expand_px)
		image = Image.create_from_data(image.get_width(), image.get_height(), false, Image.FORMAT_L8, expanded_data)

	if blur_radius_px > 0:
		var blurred_data: PackedByteArray = _box_blur_l8(image.get_data(), image.get_width(), image.get_height(), blur_radius_px)
		image = Image.create_from_data(image.get_width(), image.get_height(), false, Image.FORMAT_L8, blurred_data)

	var assigned_texture: Texture2D = null
	if save_png_cache:
		var save_ok: bool = _save_png_cache(image, cache_path, report_lines)
		if save_ok:
			assigned_texture = _load_texture_if_valid(cache_path)
		if debug_write_raw_mask_png and raw_image != null:
			var raw_path: String = _raw_debug_cache_path(cache_path)
			_save_png_cache(raw_image, raw_path, report_lines)

	if assigned_texture == null and debug_assign_in_memory_texture_fallback:
		assigned_texture = ImageTexture.create_from_image(image)
		report_lines.append("DFW Border Mask Baker: using in-memory texture fallback (cache import not ready or disabled).")

	if assigned_texture == null:
		report_lines.append("DFW Border Mask Baker: no texture available to assign after generation.")
		return false

	if auto_assign_to_dfw_materials:
		var assign_count: int = _assign_mask_to_target_materials(target, assigned_texture, report_lines)
		report_lines.append("Assigned Materials: %d" % assign_count)

	report_lines.append("Cache Path: %s" % cache_path)
	report_lines.append("Mask Size: %dx%d" % [image.get_width(), image.get_height()])
	return true


func _get_target_mesh_instance() -> MeshInstance3D:
	if target_mesh_path != NodePath(""):
		var explicit_target: MeshInstance3D = get_node_or_null(target_mesh_path) as MeshInstance3D
		if explicit_target != null:
			return explicit_target
	var parent_mesh: MeshInstance3D = get_parent() as MeshInstance3D
	return parent_mesh


func _resolve_cache_png_path(target: MeshInstance3D) -> String:
	if not cache_png_path.strip_edges().is_empty():
		return cache_png_path.strip_edges()
	var scene_name: String = "unsaved_scene"
	var scene_root: Node = get_tree().edited_scene_root if Engine.is_editor_hint() else get_tree().current_scene
	if scene_root != null and not String(scene_root.name).strip_edges().is_empty():
		scene_name = _sanitize_name(scene_root.name)
	var target_name: String = _sanitize_name(target.name)
	var filename: String = "%s__%s_border_mask.png" % [scene_name, target_name]
	return DEFAULT_CACHE_DIR.path_join(filename)


func _sanitize_name(v: String) -> String:
	var s: String = v.strip_edges()
	if s.is_empty():
		return "unnamed"
	var out: String = ""
	for i: int in s.length():
		var ch: String = s.substr(i, 1)
		var code: int = ch.unicode_at(0)
		var is_ok: bool = (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or ch == "_" or ch == "-" or ch == "."
		out += ch if is_ok else "_"
	return out


func _build_border_mask_image(target: MeshInstance3D, report_lines: PackedStringArray) -> Image:
	var mesh: Mesh = target.mesh
	if mesh == null:
		report_lines.append("DFW Border Mask Baker: target mesh missing.")
		return null

	var world3d: World3D = target.get_world_3d()
	if world3d == null:
		report_lines.append("DFW Border Mask Baker: no World3D available (editor viewport world not ready).")
		return null
	var space_state: PhysicsDirectSpaceState3D = world3d.direct_space_state
	if space_state == null:
		report_lines.append("DFW Border Mask Baker: no PhysicsDirectSpaceState3D available.")
		return null

	var width: int = maxi(mask_width, 16)
	var height: int = maxi(mask_height, 16)
	var occupancy: PackedByteArray = PackedByteArray()
	occupancy.resize(width * height)
	for i: int in occupancy.size():
		occupancy[i] = BYTE_EMPTY
	var coverage: PackedByteArray = PackedByteArray()
	coverage.resize(width * height)
	for i_cov: int in coverage.size():
		coverage[i_cov] = BYTE_EMPTY

	var total_triangles: int = 0
	var sampled_pixels: int = 0
	var occupancy_pixels_written: int = 0
	var covered_pixels_written: int = 0
	var skipped_non_triangle_surfaces: int = 0
	var skipped_missing_uv_surfaces: int = 0
	var skipped_outside_bake_radius: int = 0
	var terrain_nodes: Array[Node3D] = _resolve_terrain3d_nodes(target)
	if detect_terrain3d_via_data_api:
		var terrain_sampling_status: String = "OFF/NOT FOUND" if terrain_nodes.is_empty() else "ON"
		report_lines.append("Terrain3D Data Sampling: %s (%d node(s))" % [terrain_sampling_status, terrain_nodes.size()])
	else:
		report_lines.append("Terrain3D Data Sampling: OFF")

	var local_bias_radius: float = maxf(sample_position_bias, 0.0)
	var bake_center_world: Vector3 = target.global_position
	var use_radius_limit: bool = use_max_bake_distance_from_center and max_bake_distance_from_center > 0.0
	var max_bake_distance_sq: float = max_bake_distance_from_center * max_bake_distance_from_center
	var use_cropped_world_projection: bool = crop_mask_to_bake_radius and use_radius_limit
	_last_bake_world_crop_valid = false
	if use_cropped_world_projection:
		var radius: float = max_bake_distance_from_center
		_last_bake_world_rect_origin_xz = Vector2(bake_center_world.x - radius, bake_center_world.z - radius)
		_last_bake_world_rect_size_xz = Vector2(radius * 2.0, radius * 2.0)
		_last_bake_world_crop_valid = true
	else:
		_last_bake_world_rect_origin_xz = Vector2.ZERO
		_last_bake_world_rect_size_xz = Vector2.ONE
	var query_shape: BoxShape3D = BoxShape3D.new()
	query_shape.size = Vector3(maxf(probe_radius_xz, 0.001) * 2.0, maxf(contact_band_half_height, 0.001) * 2.0, maxf(probe_radius_xz, 0.001) * 2.0)
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = query_shape
	query.collision_mask = collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = include_areas
	query.margin = 0.0
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	ray_query.collision_mask = collision_mask
	ray_query.collide_with_bodies = true
	ray_query.collide_with_areas = include_areas

	var surface_count: int = _mesh_surface_count(mesh)
	if surface_count <= 0:
		report_lines.append("DFW Border Mask Baker: mesh has no readable surfaces.")
		return null

	for surface_idx: int in surface_count:
		if target_surface_index >= 0 and surface_idx != target_surface_index:
			continue
		if mesh is ArrayMesh:
			var array_mesh: ArrayMesh = mesh as ArrayMesh
			var primitive_type: int = array_mesh.surface_get_primitive_type(surface_idx)
			if primitive_type != Mesh.PRIMITIVE_TRIANGLES:
				skipped_non_triangle_surfaces += 1
				continue

		var arrays: Array = _mesh_surface_arrays(mesh, surface_idx)
		if arrays.is_empty():
			continue
		var vertices: PackedVector3Array = _as_packed_vector3_array(_get_surface_array_slot(arrays, Mesh.ARRAY_VERTEX))
		var uvs: PackedVector2Array = _as_packed_vector2_array(_get_surface_array_slot(arrays, Mesh.ARRAY_TEX_UV))
		var indices: PackedInt32Array = _as_packed_int32_array(_get_surface_array_slot(arrays, Mesh.ARRAY_INDEX))

		if vertices.is_empty():
			continue
		if uvs.is_empty() or uvs.size() < vertices.size():
			skipped_missing_uv_surfaces += 1
			continue

		var tri_index_list: PackedInt32Array = _build_triangle_index_list(vertices.size(), indices)
		if tri_index_list.is_empty():
			continue

		var tri_count: int = tri_index_list.size() / 3
		total_triangles += tri_count

		for tri_i: int in tri_count:
			var i0: int = tri_index_list[tri_i * 3 + 0]
			var i1: int = tri_index_list[tri_i * 3 + 1]
			var i2: int = tri_index_list[tri_i * 3 + 2]
			if i0 < 0 or i1 < 0 or i2 < 0:
				continue
			if i0 >= vertices.size() or i1 >= vertices.size() or i2 >= vertices.size():
				continue
			if i0 >= uvs.size() or i1 >= uvs.size() or i2 >= uvs.size():
				continue

			var uv0: Vector2 = uvs[i0]
			var uv1: Vector2 = uvs[i1]
			var uv2: Vector2 = uvs[i2]
			var area_uv: float = (uv1 - uv0).cross(uv2 - uv0)
			if absf(area_uv) <= 0.0000001:
				continue

			var min_uv: Vector2 = Vector2(minf(uv0.x, minf(uv1.x, uv2.x)), minf(uv0.y, minf(uv1.y, uv2.y)))
			var max_uv: Vector2 = Vector2(maxf(uv0.x, maxf(uv1.x, uv2.x)), maxf(uv0.y, maxf(uv1.y, uv2.y)))

			if max_uv.x < 0.0 or max_uv.y < 0.0 or min_uv.x > 1.0 or min_uv.y > 1.0:
				continue

			var min_px: int = maxi(int(floor(min_uv.x * float(width))), 0)
			var min_py: int = maxi(int(floor(min_uv.y * float(height))), 0)
			var max_px: int = mini(int(ceil(max_uv.x * float(width))), width - 1)
			var max_py: int = mini(int(ceil(max_uv.y * float(height))), height - 1)
			if min_px > max_px or min_py > max_py:
				continue

			var v0_local: Vector3 = vertices[i0]
			var v1_local: Vector3 = vertices[i1]
			var v2_local: Vector3 = vertices[i2]

			for py: int in range(min_py, max_py + 1):
				for px: int in range(min_px, max_px + 1):
					var local_pos: Vector3 = Vector3.ZERO
					if use_cropped_world_projection:
						var x_t: float = (float(px) + 0.5) / float(width)
						var z_t: float = (float(py) + 0.5) / float(height)
						var world_x: float = _last_bake_world_rect_origin_xz.x + x_t * _last_bake_world_rect_size_xz.x
						var world_z: float = _last_bake_world_rect_origin_xz.y + z_t * _last_bake_world_rect_size_xz.y
						var world_probe: Vector3 = Vector3(world_x, bake_center_world.y, world_z)
						local_pos = target.global_transform.affine_inverse() * world_probe
					else:
						var uv_p: Vector2 = Vector2((float(px) + 0.5) / float(width), (float(py) + 0.5) / float(height))
						var bary: Vector3 = _barycentric_uv(uv_p, uv0, uv1, uv2, area_uv)
						var inside: bool = bary.x >= -0.001 and bary.y >= -0.001 and bary.z >= -0.001
						if not inside:
							continue
						local_pos = v0_local * bary.x + v1_local * bary.y + v2_local * bary.z

					if use_cropped_world_projection:
						var world_pos_preview: Vector3 = target.global_transform * local_pos
						var dx_crop: float = world_pos_preview.x - bake_center_world.x
						var dz_crop: float = world_pos_preview.z - bake_center_world.z
						if (dx_crop * dx_crop + dz_crop * dz_crop) > max_bake_distance_sq:
							skipped_outside_bake_radius += 1
							continue

					if local_bias_radius > 0.0:
						var lateral: Vector2 = Vector2(local_pos.x, local_pos.z)
						if lateral.length() > 0.00001:
							var lateral_dir: Vector2 = lateral.normalized()
							local_pos.x += lateral_dir.x * local_bias_radius
							local_pos.z += lateral_dir.y * local_bias_radius

					var world_pos: Vector3 = target.global_transform * local_pos
					if use_radius_limit:
						var dx: float = world_pos.x - bake_center_world.x
						var dz: float = world_pos.z - bake_center_world.z
						var dist_sq: float = dx * dx + dz * dz
						if dist_sq > max_bake_distance_sq:
							skipped_outside_bake_radius += 1
							continue
					var is_border: bool = _sample_static_collision_border(space_state, query, ray_query, world_pos, target, terrain_nodes)
					var idx_pixel: int = py * width + px
					if idx_pixel < 0 or idx_pixel >= occupancy.size():
						continue
					if coverage[idx_pixel] != BYTE_OCCUPIED:
						coverage[idx_pixel] = BYTE_OCCUPIED
						covered_pixels_written += 1
					sampled_pixels += 1
					if not is_border:
						continue
					if occupancy[idx_pixel] != BYTE_OCCUPIED:
						occupancy[idx_pixel] = BYTE_OCCUPIED
						occupancy_pixels_written += 1

	var pixels: PackedByteArray = _build_border_mask_from_occupancy(occupancy, coverage, width, height)
	var border_pixels_written: int = _count_value(pixels, BYTE_BORDER)
	var image: Image = Image.create_from_data(width, height, false, Image.FORMAT_L8, pixels)
	report_lines.append("DFW Border Mask Baker: rebuilt border mask from collisions.")
	report_lines.append("Triangles Rasterized: %d" % total_triangles)
	report_lines.append("Pixels Sampled: %d" % sampled_pixels)
	report_lines.append("Covered Pixels: %d" % covered_pixels_written)
	report_lines.append("Occupancy Pixels (raw): %d" % occupancy_pixels_written)
	report_lines.append("Border Pixels (transition): %d" % border_pixels_written)
	report_lines.append("Skipped Non-Triangle Surfaces: %d" % skipped_non_triangle_surfaces)
	report_lines.append("Skipped Missing-UV Surfaces: %d" % skipped_missing_uv_surfaces)
	report_lines.append("Skipped Outside Bake Radius: %d" % skipped_outside_bake_radius)
	if _last_bake_world_crop_valid:
		report_lines.append("Mask Projection: Cropped World XZ")
		report_lines.append("Projection Rect Origin XZ: (%.3f, %.3f)" % [_last_bake_world_rect_origin_xz.x, _last_bake_world_rect_origin_xz.y])
		report_lines.append("Projection Rect Size XZ: (%.3f, %.3f)" % [_last_bake_world_rect_size_xz.x, _last_bake_world_rect_size_xz.y])
	else:
		report_lines.append("Mask Projection: Full Water UV")
	return image


func _mesh_surface_count(mesh: Mesh) -> int:
	if mesh == null:
		return 0
	if mesh is ArrayMesh:
		return (mesh as ArrayMesh).get_surface_count()
	if mesh.has_method("get_mesh_arrays"):
		return 1
	return 0


func _mesh_surface_arrays(mesh: Mesh, surface_idx: int) -> Array:
	if mesh == null:
		return []
	if mesh is ArrayMesh:
		var array_mesh: ArrayMesh = mesh as ArrayMesh
		if surface_idx < 0 or surface_idx >= array_mesh.get_surface_count():
			return []
		return array_mesh.surface_get_arrays(surface_idx)
	if surface_idx != 0:
		return []
	if mesh.has_method("get_mesh_arrays"):
		var arrays_variant: Variant = mesh.call("get_mesh_arrays")
		if arrays_variant is Array:
			return arrays_variant
	return []


func _get_surface_array_slot(arrays: Array, slot_idx: int) -> Variant:
	if slot_idx < 0 or slot_idx >= arrays.size():
		return null
	return arrays[slot_idx]


func _as_packed_vector3_array(value: Variant) -> PackedVector3Array:
	if value is PackedVector3Array:
		return value
	return PackedVector3Array()


func _as_packed_vector2_array(value: Variant) -> PackedVector2Array:
	if value is PackedVector2Array:
		return value
	return PackedVector2Array()


func _as_packed_int32_array(value: Variant) -> PackedInt32Array:
	if value is PackedInt32Array:
		return value
	return PackedInt32Array()


func _build_triangle_index_list(vertex_count: int, indices: PackedInt32Array) -> PackedInt32Array:
	var out: PackedInt32Array = PackedInt32Array()
	if not indices.is_empty():
		var tri_count_from_indices: int = indices.size() / 3
		out.resize(tri_count_from_indices * 3)
		for i: int in out.size():
			out[i] = indices[i]
		return out
	var tri_count: int = vertex_count / 3
	out.resize(tri_count * 3)
	for t: int in tri_count:
		out[t * 3 + 0] = t * 3 + 0
		out[t * 3 + 1] = t * 3 + 1
		out[t * 3 + 2] = t * 3 + 2
	return out


func _barycentric_uv(p: Vector2, a: Vector2, b: Vector2, c: Vector2, precomputed_area: float) -> Vector3:
	var area: float = precomputed_area
	if absf(area) <= 0.0000001:
		return Vector3(-1.0, -1.0, -1.0)
	var w0: float = (b - p).cross(c - p) / area
	var w1: float = (c - p).cross(a - p) / area
	var w2: float = 1.0 - w0 - w1
	return Vector3(w0, w1, w2)


func _sample_static_collision_border(
	space_state: PhysicsDirectSpaceState3D,
	query: PhysicsShapeQueryParameters3D,
	ray_query: PhysicsRayQueryParameters3D,
	world_pos: Vector3,
	target: MeshInstance3D,
	terrain_nodes: Array[Node3D]
) -> bool:
	if detect_terrain3d_via_data_api and _sample_terrain3d_border_data(world_pos, terrain_nodes):
		return true
	if _sample_static_collision_border_rays(space_state, ray_query, world_pos, target):
		return true
	query.transform = Transform3D(Basis.IDENTITY, world_pos)
	var hits: Array = space_state.intersect_shape(query, 16)
	if hits.is_empty():
		return false
	for hit_variant: Variant in hits:
		if not (hit_variant is Dictionary):
			continue
		var hit: Dictionary = hit_variant as Dictionary
		var collider_variant: Variant = hit.get("collider", null)
		if collider_variant == null:
			continue
		if collider_variant is CollisionObject3D:
			var collider_obj: CollisionObject3D = collider_variant as CollisionObject3D
			if _should_count_as_border_collision(collider_obj, target):
				return true
	return false


func _resolve_terrain3d_nodes(target: MeshInstance3D) -> Array[Node3D]:
	var out: Array[Node3D] = []
	if not detect_terrain3d_via_data_api:
		return out
	if terrain3d_target_path != NodePath(""):
		var explicit_node: Node = get_node_or_null(terrain3d_target_path)
		var explicit_node3d: Node3D = explicit_node as Node3D
		if explicit_node3d != null and explicit_node3d.is_class("Terrain3D"):
			out.append(explicit_node3d)
			return out

	var root: Node = null
	if Engine.is_editor_hint():
		root = get_tree().edited_scene_root
	if root == null:
		root = get_tree().current_scene
	if root == null and target != null:
		root = target.get_tree().root
	if root == null:
		return out
	_collect_terrain3d_nodes(root, out)
	return out


func _collect_terrain3d_nodes(node: Node, out: Array[Node3D]) -> void:
	if node == null:
		return
	var node3d: Node3D = node as Node3D
	if node3d != null and node3d.is_class("Terrain3D"):
		out.append(node3d)
	for child: Node in node.get_children():
		_collect_terrain3d_nodes(child, out)


func _sample_terrain3d_border_data(world_pos: Vector3, terrain_nodes: Array[Node3D]) -> bool:
	if terrain_nodes.is_empty():
		return false
	var up_half: float = maxf(contact_band_half_height, 0.001)
	var radius: float = maxf(probe_radius_xz, 0.0)
	var offsets: Array[Vector2] = [Vector2.ZERO]
	var ring_samples: int = _probe_ring_sample_count()
	if ring_samples >= 4 and radius > 0.0:
		offsets.append(Vector2(radius, 0.0))
		offsets.append(Vector2(-radius, 0.0))
		offsets.append(Vector2(0.0, radius))
		offsets.append(Vector2(0.0, -radius))
	if ring_samples >= 8 and radius > 0.0:
		var diag: float = radius * 0.70710678
		offsets.append(Vector2(diag, diag))
		offsets.append(Vector2(-diag, diag))
		offsets.append(Vector2(diag, -diag))
		offsets.append(Vector2(-diag, -diag))

	for off: Vector2 in offsets:
		var sample_world: Vector3 = world_pos + Vector3(off.x, 0.0, off.y)
		for terrain: Node3D in terrain_nodes:
			var h: float = _terrain3d_height_at_world(terrain, sample_world)
			if is_nan(h):
				continue
			if absf(h - world_pos.y) <= up_half:
				return true
	return false


func _terrain3d_height_at_world(terrain: Node3D, sample_world: Vector3) -> float:
	if terrain == null:
		return NAN
	var terrain_data: Object = terrain.get("data") as Object
	if terrain_data == null:
		return NAN
	if not terrain_data.has_method("get_height"):
		return NAN
	var h_variant: Variant = terrain_data.call("get_height", sample_world)
	var t: int = typeof(h_variant)
	if t == TYPE_FLOAT or t == TYPE_INT:
		return float(h_variant)
	return NAN


func _sample_static_collision_border_rays(space_state: PhysicsDirectSpaceState3D, ray_query: PhysicsRayQueryParameters3D, world_pos: Vector3, target: MeshInstance3D) -> bool:
	var up_half: float = maxf(contact_band_half_height, 0.001)
	var radius: float = maxf(probe_radius_xz, 0.0)
	var offsets: Array[Vector2] = [Vector2.ZERO]
	var ring_samples: int = _probe_ring_sample_count()
	if ring_samples >= 4 and radius > 0.0:
		offsets.append(Vector2(radius, 0.0))
		offsets.append(Vector2(-radius, 0.0))
		offsets.append(Vector2(0.0, radius))
		offsets.append(Vector2(0.0, -radius))
	if ring_samples >= 8 and radius > 0.0:
		var diag: float = radius * 0.70710678
		offsets.append(Vector2(diag, diag))
		offsets.append(Vector2(-diag, diag))
		offsets.append(Vector2(diag, -diag))
		offsets.append(Vector2(-diag, -diag))

	for off: Vector2 in offsets:
		var p_from: Vector3 = world_pos + Vector3(off.x, up_half, off.y)
		var p_to: Vector3 = world_pos + Vector3(off.x, -up_half, off.y)
		ray_query.from = p_from
		ray_query.to = p_to
		var hit_variant: Variant = space_state.intersect_ray(ray_query)
		if hit_variant is Dictionary:
			var hit: Dictionary = hit_variant as Dictionary
			var collider_variant: Variant = hit.get("collider", null)
			if collider_variant is CollisionObject3D:
				var collider_obj: CollisionObject3D = collider_variant as CollisionObject3D
				if _should_count_as_border_collision(collider_obj, target):
					return true
	return false


func _probe_ring_sample_count() -> int:
	if probe_quality <= 0:
		return 0
	if probe_quality == 1:
		return 4
	return 8


func _should_count_as_border_collision(collider_obj: CollisionObject3D, target: MeshInstance3D) -> bool:
	if collider_obj == null:
		return false
	if not include_areas and collider_obj is Area3D:
		return false
	if static_bodies_only:
		if not (collider_obj is StaticBody3D):
			return false
	if _is_same_or_child_of(collider_obj, target):
		return false
	return true


func _is_same_or_child_of(node: Node, root: Node) -> bool:
	var current: Node = node
	while current != null:
		if current == root:
			return true
		current = current.get_parent()
	return false


func _dilate_black_pixels(src: PackedByteArray, width: int, height: int, iterations: int) -> PackedByteArray:
	var current: PackedByteArray = src
	for _iter: int in iterations:
		var next_data: PackedByteArray = PackedByteArray()
		next_data.resize(current.size())
		for y: int in height:
			for x: int in width:
				var idx: int = y * width + x
				var v: int = current[idx]
				if v == BYTE_BORDER:
					next_data[idx] = BYTE_BORDER
					continue
				var has_black_neighbor: bool = false
				for oy: int in range(-1, 2):
					if has_black_neighbor:
						break
					var ny: int = y + oy
					if ny < 0 or ny >= height:
						continue
					for ox: int in range(-1, 2):
						var nx: int = x + ox
						if nx < 0 or nx >= width:
							continue
						var nidx: int = ny * width + nx
						if current[nidx] == BYTE_BORDER:
							has_black_neighbor = true
							break
				next_data[idx] = BYTE_BORDER if has_black_neighbor else v
		current = next_data
	return current


func _build_border_mask_from_occupancy(occupancy: PackedByteArray, coverage: PackedByteArray, width: int, height: int) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	out.resize(occupancy.size())
	for i: int in out.size():
		out[i] = BYTE_INTERIOR

	for y: int in height:
		for x: int in width:
			var idx: int = y * width + x
			if idx < 0 or idx >= coverage.size():
				continue
			if coverage[idx] < 128:
				continue
			var occ_center: bool = occupancy[idx] >= 128
			var touches_transition: bool = false
			var has_covered_neighbor: bool = false
			for oy: int in range(-1, 2):
				if touches_transition:
					break
				var ny: int = y + oy
				if ny < 0 or ny >= height:
					continue
				for ox: int in range(-1, 2):
					if ox == 0 and oy == 0:
						continue
					var nx: int = x + ox
					if nx < 0 or nx >= width:
						continue
					var nidx: int = ny * width + nx
					if nidx < 0 or nidx >= coverage.size():
						continue
					if coverage[nidx] < 128:
						continue
					has_covered_neighbor = true
					var occ_neighbor: bool = occupancy[nidx] >= 128
					if occ_neighbor != occ_center:
						touches_transition = true
						break
			if has_covered_neighbor and touches_transition:
				out[idx] = BYTE_BORDER
	return out


func _count_value(data: PackedByteArray, target_value: int) -> int:
	var count: int = 0
	for i: int in data.size():
		if int(data[i]) == target_value:
			count += 1
	return count


func _box_blur_l8(src: PackedByteArray, width: int, height: int, radius: int) -> PackedByteArray:
	if radius <= 0:
		return src
	var temp: PackedByteArray = PackedByteArray()
	temp.resize(src.size())
	var dst: PackedByteArray = PackedByteArray()
	dst.resize(src.size())

	# Horizontal pass.
	for y: int in height:
		for x: int in width:
			var sum: int = 0
			var count: int = 0
			for ox: int in range(-radius, radius + 1):
				var nx: int = x + ox
				if nx < 0 or nx >= width:
					continue
				sum += int(src[y * width + nx])
				count += 1
			var idx: int = y * width + x
			temp[idx] = int(round(float(sum) / float(maxi(count, 1))))

	# Vertical pass.
	for y2: int in height:
		for x2: int in width:
			var sum2: int = 0
			var count2: int = 0
			for oy: int in range(-radius, radius + 1):
				var ny2: int = y2 + oy
				if ny2 < 0 or ny2 >= height:
					continue
				sum2 += int(temp[ny2 * width + x2])
				count2 += 1
			var idx2: int = y2 * width + x2
			dst[idx2] = int(round(float(sum2) / float(maxi(count2, 1))))
	return dst


func _save_png_cache(image: Image, res_path: String, report_lines: PackedStringArray) -> bool:
	var dir_res: String = res_path.get_base_dir()
	var dir_abs: String = ProjectSettings.globalize_path(dir_res)
	var make_err: Error = DirAccess.make_dir_recursive_absolute(dir_abs)
	if make_err != OK:
		report_lines.append("DFW Border Mask Baker: failed to create cache directory (%s), error %d" % [dir_res, int(make_err)])
		return false
	var abs_path: String = ProjectSettings.globalize_path(res_path)
	var save_err: Error = image.save_png(abs_path)
	if save_err != OK:
		report_lines.append("DFW Border Mask Baker: failed to save PNG cache (%s), error %d" % [res_path, int(save_err)])
		return false
	report_lines.append("DFW Border Mask Baker: saved PNG cache.")
	return true


func _raw_debug_cache_path(main_cache_path: String) -> String:
	var base: String = main_cache_path.get_basename()
	return "%s__raw.png" % base


func _load_texture_if_valid(res_path: String) -> Texture2D:
	if res_path.is_empty():
		return null
	if not FileAccess.file_exists(res_path):
		return null
	var tex: Texture2D = ResourceLoader.load(res_path, "Texture2D") as Texture2D
	return tex


func _assign_mask_to_target_materials(target: MeshInstance3D, tex: Texture2D, report_lines: PackedStringArray) -> int:
	if target == null or tex == null:
		return 0
	var materials: Array[ShaderMaterial] = _collect_target_dfw_materials(target)
	if materials.is_empty():
		report_lines.append("DFW Border Mask Baker: no DFW ShaderMaterial found on target.")
		return 0
	var assigned_count: int = 0
	for mat: ShaderMaterial in materials:
		if mat == null:
			continue
		mat.set_shader_parameter("border_mask", tex)
		if _last_bake_world_crop_valid:
			_apply_cropped_mask_uv_projection(target, mat)
		else:
			mat.set_shader_parameter("border_mask_uv_scale", Vector2(1.0, 1.0))
			mat.set_shader_parameter("border_mask_uv_offset", Vector2(0.0, 0.0))
		if force_enable_border:
			mat.set_shader_parameter("use_border", true)
		if force_disable_border_invert:
			mat.set_shader_parameter("border_mask_invert", false)
		assigned_count += 1
	return assigned_count


func _collect_target_dfw_materials(target: MeshInstance3D) -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	if target == null:
		return out

	var mat_override: Material = target.material_override
	if mat_override is ShaderMaterial:
		var sm_override: ShaderMaterial = mat_override as ShaderMaterial
		if _is_dfw_shader_material(sm_override):
			out.append(sm_override)

	var mesh: Mesh = target.mesh
	var surface_count: int = _mesh_surface_count(mesh)
	for i: int in surface_count:
		var candidate: Material = target.get_surface_override_material(i)
		if candidate == null and not assign_surface_overrides_only and mesh != null:
			candidate = mesh.surface_get_material(i)
		if candidate is ShaderMaterial:
			var sm: ShaderMaterial = candidate as ShaderMaterial
			if _is_dfw_shader_material(sm) and not out.has(sm):
				out.append(sm)
	return out


func _is_dfw_shader_material(mat: ShaderMaterial) -> bool:
	if mat == null or mat.shader == null:
		return false
	var shader_path: String = mat.shader.resource_path
	return shader_path == DFW_SHADER_PATH


func _apply_cropped_mask_uv_projection(target: MeshInstance3D, mat: ShaderMaterial) -> void:
	if target == null or mat == null or not _last_bake_world_crop_valid:
		return
	var mesh: Mesh = target.mesh
	if mesh == null:
		return
	var aabb: AABB = mesh.get_aabb()
	var uv_rect: Rect2 = _estimate_mesh_uv_rect(mesh)
	var uv_size: Vector2 = uv_rect.size
	if absf(uv_size.x) <= 0.000001 or absf(uv_size.y) <= 0.000001:
		mat.set_shader_parameter("border_mask_uv_scale", Vector2(1.0, 1.0))
		mat.set_shader_parameter("border_mask_uv_offset", Vector2(0.0, 0.0))
		return

	# Assumes plane/river-strip convention: local XZ maps to UV XY approximately linearly.
	var local_min_xz: Vector2 = Vector2(aabb.position.x, aabb.position.z)
	var local_size_xz: Vector2 = Vector2(maxf(aabb.size.x, 0.000001), maxf(aabb.size.z, 0.000001))

	var world_origin_local: Vector3 = target.global_transform.affine_inverse() * Vector3(_last_bake_world_rect_origin_xz.x, target.global_position.y, _last_bake_world_rect_origin_xz.y)
	var world_max_local: Vector3 = target.global_transform.affine_inverse() * Vector3(_last_bake_world_rect_origin_xz.x + _last_bake_world_rect_size_xz.x, target.global_position.y, _last_bake_world_rect_origin_xz.y + _last_bake_world_rect_size_xz.y)
	var crop_local_min_xz: Vector2 = Vector2(world_origin_local.x, world_origin_local.z)
	var crop_local_size_xz: Vector2 = Vector2(world_max_local.x - world_origin_local.x, world_max_local.z - world_origin_local.z)
	if absf(crop_local_size_xz.x) <= 0.000001 or absf(crop_local_size_xz.y) <= 0.000001:
		mat.set_shader_parameter("border_mask_uv_scale", Vector2(1.0, 1.0))
		mat.set_shader_parameter("border_mask_uv_offset", Vector2(0.0, 0.0))
		return

	var u0: float = uv_rect.position.x + ((crop_local_min_xz.x - local_min_xz.x) / local_size_xz.x) * uv_size.x
	var v0: float = uv_rect.position.y + ((crop_local_min_xz.y - local_min_xz.y) / local_size_xz.y) * uv_size.y
	var u1: float = uv_rect.position.x + (((crop_local_min_xz.x + crop_local_size_xz.x) - local_min_xz.x) / local_size_xz.x) * uv_size.x
	var v1: float = uv_rect.position.y + (((crop_local_min_xz.y + crop_local_size_xz.y) - local_min_xz.y) / local_size_xz.y) * uv_size.y

	var denom_u: float = maxf(u1 - u0, 0.000001)
	var denom_v: float = maxf(v1 - v0, 0.000001)
	var scale_uv: Vector2 = Vector2(1.0 / denom_u, 1.0 / denom_v)
	var offset_uv: Vector2 = Vector2(-u0 / denom_u, -v0 / denom_v)
	mat.set_shader_parameter("border_mask_uv_scale", scale_uv)
	mat.set_shader_parameter("border_mask_uv_offset", offset_uv)


func _estimate_mesh_uv_rect(mesh: Mesh) -> Rect2:
	var rect_valid: bool = false
	var min_uv: Vector2 = Vector2.ZERO
	var max_uv: Vector2 = Vector2.ZERO
	var surface_count: int = _mesh_surface_count(mesh)
	for surface_idx: int in surface_count:
		var arrays: Array = _mesh_surface_arrays(mesh, surface_idx)
		if arrays.is_empty():
			continue
		var uvs: PackedVector2Array = _as_packed_vector2_array(_get_surface_array_slot(arrays, Mesh.ARRAY_TEX_UV))
		if uvs.is_empty():
			continue
		for uv: Vector2 in uvs:
			if not rect_valid:
				min_uv = uv
				max_uv = uv
				rect_valid = true
			else:
				min_uv.x = minf(min_uv.x, uv.x)
				min_uv.y = minf(min_uv.y, uv.y)
				max_uv.x = maxf(max_uv.x, uv.x)
				max_uv.y = maxf(max_uv.y, uv.y)
	if not rect_valid:
		return Rect2(Vector2.ZERO, Vector2.ONE)
	var size: Vector2 = max_uv - min_uv
	if absf(size.x) <= 0.000001:
		size.x = 1.0
	if absf(size.y) <= 0.000001:
		size.y = 1.0
	return Rect2(min_uv, size)
