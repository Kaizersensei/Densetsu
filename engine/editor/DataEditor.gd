extends Control

@onready var _categories: ItemList = $Root/ScrollLeft/CategoriesBox/Categories
@onready var _assets: ItemList = $Root/ScrollAssets/AssetsBox/Assets
@onready var _preview: TextureRect = $Root/ScrollAssets/AssetsBox/PreviewBox/PreviewTexture
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
@onready var _hp: LineEdit = $Root/ScrollInspector/Inspector/HPRow/HP
@onready var _mp: LineEdit = $Root/ScrollInspector/Inspector/MPRow/MP
@onready var _str: LineEdit = $Root/ScrollInspector/Inspector/StrengthRow/Strength
@onready var _def: LineEdit = $Root/ScrollInspector/Inspector/DefenseRow/Defense
@onready var _agi: LineEdit = $Root/ScrollInspector/Inspector/AgilityRow/Agility
@onready var _int: LineEdit = $Root/ScrollInspector/Inspector/IntelligenceRow/Intelligence
@onready var _luck: LineEdit = $Root/ScrollInspector/Inspector/LuckRow/Luck
@onready var _elem_fire: LineEdit = $Root/ScrollInspector/Inspector/ElemFireRow/ElemFire
@onready var _elem_water: LineEdit = $Root/ScrollInspector/Inspector/ElemWaterRow/ElemWater
@onready var _elem_earth: LineEdit = $Root/ScrollInspector/Inspector/ElemEarthRow/ElemEarth
@onready var _elem_wind: LineEdit = $Root/ScrollInspector/Inspector/ElemWindRow/ElemWind
@onready var _elem_light: LineEdit = $Root/ScrollInspector/Inspector/ElemLightRow/ElemLight
@onready var _elem_dark: LineEdit = $Root/ScrollInspector/Inspector/ElemDarkRow/ElemDark
@onready var _skill_atk: LineEdit = $Root/ScrollInspector/Inspector/SkillAtkRow/SkillAtk
@onready var _skill_support: LineEdit = $Root/ScrollInspector/Inspector/SkillSupportRow/SkillSupport
@onready var _skill_special: LineEdit = $Root/ScrollInspector/Inspector/SkillSpecialRow/SkillSpecial
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
@onready var _btn_new: Button = $Root/ScrollAssets/AssetsBox/Buttons/New
@onready var _btn_save: Button = $Root/ScrollAssets/AssetsBox/Buttons/Save
@onready var _btn_reload: Button = $Root/ScrollAssets/AssetsBox/Buttons/Reload
@onready var _btn_delete: Button = $Root/ScrollAssets/AssetsBox/Buttons/Delete

var _current_category: String = ""
var _current_id: String = ""
var _pending_select_id: String = ""
var _row_behavior: Control
var _row_dialogue: Control
var _row_loot: Control
var _row_inventory: Control
var _row_patrol: Control
var _row_schedule: Control
var _row_spawn: Control
var _row_spawn_radius: Control
var _row_level: Control
var _row_ai: Control
var _row_collision: Control
var _row_path: Control
var _row_id: Control
var _row_type_row: Control
var _row_lifecycle: Control
var _row_tags: Control
var _row_scene: Control
var _row_input: Control
var _label_behavior: Control
var _label_dialogue: Control
var _label_loot: Control
var _label_inventory: Control
var _label_patrol: Control
var _label_schedule: Control
var _label_spawn: Control
var _label_spawn_radius: Control
var _label_level: Control
var _label_ai_state: Control
var _label_ai_params: Control
var _label_collision: Control
var _label_element: Control
var _label_skills: Control
var _label_stats: Control
var _label_path: Control
var _label_id: Control
var _label_type: Control
var _label_lifecycle: Control
var _label_tags: Control
var _label_scene: Control
var _label_input: Control
var _label_player: Control
var _label_faction: Control
var _label_hostility: Control
var _label_ai_params_default: String = ""
var _group_core: Array = []
var _group_actor: Array = []
var _group_spawner: Array = []
var _group_collision: Array = []
var _group_scene: Array = []
var _key_controls: Dictionary = {}

