extends Resource
class_name StatsData

@export_category("Identity")
@export var id: String = ""
@export var description: String = ""

@export_category("Vitals")
@export var level: int = 1
@export var xp_value: int = 0
@export var hp: int = 0
@export var max_hp: int = 0
@export var mp: int = 0
@export var max_mp: int = 0

@export_category("Base Stats")
@export var strength: int = 0
@export var defense: int = 0
@export var agility: int = 0
@export var intelligence: int = 0
@export var luck: int = 0

@export_category("Elements")
# Elemental power/defense (defense 0-200; >100 implies absorption, see absorb flags)
@export var elem_fire_power: int = 0
@export var elem_fire_def: int = 0
@export var elem_fire_absorb_hp: bool = true
@export var elem_fire_absorb_mp: bool = false
@export var elem_water_power: int = 0
@export var elem_water_def: int = 0
@export var elem_water_absorb_hp: bool = true
@export var elem_water_absorb_mp: bool = false
@export var elem_earth_power: int = 0
@export var elem_earth_def: int = 0
@export var elem_earth_absorb_hp: bool = true
@export var elem_earth_absorb_mp: bool = false
@export var elem_wind_power: int = 0
@export var elem_wind_def: int = 0
@export var elem_wind_absorb_hp: bool = true
@export var elem_wind_absorb_mp: bool = false
@export var elem_light_power: int = 0
@export var elem_light_def: int = 0
@export var elem_light_absorb_hp: bool = true
@export var elem_light_absorb_mp: bool = false
@export var elem_dark_power: int = 0
@export var elem_dark_def: int = 0
@export var elem_dark_absorb_hp: bool = true
@export var elem_dark_absorb_mp: bool = false
@export var elem_thunder_power: int = 0
@export var elem_thunder_def: int = 0
@export var elem_thunder_absorb_hp: bool = true
@export var elem_thunder_absorb_mp: bool = false
@export var elem_gaea_power: int = 0
@export var elem_gaea_def: int = 0
@export var elem_gaea_absorb_hp: bool = true
@export var elem_gaea_absorb_mp: bool = false
@export var elem_timespace_power: int = 0
@export var elem_timespace_def: int = 0
@export var elem_timespace_absorb_hp: bool = true
@export var elem_timespace_absorb_mp: bool = false

@export_category("Skills")
# Combat skill proficiencies (integers)
@export var skill_unarmed: int = 0
@export var skill_armed: int = 0
@export var skill_ranged: int = 0
@export var skill_finesse: int = 0
@export var skill_stealth: int = 0
