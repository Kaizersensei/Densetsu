@tool
extends ActorCharacter3D


func _uses_actor_camera() -> bool:
	return true


func _ready() -> void:
	actor_role = ActorCharacter3D.ActorRole.PLAYER
	controller_type = ActorCharacter3D.ControllerType.PLAYER
	super._ready()
