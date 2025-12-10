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
	if upper.begins_with("MOVEMENT_"):
		return "Movement"
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
	if upper.begins_with("TELEPORTER_"):
		return "Teleporter"
	if upper.begins_with("SPRITE_"):
		return "Sprite"
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
	# Movement template link
	if "movement_id" in res and res.movement_id != "":
		var mres = reg.get_resource_for_category("Movement", res.movement_id)
		if mres:
			_apply_movement(node, mres)
	# Sprite data link
	if "sprite_data_id" in res and res.sprite_data_id != "":
		var sd = reg.get_resource_for_category("Sprite", res.sprite_data_id)
		if sd:
			_apply_sprite_data(node, sd)
	# Movement template link
	if "movement_id" in res and res.movement_id != "":
		var mres = reg.get_resource_for_category("Movement", res.movement_id)
		if mres:
			_apply_movement(node, mres)
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
			spr_after.set_meta("editor_tint", res.tint)
		elif node is Sprite2D:
			(node as Sprite2D).modulate = res.tint
			(node as Sprite2D).set_meta("editor_tint", res.tint)
		var poly_after := node.get_node_or_null("Visual") as Polygon2D
		if poly_after:
			poly_after.color = res.tint
			poly_after.set_meta("editor_tint", res.tint)
	# Teleporter-specific assignments
	if infer_category_from_id(data_id) == "Teleporter":
		if "exit_only" in res and "exit_only" in node:
			node.exit_only = res.exit_only
		if "activation_mode" in res and "activation_mode" in node:
			node.activation_mode = res.activation_mode
		if "activation_action" in res and "activation_action" in node:
			node.activation_action = res.activation_action
		if "destination_scene" in res and "destination_scene" in node:
			node.destination_scene = res.destination_scene
		if "dropoff_mode" in res and "dropoff_mode" in node:
			node.dropoff_mode = res.dropoff_mode
		if "dropoff_target" in res and "dropoff_target" in node:
			node.dropoff_target = res.dropoff_target
		if "dropoff_margin" in res and "dropoff_margin" in node:
			node.dropoff_margin = res.dropoff_margin
	# Persist id/meta so UI and saves stay in sync
	if "data_id" in node:
		node.set("data_id", data_id)
	else:
		node.set_meta("data_id", data_id)
	if node is Node2D and node.has_method("reset_base_position"):
		node.call("reset_base_position")


