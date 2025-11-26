extends Node

class_name StatsComponent

signal stat_changed(stat_name: String, new_value: float)
signal died(source_id: int)

@export var max_hp: float = 10.0
@export var max_mp: float = 0.0
@export var strength: float = 1.0
@export var defense: float = 0.0
@export var agility: float = 1.0
@export var intelligence: float = 1.0
@export var luck: float = 1.0
@export var xp_value: float = 0.0

var hp: float
var mp: float

func _ready() -> void:
	hp = max_hp
	mp = max_mp


func apply_damage(amount: float, source_id: int = -1) -> void:
	hp = max(hp - amount, 0.0)
	emit_signal("stat_changed", "hp", hp)
	if hp <= 0.0:
		emit_signal("died", source_id)


func heal(amount: float) -> void:
	hp = clamp(hp + amount, 0.0, max_hp)
	emit_signal("stat_changed", "hp", hp)
