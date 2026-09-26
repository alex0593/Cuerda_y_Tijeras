# Nudo de la tienda del taller (doc 07 §13): la cerradura no es una llave sino
# un nudo que se corta con un tiro, el mismo mecanismo que usa cualquier sala.
# Cortarlo cobra la entrada: un alfiler, o forzarla con hilos si no hay.
extends Area2D

signal opened

const KNOT_SIZE := Vector2(46, 46)

func _ready() -> void:
	collision_layer = 16
	collision_mask = 4  # proyectiles de la jugadora
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = KNOT_SIZE.x * 0.5
	shape.shape = circle
	add_child(shape)

	var knot := Polygon2D.new()
	knot.polygon = PackedVector2Array([
		Vector2(-19, -15), Vector2(19, -15), Vector2(19, 15), Vector2(-19, 15),
	])
	knot.color = Color(0.45, 0.26, 0.14)
	add_child(knot)

	var label := Label.new()
	label.text = "NUDO"
	label.position = Vector2(-40, -46)
	label.size = Vector2(80, 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.32, 0.24, 0.14))
	add_child(label)

	area_entered.connect(_on_area)

# Un tiro corta el nudo y cobra la entrada de la tienda.
func _on_area(area: Area2D) -> void:
	if not area.is_in_group("projectile_player") or not GameState.is_running:
		return
	var entry := GameState.buy_shop_entry()
	if bool(entry.get("ok", false)):
		if String(entry.get("resource", "")) == "alfiler":
			GameState.show_toast("Nudo cortado: alfiler gastado")
		else:
			GameState.show_toast("Nudo cortado: %d hilos" % int(entry.get("cost", 0)))
		opened.emit()
		queue_free()
		return
	# Con recursos la entrada se habría cobrado: solo avisar si falta.
	if GameState.alfilers > 0 or GameState.threads >= int(GameState.get_entry_info().get("cost", 0)):
		return
	GameState.show_toast("Nudo intacto: hace falta %s" % GameState.get_entry_hint())
