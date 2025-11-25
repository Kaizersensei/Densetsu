extends Area2D

@export var respawn_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		var actor := body as CharacterBody2D
		actor.global_position = respawn_position
		actor.velocity = Vector2.ZERO
	print("KillZone triggered by:", body)
