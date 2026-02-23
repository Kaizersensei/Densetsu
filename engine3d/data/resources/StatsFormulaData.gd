extends Resource
class_name StatsFormulaData

@export_category("Identity")
## Controls id.
@export var id: String = ""
## Controls description.
@export var description: String = ""

@export_category("Vital Conversions")
## Controls hp per strength.
@export var hp_per_strength: float = 0.0
## Controls mp per intelligence.
@export var mp_per_intelligence: float = 0.0
## Controls hp per defense.
@export var hp_per_defense: float = 0.0
## Controls mp per luck.
@export var mp_per_luck: float = 0.0

@export_category("Offense")
## Controls attack per strength.
@export var attack_per_strength: float = 0.0
## Controls magic per intelligence.
@export var magic_per_intelligence: float = 0.0
## Controls accuracy per agility.
@export var accuracy_per_agility: float = 0.0
## Controls crit per luck.
@export var crit_per_luck: float = 0.0

@export_category("Defense")
## Controls defense per strength.
@export var defense_per_strength: float = 0.0
## Controls resistance per intelligence.
@export var resistance_per_intelligence: float = 0.0
## Controls evasion per agility.
@export var evasion_per_agility: float = 0.0
