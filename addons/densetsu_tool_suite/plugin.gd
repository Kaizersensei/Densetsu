@tool
extends EditorPlugin

const STATIC_PACK_PLUGIN_SCRIPT: String = "res://addons/densetsu_tool_suite/helpers/static_pack_helper.gd"
const ARRAY_EXTRACT_PLUGIN_SCRIPT: String = "res://addons/densetsu_tool_suite/helpers/arraymesh_extract_helper.gd"
const TEXTURE_RESIZE_PLUGIN_SCRIPT: String = "res://addons/densetsu_tool_suite/helpers/texture_resize_helper.gd"
const PIVOT_REASSIGN_HELPER_SCRIPT: String = "res://addons/densetsu_tool_suite/helpers/pivot_reassign_helper.gd"
const MESH_OBJ_HELPER_SCRIPT: String = "res://addons/densetsu_tool_suite/helpers/mesh_obj_helper.gd"
const MENU_NEW_DENSETSU_MAP: String = "Densetsu/--- Scene ---/New Densetsu Map"
const MENU_CONVERT_MESH_RES_TO_OBJ: String = "Densetsu/Convert Mesh TRES_RES to OBJ (Selected)"
const MENU_REPLACE_MESH_REFS_WITH_OBJ: String = "Densetsu/Replace Scene TRES_RES Mesh Refs With Selected OBJ"
const MENU_REPLACE_MESH_REFS_WITH_OBJ_PROJECT: String = "Densetsu/Replace TRES_RES Mesh Refs With OBJ (Project-Wide)"
const MENU_FORCE_THUMBNAIL_REFRESH: String = "Densetsu/--- Maintenance ---/Force Thumbnail Refresh"
const MENU_FORCE_THUMBNAIL_REFRESH_SELECTED: String = "Densetsu/--- Maintenance ---/Force Thumbnail Refresh (Selected)"

const PIVOT_MODE_CENTER_MASS := 0
const PIVOT_MODE_CENTER_BOTTOM := 1

var _ctx_plugin: EditorContextMenuPlugin
var _static_pack_helper: Object
var _array_extract_helper: Object
var _texture_resize_helper: Object
var _pivot_reassign_helper: Object
var _mesh_obj_helper: Object
var _new_map_dialog: FileDialog
var _mesh_ref_replace_dialog: ConfirmationDialog
var _mesh_ref_replace_scope_current_folder_check: CheckBox
var _mesh_ref_replace_dry_run_check: CheckBox
var _mesh_ref_replace_same_folder_check: CheckBox
var _mesh_ref_replace_allow_fallback_check: CheckBox
var _mesh_ref_replace_report_dialog: AcceptDialog
var _mesh_ref_replace_report_text: TextEdit

@export_group("Scene Tools")
## Template scene used as source when creating a new editable Densetsu map.
@export_file("*.tscn") var new_map_template_scene: String = "res://engine3d/maps/templates/densetsu_map_template.tscn"
## Default save directory shown when creating a new map scene.
@export_dir var new_map_output_dir: String = "res://engine3d/maps"
## Default file name suggested in the save dialog.
@export var new_map_default_file: String = "new_densetsu_map.tscn"


class _DensetsuSuiteContextMenuPlugin:
	extends EditorContextMenuPlugin
	var _owner: EditorPlugin

	func _init(owner: EditorPlugin) -> void:
		_owner = owner

	func _popup_menu(paths: PackedStringArray) -> void:
		if paths.is_empty():
			return
		add_context_menu_item("Densetsu: Pack to Static Mesh", Callable(_owner, "_on_ctx_static_pack"))
		add_context_menu_item("Densetsu: Extract ArrayMeshes (Per File)", Callable(_owner, "_on_ctx_extract_mesh_per_file"))
		add_context_menu_item("Densetsu: Extract ArrayMeshes (Common)", Callable(_owner, "_on_ctx_extract_mesh_common"))
		add_context_menu_item("Densetsu: Extract Material Meshes (Per File)", Callable(_owner, "_on_ctx_extract_material_per_file"))
		add_context_menu_item("Densetsu: Extract Material Meshes (Common)", Callable(_owner, "_on_ctx_extract_material_common"))
		add_context_menu_item("Densetsu: Extract Combined Mesh (Per File)", Callable(_owner, "_on_ctx_extract_combined_per_file"))
		add_context_menu_item("Densetsu: Extract Combined Mesh (Common)", Callable(_owner, "_on_ctx_extract_combined_common"))
		add_context_menu_item("Densetsu: Resize Textures POT (Overwrite)", Callable(_owner, "_on_ctx_resize_overwrite"))
		add_context_menu_item("Densetsu: Resize Textures POT (Copy)", Callable(_owner, "_on_ctx_resize_copy"))
		add_context_menu_item("Densetsu: Reassign Pivot (Center Mass)", Callable(_owner, "_on_ctx_pivot_center_mass"))
		add_context_menu_item("Densetsu: Reassign Pivot (Center Bottom)", Callable(_owner, "_on_ctx_pivot_center_bottom"))
		add_context_menu_item("Densetsu: Convert Mesh TRES/RES to OBJ", Callable(_owner, "_on_ctx_convert_mesh_res_to_obj"))
		add_context_menu_item("Densetsu: Replace Scene TRES/RES Refs with Selected OBJ", Callable(_owner, "_on_ctx_replace_mesh_refs_with_obj"))
		add_context_menu_item("Densetsu: Force Thumbnail Refresh (Selected)", Callable(_owner, "_on_ctx_force_thumbnail_refresh_selected"))


