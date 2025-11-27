extends CanvasLayer

@onready var _ribbon: Control = $Ribbon
@onready var _sidebar_left: Control = $SidebarLeft
@onready var _status: Label = $Ribbon/StatusLabel
@onready var _selection: Label = $Ribbon/SelectionLabel
@onready var _snap_toggle: CheckBox = $Ribbon/SnapToggle
@onready var _snap_size: LineEdit = $Ribbon/SnapSize
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
@onready var _place_player: Button = $SidebarLeft/PrefabList/PrefabButtons/PlacePlayer
@onready var _place_enemy: Button = $SidebarLeft/PrefabList/PrefabButtons/PlaceEnemy
@onready var _place_deco: Button = $SidebarLeft/PrefabList/PrefabButtons/PlaceDeco
@onready var _place_trap: Button = $SidebarLeft/PrefabList/PrefabButtons/PlaceTrap
@onready var _place_item: Button = $SidebarLeft/PrefabList/PrefabButtons/PlaceItem
@onready var _place_ground: Button = $SidebarLeft/PrefabList/PrefabButtons/PlaceGround
@onready var _place_wall: Button = $SidebarLeft/PrefabList/PrefabButtons/PlaceWall
@onready var _place_slope_left: Button = $SidebarLeft/PrefabList/PrefabButtons/PlaceSlopeLeft
@onready var _place_slope_right: Button = $SidebarLeft/PrefabList/PrefabButtons/PlaceSlopeRight

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
		if _scale_x: _scale_x.text = str(round(n.scale.x))
		if _scale_y: _scale_y.text = str(round(n.scale.y))
	else:
		if _pos_x: _pos_x.text = ""
		if _pos_y: _pos_y.text = ""
		if _rot: _rot.text = ""
		if _scale_x: _scale_x.text = ""
		if _scale_y: _scale_y.text = ""
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

func connect_prefab_buttons(handler: Callable) -> void:
	_prefab_handler = handler
	if _place_player:
		_place_player.pressed.connect(handler.bind("player"))
	if _place_enemy:
		_place_enemy.pressed.connect(handler.bind("enemy"))
	if _place_deco:
		_place_deco.pressed.connect(handler.bind("deco"))
	if _place_trap:
		_place_trap.pressed.connect(handler.bind("trap"))
	if _place_item:
		_place_item.pressed.connect(handler.bind("item"))
	if _place_ground:
		_place_ground.pressed.connect(handler.bind("ground"))
	if _place_wall:
		_place_wall.pressed.connect(handler.bind("wall"))
	if _place_slope_left:
		_place_slope_left.pressed.connect(handler.bind("slope_left"))
	if _place_slope_right:
		_place_slope_right.pressed.connect(handler.bind("slope_right"))
