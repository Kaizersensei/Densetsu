@tool
extends RefCounted

const OPT_INCLUDE_MESH_INSTANCES := "include_mesh_instances"
const OPT_INCLUDE_CSG := "include_csg"
const OPT_INCLUDE_MULTIMESH := "include_multimesh"
const OPT_APPLY_WORLD_TRANSFORM := "apply_world_transform"
const OPT_FLIP_V_TEXCOORD := "flip_v_texcoord"
const OPT_ENFORCE_OUTWARD_WINDING := "enforce_outward_winding"
const OPT_MANIFOLD_ONLY := "manifold_only"
const OPT_REMOVE_ENCLOSED_FACES := "remove_enclosed_faces"


func export_nodes_to_obj(roots: Array, output_path: String, options: Dictionary = {}) -> Dictionary:
	if roots.is_empty():
		return {
			"ok": false,
			"error": "No selected roots."
		}

	var include_mesh_instances: bool = bool(options.get(OPT_INCLUDE_MESH_INSTANCES, true))
	var include_csg: bool = bool(options.get(OPT_INCLUDE_CSG, true))
	var include_multimesh: bool = bool(options.get(OPT_INCLUDE_MULTIMESH, false))
	var apply_world_transform: bool = bool(options.get(OPT_APPLY_WORLD_TRANSFORM, true))
	var flip_v_texcoord: bool = bool(options.get(OPT_FLIP_V_TEXCOORD, true))
	var enforce_outward_winding: bool = bool(options.get(OPT_ENFORCE_OUTWARD_WINDING, true))
	var manifold_only: bool = bool(options.get(OPT_MANIFOLD_ONLY, true))
	var remove_enclosed_faces: bool = bool(options.get(OPT_REMOVE_ENCLOSED_FACES, true))

	var mesh_items: Array = []
	for root in roots:
		if root is Node3D:
			_collect_node_geometry(root as Node3D, mesh_items, include_mesh_instances, include_csg, include_multimesh, apply_world_transform, true)

	if mesh_items.is_empty():
		return {
			"ok": false,
			"error": "No exportable geometry found under selected roots."
		}

	var mtl_path := output_path.get_basename() + ".mtl"
	var mtl_abs_path := _to_abs_path(mtl_path)
	var build := _build_obj_text(
		mesh_items,
		flip_v_texcoord,
		mtl_abs_path,
		enforce_outward_winding,
		manifold_only,
		remove_enclosed_faces
	)
	var obj_text: String = String(build.get("text", ""))
	var face_count: int = int(build.get("faces", 0))
	if face_count <= 0 or obj_text.is_empty():
		var total_surfaces: int = int(build.get("total_surfaces", 0))
		var triangle_surfaces: int = int(build.get("triangle_surfaces", 0))
		var skipped_surfaces: int = int(build.get("skipped_surfaces", 0))
		var unsupported_primitives: String = String(build.get("unsupported_primitives", ""))
		var detail := "Geometry found but no supported triangle surfaces were exported."
		if total_surfaces > 0:
			detail += " total_surfaces=%d triangle_surfaces=%d skipped=%d" % [total_surfaces, triangle_surfaces, skipped_surfaces]
		if not unsupported_primitives.is_empty():
			detail += " unsupported_primitive_ids=[" + unsupported_primitives + "]"
		return {
			"ok": false,
			"error": detail
		}

	_ensure_output_dir(output_path)
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		return {
			"ok": false,
			"error": "Failed to open output path: %s" % output_path
		}
	file.store_string(obj_text)
	file.close()

	var mtl_text: String = String(build.get("mtl_text", ""))
	if not mtl_text.is_empty():
		var mtl_file := FileAccess.open(mtl_path, FileAccess.WRITE)
		if mtl_file == null:
			return {
				"ok": false,
				"error": "OBJ written but failed to write MTL: %s" % mtl_path
			}
		mtl_file.store_string(mtl_text)
		mtl_file.close()

	return {
		"ok": true,
		"path": output_path,
		"items": mesh_items.size(),
		"faces": face_count,
		"skipped_surfaces": int(build.get("skipped_surfaces", 0)),
		"mtl_path": mtl_path,
		"materials": int(build.get("materials", 0))
	}


func _collect_node_geometry(
	node: Node3D,
	out_items: Array,
	include_mesh_instances: bool,
	include_csg: bool,
	include_multimesh: bool,
	apply_world_transform: bool,
	is_selected_root: bool
) -> void:
	if node is CollisionShape3D or node is CollisionPolygon3D:
		return

	if include_csg and node is CSGShape3D:
		var csg := node as CSGShape3D
		var parent_is_csg: bool = csg.get_parent() is CSGShape3D
		if is_selected_root or not parent_is_csg:
			var csg_mesh := _extract_csg_mesh(csg)
			if csg_mesh != null:
				var csg_xf := csg.global_transform if apply_world_transform else Transform3D.IDENTITY
				out_items.append({
					"name": csg.name,
					"mesh": csg_mesh,
					"transform": csg_xf,
					"material_override": null,
					"surface_overrides": []
				})
		# CSG trees are exported from the chosen CSG root. Do not recurse inside.
		return

	if include_mesh_instances and node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			var mi_xf := mi.global_transform if apply_world_transform else Transform3D.IDENTITY
			var surface_overrides: Array = []
			for sidx in range(mi.mesh.get_surface_count()):
				surface_overrides.append(mi.get_surface_override_material(sidx))
			out_items.append({
				"name": mi.name,
				"mesh": mi.mesh,
				"transform": mi_xf,
				"material_override": mi.material_override,
				"surface_overrides": surface_overrides
			})

	if include_multimesh and node is MultiMeshInstance3D:
		_append_multimesh_instances(node as MultiMeshInstance3D, out_items, apply_world_transform)

	for child in node.get_children():
		if child is Node3D:
			_collect_node_geometry(child as Node3D, out_items, include_mesh_instances, include_csg, include_multimesh, apply_world_transform, false)


func _extract_csg_mesh(csg: CSGShape3D) -> Mesh:
	if csg.has_method("bake_static_mesh"):
		var baked_any: Variant = csg.call("bake_static_mesh")
		if baked_any is Mesh:
			return baked_any as Mesh

	if csg.has_method("get_meshes"):
		var meshes_any: Variant = csg.call("get_meshes")
		if meshes_any is Array:
			var mesh_list: Array = meshes_any
			for entry in mesh_list:
				if entry is Mesh:
					return entry as Mesh

	return null


