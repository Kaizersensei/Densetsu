extends Node

var _popups: Array[Node] = []
var top_margin: float = 0.0

func register_popup(win: Node) -> void:
	if win == null:
		return
	if not _popups.has(win):
		_popups.append(win)
	if win is Window:
		var w: Window = win
		w.always_on_top = true
	elif win is Control:
		var c: Control = win
		c.mouse_filter = Control.MOUSE_FILTER_STOP
	if win.has_signal("gui_input"):
		win.gui_input.connect(_on_popup_gui_input.bind(win), CONNECT_DEFERRED)


func show_popup(win: Node, ratio: float = 0.9) -> void:
	if win == null:
		return
	var was_visible := false
	if win is Control:
		was_visible = (win as Control).visible
	elif win is Window:
		was_visible = (win as Window).visible
	_hide_all()
	if was_visible:
		return
	if win is Window:
		var w := win as Window
		var rect := w.get_viewport().get_visible_rect()
		if ratio > 0.0:
			w.popup_centered_ratio(ratio)
		else:
			var pos := Vector2(rect.position.x, rect.position.y + top_margin)
			var size := Vector2(rect.size.x, max(0.0, rect.size.y - top_margin))
			w.position = pos
			w.size = size
			w.show()
	elif win is Control:
		var c := win as Control
		c.anchor_left = 0
		c.anchor_top = 0
		c.anchor_right = 1
		c.anchor_bottom = 1
		c.offset_left = 0
		c.offset_right = 0
		c.offset_top = top_margin
		c.offset_bottom = 0
		c.visible = true
	if win.has_method("move_to_front"):
		win.move_to_front()


func hide_popup(win: Node) -> void:
	if win == null:
		return
	if win is Control:
		(win as Control).hide()
	elif win is Window:
		(win as Window).hide()


func _hide_all() -> void:
	for other in _popups:
		if not is_instance_valid(other):
			continue
		if other is Control:
			(other as Control).visible = false
		elif other is Window:
			(other as Window).hide()


func is_any_open() -> bool:
	for w in _popups:
		if is_instance_valid(w) and w.visible:
			return true
	return false


func _on_popup_gui_input(event: InputEvent, win: Node) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			event.accept()
	elif event is InputEventMouseMotion and win:
		# prevent propagation to camera when over popup
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()
