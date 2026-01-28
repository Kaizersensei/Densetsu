@tool
extends Node
class_name AnimDriver3D

@export_category("Targets")
@export var skin_path: NodePath
@export var animation_tree_path: NodePath
@export var animation_player_path: NodePath
@export var animation_library_name: StringName = &"biped"
@export var target_root_path: NodePath

@export_category("Debug")
@export var debug_enabled: bool = false
@export var debug_verbose: bool = false

var _skin: Node
var _anim_tree: AnimationTree
var _anim_playback: AnimationNodeStateMachinePlayback
var _anim_player: AnimationPlayer
var _last_state := ""
var _debug_missing_states: Dictionary = {}


func _ready() -> void:
	_resolve_targets()
	if debug_enabled:
		debug_dump("ready")


func set_state(state_name: String) -> void:
	if state_name == "":
		return
	if _skin != null and not is_instance_valid(_skin):
		_skin = null
	if _skin == null and _anim_playback == null and _anim_player == null:
		_resolve_targets()
	if state_name == _last_state and _can_play_state(state_name):
		return
	_last_state = state_name
	if _skin != null and not is_instance_valid(_skin):
		_skin = null
	if _skin == null:
		_resolve_targets()
	if _skin and _skin.has_method("set_state"):
		_skin.call("set_state", state_name)
		if debug_enabled:
			_debug_log_state(state_name, "skin", true)
		return
	if _anim_playback:
		_anim_playback.travel(state_name)
		if debug_enabled:
			_debug_log_state(state_name, "tree", true)
		return
	if _anim_player:
		var played := _play_animation(state_name)
		if debug_enabled:
			_debug_log_state(state_name, "player", played)
	if debug_enabled and not _can_play_state(state_name):
		_debug_missing_state(state_name)


func set_ragdoll(enabled: bool) -> void:
	if _skin != null and not is_instance_valid(_skin):
		_skin = null
	if _skin == null:
		_resolve_targets()
	if _skin and "ragdoll" in _skin:
		_skin.set("ragdoll", enabled)


func refresh_targets() -> void:
	_resolve_targets()


func _resolve_targets() -> void:
	_skin = null
	_anim_tree = null
	_anim_playback = null
	_anim_player = null
	if skin_path != NodePath(""):
		_skin = _resolve_path(skin_path)
	if _skin == null and target_root_path != NodePath(""):
		var root := _resolve_path(target_root_path)
		if root:
			_skin = root.find_child("GodotPlushSkin", true, false)
	if _skin == null:
		_skin = find_child("GodotPlushSkin", true, false)
	if animation_tree_path != NodePath(""):
		_anim_tree = _resolve_from_target_root(animation_tree_path) as AnimationTree
	elif _skin:
		_anim_tree = _skin.get_node_or_null("AnimationTree")
	if _anim_tree:
		var playback = _anim_tree.get("parameters/StateMachine/playback")
		if playback is AnimationNodeStateMachinePlayback:
			_anim_playback = playback
	if animation_player_path != NodePath(""):
		_anim_player = _pick_anim_player(_resolve_from_target_root(animation_player_path) as AnimationPlayer)
	if _anim_player == null and _skin:
		_anim_player = _pick_anim_player(_skin.get_node_or_null("AnimationPlayer") as AnimationPlayer)
	if _anim_player == null and target_root_path != NodePath(""):
		var root2 := _resolve_path(target_root_path)
		if root2:
			_anim_player = _pick_anim_player(root2.find_child("AnimationPlayer", true, false) as AnimationPlayer)
	if _anim_player == null:
		_anim_player = _pick_anim_player(find_child("AnimationPlayer", true, false) as AnimationPlayer)


func _resolve_from_target_root(path: NodePath) -> Node:
	if target_root_path != NodePath(""):
		var root := _resolve_path(target_root_path)
		if root:
			return root.get_node_or_null(path)
	return _resolve_path(path)


func _resolve_path(path: NodePath) -> Node:
	var node := get_node_or_null(path)
	if node:
		return node
	var parent := get_parent()
	while parent:
		node = parent.get_node_or_null(path)
		if node:
			return node
		parent = parent.get_parent()
	return null


