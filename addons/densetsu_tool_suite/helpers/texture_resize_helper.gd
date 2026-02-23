@tool
extends EditorPlugin

const MODE_OVERWRITE: int = 0
const MODE_COPY: int = 1
const MIN_POT: int = 32
const MAX_POT: int = 4096
const COPY_SUFFIX: String = "_pot"

var SUPPORTED_EXTS: PackedStringArray = PackedStringArray(["png", "jpg", "jpeg", "webp", "bmp", "tga"])
var _ctx_plugin: EditorContextMenuPlugin


class _TextureResizeContextMenuPlugin:
	extends EditorContextMenuPlugin
	var _owner: EditorPlugin

	func _init(owner: EditorPlugin) -> void:
		_owner = owner

	func _popup_menu(paths: PackedStringArray) -> void:
		if paths.is_empty():
			return
		add_context_menu_item("Resize Textures POT (Overwrite)", Callable(_owner, "_on_resize_paths_from_context_overwrite"))
		add_context_menu_item("Resize Textures POT (Copy)", Callable(_owner, "_on_resize_paths_from_context_copy"))


func _enter_tree() -> void:
	add_tool_menu_item("Resize Textures POT (Selected, Overwrite)", _on_resize_selected_overwrite)
	add_tool_menu_item("Resize Textures POT (Selected, Copy)", _on_resize_selected_copy)
	_ctx_plugin = _TextureResizeContextMenuPlugin.new(self)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _ctx_plugin)


func _exit_tree() -> void:
	remove_tool_menu_item("Resize Textures POT (Selected, Overwrite)")
	remove_tool_menu_item("Resize Textures POT (Selected, Copy)")
	if _ctx_plugin:
		remove_context_menu_plugin(_ctx_plugin)
		_ctx_plugin = null


func _on_resize_selected_overwrite() -> void:
	var paths: PackedStringArray = _get_filesystem_selection()
	_resize_paths(paths, MODE_OVERWRITE)


func _on_resize_selected_copy() -> void:
	var paths: PackedStringArray = _get_filesystem_selection()
	_resize_paths(paths, MODE_COPY)


func _on_resize_paths_from_context_overwrite(paths: PackedStringArray = PackedStringArray()) -> void:
	_resize_paths(paths, MODE_OVERWRITE)


func _on_resize_paths_from_context_copy(paths: PackedStringArray = PackedStringArray()) -> void:
	_resize_paths(paths, MODE_COPY)


func _get_filesystem_selection() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var iface: EditorInterface = get_editor_interface()
	if iface and iface.has_method("get_selected_paths"):
		var sel_any: Variant = iface.call("get_selected_paths")
		if sel_any is PackedStringArray:
			out = sel_any
		elif sel_any is Array:
			for p in sel_any:
				out.append(String(p))
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
				out.append(String(p))
			return out

	if dock.has_method("get_selected_files"):
		var sel_files: Variant = dock.get_selected_files()
		if sel_files is PackedStringArray:
			return sel_files
		if sel_files is Array:
			for p in sel_files:
				out.append(String(p))
			return out

	if dock.has_method("get_selected_file"):
		var sel_file: Variant = dock.get_selected_file()
		if sel_file is String and String(sel_file) != "":
			out.append(String(sel_file))
	return out


func _resize_paths(paths: PackedStringArray, mode: int) -> void:
	if paths.is_empty():
		push_warning("Select texture files or folders in the FileSystem dock first.")
		return

	var files: PackedStringArray = _expand_paths(paths)
	var textures: PackedStringArray = PackedStringArray()
	for path in files:
		if _is_supported(path):
			textures.append(path)

	if textures.is_empty():
		push_warning("No supported textures found in selection.")
		return

	var mode_name: String = "overwrite" if mode == MODE_OVERWRITE else "copy"
	print("Texture POT resize: mode=", mode_name, " count=", textures.size())

	var processed: int = 0
	var skipped: int = 0
	var failed: int = 0
	for tex_path in textures:
		var result: int = _resize_single(tex_path, mode)
		if result == 1:
			processed += 1
		elif result == 0:
			skipped += 1
		else:
			failed += 1

	print("Texture POT resize summary: processed=", processed, " skipped=", skipped, " failed=", failed)
	get_editor_interface().get_resource_filesystem().scan()


