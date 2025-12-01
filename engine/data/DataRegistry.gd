extends Node

signal data_changed

const CATEGORY_DIRS := {
	"Actor": "res://data/actors",
	"AIProfile": "res://data/ai_profiles",
	"Biome": "res://data/biomes",
	"Faction": "res://data/factions",
	"Item": "res://data/items",
	"LootTable": "res://data/loot_tables",
	"Particles": "res://data/particles",
	"Scenery": "res://data/platforms",
	"Prefab": "res://data/prefabs",
	"Projectile": "res://data/projectiles",
	"PolygonTemplate": "res://data/polygon_templates",
	"Quest": "res://data/quests",
	"Region": "res://data/regions",
	"Sound": "res://data/sounds",
	"Spawner": "res://data/spawners",
	"Stats": "res://data/stats",
	"StatusEffect": "res://data/status_effects",
	"Strings": "res://data/strings",
	"Trap": "res://data/traps",
	"Trigger": "res://data/triggers",
	"Weather": "res://data/weather",
}

var _by_id: Dictionary = {}
var _by_category: Dictionary = {}
var _by_category_map: Dictionary = {}

func _ready() -> void:
	_rescan()


func _rescan() -> void:
	_by_id.clear()
	_by_category.clear()
	_by_category_map.clear()
	var cats: Array = CATEGORY_DIRS.keys()
	cats.sort()
	for cat in cats:
		_by_category[cat] = []
		_by_category_map[cat] = {}
		var dir_path: String = CATEGORY_DIRS[cat]
		DirAccess.make_dir_recursive_absolute(dir_path)
		_load_dir(cat, dir_path)
	data_changed.emit()


func _load_dir(category: String, dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if dir.current_is_dir():
			fname = dir.get_next()
			continue
		if not fname.ends_with(".tres"):
			fname = dir.get_next()
			continue
		var full_path: String = dir_path.path_join(fname)
		var res := ResourceLoader.load(full_path)
		if res:
			var rid: String = ""
			if "id" in res:
				rid = res.id
			else:
				rid = fname.get_basename()
			_by_id[rid] = {"resource": res, "path": full_path, "category": category}
			_by_category[category].append(rid)
			_by_category_map[category][rid] = {"resource": res, "path": full_path}
		fname = dir.get_next()
	dir.list_dir_end()


func get_ids(category: String = "") -> Array:
	var ids: Array = []
	if category != "" and _by_category.has(category):
		ids = _by_category[category].duplicate()
	else:
		ids = _by_id.keys()
	# Filter out legacy/base entries
	ids = ids.filter(func(id):
		if id == null:
			return false
		var s := String(id)
		return not s.begins_with("Base"))
	return ids


func get_resource(id: String):
	if _by_id.has(id):
		return _by_id[id]["resource"]
	return null

func get_resource_for_category(category: String, id: String):
	if _by_category_map.has(category) and _by_category_map[category].has(id):
		return _by_category_map[category][id]["resource"]
	return get_resource(id)

func get_resource_path_by_id(id: String) -> String:
	if _by_id.has(id):
		return _by_id[id]["path"]
	return ""

func get_resource_path(category: String, id: String) -> String:
	if _by_category_map.has(category) and _by_category_map[category].has(id):
		return _by_category_map[category][id]["path"]
	return get_resource_path_by_id(id)


func save_resource(category: String, id: String, res: Resource) -> void:
	if not CATEGORY_DIRS.has(category):
		push_error("Unknown category %s" % category)
		return
	var dir_path: String = CATEGORY_DIRS[category]
	DirAccess.make_dir_recursive_absolute(dir_path)
	var path: String = dir_path.path_join("%s.tres" % id)
	var err := ResourceSaver.save(res, path)
	if err != OK:
		push_error("Failed to save resource %s err %d" % [path, err])
		return
	_by_id[id] = {"resource": res, "path": path, "category": category}
	if not _by_category.has(category):
		_by_category[category] = []
	if not _by_category[category].has(id):
		_by_category[category].append(id)
	data_changed.emit()


func remove(id: String) -> void:
	if not _by_id.has(id):
		return
	var info: Dictionary = _by_id[id]
	var path: String = info["path"]
	var cat: String = info["category"]
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	_by_id.erase(id)
	if _by_category.has(cat):
		_by_category[cat].erase(id)
	data_changed.emit()
