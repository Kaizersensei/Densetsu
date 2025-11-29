extends Control

@onready var _categories: ItemList = $Root/ScrollLeft/CategoriesBox/Categories
@onready var _assets: ItemList = $Root/ScrollAssets/AssetsBox/Assets
@onready var _path: LineEdit = $Root/ScrollInspector/Inspector/Path
@onready var _id: LineEdit = $Root/ScrollInspector/Inspector/Id
@onready var _type: OptionButton = $Root/ScrollInspector/Inspector/Type
@onready var _lifecycle: OptionButton = $Root/ScrollInspector/Inspector/Lifecycle
@onready var _tags: LineEdit = $Root/ScrollInspector/Inspector/Tags
@onready var _scene: LineEdit = $Root/ScrollInspector/Inspector/Scene
@onready var _scene_browse: Button = $Root/ScrollInspector/Inspector/SceneBrowse
@onready var _input_source: OptionButton = $Root/ScrollInspector/Inspector/InputSource
@onready var _player_row: HBoxContainer = $Root/ScrollInspector/Inspector/PlayerRow
@onready var _player_number: SpinBox = $Root/ScrollInspector/Inspector/PlayerRow/PlayerNumber
@onready var _faction: LineEdit = $Root/ScrollInspector/Inspector/Faction
@onready var _hostility: OptionButton = $Root/ScrollInspector/Inspector/Hostility
@onready var _behavior_profile: LineEdit = $Root/ScrollInspector/Inspector/BehaviorRow/BehaviorProfile
@onready var _behavior_locate: Button = $Root/ScrollInspector/Inspector/BehaviorRow/BehaviorLocate
@onready var _behavior_create: Button = $Root/ScrollInspector/Inspector/BehaviorRow/BehaviorCreate
@onready var _dialogue: LineEdit = $Root/ScrollInspector/Inspector/DialogueRow/Dialogue
@onready var _dialogue_locate: Button = $Root/ScrollInspector/Inspector/DialogueRow/DialogueLocate
@onready var _dialogue_create: Button = $Root/ScrollInspector/Inspector/DialogueRow/DialogueCreate
@onready var _loot: LineEdit = $Root/ScrollInspector/Inspector/LootRow/Loot
@onready var _loot_locate: Button = $Root/ScrollInspector/Inspector/LootRow/LootLocate
@onready var _loot_create: Button = $Root/ScrollInspector/Inspector/LootRow/LootCreate
@onready var _inventory: LineEdit = $Root/ScrollInspector/Inspector/InventoryRow/Inventory
@onready var _inventory_locate: Button = $Root/ScrollInspector/Inspector/InventoryRow/InventoryLocate
@onready var _inventory_create: Button = $Root/ScrollInspector/Inspector/InventoryRow/InventoryCreate
@onready var _patrol: LineEdit = $Root/ScrollInspector/Inspector/PatrolRow/Patrol
@onready var _patrol_locate: Button = $Root/ScrollInspector/Inspector/PatrolRow/PatrolLocate
@onready var _patrol_create: Button = $Root/ScrollInspector/Inspector/PatrolRow/PatrolCreate
@onready var _schedule: LineEdit = $Root/ScrollInspector/Inspector/ScheduleRow/Schedule
@onready var _schedule_locate: Button = $Root/ScrollInspector/Inspector/ScheduleRow/ScheduleLocate
@onready var _schedule_create: Button = $Root/ScrollInspector/Inspector/ScheduleRow/ScheduleCreate
@onready var _spawn_respawn: CheckBox = $Root/ScrollInspector/Inspector/SpawnRow/SpawnRespawn
@onready var _spawn_unique: CheckBox = $Root/ScrollInspector/Inspector/SpawnRow/SpawnUnique
@onready var _spawn_persistent: CheckBox = $Root/ScrollInspector/Inspector/SpawnRow/SpawnPersistent
@onready var _spawn_radius: LineEdit = $Root/ScrollInspector/Inspector/SpawnRadius
@onready var _level: LineEdit = $Root/ScrollInspector/Inspector/LevelRow/Level
@onready var _xp: LineEdit = $Root/ScrollInspector/Inspector/LevelRow/XP
@onready var _ai_state: LineEdit = $Root/ScrollInspector/Inspector/AIState
@onready var _ai_params: LineEdit = $Root/ScrollInspector/Inspector/AIParams
@onready var _layers: LineEdit = $Root/ScrollInspector/Inspector/CollisionRow/Layers
@onready var _mask: LineEdit = $Root/ScrollInspector/Inspector/CollisionRow/Mask
@onready var _spawner_box: VBoxContainer = $Root/ScrollInspector/Inspector/SpawnerBox
@onready var _spawner_spawn_scene: LineEdit = $Root/ScrollInspector/Inspector/SpawnerBox/SpawnerSceneRow/SpawnerScene
@onready var _spawner_scene_browse: Button = $Root/ScrollInspector/Inspector/SpawnerBox/SpawnerSceneRow/SpawnerSceneBrowse
@onready var _min_spawn: LineEdit = $Root/ScrollInspector/Inspector/SpawnerBox/SpawnerCountsRow/MinSpawn
@onready var _max_spawn: LineEdit = $Root/ScrollInspector/Inspector/SpawnerBox/SpawnerCountsRow/MaxSpawn
@onready var _cooldown: LineEdit = $Root/ScrollInspector/Inspector/SpawnerBox/CooldownRow/Cooldown
@onready var _active_start: LineEdit = $Root/ScrollInspector/Inspector/SpawnerBox/ActiveRow/ActiveStart
@onready var _active_end: LineEdit = $Root/ScrollInspector/Inspector/SpawnerBox/ActiveRow/ActiveEnd
@onready var _spawn_on_start: CheckBox = $Root/ScrollInspector/Inspector/SpawnerBox/SpawnerFlagsRow/SpawnOnStart
@onready var _show_in_game: CheckBox = $Root/ScrollInspector/Inspector/SpawnerBox/SpawnerFlagsRow/ShowInGame
@onready var _team: LineEdit = $Root/ScrollInspector/Inspector/SpawnerBox/TeamRow/Team
@onready var _btn_new: Button = $Root/ScrollInspector/Inspector/Buttons/New
@onready var _btn_save: Button = $Root/ScrollInspector/Inspector/Buttons/Save
@onready var _btn_reload: Button = $Root/ScrollInspector/Inspector/Buttons/Reload
@onready var _btn_delete: Button = $Root/ScrollInspector/Inspector/Buttons/Delete
@onready var _btn_close: Button = $Root/ScrollInspector/Inspector/Buttons/Close

