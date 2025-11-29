extends Resource
class_name ActorData
@export var id: String = ""
@export var description: String = ""
@export_enum("Character", "Creature", "Trap", "Projectile", "Item", "Utility", "Decoration", "Spawner", "Destructible") var type: String = "Character"
@export var tags: PackedStringArray = PackedStringArray()
@export_enum("Player", "AI") var input_source: String = "AI"
@export var player_number: int = 1
@export_enum("Active", "SemiActive", "Passive", "Dormant") var lifecycle_state: String = "Active"
@export var scene: PackedScene
@export var group: String = "actors"
@export var initial_state: String = ""
@export var owner_id: int = -1
@export var team: String = ""
@export var faction_id: String = ""
@export_enum("-1", "0", "1") var aggressiveness: int = 0
@export var behavior_profile_id: String = ""
@export var loot_table_id: String = ""
@export var dialogue_id: String = ""
@export var inventory_template_id: String = ""
@export var patrol_path_id: String = ""
@export var schedule_id: String = ""
@export var spawn_respawn: bool = false
@export var spawn_unique: bool = false
@export var spawn_persistent: bool = false
@export var spawn_radius: float = 0.0
@export var level: int = 1
@export var xp_value: int = 0
@export var ai_state_init: String = ""
@export var ai_params: Dictionary = {}
@export var position: Vector2 = Vector2.ZERO
@export var rotation: float = 0.0
@export var scale: Vector2 = Vector2.ONE
@export var collision_layers: int = 1
@export var collision_mask: int = 1
@export var sprite: Texture2D
@export var collider_shape: Resource
@export var stats: Dictionary = {}
@export var resistances: Dictionary = {}
@export var abilities: Array[String] = []
@export var effects: Array[String] = []
@export var ai_profile: String = ""
@export var quest_hooks: Dictionary = {}
@export var persistence: bool = false
