extends Area2D
class_name Teleporter2D

@export var data_id: String = ""
@export var exit_only: bool = false
@export var activation_mode: String = "collision" # collision | input
@export var activation_action: String = "interact"
@export var destination_scene: PackedScene
@export var dropoff_mode: String = "right_edge" # left_edge | right_edge | top_edge | bottom_edge
@export var dropoff_target: String = ""
@export var dropoff_margin: float = 960.0
@export var tint: Color = Color(0.4, 0.6, 1.0, 0.25)

var _overlapping: Array[Node] = []
var _cooldown: Dictionary = {}
const TELEPORT_INTERVAL_MS := 200

func _ready() -> void:
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("teleporters")
	_apply_tint()


func _process(_delta: float) -> void:
	if activation_mode != "input":
		return
	for b in _overlapping:
		if not is_instance_valid(b):
			continue
		if Input.is_action_just_pressed(activation_action):
			_try_teleport(b)


func _on_body_entered(body: Node) -> void:
	if body == null or not is_instance_valid(body):
		return
	if exit_only:
		return
	_overlapping.append(body)
	if activation_mode == "collision":
		_try_teleport(body)


func _on_body_exited(body: Node) -> void:
	_overlapping.erase(body)


func _try_teleport(body: Node) -> void:
	if body == null or not is_instance_valid(body):
		return
	var now: int = Time.get_ticks_msec()
	var last: int = _cooldown.get(body.get_instance_id(), 0)
	if now - last < TELEPORT_INTERVAL_MS:
		return
	_cooldown[body.get_instance_id()] = now

	var target_pos := _compute_dropoff(body)
	if body is Node2D:
		(body as Node2D).global_position = target_pos
		if "velocity" in body:
			body.set("velocity", Vector2.ZERO)
	_overlapping.erase(body)


func _compute_dropoff(body: Node) -> Vector2:
	var target := _find_target_teleporter()
	if target == null:
		target = self
	var dir := Vector2.RIGHT
	match dropoff_mode:
		"left_edge":
			dir = Vector2.LEFT
		"right_edge":
			dir = Vector2.RIGHT
		"top_edge":
			dir = Vector2.UP
		"bottom_edge":
			dir = Vector2.DOWN
		_:
			dir = Vector2.RIGHT
	return target.global_position + _edge_safe_offset(dir, target)


func _edge_safe_offset(dir: Vector2, t: Teleporter2D) -> Vector2:
	var extent := Vector2(32, 48)
	var cs := t.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs and cs.shape is RectangleShape2D:
		var rs := cs.shape as RectangleShape2D
		extent = rs.size * 0.5
	var safety := 12.0
	var extra: float = max(dropoff_margin, 0.0)
	var dist: float = max(extent.x, extent.y) + safety + extra
	return dir.normalized() * dist


func _find_target_teleporter() -> Teleporter2D:
	var tele_list := get_tree().get_nodes_in_group("teleporters")
	for t in tele_list:
		if t == self:
			continue
		if not (t is Teleporter2D):
			continue
		var id := ""
		if "data_id" in t:
			var dv = t.get("data_id")
			if dv is String:
				id = dv
		if id == "" and t.has_meta("data_id"):
			var mv = t.get_meta("data_id")
			if mv is String:
				id = mv
		if dropoff_target != "" and (t.name == dropoff_target or id == dropoff_target):
			return t
		if dropoff_target == "" and id != "":
			return t
	return null


func _apply_tint() -> void:
	var poly := get_node_or_null("Visual") as Polygon2D
	var spr := get_node_or_null("Sprite2D") as Sprite2D
	if poly:
		poly.color = tint
	if spr:
		spr.modulate = tint
