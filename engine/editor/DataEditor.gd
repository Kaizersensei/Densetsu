extends Control

@onready var _categories: ItemList = $Root/ScrollLeft/CategoriesBox/Categories
@onready var _assets: ItemList = $Root/ScrollAssets/AssetsBox/Assets
@onready var _preview: TextureRect = $Root/ScrollAssets/AssetsBox/PreviewBox/PreviewTexture
@onready var _btn_new: Button = $Root/ScrollAssets/AssetsBox/Buttons/New
@onready var _btn_save: Button = $Root/ScrollAssets/AssetsBox/Buttons/Save
@onready var _btn_reload: Button = $Root/ScrollAssets/AssetsBox/Buttons/Reload
@onready var _btn_delete: Button = $Root/ScrollAssets/AssetsBox/Buttons/Delete

var _current_category: String = ""
var _current_id: String = ""
var _pending_select_id: String = ""
var _current_res: Resource = null
# dynamic UI building
var _dynamic_inspector: VBoxContainer
var _inspector_rows: Dictionary = {} # key -> {row, label, ctrl}
var _dynamic_fields: Dictionary = {}
var _dynamic_box: VBoxContainer = null
var _key_controls: Dictionary = {}
var _group_core: Array = []
var _group_actor: Array = []
var _group_spawner: Array = []
var _group_collision: Array = []
var _group_scene: Array = []
var _label_ai_params_default: String = ""
# legacy placeholders (unused in dynamic builder, but kept to avoid null refs)
var _scene: LineEdit = null
var _scene_browse: Button = null
var _spawner_scene_browse: Button = null
var _spawner_spawn_scene: LineEdit = null
var _min_spawn: LineEdit = null
var _max_spawn: LineEdit = null
var _cooldown: LineEdit = null
var _active_start: LineEdit = null
var _active_end: LineEdit = null
var _spawn_on_start: CheckBox = null
var _show_in_game: CheckBox = null
var _team: LineEdit = null
var _behavior_locate: Button = null
var _dialogue_locate: Button = null
var _loot_locate: Button = null
var _inventory_locate: Button = null
var _patrol_locate: Button = null
var _schedule_locate: Button = null
var _behavior_create: Button = null
var _dialogue_create: Button = null
var _loot_create: Button = null
var _inventory_create: Button = null
var _patrol_create: Button = null
var _schedule_create: Button = null

const FIELD_TYPES := {
	"bool": "CheckBox",
	"int": "LineEdit",
	"float": "LineEdit",
	"string": "LineEdit",
	"resource": "LineEdit",
	"color": "LineEdit",
}

