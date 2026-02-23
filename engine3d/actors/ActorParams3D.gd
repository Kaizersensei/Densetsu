@tool
extends Node
class_name ActorParams3D

@export_category("Ids")
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

@export_category("Resources")
## Controls movement data.
@export var movement_data: MovementData3D
## Controls model data.
@export var model_data: ModelData3D
## Controls camera data.
@export var camera_data: CameraRigData3D
## Controls stats data.
@export var stats_data: StatsData
## Controls formulas data.
@export var formulas_data: StatsFormulaData
