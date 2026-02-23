@tool
extends EditorPlugin

const MENU_LABEL := "Densetsu/Export Selected Scene Geometry to OBJ"
const EXPORTER_SCRIPT := preload("res://addons/densetsu_geometry_obj_export/scene_geometry_obj_exporter.gd")

var _file_dialog: FileDialog
var _pending_roots: Array = []
var _exporter: RefCounted

# Prioritized defaults:
# - nested MeshInstance3D
# - static mesh export pass with CSG combines enabled
@export_group("Source Geometry")
## Export regular MeshInstance3D nodes under the selected roots (including nested children).
## Disable this only if you want to export CSG/MultiMesh data without regular mesh nodes.
@export var include_mesh_instances: bool = true
## Export baked CSGShape3D result from selected CSG roots (or top-level CSG roots under selection).
## Keeps CSG authoring workflows usable for OBJ export without manual mesh conversion.
@export var include_csg: bool = true
## Expand MultiMesh instances to regular triangles in OBJ.
## Useful for dense repeated props; can generate very large OBJ files.
@export var include_multimesh: bool = false

@export_group("Transform And Coordinates")
## Bake global transforms into exported vertex positions.
## When enabled, OBJ matches in-scene placement; when disabled, local mesh coordinates are exported.
@export var apply_world_transform: bool = true
## Flip UV V coordinate for DCC-friendly OBJ texture orientation.
## Disable if your target tool expects Godot-style UV V direction.
@export var flip_v_texcoord: bool = true

@export_group("Normals And Winding")
## Attempt to correct triangle winding so faces point outward.
## Uses normals first, then geometry/continuity heuristics; best-effort for open/non-manifold meshes.
@export var enforce_outward_winding: bool = true

@export_group("Topology Cleanup")
## Keep only closed 2-manifold triangle shells.
## Drops open/non-manifold triangle regions from export.
@export var manifold_only: bool = true
## Remove manifold shells that are fully enclosed by another manifold shell.
## Useful for stripping interior geometry from boolean/combined scene meshes.
@export var remove_enclosed_faces: bool = true


func _enter_tree() -> void:
	_exporter = EXPORTER_SCRIPT.new()
	add_tool_menu_item(MENU_LABEL, _on_menu_export_selected)
	_build_file_dialog()


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_LABEL)
	if is_instance_valid(_file_dialog):
		_file_dialog.queue_free()
	_file_dialog = null
	_pending_roots.clear()
	_exporter = null


func _build_file_dialog() -> void:
	_file_dialog = FileDialog.new()
	_file_dialog.title = "Export Selected Geometry to OBJ"
	_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.filters = PackedStringArray(["*.obj ; Wavefront OBJ"])
	_file_dialog.current_dir = "res://temp"
	_file_dialog.current_file = "scene_geometry_export.obj"
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)


func _on_menu_export_selected() -> void:
	_pending_roots = _get_selected_scene_nodes()
	if _pending_roots.is_empty():
		push_warning("Geometry OBJ Export: Select one or more Node3D roots in the Scene tree first.")
		return
	_file_dialog.popup_centered_ratio(0.5)


func _on_file_selected(path: String) -> void:
	if _exporter == null:
		push_error("Geometry OBJ Export: Exporter not initialized.")
		return
	if _pending_roots.is_empty():
		push_warning("Geometry OBJ Export: No pending selection to export.")
		return

	var options := {
		"include_mesh_instances": include_mesh_instances,
		"include_csg": include_csg,
		"include_multimesh": include_multimesh,
		"apply_world_transform": apply_world_transform,
		"flip_v_texcoord": flip_v_texcoord,
		"enforce_outward_winding": enforce_outward_winding,
		"manifold_only": manifold_only,
		"remove_enclosed_faces": remove_enclosed_faces
	}
	var result: Dictionary = _exporter.export_nodes_to_obj(_pending_roots, path, options)
	_pending_roots.clear()

	if bool(result.get("ok", false)):
		print(
			"Geometry OBJ Export: OK path=%s items=%d faces=%d skipped_surfaces=%d materials=%d mtl=%s"
			% [
				String(result.get("path", path)),
				int(result.get("items", 0)),
				int(result.get("faces", 0)),
				int(result.get("skipped_surfaces", 0)),
				int(result.get("materials", 0)),
				String(result.get("mtl_path", ""))
			]
		)
	else:
		push_error("Geometry OBJ Export: " + String(result.get("error", "Export failed.")))


func _get_selected_scene_nodes() -> Array:
	var out: Array = []
	var iface := get_editor_interface()
	if iface == null:
		return out
	var selection := iface.get_selection()
	if selection == null:
		return out
	var selected_nodes: Array = selection.get_selected_nodes()
	var selected_ids := {}
	for n in selected_nodes:
		if n is Node:
			selected_ids[(n as Node).get_instance_id()] = true
	for node in selected_nodes:
		if not (node is Node3D):
			continue
		var current := node as Node
		var is_nested_under_selected := false
		var parent := current.get_parent()
		while parent != null:
			if selected_ids.has(parent.get_instance_id()):
				is_nested_under_selected = true
				break
			parent = parent.get_parent()
		if not is_nested_under_selected:
			out.append(node)
	return out