func _pick_anim_player(candidate: AnimationPlayer) -> AnimationPlayer:
	if candidate == null:
		return null
	return candidate


func _play_animation(state_name: String) -> bool:
	if _anim_player == null:
		return false
	if _anim_player.has_animation(state_name):
		_anim_player.play(state_name)
		return true
	if animation_library_name != StringName():
		var lib_name := String(animation_library_name)
		var prefixed := lib_name + "/" + state_name
		if _anim_player.has_animation(prefixed):
			_anim_player.play(prefixed)
			return true
	return false


func _can_play_state(state_name: String) -> bool:
	if _skin and _skin.has_method("set_state"):
		return true
	if _anim_playback:
		return true
	if _anim_player == null:
		return false
	if _anim_player.has_animation(state_name):
		return true
	if animation_library_name != StringName():
		var lib_name := String(animation_library_name)
		var prefixed := lib_name + "/" + state_name
		if _anim_player.has_animation(prefixed):
			return true
	return false


func debug_dump(reason: String = "") -> void:
	_resolve_targets()
	var header := "AnimDriver3D debug"
	if reason != "":
		header += " (" + reason + ")"
	print(header)
	print("- node:", _safe_node_path(self))
	var root := _resolve_path(target_root_path)
	print("- target_root_path:", String(target_root_path), "resolved:", _safe_node_path(root))
	print("- skin_path:", String(skin_path), "resolved:", _safe_node_path(_skin))
	print("- anim_tree_path:", String(animation_tree_path), "resolved:", _safe_node_path(_anim_tree))
	print("- anim_player_path:", String(animation_player_path), "resolved:", _safe_node_path(_anim_player))
	print("- animation_library_name:", String(animation_library_name))
	if _anim_player:
		if "playback_process_mode" in _anim_player:
			print("- anim_player.playback_process_mode:", _anim_player.get("playback_process_mode"))
		if "playback_active" in _anim_player:
			print("- anim_player.playback_active:", _anim_player.get("playback_active"))
		print("- anim_player.root_node:", String(_anim_player.root_node))
		print("- anim_player.current_animation:", _anim_player.current_animation)
		if _anim_player.has_method("get_animation_library_list"):
			var libs := _anim_player.get_animation_library_list()
			print("- anim_player.libraries:", libs)
		var anims := _anim_player.get_animation_list()
		print("- anim_player.animation_count:", anims.size())
		if debug_verbose:
			print("- anim_player.animations:", anims)
			if _anim_player.current_animation != "":
				_debug_validate_animation(_anim_player.current_animation)
				_debug_dump_track_bones(_anim_player.current_animation)
			_debug_dump_skeletons()
	elif root:
		var anim_players := root.find_children("*", "AnimationPlayer", true, false)
		var anim_trees := root.find_children("*", "AnimationTree", true, false)
		print("- anim_player.search_count:", anim_players.size())
		if debug_verbose and anim_players.size() > 0:
			var paths: PackedStringArray = PackedStringArray()
			for p in anim_players:
				paths.append(_safe_node_path(p))
			print("- anim_player.paths:", paths)
		print("- anim_tree.search_count:", anim_trees.size())
		if debug_verbose and anim_trees.size() > 0:
			var tpaths: PackedStringArray = PackedStringArray()
			for t in anim_trees:
				tpaths.append(_safe_node_path(t))
			print("- anim_tree.paths:", tpaths)


