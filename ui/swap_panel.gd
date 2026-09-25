# SwapPanel — elegir a qué objeto reemplazo cuando el slot está lleno.
# Reglas móviles: objetivos grandes, texto breve, cancelar siempre es posible
# y el juego se congela para que la decisión no cueste vida.
extends CanvasLayer

const SLOT_LABELS := {"weapon": "Arma", "mechanism": "Mecanismo", "amulet": "Amuleto", "consumable": "Consumible"}
const PANEL_SIZE := Vector2(760, 340)
const BUTTON_SIZE := Vector2(300, 92)

var _pickup: Node = null
var _new_item_id := ""
var _candidates: Array = []
var _dim: ColorRect = null
var _title: Label = null
var _options: HBoxContainer = null
var is_open := false

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()



func _build() -> void:
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0.08, 0.07, 0.06, 0.72)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 18)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 26)
	box.add_child(_title)

	var hint := Label.new()
	hint.name = "Hint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.86, 0.84, 0.80))
	hint.text = "Toca un objeto para descartarlo · fuera para cancelar"
	box.add_child(hint)

	_options = HBoxContainer.new()
	_options.name = "Options"
	_options.alignment = BoxContainer.ALIGNMENT_CENTER
	_options.add_theme_constant_override("separation", 16)
	box.add_child(_options)

func _on_dim_input(event: InputEvent) -> void:
	# Tocar fuera cancela: nunca se pierde un objeto sin querer.
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_close()

func open(pickup: Node, new_item_id: String, candidates: Array) -> void:
	if is_open or visible or candidates.is_empty():
		return
	_pickup = pickup
	_new_item_id = new_item_id
	_candidates = candidates.duplicate()
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
	var new_name := String(SynergyDB.get_item(new_item_id).get("name", new_item_id))
	var slot := String(SynergyDB.get_item(new_item_id).get("slot", ""))
	_title.text = "%s lleno — ¿cambiar?" % SLOT_LABELS.get(slot, "Slot")
	var hint := _options.get_parent().get_node_or_null("Hint") as Label
	if hint:
		hint.text = "Nuevo: %s" % new_name
	for candidate_id in _candidates:
		_options.add_child(_make_option_button(String(candidate_id)))
	is_open = true
	visible = true
	get_tree().paused = true

func _make_option_button(replaced_id: String) -> Button:
	var button := Button.new()
	var item_name := String(SynergyDB.get_item(replaced_id).get("name", replaced_id))
	button.custom_minimum_size = BUTTON_SIZE
	button.text = item_name
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(_on_option_pressed.bind(replaced_id))
	return button

func _on_option_pressed(replaced_id: String) -> void:
	var pickup := _pickup
	var new_id := _new_item_id
	if GameState.swap_item(new_id, replaced_id):
		if is_instance_valid(pickup):
			pickup.queue_free()
		GameState.show_toast("Cambiado a %s" % String(SynergyDB.get_item(new_id).get("name", new_id)))
	_close()

func _close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	_pickup = null
	_new_item_id = ""
	_candidates.clear()
	get_tree().paused = false
