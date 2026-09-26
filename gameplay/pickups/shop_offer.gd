# Oferta en el suelo de la tienda (doc 07 §13): un objeto de la pool exclusiva
# o la reparación de vida, con su precio en hilos. Pisarla compra si hay hilos;
# si faltan, se queda en el suelo y puedes volver. Nunca se recoge gratis.
extends Area2D

const CARD_SIZE := Vector2(76, 76)
const NAME_BOX := Rect2(-70, -84, 140, 44)
const PRICE_BOX := Rect2(-70, -16, 140, 32)

# La reparación no es un objeto: se compra con hilos y se puede repetir.
const REPAIR_ID := "repair"

var offer_id := ""
var is_repair := false
var enabled := true

func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = CARD_SIZE
	shape.shape = rectangle
	add_child(shape)

	var color := Color(0.88, 0.52, 0.28) if is_repair else _rarity_color(_rarity())
	var half := CARD_SIZE * 0.5
	var frame := Polygon2D.new()
	frame.polygon = PackedVector2Array([
		Vector2(-half.x - 4, -half.y - 4), Vector2(half.x + 4, -half.y - 4),
		Vector2(half.x + 4, half.y + 4), Vector2(-half.x - 4, half.y + 4),
	])
	frame.color = color.darkened(0.45)
	add_child(frame)

	var card := Polygon2D.new()
	card.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	])
	card.color = color
	add_child(card)

	var ink := Color(0.22, 0.17, 0.11)
	var name := Label.new()
	name.text = "Reparar vida" if is_repair else String(SynergyDB.get_item(offer_id).get("name", offer_id))
	name.position = NAME_BOX.position
	name.size = NAME_BOX.size
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.add_theme_font_size_override("font_size", 16)
	name.add_theme_color_override("font_color", ink)
	add_child(name)

	var price := Label.new()
	price.text = "%d hilos" % price_of()
	price.position = PRICE_BOX.position
	price.size = PRICE_BOX.size
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price.add_theme_font_size_override("font_size", 18)
	price.add_theme_color_override("font_color", ink)
	add_child(price)

	_apply_enabled()
	body_entered.connect(_on_body_entered)

func price_of() -> int:
	return SynergyDB.get_repair_cost() if is_repair else SynergyDB.get_price(offer_id)

func _rarity() -> String:
	return "común" if is_repair else String(SynergyDB.get_item(offer_id).get("rarity", "común"))

# Pisar la oferta compra si hay hilos; si no, avisa y se queda en el suelo.
func _on_body_entered(body: Node) -> void:
	if not enabled or not GameState.is_running:
		return
	if not body.is_in_group("player"):
		return
	if is_repair:
		_on_repair()
		return
	var info := GameState.get_buy_info(offer_id)
	if not bool(info.get("allowed", false)):
		# «ya lo llevas» no debería pasar: la pool ya excluye lo que llevas.
		if String(info.get("reason", "")) != "ya lo llevas":
			GameState.show_toast(String(info.get("reason", "faltan hilos")))
		return
	var bought := GameState.buy_item(offer_id)
	if bool(bought.get("ok", false)):
		var item_name := String(SynergyDB.get_item(offer_id).get("name", offer_id))
		GameState.show_toast("Comprado: %s" % item_name)
		set_enabled(false)
	else:
		GameState.show_toast(String(bought.get("reason", "no se pudo comprar")))

func _on_repair() -> void:
	if GameState.buy_repair():
		GameState.show_toast("Vida reparada")
		return
	# Con la vida llena no hay nada que hacer: no molestar.
	if String(GameState.get_repair_info().get("reason", "")) != "la vida ya está llena":
		GameState.show_toast(String(GameState.get_repair_info().get("reason", "no se pudo reparar")))

# La tienda cerrada no enseña sus ofertas; al abrirlas aparecen.
func set_enabled(on: bool) -> void:
	enabled = on
	_apply_enabled()

func _apply_enabled() -> void:
	visible = enabled
	if is_inside_tree():
		set_deferred("monitoring", enabled)
	else:
		monitoring = enabled

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"especial":
			return Color(0.62, 0.74, 0.86)
		"rara":
			return Color(0.80, 0.68, 0.86)
	return Color(0.82, 0.77, 0.62)
