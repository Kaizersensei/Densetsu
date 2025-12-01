extends Resource
class_name FactionData

@export var id: String = ""
@export var description: String = ""
@export var tags: PackedStringArray = PackedStringArray()
@export var hostility_table: Dictionary = {}
@export var base_loot_table_id: String = ""
@export var inventory_template_id: String = ""
@export var base_stats: Dictionary = {}
@export_enum("override", "average", "add", "merge") var stats_merge_policy: String = "override"
@export_enum("override", "merge") var inventory_merge_policy: String = "override"