func _resize_single(src_path: String, mode: int) -> int:
	var image: Image = Image.new()
	var err_load: int = image.load(src_path)
	if err_load != OK:
		push_warning("Texture POT resize: failed to load " + src_path + " (err " + str(err_load) + ")")
		return -1
	if image.is_empty():
		push_warning("Texture POT resize: empty image " + src_path)
		return -1

	var src_w: int = image.get_width()
	var src_h: int = image.get_height()
	if src_w <= 0 or src_h <= 0:
		push_warning("Texture POT resize: invalid dimensions " + src_path)
		return -1

	var target: Vector2i = _compute_target_size(src_w, src_h)
	if target.x <= 0 or target.y <= 0:
		push_warning("Texture POT resize: invalid target size for " + src_path)
		return -1

	if src_w == target.x and src_h == target.y and mode == MODE_OVERWRITE:
		print("Texture POT resize: already POT, skip ", src_path, " (", src_w, "x", src_h, ")")
		return 0

	image.resize(target.x, target.y, Image.INTERPOLATE_LANCZOS)

	var output_path: String = src_path
	if mode == MODE_COPY:
		output_path = _derive_copy_path(src_path)

	var err_save: int = _save_image(image, output_path, mode)
	if err_save != OK:
		push_warning("Texture POT resize: failed to save " + output_path + " (err " + str(err_save) + ")")
		return -1

	var ratio_class: String = _classify_ratio(src_w, src_h)
	print("Texture POT resize: ", src_path, " ", src_w, "x", src_h, " -> ", target.x, "x", target.y, " class=", ratio_class, " out=", output_path)
	return 1


func _save_image(image: Image, path: String, mode: int) -> int:
	var ext: String = path.get_extension().to_lower()
	if ext == "png":
		return image.save_png(path)
	if ext == "jpg" or ext == "jpeg":
		return image.save_jpg(path)
	if ext == "webp":
		return image.save_webp(path)

	# BMP/TGA can be read but not reliably overwritten in current Image save API.
	if mode == MODE_OVERWRITE:
		push_warning("Texture POT resize: overwrite not supported for ." + ext + " (" + path + "), use copy mode.")
		return ERR_UNAVAILABLE
	var png_path: String = path.get_basename() + ".png"
	return image.save_png(png_path)


func _derive_copy_path(src_path: String) -> String:
	var ext: String = src_path.get_extension().to_lower()
	var base: String = src_path.get_basename()
	if ext == "png" or ext == "jpg" or ext == "jpeg" or ext == "webp":
		return base + COPY_SUFFIX + "." + ext
	return base + COPY_SUFFIX + ".png"


func _compute_target_size(w: int, h: int) -> Vector2i:
	var ratio_class: String = _classify_ratio(w, h)
	var area: float = float(w * h)
	var n: int
	if ratio_class == "long":
		n = _nearest_pot(int(round(sqrt(area / 2.0))))
		return Vector2i(_clamp_to_pot(n * 2), _clamp_to_pot(n))
	if ratio_class == "tall":
		n = _nearest_pot(int(round(sqrt(area / 2.0))))
		return Vector2i(_clamp_to_pot(n), _clamp_to_pot(n * 2))
	n = _nearest_pot(int(round(sqrt(area))))
	return Vector2i(_clamp_to_pot(n), _clamp_to_pot(n))


func _classify_ratio(w: int, h: int) -> String:
	var ratio: float = float(w) / float(h)
	if ratio > 1.34:
		return "long"
	if ratio < 0.75:
		return "tall"
	return "square"


func _nearest_pot(value: int) -> int:
	if value <= MIN_POT:
		return MIN_POT
	if value >= MAX_POT:
		return MAX_POT

	var lower: int = MIN_POT
	while lower < value and lower < MAX_POT:
		lower *= 2
	if lower == value:
		return lower
	var upper: int = lower
	lower /= 2
	if (value - lower) <= (upper - value):
		return _clamp_to_pot(lower)
	return _clamp_to_pot(upper)


func _clamp_to_pot(value: int) -> int:
	if value < MIN_POT:
		return MIN_POT
	if value > MAX_POT:
		return MAX_POT
	return value


func _expand_paths(paths: PackedStringArray) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for path in paths:
		if path.ends_with(".import") or path.ends_with(".uid"):
			continue
		if _is_dir(path):
			_collect_files_recursive(path, out)
		else:
			out.append(path)
	return out


func _is_dir(path: String) -> bool:
	if path == "":
		return false
	var abs: String = ProjectSettings.globalize_path(path)
	return DirAccess.dir_exists_absolute(abs)


func _collect_files_recursive(dir_path: String, out: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name: String = dir.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue
		var full: String = dir_path.path_join(name)
		if dir.current_is_dir():
			_collect_files_recursive(full, out)
		else:
			out.append(full)
	dir.list_dir_end()


func _is_supported(path: String) -> bool:
	var ext: String = path.get_extension().to_lower()
	return SUPPORTED_EXTS.has(ext)