const CATEGORY_SCHEMA := {
	"Actor": [
		"type", "lifecycle_state", "input_source", "player_number",
		"faction_id", "aggressiveness", "behavior_profile_id", "dialogue_id",
		"loot_table_id", "inventory_template_id", "patrol_path_id", "schedule_id",
		"spawn_respawn", "spawn_unique", "spawn_persistent", "spawn_radius",
		"level", "xp_value", "ai_state_init", "ai_params",
		"collision_layers", "collision_mask"
	],
	"Spawner": [
		"spawn_scene", "min_spawn", "max_spawn", "cooldown",
		"active_start_time", "active_end_time", "spawn_on_start",
		"show_in_game", "team", "collision_layers", "collision_mask"
	],
	"Item": ["scene", "collision_layers", "collision_mask"],
	"Projectile": ["scene", "collision_layers", "collision_mask"],
	"Trap": ["scene", "collision_layers", "collision_mask"],
	"Platform": ["scene", "collision_layers", "collision_mask"],
	"LootTable": [],
	"Stats": ["level", "hp", "mp", "strength", "defense", "agility", "intelligence", "luck"],
	"AIProfile": [],
	"Faction": [],
	"Weather": [],
	"Particles": [],
	"Sounds": [],
	"Strings": [],
	"Quests": []
}
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
	"Weather": "res://engine/data/resources/WeatherData.gd",
	"Particles": "res://engine/data/resources/ParticlesData.gd",
	"Sounds": "res://engine/data/resources/SoundsData.gd",
	"Strings": "res://engine/data/resources/StringsData.gd",
	"Quests": "res://engine/data/resources/QuestsData.gd",
}
const CATEGORY_TIPS := {
	"Actor": "Entities with behaviors/inputs; set sprite/scene/collider, AI params, stats.",
	"Spawner": "Spawn definitions; link spawn scene, counts, timing, visibility.",
	"Faction": "Group alignment; affects relationships/hostility.",
	"AIProfile": "Behavior profiles and decision params.",
	"Item": "Pickups/consumables; link sprite/scene and effects.",
	"Projectile": "Shots/bullets; link sprite/scene and damage params.",
	"Trap": "Hazards; link sprite/scene and damage/flags.",
	"Platform": "Solids/one-ways/slopes; link platform scenes.",
	"LootTable": "Drop lists; define loot roll sets.",
	"Stats": "Stat templates; baseline hp/atk/etc.",
	"Weather": "Weather effect definitions and parameters.",
	"Particles": "Particle presets to reuse in spawners/effects.",
	"Sounds": "Sound cues/presets for reuse.",
	"Strings": "Localized or in-game text entries.",
	"Quests": "Quest definitions, objectives, and flow hints.",
}

func _ready() -> void:
	_populate_categories()
	_ensure_dropdowns()
	_cache_rows()
	_categories.gui_input.connect(_on_list_gui_input.bind("categories"))
	_assets.gui_input.connect(_on_list_gui_input.bind("assets"))
	_btn_new.pressed.connect(_on_new)
	_btn_save.pressed.connect(_on_save)
	_btn_reload.pressed.connect(_on_reload)
	_btn_delete.pressed.connect(_on_delete)
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
			var idx := _categories.add_item(cat)
			if CATEGORY_TIPS.has(cat):
				_categories.set_item_tooltip(idx, CATEGORY_TIPS[cat])
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
		var idx := _assets.add_item(id)
		var res_any = reg.get_resource_for_category(_current_category, id)
		if res_any and "description" in res_any:
			_assets.set_item_tooltip(idx, String(res_any.description))
	if _pending_select_id != "":
		var idx := _find_item_index(_assets, _pending_select_id)
		_pending_select_id = ""
		if idx != -1:
			_assets.select(idx)
			_on_asset_selected(idx)
			return
	if _assets.item_count > 0:
		_assets.select(0)
		_on_asset_selected(0)
	else:
		_current_id = ""
		_path.text = ""
		_id.text = ""