const CATEGORY_CONTROLS := {
	"Actor": [
		{"key": "path", "label": "Path", "type": "string"},
		{"key": "id", "label": "Id", "type": "string"},
		{"key": "tags", "label": "Tags", "type": "string"},
		{"key": "type", "label": "Type", "type": "string"},
		{"key": "lifecycle_state", "label": "Lifecycle", "type": "string"},
		{"key": "input_source", "label": "Input", "type": "string"},
		{"key": "player_number", "label": "Player", "type": "int"},
		{"key": "faction_id", "label": "Faction", "type": "string"},
		{"key": "aggressiveness", "label": "Aggro", "type": "int"},
		{"key": "behavior_profile_id", "label": "Behavior", "type": "string"},
		{"key": "dialogue_id", "label": "Dialogue", "type": "string"},
		{"key": "loot_table_id", "label": "Loot", "type": "string"},
		{"key": "inventory_template_id", "label": "Inventory", "type": "string"},
		{"key": "patrol_path_id", "label": "Patrol", "type": "string"},
		{"key": "schedule_id", "label": "Schedule", "type": "string"},
		{"key": "movement_id", "label": "Movement", "type": "string"},
		{"key": "spawn_respawn", "label": "Respawn", "type": "bool"},
		{"key": "spawn_unique", "label": "Unique", "type": "bool"},
		{"key": "spawn_persistent", "label": "Persistent", "type": "bool"},
		{"key": "spawn_radius", "label": "Spawn Radius", "type": "float"},
		{"key": "level", "label": "Level", "type": "int"},
		{"key": "xp_value", "label": "XP", "type": "int"},
		{"key": "ai_state_init", "label": "AI State", "type": "string"},
		{"key": "ai_params", "label": "AI Params", "type": "string"},
		{"key": "collision_layer", "label": "Collision Layer", "type": "int"},
		{"key": "collision_layers", "label": "Collision Layers", "type": "int"},
		{"key": "collision_mask", "label": "Collision Mask", "type": "int"},
		{"key": "sprite", "label": "Sprite", "type": "string"},
		{"key": "tint", "label": "Tint", "type": "color"},
	],
	"Item": [
		{"key": "path", "label": "Path", "type": "string"},
		{"key": "id", "label": "Id", "type": "string"},
		{"key": "tags", "label": "Tags", "type": "string"},
		{"key": "sprite", "label": "Sprite", "type": "string"},
		{"key": "scene", "label": "Scene", "type": "string"},
		{"key": "amount", "label": "Amount", "type": "int"},
		{"key": "auto_pickup", "label": "Auto Pickup", "type": "bool"},
		{"key": "float_idle", "label": "Float Idle", "type": "bool"},
		{"key": "slots_needed", "label": "Slots Needed", "type": "int"},
		{"key": "max_stack", "label": "Max Stack", "type": "int"},
		{"key": "value", "label": "Value", "type": "int"},
		{"key": "is_equippable", "label": "Equippable", "type": "bool"},
		{"key": "equip_slot", "label": "Equip Slot", "type": "string"},
		{"key": "is_consumable", "label": "Consumable", "type": "bool"},
		{"key": "is_subweapon", "label": "Subweapon", "type": "bool"},
		{"key": "subweapon_projectile_id", "label": "Subweapon Projectile", "type": "string"},
		{"key": "collision_layer", "label": "Collision Layer", "type": "int"},
		{"key": "collision_mask", "label": "Collision Mask", "type": "int"},
	],
	"Scenery": [
		{"key": "path", "label": "Path", "type": "string"},
		{"key": "id", "label": "Id", "type": "string"},
		{"key": "tags", "label": "Tags", "type": "string"},
		{"key": "scene", "label": "Scene", "type": "string"},
		{"key": "platform_type", "label": "Platform Type", "type": "string"},
		{"key": "slope_direction", "label": "Slope Direction", "type": "string"},
		{"key": "speed", "label": "Speed", "type": "float"},
		{"key": "movement_path_id", "label": "Movement Path", "type": "string"},
		{"key": "allow_projectile_collision", "label": "Allow Projectile Collision", "type": "bool"},
		{"key": "collision_layer", "label": "Collision Layer", "type": "int"},
		{"key": "collision_mask", "label": "Collision Mask", "type": "int"},
		{"key": "tint", "label": "Tint", "type": "color"},
	],
	"Faction": [
		{"key": "path", "label": "Path", "type": "string"},
		{"key": "id", "label": "Id", "type": "string"},
		{"key": "tags", "label": "Tags", "type": "string"},
		{"key": "hostility_table", "label": "Hostility Table", "type": "dict"},
		{"key": "base_loot_table_id", "label": "Base Loot", "type": "string"},
	],
	"Weather": [
		{"key": "path", "label": "Path", "type": "string"},
		{"key": "id", "label": "Id", "type": "string"},
		{"key": "tags", "label": "Tags", "type": "string"},
		{"key": "precipitation_type", "label": "Precipitation", "type": "string"},
		{"key": "intensity", "label": "Intensity", "type": "float"},
		{"key": "wind_speed", "label": "Wind Speed", "type": "float"},
		{"key": "ambient_light", "label": "Ambient Light", "type": "color"},
		{"key": "particle_effect_id", "label": "Particle Effect", "type": "string"},
	],
	"Particles": [
		{"key": "path", "label": "Path", "type": "string"},
		{"key": "id", "label": "Id", "type": "string"},
		{"key": "tags", "label": "Tags", "type": "string"},
		{"key": "particle_path", "label": "Particle Path", "type": "string"},
		{"key": "looping", "label": "Looping", "type": "bool"},
		{"key": "spawn_rate", "label": "Spawn Rate", "type": "float"},
	],
	"Sound": [
		{"key": "path", "label": "Path", "type": "string"},
		{"key": "id", "label": "Id", "type": "string"},
		{"key": "tags", "label": "Tags", "type": "string"},
		{"key": "file_path", "label": "File", "type": "string"},
		{"key": "category", "label": "Category", "type": "string"},
		{"key": "loop", "label": "Loop", "type": "bool"},
		{"key": "volume", "label": "Volume", "type": "float"},
		{"key": "attack_decay", "label": "Attack/Decay", "type": "float"},
	],
	"Strings": [
		{"key": "path", "label": "Path", "type": "string"},
		{"key": "id", "label": "Id", "type": "string"},
		{"key": "tags", "label": "Tags", "type": "string"},
		{"key": "key", "label": "Key", "type": "string"},
		{"key": "value_en", "label": "Value EN", "type": "string"},
		{"key": "value_pt", "label": "Value PT", "type": "string"},
		{"key": "category", "label": "Category", "type": "string"},
	],
	"Movement": [
		{"key": "path", "label": "Path", "type": "string"},
		{"key": "id", "label": "Id", "type": "string"},
		{"key": "tags", "label": "Tags", "type": "string"},
		{"key": "description", "label": "Description", "type": "string"},
		{"key": "gravity", "label": "Gravity", "type": "float"},
		{"key": "move_speed", "label": "Move Speed", "type": "float"},
		{"key": "acceleration", "label": "Acceleration", "type": "float"},
		{"key": "friction_ground", "label": "Ground Friction", "type": "float"},
		{"key": "friction_air", "label": "Air Friction", "type": "float"},
		{"key": "max_fall_speed", "label": "Max Fall Speed", "type": "float"},
		{"key": "slope_penalty", "label": "Slope Penalty", "type": "float"},
		{"key": "jump_speed", "label": "Jump Speed", "type": "float"},
		{"key": "air_jump_speed", "label": "Air Jump Speed", "type": "float"},
		{"key": "max_jumps", "label": "Max Jumps", "type": "int"},
		{"key": "min_jump_height", "label": "Min Jump Height", "type": "float"},
		{"key": "coyote_time", "label": "Coyote Time", "type": "float"},
		{"key": "jump_buffer_time", "label": "Jump Buffer", "type": "float"},
		{"key": "jump_release_gravity_scale", "label": "Release Gravity Scale", "type": "float"},
		{"key": "jump_release_cut", "label": "Release Cut", "type": "float"},
		{"key": "drop_through_time", "label": "Drop Through Time", "type": "float"},
		{"key": "wall_slide_gravity_scale", "label": "Wall Slide Gravity", "type": "float"},
		{"key": "wall_jump_speed_x", "label": "Wall Jump X", "type": "float"},
		{"key": "wall_jump_speed_y", "label": "Wall Jump Y", "type": "float"},
		{"key": "enable_glide", "label": "Enable Glide", "type": "bool"},
		{"key": "glide_gravity_scale", "label": "Glide Gravity", "type": "float"},
		{"key": "glide_max_fall_speed", "label": "Glide Max Fall", "type": "float"},
		{"key": "enable_flight", "label": "Enable Flight", "type": "bool"},
		{"key": "flight_acceleration", "label": "Flight Accel", "type": "float"},
		{"key": "flight_max_speed", "label": "Flight Max Speed", "type": "float"},
		{"key": "flight_drag", "label": "Flight Drag", "type": "float"},
		{"key": "enable_swim", "label": "Enable Swim", "type": "bool"},
		{"key": "swim_speed", "label": "Swim Speed", "type": "float"},
		{"key": "swim_drag", "label": "Swim Drag", "type": "float"},
		{"key": "swim_gravity_scale", "label": "Swim Gravity", "type": "float"},
		{"key": "swim_jump_speed", "label": "Swim Jump", "type": "float"},
		{"key": "enable_flap", "label": "Enable Flap", "type": "bool"},
		{"key": "max_flaps", "label": "Max Flaps", "type": "int"},
		{"key": "flap_impulse", "label": "Flap Impulse", "type": "float"},
	],
	"Spawner": [
		{"key": "path", "label": "Path", "type": "string"},
		{"key": "id", "label": "Id", "type": "string"},
		{"key": "description", "label": "Description", "type": "string"},
		{"key": "spawn_scene", "label": "Spawn Scene", "type": "string"},
		{"key": "min_spawn", "label": "Min Spawn", "type": "int"},
		{"key": "max_spawn", "label": "Max Spawn", "type": "int"},
		{"key": "cooldown", "label": "Cooldown", "type": "float"},
		{"key": "spawn_on_start", "label": "Spawn On Start", "type": "bool"},
		{"key": "active_start_time", "label": "Active Start", "type": "float"},
		{"key": "active_end_time", "label": "Active End", "type": "float"},
		{"key": "team", "label": "Team", "type": "string"},
		{"key": "show_in_game", "label": "Show In Game", "type": "bool"},
		{"key": "target_category", "label": "Target Category", "type": "string"},
		{"key": "target_id", "label": "Target Id", "type": "string"},
		{"key": "spawn_radius", "label": "Spawn Radius", "type": "float"},
		{"key": "collision_layers", "label": "Collision Layers", "type": "int"},
		{"key": "collision_mask", "label": "Collision Mask", "type": "int"},
	],
}

