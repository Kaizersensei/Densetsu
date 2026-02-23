@tool
extends Resource
class_name ItemData3D

## Identifier for item.
@export var item_id: String = ""
## Name for display.
@export var display_name: String = ""
## Controls description.
@export_multiline var description: String = ""
## Controls category.
@export var category: String = "generic"
## Controls equip slot.
@export var equip_slot: String = ""
## Controls tags.
@export var tags: PackedStringArray = PackedStringArray()