func _on_category_selected(index: int) -> void:
	_current_category = _categories.get_item_text(index)
	print("[DataEditor] Category selected:", _current_category)
	_refresh_assets(true)


func _on_asset_selected(index: int) -> void:
	if index < 0:
		print("[DataEditor] Asset selection index <0; ignoring")
		return
	_current_id = _assets.get_item_text(index)
	_refresh_selection()


func _refresh_selection() -> void:
	_clear_all_fields()
	_apply_category_visibility(_current_category)
	var reg = _get_registry()
	if reg == null:
		print("[DataEditor] Registry missing; cannot load asset")
		return
	var res_loaded = reg.get_resource_for_category(_current_category, _current_id)
	var path = reg.get_resource_path(_current_category, _current_id)
	print("[DataEditor] Loading asset:", _current_id, "path:", path, "category:", _current_category)
	_path.text = path
	if res_loaded == null:
		print("[DataEditor] Loaded resource is null for id:", _current_id, "category:", _current_category)
		_id.text = _current_id
		_update_preview(null)
		return
	_fill_common_fields(res_loaded)
	_fill_category_fields(res_loaded)
	_update_preview(res_loaded)


func _fill_common_fields(res: Resource) -> void:
	_id.text = _get_res_id(res)
	if "description" in res and res.description is String:
		_tags.placeholder_text = res.description
	else:
		_tags.placeholder_text = ""
	if "tags" in res and res.tags is PackedStringArray:
		_tags.text = ",".join(res.tags)
	if "scene" in res and res.scene:
		_scene.text = res.scene.resource_path if res.scene else ""


func _fill_category_fields(res: Resource) -> void:
	match _current_category:
		"Actor":
			if res and "type" in res:
				for i in range(_type.item_count):
					if _type.get_item_text(i) == res.type:
						_type.select(i)
						break
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
			if "level" in res:
				_level.text = str(res.level)
			if "xp_value" in res:
				_xp.text = str(res.xp_value)
			if "ai_state_init" in res:
				_ai_state.text = res.ai_state_init
			if "ai_params" in res:
				_ai_params.text = _serialize_dict(res.ai_params)
			if "collision_layers" in res:
				_layers.text = str(res.collision_layers)
			if "collision_mask" in res:
				_mask.text = str(res.collision_mask)
		"Stats":
			if "level" in res:
				_level.text = str(res.level)
			if "xp_value" in res and _xp:
				_xp.text = str(int(res.xp_value))
			if _hp and "hp" in res:
				_hp.text = str(int(res.hp))
			if _mp and "mp" in res:
				_mp.text = str(int(res.mp))
			if _str and "strength" in res:
				_str.text = str(int(res.strength))
			if _def and "defense" in res:
				_def.text = str(int(res.defense))
			if _agi and "agility" in res:
				_agi.text = str(int(res.agility))
			if _int and "intelligence" in res:
				_int.text = str(int(res.intelligence))
			if _luck and "luck" in res:
				_luck.text = str(int(res.luck))
			if _elem_fire and "elem_fire" in res:
				_elem_fire.text = str(int(res.elem_fire))
			if _elem_water and "elem_water" in res:
				_elem_water.text = str(int(res.elem_water))
			if _elem_earth and "elem_earth" in res:
				_elem_earth.text = str(int(res.elem_earth))
			if _elem_wind and "elem_wind" in res:
				_elem_wind.text = str(int(res.elem_wind))
			if _elem_light and "elem_light" in res:
				_elem_light.text = str(int(res.elem_light))
			if _elem_dark and "elem_dark" in res:
				_elem_dark.text = str(int(res.elem_dark))
			if _skill_atk and "skill_attack" in res:
				_skill_atk.text = str(int(res.skill_attack))
			if _skill_support and "skill_support" in res:
				_skill_support.text = str(int(res.skill_support))
			if _skill_special and "skill_special" in res:
				_skill_special.text = str(int(res.skill_special))
			_ai_params.text = ""
		"Spawner":
			if res is SpawnerData:
				_spawner_spawn_scene.text = res.spawn_scene.resource_path if res.spawn_scene else ""
				_min_spawn.text = str(res.min_spawn)
				_max_spawn.text = str(res.max_spawn)
				_cooldown.text = str(res.cooldown)
				_active_start.text = str(res.active_start_time)
				_active_end.text = str(res.active_end_time)
				_spawn_on_start.button_pressed = res.spawn_on_start
				_show_in_game.button_pressed = res.show_in_game
				if "team" in res:
					_team.text = res.team
				if "collision_layers" in res:
					_layers.text = str(res.collision_layers)
				if "collision_mask" in res:
					_mask.text = str(res.collision_mask)
		"Item", "Projectile", "Trap", "Platform":
			if "collision_layers" in res:
				_layers.text = str(res.collision_layers)
			if "collision_mask" in res:
				_mask.text = str(res.collision_mask)
			if "scene" in res and res.scene:
				_scene.text = res.scene.resource_path
		"LootTable", "Stats", "AIProfile", "Faction":
			# minimal fill for now
			pass
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
	var res: Resource = reg.get_resource_for_category(_current_category, _current_id)
	if res == null:
		res = _create_resource_for_category(_current_category)
	if res == null:
		return
	_apply_fields_to_resource(res)
	var rid: String = _get_res_id(res)
	if rid == "":
		rid = "asset_%s" % str(Time.get_ticks_msec())
	reg.save_resource(_current_category, rid, res)
	_current_id = rid
	_refresh_assets()
	_update_preview(res)