func _enter_tree() -> void:
	_static_pack_helper = _instantiate_plugin(STATIC_PACK_PLUGIN_SCRIPT)
	_array_extract_helper = _instantiate_plugin(ARRAY_EXTRACT_PLUGIN_SCRIPT)
	_texture_resize_helper = _instantiate_plugin(TEXTURE_RESIZE_PLUGIN_SCRIPT)
	_pivot_reassign_helper = _instantiate_plugin(PIVOT_REASSIGN_HELPER_SCRIPT)
	_mesh_obj_helper = _instantiate_plugin(MESH_OBJ_HELPER_SCRIPT)
	_build_new_map_dialog()
	_build_mesh_ref_replace_dialog()
	_build_mesh_ref_replace_report_dialog()

	add_tool_menu_item("Densetsu/Pack to Static Mesh (Selected)", _on_tool_static_pack)
	add_tool_menu_item("Densetsu/Extract ArrayMeshes (Per File)", _on_tool_extract_mesh_per_file)
	add_tool_menu_item("Densetsu/Extract ArrayMeshes (Common)", _on_tool_extract_mesh_common)
	add_tool_menu_item("Densetsu/Extract Material Meshes (Per File)", _on_tool_extract_material_per_file)
	add_tool_menu_item("Densetsu/Extract Material Meshes (Common)", _on_tool_extract_material_common)
	add_tool_menu_item("Densetsu/Extract Combined Mesh (Per File)", _on_tool_extract_combined_per_file)
	add_tool_menu_item("Densetsu/Extract Combined Mesh (Common)", _on_tool_extract_combined_common)
	add_tool_menu_item("Densetsu/Resize Textures POT (Overwrite)", _on_tool_resize_overwrite)
	add_tool_menu_item("Densetsu/Resize Textures POT (Copy)", _on_tool_resize_copy)
	add_tool_menu_item("Densetsu/Reassign Pivot (Center Mass)", _on_tool_pivot_center_mass)
	add_tool_menu_item("Densetsu/Reassign Pivot (Center Bottom)", _on_tool_pivot_center_bottom)
	add_tool_menu_item(MENU_CONVERT_MESH_RES_TO_OBJ, _on_tool_convert_mesh_res_to_obj)
	add_tool_menu_item(MENU_REPLACE_MESH_REFS_WITH_OBJ, _on_tool_replace_mesh_refs_with_obj)
	add_tool_menu_item(MENU_REPLACE_MESH_REFS_WITH_OBJ_PROJECT, _on_tool_replace_mesh_refs_with_obj_project)
	add_tool_menu_item(MENU_FORCE_THUMBNAIL_REFRESH, _on_tool_force_thumbnail_refresh)
	add_tool_menu_item(MENU_FORCE_THUMBNAIL_REFRESH_SELECTED, _on_tool_force_thumbnail_refresh_selected)
	add_tool_menu_item(MENU_NEW_DENSETSU_MAP, _on_tool_new_densetsu_map)

	_ctx_plugin = _DensetsuSuiteContextMenuPlugin.new(self)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _ctx_plugin)


func _exit_tree() -> void:
	remove_tool_menu_item("Densetsu/Pack to Static Mesh (Selected)")
	remove_tool_menu_item("Densetsu/Extract ArrayMeshes (Per File)")
	remove_tool_menu_item("Densetsu/Extract ArrayMeshes (Common)")
	remove_tool_menu_item("Densetsu/Extract Material Meshes (Per File)")
	remove_tool_menu_item("Densetsu/Extract Material Meshes (Common)")
	remove_tool_menu_item("Densetsu/Extract Combined Mesh (Per File)")
	remove_tool_menu_item("Densetsu/Extract Combined Mesh (Common)")
	remove_tool_menu_item("Densetsu/Resize Textures POT (Overwrite)")
	remove_tool_menu_item("Densetsu/Resize Textures POT (Copy)")
	remove_tool_menu_item("Densetsu/Reassign Pivot (Center Mass)")
	remove_tool_menu_item("Densetsu/Reassign Pivot (Center Bottom)")
	remove_tool_menu_item(MENU_CONVERT_MESH_RES_TO_OBJ)
	remove_tool_menu_item(MENU_REPLACE_MESH_REFS_WITH_OBJ)
	remove_tool_menu_item(MENU_REPLACE_MESH_REFS_WITH_OBJ_PROJECT)
	remove_tool_menu_item(MENU_FORCE_THUMBNAIL_REFRESH)
	remove_tool_menu_item(MENU_FORCE_THUMBNAIL_REFRESH_SELECTED)
	remove_tool_menu_item(MENU_NEW_DENSETSU_MAP)
	if _ctx_plugin:
		remove_context_menu_plugin(_ctx_plugin)
		_ctx_plugin = null
	if is_instance_valid(_new_map_dialog):
		_new_map_dialog.queue_free()
	_new_map_dialog = null
	if is_instance_valid(_mesh_ref_replace_dialog):
		_mesh_ref_replace_dialog.queue_free()
	_mesh_ref_replace_dialog = null
	if is_instance_valid(_mesh_ref_replace_report_dialog):
		_mesh_ref_replace_report_dialog.queue_free()
	_mesh_ref_replace_report_dialog = null
	_mesh_ref_replace_report_text = null


func _instantiate_plugin(path: String) -> Object:
	var script_res: Script = load(path)
	if script_res == null:
		push_warning("Densetsu Suite: failed to load helper plugin script: " + path)
		return null
	if script_res.has_method("can_instantiate") and not script_res.can_instantiate():
		push_warning("Densetsu Suite: helper script is not instantiable: " + path)
		return null
	var instance: Object = script_res.new()
	if instance == null:
		push_warning("Densetsu Suite: failed to instantiate helper plugin script: " + path)
	return instance


