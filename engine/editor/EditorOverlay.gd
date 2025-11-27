extends CanvasLayer

@onready var _ribbon: Control = $Ribbon
@onready var _sidebar_left: Control = $SidebarLeft
@onready var _status: Label = $Ribbon/StatusLabel
@onready var _selection: Label = $Ribbon/SelectionLabel
@onready var _snap_toggle: CheckBox = $Ribbon/SnapToggle
@onready var _snap_size: LineEdit = $Ribbon/SnapSize
@onready var _undo_button: Button = $Ribbon/Undo
@onready var _redo_button: Button = $Ribbon/Redo
@onready var _save_button: Button = $Ribbon/Save
@onready var _load_button: Button = $Ribbon/Load
@onready var _reload_button: Button = $Ribbon/Reload
@onready var _save_dialog: FileDialog = $SaveDialog
@onready var _load_dialog: FileDialog = $LoadDialog
@onready var _pos_x: LineEdit = $Inspector/PosRow/PosX
@onready var _pos_y: LineEdit = $Inspector/PosYRow/PosY
@onready var _rot: LineEdit = $Inspector/RotRow/Rot
@onready var _scale_x: LineEdit = $Inspector/ScaleXRow/ScaleX
@onready var _scale_y: LineEdit = $Inspector/ScaleYRow/ScaleY
@onready var _pos_x_apply: Button = $Inspector/PosRow/PosXApply
@onready var _pos_y_apply: Button = $Inspector/PosYRow/PosYApply
@onready var _rot_apply: Button = $Inspector/RotRow/RotApply
@onready var _scale_x_apply: Button = $Inspector/ScaleXRow/ScaleXApply
@onready var _scale_y_apply: Button = $Inspector/ScaleYRow/ScaleYApply
@onready var _proj_collide: CheckBox = $Inspector/ProjRow/ProjCollide
@onready var _proj_apply: Button = $Inspector/ProjRow/ProjApply
@onready var _place_player: Button = $SidebarLeft/PrefabList/PrefabTabs/Actors/PlacePlayer
@onready var _place_enemy: Button = $SidebarLeft/PrefabList/PrefabTabs/Actors/PlaceEnemy
@onready var _place_trap: Button = $SidebarLeft/PrefabList/PrefabTabs/Actors/PlaceTrap
@onready var _place_item: Button = $SidebarLeft/PrefabList/PrefabTabs/Actors/PlaceItem
@onready var _place_solid: Button = $SidebarLeft/PrefabList/PrefabTabs/Building/PlaceSolid
@onready var _place_one_way: Button = $SidebarLeft/PrefabList/PrefabTabs/Building/PlaceOneWay
@onready var _place_slope_left: Button = $SidebarLeft/PrefabList/PrefabTabs/Building/PlaceSlopeLeft
@onready var _place_slope_right: Button = $SidebarLeft/PrefabList/PrefabTabs/Building/PlaceSlopeRight
@onready var _place_deco: Button = $SidebarLeft/PrefabList/PrefabTabs/Building/PlaceDeco
@onready var _place_deco_solid: Button = $SidebarLeft/PrefabList/PrefabTabs/Building/PlaceDecoSolid
@onready var _delete_button: Button = $SidebarLeft/PrefabList/DeleteButton

var _inspector_signal_block := false
var _prefab_handler: Callable = Callable()

func set_editor_mode(active: bool) -> void:
	visible = active
	if _status:
		_status.text = "EDITOR MODE" if active else "GAME"


func set_selection_name(name: String) -> void:
	if _selection:
		_selection.text = "Selected: %s" % name


func get_snap_enabled() -> bool:
	return _snap_toggle.button_pressed if _snap_toggle else false


func get_snap_size() -> float:
	if _snap_size:
		var v := float(_snap_size.text)
		return max(v, 0.1)
	return 8.0


func populate_inspector(node: Node) -> void:
	if _inspector_signal_block:
		return
	_inspector_signal_block = true
	if node is Node2D:
		var n := node as Node2D
		if _pos_x: _pos_x.text = str(round(n.position.x))
		if _pos_y: _pos_y.text = str(round(n.position.y))
		if _rot: _rot.text = str(round(rad_to_deg(n.rotation)))
		if _scale_x: _scale_x.text = "%0.4f" % n.scale.x
		if _scale_y: _scale_y.text = "%0.4f" % n.scale.y
		if _proj_collide:
			var row := _proj_collide.get_parent()
			if "allow_projectile_collision" in n:
				_proj_collide.button_pressed = bool(n.get("allow_projectile_collision"))
				_proj_collide.visible = true
				if _proj_apply:
					_proj_apply.visible = true
				if row:
					row.visible = true
			else:
				_proj_collide.visible = false
				if _proj_apply:
					_proj_apply.visible = false
				if row:
					row.visible = false
	else:
		if _pos_x: _pos_x.text = ""
		if _pos_y: _pos_y.text = ""
		if _rot: _rot.text = ""
		if _scale_x: _scale_x.text = ""
		if _scale_y: _scale_y.text = ""
		if _proj_collide:
			_proj_collide.visible = false
			var row := _proj_collide.get_parent()
			if row:
				row.visible = false
		if _proj_apply:
			_proj_apply.visible = false
	_inspector_signal_block = false


