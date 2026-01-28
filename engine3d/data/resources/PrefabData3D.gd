extends Resource
class_name PrefabData3D

@export_category("Identity")
@export var id: String = ""
@export var name: String = ""
@export var category: String = ""

@export_category("Prefab")
@export var prefab_path: String = ""
@export var allowed_overrides: Array = []

@export_category("Overrides")
@export var movement_id: String = ""
@export var model_id: String = ""
@export var camera_id: String = ""
@export var stats_id: String = ""
@export var formulas_id: String = ""