func _build_new_map_dialog() -> void:
	if is_instance_valid(_new_map_dialog):
		_new_map_dialog.queue_free()
	_new_map_dialog = FileDialog.new()
	_new_map_dialog.title = "Create New Densetsu Map"
	_new_map_dialog.access = FileDialog.ACCESS_RESOURCES
	_new_map_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_new_map_dialog.filters = PackedStringArray(["*.tscn ; Godot Scene"])
	_new_map_dialog.file_selected.connect(_on_new_map_file_selected)
	add_child(_new_map_dialog)


func _build_mesh_ref_replace_dialog() -> void:
	if is_instance_valid(_mesh_ref_replace_dialog):
		_mesh_ref_replace_dialog.queue_free()

	_mesh_ref_replace_dialog = ConfirmationDialog.new()
	_mesh_ref_replace_dialog.title = "Replace Mesh References With OBJ"
	_mesh_ref_replace_dialog.ok_button_text = "Run"
	_mesh_ref_replace_dialog.confirmed.connect(_on_mesh_ref_replace_dialog_confirmed)
	add_child(_mesh_ref_replace_dialog)

	var root_box: VBoxContainer = VBoxContainer.new()
	root_box.custom_minimum_size = Vector2(640, 0)
	_mesh_ref_replace_dialog.add_child(root_box)

	var intro: Label = Label.new()
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.text = "Project-wide replacement with conflict controls. Recommended flow: keep Dry Run ON first, check report, then apply."
	root_box.add_child(intro)

	_mesh_ref_replace_scope_current_folder_check = CheckBox.new()
	_mesh_ref_replace_scope_current_folder_check.text = "Use Current Filesystem Folder as Candidate Scope"
	_mesh_ref_replace_scope_current_folder_check.button_pressed = true
	root_box.add_child(_mesh_ref_replace_scope_current_folder_check)

	_mesh_ref_replace_dry_run_check = CheckBox.new()
	_mesh_ref_replace_dry_run_check.text = "Dry Run (Preview Only)"
	_mesh_ref_replace_dry_run_check.button_pressed = true
	root_box.add_child(_mesh_ref_replace_dry_run_check)

	_mesh_ref_replace_same_folder_check = CheckBox.new()
	_mesh_ref_replace_same_folder_check.text = "Same Folder OBJ Only (Safe)"
	_mesh_ref_replace_same_folder_check.button_pressed = true
	_mesh_ref_replace_same_folder_check.toggled.connect(_on_mesh_ref_same_folder_toggled)
	root_box.add_child(_mesh_ref_replace_same_folder_check)

	_mesh_ref_replace_allow_fallback_check = CheckBox.new()
	_mesh_ref_replace_allow_fallback_check.text = "Allow Basename Fallback Across Scope (Use with care)"
	_mesh_ref_replace_allow_fallback_check.button_pressed = false
	_mesh_ref_replace_allow_fallback_check.disabled = true
	root_box.add_child(_mesh_ref_replace_allow_fallback_check)

	var note: Label = Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "Target scan is project-wide. Candidate scope limits which OBJ/TRES assets are considered. Missing same-folder OBJ is skipped. Ambiguous fallback is skipped and reported."
	root_box.add_child(note)


func _build_mesh_ref_replace_report_dialog() -> void:
	if is_instance_valid(_mesh_ref_replace_report_dialog):
		_mesh_ref_replace_report_dialog.queue_free()

	_mesh_ref_replace_report_dialog = AcceptDialog.new()
	_mesh_ref_replace_report_dialog.title = "OBJ Replacement Report"
	_mesh_ref_replace_report_dialog.ok_button_text = "Close"
	_mesh_ref_replace_report_dialog.min_size = Vector2i(420, 280)
	add_child(_mesh_ref_replace_report_dialog)

	_mesh_ref_replace_report_text = TextEdit.new()
	_mesh_ref_replace_report_text.custom_minimum_size = Vector2(360, 220)
	_mesh_ref_replace_report_text.editable = false
	_mesh_ref_replace_report_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mesh_ref_replace_report_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_mesh_ref_replace_report_dialog.add_child(_mesh_ref_replace_report_text)


func _on_mesh_ref_same_folder_toggled(pressed: bool) -> void:
	if _mesh_ref_replace_allow_fallback_check == null:
		return
	_mesh_ref_replace_allow_fallback_check.disabled = pressed
	if pressed:
		_mesh_ref_replace_allow_fallback_check.button_pressed = false


func _open_mesh_ref_replace_dialog() -> void:
	if not is_instance_valid(_mesh_ref_replace_dialog):
		_build_mesh_ref_replace_dialog()
	if not is_instance_valid(_mesh_ref_replace_dialog):
		push_warning("Densetsu Suite: Unable to open OBJ replacement dialog.")
		return
	_popup_window_fit_screen(_mesh_ref_replace_dialog, Vector2i(760, 180), Vector2i(560, 150))