func _append_multimesh_instances(mmi: MultiMeshInstance3D, out_items: Array, apply_world_transform: bool) -> void:
	var mm := mmi.multimesh
	if mm == null:
		return
	if mm.mesh == null:
		return
	var source_mesh: Mesh = mm.mesh
	var count: int = int(mm.instance_count)
	if count <= 0:
		return

	for i in range(count):
		var visible: bool = true
		if mm.has_method("get_instance_visible"):
			var vis_any: Variant = mm.call("get_instance_visible", i)
			if vis_any is bool:
				visible = bool(vis_any)
		if not visible:
			continue

		var local_xf: Transform3D = mm.get_instance_transform(i)
		var world_xf := local_xf
		if apply_world_transform:
			world_xf = mmi.global_transform * local_xf
		out_items.append({
			"name": "%s_i%d" % [mmi.name, i],
			"mesh": source_mesh,
			"transform": world_xf,
			"material_override": mmi.material_override,
			"surface_overrides": []
		})


func _build_obj_text(
	mesh_items: Array,
	flip_v_texcoord: bool,
	mtl_abs_path: String,
	enforce_outward_winding: bool,
	manifold_only: bool,
	remove_enclosed_faces: bool
) -> Dictionary:
	var lines := PackedStringArray()
	lines.append("# Densetsu Geometry OBJ Export")
	if not mtl_abs_path.is_empty():
		lines.append("mtllib " + _obj_path_escape(mtl_abs_path))
	lines.append("o scene_export")

	var mtl_lines: Array = []
	mtl_lines.append("# Densetsu Geometry OBJ Export Materials")

	var material_key_to_name := {}
	var material_name_registry := {}
	var next_material_index: int = 1

	var vertex_offset: int = 0
	var uv_offset: int = 0
	var normal_offset: int = 0
	var face_count: int = 0
	var skipped_surfaces: int = 0
	var total_surfaces: int = 0
	var triangle_surfaces: int = 0
	var unsupported_by_primitive := {}
	var current_usemtl := ""

	for item in mesh_items:
		var mesh := item.get("mesh", null) as Mesh
		if mesh == null:
			continue
		var mesh_name := _sanitize_obj_name(String(item.get("name", "mesh")))
		var xf: Transform3D = Transform3D.IDENTITY
		var xf_any: Variant = item.get("transform", Transform3D.IDENTITY)
		if xf_any is Transform3D:
			xf = xf_any

		var normal_basis := xf.basis
		if xf.basis.determinant() != 0.0:
			normal_basis = xf.basis.inverse().transposed()
		var item_surface_records: Array = []
		var item_center_sum := Vector3.ZERO
		var item_center_count: int = 0

		for surface_idx in range(mesh.get_surface_count()):
			var arrays: Array = mesh.surface_get_arrays(surface_idx)
			if arrays.is_empty():
				continue

			var vertices: PackedVector3Array = _as_packed_vector3_array(_array_slot(arrays, Mesh.ARRAY_VERTEX))
			if vertices.is_empty():
				continue
			total_surfaces += 1

			var normals: PackedVector3Array = _as_packed_vector3_array(_array_slot(arrays, Mesh.ARRAY_NORMAL))
			var uvs: PackedVector2Array = _as_packed_vector2_array(_array_slot(arrays, Mesh.ARRAY_TEX_UV))
			var indices: PackedInt32Array = _as_packed_int32_array(_array_slot(arrays, Mesh.ARRAY_INDEX))
			var primitive: int = _get_surface_primitive_type(mesh, surface_idx)
			var triangles: PackedInt32Array = _build_triangle_indices(primitive, vertices.size(), indices)
			if triangles.is_empty():
				skipped_surfaces += 1
				if primitive != Mesh.PRIMITIVE_TRIANGLES and primitive != Mesh.PRIMITIVE_TRIANGLE_STRIP:
					unsupported_by_primitive[primitive] = int(unsupported_by_primitive.get(primitive, 0)) + 1
				continue

			var has_uv: bool = (not uvs.is_empty()) and (uvs.size() == vertices.size())
			var has_normal: bool = (not normals.is_empty()) and (normals.size() == vertices.size())
			var transformed_vertices: PackedVector3Array = PackedVector3Array()
			transformed_vertices.resize(vertices.size())
			for vi in range(vertices.size()):
				transformed_vertices[vi] = xf * vertices[vi]
				item_center_sum += transformed_vertices[vi]
				item_center_count += 1
			var transformed_normals: PackedVector3Array = PackedVector3Array()
			if has_normal:
				transformed_normals.resize(normals.size())
				for ni in range(normals.size()):
					transformed_normals[ni] = (normal_basis * normals[ni]).normalized()

			var topology_filter: Dictionary = _filter_surface_triangles(
				triangles,
				transformed_vertices,
				manifold_only,
				remove_enclosed_faces
			)
			triangles = topology_filter.get("triangles", PackedInt32Array())
			if triangles.is_empty():
				skipped_surfaces += 1
				continue
			triangle_surfaces += 1

			var surface_material: Material = _resolve_surface_material(item, mesh, surface_idx)
			var bounds: Dictionary = _compute_surface_bounds(transformed_vertices)
			item_surface_records.append({
				"surface_idx": surface_idx,
				"vertices": vertices,
				"uvs": uvs,
				"normals": normals,
				"triangles": triangles,
				"has_uv": has_uv,
				"has_normal": has_normal,
				"transformed_vertices": transformed_vertices,
				"transformed_normals": transformed_normals,
				"surface_material": surface_material,
				"aabb": bounds.get("aabb", AABB()),
				"center": bounds.get("center", Vector3.ZERO),
				"radius": float(bounds.get("radius", 0.0))
			})

		if item_surface_records.is_empty():
			continue

		var item_center := Vector3.ZERO
		if item_center_count > 0:
			item_center = item_center_sum / float(item_center_count)

		var item_orientation_vote := 0.0
		for rec_idx in range(item_surface_records.size()):
			var rec: Dictionary = item_surface_records[rec_idx]
			var rec_triangles: PackedInt32Array = rec.get("triangles", PackedInt32Array())
			var rec_tverts: PackedVector3Array = rec.get("transformed_vertices", PackedVector3Array())
			var rec_tnormals: PackedVector3Array = rec.get("transformed_normals", PackedVector3Array())
			var rec_has_normal: bool = bool(rec.get("has_normal", false))
			var winding := _evaluate_winding_policy(
				rec_triangles,
				rec_tverts,
				rec_tnormals,
				rec_has_normal,
				enforce_outward_winding,
				xf.basis.determinant(),
				item_center
			)
			rec["flip_winding"] = bool(winding.get("flip_winding", false))
			rec["invert_normals"] = bool(winding.get("invert_normals", false))
			rec["outward_score"] = float(winding.get("outward_score", 0.0))
			rec["normal_score"] = float(winding.get("normal_score", 0.0))
			rec["samples"] = int(winding.get("samples", 0))
			rec["confidence"] = float(winding.get("confidence", 0.0))
			var decision_weight: float = max(1.0, float(rec["samples"])) * max(0.0, float(rec["confidence"]))
			rec["decision_weight"] = decision_weight
			if decision_weight > 0.0:
				var orient_sign := -1.0 if bool(rec["flip_winding"]) else 1.0
				item_orientation_vote += orient_sign * decision_weight
			item_surface_records[rec_idx] = rec

		for rec_idx in range(item_surface_records.size()):
			var rec: Dictionary = item_surface_records[rec_idx]
			var confidence: float = float(rec.get("confidence", 0.0))
			if confidence >= 0.12:
				continue

			var neighbor_vote := 0.0
			var neighbor_weight := 0.0
			for other_idx in range(item_surface_records.size()):
				if other_idx == rec_idx:
					continue
				var other: Dictionary = item_surface_records[other_idx]
				var other_conf: float = float(other.get("confidence", 0.0))
				if other_conf < 0.08:
					continue
				var affinity: float = _surface_continuity_affinity(rec, other)
				if affinity <= 0.0:
					continue
				var vote_weight: float = max(1.0, float(other.get("samples", 1))) * other_conf * affinity
				var other_orient_sign := -1.0 if bool(other.get("flip_winding", false)) else 1.0
				neighbor_vote += other_orient_sign * vote_weight
				neighbor_weight += vote_weight

			var updated_by_context := false
			if neighbor_weight > 0.0 and abs(neighbor_vote) > (neighbor_weight * 0.25):
				rec["flip_winding"] = neighbor_vote < 0.0
				updated_by_context = true
			elif confidence < 0.04 and abs(item_orientation_vote) > 0.0001:
				rec["flip_winding"] = item_orientation_vote < 0.0
				updated_by_context = true

			if updated_by_context and bool(rec.get("has_normal", false)):
				var normal_score: float = float(rec.get("normal_score", 0.0))
				if abs(normal_score) > 0.000001:
					var final_normal_score := normal_score * (-1.0 if bool(rec.get("flip_winding", false)) else 1.0)
					rec["invert_normals"] = final_normal_score < 0.0
			item_surface_records[rec_idx] = rec

		for rec in item_surface_records:
			var surface_idx: int = int(rec.get("surface_idx", -1))
			if surface_idx < 0:
				continue
			var vertices: PackedVector3Array = rec.get("vertices", PackedVector3Array())
			var uvs: PackedVector2Array = rec.get("uvs", PackedVector2Array())
			var normals: PackedVector3Array = rec.get("normals", PackedVector3Array())
			var triangles: PackedInt32Array = rec.get("triangles", PackedInt32Array())
			var has_uv: bool = bool(rec.get("has_uv", false))
			var has_normal: bool = bool(rec.get("has_normal", false))
			var transformed_vertices: PackedVector3Array = rec.get("transformed_vertices", PackedVector3Array())
			var transformed_normals: PackedVector3Array = rec.get("transformed_normals", PackedVector3Array())
			var surface_material: Material = rec.get("surface_material", null) as Material
			var flip_winding: bool = bool(rec.get("flip_winding", false))
			var invert_normals: bool = bool(rec.get("invert_normals", false))
			var compacted: Dictionary = _compact_surface_data(
				triangles,
				vertices,
				transformed_vertices,
				uvs,
				normals,
				transformed_normals,
				has_uv,
				has_normal
			)
			triangles = compacted.get("triangles", PackedInt32Array())
			vertices = compacted.get("vertices", PackedVector3Array())
			transformed_vertices = compacted.get("transformed_vertices", PackedVector3Array())
			has_uv = bool(compacted.get("has_uv", false))
			uvs = compacted.get("uvs", PackedVector2Array())
			has_normal = bool(compacted.get("has_normal", false))
			normals = compacted.get("normals", PackedVector3Array())
			transformed_normals = compacted.get("transformed_normals", PackedVector3Array())
			if triangles.is_empty() or vertices.is_empty():
				continue

			var triangle_extra_flips := _compute_triangle_extra_flips(
				triangles,
				transformed_vertices,
				transformed_normals,
				has_normal,
				enforce_outward_winding,
				flip_winding,
				item_center
			)
			var has_triangle_extra_flips := false
			for flip_flag in triangle_extra_flips:
				if int(flip_flag) != 0:
					has_triangle_extra_flips = true
					break
			if has_triangle_extra_flips:
				# Per-triangle winding correction can intentionally mix winding within a surface.
				# Keep exported normals as-is to avoid global inversion fighting local fixes.
				invert_normals = false

			lines.append("g %s_s%d" % [mesh_name, surface_idx])

			var use_mtl_name := ""
			if surface_material != null:
				var register_result := _ensure_material_entry(
					surface_material,
					material_key_to_name,
					material_name_registry,
					mtl_lines,
					next_material_index
				)
				use_mtl_name = String(register_result.get("name", ""))
				next_material_index = int(register_result.get("next_material_index", next_material_index))
			if not use_mtl_name.is_empty() and use_mtl_name != current_usemtl:
				lines.append("usemtl " + use_mtl_name)
				current_usemtl = use_mtl_name

			for vw in transformed_vertices:
				lines.append("v %.6f %.6f %.6f" % [vw.x, vw.y, vw.z])

			if has_uv:
				for uv in uvs:
					var uv_y := 1.0 - uv.y if flip_v_texcoord else uv.y
					lines.append("vt %.6f %.6f" % [uv.x, uv_y])

			if has_normal:
				for nw_src in transformed_normals:
					var nw := -nw_src if invert_normals else nw_src
					lines.append("vn %.6f %.6f %.6f" % [nw.x, nw.y, nw.z])

			var tri_counter: int = 0
			for tri_idx in range(0, triangles.size(), 3):
				var a: int = triangles[tri_idx]
				var b: int = triangles[tri_idx + 1]
				var c: int = triangles[tri_idx + 2]
				if a < 0 or b < 0 or c < 0:
					tri_counter += 1
					continue
				if a >= vertices.size() or b >= vertices.size() or c >= vertices.size():
					tri_counter += 1
					continue
				var i0 := a
				var i1 := b
				var i2 := c
				var local_flip_winding := flip_winding
				if tri_counter < triangle_extra_flips.size() and int(triangle_extra_flips[tri_counter]) != 0:
					local_flip_winding = not local_flip_winding
				if local_flip_winding:
					var tmp := i1
					i1 = i2
					i2 = tmp
				lines.append("f %s %s %s" % [
					_face_token(i0, vertex_offset, uv_offset, normal_offset, has_uv, has_normal),
					_face_token(i1, vertex_offset, uv_offset, normal_offset, has_uv, has_normal),
					_face_token(i2, vertex_offset, uv_offset, normal_offset, has_uv, has_normal)
				])
				face_count += 1
				tri_counter += 1

			vertex_offset += vertices.size()
			if has_uv:
				uv_offset += uvs.size()
			if has_normal:
				normal_offset += normals.size()

	var mtl_text := ""
	if material_key_to_name.size() > 0:
		mtl_text = "\n".join(mtl_lines) + "\n"

	return {
		"text": "\n".join(lines) + "\n",
		"mtl_text": mtl_text,
		"materials": material_key_to_name.size(),
		"faces": face_count,
		"skipped_surfaces": skipped_surfaces,
		"total_surfaces": total_surfaces,
		"triangle_surfaces": triangle_surfaces,
		"unsupported_primitives": _format_primitive_summary(unsupported_by_primitive)
	}


