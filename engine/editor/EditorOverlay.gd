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
@onready var _data_button: Button = $Ribbon/Data
@onready var _polygon_button: Button = $Ribbon/Polygon
@onready var _poly_use_button: Button = $PolygonToolbar/PolygonButtons/UsePolygon
@onready var _poly_cancel_button: Button = $PolygonToolbar/PolygonButtons/CancelPolygon
@onready var _polygon_toolbar: Control = $PolygonToolbar
@onready var _save_panel: Panel = $SavePanel
@onready var _save_path: LineEdit = $SavePanel/SaveRoot/SavePathRow/SavePath
@onready var _save_filename: LineEdit = $SavePanel/SaveRoot/SaveFilenameRow/SaveFilename
@onready var _save_list: ItemList = $SavePanel/SaveRoot/SaveList
@onready var _save_confirm: Button = $SavePanel/SaveRoot/SaveButtons/SaveConfirm
@onready var _save_cancel: Button = $SavePanel/SaveRoot/SaveButtons/SaveCancel
@onready var _save_dialog: FileDialog = $SavePanel/SaveDialog
@onready var _load_panel: Panel = $LoadPanel
@onready var _load_path: LineEdit = $LoadPanel/LoadRoot/LoadPathRow/LoadPath
@onready var _load_list: ItemList = $LoadPanel/LoadRoot/LoadList
@onready var _load_confirm: Button = $LoadPanel/LoadRoot/LoadButtons/LoadConfirm
@onready var _load_cancel: Button = $LoadPanel/LoadRoot/LoadButtons/LoadCancel
@onready var _load_dialog: FileDialog = $LoadPanel/LoadDialog
@onready var _modal_blocker: ColorRect = $ModalBlocker
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
@onready var _rot_reset: Button = $Inspector/RotRow/RotReset
@onready var _scale_x_reset: Button = $Inspector/ScaleXRow/ScaleXReset
@onready var _scale_y_reset: Button = $Inspector/ScaleYRow/ScaleYReset
@onready var _proj_collide: CheckBox = $Inspector/ProjRow/ProjCollide
@onready var _proj_apply: Button = $Inspector/ProjRow/ProjApply
@onready var _place_player: Button = $SidebarLeft/PrefabList/PrefabTabs/Actors/PlacePlayer
@onready var _place_enemy: Button = $SidebarLeft/PrefabList/PrefabTabs/Actors/PlaceEnemy
@onready var _place_npc: Button = $SidebarLeft/PrefabList/PrefabTabs/Actors/PlaceNPC
@onready var _place_trap: Button = $SidebarLeft/PrefabList/PrefabTabs/Actors/PlaceTrap
@onready var _place_spawner: Button = $SidebarLeft/PrefabList/PrefabTabs/Actors/PlaceSpawner
@onready var _place_item: Button = $SidebarLeft/PrefabList/PrefabTabs/Actors/PlaceItem
@onready var _place_solid: Button = $SidebarLeft/PrefabList/PrefabTabs/Building/PlaceSolid
@onready var _place_one_way: Button = $SidebarLeft/PrefabList/PrefabTabs/Building/PlaceOneWay
@onready var _place_deco: Button = $SidebarLeft/PrefabList/PrefabTabs/Building/PlaceDeco
@onready var _place_deco_solid: Button = $SidebarLeft/PrefabList/PrefabTabs/Building/PlaceDecoSolid
@onready var _place_polygon: Button = $SidebarLeft/PrefabList/PrefabTabs/Building/PlacePolygon
@onready var _delete_button: Button = $SidebarLeft/PrefabList/DeleteButton
@onready var _close_panels: Button = $Ribbon/ClosePanels

var _inspector_signal_block := false
var _prefab_handler: Callable = Callable()
var _window_controller: Node = null
var _ribbon_hidden: Array[Control] = []
var _panel_buttons: Array[Control] = []
var _current_panel: String = ""
var _data_panel: Control = null
@onready var _hover_label: Label = $Ribbon/HoverLabel

func set_editor_mode(active: bool) -> void:
	visible = active
	if _status:
		_status.text = "EDITOR MODE" if active else "GAME"


func set_selection_name(name: String) -> void:
	if _selection:
		_selection.text = "Selected: %s" % name

func set_status(text: String) -> void:
	if _status:
		_status.text = text


func set_footer(text: String) -> void:
	if has_node("Footer"):
		var footer := get_node("Footer")
		if footer and footer is Control:
			footer.position = Vector2(0, get_viewport().get_visible_rect().size.y - footer.size.y - 12)
			footer.visible = text != ""
			var lbl := footer.get_node_or_null("FooterLabel")
			if lbl and lbl is Label:
				lbl.text = text