func _on_mesh_ref_replace_dialog_confirmed() -> void:
	var dry_run: bool = true
	var same_folder_only: bool = true
	var allow_fallback: bool = false
	var current_folder_only: bool = true
	if _mesh_ref_replace_dry_run_check != null:
		dry_run = _mesh_ref_replace_dry_run_check.button_pressed
	if _mesh_ref_replace_same_folder_check != null:
		same_folder_only = _mesh_ref_replace_same_folder_check.button_pressed
	if _mesh_ref_replace_allow_fallback_check != null and not _mesh_ref_replace_allow_fallback_check.disabled:
		allow_fallback = _mesh_ref_replace_allow_fallback_check.button_pressed
	if _mesh_ref_replace_scope_current_folder_check != null:
		current_folder_only = _mesh_ref_replace_scope_current_folder_check.button_pressed

	var candidate_scope_root: String = "res://"
	if current_folder_only:
		candidate_scope_root = _get_filesystem_current_folder()

	var target_scope_root: String = "res://"
	_run_replace_mesh_refs_with_obj_project(
		dry_run,
		same_folder_only,
		allow_fallback,
		target_scope_root,
		candidate_scope_root
	)


func _get_filesystem_current_folder() -> String:
	var iface: EditorInterface = get_editor_interface()
	if iface == null:
		return "res://"
	var dock: Object = iface.get_file_system_dock()
	if dock == null:
		return "res://"

	if dock.has_method("get_current_path"):
		var p_any: Variant = dock.call("get_current_path")
		var p: String = str(p_any)
		if not p.is_empty():
			if p.get_extension().is_empty():
				return p
			return p.get_base_dir()

	if dock.has_method("get_selected_path"):
		var s_any: Variant = dock.call("get_selected_path")
		var s: String = str(s_any)
		if not s.is_empty():
			if s.get_extension().is_empty():
				return s
			return s.get_base_dir()

	var selected_paths: PackedStringArray = _get_filesystem_selection()
	if not selected_paths.is_empty():
		var first_path: String = selected_paths[0]
		if first_path.get_extension().is_empty():
			return first_path
		return first_path.get_base_dir()

	return "res://"


func _show_mesh_ref_replace_report(result: Dictionary) -> void:
	if not is_instance_valid(_mesh_ref_replace_report_dialog):
		_build_mesh_ref_replace_report_dialog()
	if not is_instance_valid(_mesh_ref_replace_report_dialog):
		return

	var lines: PackedStringArray = PackedStringArray()
	lines.append("Densetsu OBJ Replacement Report")
	lines.append("")
	lines.append("Scope: %s" % str(result.get("scope_root", "res://")))
	lines.append("OBJ Search Scope: %s" % str(result.get("obj_scope_root", "res://")))
	lines.append("Dry Run: %s" % str(result.get("dry_run", true)))
	lines.append("Same Folder Only: %s" % str(result.get("same_folder_only", true)))
	lines.append("Allow Fallback: %s" % str(result.get("allow_basename_fallback", false)))
	lines.append("")
	lines.append("Scanned Files: %d" % int(result.get("scanned", 0)))
	lines.append("Files With Replacements: %d" % int(result.get("updated_files", 0)))
	lines.append("Total Replacements: %d" % int(result.get("replacements", 0)))
	lines.append("Failed Writes/Reads: %d" % int(result.get("failed", 0)))
	lines.append("")
	lines.append("OBJ In Scope: %d" % int(result.get("obj_total", 0)))
	lines.append("OBJ Basenames Used: %d" % int(result.get("obj_used", 0)))
	lines.append("Duplicate OBJ Basenames: %d" % int(result.get("obj_duplicate_basenames", 0)))
	lines.append("Mesh TRES_RES In OBJ Scope: %d" % int(result.get("mesh_res_total_in_obj_scope", 0)))
	lines.append("Mesh TRES_RES With Same-Folder OBJ: %d" % int(result.get("mesh_res_with_same_folder_obj", 0)))
	lines.append("Mesh TRES_RES Without Same-Folder OBJ: %d" % int(result.get("mesh_res_without_same_folder_obj", 0)))
	lines.append("")
	lines.append("Note: replacement counts below are live path references in text resources, not raw pair totals.")
	lines.append("")
	lines.append("Same-Folder Matches: %d" % int(result.get("same_folder_matches", 0)))
	lines.append("Fallback Matches: %d" % int(result.get("fallback_matches", 0)))
	lines.append("UID Cleanups On Existing OBJ Refs: %d" % int(result.get("uid_cleanups", 0)))
	lines.append("Conflicts (Missing OBJ): %d" % int(result.get("conflicts_missing_obj", 0)))
	lines.append("Conflicts (Ambiguous Fallback): %d" % int(result.get("conflicts_ambiguous_fallback", 0)))
	lines.append("")

	var samples_any: Variant = result.get("conflict_samples", PackedStringArray())
	if samples_any is PackedStringArray:
		var samples: PackedStringArray = samples_any
		if not samples.is_empty():
			lines.append("Conflict Samples:")
			for sample in samples:
				lines.append(" - " + str(sample))

	var report_text: String = "\n".join(lines)
	if _mesh_ref_replace_report_text != null:
		_mesh_ref_replace_report_text.text = report_text
	_popup_window_fit_screen(_mesh_ref_replace_report_dialog, Vector2i(980, 460), Vector2i(680, 280))


func _popup_window_fit_screen(win: Window, preferred_size: Vector2i, min_size: Vector2i) -> void:
	if win == null:
		return
	win.popup()
	_clamp_window_to_usable_screen(win, preferred_size, min_size)
	call_deferred("_clamp_window_to_usable_screen", win, preferred_size, min_size)


