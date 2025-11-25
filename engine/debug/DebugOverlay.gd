extends Node2D

@export var player_path: NodePath

var _show_debug := false
var _player: CharacterBody2D

func _ready() -> void:
	_player = get_node_or_null(player_path)
	set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			_show_debug = !_show_debug
			get_tree().debug_collisions_hint = _show_debug
			set_process(_show_debug)
			queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not _show_debug:
		return
	if not is_instance_valid(_player):
		return
	var origin := _player.global_position
	var vel := _player.velocity
	draw_circle(origin, 4.0, Color(0, 1, 1))
	draw_line(origin, origin + vel * 0.1, Color(1, 0, 0), 2.0)