func _compact_surface_data(
	triangles: PackedInt32Array,
	vertices: PackedVector3Array,
	transformed_vertices: PackedVector3Array,
	uvs: PackedVector2Array,
	normals: PackedVector3Array,
	transformed_normals: PackedVector3Array,
	has_uv: bool,
	has_normal: bool
) -> Dictionary:
	var remap := {}
	var ordered_indices := PackedInt32Array()
	var remapped_triangles := PackedInt32Array()
	for tri_idx in range(0, triangles.size(), 3):
		var a: int = triangles[tri_idx]
		var b: int = triangles[tri_idx + 1]
		var c: int = triangles[tri_idx + 2]
		if a < 0 or b < 0 or c < 0:
			continue
		if a >= vertices.size() or b >= vertices.size() or c >= vertices.size():
			continue
		var mapped_a: int = -1
		var mapped_b: int = -1
		var mapped_c: int = -1
		if remap.has(a):
			mapped_a = int(remap[a])
		else:
			mapped_a = ordered_indices.size()
			remap[a] = mapped_a
			ordered_indices.push_back(a)
		if remap.has(b):
			mapped_b = int(remap[b])
		else:
			mapped_b = ordered_indices.size()
			remap[b] = mapped_b
			ordered_indices.push_back(b)
		if remap.has(c):
			mapped_c = int(remap[c])
		else:
			mapped_c = ordered_indices.size()
			remap[c] = mapped_c
			ordered_indices.push_back(c)
		remapped_triangles.push_back(mapped_a)
		remapped_triangles.push_back(mapped_b)
		remapped_triangles.push_back(mapped_c)

	var compact_vertices := PackedVector3Array()
	compact_vertices.resize(ordered_indices.size())
	var compact_transformed_vertices := PackedVector3Array()
	compact_transformed_vertices.resize(ordered_indices.size())
	for new_idx in range(ordered_indices.size()):
		var old_idx: int = ordered_indices[new_idx]
		compact_vertices[new_idx] = vertices[old_idx]
		if old_idx < transformed_vertices.size():
			compact_transformed_vertices[new_idx] = transformed_vertices[old_idx]

	var compact_uvs := PackedVector2Array()
	var compact_has_uv: bool = has_uv and (uvs.size() == vertices.size())
	if compact_has_uv:
		compact_uvs.resize(ordered_indices.size())
		for new_idx in range(ordered_indices.size()):
			var old_idx: int = ordered_indices[new_idx]
			compact_uvs[new_idx] = uvs[old_idx]

	var compact_normals := PackedVector3Array()
	var compact_transformed_normals := PackedVector3Array()
	var compact_has_normal: bool = has_normal and (normals.size() == vertices.size()) and (transformed_normals.size() == vertices.size())
	if compact_has_normal:
		compact_normals.resize(ordered_indices.size())
		compact_transformed_normals.resize(ordered_indices.size())
		for new_idx in range(ordered_indices.size()):
			var old_idx: int = ordered_indices[new_idx]
			compact_normals[new_idx] = normals[old_idx]
			compact_transformed_normals[new_idx] = transformed_normals[old_idx]

	return {
		"triangles": remapped_triangles,
		"vertices": compact_vertices,
		"transformed_vertices": compact_transformed_vertices,
		"has_uv": compact_has_uv,
		"uvs": compact_uvs,
		"has_normal": compact_has_normal,
		"normals": compact_normals,
		"transformed_normals": compact_transformed_normals
	}