const CATEGORY_SCHEMA := {
	"Actor": [
		"type", "lifecycle_state", "input_source", "player_number",
		"faction_id", "aggressiveness", "behavior_profile_id", "dialogue_id",
		"loot_table_id", "inventory_template_id", "patrol_path_id", "schedule_id",
		"movement_id",
		"spawn_respawn", "spawn_unique", "spawn_persistent", "spawn_radius",
		"level", "xp_value", "ai_state_init", "ai_params",
		"collision_layers", "collision_mask"
	],
	"AIProfile": [],
	"Biome": ["id", "name", "ambient_particle_id", "ambient_sound_id", "color_profile_id"],
	"Faction": ["hostility_table", "base_loot_table_id"],
	"Spawner": [
		"spawn_scene", "min_spawn", "max_spawn", "cooldown",
		"active_start_time", "active_end_time", "spawn_on_start",
		"show_in_game", "team", "collision_layers", "collision_mask"
	],
	"Prefab": ["prefab_path", "category", "allowed_overrides"],
	"Item": [
		"scene", "collision_layer", "collision_mask",
		"sprite", "amount", "auto_pickup", "float_idle",
		"slots_needed", "max_stack", "value",
		"is_equippable", "equip_slot",
		"is_consumable", "is_subweapon", "subweapon_projectile_id"
	],
	"Projectile": ["scene", "collision_layers", "collision_mask"],
	"Trap": ["scene", "collision_layers", "collision_mask"],
	"Scenery": [
		"scene", "collision_layers", "collision_mask",
		"name", "platform_type", "slope_direction",
		"speed", "movement_path_id", "allow_projectile_collision", "tint"
	],
	"Movement": [
		"gravity", "move_speed", "acceleration", "friction_ground", "friction_air",
		"max_fall_speed", "slope_penalty",
		"jump_speed", "air_jump_speed", "max_jumps", "min_jump_height",
		"coyote_time", "jump_buffer_time", "jump_release_gravity_scale", "jump_release_cut", "drop_through_time",
		"wall_slide_gravity_scale", "wall_jump_speed_x", "wall_jump_speed_y",
		"enable_glide", "glide_gravity_scale", "glide_max_fall_speed",
		"enable_flight", "flight_acceleration", "flight_max_speed", "flight_drag",
		"enable_swim", "swim_speed", "swim_drag", "swim_gravity_scale", "swim_jump_speed",
		"enable_flap", "max_flaps", "flap_impulse"
	],
	"PolygonTemplate": [
		"texture_border", "texture_transition", "texture_core",
		"border_width", "transition_width",
		"angle_min", "angle_max",
		"smoothing_threshold_deg", "smoothing_steps",
		"material_override"
	],
	"LootTable": [],
	"Stats": [
		"level", "xp_value",
		"hp", "mp", "strength", "defense", "agility", "intelligence", "luck",
		"elem_fire", "elem_water", "elem_earth", "elem_wind", "elem_light", "elem_dark",
		"elem_thunder", "elem_gaea", "elem_timespace",
		"skill_unarmed", "skill_armed", "skill_ranged", "skill_finesse", "skill_stealth"
	],
	"Region": ["continent", "biome_id", "weather_id", "description", "recommended_level_range"],
	"StatusEffect": [
		"type", "duration", "max_stacks", "tick_interval", "tick_damage",
		"stat_modifiers", "movement_modifiers", "control_modifiers",
		"visual_fx_id", "sound_fx_id",
		"is_dispersed_by_cleanse", "is_temporal", "ignore_invulnerability", "applies_knockback"
	],
	"Strings": ["key", "value_en", "value_pt", "category"],
	"Quest": ["name", "description", "objectives", "rewards", "dependencies", "region_id"],
	"Weather": ["precipitation_type", "intensity", "wind_speed", "ambient_light", "particle_effect_id"],
	"Particles": ["particle_path", "looping", "spawn_rate"],
	"Sound": ["file_path", "category", "loop", "volume", "attack_decay"],
	"Trigger": ["trigger_type", "conditions", "actions", "region_id"],
	"Teleporter": [
		"exit_only", "activation_mode", "activation_action",
		"destination_scene", "dropoff_mode", "dropoff_target", "dropoff_margin", "tint"
	],
}
const CATEGORY_SCRIPTS := {
	"Actor": "res://engine/actors/resources/ActorData.gd",
	"AIProfile": "res://engine/data/resources/AIProfileData.gd",
	"Biome": "res://engine/data/resources/BiomeData.gd",
	"Faction": "res://engine/data/resources/FactionData.gd",
	"Item": "res://engine/data/resources/ItemData.gd",
	"LootTable": "res://engine/data/resources/LootTableData.gd",
	"Particles": "res://engine/data/resources/ParticlesData.gd",
	"Scenery": "res://engine/data/resources/PlatformData.gd",
	"Prefab": "res://engine/data/resources/PrefabData.gd",
	"Projectile": "res://engine/data/resources/ProjectileData.gd",
	"Quest": "res://engine/data/resources/QuestsData.gd",
	"Region": "res://engine/data/resources/RegionData.gd",
	"Sound": "res://engine/data/resources/SoundsData.gd",
	"Spawner": "res://engine/actors/resources/SpawnerData.gd",
	"Stats": "res://engine/data/resources/StatsData.gd",
	"StatusEffect": "res://engine/data/resources/StatusEffectData.gd",
	"Strings": "res://engine/data/resources/StringsData.gd",
	"Trap": "res://engine/data/resources/TrapData.gd",
	"Trigger": "res://engine/data/resources/TriggerData.gd",
	"Weather": "res://engine/data/resources/WeatherData.gd",
	"PolygonTemplate": "res://engine/data/resources/PolygonTemplateData.gd",
	"Teleporter": "res://engine/data/resources/TeleporterData.gd",
}
const CATEGORY_TIPS := {
	"Actor": "Entities with behaviors/inputs; set sprite/scene/collider, AI params, stats.",
	"Spawner": "Spawn definitions; link spawn scene, counts, timing, visibility.",
	"Faction": "Group alignment; affects relationships/hostility.",
	"AIProfile": "Behavior profiles and decision params.",
	"Item": "Pickups/consumables; link sprite/scene and effects.",
	"Projectile": "Shots/bullets; link sprite/scene and damage params.",
	"Trap": "Hazards; link sprite/scene and damage/flags.",
	"Scenery": "Solids/one-ways/slopes/deco; link platform scenes and tints.",
	"PolygonTemplate": "Textures/zones/smoothing defaults for polygon terrain.",
	"LootTable": "Drop lists; define loot roll sets.",
	"Stats": "Stat templates; baseline hp/atk/etc.",
	"Weather": "Weather effect definitions and parameters.",
	"Particles": "Particle presets to reuse in spawners/effects.",
	"Sound": "Sound cues/presets for reuse.",
	"Strings": "Localized or in-game text entries.",
	"Quests": "Quest definitions, objectives, and flow hints.",
	"Teleporter": "Teleport pads; configure activation, destination, dropoff, and tint.",
}

