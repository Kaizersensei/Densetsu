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

var _inspector_signal_block := false

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
