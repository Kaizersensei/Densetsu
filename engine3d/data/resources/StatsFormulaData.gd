extends Resource
class_name StatsFormulaData

@export_category("Identity")
@export var id: String = ""
@export var description: String = ""

@export_category("Vital Conversions")
@export var hp_per_strength: float = 0.0
@export var mp_per_intelligence: float = 0.0
@export var hp_per_defense: float = 0.0
@export var mp_per_luck: float = 0.0

@export_category("Offense")
@export var attack_per_strength: float = 0.0
@export var magic_per_intelligence: float = 0.0
@export var accuracy_per_agility: float = 0.0
@export var crit_per_luck: float = 0.0

@export_category("Defense")
@export var defense_per_strength: float = 0.0
@export var resistance_per_intelligence: float = 0.0
@export var evasion_per_agility: float = 0.0
