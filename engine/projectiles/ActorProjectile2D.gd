extends Area2D

@export var speed: float = 300.0
@export var lifetime: float = 3.0
@export var gravity_force: float = 0.0
@export var damage: int = 1
@export var knockback: Vector2 = Vector2.ZERO
@export var owner_id: int = -1
@export var element: int = 0
@export var pierce_count: int = 0

var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	if gravity_force != 0.0:
		velocity.y += gravity_force * delta

	global_position += velocity * delta


func _on_body_entered(body: Node) -> void:
	if _is_owner(body):
		return
	if body.is_in_group("items"):
		return
	_apply_hit_to(body)
	_on_impact()


func _on_area_entered(area: Area2D) -> void:
	if _is_owner(area):
		return
	if area.is_in_group("items"):
		return
	_apply_hit_to(area)
	_on_impact()


func _is_owner(node: Node) -> bool:
	return node != null and node.get_instance_id() == owner_id


func _apply_hit_to(target: Node) -> void:
	# Placeholder hook for combat/stats system.
	print("Projectile hit:", target, "owner:", owner_id, "damage:", damage)


func _on_impact() -> void:
	if pierce_count > 0:
		pierce_count -= 1
	if pierce_count <= 0:
		queue_free()