func connect_inspector(handler: Callable) -> void:
	if _pos_x:
		_pos_x.text_submitted.connect(handler.bind("pos_x"))
		_pos_x.focus_exited.connect(handler.bind("pos_x", _pos_x.text))
	if _pos_x_apply:
		_pos_x_apply.pressed.connect(handler.bind("pos_x"))
	if _pos_y:
		_pos_y.text_submitted.connect(handler.bind("pos_y"))
		_pos_y.focus_exited.connect(handler.bind("pos_y", _pos_y.text))
	if _pos_y_apply:
		_pos_y_apply.pressed.connect(handler.bind("pos_y"))
	if _rot:
		_rot.text_submitted.connect(handler.bind("rot"))
		_rot.focus_exited.connect(handler.bind("rot", _rot.text))
	if _rot_apply:
		_rot_apply.pressed.connect(handler.bind("rot"))
	if _scale_x:
		_scale_x.text_submitted.connect(handler.bind("scale_x"))
		_scale_x.focus_exited.connect(handler.bind("scale_x", _scale_x.text))
	if _scale_x_apply:
		_scale_x_apply.pressed.connect(handler.bind("scale_x"))
	if _scale_y:
		_scale_y.text_submitted.connect(handler.bind("scale_y"))
		_scale_y.focus_exited.connect(handler.bind("scale_y", _scale_y.text))
	if _scale_y_apply:
		_scale_y_apply.pressed.connect(handler.bind("scale_y"))
	if _proj_apply and _proj_collide:
		_proj_apply.pressed.connect(handler.bind("proj_collide"))

func connect_prefab_buttons(handler: Callable) -> void:
	_prefab_handler = handler
	if _delete_button:
		_delete_button.pressed.connect(handler.bind("delete"))
	if _place_player:
		_place_player.pressed.connect(handler.bind("player"))
	if _place_enemy:
		_place_enemy.pressed.connect(handler.bind("enemy"))
	if _place_deco:
		_place_deco.pressed.connect(handler.bind("deco"))
	if _place_deco_solid:
		_place_deco_solid.pressed.connect(handler.bind("deco_solid"))
	if _place_trap:
		_place_trap.pressed.connect(handler.bind("trap"))
	if _place_item:
		_place_item.pressed.connect(handler.bind("item"))
	if _place_solid:
		_place_solid.pressed.connect(handler.bind("solid"))
	if _place_one_way:
		_place_one_way.pressed.connect(handler.bind("one_way"))
	if _place_slope_left:
		_place_slope_left.pressed.connect(handler.bind("slope_left"))
	if _place_slope_right:
		_place_slope_right.pressed.connect(handler.bind("slope_right"))
	if _undo_button:
		_undo_button.pressed.connect(handler.bind("undo"))
	if _redo_button:
		_redo_button.pressed.connect(handler.bind("redo"))
	if _save_button:
		_save_button.pressed.connect(_open_save_dialog)
	if _load_button:
		_load_button.pressed.connect(_open_load_dialog)
	if _reload_button:
		_reload_button.pressed.connect(handler.bind("reload"))
	if _save_dialog:
		_save_dialog.file_selected.connect(_on_save_dialog_confirmed)
		_save_dialog.canceled.connect(_on_save_dialog_canceled)
		_save_dialog.close_requested.connect(_on_save_dialog_canceled)
	if _load_dialog:
		_load_dialog.file_selected.connect(_on_load_dialog_confirmed)
		_load_dialog.canceled.connect(_on_load_dialog_canceled)
		_load_dialog.close_requested.connect(_on_load_dialog_canceled)


func _open_save_dialog() -> void:
	if _save_dialog:
		_save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		_save_dialog.popup_centered()
	else:
		if _prefab_handler.is_valid():
			_prefab_handler.call("save")


func _open_load_dialog() -> void:
	if _load_dialog:
		_load_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		_load_dialog.popup_centered()
	else:
		if _prefab_handler.is_valid():
			_prefab_handler.call("load")


func _on_save_dialog_confirmed(path: String) -> void:
	if _prefab_handler.is_valid():
		_prefab_handler.call("save_path", path)


func _on_load_dialog_confirmed(path: String) -> void:
	if _prefab_handler.is_valid():
		_prefab_handler.call("load_path", path)


func _on_save_dialog_canceled() -> void:
	if _save_dialog:
		_save_dialog.hide()


func _on_load_dialog_canceled() -> void:
	if _load_dialog:
		_load_dialog.hide()