func _ready() -> void:
	_populate_categories()
	_ensure_dropdowns()
	_cache_rows()
	_dynamic_inspector = get_node_or_null("Root/ScrollInspector/Inspector")
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
		var cats: Array = reg.CATEGORY_DIRS.keys()
		cats.sort()
		for cat in cats:
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
	_current_res = null
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
		_build_inspector(_current_category, null)


func _on_category_selected(index: int) -> void:
	_current_category = _categories.get_item_text(index)
	print("[DataEditor] Category selected:", _current_category)
	_refresh_assets(true)


func _on_asset_selected(index: int) -> void:
	if index < 0:
		print("[DataEditor] Asset selection index <0; ignoring")
		return
	_current_id = _assets.get_item_text(index)
	_current_res = null
	_refresh_selection()


func _refresh_selection() -> void:
	_clear_all_fields()
	var reg = _get_registry()
	if reg == null:
		print("[DataEditor] Registry missing; cannot load asset")
		return
	var res_loaded = reg.get_resource_for_category(_current_category, _current_id)
	var path = reg.get_resource_path(_current_category, _current_id)
	print("[DataEditor] Loading asset:", _current_id, "path:", path, "category:", _current_category)
	if res_loaded == null:
		print("[DataEditor] Loaded resource is null for id:", _current_id, "category:", _current_category)
		_build_inspector(_current_category, null, path)
		_update_preview(null)
		return
	_current_res = res_loaded
	_build_inspector(_current_category, _current_res, path)
	_update_preview(res_loaded)


