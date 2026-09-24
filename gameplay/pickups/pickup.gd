# Pickup genérico: hilo (moneda), llave, item.
extends Area2D

@export var kind := "thread"

func _ready() -> void:
	add_to_group("pickup")
	body_entered.connect(_on_body)

func _physics_process(delta: float) -> void:
	# Imán atrae recursos (doc 05).
	if "iron_magnet" in GameState.items:
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p:
			var d: float = global_position.distance_to(p.global_position)
			if d < 96.0:
				global_position = global_position.move_toward(p.global_position, 220.0 * delta)

func _on_body(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if kind.begins_with("item:"):
		GameState.add_item(kind.trim_prefix("item:"))
	else:
		GameState.rooms_visited += 0 # placeholder economía hilos
	queue_free()
