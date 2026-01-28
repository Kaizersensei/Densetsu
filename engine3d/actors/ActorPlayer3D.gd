@tool
extends ActorCharacter3D


func _ready() -> void:
	actor_role = ActorCharacter3D.ActorRole.PLAYER
	controller_type = ActorCharacter3D.ControllerType.PLAYER
	super._ready()