func _clamp_window_to_usable_screen(win: Window, preferred_size: Vector2i, min_size: Vector2i) -> void:
	if not is_instance_valid(win):
		return
	var usable: Rect2i = _get_editor_dialog_bounds_rect()
	var margin: int = 8
	var max_w: int = int(max(320, usable.size.x - (margin * 2)))
	var max_h: int = int(max(220, usable.size.y - (margin * 2)))
	win.max_size = Vector2i(max_w, max_h)

	var desired: Vector2i = win.size
	if desired.x <= 0 or desired.y <= 0:
		desired = preferred_size
	desired.x = int(max(min_size.x, desired.x))
	desired.y = int(max(min_size.y, desired.y))
	desired.x = int(min(desired.x, max_w))
	desired.y = int(min(desired.y, max_h))
	win.size = desired

	var pos: Vector2i = win.position
	var min_x: int = usable.position.x + margin
	var min_y: int = usable.position.y + margin
	var max_x: int = usable.position.x + usable.size.x - desired.x - margin
	var max_y: int = usable.position.y + usable.size.y - desired.y - margin
	if max_x < min_x:
		max_x = min_x
	if max_y < min_y:
		max_y = min_y
	pos.x = clampi(pos.x, min_x, max_x)
	pos.y = clampi(pos.y, min_y, max_y)
	win.position = pos


func _get_editor_dialog_bounds_rect() -> Rect2i:
	var screen: int = DisplayServer.window_get_current_screen()
	var screen_usable: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	if screen_usable.size.x <= 0 or screen_usable.size.y <= 0:
		var full_size: Vector2i = DisplayServer.screen_get_size(screen)
		screen_usable = Rect2i(Vector2i.ZERO, full_size)

	var iface: EditorInterface = get_editor_interface()
	if iface != null:
		var base: Control = iface.get_base_control()
		if base != null:
			var editor_window: Window = base.get_window()
			if editor_window != null:
				var editor_rect: Rect2i = Rect2i(editor_window.position, editor_window.size)
				if editor_rect.size.x > 0 and editor_rect.size.y > 0:
					var clipped: Rect2i = editor_rect.intersection(screen_usable)
					if clipped.size.x > 0 and clipped.size.y > 0:
						return clipped
					return screen_usable
	return screen_usable


func _get_filesystem_selection() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var iface: EditorInterface = get_editor_interface()
	if iface and iface.has_method("get_selected_paths"):
		var sel_any: Variant = iface.call("get_selected_paths")
		if sel_any is PackedStringArray:
			out = sel_any
		elif sel_any is Array:
			for p in sel_any:
				out.append(str(p))
	if out.size() > 0:
		return out

	var dock: Object = iface.get_file_system_dock() if iface else null
	if dock == null:
		return out

	if dock.has_method("get_selected_paths"):
		var sel_paths: Variant = dock.get_selected_paths()
		if sel_paths is PackedStringArray:
			return sel_paths
		if sel_paths is Array:
			for p in sel_paths:
				out.append(str(p))
			return out

	if dock.has_method("get_selected_files"):
		var sel_files: Variant = dock.get_selected_files()
		if sel_files is PackedStringArray:
			return sel_files
		if sel_files is Array:
			for p in sel_files:
				out.append(str(p))
			return out

	if dock.has_method("get_selected_file"):
		var sel_file: Variant = dock.get_selected_file()
		if sel_file is String and str(sel_file) != "":
			out.append(str(sel_file))
	return out


func _run_static_pack(paths: PackedStringArray) -> void:
	if _static_pack_helper == null:
		push_warning("Densetsu Suite: Static Pack helper unavailable.")
		return
	if _static_pack_helper.has_method("_pack_paths"):
		_static_pack_helper.call("_pack_paths", paths)
	else:
		push_warning("Densetsu Suite: Static Pack helper missing _pack_paths.")


func _run_array_extract(paths: PackedStringArray, mode: int, output_mode: int) -> void:
	if _array_extract_helper == null:
		push_warning("Densetsu Suite: ArrayMesh Extract helper unavailable.")
		return
	if _array_extract_helper.has_method("_extract_paths"):
		_array_extract_helper.call("_extract_paths", paths, mode, output_mode)
	else:
		push_warning("Densetsu Suite: ArrayMesh Extract helper missing _extract_paths.")


func _run_texture_resize(paths: PackedStringArray, mode: int) -> void:
	if _texture_resize_helper == null:
		push_warning("Densetsu Suite: Texture Resize helper unavailable.")
		return
	if _texture_resize_helper.has_method("_resize_paths"):
		_texture_resize_helper.call("_resize_paths", paths, mode)
	else:
		push_warning("Densetsu Suite: Texture Resize helper missing _resize_paths.")


func _run_pivot_reassign(paths: PackedStringArray, mode: int) -> void:
	if _pivot_reassign_helper == null:
		push_warning("Densetsu Suite: Pivot Reassign helper unavailable.")
		return
	if _pivot_reassign_helper.has_method("reassign_pivot_paths"):
		_pivot_reassign_helper.call("reassign_pivot_paths", paths, mode, get_editor_interface())
	else:
		push_warning("Densetsu Suite: Pivot Reassign helper missing reassign_pivot_paths.")


func _run_convert_mesh_res_to_obj(paths: PackedStringArray) -> void:
	if not _ensure_mesh_obj_helper():
		push_warning("Densetsu Suite: Mesh OBJ helper unavailable.")
		return
	if not _mesh_obj_helper.has_method("convert_mesh_resource_paths_to_obj"):
		push_warning("Densetsu Suite: Mesh OBJ helper missing convert_mesh_resource_paths_to_obj.")
		return
	var result: Dictionary = _mesh_obj_helper.call("convert_mesh_resource_paths_to_obj", paths, get_editor_interface())
	var converted: int = int(result.get("converted", 0))
	var failed: int = int(result.get("failed", 0))
	var skipped: int = int(result.get("skipped", 0))
	print("Densetsu Suite: Mesh TRES/RES -> OBJ converted=%d failed=%d skipped=%d" % [converted, failed, skipped])