func _apply_fields_to_resource(res: Resource) -> void:
	var new_id := _id.text.strip_edges()
	if new_id != "":
		_set_res_id(res, new_id)
	if "type" in res and _current_category == "Actor":
		res.type = _type.get_item_text(_type.selected)
	if "lifecycle_state" in res and _current_category == "Actor":
		res.lifecycle_state = _lifecycle.get_item_text(_lifecycle.selected)
	if "tags" in res:
		var tag_list: PackedStringArray = PackedStringArray()
		for t in _tags.text.split(",", false, 0):
			tag_list.append(String(t).strip_edges())
		res.tags = tag_list
	if "input_source" in res and _current_category == "Actor":
		res.input_source = _input_source.get_item_text(_input_source.selected)
		if res.input_source == "Player" and "player_number" in res:
			res.player_number = int(_player_number.value)
	if "scene" in res and _scene:
		var scene_path := _scene.text.strip_edges()
		if scene_path != "":
			res.scene = load(scene_path)
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
	if _current_category == "Stats":
		if _level.text.strip_edges() != "":
			res.level = int(_level.text)
		if _hp and _hp.text.strip_edges() != "":
			res.hp = int(_hp.text)
		if _mp and _mp.text.strip_edges() != "":
			res.mp = int(_mp.text)
		if _str and _str.text.strip_edges() != "":
			res.strength = int(_str.text)
		if _def and _def.text.strip_edges() != "":
			res.defense = int(_def.text)
		if _agi and _agi.text.strip_edges() != "":
			res.agility = int(_agi.text)
		if _int and _int.text.strip_edges() != "":
			res.intelligence = int(_int.text)
		if _luck and _luck.text.strip_edges() != "":
			res.luck = int(_luck.text)
		if _elem_fire and _elem_fire.text.strip_edges() != "":
			res.elem_fire = int(_elem_fire.text)
		if _elem_water and _elem_water.text.strip_edges() != "":
			res.elem_water = int(_elem_water.text)
		if _elem_earth and _elem_earth.text.strip_edges() != "":
			res.elem_earth = int(_elem_earth.text)
		if _elem_wind and _elem_wind.text.strip_edges() != "":
			res.elem_wind = int(_elem_wind.text)
		if _elem_light and _elem_light.text.strip_edges() != "":
			res.elem_light = int(_elem_light.text)
		if _elem_dark and _elem_dark.text.strip_edges() != "":
			res.elem_dark = int(_elem_dark.text)
		if _skill_atk and _skill_atk.text.strip_edges() != "":
			res.skill_attack = int(_skill_atk.text)
		if _skill_support and _skill_support.text.strip_edges() != "":
			res.skill_support = int(_skill_support.text)
		if _skill_special and _skill_special.text.strip_edges() != "":
			res.skill_special = int(_skill_special.text)
		# keep dictionary in sync for derived usage
		res.stats = {
			"hp": res.hp,
			"mp": res.mp,
			"strength": res.strength,
			"defense": res.defense,
			"agility": res.agility,
			"intelligence": res.intelligence,
			"luck": res.luck,
			"elem_fire": res.elem_fire,
			"elem_water": res.elem_water,
			"elem_earth": res.elem_earth,
			"elem_wind": res.elem_wind,
			"elem_light": res.elem_light,
			"elem_dark": res.elem_dark,
			"skill_attack": res.skill_attack,
			"skill_support": res.skill_support,
			"skill_special": res.skill_special,
			"level": res.level,
		}
	if res is SpawnerData:
		if _spawner_spawn_scene.text.strip_edges() != "":
			res.spawn_scene = load(_spawner_spawn_scene.text)
		if _min_spawn.text.strip_edges() != "":
			res.min_spawn = int(_min_spawn.text)
		if _max_spawn.text.strip_edges() != "":
			res.max_spawn = int(_max_spawn.text)
		if _cooldown.text.strip_edges() != "":
			res.cooldown = float(_cooldown.text)
		if _active_start.text.strip_edges() != "":
			res.active_start_time = float(_active_start.text)
		if _active_end.text.strip_edges() != "":
			res.active_end_time = float(_active_end.text)
		res.spawn_on_start = _spawn_on_start.button_pressed
		res.show_in_game = _show_in_game.button_pressed
		if "team" in res:
			res.team = _team.text.strip_edges()


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
	_update_preview(null)


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
	_set_res_id(res, "Base%s" % cat)
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


