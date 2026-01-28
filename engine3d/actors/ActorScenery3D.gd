@tool
extends ActorCharacter3D


func _ready() -> void:
	actor_role = ActorCharacter3D.ActorRole.SCENERY
	controller_type = ActorCharacter3D.ControllerType.NONE
	super._ready()