func _run_replace_mesh_refs_with_obj(paths: PackedStringArray) -> void:
	if not _ensure_mesh_obj_helper():
		push_warning("Densetsu Suite: Mesh OBJ helper unavailable.")
		return
	if not _mesh_obj_helper.has_method("replace_scene_mesh_references_with_obj"):
		push_warning("Densetsu Suite: Mesh OBJ helper missing replace_scene_mesh_references_with_obj.")
		return
	var result: Dictionary = _mesh_obj_helper.call("replace_scene_mesh_references_with_obj", paths, get_editor_interface())
	var updated_scenes: int = int(result.get("updated_scenes", 0))
	var replacements: int = int(result.get("replacements", 0))
	var failed: int = int(result.get("failed", 0))
	if not bool(result.get("ok", false)):
		var err_text: String = str(result.get("error", "No matching scene references updated."))
		push_warning("Densetsu Suite: " + err_text)
	print("Densetsu Suite: Scene mesh refs replaced scenes=%d refs=%d failed=%d" % [updated_scenes, replacements, failed])


func _run_replace_mesh_refs_with_obj_project(
	dry_run: bool = true,
	same_folder_only: bool = true,
	allow_basename_fallback: bool = false,
	scope_root: String = "res://",
	obj_scope_root: String = "res://"
) -> void:
	if not _ensure_mesh_obj_helper():
		push_warning("Densetsu Suite: Mesh OBJ helper unavailable.")
		return
	if not _mesh_obj_helper.has_method("replace_project_mesh_references_with_obj_with_options"):
		if not _mesh_obj_helper.has_method("replace_project_mesh_references_with_obj_auto"):
			push_warning("Densetsu Suite: Mesh OBJ helper missing project replacement methods.")
			return
		var legacy_result: Dictionary = _mesh_obj_helper.call("replace_project_mesh_references_with_obj_auto", get_editor_interface())
		_show_mesh_ref_replace_report(legacy_result)
		return
	var result: Dictionary = _mesh_obj_helper.call(
		"replace_project_mesh_references_with_obj_with_options",
		get_editor_interface(),
		dry_run,
		same_folder_only,
		allow_basename_fallback,
		scope_root,
		obj_scope_root
	)
	var scanned: int = int(result.get("scanned", 0))
	var updated_files: int = int(result.get("updated_files", 0))
	var replacements: int = int(result.get("replacements", 0))
	var failed: int = int(result.get("failed", 0))
	var obj_total: int = int(result.get("obj_total", 0))
	var obj_used: int = int(result.get("obj_used", 0))
	var obj_dupes: int = int(result.get("obj_duplicate_basenames", 0))
	var missing: int = int(result.get("conflicts_missing_obj", 0))
	var ambiguous: int = int(result.get("conflicts_ambiguous_fallback", 0))
	if not bool(result.get("ok", false)):
		var err_text: String = str(result.get("error", "No project references updated."))
		push_warning("Densetsu Suite: " + err_text)
	print(
		"Densetsu Suite: Project OBJ pass scope=%s obj_scope=%s dry_run=%s scanned=%d updated_files=%d refs=%d failed=%d obj_total=%d obj_used=%d dupes=%d missing=%d ambiguous=%d"
		% [
			str(result.get("scope_root", "res://")),
			str(result.get("obj_scope_root", "res://")),
			str(result.get("dry_run", dry_run)),
			scanned,
			updated_files,
			replacements,
			failed,
			obj_total,
			obj_used,
			obj_dupes,
			missing,
			ambiguous
		]
	)
	_show_mesh_ref_replace_report(result)


func _ensure_mesh_obj_helper() -> bool:
	if _mesh_obj_helper != null:
		return true
	_mesh_obj_helper = _instantiate_plugin(MESH_OBJ_HELPER_SCRIPT)
	return _mesh_obj_helper != null


func _run_force_thumbnail_refresh() -> void:
	var removed: int = 0
	removed += _clear_project_editor_cache()
	removed += _clear_user_thumbnail_cache()

	var iface: EditorInterface = get_editor_interface()
	var fs: EditorFileSystem = null
	if iface != null:
		fs = iface.get_resource_filesystem()
	if fs != null and fs.has_method("scan"):
		fs.scan()
	print("Densetsu Suite: forced thumbnail refresh, removed cache files=", removed)


func _run_force_thumbnail_refresh_selected(paths: PackedStringArray) -> void:
	var files: PackedStringArray = _expand_selected_resource_paths(paths)
	if files.is_empty():
		push_warning("Densetsu Suite: No files selected for thumbnail refresh.")
		return
	var selected_names: PackedStringArray = PackedStringArray()
	var seen: Dictionary = {}
	for p in files:
		if p.ends_with(".import") or p.ends_with(".uid"):
			continue
		var n: String = p.get_file()
		if n.is_empty():
			continue
		if seen.has(n):
			continue
		seen[n] = true
		selected_names.append(n)

	if selected_names.is_empty():
		push_warning("Densetsu Suite: Selected paths did not resolve to refreshable files.")
		return

	var removed: int = _clear_project_editor_cache_for_files(selected_names)
	var iface: EditorInterface = get_editor_interface()
	var fs: EditorFileSystem = null
	if iface != null:
		fs = iface.get_resource_filesystem()
	if fs != null:
		for p in files:
			fs.update_file(p)
	print("Densetsu Suite: selective thumbnail refresh files=%d removed_cache=%d" % [files.size(), removed])