func _cache_rows() -> void:
	_row_behavior = _behavior_profile.get_parent() if _behavior_profile else null
	_row_dialogue = _dialogue.get_parent() if _dialogue else null
	_row_loot = _loot.get_parent() if _loot else null
	_row_inventory = _inventory.get_parent() if _inventory else null
	_row_patrol = _patrol.get_parent() if _patrol else null
	_row_schedule = _schedule.get_parent() if _schedule else null
	_row_spawn = _spawn_respawn.get_parent() if _spawn_respawn else null
	_row_spawn_radius = _spawn_radius.get_parent() if _spawn_radius else null
	_row_level = _level.get_parent() if _level else null
	_row_ai = _ai_state.get_parent() if _ai_state else null
	_row_collision = _layers.get_parent() if _layers else null
	_row_path = _path.get_parent() if _path else null
	_row_id = _id.get_parent() if _id else null
	_row_type_row = _type.get_parent() if _type else null
	_row_lifecycle = _lifecycle.get_parent() if _lifecycle else null
	_row_tags = _tags.get_parent() if _tags else null
	_row_scene = _scene.get_parent() if _scene else null
	_row_input = _input_source.get_parent() if _input_source else null
	_label_behavior = get_node_or_null("Root/ScrollInspector/Inspector/BehaviorLabel")
	_label_dialogue = get_node_or_null("Root/ScrollInspector/Inspector/DialogueLabel")
	_label_loot = get_node_or_null("Root/ScrollInspector/Inspector/LootLabel")
	_label_inventory = get_node_or_null("Root/ScrollInspector/Inspector/InventoryLabel")
	_label_patrol = get_node_or_null("Root/ScrollInspector/Inspector/PatrolLabel")
	_label_schedule = get_node_or_null("Root/ScrollInspector/Inspector/ScheduleLabel")
	_label_spawn = get_node_or_null("Root/ScrollInspector/Inspector/SpawnLabel")
	_label_spawn_radius = get_node_or_null("Root/ScrollInspector/Inspector/SpawnRadiusLabel")
	_label_level = get_node_or_null("Root/ScrollInspector/Inspector/LevelRow/LevelLabel")
	_label_ai_state = get_node_or_null("Root/ScrollInspector/Inspector/AIStateLabel")
	_label_ai_params = get_node_or_null("Root/ScrollInspector/Inspector/AIParamsLabel")
	_label_collision = get_node_or_null("Root/ScrollInspector/Inspector/CollisionLabel")
	_label_stats = get_node_or_null("Root/ScrollInspector/Inspector/StatsLabel")
	_label_element = get_node_or_null("Root/ScrollInspector/Inspector/ElementLabel")
	_label_skills = get_node_or_null("Root/ScrollInspector/Inspector/SkillLabel")
	_label_ai_params_default = _label_ai_params.text if _label_ai_params else ""
	_label_path = get_node_or_null("Root/ScrollInspector/Inspector/PathLabel")
	_label_id = get_node_or_null("Root/ScrollInspector/Inspector/IdLabel")
	_label_type = get_node_or_null("Root/ScrollInspector/Inspector/TypeLabel")
	_label_lifecycle = get_node_or_null("Root/ScrollInspector/Inspector/LifecycleLabel")
	_label_tags = get_node_or_null("Root/ScrollInspector/Inspector/TagsLabel")
	_label_scene = get_node_or_null("Root/ScrollInspector/Inspector/SceneLabel")
	_label_input = get_node_or_null("Root/ScrollInspector/Inspector/InputSourceLabel")
	_label_player = get_node_or_null("Root/ScrollInspector/Inspector/PlayerRow/PlayerNumberLabel")
	_label_faction = get_node_or_null("Root/ScrollInspector/Inspector/FactionLabel")
	_label_hostility = get_node_or_null("Root/ScrollInspector/Inspector/HostilityLabel")
	_label_stats = get_node_or_null("Root/ScrollInspector/Inspector/StatsLabel")
	_group_core = [_row_path, _row_id, _row_tags]
	_group_actor = [
		_row_type_row, _row_lifecycle, _row_input, _player_row,
		_row_behavior, _row_dialogue, _row_loot, _row_inventory,
		_row_patrol, _row_schedule, _row_spawn, _row_spawn_radius,
		_row_level, _row_ai, _row_collision,
		_label_behavior, _label_dialogue, _label_loot, _label_inventory,
		_label_patrol, _label_schedule, _label_spawn, _label_spawn_radius,
		_label_level, _label_ai_state, _label_ai_params, _label_collision, _label_stats
	]
	_group_spawner = [_spawner_box, _label_collision, _row_collision]
	_group_collision = [_row_collision, _label_collision]
	_group_scene = [_row_scene]
	_key_controls = {
		"path": [_row_path, _label_path],
		"id": [_row_id, _label_id],
		"tags": [_row_tags, _label_tags],
		"scene": [_row_scene, _label_scene],
		"type": [_row_type_row, _label_type],
		"lifecycle_state": [_row_lifecycle, _label_lifecycle],
		"input_source": [_row_input, _label_input],
		"player_number": [_player_row, _label_player],
		"faction_id": [_faction.get_parent() if _faction else null, _label_faction],
		"aggressiveness": [_hostility.get_parent() if _hostility else null, _label_hostility],
		"behavior_profile_id": [_row_behavior, _label_behavior],
		"dialogue_id": [_row_dialogue, _label_dialogue],
		"loot_table_id": [_row_loot, _label_loot],
		"inventory_template_id": [_row_inventory, _label_inventory],
		"patrol_path_id": [_row_patrol, _label_patrol],
		"schedule_id": [_row_schedule, _label_schedule],
		"spawn_respawn": [_row_spawn, _label_spawn],
		"spawn_unique": [_row_spawn, _label_spawn],
		"spawn_persistent": [_row_spawn, _label_spawn],
		"spawn_radius": [_row_spawn_radius, _label_spawn_radius],
		"level": [_row_level, _label_level],
		"xp_value": [_row_level, _label_level],
		"ai_state_init": [_row_ai, _label_ai_state],
		"ai_params": [_row_ai, _label_ai_params],
		"hp": [_hp.get_parent() if _hp else null, _label_stats],
		"mp": [_mp.get_parent() if _mp else null, _label_stats],
		"strength": [_str.get_parent() if _str else null, _label_stats],
		"defense": [_def.get_parent() if _def else null, _label_stats],
		"agility": [_agi.get_parent() if _agi else null, _label_stats],
		"intelligence": [_int.get_parent() if _int else null, _label_stats],
		"luck": [_luck.get_parent() if _luck else null, _label_stats],
		"elem_fire": [_elem_fire.get_parent() if _elem_fire else null, _label_element],
		"elem_water": [_elem_water.get_parent() if _elem_water else null, _label_element],
		"elem_earth": [_elem_earth.get_parent() if _elem_earth else null, _label_element],
		"elem_wind": [_elem_wind.get_parent() if _elem_wind else null, _label_element],
		"elem_light": [_elem_light.get_parent() if _elem_light else null, _label_element],
		"elem_dark": [_elem_dark.get_parent() if _elem_dark else null, _label_element],
		"skill_attack": [_skill_atk.get_parent() if _skill_atk else null, _label_skills],
		"skill_support": [_skill_support.get_parent() if _skill_support else null, _label_skills],
		"skill_special": [_skill_special.get_parent() if _skill_special else null, _label_skills],
		"collision_layers": [_row_collision, _label_collision],
		"collision_mask": [_row_collision, _label_collision],
		"spawn_scene": [_spawner_box],
		"min_spawn": [_spawner_box],
		"max_spawn": [_spawner_box],
		"cooldown": [_spawner_box],
		"active_start_time": [_spawner_box],
		"active_end_time": [_spawner_box],
		"spawn_on_start": [_spawner_box],
		"show_in_game": [_spawner_box],
		"team": [_spawner_box],
	}