var _current_category: String = ""
var _current_id: String = ""
const CATEGORY_SCRIPTS := {
	"Actor": "res://engine/actors/resources/ActorData.gd",
	"Spawner": "res://engine/actors/resources/SpawnerData.gd",
	"Faction": "res://engine/data/resources/FactionData.gd",
	"AIProfile": "res://engine/data/resources/AIProfileData.gd",
	"Item": "res://engine/data/resources/ItemData.gd",
	"Projectile": "res://engine/data/resources/ProjectileData.gd",
	"Trap": "res://engine/data/resources/TrapData.gd",
	"Platform": "res://engine/data/resources/PlatformData.gd",
	"LootTable": "res://engine/data/resources/LootTableData.gd",
	"Stats": "res://engine/data/resources/StatsData.gd",
}

func _ready() -> void:
	_populate_categories()
	_ensure_dropdowns()
	_categories.gui_input.connect(_on_list_gui_input.bind("categories"))
	_assets.gui_input.connect(_on_list_gui_input.bind("assets"))
	_btn_new.pressed.connect(_on_new)
	_btn_save.pressed.connect(_on_save)
	_btn_reload.pressed.connect(_on_reload)
	_btn_delete.pressed.connect(_on_delete)
	_btn_close.pressed.connect(hide)
	if _scene_browse:
		_scene_browse.pressed.connect(_browse_scene)
	if _spawner_scene_browse:
		_spawner_scene_browse.pressed.connect(_browse_spawn_scene)
	_categories.item_selected.connect(_on_category_selected)
	_categories.item_clicked.connect(func(index, _pos, _button): _on_category_selected(index))
	_assets.item_selected.connect(_on_asset_selected)
	_assets.item_clicked.connect(func(index, _pos, _button): _on_asset_selected(index))
	_connect_template_buttons()
	if Engine.has_singleton("DataRegistry"):
		var reg = Engine.get_singleton("DataRegistry")
		if reg.has_signal("data_changed"):
			reg.data_changed.connect(_refresh_assets)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		hide()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			get_viewport().set_input_as_handled()


