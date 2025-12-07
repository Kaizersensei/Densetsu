extends Control

const DEFAULT_SCENE := "res://game/levels/default_scene.tscn"
const FALLBACK_SCENE := "res://game/levels/CollisionTest.tscn"

@onready var _btn_default: Button = %LoadDefault
@onready var _btn_new: Button = %NewScene
@onready var _btn_load: Button = %LoadScene
@onready var _btn_quit: Button = %Quit
@onready var _file_dialog: FileDialog = %FileDialog

func _ready() -> void:
	if _btn_default:
		_btn_default.pressed.connect(_on_load_default)
	if _btn_new:
		_btn_new.pressed.connect(_on_new_scene)
	if _btn_load:
		_btn_load.pressed.connect(_on_open_dialog)
	if _btn_quit:
		_btn_quit.pressed.connect(_on_quit)
	if _file_dialog:
		_file_dialog.file_selected.connect(_on_file_selected)


func _on_load_default() -> void:
	_goto_scene(_resolve_default_scene(), false)


func _on_new_scene() -> void:
	# Create a fresh blank scene file and open it in editor mode.
	var new_path := _create_blank_scene()
	_goto_scene(new_path, true)


func _on_open_dialog() -> void:
	if _file_dialog:
		_file_dialog.popup_centered()


func _on_file_selected(path: String) -> void:
	if path == "":
		return
	_goto_scene(path, false)


func _on_quit() -> void:
	get_tree().quit()


func _resolve_default_scene() -> String:
	if FileAccess.file_exists(DEFAULT_SCENE):
		return DEFAULT_SCENE
	return FALLBACK_SCENE


func _create_blank_scene() -> String:
	var dir_path := "res://editor_saves"
	DirAccess.make_dir_recursive_absolute(dir_path)
	var path := dir_path.path_join("new_scene.tscn")
	var root := Node2D.new()
	root.name = "NewScene"
	var packed := PackedScene.new()
	if packed.pack(root) == OK:
		var err := ResourceSaver.save(packed, path)
		if err != OK:
			push_error("Failed to save blank scene: %s (err %d)" % [path, err])
			return _resolve_default_scene()
	else:
		push_error("Failed to pack blank scene; falling back to default")
		return _resolve_default_scene()
	return path


func _goto_scene(path: String, enter_editor: bool) -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.set_meta("enter_editor_next", enter_editor)
	var err := tree.change_scene_to_file(path)
	if err != OK:
		push_error("Failed to load scene: %s (err %d)" % [path, err])
		return