func _fill_common_fields(res: Resource) -> void:
	return


func _fill_category_fields(res: Resource) -> void:
	return
func _on_new() -> void:
	if _current_category == "":
		return
	_current_id = ""
	_current_res = _create_resource_for_category(_current_category)
	_build_inspector(_current_category, _current_res)
	_update_preview(null)


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
	if _inspector_rows.is_empty():
		return
	for key in _inspector_rows.keys():
		var info = _inspector_rows[key]
		if not info.has("ctrl"):
			continue
		var ctrl = info["ctrl"]
		var ftype = String(info.get("type", "string"))
		if ctrl is CheckBox:
			if _res_has(res, key):
				res.set(key, (ctrl as CheckBox).button_pressed)
			continue
		if ctrl is LineEdit:
			var txt := (ctrl as LineEdit).text.strip_edges()
			if key == "id":
				if txt != "":
					_set_res_id(res, txt)
				continue
			if key == "path":
				# managed by registry/save
				continue
			if not _res_has(res, key):
				continue
			match ftype:
				"int":
					if txt != "":
						res.set(key, int(txt))
				"float":
					if txt != "":
						res.set(key, float(txt))
				"bool":
					res.set(key, txt.to_lower() in ["true", "1", "yes", "on"])
				"color":
					if txt != "":
						res.set(key, Color(txt))
				"dict":
					res.set(key, _parse_dict(txt))
				"array":
					var arr: Array = []
					for part in txt.split(",", false, 0):
						var p := String(part).strip_edges()
						if p != "":
							arr.append(p)
					res.set(key, arr)
				"string":
					if key == "tags":
						var tag_list: PackedStringArray = PackedStringArray()
						for t in txt.split(",", false, 0):
							tag_list.append(String(t).strip_edges())
						res.set(key, tag_list)
					elif key.find("scene") != -1 or key == "scene":
						if txt != "":
							var ps := load(txt)
							if ps and ps is PackedScene:
								res.set(key, ps)
					elif key.find("sprite") != -1 or key.find("texture") != -1:
						if txt != "":
							var tex := load(txt)
							if tex:
								res.set(key, tex)
					else:
						res.set(key, txt)
				_:
					res.set(key, txt)