func _on_list_gui_input(event: InputEvent, list_name: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[DataEditor] list click:", list_name)
		# item_selected/item_clicked handle selection changes


func force_refresh() -> void:
	if _categories.item_count > 0:
		var sel := _categories.get_selected_items()
		if sel.size() > 0:
			_on_category_selected(sel[0])
		else:
			_on_category_selected(0)


func _populate_categories() -> void:
	_categories.clear()
	var reg = _get_registry()
	if reg:
		for cat in reg.CATEGORY_DIRS.keys():
			_categories.add_item(cat)
	if _categories.item_count > 0:
		_categories.select(0)
		_on_category_selected(0)


func _refresh_assets(rescan: bool = false) -> void:
	if _current_category == "":
		return
	var reg = _get_registry()
	if reg == null:
		return
	if rescan and reg.has_method("_rescan"):
		reg._rescan()
	_ensure_default_for_category(_current_category)
	_assets.clear()
	_current_id = ""
	_clear_all_fields()
	var ids: Array = reg.get_ids(_current_category)
	for id in ids:
		_assets.add_item(id)
	if _assets.item_count > 0:
		_assets.select(0)
		_on_asset_selected(0)
	else:
		_current_id = ""
		_path.text = ""
		_id.text = ""
		_clear_all_fields()


func _on_category_selected(index: int) -> void:
	_current_category = _categories.get_item_text(index)
	print("[DataEditor] Category selected:", _current_category)
	_refresh_assets(true)


func _on_asset_selected(index: int) -> void:
	if index < 0:
		print("[DataEditor] Asset selection index <0; ignoring")
		return
	_current_id = _assets.get_item_text(index)
	print("[DataEditor] Asset selected (index:", index, "id:", _current_id, ")")
	var reg = _get_registry()
	if reg == null:
		print("[DataEditor] Registry missing; cannot load asset")
		return
	var res = reg.get_resource_for_category(_current_category, _current_id)
	var path = reg.get_resource_path(_current_category, _current_id)
	print("[DataEditor] Loading asset:", _current_id, "path:", path, "category:", _current_category)
	if res == null:
		print("[DataEditor] Loaded resource is null for id:", _current_id, "category:", _current_category)
	_path.text = path
	_clear_all_fields()
	if res and "id" in res:
		_id.text = res.id
	if res and "type" in res:
		for i in range(_type.item_count):
			if _type.get_item_text(i) == res.type:
				_type.select(i)
				break
		_spawner_box.visible = res.type == "Spawner"
	if res and "lifecycle_state" in res:
		for i in range(_lifecycle.item_count):
			if _lifecycle.get_item_text(i) == res.lifecycle_state:
				_lifecycle.select(i)
				break
	if res and "input_source" in res:
		for i in range(_input_source.item_count):
			if _input_source.get_item_text(i) == res.input_source:
				_input_source.select(i)
				break
	if res and "player_number" in res and _player_number:
		_player_number.value = max(1, min(4, int(res.player_number)))
	if _player_row:
		_player_row.visible = res and "input_source" in res and res.input_source == "Player"
	if res and "tags" in res:
		_tags.text = ",".join(res.tags)
	if res and "scene" in res:
		_scene.text = res.scene.resource_path if res.scene else ""
	if res and "faction_id" in res:
		_faction.text = res.faction_id
	if res and "aggressiveness" in res and _hostility:
		for i in range(_hostility.item_count):
			if _hostility.get_item_text(i) == str(res.aggressiveness):
				_hostility.select(i)
				break
	if res and "behavior_profile_id" in res:
		_behavior_profile.text = res.behavior_profile_id
	if res and "dialogue_id" in res:
		_dialogue.text = res.dialogue_id
	if res and "loot_table_id" in res:
		_loot.text = res.loot_table_id
	if res and "inventory_template_id" in res:
		_inventory.text = res.inventory_template_id
	if res and "patrol_path_id" in res:
		_patrol.text = res.patrol_path_id
	if res and "schedule_id" in res:
		_schedule.text = res.schedule_id
	if res and "spawn_respawn" in res:
		_spawn_respawn.button_pressed = res.spawn_respawn
	if res and "spawn_unique" in res:
		_spawn_unique.button_pressed = res.spawn_unique
	if res and "spawn_persistent" in res:
		_spawn_persistent.button_pressed = res.spawn_persistent
	if res and "spawn_radius" in res:
		_spawn_radius.text = str(res.spawn_radius)
	if res and "level" in res:
		_level.text = str(res.level)
	if res and "xp_value" in res:
		_xp.text = str(res.xp_value)
	if res and "ai_state_init" in res:
		_ai_state.text = res.ai_state_init
	if res and "ai_params" in res:
		_ai_params.text = _serialize_dict(res.ai_params)
	if res and "collision_layers" in res:
		_layers.text = str(res.collision_layers)
	if res and "collision_mask" in res:
		_mask.text = str(res.collision_mask)
	if res is SpawnerData:
		_spawner_box.visible = true
		_spawner_spawn_scene.text = res.spawn_scene.resource_path if res.spawn_scene else ""
		_min_spawn.text = str(res.min_spawn)
		_max_spawn.text = str(res.max_spawn)
		_cooldown.text = str(res.cooldown)
		_active_start.text = str(res.active_start_time)
		_active_end.text = str(res.active_end_time)
		_spawn_on_start.button_pressed = res.spawn_on_start
		_show_in_game.button_pressed = res.show_in_game
		_team.text = res.team if "team" in res else ""
	else:
		_spawner_box.visible = false


func _on_new() -> void:
	if _current_category == "":
		return
	_id.text = ""
	_tags.text = ""
	_scene.text = ""
	_input_source.select(1)
	if _player_row:
		_player_row.visible = false
	_faction.text = ""
	if _hostility:
		_hostility.select(1)
	_behavior_profile.text = ""
	_dialogue.text = ""
	_loot.text = ""
	_inventory.text = ""
	_patrol.text = ""
	_schedule.text = ""
	_spawn_respawn.button_pressed = false
	_spawn_unique.button_pressed = false
	_spawn_persistent.button_pressed = false
	_spawn_radius.text = ""
	_level.text = ""
	_xp.text = ""
	_ai_state.text = ""
	_ai_params.text = ""
	_path.text = ""
	_type.select(0)
	_current_id = ""


func _on_save() -> void:
	if _current_category == "":
		return
	var reg = _get_registry()
	if reg == null:
		return
	var res: Resource = _create_resource_for_category(_current_category)
	res.id = _id.text.strip_edges()
	res.type = _type.get_item_text(_type.selected)
	if "lifecycle_state" in res:
		res.lifecycle_state = _lifecycle.get_item_text(_lifecycle.selected)
	var tag_list: PackedStringArray = PackedStringArray()
	for t in _tags.text.split(",", false, 0):
		tag_list.append(String(t).strip_edges())
	if "tags" in res:
		res.tags = tag_list
	if "input_source" in res:
		res.input_source = _input_source.get_item_text(_input_source.selected)
		if res.input_source == "Player" and "player_number" in res:
			res.player_number = int(_player_number.value)
	res.scene = load(_scene.text) if _scene.text.strip_edges() != "" else null
	if "faction_id" in res:
		res.faction_id = _faction.text.strip_edges()
	if "aggressiveness" in res and _hostility:
		res.aggressiveness = int(_hostility.get_item_text(_hostility.selected))
	if "behavior_profile_id" in res:
		res.behavior_profile_id = _behavior_profile.text.strip_edges()
	if "dialogue_id" in res:
		res.dialogue_id = _dialogue.text.strip_edges()
	if "loot_table_id" in res:
		res.loot_table_id = _loot.text.strip_edges()
	if "inventory_template_id" in res:
		res.inventory_template_id = _inventory.text.strip_edges()
	if "patrol_path_id" in res:
		res.patrol_path_id = _patrol.text.strip_edges()
	if "schedule_id" in res:
		res.schedule_id = _schedule.text.strip_edges()
	if "spawn_respawn" in res:
		res.spawn_respawn = _spawn_respawn.button_pressed
	if "spawn_unique" in res:
		res.spawn_unique = _spawn_unique.button_pressed
	if "spawn_persistent" in res:
		res.spawn_persistent = _spawn_persistent.button_pressed
	if "spawn_radius" in res and _spawn_radius.text.strip_edges() != "":
		res.spawn_radius = float(_spawn_radius.text)
	if "level" in res and _level.text.strip_edges() != "":
		res.level = int(_level.text)
	if "xp_value" in res and _xp.text.strip_edges() != "":
		res.xp_value = int(_xp.text)
	if "ai_state_init" in res:
		res.ai_state_init = _ai_state.text.strip_edges()
	if "ai_params" in res:
		res.ai_params = _parse_dict(_ai_params.text)
	if "collision_layers" in res and _layers.text.strip_edges() != "":
		res.collision_layers = int(_layers.text)
	if "collision_mask" in res and _mask.text.strip_edges() != "":
		res.collision_mask = int(_mask.text)
	if res is SpawnerData:
		res.spawn_scene = load(_spawner_spawn_scene.text) if _spawner_spawn_scene.text.strip_edges() != "" else null
		res.min_spawn = int(_min_spawn.text) if _min_spawn.text.strip_edges() != "" else res.min_spawn
		res.max_spawn = int(_max_spawn.text) if _max_spawn.text.strip_edges() != "" else res.max_spawn
		res.cooldown = float(_cooldown.text) if _cooldown.text.strip_edges() != "" else res.cooldown
		res.active_start_time = float(_active_start.text) if _active_start.text.strip_edges() != "" else res.active_start_time
		res.active_end_time = float(_active_end.text) if _active_end.text.strip_edges() != "" else res.active_end_time
		res.spawn_on_start = _spawn_on_start.button_pressed
		res.show_in_game = _show_in_game.button_pressed
		if "team" in res:
			res.team = _team.text.strip_edges()
	var rid: String = res.id
	if rid == "":
		rid = "asset_%s" % str(Time.get_ticks_msec())
	reg.save_resource(_current_category, rid, res)
	_current_id = rid
	_refresh_assets()


func _on_reload() -> void:
	var reg = _get_registry()
	if reg:
		reg._rescan()
	_refresh_assets()


func _ensure_dropdowns() -> void:
	if _type:
		_type.clear()
	for t in ["Character", "Creature", "Trap", "Projectile", "Item", "Utility", "Decoration", "Spawner", "Destructible"]:
		_type.add_item(t)
	_type.select(0)
	if _input_source:
		_input_source.clear()
		for src in ["Player", "AI"]:
			_input_source.add_item(src)
		_input_source.select(1)
	if _lifecycle:
		_lifecycle.clear()
		for l in ["Active", "SemiActive", "Passive", "Dormant"]:
			_lifecycle.add_item(l)
		_lifecycle.select(0)
	if _hostility:
		_hostility.clear()
		for a in ["-1", "0", "1"]:
			_hostility.add_item(a)
		_hostility.select(1)


func _on_delete() -> void:
	if _current_id == "":
		return
	var reg = _get_registry()
	if reg:
		reg.remove(_current_id)
	_current_id = ""
	_refresh_assets()


func _create_resource_for_category(cat: String) -> Resource:
	if CATEGORY_SCRIPTS.has(cat):
		var path: String = CATEGORY_SCRIPTS[cat]
		if ResourceLoader.exists(path):
			var s := load(path)
			if s:
				return s.new()
	return Resource.new()


func _ensure_default_for_category(cat: String) -> void:
	var reg = _get_registry()
	if reg == null:
		return
	if reg.get_ids(cat).size() > 0:
		return
	var res: Resource = _create_resource_for_category(cat)
	if res == null:
		return
	res.id = "Base%s" % cat
	if "type" in res and cat == "Actor":
		res.type = "Character"
	if "lifecycle_state" in res:
		res.lifecycle_state = "Active"
	if "tags" in res:
		res.tags = PackedStringArray()
	if "aggressiveness" in res:
		res.aggressiveness = 0
	reg.save_resource(cat, res.id, res)


func _get_registry():
	if has_node("/root/DataRegistry"):
		return get_node("/root/DataRegistry")
	return null


func _clear_actor_fields() -> void:
	_input_source.select(1)
	_player_row.visible = false
	_player_number.value = 1
	_faction.text = ""
	if _hostility:
		_hostility.select(1)
	_behavior_profile.text = ""
	_dialogue.text = ""
	_loot.text = ""
	_inventory.text = ""
	_patrol.text = ""
	_schedule.text = ""
	_spawn_respawn.button_pressed = false
	_spawn_unique.button_pressed = false
	_spawn_persistent.button_pressed = false
	_spawn_radius.text = ""
	_level.text = ""
	_xp.text = ""
	_ai_state.text = ""
	_ai_params.text = ""


func _clear_all_fields() -> void:
	_id.text = ""
	_path.text = ""
	_type.select(0)
	_lifecycle.select(0)
	_tags.text = ""
	_scene.text = ""
	_clear_actor_fields()
	_spawner_box.visible = false
	_spawner_spawn_scene.text = ""
	_min_spawn.text = ""
	_max_spawn.text = ""
	_cooldown.text = ""
	_active_start.text = ""
	_active_end.text = ""
	_spawn_on_start.button_pressed = false
	_show_in_game.button_pressed = false
	_team.text = ""
	_layers.text = ""
	_mask.text = ""


func _browse_scene() -> void:
	var fd := FileDialog.new()
	fd.access = FileDialog.ACCESS_RESOURCES
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.filters = PackedStringArray(["*.tscn ; Scenes"])
	fd.file_selected.connect(func(p): _scene.text = p)
	add_child(fd)
	fd.popup_centered()


func _browse_spawn_scene() -> void:
	var fd := FileDialog.new()
	fd.access = FileDialog.ACCESS_RESOURCES
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.filters = PackedStringArray(["*.tscn ; Scenes"])
	fd.file_selected.connect(func(p): _spawner_spawn_scene.text = p)
	add_child(fd)
	fd.popup_centered()


func _connect_template_buttons() -> void:
	var button_map: Dictionary = {
		_behavior_locate: "behavior_profile_id",
		_dialogue_locate: "dialogue_id",
		_loot_locate: "loot_table_id",
		_inventory_locate: "inventory_template_id",
		_patrol_locate: "patrol_path_id",
		_schedule_locate: "schedule_id",
		_behavior_create: "behavior_profile_id",
		_dialogue_create: "dialogue_id",
		_loot_create: "loot_table_id",
		_inventory_create: "inventory_template_id",
		_patrol_create: "patrol_path_id",
		_schedule_create: "schedule_id",
	}
	for btn in button_map.keys():
		if btn:
			if btn.text == "+":
				btn.pressed.connect(_on_create_template.bind(button_map[btn]))
			else:
				btn.pressed.connect(_on_locate_template.bind(button_map[btn]))


func _on_locate_template(field: String) -> void:
	print("Locate template for ", field, " (not implemented)")


func _on_create_template(field: String) -> void:
	print("Create template for ", field, " (not implemented)")


func _serialize_dict(d: Dictionary) -> String:
	var parts: Array[String] = []
	for k in d.keys():
		parts.append("%s=%s" % [str(k), str(d[k])])
	return ";".join(parts)


func _parse_dict(text: String) -> Dictionary:
	var d: Dictionary = {}
	for part in text.split(";", false, 0):
		var p := part.strip_edges()
		if p == "":
			continue
		var eq := p.find("=")
		if eq == -1:
			d[p] = ""
		else:
			var key := p.substr(0, eq).strip_edges()
			var val := p.substr(eq + 1, p.length()).strip_edges()
			d[key] = val
	return d
