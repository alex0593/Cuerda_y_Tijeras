# Game — flujo vertical slice: menú mínimo -> salas -> jefe -> resumen.
extends Node2D

var flow: Dictionary = {}
var room_index := 0
var current_room: Node = null
var _transitioning := false
var _run_serial := 0

@onready var hud: CanvasLayer = $HUD
@onready var touch: CanvasLayer = $TouchControls

func _ready() -> void:
	# El coordinator debe seguir recibiendo entrada mientras el árbol está pausado
	# para poder cerrar la pausa o reintentar desde el resumen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.run_ended.connect(_on_run_ended)
	_start_new_run(randi())

func _start_new_run(p_seed: int) -> void:
	_run_serial += 1
	get_tree().paused = false
	_transitioning = false
	GameState.start_run(p_seed)
	flow = RoomGenerator.generate_run(p_seed)
	room_index = 0
	($End as CanvasLayer).visible = false
	$PauseOverlay.visible = false
	_spawn_current()

func _spawn_current() -> void:
	if is_instance_valid(current_room):
		if current_room.cleared.is_connected(_on_room_cleared):
			current_room.cleared.disconnect(_on_room_cleared)
		if current_room.exit_reached.is_connected(_on_room_exit):
			current_room.exit_reached.disconnect(_on_room_exit)
		current_room.free()
	_transitioning = false
	var data: Dictionary = (flow["rooms"] as Array)[room_index]
	var room := preload("res://gameplay/rooms/room.tscn").instantiate()
	# Main es ALWAYS para poder cerrar pausas, pero la sala con su jugador,
	# enemigos y botín debe ser pausable: si hereda ALWAYS, los paneles y la
	# pausa congelan la interfaz y no la partida (doc 07 §13).
	room.process_mode = Node.PROCESS_MODE_PAUSABLE
	# Configurar y conectar antes de add_child: _ready() se ejecuta al entrar al árbol.
	room.setup(data)
	room.cleared.connect(_on_room_cleared)
	room.exit_reached.connect(_on_room_exit)
	current_room = room
	add_child(room)
	move_child(room, 0)
	_drop_loot(data.get("loot", []) as Array)
	if String(data.get("kind", "")) == "workshop":
		_spawn_shop(data)
	# Las salas sin enemigos se completan después de añadir sus recompensas.
	if (data.get("enemies", []) as Array).is_empty():
		room.call("_mark_cleared")

func _drop_reward(pos: Vector2, kind: String) -> void:
	var pk := preload("res://gameplay/pickups/pickup.tscn").instantiate()
	pk.kind = kind
	current_room.add_child(pk)
	pk.global_position = pos

# Hilos en el suelo: la moneda de la partida, generada con semilla (doc 07 §12).
const LOOT_SLOTS: Array[Vector2] = [
	Vector2(240, 470), Vector2(400, 470), Vector2(560, 470),
	Vector2(720, 470), Vector2(860, 470),
]

func _drop_loot(loot: Array) -> void:
	for i in mini(loot.size(), LOOT_SLOTS.size()):
		_drop_reward(LOOT_SLOTS[i], String(loot[i]))

# La tienda del taller (doc 07 §13): un mostrador cerrado con un nudo que se
# corta con un tiro (el mecanismo que usan todas las salas). Cortarlo cobra la
# entrada: un alfiler, o forzarla con hilos. Dentro, las ofertas en el suelo
# con su precio se compran al pisarlas.
const SHOP_SLOTS: Array[Vector2] = [
	Vector2(360, 400), Vector2(680, 400),
]
const REPAIR_ID := "repair"
const REPAIR_SLOT := Vector2(520, 400)
const COUNTER_POS := Vector2(520, 395)
const KNOT_POS := Vector2(520, 330)

var _shop_data: Dictionary = {}
var _shop_cards: Array = []
var _shop_label: Label = null

func _spawn_shop(data: Dictionary) -> void:
	_shop_data = data
	_shop_cards.clear()
	_spawn_counter()
	_spawn_knot()
	_spawn_shop_cards()
	_style_shop(GameState.shop_open)

# El mostrador: se ve cerrado hasta cortar el nudo.
func _spawn_counter() -> void:
	var counter := Polygon2D.new()
	counter.polygon = PackedVector2Array([
		Vector2(-240, -55), Vector2(240, -55), Vector2(240, 55), Vector2(-240, 55),
	])
	counter.color = Color(0.55, 0.42, 0.24)
	counter.position = COUNTER_POS
	current_room.add_child(counter)

	_shop_label = Label.new()
	_shop_label.position = Vector2(COUNTER_POS.x - 110, COUNTER_POS.y - 145)
	_shop_label.size = Vector2(220, 30)
	_shop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_label.add_theme_font_size_override("font_size", 18)
	current_room.add_child(_shop_label)

