# Oferta a la vista en el taller (doc 07 §13): un objeto de la pool exclusiva
# con su precio. Tocarla abre el panel de compra; nunca se recoge gratis.
extends Area2D

signal chosen(item_id: String)

const CARD_SIZE := Vector2(76, 76)
const NAME_BOX := Rect2(-70, -84, 140, 44)
const PRICE_BOX := Rect2(-70, -16, 140, 32)

var item_id := ""
var enabled := true

func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = CARD_SIZE
	shape.shape = rectangle
	add_child(shape)

	var color := _rarity_color(String(SynergyDB.get_item(item_id).get("rarity", "común")))
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
	name.text = String(SynergyDB.get_item(item_id).get("name", item_id))
	name.position = NAME_BOX.position
	name.size = NAME_BOX.size
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.add_theme_font_size_override("font_size", 16)
	name.add_theme_color_override("font_color", ink)
	add_child(name)

	var price := Label.new()
	price.text = "%d hilos" % SynergyDB.get_price(item_id)
	price.position = PRICE_BOX.position
	price.size = PRICE_BOX.size
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price.add_theme_font_size_override("font_size", 18)
	price.add_theme_color_override("font_color", ink)
	add_child(price)

	_apply_enabled()
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not enabled or not GameState.is_running:
		return
	if not body.is_in_group("player"):
		return
	chosen.emit(item_id)

# La tercera oferta se enseña cuando se gasta una llave; mientras tanto ni se
# ve ni se puede tocar, para que nadie abra el panel contra su voluntad.
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