func _filter_surface_triangles(
	triangles: PackedInt32Array,
	verts: PackedVector3Array,
	manifold_only: bool,
	remove_enclosed_faces: bool
) -> Dictionary:
	if triangles.is_empty():
		return {"triangles": triangles}
	if (not manifold_only) and (not remove_enclosed_faces):
		return {"triangles": triangles}

	var topology: Dictionary = _build_triangle_components(triangles)
	var components: Array = topology.get("components", [])
	var edge_to_triangles: Dictionary = topology.get("edge_to_triangles", {})
	if components.is_empty():
		return {"triangles": triangles}

	var component_closed := PackedByteArray()
	component_closed.resize(components.size())
	var component_keep := PackedByteArray()
	component_keep.resize(components.size())
	for ci in range(components.size()):
		var component_triangles: Array = components[ci]
		var is_closed: bool = _component_is_closed_manifold(component_triangles, triangles, edge_to_triangles)
		component_closed[ci] = 1 if is_closed else 0
		component_keep[ci] = 1
		if manifold_only and not is_closed:
			component_keep[ci] = 0

	if remove_enclosed_faces:
		var component_aabbs: Array = []
		component_aabbs.resize(components.size())
		for ci in range(components.size()):
			component_aabbs[ci] = _compute_component_aabb(components[ci], triangles, verts)

		var closed_candidates: Array = []
		for ci in range(components.size()):
			if component_keep[ci] == 0:
				continue
			if component_closed[ci] == 0:
				continue
			closed_candidates.append(ci)

		for ci_any in closed_candidates:
			var ci: int = int(ci_any)
			if component_keep[ci] == 0:
				continue
			var sample_points: PackedVector3Array = _component_sample_points(components[ci], triangles, verts)
			if sample_points.is_empty():
				continue
			var inside_votes: int = 0
			var sample_count: int = 0
			for sample in sample_points:
				sample_count += 1
				var is_inside_other := false
				for cj_any in closed_candidates:
					var cj: int = int(cj_any)
					if cj == ci:
						continue
					if component_keep[cj] == 0:
						continue
					var outer_aabb: AABB = component_aabbs[cj]
					if not outer_aabb.grow(0.001).has_point(sample):
						continue
					if _point_inside_component(sample, components[cj], triangles, verts):
						is_inside_other = true
						break
				if is_inside_other:
					inside_votes += 1
			if sample_count > 0 and (float(inside_votes) / float(sample_count)) >= 0.6:
				component_keep[ci] = 0

	var filtered := PackedInt32Array()
	for ci in range(components.size()):
		if component_keep[ci] == 0:
			continue
		var component_triangles: Array = components[ci]
		for tri_id_any in component_triangles:
			var tri_id: int = int(tri_id_any)
			var base: int = tri_id * 3
			if base + 2 >= triangles.size():
				continue
			filtered.push_back(triangles[base])
			filtered.push_back(triangles[base + 1])
			filtered.push_back(triangles[base + 2])

	return {"triangles": filtered}


