extends Resource
class_name StatusEffectData

@export var id: String = ""
@export var name: String = ""
@export var type: String = ""
@export var duration: float = 0.0
@export var max_stacks: int = 0
@export var tick_interval: float = 0.0
@export var tick_damage: float = 0.0
@export var stat_modifiers: Dictionary = {}
@export var movement_modifiers: Dictionary = {}
@export var control_modifiers: Dictionary = {}
@export var visual_fx_id: String = ""
@export var sound_fx_id: String = ""
@export var is_dispersed_by_cleanse: bool = true
@export var is_temporal: bool = false
@export var ignore_invulnerability: bool = false
@export var applies_knockback: bool = false