func _on_reload() -> void:
	var reg = _get_registry()
	if reg:
		reg._rescan()
	_refresh_assets()


func _ensure_dropdowns() -> void:
	# dynamic inspector builds its own controls
	return


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
	return


func _set_row_visible(row: Control, flag: bool) -> void:
	return


func _set_block_visible(nodes: Array, flag: bool) -> void:
	return


func _apply_category_visibility(cat: String, res: Resource = null) -> void:
	# Default: show everything
	for k in _inspector_rows.keys():
		var info = _inspector_rows[k]
		if info.has("row") and info.row:
			info.row.visible = true
	if cat != "Movement":
		return
	var enable_glide := _read_bool_field("enable_glide", res)
	var enable_flight := _read_bool_field("enable_flight", res)
	var enable_swim := _read_bool_field("enable_swim", res)
	var enable_flap := _read_bool_field("enable_flap", res)

	var glide_fields := ["glide_gravity_scale", "glide_max_fall_speed"]
	var flight_fields := ["flight_acceleration", "flight_max_speed", "flight_drag"]
	var swim_fields := ["swim_speed", "swim_drag", "swim_gravity_scale", "swim_jump_speed"]
	var flap_fields := ["max_flaps", "flap_impulse"]

	for f in glide_fields:
		if _inspector_rows.has(f):
			_inspector_rows[f]["row"].visible = enable_glide
	for f in flight_fields:
		if _inspector_rows.has(f):
			_inspector_rows[f]["row"].visible = enable_flight
	for f in swim_fields:
		if _inspector_rows.has(f):
			_inspector_rows[f]["row"].visible = enable_swim
	for f in flap_fields:
		if _inspector_rows.has(f):
			_inspector_rows[f]["row"].visible = enable_flap


