extends Resource
class_name ItemData

@export var id: String = ""
@export var description: String = ""
@export var sprite: Texture2D
@export var scene: PackedScene
@export var amount: int = 1
@export var auto_pickup: bool = true
@export var float_idle: bool = true
@export var collision_layer: int = 1
@export var collision_mask: int = 1
@export var slots_needed: int = 1
@export var max_stack: int = 99
@export var value: int = 0
@export var is_equippable: bool = false
@export var equip_slot: String = ""
@export var equip_stats: Dictionary = {}
@export var equip_effects: Array = []
@export var is_consumable: bool = false
@export var consume_effects: Array = []
@export var is_subweapon: bool = false
@export var subweapon_projectile_id: String = ""
@export var subweapon_projectile_scene: PackedScene
