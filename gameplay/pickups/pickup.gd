# Pickup genérico: hilo (moneda), llave, item.
extends Area2D

@export var kind := "thread"

func _ready() -> void:
	add_to_group("pickup")
	body_entered.connect(_on_body)
	var label := Label.new()
	label.text = _display_name()
	label.position = Vector2(-70, -34)
	label.size = Vector2(140, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.z_index = 2
	label.add_theme_color_override("font_color", _display_color())
	add_child(label)
	var visual := get_node("Vis") as Polygon2D
	visual.color = _display_color()

func _display_name() -> String:
	if kind.begins_with("item:"):
		var item_id := kind.trim_prefix("item:")
		return String(SynergyDB.get_item(item_id).get("name", item_id))
	return "Hilo" if kind == "thread" else "Llave"

func _display_color() -> Color:
	if kind == "thread":
		return Color(0.78, 0.20, 0.25)
	if kind == "key":
		return Color(0.85, 0.65, 0.18)
	return Color(0.20, 0.45, 0.70)

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
		GameState.add_resource(kind)
	queue_free()
