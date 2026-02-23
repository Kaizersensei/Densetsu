@tool
extends StaticBody3D
class_name DensetsuStaticMesh3D

@export_category("Model")
## Controls mesh.
@export var mesh: Mesh:
	set(value):
		mesh = value
		if is_inside_tree():
			_apply_mesh()
## Material used for material override.
@export var material_override: Material:
	set(value):
		material_override = value
		if is_inside_tree():
			_apply_material_override()

@export_category("Materials")
## Material used for surface materials.
@export var surface_materials: Array[Material] = []:
	set(value):
		surface_materials = value
		if is_inside_tree():
			_apply_surface_materials()

@export_category("Rendering")
## Controls cast shadows.
@export var cast_shadows: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_ON:
	set(value):
		cast_shadows = value
		if is_inside_tree():
			_apply_cast_shadows()


func _ready() -> void:
	var meshes := find_children("*", "MeshInstance3D", true, false)
	if meshes.size() > 1:
		return
	_ensure_model()
	_apply_all()


func _ensure_model() -> MeshInstance3D:
	var model := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if model == null:
		var matches := find_children("*", "MeshInstance3D", true, false)
		if not matches.is_empty():
			model = matches[0] as MeshInstance3D
	if model == null:
		model = MeshInstance3D.new()
		model.name = "MeshInstance3D"
		add_child(model)
	if model.owner == null:
		model.owner = self
	return model


func _apply_all() -> void:
	_apply_mesh()
	_apply_material_override()
	_apply_surface_materials()
	_apply_cast_shadows()


func _apply_mesh() -> void:
	var model := _ensure_model()
	if mesh == null and model.mesh != null:
		return
	model.mesh = mesh


func _apply_material_override() -> void:
	var model := _ensure_model()
	if material_override == null:
		return
	model.material_override = material_override


func _apply_surface_materials() -> void:
	var model := _ensure_model()
	if mesh == null:
		return
	var surface_count := mesh.get_surface_count()
	if surface_count <= 0:
		return
	if surface_materials.size() == 0:
		return
	for i in range(surface_count):
		var mat: Material = null
		if i < surface_materials.size():
			mat = surface_materials[i]
		model.set_surface_override_material(i, mat)


func _apply_cast_shadows() -> void:
	var model := _ensure_model()
	model.cast_shadow = cast_shadows