func _debug_validate_animation(anim_name: String) -> void:
	if _anim_player == null or anim_name == "":
		return
	var anim := _anim_player.get_animation(anim_name)
	if anim == null:
		return
	var root: Node = _anim_player
	if _anim_player.root_node != NodePath(""):
		var root_candidate := _anim_player.get_node_or_null(_anim_player.root_node)
		if root_candidate:
			root = root_candidate
	var skeletons: Array = []
	if root:
		skeletons = root.find_children("*", "Skeleton3D", true, false)
	print("- debug_validate:", anim_name, "tracks:", anim.get_track_count(), "root:", _safe_node_path(root))
	if skeletons.size() > 0:
		var paths: PackedStringArray = PackedStringArray()
		for skel in skeletons:
			paths.append(_safe_node_path(skel))
		print("- debug_validate.skeletons:", paths)
	var missing_nodes := 0
	var missing_bones := 0
	var resolved_nodes := 0
	var unresolved_samples: PackedStringArray = PackedStringArray()
	var missing_bone_samples: PackedStringArray = PackedStringArray()
	for track_idx in range(anim.get_track_count()):
		var path := anim.track_get_path(track_idx)
		var node_path := NodePath(path.get_concatenated_names())
		var node: Node = null
		if root:
			node = root.get_node_or_null(node_path)
		if node == null:
			missing_nodes += 1
			if unresolved_samples.size() < 5:
				unresolved_samples.append(String(path))
			continue
		resolved_nodes += 1
		if node is Skeleton3D and path.get_subname_count() > 0:
			var bone_name := String(path.get_subname(0))
			if (node as Skeleton3D).find_bone(bone_name) == -1:
				missing_bones += 1
				if missing_bone_samples.size() < 5:
					missing_bone_samples.append(bone_name)
	print("- debug_validate.nodes_resolved:", resolved_nodes, "missing_nodes:", missing_nodes)
	if unresolved_samples.size() > 0:
		print("- debug_validate.unresolved_samples:", unresolved_samples)
	if missing_bones > 0:
		print("- debug_validate.missing_bones:", missing_bones)
		print("- debug_validate.missing_bone_samples:", missing_bone_samples)


func _debug_dump_skeletons() -> void:
	if _anim_player == null:
		return
	var root: Node = _anim_player
	if _anim_player.root_node != NodePath(""):
		var root_candidate := _anim_player.get_node_or_null(_anim_player.root_node)
		if root_candidate:
			root = root_candidate
	if root == null:
		return
	var skeletons := root.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		print("- debug_skeletons: none")
		return
	for skel in skeletons:
		var s := skel as Skeleton3D
		if s == null:
			continue
		var bone_count := s.get_bone_count()
		print("- debug_skeleton:", _safe_node_path(s), "bones:", bone_count)
		if bone_count > 0:
			var sample: PackedStringArray = PackedStringArray()
			for i in range(min(10, bone_count)):
				sample.append(s.get_bone_name(i))
			print("- debug_skeleton.bone_sample:", sample)


func _debug_dump_track_bones(anim_name: String) -> void:
	if _anim_player == null or anim_name == "":
		return
	var anim := _anim_player.get_animation(anim_name)
	if anim == null:
		return
	var root: Node = _anim_player
	if _anim_player.root_node != NodePath(""):
		var root_candidate := _anim_player.get_node_or_null(_anim_player.root_node)
		if root_candidate:
			root = root_candidate
	var bone_samples: PackedStringArray = PackedStringArray()
	for track_idx in range(anim.get_track_count()):
		var path := anim.track_get_path(track_idx)
		var node_path := NodePath(path.get_concatenated_names())
		var node: Node = null
		if root:
			node = root.get_node_or_null(node_path)
		if node is Skeleton3D and path.get_subname_count() > 0:
			var bone_name := String(path.get_subname(0))
			if bone_samples.has(bone_name):
				continue
			bone_samples.append(bone_name)
			if bone_samples.size() >= 10:
				break
	if bone_samples.is_empty():
		print("- debug_track_bones:", anim_name, "no skeleton track bones resolved")
	else:
		print("- debug_track_bones:", anim_name, bone_samples)


func _debug_missing_state(state_name: String) -> void:
	if _debug_missing_states.has(state_name):
		return
	_debug_missing_states[state_name] = true
	debug_dump("missing state: " + state_name)


func _debug_log_state(state_name: String, method: String, played: bool) -> void:
	if not debug_enabled:
		return
	var msg := "AnimDriver3D state=" + state_name + " method=" + method + " played=" + str(played)
	if _anim_player:
		msg += " current=" + _anim_player.current_animation
	print(msg)


func _safe_node_path(node: Node) -> String:
	if node == null:
		return "<null>"
	if not is_instance_valid(node):
		return "<freed>"
	return String(node.get_path())
