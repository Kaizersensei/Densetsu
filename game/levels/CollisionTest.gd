extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var projectile_scene: PackedScene = preload("res://engine/projectiles/ActorProjectile2D.tscn")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("fire_projectile"):
		_fire_projectile()


func _fire_projectile() -> void:
	if not is_instance_valid(player):
		return
	var projectile := projectile_scene.instantiate() as Area2D
	var dir := 1.0
	if "get_facing_dir" in player:
		dir = player.get_facing_dir()
	projectile.global_position = player.global_position + Vector2(dir * 12.0, -6.0)
	projectile.velocity = Vector2(projectile.speed * dir, 0.0)
	projectile.owner_id = player.get_instance_id()
	add_child(projectile)
