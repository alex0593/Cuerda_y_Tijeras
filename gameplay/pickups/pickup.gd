# Pickup genérico: hilo (moneda), llave, item.
extends Area2D

@export var kind := "thread"
var _flash_time := 0.0
var _rejected := false

func _ready() -> void:
	add_to_group("pickup")
	body_entered.connect(_on_body)
	var label := Label.new()
	label.name = "Label"
	label.text = _display_name()
	label.position = Vector2(-70, -76)
	label.size = Vector2(140, 46)
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
	if _flash_time > 0.0:
		_flash_time -= delta
		var visual := get_node_or_null("Vis") as Polygon2D
		if visual:
			visual.modulate = Color(1.0, 0.55, 0.55) if int(_flash_time * 8.0) % 2 == 0 else Color(1, 1, 1)
		if _flash_time <= 0.0 and visual:
			visual.modulate = Color(1, 1, 1)
	# Imán atrae recursos (doc 05), pero no lo que no se puede recoger:
	# si no, los objetos rechazados se acumulan sobre la jugadora.
	if "iron_magnet" in GameState.items and _is_collectable():
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p:
			var d: float = global_position.distance_to(p.global_position)
			if d < 96.0:
				global_position = global_position.move_toward(p.global_position, 220.0 * delta)

func _is_collectable() -> bool:
	if not kind.begins_with("item:"):
		return true
	var info := GameState.get_swap_info(kind.trim_prefix("item:"))
	if bool(info.get("needs_swap", false)):
		return true
	return String(info.get("reason", "")) == ""

func _on_body(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var consumed := true
	if kind.begins_with("item:"):
		var item_id := kind.trim_prefix("item:")
		consumed = GameState.add_item(item_id)
		if not consumed:
			var info := GameState.get_swap_info(item_id)
			if bool(info.get("needs_swap", false)):
				# El slot está lleno: que la jugadora decida a quién cambia.
				GameState.swap_requested.emit(self, item_id, info.get("candidates", []))
			else:
				# Sin feedback el objeto parece roto: la jugadora no entiende por qué
				# no se recoge (doc 05, restricciones deben ser legibles).
				_reject(String(info.get("reason", "no se puede llevar")))
	else:
		GameState.add_resource(kind)
	if consumed:
		queue_free()

func _reject(reason: String) -> void:
	_flash_time = 0.6
	var label := get_node_or_null("Label") as Label
	if label and not _rejected:
		_rejected = true
		label.text = "%s\n%s" % [_display_name(), reason]
		label.add_theme_color_override("font_color", Color(0.85, 0.45, 0.40))