func _set_row_visible(row: Control, flag: bool) -> void:
	if row:
		row.visible = flag


func _set_block_visible(nodes: Array, flag: bool) -> void:
	for n in nodes:
		if n and n is Control:
			(n as Control).visible = flag


func _apply_category_visibility(cat: String) -> void:
	# start by hiding everything except core
	_set_block_visible(_group_core, true)
	_set_block_visible(_group_actor, false)
	_set_block_visible(_group_spawner, false)
	_set_block_visible(_group_collision, false)
	_set_block_visible(_group_scene, false)
	_set_all_keys_visible(false)
	# core keys always
	_set_key_visible("path", true)
	_set_key_visible("id", true)
	_set_key_visible("tags", true)
	# Stats: explicit, hide everything else
	if cat == "Stats":
		var stats_keys := [
			"level", "xp_value",
			"hp", "mp", "strength", "defense", "agility", "intelligence", "luck",
			"elem_fire", "elem_water", "elem_earth", "elem_wind", "elem_light", "elem_dark",
			"skill_attack", "skill_support", "skill_special"
		]
		for k in stats_keys:
			_set_key_visible(k, true)
		return
	var schema: Array = []
	if CATEGORY_SCHEMA.has(cat):
		schema = CATEGORY_SCHEMA[cat]
	for key in schema:
		_set_key_visible(key, true)
	if _label_ai_params:
		_label_ai_params.text = _label_ai_params_default if _label_ai_params_default != "" else _label_ai_params.text