func set_hover_info(text: String, pos: Vector2 = Vector2.ZERO) -> void:
	# Suppress hover tips while any panel is open
	if _current_panel != "":
		if has_node("HoverTip"):
			var tip := get_node("HoverTip") as Control
			if tip:
				tip.visible = false
		if _hover_label:
			_hover_label.text = ""
		return
	if _hover_label:
		_hover_label.text = ""
	if has_node("HoverTip"):
		var tip := get_node("HoverTip")
		if tip and tip is Control:
			var lbl := tip.get_node_or_null("HoverTipLabel")
			if lbl and lbl is Label:
				(lbl as Label).text = text
			tip.visible = text != "" and text != "Hover: None"
			if tip.visible:
				var offset := Vector2(12, 12)
				var target := pos + offset
				var vr := get_viewport().get_visible_rect()
				var tip_size: Vector2 = tip.size
				target.x = clamp(target.x, 0.0, vr.size.x - tip_size.x)
				target.y = clamp(target.y, 0.0, vr.size.y - tip_size.y)
				tip.position = target


func get_snap_enabled() -> bool:
	return _snap_toggle.button_pressed if _snap_toggle else false


func get_snap_size() -> float:
	if _snap_size:
		var v := float(_snap_size.text)
		return max(v, 0.1)
	return 8.0


func populate_inspector(node: Node) -> void:
	# deprecated; using right-side inspector strip instead
	pass


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
	if _rot_reset:
		_rot_reset.pressed.connect(handler.bind("rot_reset"))
	if _scale_x:
		_scale_x.text_submitted.connect(handler.bind("scale_x"))
		_scale_x.focus_exited.connect(handler.bind("scale_x", _scale_x.text))
	if _scale_x_apply:
		_scale_x_apply.pressed.connect(handler.bind("scale_x"))
	if _scale_x_reset:
		_scale_x_reset.pressed.connect(handler.bind("scale_x_reset"))
	if _scale_y:
		_scale_y.text_submitted.connect(handler.bind("scale_y"))
		_scale_y.focus_exited.connect(handler.bind("scale_y", _scale_y.text))
	if _scale_y_apply:
		_scale_y_apply.pressed.connect(handler.bind("scale_y"))
	if _scale_y_reset:
		_scale_y_reset.pressed.connect(handler.bind("scale_y_reset"))
	if _proj_apply and _proj_collide:
		_proj_apply.pressed.connect(handler.bind("proj_collide"))

func connect_prefab_buttons(handler: Callable) -> void:
	_prefab_handler = handler
	if _delete_button:
		_delete_button.pressed.connect(handler.bind("delete"))
	if _polygon_button:
		_polygon_button.pressed.connect(handler.bind("edit_polygon"))
	if _poly_use_button:
		_poly_use_button.pressed.connect(handler.bind("use_polygon"))
	if _poly_cancel_button:
		_poly_cancel_button.pressed.connect(handler.bind("cancel_polygon"))
	if _close_panels:
		_close_panels.pressed.connect(handler.bind("close_panels"))
	if _place_player:
		_place_player.pressed.connect(handler.bind("player"))
	if _place_enemy:
		_place_enemy.pressed.connect(handler.bind("enemy"))
	if _place_npc:
		_place_npc.pressed.connect(handler.bind("npc"))
	if _place_deco:
		_place_deco.pressed.connect(handler.bind("deco"))
	if _place_deco_solid:
		_place_deco_solid.pressed.connect(handler.bind("deco_solid"))
	if _place_trap:
		_place_trap.pressed.connect(handler.bind("trap"))
	if _place_spawner:
		_place_spawner.pressed.connect(handler.bind("spawner"))
	if _place_item:
		_place_item.pressed.connect(handler.bind("item"))
	if _place_solid:
		_place_solid.pressed.connect(handler.bind("solid"))
	if _place_one_way:
		_place_one_way.pressed.connect(handler.bind("one_way"))
	if _place_polygon:
		_place_polygon.pressed.connect(handler.bind("polygon"))
	if _undo_button:
		_undo_button.pressed.connect(handler.bind("undo"))
	if _redo_button:
		_redo_button.pressed.connect(handler.bind("redo"))
	if _save_button:
		_save_button.pressed.connect(_open_save_panel)
	if _load_button:
		_load_button.pressed.connect(_open_load_panel)
	if _data_button:
		_data_button.pressed.connect(_open_data_panel)
	if _reload_button:
		_reload_button.pressed.connect(handler.bind("reload"))
	if _save_confirm:
		_save_confirm.pressed.connect(_on_save_confirm)
	if _save_cancel:
		_save_cancel.pressed.connect(_on_save_cancel)
	if _save_dialog:
		_save_dialog.file_selected.connect(_on_save_dialog_selected)
		_save_dialog.canceled.connect(_on_save_cancel)
	if _load_confirm:
		_load_confirm.pressed.connect(_on_load_confirm)
	if _load_cancel:
		_load_cancel.pressed.connect(_on_load_cancel)
	if _load_dialog:
		_load_dialog.file_selected.connect(_on_load_dialog_selected)
		_load_dialog.canceled.connect(_on_load_cancel)
	if _close_panels:
		_close_panels.pressed.connect(func(): _set_active_panel(""))

	# Tooltip bindings to feed footer/status
	var tooltip_controls: Array = [
		_undo_button, _redo_button, _save_button, _load_button, _data_button, _polygon_button, _reload_button,
		_snap_toggle, _snap_size, _close_panels, _poly_use_button, _poly_cancel_button,
		_place_player, _place_enemy, _place_npc, _place_trap, _place_spawner, _place_item,
		_place_solid, _place_one_way, _place_deco, _place_deco_solid, _place_polygon, _delete_button,
	]
	for c in tooltip_controls:
		_bind_tooltip(c)
	_ribbon_hidden = []
	for c in [_undo_button, _redo_button, _reload_button, _snap_toggle, _snap_size]:
		if c:
			_ribbon_hidden.append(c)
	_panel_buttons = []
	for c in [_save_button, _load_button, _data_button]:
		if c:
			_panel_buttons.append(c)