func _on_tool_static_pack() -> void:
	_run_static_pack(_get_filesystem_selection())


func _on_tool_extract_mesh_per_file() -> void:
	_run_array_extract(_get_filesystem_selection(), 0, 0)


func _on_tool_extract_mesh_common() -> void:
	_run_array_extract(_get_filesystem_selection(), 0, 1)


func _on_tool_extract_material_per_file() -> void:
	_run_array_extract(_get_filesystem_selection(), 1, 0)


func _on_tool_extract_material_common() -> void:
	_run_array_extract(_get_filesystem_selection(), 1, 1)


func _on_tool_extract_combined_per_file() -> void:
	_run_array_extract(_get_filesystem_selection(), 2, 0)


func _on_tool_extract_combined_common() -> void:
	_run_array_extract(_get_filesystem_selection(), 2, 1)


func _on_tool_resize_overwrite() -> void:
	_run_texture_resize(_get_filesystem_selection(), 0)


func _on_tool_resize_copy() -> void:
	_run_texture_resize(_get_filesystem_selection(), 1)


func _on_tool_pivot_center_mass() -> void:
	_run_pivot_reassign(_get_filesystem_selection(), PIVOT_MODE_CENTER_MASS)


func _on_tool_pivot_center_bottom() -> void:
	_run_pivot_reassign(_get_filesystem_selection(), PIVOT_MODE_CENTER_BOTTOM)


func _on_tool_convert_mesh_res_to_obj() -> void:
	_run_convert_mesh_res_to_obj(_get_filesystem_selection())


func _on_tool_replace_mesh_refs_with_obj() -> void:
	_run_replace_mesh_refs_with_obj(_get_filesystem_selection())


func _on_tool_replace_mesh_refs_with_obj_project() -> void:
	_open_mesh_ref_replace_dialog()


func _on_tool_force_thumbnail_refresh() -> void:
	_run_force_thumbnail_refresh()


func _on_tool_force_thumbnail_refresh_selected() -> void:
	_run_force_thumbnail_refresh_selected(_get_filesystem_selection())


func _on_tool_new_densetsu_map() -> void:
	var template_path := new_map_template_scene.strip_edges()
	if template_path.is_empty():
		push_warning("Densetsu Suite: Set 'new_map_template_scene' before creating a map.")
		return
	if not ResourceLoader.exists(template_path, "PackedScene"):
		push_warning("Densetsu Suite: Template scene not found: " + template_path)
		return
	if not is_instance_valid(_new_map_dialog):
		_build_new_map_dialog()
	if not is_instance_valid(_new_map_dialog):
		push_warning("Densetsu Suite: Failed to open new map dialog.")
		return

	var dir_path := new_map_output_dir.strip_edges()
	if dir_path.is_empty():
		dir_path = "res://"
	var default_name := new_map_default_file.strip_edges()
	if default_name.is_empty():
		default_name = "new_densetsu_map.tscn"
	_new_map_dialog.current_dir = dir_path
	_new_map_dialog.current_file = default_name
	_popup_window_fit_screen(_new_map_dialog, Vector2i(920, 620), Vector2i(680, 420))


func _on_new_map_file_selected(path: String) -> void:
	var save_path := path
	if not save_path.to_lower().ends_with(".tscn"):
		save_path += ".tscn"
	var result := _create_new_map_from_template(save_path)
	if not bool(result.get("ok", false)):
		push_error("Densetsu Suite: " + str(result.get("error", "Failed to create map scene.")))
		return
	var iface := get_editor_interface()
	if iface:
		iface.open_scene_from_path(save_path)
	print("Densetsu Suite: New map scene created at " + save_path)


func _create_new_map_from_template(save_path: String) -> Dictionary:
	var template_path := new_map_template_scene.strip_edges()
	if template_path.is_empty():
		return {"ok": false, "error": "Template scene path is empty."}

	var template_scene := load(template_path) as PackedScene
	if template_scene == null:
		return {"ok": false, "error": "Failed to load template scene: " + template_path}

	var instance_root := template_scene.instantiate()
	if not (instance_root is Node):
		return {"ok": false, "error": "Template root is not a Node."}

	var root_node := (instance_root as Node).duplicate(Node.DUPLICATE_SIGNALS | Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS)
	instance_root.free()
	if not (root_node is Node):
		return {"ok": false, "error": "Failed to duplicate template instance."}

	var scene_root := root_node as Node
	_set_scene_owner_recursive(scene_root, scene_root)

	var packed := PackedScene.new()
	var pack_err := packed.pack(scene_root)
	if pack_err != OK:
		scene_root.free()
		return {"ok": false, "error": "Failed to pack new scene. Error code: %d" % pack_err}

	_ensure_res_output_dir(save_path)
	var save_err := ResourceSaver.save(packed, save_path)
	scene_root.free()
	if save_err != OK:
		return {"ok": false, "error": "Failed to save new scene. Error code: %d" % save_err}

	return {"ok": true}


func _set_scene_owner_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		if child is Node:
			var child_node := child as Node
			child_node.owner = owner
			_set_scene_owner_recursive(child_node, owner)


func _ensure_res_output_dir(res_path: String) -> void:
	var dir_path := res_path.get_base_dir()
	if dir_path.is_empty():
		return
	var abs_dir := ProjectSettings.globalize_path(dir_path)
	DirAccess.make_dir_recursive_absolute(abs_dir)


func _on_ctx_static_pack(paths: PackedStringArray = PackedStringArray()) -> void:
	_run_static_pack(paths)


