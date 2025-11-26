extends Node

class_name ActorInterface

signal actor_initialized(actor)
signal actor_state_changed(new_state: String)
signal actor_tag_added(tag: String)
signal actor_tag_removed(tag: String)
signal actor_damaged(amount: int, source_id: int)
signal actor_died(source_id: int)

var actor_id: int = -1
var actor_type: String = ""
var tags: Array[String] = []
var active_state: String = "active"

var owner_root: Node
var fsm: Node
var stats: Node
var combat: Node
var inventory: Node
var ai: Node

func initialize(actor: Node) -> void:
	owner_root = actor
	actor_id = actor.get_instance_id()
	actor_type = _infer_actor_type(actor)
	_bind_components(actor)
	if owner_root and owner_root.has_method("add_to_group"):
		owner_root.add_to_group("actors")
	emit_signal("actor_initialized", self)
	on_actor_ready()


func on_actor_ready() -> void:
	pass


func on_actor_update(_delta: float) -> void:
	pass


func on_actor_physics(_delta: float) -> void:
	pass


func on_actor_hit(hit_info) -> void:
	pass


func on_actor_death() -> void:
	pass


func on_actor_respawn() -> void:
	pass


func set_active_state(new_state: String) -> void:
	if active_state == new_state:
		return
	active_state = new_state
	emit_signal("actor_state_changed", new_state)


func add_tag(tag: String) -> void:
	if not tags.has(tag):
		tags.append(tag)
		emit_signal("actor_tag_added", tag)


func remove_tag(tag: String) -> void:
	if tags.has(tag):
		tags.erase(tag)
		emit_signal("actor_tag_removed", tag)


func has_tag(tag: String) -> bool:
	return tag in tags


func get_actor_id() -> int:
	return actor_id


func get_actor_type() -> String:
	return actor_type


func get_root() -> Node:
	return owner_root


func get_fsm() -> Node:
	return fsm


func apply_damage(amount: int, source_id: int = -1) -> void:
	emit_signal("actor_damaged", amount, source_id)
	if stats and stats.has_method("apply_damage"):
		stats.apply_damage(amount, source_id)
	on_actor_hit({"amount": amount, "source_id": source_id})


func apply_knockback(_vec: Vector2) -> void:
	pass


func apply_status_effect(_effect_id) -> void:
	pass


func change_state(state_name: String, ctx := {}) -> void:
	if fsm and fsm.has_method("request_state"):
		fsm.request_state(state_name, ctx)


func is_state(state_name: String) -> bool:
	if fsm and fsm is StateMachine:
		var sm: StateMachine = fsm
		return sm.current_state == state_name
	return false


func distance_to(other_actor: Node) -> float:
	if owner_root and other_actor and owner_root.has_method("global_position") and other_actor.has_method("global_position"):
		return owner_root.global_position.distance_to(other_actor.global_position)
	return 0.0


func direction_to(other_actor: Node) -> Vector2:
	if owner_root and other_actor and owner_root.has_method("global_position") and other_actor.has_method("global_position"):
		return (other_actor.global_position - owner_root.global_position).normalized()
	return Vector2.ZERO


func _infer_actor_type(actor: Node) -> String:
	if actor is CharacterBody2D:
		return "character"
	if actor is Area2D:
		return "area"
	if actor is StaticBody2D:
		return "static"
	return "actor"


func _bind_components(actor: Node) -> void:
	fsm = actor.get_node_or_null("StateMachine")
	stats = actor.get_node_or_null("StatsComponent")
	combat = actor.get_node_or_null("Combat")
	inventory = actor.get_node_or_null("Inventory")
	ai = actor.get_node_or_null("AI")
	if stats and stats.has_signal("died"):
		stats.died.connect(_on_stats_died)


func _on_stats_died(source_id: int) -> void:
	emit_signal("actor_died", source_id)
	on_actor_death()