func register_popups(controller: Node) -> void:
	_window_controller = controller
	if _window_controller == null:
		return
	if _save_panel:
		_window_controller.call_deferred("register_popup", _save_panel)
	if _load_panel:
		_window_controller.call_deferred("register_popup", _load_panel)
	set_polygon_toolbar_visible(false)
	set_polygon_toolbar_visible(false)


func _open_save_panel() -> void:
	if _save_dialog:
		_save_dialog.current_dir = "res://editor_saves"
		_save_dialog.current_file = "scene.tscn"
		_save_dialog.popup_centered_ratio(0.8)
	else:
		if _current_panel == "save":
			_set_active_panel("")
		else:
			_set_active_panel("save")


func _open_load_panel() -> void:
	if _load_dialog:
		_load_dialog.current_dir = "res://editor_saves"
		_load_dialog.popup_centered_ratio(0.8)
	else:
		if _current_panel == "load":
			_set_active_panel("")
		else:
			_set_active_panel("load")


func _open_data_panel() -> void:
	if _current_panel == "data":
		_set_active_panel("")
	else:
		_set_active_panel("data")
		if has_node("DataEditor"):
			var de := get_node("DataEditor")
			if de.has_method("force_refresh"):
				de.call_deferred("force_refresh")

func _on_save_dialog_canceled() -> void:
	_hide_modal()


func _on_load_dialog_canceled() -> void:
	_hide_modal()


func _set_active_panel(name: String) -> void:
	_current_panel = name
	var ribbon_h := _ribbon.size.y if _ribbon else 0.0
	_hide_modal()
	if name == "":
		var mgr := get_parent()
		if mgr and mgr.has_method("_update_entity_popup"):
			mgr.call("_update_entity_popup", true)
		if mgr and mgr.has_method("_overlay_closed"):
			mgr.call("_overlay_closed")
		set_polygon_toolbar_visible(false)
		_highlight_panel_buttons("")
		return
	var panel: Control = null
	if name == "save":
		panel = _save_panel
	elif name == "load":
		panel = _load_panel
	elif name == "data":
		if _data_panel == null:
			_data_panel = get_node_or_null("DataEditor") as Control
		panel = _data_panel
	elif name == "polygon":
		panel = _polygon_toolbar
	if panel:
		_current_panel = name
		var use_blocker := name != "data" and name != "polygon"
		if name == "polygon":
			panel.anchor_left = 0
			panel.anchor_top = 0
			panel.anchor_right = 1
			panel.anchor_bottom = 0
			panel.offset_left = 0
			panel.offset_right = 0
			panel.offset_top = ribbon_h
			var desired_h: float = max(panel.size.y, 32.0)
			panel.offset_bottom = ribbon_h + desired_h
		else:
			panel.anchor_left = 0
			panel.anchor_top = 0
			panel.anchor_right = 1
			panel.anchor_bottom = 1
			panel.offset_left = 0
			panel.offset_right = 0
			panel.offset_top = ribbon_h
			panel.offset_bottom = 0
		panel.visible = true
		panel.z_index = 1000
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		if name == "polygon":
			set_polygon_toolbar_visible(true)
			_hide_ribbon_buttons(false)
		_highlight_panel_buttons(name)
		if _modal_blocker:
			if use_blocker:
				_modal_blocker.visible = true
				_modal_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
				_modal_blocker.anchor_left = 0
				_modal_blocker.anchor_top = 0
				_modal_blocker.anchor_right = 1
				_modal_blocker.anchor_bottom = 1
				_modal_blocker.offset_left = 0
				_modal_blocker.offset_right = 0
				_modal_blocker.offset_top = ribbon_h
				_modal_blocker.offset_bottom = 0
			else:
				_modal_blocker.visible = false
				_modal_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if name != "polygon":
			_hide_ribbon_buttons(true)
	var mgr := get_parent()
	if mgr and mgr.has_method("_update_entity_popup"):
		mgr.call("_update_entity_popup", true)