func _build_triangle_components(triangles: PackedInt32Array) -> Dictionary:
	var tri_count: int = int(triangles.size() / 3)
	if tri_count <= 0:
		return {
			"components": [],
			"edge_to_triangles": {}
		}

	var edge_to_triangles := {}
	var tri_neighbors: Array = []
	tri_neighbors.resize(tri_count)
	for tri_id in range(tri_count):
		tri_neighbors[tri_id] = []
		var base: int = tri_id * 3
		var a: int = triangles[base]
		var b: int = triangles[base + 1]
		var c: int = triangles[base + 2]
		_append_triangle_to_edge_map(edge_to_triangles, _edge_key(a, b), tri_id)
		_append_triangle_to_edge_map(edge_to_triangles, _edge_key(b, c), tri_id)
		_append_triangle_to_edge_map(edge_to_triangles, _edge_key(c, a), tri_id)

	for edge_key in edge_to_triangles.keys():
		var linked: Variant = edge_to_triangles[edge_key]
		if not (linked is Array):
			continue
		var tri_ids: Array = linked
		if tri_ids.size() < 2:
			continue
		for i in range(tri_ids.size()):
			var a_tri: int = int(tri_ids[i])
			for j in range(i + 1, tri_ids.size()):
				var b_tri: int = int(tri_ids[j])
				var neigh_a: Array = tri_neighbors[a_tri]
				if neigh_a.find(b_tri) == -1:
					neigh_a.append(b_tri)
					tri_neighbors[a_tri] = neigh_a
				var neigh_b: Array = tri_neighbors[b_tri]
				if neigh_b.find(a_tri) == -1:
					neigh_b.append(a_tri)
					tri_neighbors[b_tri] = neigh_b

	var visited := PackedByteArray()
	visited.resize(tri_count)
	var components: Array = []
	for start in range(tri_count):
		if visited[start] != 0:
			continue
		var stack: Array = [start]
		visited[start] = 1
		var component_triangles: Array = []
		while not stack.is_empty():
			var tri_id: int = int(stack.pop_back())
			component_triangles.append(tri_id)
			var neighbors: Array = tri_neighbors[tri_id]
			for nb_any in neighbors:
				var nb: int = int(nb_any)
				if nb < 0 or nb >= tri_count:
					continue
				if visited[nb] != 0:
					continue
				visited[nb] = 1
				stack.append(nb)
		components.append(component_triangles)

	return {
		"components": components,
		"edge_to_triangles": edge_to_triangles
	}


func _component_is_closed_manifold(component_triangles: Array, triangles: PackedInt32Array, edge_to_triangles: Dictionary) -> bool:
	var component_set := {}
	for tri_id_any in component_triangles:
		component_set[int(tri_id_any)] = true

	for tri_id_any in component_triangles:
		var tri_id: int = int(tri_id_any)
		var base: int = tri_id * 3
		if base + 2 >= triangles.size():
			return false
		var a: int = triangles[base]
		var b: int = triangles[base + 1]
		var c: int = triangles[base + 2]
		var edge_keys := PackedStringArray([
			_edge_key(a, b),
			_edge_key(b, c),
			_edge_key(c, a)
		])
		for edge_key in edge_keys:
			var linked: Variant = edge_to_triangles.get(edge_key, [])
			if not (linked is Array):
				return false
			var tri_ids: Array = linked
			if tri_ids.size() != 2:
				return false
			for linked_tri_any in tri_ids:
				var linked_tri: int = int(linked_tri_any)
				if not component_set.has(linked_tri):
					return false
	return true


func _compute_component_aabb(component_triangles: Array, triangles: PackedInt32Array, verts: PackedVector3Array) -> AABB:
	var has_point := false
	var aabb := AABB()
	for tri_id_any in component_triangles:
		var tri_id: int = int(tri_id_any)
		var base: int = tri_id * 3
		if base + 2 >= triangles.size():
			continue
		for offset in range(3):
			var vi: int = triangles[base + offset]
			if vi < 0 or vi >= verts.size():
				continue
			var point: Vector3 = verts[vi]
			if not has_point:
				aabb = AABB(point, Vector3.ZERO)
				has_point = true
			else:
				aabb = aabb.expand(point)
	return aabb