func _set_all_keys_visible(flag: bool) -> void:
	for arr in _key_controls.values():
		for ctrl in arr:
			if ctrl and ctrl is Control:
				(ctrl as Control).visible = flag


func _set_key_visible(key: String, flag: bool) -> void:
	if not _key_controls.has(key):
		return
	for ctrl in _key_controls[key]:
		if ctrl and ctrl is Control:
			(ctrl as Control).visible = flag
	# Special cases for grouped containers
	if key in ["spawn_scene", "min_spawn", "max_spawn", "cooldown", "active_start_time", "active_end_time", "spawn_on_start", "show_in_game", "team"]:
		if _spawner_box:
			_spawner_box.visible = flag
	if key in ["collision_layers", "collision_mask"]:
		_set_block_visible(_group_collision, flag)
	if key == "scene":
		_set_block_visible(_group_scene, flag)


func _get_res_id(res: Resource) -> String:
	if "id" in res:
		return String(res.id)
	if res.has_meta("id"):
		var mid = res.get_meta("id")
		if mid is String:
			return mid
	return ""


func _set_res_id(res: Resource, new_id: String) -> void:
	if "id" in res:
		res.set("id", new_id)
	else:
		res.set_meta("id", new_id)


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
	_update_preview(null)


func _clear_all_fields() -> void:
	_id.text = ""
	_path.text = ""
	_type.select(0)
	_lifecycle.select(0)
	_tags.text = ""
	_tags.placeholder_text = ""
	_scene.text = ""
	if _hp: _hp.text = ""
	if _mp: _mp.text = ""
	if _str: _str.text = ""
	if _def: _def.text = ""
	if _agi: _agi.text = ""
	if _int: _int.text = ""
	if _luck: _luck.text = ""
	if _elem_fire: _elem_fire.text = ""
	if _elem_water: _elem_water.text = ""
	if _elem_earth: _elem_earth.text = ""
	if _elem_wind: _elem_wind.text = ""
	if _elem_light: _elem_light.text = ""
	if _elem_dark: _elem_dark.text = ""
	if _skill_atk: _skill_atk.text = ""
	if _skill_support: _skill_support.text = ""
	if _skill_special: _skill_special.text = ""
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
	_update_preview(null)


