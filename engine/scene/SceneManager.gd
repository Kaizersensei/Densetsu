extends Node

# Centralized helpers to apply data resources to scene nodes.

func _ready() -> void:
	pass


func _registry():
	if Engine.has_singleton("DataRegistry"):
		return Engine.get_singleton("DataRegistry")
	if has_node("/root/DataRegistry"):
		return get_node("/root/DataRegistry")
	return null


func infer_category_from_id(data_id: String) -> String:
	var upper := data_id.to_upper()
	if upper.begins_with("ACTOR_"):
		if upper.begins_with("ACTOR_DECO"):
			return "Scenery"
		return "Actor"
	if upper.begins_with("SCENERY_"):
		return "Scenery"
	if upper.begins_with("SPAWNER_"):
		return "Spawner"
	if upper.begins_with("ITEM_"):
		return "Item"
	if upper.begins_with("PROJECTILE_"):
		return "Projectile"
	if upper.begins_with("TRAP_"):
		return "Trap"
	if upper.begins_with("PLATFORM_"):
		return "Scenery"
	if upper.begins_with("AIPROFILE_"):
		return "AIProfile"
	if upper.begins_with("FACTION_"):
		return "Faction"
	if upper.begins_with("LOOTTABLE_"):
		return "LootTable"
	if upper.begins_with("STATS_"):
		return "Stats"
	return ""


func apply_scene_overrides(node: Node, scene: PackedScene) -> void:
	if node == null or scene == null:
		return
	var inst := scene.instantiate()
	if inst == null:
		return
	var tex: Texture2D = null
	var mod := Color(1, 1, 1, 1)
	var spr_inst: Sprite2D = inst.get_node_or_null("SpriteRoot/Sprite2D") as Sprite2D
	if spr_inst and spr_inst.texture:
		tex = spr_inst.texture
		mod = spr_inst.modulate
	var cs_inst := _find_collision_shape(inst)
	var shape: Shape2D = null
	if cs_inst and cs_inst.shape:
		shape = cs_inst.shape.duplicate()
	var poly: PackedVector2Array = PackedVector2Array()
	var poly_color := Color(1, 1, 1, 1)
	var poly_inst: Polygon2D = inst.get_node_or_null("Visual") as Polygon2D
	if poly_inst and poly_inst.polygon.size() > 0:
		poly = poly_inst.polygon.duplicate()
		poly_color = poly_inst.color
	inst.queue_free()
	if tex:
		var target_spr: Sprite2D = node.get_node_or_null("SpriteRoot/Sprite2D") as Sprite2D
		if target_spr:
			target_spr.texture = tex
			target_spr.modulate = mod
		elif node is Sprite2D:
			(node as Sprite2D).texture = tex
	if shape:
		var target_cs := _find_collision_shape(node)
		if target_cs:
			target_cs.shape = shape
	if poly.size() > 0:
		var target_poly: Polygon2D = node.get_node_or_null("Visual") as Polygon2D
		if target_poly:
			target_poly.polygon = poly
			target_poly.color = poly_color


func apply_actor_data(node: Node) -> void:
	if node == null:
		return
	var data_id := _extract_data_id(node)
	if data_id == "":
		return
	var reg = _registry()
	if reg == null or not reg.has_method("get_resource_for_category"):
		return
	var res = reg.get_resource_for_category("Actor", data_id)
	if res == null:
		return
	# Input source hint
	if "use_player_input" in node:
		var wants_player: bool = data_id == "ACTOR_Player"
		if "input_source" in res:
			wants_player = res.input_source == "Player"
		node.set("use_player_input", wants_player)
	if "player_number" in node and "player_number" in res:
		node.set("player_number", res.player_number)
	# Collision properties
	if "collision_layers" in res and "collision_layer" in node:
		node.set("collision_layer", res.collision_layers)
	if "collision_mask" in res and "collision_mask" in node:
		node.set("collision_mask", res.collision_mask)
	# Apply sprite override
	if "sprite" in res and res.sprite:
		var spr := node.get_node_or_null("SpriteRoot/Sprite2D")
		if spr and spr is Sprite2D:
			(spr as Sprite2D).texture = res.sprite
	# Apply collider shape override if provided
	if "collider_shape" in res and res.collider_shape:
		var cs := _find_collision_shape(node)
		if cs:
			cs.shape = res.collider_shape
	# Sync visuals/collider from scene template if provided
	if "scene" in res and res.scene:
		apply_scene_overrides(node, res.scene)
	# Apply tint override after scene override so it sticks
	if "tint" in res and res.tint is Color:
		var spr_after := node.get_node_or_null("SpriteRoot/Sprite2D") as Sprite2D
		if spr_after:
			spr_after.modulate = res.tint
	# Persist id/meta so UI and saves stay in sync
	if "data_id" in node:
		node.set("data_id", data_id)
	else:
		node.set_meta("data_id", data_id)
	if node is Node2D and node.has_method("reset_base_position"):
		node.call("reset_base_position")


