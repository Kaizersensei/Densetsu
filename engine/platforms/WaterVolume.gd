extends Area2D
class_name WaterVolume

@export var tint: Color = Color(0.4, 0.8, 1.0, 0.25)
var _inside: Dictionary = {}

func _ready() -> void:
	monitoring = true
	monitorable = true
	add_to_group("water_volume")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_sync_polygon_to_shape()
	_apply_tint()


func _on_body_entered(body: Node) -> void:
	var id := body.get_instance_id()
	_inside[id] = _inside.get(id, 0) + 1
	_mark_in_water(body, true)


func _on_body_exited(body: Node) -> void:
	var id := body.get_instance_id()
	if _inside.has(id):
		_inside[id] -= 1
		if _inside[id] <= 0:
			_inside.erase(id)
			_mark_in_water(body, false)
	else:
		_mark_in_water(body, false)


func _mark_in_water(body: Node, flag: bool) -> void:
	if body == null or not is_instance_valid(body):
		return
	if _has_property(body, "in_water"):
		body.set("in_water", flag)


func _has_property(obj: Object, name: String) -> bool:
	if obj == null:
		return false
	for p in obj.get_property_list():
		if p.name == name:
			return true
	return false


func _sync_polygon_to_shape() -> void:
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var poly := get_node_or_null("Visual") as Polygon2D
	if cs and cs.shape is RectangleShape2D and poly:
		var half := (cs.shape as RectangleShape2D).size * 0.5
		poly.polygon = PackedVector2Array(
			[
				Vector2(-half.x, -half.y),
				Vector2(half.x, -half.y),
				Vector2(half.x, half.y),
				Vector2(-half.x, half.y),
			]
		)


func _apply_tint() -> void:
	var poly := get_node_or_null("Visual") as Polygon2D
	if poly:
		poly.color = tint