func _component_sample_points(component_triangles: Array, triangles: PackedInt32Array, verts: PackedVector3Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	if component_triangles.is_empty():
		return out
	var max_seed_tris: int = 4
	var step: int = max(1, int(ceil(float(component_triangles.size()) / float(max_seed_tris))))
	for tri_idx in range(0, component_triangles.size(), step):
		var tri_id: int = int(component_triangles[tri_idx])
		var base: int = tri_id * 3
		if base + 2 >= triangles.size():
			continue
		var ia: int = triangles[base]
		var ib: int = triangles[base + 1]
		var ic: int = triangles[base + 2]
		if ia < 0 or ib < 0 or ic < 0:
			continue
		if ia >= verts.size() or ib >= verts.size() or ic >= verts.size():
			continue
		var va: Vector3 = verts[ia]
		var vb: Vector3 = verts[ib]
		var vc: Vector3 = verts[ic]
		var center: Vector3 = (va + vb + vc) / 3.0
		var normal: Vector3 = (vb - va).cross(vc - va)
		var normal_len: float = normal.length()
		if normal_len > 0.000001:
			normal /= normal_len
			out.push_back(center + (normal * 0.0005))
			out.push_back(center - (normal * 0.0005))
		else:
			out.push_back(center)
		if out.size() >= 8:
			break
	return out


func _point_inside_component(
	point: Vector3,
	component_triangles: Array,
	triangles: PackedInt32Array,
	verts: PackedVector3Array
) -> bool:
	var directions := [
		Vector3(0.937, 0.276, 0.215).normalized(),
		Vector3(-0.421, 0.891, 0.171).normalized(),
		Vector3(0.312, -0.227, 0.922).normalized()
	]
	var inside_votes: int = 0
	for dir in directions:
		var intersections: int = _count_component_ray_intersections(point, dir, component_triangles, triangles, verts)
		if (intersections % 2) == 1:
			inside_votes += 1
	return inside_votes >= 2


func _count_component_ray_intersections(
	origin: Vector3,
	direction: Vector3,
	component_triangles: Array,
	triangles: PackedInt32Array,
	verts: PackedVector3Array
) -> int:
	var bins := {}
	for tri_id_any in component_triangles:
		var tri_id: int = int(tri_id_any)
		var base: int = tri_id * 3
		if base + 2 >= triangles.size():
			continue
		var ia: int = triangles[base]
		var ib: int = triangles[base + 1]
		var ic: int = triangles[base + 2]
		if ia < 0 or ib < 0 or ic < 0:
			continue
		if ia >= verts.size() or ib >= verts.size() or ic >= verts.size():
			continue
		var t_hit: float = _ray_intersects_triangle(origin, direction, verts[ia], verts[ib], verts[ic])
		if t_hit <= 0.00001:
			continue
		var bucket: int = int(round(t_hit * 100000.0))
		bins[bucket] = true
	return bins.size()


func _ray_intersects_triangle(origin: Vector3, direction: Vector3, v0: Vector3, v1: Vector3, v2: Vector3) -> float:
	var eps: float = 0.0000001
	var edge1: Vector3 = v1 - v0
	var edge2: Vector3 = v2 - v0
	var pvec: Vector3 = direction.cross(edge2)
	var det: float = edge1.dot(pvec)
	if abs(det) <= eps:
		return -1.0
	var inv_det: float = 1.0 / det
	var tvec: Vector3 = origin - v0
	var u: float = tvec.dot(pvec) * inv_det
	if u < 0.0 or u > 1.0:
		return -1.0
	var qvec: Vector3 = tvec.cross(edge1)
	var v: float = direction.dot(qvec) * inv_det
	if v < 0.0 or (u + v) > 1.0:
		return -1.0
	var t: float = edge2.dot(qvec) * inv_det
	if t <= eps:
		return -1.0
	return t


func _append_triangle_to_edge_map(edge_to_triangles: Dictionary, edge_key: String, tri_id: int) -> void:
	var linked: Array = []
	if edge_to_triangles.has(edge_key):
		var existing: Variant = edge_to_triangles[edge_key]
		if existing is Array:
			linked = existing
	linked.append(tri_id)
	edge_to_triangles[edge_key] = linked


func _edge_key(a: int, b: int) -> String:
	if a <= b:
		return "%d:%d" % [a, b]
	return "%d:%d" % [b, a]


func _build_triangle_indices(primitive: int, vertex_count: int, indices: PackedInt32Array) -> PackedInt32Array:
	var source := PackedInt32Array()
	if indices.is_empty():
		source.resize(vertex_count)
		for i in range(vertex_count):
			source[i] = i
	else:
		source = indices

	var out := PackedInt32Array()
	match primitive:
		Mesh.PRIMITIVE_TRIANGLES:
			var end := source.size() - (source.size() % 3)
			for i in range(0, end, 3):
				out.push_back(source[i])
				out.push_back(source[i + 1])
				out.push_back(source[i + 2])
		Mesh.PRIMITIVE_TRIANGLE_STRIP:
			for i in range(2, source.size()):
				var a := source[i - 2]
				var b := source[i - 1]
				var c := source[i]
				if a == b or b == c or a == c:
					continue
				if (i % 2) == 0:
					out.push_back(a)
					out.push_back(b)
					out.push_back(c)
				else:
					out.push_back(b)
					out.push_back(a)
					out.push_back(c)
		_:
			return PackedInt32Array()
	return out


func _evaluate_winding_policy(
	triangles: PackedInt32Array,
	verts: PackedVector3Array,
	normals: PackedVector3Array,
	has_normals: bool,
	enforce_outward_winding: bool,
	basis_determinant: float,
	center_override: Variant = null
) -> Dictionary:
	var scores := _compute_winding_scores(triangles, verts, normals, has_normals, center_override)
	var outward_score: float = float(scores.get("outward_score", 0.0))
	var normal_score: float = float(scores.get("normal_score", 0.0))
	var samples: int = int(scores.get("samples", 0))

	var flip_winding := false
	var invert_normals := false
	var confidence := 0.0

	if has_normals and samples > 0 and abs(normal_score) > 0.000001:
		flip_winding = normal_score < 0.0
		confidence = abs(normal_score) / float(samples)
	elif enforce_outward_winding and samples > 0 and abs(outward_score) > 0.000001:
		flip_winding = outward_score < 0.0
		confidence = abs(outward_score) / float(samples)
	else:
		flip_winding = basis_determinant < 0.0

	if has_normals and samples > 0 and abs(normal_score) > 0.000001:
		var final_normal_score := normal_score * (-1.0 if flip_winding else 1.0)
		invert_normals = final_normal_score < 0.0

	return {
		"flip_winding": flip_winding,
		"invert_normals": invert_normals,
		"outward_score": outward_score,
		"normal_score": normal_score,
		"samples": samples,
		"confidence": confidence
	}


func _compute_winding_scores(
	triangles: PackedInt32Array,
	verts: PackedVector3Array,
	normals: PackedVector3Array,
	has_normals: bool,
	center_override: Variant = null
) -> Dictionary:
	var center := _resolve_score_center(verts, center_override)

	var outward_score := 0.0
	var normal_score := 0.0
	var samples: int = 0

	for tri_idx in range(0, triangles.size(), 3):
		var a: int = triangles[tri_idx]
		var b: int = triangles[tri_idx + 1]
		var c: int = triangles[tri_idx + 2]
		if a < 0 or b < 0 or c < 0:
			continue
		if a >= verts.size() or b >= verts.size() or c >= verts.size():
			continue

		var va := verts[a]
		var vb := verts[b]
		var vc := verts[c]
		var fn := (vb - va).cross(vc - va)
		var fn_len := fn.length()
		if fn_len <= 0.000001:
			continue
		fn /= fn_len

		var tri_center := (va + vb + vc) / 3.0
		var to_out := tri_center - center
		var to_out_len := to_out.length()
		if to_out_len > 0.000001:
			outward_score += fn.dot(to_out / to_out_len)

		if has_normals and a < normals.size() and b < normals.size() and c < normals.size():
			var vn := normals[a] + normals[b] + normals[c]
			var vn_len := vn.length()
			if vn_len > 0.000001:
				normal_score += fn.dot(vn / vn_len)

		samples += 1

	return {
		"outward_score": outward_score,
		"normal_score": normal_score,
		"samples": samples
	}


func _compute_triangle_extra_flips(
	triangles: PackedInt32Array,
	verts: PackedVector3Array,
	normals: PackedVector3Array,
	has_normals: bool,
	enforce_outward_winding: bool,
	base_flip_winding: bool,
	center_override: Variant = null
) -> PackedByteArray:
	var tri_count: int = int(triangles.size() / 3)
	var out := PackedByteArray()
	out.resize(tri_count)
	if tri_count <= 0:
		return out

	var center := _resolve_score_center(verts, center_override)

	var tri_counter: int = 0
	for tri_idx in range(0, triangles.size(), 3):
		var a: int = triangles[tri_idx]
		var b: int = triangles[tri_idx + 1]
		var c: int = triangles[tri_idx + 2]
		if a < 0 or b < 0 or c < 0:
			tri_counter += 1
			continue
		if a >= verts.size() or b >= verts.size() or c >= verts.size():
			tri_counter += 1
			continue

		var i0 := a
		var i1 := b
		var i2 := c
		if base_flip_winding:
			var swap_idx := i1
			i1 = i2
			i2 = swap_idx

		var va := verts[i0]
		var vb := verts[i1]
		var vc := verts[i2]
		var fn := (vb - va).cross(vc - va)
		var fn_len := fn.length()
		if fn_len <= 0.000001:
			tri_counter += 1
			continue
		fn /= fn_len

		var score := 0.0
		var score_weight := 0.0

		if has_normals and i0 < normals.size() and i1 < normals.size() and i2 < normals.size():
			var vn := normals[i0] + normals[i1] + normals[i2]
			var vn_len := vn.length()
			if vn_len > 0.000001:
				score += fn.dot(vn / vn_len) * 2.0
				score_weight += 2.0

		if enforce_outward_winding:
			var tri_center := (va + vb + vc) / 3.0
			var to_out := tri_center - center
			var to_out_len := to_out.length()
			if to_out_len > 0.000001:
				score += fn.dot(to_out / to_out_len)
				score_weight += 1.0

		if score_weight > 0.0 and score < -0.00001:
			out[tri_counter] = 1

		tri_counter += 1

	return out


func _resolve_score_center(verts: PackedVector3Array, center_override: Variant = null) -> Vector3:
	if center_override is Vector3:
		return center_override
	var center := Vector3.ZERO
	if verts.size() > 0:
		for v in verts:
			center += v
		center /= float(verts.size())
	return center


func _compute_surface_bounds(verts: PackedVector3Array) -> Dictionary:
	if verts.is_empty():
		return {
			"aabb": AABB(),
			"center": Vector3.ZERO,
			"radius": 0.0
		}
	var aabb := AABB(verts[0], Vector3.ZERO)
	for i in range(1, verts.size()):
		aabb = aabb.expand(verts[i])
	var center := aabb.position + (aabb.size * 0.5)
	var radius := 0.0
	for v in verts:
		radius = max(radius, center.distance_to(v))
	return {
		"aabb": aabb,
		"center": center,
		"radius": radius
	}


func _surface_continuity_affinity(a: Dictionary, b: Dictionary) -> float:
	var a_aabb: AABB = a.get("aabb", AABB())
	var b_aabb: AABB = b.get("aabb", AABB())
	var diag_a: float = a_aabb.size.length()
	var diag_b: float = b_aabb.size.length()
	var grow: float = max(0.01, max(diag_a, diag_b) * 0.02)
	if not a_aabb.grow(grow).intersects(b_aabb.grow(grow)):
		return 0.0

	var center_a: Vector3 = a.get("center", Vector3.ZERO)
	var center_b: Vector3 = b.get("center", Vector3.ZERO)
	var radius_a: float = float(a.get("radius", 0.0))
	var radius_b: float = float(b.get("radius", 0.0))
	var distance: float = center_a.distance_to(center_b)
	var reach: float = max(0.01, radius_a + radius_b)
	var proximity: float = 1.0 - clamp(distance / (reach * 2.0), 0.0, 1.0)
	return clamp(0.2 + (0.8 * proximity), 0.0, 1.0)


func _get_surface_primitive_type(mesh: Mesh, surface_idx: int) -> int:
	# Some primitive meshes in this Godot build do not expose surface_get_primitive_type.
	if mesh.has_method("surface_get_primitive_type"):
		return int(mesh.call("surface_get_primitive_type", surface_idx))
	# Primitive mesh resources are triangle-based for export purposes.
	return Mesh.PRIMITIVE_TRIANGLES


func _face_token(local_index: int, vertex_offset: int, uv_offset: int, normal_offset: int, has_uv: bool, has_normal: bool) -> String:
	var v_idx := vertex_offset + local_index + 1
	if has_uv and has_normal:
		var t_idx := uv_offset + local_index + 1
		var n_idx := normal_offset + local_index + 1
		return "%d/%d/%d" % [v_idx, t_idx, n_idx]
	if has_uv:
		var t_only := uv_offset + local_index + 1
		return "%d/%d" % [v_idx, t_only]
	if has_normal:
		var n_only := normal_offset + local_index + 1
		return "%d//%d" % [v_idx, n_only]
	return str(v_idx)


func _sanitize_obj_name(value: String) -> String:
	var clean := value.strip_edges()
	if clean.is_empty():
		return "mesh"
	return clean.replace(" ", "_")


func _array_slot(arrays: Array, idx: int) -> Variant:
	if idx >= 0 and idx < arrays.size():
		return arrays[idx]
	return null


func _as_packed_vector3_array(v: Variant) -> PackedVector3Array:
	if v is PackedVector3Array:
		return v
	return PackedVector3Array()


func _as_packed_vector2_array(v: Variant) -> PackedVector2Array:
	if v is PackedVector2Array:
		return v
	return PackedVector2Array()


func _as_packed_int32_array(v: Variant) -> PackedInt32Array:
	if v is PackedInt32Array:
		return v
	var out := PackedInt32Array()
	if v is PackedInt64Array:
		for it in v:
			out.push_back(int(it))
		return out
	if v is Array:
		for it in v:
			out.push_back(int(it))
	return out


func _format_primitive_summary(counts: Dictionary) -> String:
	if counts.is_empty():
		return ""
	var keys := counts.keys()
	keys.sort()
	var parts := PackedStringArray()
	for key in keys:
		parts.append("%s:%s" % [str(key), str(counts[key])])
	return ",".join(parts)


func _resolve_surface_material(item: Dictionary, mesh: Mesh, surface_idx: int) -> Material:
	var material_override: Variant = item.get("material_override", null)
	if material_override is Material:
		return material_override as Material

	var surface_overrides: Variant = item.get("surface_overrides", [])
	if surface_overrides is Array:
		var overrides: Array = surface_overrides
		if surface_idx >= 0 and surface_idx < overrides.size():
			if overrides[surface_idx] is Material:
				return overrides[surface_idx] as Material

	var surface_material := mesh.surface_get_material(surface_idx)
	if surface_material is Material:
		return surface_material as Material
	return null


func _ensure_material_entry(
	material: Material,
	material_key_to_name: Dictionary,
	material_name_registry: Dictionary,
	mtl_lines: Array,
	next_material_index: int
) -> Dictionary:
	var key := _material_key(material)
	if material_key_to_name.has(key):
		return {
			"name": String(material_key_to_name[key]),
			"next_material_index": next_material_index
		}

	var proposed := _sanitize_obj_name(material.resource_name)
	if proposed.is_empty():
		proposed = "mat_%d" % next_material_index
		next_material_index += 1
	while material_name_registry.has(proposed):
		proposed = proposed + "_%d" % next_material_index
		next_material_index += 1

	material_key_to_name[key] = proposed
	material_name_registry[proposed] = true

	var entry_lines := _build_mtl_entry_lines(material, proposed)
	for ln in entry_lines:
		mtl_lines.append(ln)
	mtl_lines.append("")

	return {
		"name": proposed,
		"next_material_index": next_material_index
	}


func _material_key(material: Material) -> String:
	if material == null:
		return ""
	if not material.resource_path.is_empty():
		return "path:" + material.resource_path
	return "id:" + str(material.get_instance_id())


func _build_mtl_entry_lines(material: Material, mtl_name: String) -> Array:
	var out: Array = []
	out.append("newmtl " + mtl_name)
	out.append("Ka 1.000000 1.000000 1.000000")
	out.append("Kd 1.000000 1.000000 1.000000")
	out.append("Ks 0.000000 0.000000 0.000000")
	out.append("d 1.000000")
	out.append("illum 2")

	if material is BaseMaterial3D:
		var bm := material as BaseMaterial3D
		var c: Color = bm.albedo_color
		out.append("Ka %.6f %.6f %.6f" % [c.r, c.g, c.b])
		out.append("Kd %.6f %.6f %.6f" % [c.r, c.g, c.b])
		out.append("d %.6f" % c.a)
		var ns: float = clamp(1000.0 * (1.0 - bm.roughness), 0.0, 1000.0)
		out.append("Ns %.6f" % ns)

		var albedo_tex: Texture2D = bm.get_texture(BaseMaterial3D.TEXTURE_ALBEDO)
		var normal_tex: Texture2D = bm.get_texture(BaseMaterial3D.TEXTURE_NORMAL)
		var emission_tex: Texture2D = bm.get_texture(BaseMaterial3D.TEXTURE_EMISSION)

		var albedo_path := _texture_to_abs_path(albedo_tex)
		var normal_path := _texture_to_abs_path(normal_tex)
		var emission_path := _texture_to_abs_path(emission_tex)
		if not albedo_path.is_empty():
			out.append("map_Kd " + _obj_path_escape(albedo_path))
		if not normal_path.is_empty():
			out.append("map_Bump " + _obj_path_escape(normal_path))
		if not emission_path.is_empty():
			out.append("map_Ke " + _obj_path_escape(emission_path))
		return out

	if material is ShaderMaterial:
		var sm := material as ShaderMaterial
		var tex_path := _shader_material_diffuse_texture_path(sm)
		if not tex_path.is_empty():
			out.append("map_Kd " + _obj_path_escape(tex_path))

	return out


func _shader_material_diffuse_texture_path(sm: ShaderMaterial) -> String:
	if sm == null:
		return ""
	var shader := sm.shader
	if shader == null:
		return ""
	if not shader.has_method("get_shader_uniform_list"):
		return ""

	var uniforms_any: Variant = shader.call("get_shader_uniform_list")
	if not (uniforms_any is Array):
		return ""

	var preferred: Array = []
	var fallback: Array = []
	var uniforms: Array = uniforms_any
	for u in uniforms:
		if not (u is Dictionary):
			continue
		var ud: Dictionary = u
		var uname := String(ud.get("name", ""))
		if uname.is_empty():
			continue
		var v := sm.get_shader_parameter(uname)
		if v is Texture2D:
			var p := _texture_to_abs_path(v as Texture2D)
			if p.is_empty():
				continue
			var lname := uname.to_lower()
			if lname.contains("albedo") or lname.contains("diffuse") or lname.contains("base") or lname.contains("color") or lname.contains("main"):
				preferred.append(p)
			else:
				fallback.append(p)
	if preferred.size() > 0:
		return preferred[0]
	if fallback.size() > 0:
		return fallback[0]
	return ""


func _texture_to_abs_path(tex: Texture2D) -> String:
	if tex == null:
		return ""
	var t: Texture2D = tex
	if tex is AtlasTexture:
		var atlas := (tex as AtlasTexture).atlas
		if atlas is Texture2D:
			t = atlas as Texture2D
	var rp := t.resource_path
	if rp.is_empty():
		return ""
	return _to_abs_path(rp)


func _to_abs_path(path: String) -> String:
	var p := path
	if p.begins_with("res://") or p.begins_with("user://"):
		p = ProjectSettings.globalize_path(p)
	return p.replace("\\", "/")


func _obj_path_escape(path: String) -> String:
	return path.replace("\\", "/").replace(" ", "\\ ")


func _ensure_output_dir(path: String) -> void:
	var dir_path := path.get_base_dir()
	if dir_path.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
