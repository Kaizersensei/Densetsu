extends Node2D

@export var deco_id: String = ""
@export var tint: Color = Color(1, 1, 1)

func _ready() -> void:
	if has_node("Sprite2D"):
		$Sprite2D.modulate = tint
