extends Resource
class_name PrefabData3D

@export_category("Identity")
## Controls id.
@export var id: String = ""
## Controls name.
@export var name: String = ""
## Controls category.
@export var category: String = ""

@export_category("Prefab")
## NodePath to prefab.
@export var prefab_path: String = ""
## Controls allowed overrides.
@export var allowed_overrides: Array = []

@export_category("Overrides")
## Identifier for movement.
@export var movement_id: String = ""
## Identifier for model.
@export var model_id: String = ""
## Identifier for camera.
@export var camera_id: String = ""
## Identifier for stats.
@export var stats_id: String = ""
## Identifier for formulas.
@export var formulas_id: String = ""