# Helper to read a bool from a current checkbox or fallback resource
func _read_bool_field(field: String, res: Resource = null) -> bool:
	if _inspector_rows.has(field):
		var ctrl = _inspector_rows[field].get("ctrl", null)
		if ctrl and ctrl is CheckBox:
			return (ctrl as CheckBox).button_pressed
	if res != null and _res_has(res, field):
		return bool(res.get(field))
	return false

func _set_all_keys_visible(flag: bool) -> void:
	return


func _set_key_visible(key: String, flag: bool) -> void:
	return


func _compute_allowed_keys(cat: String, res: Resource = null) -> Array[String]:
	var allowed: Array[String] = ["path", "id", "tags"]
	# schema-first: use declared schema for the category (deterministic)
	if CATEGORY_SCHEMA.has(cat):
		for k in CATEGORY_SCHEMA[cat]:
			var ks = String(k)
			if not allowed.has(ks):
				allowed.append(ks)
	# always ensure the core is present
	if allowed.is_empty():
		allowed = ["path", "id", "tags"]
	return allowed


func _clear_dynamic_fields() -> void:
	return


func _ensure_dynamic_field(key: String, value: Variant = null) -> void:
	if _dynamic_box == null:
		return
	if _dynamic_fields.has(key):
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var lbl := Label.new()
	lbl.text = key
	var line := LineEdit.new()
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	row.add_child(line)
	_dynamic_box.add_child(row)
	_dynamic_fields[key] = {"ctrl": line, "type_hint": value}


func _fill_dynamic_fields(res: Resource) -> void:
	if res == null or _dynamic_box == null:
		return
	for p in res.get_property_list():
		if not p.has("name"):
			continue
		var pname := String(p.name)
		if _key_controls.has(pname):
			continue
		if pname in ["resource_name", "script", "resource_path", "resource_local_to_scene", "resource_scene_unique_id"]:
			continue
		var val = res.get(pname)
		_ensure_dynamic_field(pname, val)
		if _dynamic_fields.has(pname):
			var info = _dynamic_fields[pname]
			if info.has("ctrl") and info.ctrl and info.ctrl is LineEdit:
				var txt := ""
				match typeof(val):
					TYPE_BOOL:
						txt = "true" if val else "false"
					_:
						txt = str(val)
				(info.ctrl as LineEdit).text = txt


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
	return


func _clear_all_fields() -> void:
	_inspector_rows.clear()
	if _dynamic_inspector:
		for child in _dynamic_inspector.get_children():
			_dynamic_inspector.remove_child(child)
			child.queue_free()
	_update_preview(null)