func _on_save_confirm() -> void:
	if _save_dialog:
		_save_dialog.popup_centered_ratio(0.8)
		return
	if _prefab_handler.is_valid():
		var path := (_save_path.text + "/" + _save_filename.text).strip_edges()
		_prefab_handler.call("save_path", path)
	_hide_modal()


func _on_load_confirm() -> void:
	if _load_dialog:
		_load_dialog.popup_centered_ratio(0.8)
		return
	if _prefab_handler.is_valid():
		var items := _load_list.get_selected_items()
		var fname := ""
		if items.size() > 0:
			fname = _load_list.get_item_text(items[0])
		var path := (_load_path.text + "/" + fname).strip_edges()
		_prefab_handler.call("load_path", path)
	_hide_modal()


func _on_save_cancel() -> void:
	_hide_modal()


func _on_load_cancel() -> void:
	_hide_modal()


func _on_save_dialog_selected(path: String) -> void:
	if _prefab_handler.is_valid():
		_prefab_handler.call("save_path", path)
	_hide_modal()


func _on_load_dialog_selected(path: String) -> void:
	if _prefab_handler.is_valid():
		_prefab_handler.call("load_path", path)
	_hide_modal()


func _show_modal(panel: Control) -> void:
	_hide_modal()
	var ribbon_h := _ribbon.size.y if _ribbon else 0.0
	if _modal_blocker:
		_modal_blocker.visible = true
		_modal_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		_modal_blocker.anchor_left = 0
		_modal_blocker.anchor_top = 0
		_modal_blocker.anchor_right = 1
		_modal_blocker.anchor_bottom = 1
		_modal_blocker.offset_left = 0
		_modal_blocker.offset_right = 0
		_modal_blocker.offset_top = ribbon_h
		_modal_blocker.offset_bottom = 0
	if panel:
		panel.anchor_left = 0
		panel.anchor_top = 0
		panel.anchor_right = 1
		panel.anchor_bottom = 1
		panel.offset_left = 0
		panel.offset_right = 0
		panel.offset_top = ribbon_h
		panel.offset_bottom = 0
		panel.visible = true
		_hide_ribbon_buttons(true)


func _hide_modal() -> void:
	if _modal_blocker:
		_modal_blocker.visible = false
		_modal_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _save_panel:
		_save_panel.visible = false
	if _load_panel:
		_load_panel.visible = false
	if _save_dialog:
		_save_dialog.hide()
	if _load_dialog:
		_load_dialog.hide()
	if _data_panel:
		_data_panel.visible = false
	set_polygon_toolbar_visible(false)
	_current_panel = ""
	_hide_ribbon_buttons(false)
	_highlight_panel_buttons("")
	if get_tree():
		var mgr := get_tree().root.get_node_or_null("EditorManager")
		if mgr and mgr.has_method("_update_entity_popup"):
			mgr.call_deferred("_update_entity_popup")


func _hide_ribbon_buttons(hide: bool) -> void:
	for c in _ribbon_hidden:
		if c:
			c.visible = not hide
	for c in _panel_buttons:
		if c:
			c.visible = true


func _highlight_panel_buttons(active: String) -> void:
	var highlight := Color(1, 1, 0.3, 1)
	var normal := Color(1, 1, 1, 1)
	var pairs := {
		"save": _save_button,
		"load": _load_button,
		"data": _data_button,
		"polygon": _polygon_button,
	}
	for key in pairs.keys():
		var btn: Control = pairs[key]
		if btn:
			btn.self_modulate = highlight if key == active else normal


func _bind_tooltip(ctrl: Control) -> void:
	if ctrl == null:
		return
	ctrl.mouse_entered.connect(func():
		var tip := ctrl.tooltip_text
		if tip == "" and "text" in ctrl:
			tip = str(ctrl.text)
		set_status(tip)
	)
	ctrl.mouse_exited.connect(func():
		set_status("")
	)


func set_polygon_toolbar_visible(visible: bool) -> void:
	if _polygon_toolbar:
		_polygon_toolbar.visible = visible
	if _poly_use_button:
		_poly_use_button.visible = visible
	if _poly_cancel_button:
		_poly_cancel_button.visible = visible
