@tool
extends ActorCharacter3D


func _ready() -> void:
	actor_role = ActorCharacter3D.ActorRole.NPC
	controller_type = ActorCharacter3D.ControllerType.AI
	super._ready()
