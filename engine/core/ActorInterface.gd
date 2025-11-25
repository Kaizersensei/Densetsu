extends Node

## Placeholder interface that Phase Zero actors call into for future composition.
class_name ActorInterface

static func initialize(actor: Node) -> void:
	# Future: wire FSM, stats, and signals here.
	pass


static func post_physics(actor: Node) -> void:
	# Future: state post-processing hook after physics step.
	pass