func _on_ctx_extract_mesh_per_file(paths: PackedStringArray = PackedStringArray()) -> void:
	_run_array_extract(paths, 0, 0)


func _on_ctx_extract_mesh_common(paths: PackedStringArray = PackedStringArray()) -> void:
	_run_array_extract(paths, 0, 1)


func _on_ctx_extract_material_per_file(paths: PackedStringArray = PackedStringArray()) -> void:
	_run_array_extract(paths, 1, 0)


func _on_ctx_extract_material_common(paths: PackedStringArray = PackedStringArray()) -> void:
	_run_array_extract(paths, 1, 1)


func _on_ctx_extract_combined_per_file(paths: PackedStringArray = PackedStringArray()) -> void:
	_run_array_extract(paths, 2, 0)


func _on_ctx_extract_combined_common(paths: PackedStringArray = PackedStringArray()) -> void:
	_run_array_extract(paths, 2, 1)


func _on_ctx_resize_overwrite(paths: PackedStringArray = PackedStringArray()) -> void:
	_run_texture_resize(paths, 0)


func _on_ctx_resize_copy(paths: PackedStringArray = PackedStringArray()) -> void:
	_run_texture_resize(paths, 1)


func _on_ctx_pivot_center_mass(paths: PackedStringArray = PackedStringArray()) -> void:
	_run_pivot_reassign(paths, PIVOT_MODE_CENTER_MASS)


func _on_ctx_pivot_center_bottom(paths: PackedStringArray = PackedStringArray()) -> void:
	_run_pivot_reassign(paths, PIVOT_MODE_CENTER_BOTTOM)


func _on_ctx_convert_mesh_res_to_obj(paths: PackedStringArray = PackedStringArray()) -> void:
	_run_convert_mesh_res_to_obj(paths)


func _on_ctx_replace_mesh_refs_with_obj(paths: PackedStringArray = PackedStringArray()) -> void:
	_run_replace_mesh_refs_with_obj(paths)


func _on_ctx_force_thumbnail_refresh_selected(paths: PackedStringArray = PackedStringArray()) -> void:
	_run_force_thumbnail_refresh_selected(paths)


func _clear_project_editor_cache() -> int:
	var removed: int = 0
	var editor_dir_abs: String = ProjectSettings.globalize_path("res://.godot/editor")
	if not DirAccess.dir_exists_absolute(editor_dir_abs):
		return removed
	var file_names: PackedStringArray = PackedStringArray()
	_collect_files_recursive_absolute(editor_dir_abs, file_names)
	for file_path in file_names:
		var file_name: String = file_path.get_file()
		if file_name.begins_with("filesystem_cache"):
			if DirAccess.remove_absolute(file_path) == OK:
				removed += 1
			continue
		if file_name.find(".mesh-folding-") != -1:
			if DirAccess.remove_absolute(file_path) == OK:
				removed += 1
	return removed


func _clear_project_editor_cache_for_files(file_names: PackedStringArray) -> int:
	var removed: int = 0
	var editor_dir_abs: String = ProjectSettings.globalize_path("res://.godot/editor")
	if not DirAccess.dir_exists_absolute(editor_dir_abs):
		return removed
	if file_names.is_empty():
		return removed

	var file_names_set: Dictionary = {}
	for n in file_names:
		file_names_set[n] = true

	var cache_files: PackedStringArray = PackedStringArray()
	_collect_files_recursive_absolute(editor_dir_abs, cache_files)
	for cache_file in cache_files:
		var cache_name: String = cache_file.get_file()
		for n in file_names_set.keys():
			var needle: String = str(n)
			if cache_name.begins_with(needle + "-"):
				if DirAccess.remove_absolute(cache_file) == OK:
					removed += 1
				break
	return removed


func _clear_user_thumbnail_cache() -> int:
	var removed: int = 0
	var appdata: String = OS.get_environment("APPDATA")
	if appdata.is_empty():
		return removed
	var candidate_dirs: PackedStringArray = PackedStringArray([
		appdata.path_join("Godot/editor/cache"),
		appdata.path_join("Godot/editor/thumbnails")
	])
	for dir_path in candidate_dirs:
		if not DirAccess.dir_exists_absolute(dir_path):
			continue
		var files: PackedStringArray = PackedStringArray()
		_collect_files_recursive_absolute(dir_path, files)
		for file_path in files:
			if DirAccess.remove_absolute(file_path) == OK:
				removed += 1
	return removed


func _collect_files_recursive_absolute(dir_path: String, out: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name.is_empty():
			break
		if name.begins_with("."):
			continue
		var full_path: String = dir_path.path_join(name)
		if dir.current_is_dir():
			_collect_files_recursive_absolute(full_path, out)
		else:
			out.append(full_path)
	dir.list_dir_end()


func _expand_selected_resource_paths(paths: PackedStringArray) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for p in paths:
		if p.ends_with(".import") or p.ends_with(".uid"):
			continue
		if _is_resource_dir(p):
			_collect_resource_files_recursive(p, out)
		else:
			out.append(p)
	return out


func _is_resource_dir(path: String) -> bool:
	if path.is_empty():
		return false
	var abs_path: String = ProjectSettings.globalize_path(path)
	return DirAccess.dir_exists_absolute(abs_path)


func _collect_resource_files_recursive(dir_path: String, out: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name.is_empty():
			break
		if name.begins_with("."):
			continue
		var full_path: String = dir_path.path_join(name)
		if dir.current_is_dir():
			_collect_resource_files_recursive(full_path, out)
		else:
			if full_path.ends_with(".import") or full_path.ends_with(".uid"):
				continue
			out.append(full_path)
	dir.list_dir_end()
