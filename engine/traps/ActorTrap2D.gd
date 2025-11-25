extends StaticBody2D

@export var damage: int = 1
@export var knockback: Vector2 = Vector2.ZERO
@export var element: int = 0
@export var active: bool = true
@export var one_shot: bool = false
@export var cooldown: float = 0.0

var _cooldown_timer: float = 0.0
@onready var _damage_area: Area2D = $DamageArea

func _ready() -> void:
	if _damage_area:
		_damage_area.body_entered.connect(_on_damage_area_body_entered)
		_damage_area.area_entered.connect(_on_damage_area_area_entered)


func _physics_process(delta: float) -> void:
	if not active and cooldown > 0.0:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			active = true


func _on_damage_area_body_entered(body: Node) -> void:
	if not active:
		return
	_apply_trap_effect(body)


func _on_damage_area_area_entered(area: Area2D) -> void:
	if not active:
		return
	_apply_trap_effect(area)


func _apply_trap_effect(target: Node) -> void:
	print("Trap triggered on:", target)
	if one_shot:
		active = false
	elif cooldown > 0.0:
		_cooldown_timer = cooldown
		active = false