func apply_data(node: Node) -> void:
	if node == null:
		return
	var data_id := _extract_data_id(node)
	if data_id == "":
		return
	var reg = _registry()
	if reg == null or not reg.has_method("get_resource_for_category"):
		return
	var cat := infer_category_from_id(data_id)
	if cat == "Actor":
		apply_actor_data(node)
		return
	var res = reg.get_resource_for_category(cat, data_id)
	if res == null:
		return
	# scene overrides first
	if "scene" in res and res.scene:
		apply_scene_overrides(node, res.scene)
	# apply tint override if provided
	if "tint" in res:
		var tint: Color = res.tint
		var spr_all := node.get_node_or_null("SpriteRoot/Sprite2D") as Sprite2D
		if spr_all:
			spr_all.modulate = tint
		elif node is Sprite2D:
			(node as Sprite2D).modulate = tint
		var poly_all := node.get_node_or_null("Visual") as Polygon2D
		if poly_all:
			poly_all.color = tint
	# item visuals
	if cat == "Item":
		if "sprite" in res and res.sprite:
			var spr2 := node.get_node_or_null("SpriteRoot/Sprite2D") as Sprite2D
			if spr2:
				spr2.texture = res.sprite
				if "tint" in res:
					spr2.modulate = res.tint
			elif node is Sprite2D:
				(node as Sprite2D).texture = res.sprite
				if "tint" in res:
					(node as Sprite2D).modulate = res.tint
	# trap/projectile collision/spawner
	if cat in ["Trap", "Projectile", "Spawner"]:
		if "collision_layer" in res and "collision_layer" in node:
			node.set("collision_layer", res.collision_layer)
		if "collision_mask" in res and "collision_mask" in node:
			node.set("collision_mask", res.collision_mask)
	# apply collision if present
	if "collision_layer" in res and "collision_layer" in node:
		node.set("collision_layer", res.collision_layer)
	if "collision_layers" in res and "collision_layer" in node:
		node.set("collision_layer", res.collision_layers)
	if "collision_mask" in res and "collision_mask" in node:
		node.set("collision_mask", res.collision_mask)
	# sprite/texture best-effort
	if "sprite" in res and res.sprite:
		var spr := node.get_node_or_null("SpriteRoot/Sprite2D")
		if spr and spr is Sprite2D:
			(spr as Sprite2D).texture = res.sprite
			if "tint" in res:
				(spr as Sprite2D).modulate = res.tint
		elif node is Sprite2D:
			(node as Sprite2D).texture = res.sprite
			if "tint" in res:
				(node as Sprite2D).modulate = res.tint
	# persist data id
	if "data_id" in node:
		node.set("data_id", data_id)
	else:
		node.set_meta("data_id", data_id)
	if node is Node2D and node.has_method("reset_base_position"):
		node.call("reset_base_position")


func _extract_data_id(node: Node) -> String:
	if node == null:
		return ""
	if node.has_meta("data_id"):
		var meta_val = node.get_meta("data_id")
		if meta_val is String:
			return meta_val
	if "data_id" in node:
		var v = node.get("data_id")
		if v is String:
			return v
	if "id" in node:
		var idv = node.get("id")
		if idv is String:
			return idv
	return node.name


func _find_collision_shape(node: Node) -> CollisionShape2D:
	if node is CollisionShape2D:
		return node
	for child in node.get_children():
		if child is CollisionShape2D:
			return child
		var deeper := _find_collision_shape(child)
		if deeper:
			return deeper
	return null
