extends Resource
class_name StatsData

@export var id: String = ""
@export var description: String = ""
# Core stat block (explicit fields for editor visibility)
@export var level: int = 1
@export var hp: float = 0.0
@export var mp: float = 0.0
@export var strength: float = 0.0
@export var defense: float = 0.0
@export var agility: float = 0.0
@export var intelligence: float = 0.0
@export var luck: float = 0.0
@export var xp_value: int = 0
# Elemental/offense affinities (0-100 baseline)
@export var elem_fire: float = 0.0
@export var elem_water: float = 0.0
@export var elem_earth: float = 0.0
@export var elem_wind: float = 0.0
@export var elem_light: float = 0.0
@export var elem_dark: float = 0.0
# Skill multipliers
@export var skill_attack: float = 0.0
@export var skill_support: float = 0.0
@export var skill_special: float = 0.0
# Freeform dictionary for derived or extended stats
@export var stats: Dictionary = {}