func _browse_scene() -> void:
	var fd := FileDialog.new()
	fd.access = FileDialog.ACCESS_RESOURCES
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.filters = PackedStringArray(["*.tscn ; Scenes"])
	fd.file_selected.connect(func(p):
		_scene.text = p
		_update_preview_from_inputs()
	)
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


func _find_item_index(list: ItemList, text: String) -> int:
	for i in range(list.item_count):
		if list.get_item_text(i) == text:
			return i
	return -1


func _texture_from_scene(res: Resource) -> Dictionary:
	if "scene" in res and res.scene and res.scene is PackedScene:
		var inst := (res.scene as PackedScene).instantiate()
		var tex: Texture2D = null
		var mod := Color(1, 1, 1, 1)
		if inst:
			var spr := inst.get_node_or_null("SpriteRoot/Sprite2D")
			if spr and spr is Sprite2D and spr.texture:
				tex = spr.texture
				mod = spr.modulate
			elif inst is Sprite2D and inst.texture:
				tex = inst.texture
			else:
				for child in inst.get_children():
					if child is Sprite2D and child.texture:
						tex = child.texture
						mod = child.modulate
						break
			inst.queue_free()
		return {"tex": tex, "modulate": mod}
	return {}


func sync_from_node(category: String, data_id: String) -> void:
	if category == "":
		return
	var cat_idx := _find_item_index(_categories, category)
	if cat_idx == -1:
		return
	_pending_select_id = data_id
	var current_sel := _categories.get_selected_items()
	var already_selected := current_sel.size() > 0 and current_sel[0] == cat_idx
	_categories.select(cat_idx)
	_current_category = category
	if already_selected:
		_refresh_assets(true)
	else:
		_on_category_selected(cat_idx)


func _update_preview(res: Resource) -> void:
	if _preview == null:
		return
	_preview.modulate = Color(1, 1, 1, 1)
	if res == null:
		_preview.texture = null
		return
	var scene_info := _texture_from_scene(res)
	var tex: Texture2D = null
	var mod := Color(1, 1, 1, 1)
	if scene_info.has("tex"):
		tex = scene_info["tex"]
	if scene_info.has("modulate") and scene_info["modulate"] is Color:
		mod = scene_info["modulate"]
	if "sprite" in res and res.sprite:
		tex = res.sprite
	elif "texture" in res and res.texture:
		tex = res.texture
	_preview.texture = tex
	_preview.modulate = mod


func _update_preview_from_inputs() -> void:
	# Build a lightweight proxy using current inputs to preview pending changes
	var proxy := Resource.new()
	var scene_path := _scene.text.strip_edges()
	if scene_path != "":
		var ps := load(scene_path)
		if ps and ps is PackedScene:
			proxy.set("scene", ps)
	if proxy == null:
		_update_preview(null)
	else:
		_update_preview(proxy)