func _apply_movement(node: Node, mv) -> void:
	if node == null or mv == null:
		return
	# Kinematics
	if "gravity" in node and "gravity" in mv:
		node.gravity = mv.gravity
	if "move_speed" in node and "move_speed" in mv:
		node.move_speed = mv.move_speed
	if "acceleration" in node and "acceleration" in mv:
		node.acceleration = mv.acceleration
	if "friction_ground" in node and "friction_ground" in mv:
		node.friction_ground = mv.friction_ground
	if "friction_air" in node and "friction_air" in mv:
		node.friction_air = mv.friction_air
	if "max_fall_speed" in node and "max_fall_speed" in mv:
		node.max_fall_speed = mv.max_fall_speed
	if "slope_penalty" in node and "slope_penalty" in mv:
		node.slope_penalty = mv.slope_penalty
	# Jump
	if "jump_speed" in node and "jump_speed" in mv:
		node.jump_speed = mv.jump_speed
	if "air_jump_speed" in node and "air_jump_speed" in mv:
		node.air_jump_speed = mv.air_jump_speed
	if "max_jumps" in node and "max_jumps" in mv:
		node.max_jumps = mv.max_jumps
	if "min_jump_height" in node and "min_jump_height" in mv:
		node.min_jump_height = mv.min_jump_height
	if "coyote_time" in node and "coyote_time" in mv:
		node.coyote_time = mv.coyote_time
	if "jump_buffer_time" in node and "jump_buffer_time" in mv:
		node.jump_buffer_time = mv.jump_buffer_time
	if "jump_release_gravity_scale" in node and "jump_release_gravity_scale" in mv:
		node.jump_release_gravity_scale = mv.jump_release_gravity_scale
	if "jump_release_cut" in node and "jump_release_cut" in mv:
		node.jump_release_cut = mv.jump_release_cut
	if "drop_through_time" in node and "drop_through_time" in mv:
		node.drop_through_time = mv.drop_through_time
	# Wall
	if "wall_slide_gravity_scale" in node and "wall_slide_gravity_scale" in mv:
		node.wall_slide_gravity_scale = mv.wall_slide_gravity_scale
	if "wall_jump_speed_x" in node and "wall_jump_speed_x" in mv:
		node.wall_jump_speed_x = mv.wall_jump_speed_x
	if "wall_jump_speed_y" in node and "wall_jump_speed_y" in mv:
		node.wall_jump_speed_y = mv.wall_jump_speed_y
	# Glide
	if "enable_glide" in node and "enable_glide" in mv:
		node.enable_glide = mv.enable_glide
	if "glide_gravity_scale" in node and "glide_gravity_scale" in mv:
		node.glide_gravity_scale = mv.glide_gravity_scale
	if "glide_max_fall_speed" in node and "glide_max_fall_speed" in mv:
		node.glide_max_fall_speed = mv.glide_max_fall_speed
	# Flight
	if "enable_flight" in node and "enable_flight" in mv:
		node.enable_flight = mv.enable_flight
	if "flight_acceleration" in node and "flight_acceleration" in mv:
		node.flight_acceleration = mv.flight_acceleration
	if "flight_max_speed" in node and "flight_max_speed" in mv:
		node.flight_max_speed = mv.flight_max_speed
	if "flight_drag" in node and "flight_drag" in mv:
		node.flight_drag = mv.flight_drag
	# Swim
	if "enable_swim" in node and "enable_swim" in mv:
		node.enable_swim = mv.enable_swim
	if "swim_speed" in node and "swim_speed" in mv:
		node.swim_speed = mv.swim_speed
	if "swim_drag" in node and "swim_drag" in mv:
		node.swim_drag = mv.swim_drag
	if "swim_gravity_scale" in node and "swim_gravity_scale" in mv:
		node.swim_gravity_scale = mv.swim_gravity_scale
	if "swim_jump_speed" in node and "swim_jump_speed" in mv:
		node.swim_jump_speed = mv.swim_jump_speed
	# Flap
	if "enable_flap" in node and "enable_flap" in mv:
		node.enable_flap = mv.enable_flap
	if "max_flaps" in node and "max_flaps" in mv:
		node.max_flaps = mv.max_flaps
	if "flap_impulse" in node and "flap_impulse" in mv:
		node.flap_impulse = mv.flap_impulse


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
	# teleporter props
	if cat == "Teleporter":
		if "exit_only" in res and "exit_only" in node:
			node.exit_only = res.exit_only
		if "activation_mode" in res and "activation_mode" in node:
			node.activation_mode = res.activation_mode
		if "activation_action" in res and "activation_action" in node:
			node.activation_action = res.activation_action
		if "destination_scene" in res and "destination_scene" in node:
			node.destination_scene = res.destination_scene
		if "dropoff_mode" in res and "dropoff_mode" in node:
			node.dropoff_mode = res.dropoff_mode
		if "dropoff_target" in res and "dropoff_target" in node:
			node.dropoff_target = res.dropoff_target
		if "dropoff_margin" in res and "dropoff_margin" in node:
			node.dropoff_margin = res.dropoff_margin
	# apply tint override if provided (covers sprite, polygon, and stores meta)
	if "tint" in res:
		var tint: Color = res.tint
		var spr_all := node.get_node_or_null("SpriteRoot/Sprite2D") as Sprite2D
		if spr_all:
			spr_all.modulate = tint
			spr_all.set_meta("editor_tint", tint)
		elif node is Sprite2D:
			(node as Sprite2D).modulate = tint
			(node as Sprite2D).set_meta("editor_tint", tint)
		var poly_all := node.get_node_or_null("Visual") as Polygon2D
		if poly_all:
			poly_all.color = tint
			poly_all.set_meta("editor_tint", tint)
	# item visuals
	if cat == "Item":
		if "sprite" in res and res.sprite:
			var spr2 := node.get_node_or_null("SpriteRoot/Sprite2D") as Sprite2D
			if spr2:
				spr2.texture = res.sprite
				if "tint" in res:
					spr2.modulate = res.tint
					spr2.set_meta("editor_tint", res.tint)
			elif node is Sprite2D:
				(node as Sprite2D).texture = res.sprite
				if "tint" in res:
					(node as Sprite2D).modulate = res.tint
					(node as Sprite2D).set_meta("editor_tint", res.tint)
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
				(spr as Sprite2D).set_meta("editor_tint", res.tint)
		elif node is Sprite2D:
			(node as Sprite2D).texture = res.sprite
			if "tint" in res:
				(node as Sprite2D).modulate = res.tint
				(node as Sprite2D).set_meta("editor_tint", res.tint)
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


func _apply_sprite_data(node: Node, sd) -> void:
	if sd == null:
		return
	var tint := Color(1, 1, 1, 1)
	if "tint" in sd:
		tint = sd.tint
	var offset := Vector2.ZERO
	if "offset" in sd:
		offset = sd.offset
	var frames = null
	if "frames" in sd:
		frames = sd.frames
	var anim_name := ""
	if "default_animation" in sd:
		anim_name = sd.default_animation
	var speed := 1.0
	if "playback_speed" in sd:
		speed = sd.playback_speed
	var flip_h := false
	var flip_v := false
	if "flip_h" in sd:
		flip_h = sd.flip_h
	if "flip_v" in sd:
		flip_v = sd.flip_v

	var anim: AnimatedSprite2D = node.get_node_or_null("SpriteRoot/AnimatedSprite2D") as AnimatedSprite2D
	if anim == null:
		for child in node.get_children():
			if child is AnimatedSprite2D:
				anim = child
				break
	if anim and frames:
		anim.sprite_frames = frames
		if anim_name != "":
			anim.animation = anim_name
		anim.speed_scale = speed
		anim.flip_h = flip_h
		anim.flip_v = flip_v
		anim.position = offset
		anim.modulate = tint
		return

	var spr2: Sprite2D = node.get_node_or_null("SpriteRoot/Sprite2D") as Sprite2D
	if spr2:
		if frames:
			var use_anim: String = anim_name if anim_name != "" else (frames.get_animation_names()[0] if frames.get_animation_names().size() > 0 else "")
			if use_anim != "" and frames.has_animation(use_anim) and frames.get_frame_count(use_anim) > 0:
				var tex: Texture2D = frames.get_frame_texture(use_anim, 0)
				if tex:
					spr2.texture = tex
		spr2.flip_h = flip_h
		spr2.flip_v = flip_v
		spr2.modulate = tint
		spr2.position = offset
		spr2.set_meta("editor_tint", tint)
