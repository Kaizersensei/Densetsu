extends StaticBody2D
class_name PolygonTerrain2D

@export var vertices: Array[Vector2] = []
@export var template_id: String = "POLY_Default"
@export var border_width: float = 8.0
@export var transition_width: float = 12.0
@export var smoothing_threshold_deg: float = 30.0
@export var smoothing_steps: int = 0
@export var collision_layers_bits: int = 1
@export var collision_mask_bits: int = 1

var _smoothed_vertices: Array[Vector2] = []
var _visual: Polygon2D
var _collision: CollisionPolygon2D
var _show_points := false
var _active_vertex_index := -1

func _ready() -> void:
	_ensure_nodes()
	collision_layer = collision_layers_bits
	collision_mask = collision_mask_bits
	_apply_template()
	_refresh_geometry_from_vertices()


func _apply_template() -> void:
	if not Engine.has_singleton("DataRegistry"):
		return
	var reg = Engine.get_singleton("DataRegistry")
	if reg == null or not reg.has_method("get_resource_for_category"):
		return
	var tmpl: PolygonTemplateData = reg.get_resource_for_category("PolygonTemplate", template_id) as PolygonTemplateData
	if tmpl == null:
		return
	if "border_width" in tmpl:
		border_width = tmpl.border_width
	if "transition_width" in tmpl:
		transition_width = tmpl.transition_width
	if "smoothing_threshold_deg" in tmpl:
		smoothing_threshold_deg = tmpl.smoothing_threshold_deg
	if "smoothing_steps" in tmpl:
		smoothing_steps = tmpl.smoothing_steps
	if tmpl.material_override:
		if _visual:
			_visual.material = tmpl.material_override
		if has_node("Visual"):
			get_node("Visual").material = tmpl.material_override
	# Mesh/shader generation to be added later


func set_vertices(new_vertices: Array[Vector2]) -> void:
	var local_vertices: Array[Vector2] = []
	for v in new_vertices:
		local_vertices.append(v)
	vertices = local_vertices
	_refresh_geometry_from_vertices()
	queue_redraw()


func get_bounds() -> Rect2:
	if vertices.is_empty():
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var minv := vertices[0]
	var maxv := vertices[0]
	for v in vertices:
		minv = minv.min(v)
		maxv = maxv.max(v)
	return Rect2(minv, maxv - minv)


func set_show_points(flag: bool) -> void:
	_show_points = flag
	queue_redraw()


func set_active_vertex_index(idx: int) -> void:
	_active_vertex_index = idx
	queue_redraw()


func _ensure_nodes() -> void:
	_visual = get_node_or_null("Visual") as Polygon2D
	if _visual == null:
		_visual = Polygon2D.new()
		_visual.name = "Visual"
		_visual.color = Color(0.2, 0.7, 1.0, 0.25)
		_visual.antialiased = true
		add_child(_visual)
	_collision = get_node_or_null("Collider") as CollisionPolygon2D
	if _collision == null:
		_collision = CollisionPolygon2D.new()
		_collision.name = "Collider"
		add_child(_collision)


func _refresh_geometry_from_vertices() -> void:
	var poly := PackedVector2Array()
	for v in vertices:
		poly.append(v)
	if _visual:
		_visual.polygon = poly
	# Update collision only if polygon is valid (area > 0 and >=3 points)
	if _collision:
		if poly.size() >= 3 and _is_polygon_valid(poly):
			_collision.polygon = poly
		else:
			_collision.polygon = PackedVector2Array()
	queue_redraw()


func _draw() -> void:
	if not _show_points:
		return
	var font: Font = ThemeDB.fallback_font
	var font_size: int = ThemeDB.fallback_font_size
	var poly := PackedVector2Array()
	for v in vertices:
		poly.append(v)
	var valid := _is_polygon_valid(poly) and poly.size() >= 3
	var line_color := Color(0.4, 0.8, 1.0, 0.9)
	if not valid:
		line_color = Color(1, 0.3, 0.3, 0.9)
	if poly.size() >= 2:
		var pts := []
		for v in poly:
			pts.append(v)
		pts.append(poly[0])
		draw_polyline(PackedVector2Array(pts), line_color, 2.0, true)
	if not valid:
		var center := Vector2.ZERO
		for v in poly:
			center += v
		if poly.size() > 0:
			center /= poly.size()
		if font:
			draw_string(font, center + Vector2(8, -8), "Check point order!", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 0.6, 0.1, 1))
	for i in range(vertices.size()):
		var col := Color(0.9, 0.9, 0.1, 0.9)
		if i == _active_vertex_index:
			col = Color(0.2, 1.0, 0.2, 1.0)
		draw_circle(vertices[i], 3.5, col)
		if font:
			draw_string(font, vertices[i] + Vector2(6, -4), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)


func _is_polygon_valid(poly: PackedVector2Array) -> bool:
	if poly.size() < 3:
		return false
	var area := 0.0
	for i in range(poly.size()):
		var j := (i + 1) % poly.size()
		area += poly[i].x * poly[j].y - poly[j].x * poly[i].y
	return abs(area) > 0.0001
