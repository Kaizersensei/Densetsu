@tool
extends VBoxContainer

const REPORT_DIR := "res://.audit"
const REPORT_PATH := "res://.audit/unused_files.txt"

var _editor_interface: EditorInterface
var _unused: PackedStringArray = PackedStringArray()

@onready var _scan_button: Button = %ScanButton
@onready var _save_button: Button = %SaveButton
@onready var _copy_button: Button = %CopyButton
@onready var _count_label: Label = %CountLabel
@onready var _tree: Tree = %Tree


func _ready() -> void:
	_scan_button.pressed.connect(_scan_unused)
	_save_button.pressed.connect(_save_report)
	_copy_button.pressed.connect(_copy_report)


func set_editor_interface(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface


func _scan_unused() -> void:
	var all_files := _collect_all_files()
	var used_files := _collect_used_files()
	var unused := []
	for path in all_files:
		if not used_files.has(path):
			unused.append(path)
	unused.sort()
	_unused = PackedStringArray(unused)
	_render_unused()


func _save_report() -> void:
	_ensure_report_dir()
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		return
	for path in _unused:
		file.store_line(path)
	file.close()


func _copy_report() -> void:
	if _unused.is_empty():
		DisplayServer.clipboard_set("")
		return
	DisplayServer.clipboard_set("\n".join(_unused))


func _render_unused() -> void:
	_tree.clear()
	var root := _tree.create_item()
	for path in _unused:
		var item := _tree.create_item(root)
		item.set_text(0, path)
	_count_label.text = "Unused: %d" % _unused.size()


func _collect_all_files() -> PackedStringArray:
	var out := []
	var fs = _editor_interface.get_resource_filesystem() if _editor_interface else null
	if fs == null:
		return PackedStringArray()
	var root = fs.get_filesystem()
	_collect_files_recursive(root, out)
	return PackedStringArray(out)


func _collect_files_recursive(dir: EditorFileSystemDirectory, out: Array) -> void:
	if dir == null:
		return
	var file_count := dir.get_file_count()
	for i in range(file_count):
		var name := dir.get_file(i)
		var path := dir.get_file_path(i)
		if _is_audit_ignored(name, path):
			continue
		if _is_trackable_resource(path):
			out.append(path)
	var sub_count := dir.get_subdir_count()
	for i in range(sub_count):
		_collect_files_recursive(dir.get_subdir(i), out)


func _is_audit_ignored(name: String, path: String) -> bool:
	if name.begins_with("."):
		return true
	if path.begins_with("res://.godot/") or path.begins_with("res://.git/"):
		return true
	if path.begins_with(REPORT_DIR + "/"):
		return true
	return false


func _is_trackable_resource(path: String) -> bool:
	var ext := path.get_extension().to_lower()
	if ext == "":
		return false
	if ext == "import" or ext == "uid" or ext == "tmp":
		return false
	var allowed := {
		"tscn": true,
		"tres": true,
		"res": true,
		"gd": true,
		"gdshader": true,
		"shader": true,
		"png": true,
		"jpg": true,
		"jpeg": true,
		"webp": true,
		"svg": true,
		"wav": true,
		"ogg": true,
		"mp3": true,
		"glb": true,
		"gltf": true,
		"fbx": true,
		"obj": true,
		"mesh": true,
		"material": true,
		"tga": true,
		"exr": true,
	}
	return allowed.has(ext)


func _collect_used_files() -> Dictionary:
	var used := {}
	var roots := _collect_dependency_roots()
	var queue := roots.duplicate()
	while queue.size() > 0:
		var path: String = queue.pop_back()
		if used.has(path):
			continue
		used[path] = true
		if not ResourceLoader.exists(path):
			continue
		var deps := ResourceLoader.get_dependencies(path)
		for dep in deps:
			if not used.has(dep):
				queue.append(dep)
	return used


func _collect_dependency_roots() -> Array:
	var roots := []
	var main_scene := ProjectSettings.get_setting("application/run/main_scene")
	if typeof(main_scene) == TYPE_STRING and main_scene != "":
		roots.append(main_scene)
	var autoloads := ProjectSettings.get_setting("autoload")
	if typeof(autoloads) == TYPE_DICTIONARY:
		for key in autoloads.keys():
			var entry = autoloads[key]
			if typeof(entry) == TYPE_STRING and entry != "":
				roots.append(entry)
			elif typeof(entry) == TYPE_DICTIONARY and entry.has("path"):
				roots.append(entry["path"])
	return roots


func _ensure_report_dir() -> void:
	var abs := ProjectSettings.globalize_path(REPORT_DIR)
	var dir := DirAccess.open(abs)
	if dir == null:
		DirAccess.make_dir_recursive_absolute(abs)
