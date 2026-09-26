# ShopPanel — taller (doc 07 §13): gastar hilos en un objeto a elegir o en vida.
# Mismas reglas móviles que SwapPanel: objetivos grandes, texto breve,
# tocar fuera cancela y la partida queda congelada mientras se decide.
extends CanvasLayer

const PANEL_SIZE := Vector2(880, 468)
const ITEM_SIZE := Vector2(270, 74)
const ACTION_SIZE := Vector2(300, 74)

var is_open := false
var _pending_item := ""
var _dim: ColorRect = null
var _title: Label = null
var _hint: Label = null
var _body: VBoxContainer = null

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
		margin.add_theme_constant_override("margin_%s" % side, 16)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 26)
	box.add_child(_title)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", Color(0.86, 0.84, 0.80))
	box.add_child(_hint)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 10)
	box.add_child(_body)

func _on_dim_input(event: InputEvent) -> void:
	# Tocar fuera cierra el taller; no se gasta nada sin confirmar.
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_close()

func open() -> void:
	if is_open or visible or not GameState.is_running:
		return
	_pending_item = ""
	_render_catalog()
	is_open = true
	visible = true
	get_tree().paused = true

func _close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	_pending_item = ""
	get_tree().paused = false

# --- Vistas -----------------------------------------------------------------

func _clear_body() -> void:
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()

# GridContainer no centra por sí solo: se envuelve en un CenterContainer.
func _make_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	return grid

func _centered(control: Control) -> CenterContainer:
	var center := CenterContainer.new()
	center.add_child(control)
	return center

func _render_catalog() -> void:
	_clear_body()
	_title.text = "TALLER"
	_hint.text = "Hilos: %d · toca para comprar" % GameState.threads
	var grid := _make_grid()
	for item_id in _catalog():
		grid.add_child(_make_item_button(item_id))
	_body.add_child(_centered(grid))

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	actions.add_child(_make_repair_button())
	actions.add_child(_make_action_button("Salir", _close))
	_body.add_child(actions)

# El catálogo es todo el contenido de items salvo el arma inicial:
# la jugadora compra exactamente lo que quiere (decisión 2026-09-25).
func _catalog() -> Array:
	var out: Array = []
	for item_id in SynergyDB.items_data.keys():
		if String(item_id) != "scissors_basic":
			out.append(String(item_id))
	return out

func _make_item_button(item_id: String) -> Button:
	var info := GameState.get_buy_info(item_id)
	var item_name := String(SynergyDB.get_item(item_id).get("name", item_id))
	var status := ""
	if bool(info.get("needs_swap", false)):
		status = "%d hilos · ¿qué cambio?" % int(info.get("price", 0))
	elif bool(info.get("allowed", false)):
		status = "%d hilos" % int(info.get("price", 0))
	else:
		status = String(info.get("reason", "no disponible"))
	var button := Button.new()
	button.custom_minimum_size = ITEM_SIZE
	button.text = "%s\n%s" % [item_name, status]
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 18)
	button.disabled = not (bool(info.get("allowed", false)) or bool(info.get("needs_swap", false)))
	button.pressed.connect(_on_item_pressed.bind(item_id))
	return button

func _make_repair_button() -> Button:
	var info := GameState.get_repair_info()
	var status := "%d hilos" % int(info.get("cost", 0)) if bool(info["allowed"]) else String(info["reason"])
	var button := Button.new()
	button.custom_minimum_size = ACTION_SIZE
	button.text = "Reparar vida\n%s" % status
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 18)
	button.disabled = not bool(info["allowed"])
	button.pressed.connect(_on_repair_pressed)
	return button

func _make_action_button(text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.custom_minimum_size = ACTION_SIZE
	button.text = text
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(handler)
	return button

func _render_swap() -> void:
	_clear_body()
	var item_name := String(SynergyDB.get_item(_pending_item).get("name", _pending_item))
	var slot := String(SynergyDB.get_item(_pending_item).get("slot", ""))
	_title.text = "%s lleno — ¿cambiar?" % _slot_label(slot)
	_hint.text = "Nuevo: %s" % item_name
	var grid := _make_grid()
	for candidate in GameState.get_buy_info(_pending_item).get("candidates", []):
		grid.add_child(_make_swap_button(String(candidate)))
	_body.add_child(_centered(grid))

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	actions.add_child(_make_action_button("Cancelar", _render_catalog))
	_body.add_child(actions)

func _slot_label(slot: String) -> String:
	match slot:
		"weapon":
			return "Arma"
		"mechanism":
			return "Mecanismo"
		"amulet":
			return "Amuleto"
		"consumable":
			return "Consumible"
	return "Slot"

func _make_swap_button(replaced_id: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = ITEM_SIZE
	button.text = String(SynergyDB.get_item(replaced_id).get("name", replaced_id))
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(_on_swap_pressed.bind(replaced_id))
	return button

# --- Acciones ---------------------------------------------------------------

func _on_item_pressed(item_id: String) -> void:
	var info := GameState.get_buy_info(item_id)
	if bool(info.get("needs_swap", false)):
		_pending_item = item_id
		_render_swap()
		return
	var result := GameState.buy_item(item_id)
	if bool(result.get("ok", false)):
		GameState.show_toast("Comprado: %s" % String(SynergyDB.get_item(item_id).get("name", item_id)))
	else:
		GameState.show_toast(String(result.get("reason", "no se puede comprar")))
	_render_catalog()

func _on_swap_pressed(replaced_id: String) -> void:
	var item_id := _pending_item
	_pending_item = ""
	var result := GameState.buy_item(item_id, replaced_id)
	if bool(result.get("ok", false)):
		GameState.show_toast("Comprado: %s" % String(SynergyDB.get_item(item_id).get("name", item_id)))
	else:
		GameState.show_toast(String(result.get("reason", "no se pudo comprar")))
	_render_catalog()

func _on_repair_pressed() -> void:
	if GameState.buy_repair():
		GameState.show_toast("Vida reparada")
	else:
		GameState.show_toast(String(GameState.get_repair_info().get("reason", "no se pudo reparar")))
	_render_catalog()
