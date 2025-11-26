extends Node2D

@export var enabled: bool = true
@export var snap_size: float = 8.0
@export var tile_color: Color = Color(0.6, 0.6, 0.6, 0.3)

var editor_camera: Camera2D
var _tiles: Dictionary = {}
var _last_cam_pos: Vector2 = Vector2.INF
var _last_zoom: Vector2 = Vector2.ZERO
var _last_snap: float = 0.0
var _redraw_cooldown: float = 0.0
@export var redraw_interval := 0.25

func _ready() -> void:
	set_process(true)
	_prebuild_tiles()


func _process(delta: float) -> void:
	if not enabled or snap_size <= 0.0 or editor_camera == null:
		visible = false
		return
	visible = true
	_redraw_cooldown = max(_redraw_cooldown - delta, 0.0)
	if _should_redraw():
		_last_cam_pos = editor_camera.global_position
		_last_zoom = editor_camera.zoom
		_last_snap = snap_size
		_redraw_cooldown = redraw_interval
		queue_redraw()


func _draw() -> void:
	if not enabled or snap_size <= 0.0 or editor_camera == null:
		return
	var tex := _get_tile_for_snap(snap_size)
	if tex == null:
		return
	var vp_size: Vector2 = get_viewport_rect().size
	var zoom: Vector2 = editor_camera.zoom
	var tile_size: Vector2 = tex.get_size() * zoom
	var origin: Vector2 = editor_camera.global_position - (vp_size * 0.5) * zoom
	var end: Vector2 = origin + vp_size * zoom
	var start_x: float = floor(origin.x / tile_size.x) * tile_size.x
	var start_y: float = floor(origin.y / tile_size.y) * tile_size.y
	var x: float = start_x
	while x < end.x:
		var y: float = start_y
		while y < end.y:
			draw_texture(tex, Vector2(x, y), tile_color)
			y += tile_size.y
		x += tile_size.x


func _prebuild_tiles() -> void:
	var sizes = [4, 8, 16, 32, 64]
	for s in sizes:
		var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		img.set_pixel(0, 0, Color.WHITE)
		var tex := ImageTexture.create_from_image(img)
		_tiles[str(s)] = tex


func _get_tile_for_snap(value: float) -> Texture2D:
	var sizes = [4, 8, 16, 32, 64]
	var nearest: int = sizes[0]
	for s in sizes:
		if absf(value - s) < absf(value - nearest):
			nearest = s
	return _tiles.get(str(nearest), null)


func _should_redraw() -> bool:
	if _redraw_cooldown > 0.0:
		return false
	if snap_size != _last_snap:
		return true
	if _last_cam_pos == Vector2.INF:
		return true
	var cam_delta := (editor_camera.global_position - _last_cam_pos).length()
	if cam_delta > snap_size * 0.5:
		return true
	if _last_zoom != editor_camera.zoom:
		return true
	return false