# El nudo: se corta con un tiro y cobra la entrada al cortarse.
func _spawn_knot() -> void:
	if GameState.shop_open:
		return
	var knot := preload("res://gameplay/pickups/shop_knot.gd").new()
	knot.position = KNOT_POS
	knot.opened.connect(_on_shop_opened)
	current_room.add_child(knot)

func _on_shop_opened() -> void:
	_style_shop(true)
	for card in _shop_cards:
		if is_instance_valid(card):
			card.call("set_enabled", true)

func _style_shop(open: bool) -> void:
	if not is_instance_valid(_shop_label):
		return
	_shop_label.text = "TIENDA ABIERTA" if open else "TIENDA CERRADA"
	_shop_label.add_theme_color_override("font_color", Color(0.20, 0.55, 0.25) if open else Color(0.75, 0.30, 0.25))

# Las ofertas se sacan de la pool del taller sin repetir lo que ya llevas.
func _spawn_shop_cards() -> void:
	var offers: Array = RoomGenerator.shop_offers_for(_shop_data, GameState.items)
	for i in mini(offers.size(), SHOP_SLOTS.size()):
		_spawn_card(String(offers[i]), SHOP_SLOTS[i], false)
	_spawn_card(REPAIR_ID, REPAIR_SLOT, true)

func _spawn_card(offer_id: String, pos: Vector2, is_repair: bool) -> void:
	var card := preload("res://gameplay/pickups/shop_offer.gd").new()
	card.offer_id = offer_id
	card.is_repair = is_repair
	card.enabled = GameState.shop_open
	current_room.add_child(card)
	card.global_position = pos
	_shop_cards.append(card)

func _on_room_cleared() -> void:
	if not GameState.is_running or _transitioning:
		return
	GameState.rooms_visited += 1
	SaveService.save_run()
	if _room_requires_exit():
		# Las salas de combate esperan a que la jugadora llegue a la puerta.
		return
	_advance_to_next_room()

func _on_room_exit() -> void:
	if not GameState.is_running or _transitioning:
		return
	_advance_to_next_room()

func _room_requires_exit() -> bool:
	if not is_instance_valid(current_room):
		return false
	var kind := String(current_room.kind)
	# Las salas de recompensa mantienen la puerta cerrada para dar tiempo a recoger
	# los objetos que interesen; start deja pasar al terminar.
	if kind in ["combat", "risk", "boss"]:
		return true
	return kind != "start"

func _advance_to_next_room() -> void:
	if _transitioning:
		return
	_transitioning = true
	var serial := _run_serial
	await get_tree().create_timer(0.8).timeout
	if serial != _run_serial or not GameState.is_running:
		_transitioning = false
		return
	room_index += 1
	if room_index >= (flow["rooms"] as Array).size():
		GameState.end_run(true)
		_transitioning = false
		return
	_spawn_current()

func _on_run_ended(victory: bool) -> void:
	get_tree().paused = true
	$PauseOverlay.visible = false
	SaveService.profile.runs = int(SaveService.profile.get("runs", 0)) + 1
	if victory:
		var best := float(SaveService.profile.get("best_time", 0.0))
		SaveService.profile.best_time = GameState.run_time if best <= 0.0 else minf(best, GameState.run_time)
	SaveService.save_profile()
	var label := $End/Label as Label
	($End as CanvasLayer).visible = true
	var mins := int(GameState.run_time) / 60
	var secs := int(GameState.run_time) % 60
	label.text = "%s\nTiempo %02d:%02d  Salas %d  Kills %d\nSemilla %s\n[R] reintentar" % [
		"¡Función completa!" if victory else "La función no ha terminado",
		mins, secs, GameState.rooms_visited, GameState.kills, SaveService.export_seed()]

func _process(_delta: float) -> void:
	# Los paneles congelan la partida: pausa y reinicio no deben actuar encima.
	if not _panel_open():
		if ($End as CanvasLayer).visible and Input.is_action_just_pressed("restart"):
			_start_new_run(randi())
		elif Input.is_action_just_pressed("pause") and not ($End as CanvasLayer).visible:
			get_tree().paused = not get_tree().paused
	# El overlay es un espejo del estado real, nunca una variable aparte: si se
	# asigna a mano puede quedarse visible mientras la partida corre, o tapar
	# el taller. Ni con panel abierto ni con el resumen encima.
	$PauseOverlay.visible = get_tree().paused and not _panel_open() and not ($End as CanvasLayer).visible

func _panel_open() -> bool:
	return false

func _unhandled_input(event: InputEvent) -> void:
	# En Android el botón atrás cerraba la app y perdía la partida. Ahora pausa.
	if not _is_back_pressed(event):
		return
	if ($End as CanvasLayer).visible:
		return
	get_viewport().set_input_as_handled()
	if not get_tree().paused:
		get_tree().paused = true
		$PauseOverlay.visible = true

func _is_back_pressed(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		return true
	return event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_BACK
