extends Area2D

@export var item_id: String = ""
@export var amount: int = 1
@export var auto_pickup: bool = true
@export var float_idle: bool = true

var _float_time := 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("items")


func _physics_process(delta: float) -> void:
	if float_idle:
		_float_time += delta
		position.y = sin(_float_time * 2.5) * 3.0


func _on_body_entered(body: Node) -> void:
	if not auto_pickup:
		return
	_give_to(body)


func _give_to(body: Node) -> void:
	print("Item picked:", item_id, "x", amount, "by", body)
	queue_free()