func _build_inspector(cat: String, res: Resource = null, res_path: String = "") -> void:
	_clear_all_fields()
	if _dynamic_inspector == null:
		return
	var rows: Array = []
	# core fields always first
	rows.append({"key": "path", "label": "Path", "type": "string"})
	rows.append({"key": "id", "label": "Id", "type": "string"})
	rows.append({"key": "tags", "label": "Tags", "type": "string"})
	if CATEGORY_CONTROLS.has(cat):
		for entry in CATEGORY_CONTROLS[cat]:
			rows.append(entry)
	var seen: Dictionary = {}
	for r in rows:
		var key := String(r.get("key", ""))
		if key == "" or seen.has(key):
			continue
		seen[key] = true
		var label_text := String(r.get("label", key.capitalize()))
		var ftype := String(r.get("type", "string")).to_lower()
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var lbl := Label.new()
		lbl.text = label_text
		lbl.custom_minimum_size = Vector2(140, 0)
		var ctrl: Control = null
		if ftype == "bool":
			var cb := CheckBox.new()
			ctrl = cb
			# For movement module toggles, re-apply visibility when toggled
			if cat == "Movement" and key in ["enable_glide", "enable_flight", "enable_swim", "enable_flap"]:
				cb.toggled.connect(func(_val): _apply_category_visibility(cat, _current_res))
		else:
			var le := LineEdit.new()
			le.placeholder_text = key
			le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if ftype == "color":
				le.text_changed.connect(_update_preview_from_inputs)
			ctrl = le
		row.add_child(lbl)
		row.add_child(ctrl)
		_dynamic_inspector.add_child(row)
		_inspector_rows[key] = {"row": row, "label": lbl, "ctrl": ctrl, "type": ftype}
		# set value if available
		if res != null and _res_has(res, key):
			var val = res.get(key)
			if ctrl is CheckBox:
				(ctrl as CheckBox).button_pressed = bool(val)
			elif ctrl is LineEdit:
				var txt := ""
				if key == "tags" and val is PackedStringArray:
					txt = ",".join(val)
				elif ftype == "dict" and val is Dictionary:
					txt = _serialize_dict(val)
				elif ftype == "array" and val is Array:
					var parts: Array[String] = []
					for v in val:
						parts.append(str(v))
					txt = ",".join(parts)
				elif ftype == "color" and val is Color:
					txt = (val as Color).to_html()
				elif val is PackedScene or val is Texture2D:
					if val is Resource and String(val.resource_path) != "":
						txt = String(val.resource_path)
				elif val is Color:
					txt = (val as Color).to_html()
				else:
					txt = str(val)
				(ctrl as LineEdit).text = txt
		else:
			if key == "path" and res_path != "" and ctrl is LineEdit:
				(ctrl as LineEdit).text = res_path
	# Apply category-specific visibility (e.g., hide module fields)
	_apply_category_visibility(cat, res)


func _browse_scene() -> void:
	var fd := FileDialog.new()
	fd.access = FileDialog.ACCESS_RESOURCES
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.filters = PackedStringArray(["*.tscn ; Scenes"])
	fd.file_selected.connect(func(p):
		if _inspector_rows.has("scene"):
			var ctrl = _inspector_rows["scene"].get("ctrl", null)
			if ctrl and ctrl is LineEdit:
				(ctrl as LineEdit).text = p
		_update_preview_from_inputs()
	)
	add_child(fd)
	fd.popup_centered()


func _browse_spawn_scene() -> void:
	var fd := FileDialog.new()
	fd.access = FileDialog.ACCESS_RESOURCES
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.filters = PackedStringArray(["*.tscn ; Scenes"])
	fd.file_selected.connect(func(p):
		if _inspector_rows.has("spawn_scene"):
			var ctrl = _inspector_rows["spawn_scene"].get("ctrl", null)
			if ctrl and ctrl is LineEdit:
				(ctrl as LineEdit).text = p
	)
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


func _res_has(res: Object, key: String) -> bool:
	if res == null:
		return false
	for p in res.get_property_list():
		if p.has("name") and String(p.name) == key:
			return true
	return false


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
	if "tint" in res and res.tint is Color:
		mod = res.tint
	_preview.texture = tex
	_preview.modulate = mod


func _update_preview_from_inputs() -> void:
	# Build a lightweight proxy using current inputs to preview pending changes
	var proxy := Resource.new()
	var scene_path := ""
	if _inspector_rows.has("scene"):
		var ctrl = _inspector_rows["scene"].get("ctrl", null)
		if ctrl and ctrl is LineEdit:
			scene_path = (ctrl as LineEdit).text.strip_edges()
	if _inspector_rows.has("sprite"):
		var sctrl = _inspector_rows["sprite"].get("ctrl", null)
		if sctrl and sctrl is LineEdit:
			var stxt := (sctrl as LineEdit).text.strip_edges()
			if stxt != "":
				var tex := load(stxt)
				if tex and tex is Texture2D:
					proxy.set("sprite", tex)
	if scene_path != "":
		var ps := load(scene_path)
		if ps and ps is PackedScene:
			proxy.set("scene", ps)
	if _inspector_rows.has("tint"):
		var tctrl = _inspector_rows["tint"].get("ctrl", null)
		if tctrl and tctrl is LineEdit:
			var ttxt := (tctrl as LineEdit).text.strip_edges()
			if ttxt != "":
				var col := Color(ttxt)
				proxy.set("tint", col)
	if proxy == null or (not _res_has(proxy, "scene")):
		_update_preview(null)
	else:
		_update_preview(proxy)
