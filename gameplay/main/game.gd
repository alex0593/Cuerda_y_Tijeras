# Game — mapa del vertical slice: rejilla de salas, jugadora que camina por
# ella, taller, jefe y resumen (doc 07 §11).
extends Node2D

const RoomScript := preload("res://gameplay/rooms/room.gd")
const LelaScript := preload("res://gameplay/player/lela.tscn")

const START_CELL := Vector2i(0, 0)
const REPAIR_ID := "repair"
# Por encima del suelo y los muros de la sala, que van en 0.
const PLAYER_Z := 5
# Velocidad de la jugadora con la sala al 180%. Antes iba a 220 con la sala a
# 960x540: cruzar una sala costaba 4,4 s y con la sala grande costaría 7,9 s.
const PLAYER_SPEED := 260.0
const PLAYER_DASH_SPEED := 560.0
const STEP := {"left": Vector2i(-1, 0), "right": Vector2i(1, 0), "up": Vector2i(0, -1), "down": Vector2i(0, 1)}
const OPPOSITE := {"left": "right", "right": "left", "up": "down", "down": "up"}

# Hilos en el suelo: la moneda de la partida, generada con semilla (doc 07 §12).
const LOOT_SLOTS: Array[Vector2] = [
	Vector2(240, 470), Vector2(400, 470), Vector2(560, 470),
	Vector2(720, 470), Vector2(860, 470),
]

# La tienda del taller (doc 07 §13): un mostrador cerrado con un nudo que se
# corta con un tiro (el mecanismo que usan todas las salas). Cortarlo cobra la
# entrada: un alfiler, o forzarla con hilos. Dentro, las ofertas en el suelo con
# su precio se compran al pisarlas.
const SHOP_SLOTS: Array[Vector2] = [
	Vector2(360, 400), Vector2(680, 400),
]
const REPAIR_SLOT := Vector2(520, 400)
const COUNTER_POS := Vector2(520, 395)
const KNOT_POS := Vector2(520, 330)

var flow: Dictionary = {}
var rooms: Dictionary = {}
var player: Node2D = null
var current_cell := Vector2i(-1, -1)
var visited: Dictionary = {}
var _transitioning := false
var _run_serial := 0
var _shop_cards: Array = []
var _shop_label: Label = null
var _shop_knot: Node2D = null

@onready var hud: CanvasLayer = $HUD
@onready var touch: CanvasLayer = $TouchControls
@onready var camera: Camera2D = $Camera

func _ready() -> void:
	# El coordinator debe seguir recibiendo entrada mientras el árbol está pausado
	# para poder cerrar la pausa o reintentar desde el resumen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.run_ended.connect(_on_run_ended)
	($PauseOverlay/MenuBtn as Button).pressed.connect(_on_back_to_menu)
	# Si el menú dejó una partida cargada para continuar, manda su semilla; si no,
	# es una partida nueva. Sin esto, entrar en la escena siempre tiraba la
	# partida guardada y empezaba una al azar, que es lo contrario de «Continuar».
	if GameState.resuming:
		_start_new_run(GameState.seed_value)
	else:
		_start_new_run(randi())

func _start_new_run(p_seed: int) -> void:
	_run_serial += 1
	get_tree().paused = false
	_transitioning = false
	# Al continuar NO se llama a start_run(): el estado acaba de restaurarse del
	# guardado y start_run() lo dejaría a cero (vida, tensión, objetos e hilos).
	# Solo hay que reconstruir el mapa con la misma semilla y devolverle a la
	# jugadora la sala en la que estaba.
	var resuming: bool = GameState.resuming
	GameState.resuming = false
	var resume_state: Dictionary = (GameState.map_state as Dictionary).duplicate(true) if resuming else {}
	if not resuming:
		GameState.start_run(p_seed)
	flow = RoomGenerator.generate_run(p_seed)
	_clear_map()
	_build_map()
	GameState.map_state = resume_state
	_restore_map_state()
	_spawn_player()
	if resuming:
		# La jugadora vuelve a la sala en la que estaba, no a la entrada: si no,
		# «Continuar» la teletransportaba al principio del mapa.
		_enter_room(_resume_cell(), "")
	else:
		_enter_room(START_CELL, "")

# La celda donde estaba la jugadora al guardarse. Se deduce del estado del mapa:
# la última sala visitada que aún tenía enemigos es la más avanzada, y si no
# queda ninguna, la última visitada.
func _resume_cell() -> Vector2i:
	var visited: Array[Vector2i] = []
	for key in GameState.map_state.keys():
		var parts := String(key).split(",")
		if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
			visited.append(Vector2i(int(parts[0]), int(parts[1])))
	if visited.is_empty():
		return START_CELL
	visited.sort_custom(func(a, b): return _manhattan(a, START_CELL) > _manhattan(b, START_CELL))
	var start: Vector2i = START_CELL
	for cell in visited:
		var entry: Dictionary = GameState.room_state(cell)
		if not bool(entry.get("cleared", false)):
			start = cell
			break
	return start

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func _clear_map() -> void:
	rooms.clear()
	visited.clear()
	current_cell = Vector2i(-1, -1)
	_shop_cards.clear()
	_shop_label = null
	_shop_knot = null
	for child in get_children():
		if child is Node2D and not (child is Camera2D):
			remove_child(child)
			child.queue_free()

# Todas las salas existen desde el principio: el mapa se puede recorrer entero.
# Su contenido (enemigos, botín y tienda) se monta al entrar la primera vez.
func _build_map() -> void:
	var room_size: Vector2 = flow.get("room_size", Vector2(960, 540))
	var grid: Vector2i = flow.get("grid", Vector2i(3, 3))
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(room_size.x * grid.x)
	camera.limit_bottom = int(room_size.y * grid.y)
	_fit_camera(room_size)
	# El mapa se vuelve a construir en cada reinicio, así que la conexión al
	# cambio de tamaño hay que renovarla: conectar dos veces la misma señal
	# avisa por consola cada vez que se reintenta.
	var on_resize := _fit_camera.bind(room_size)
	if get_viewport().size_changed.is_connected(on_resize):
		get_viewport().size_changed.disconnect(on_resize)
	get_viewport().size_changed.connect(on_resize)
	for data in (flow["rooms"] as Array):
		var room: RoomScript = preload("res://gameplay/rooms/room.tscn").instantiate()
		room.process_mode = Node.PROCESS_MODE_PAUSABLE
		room.setup(data)
		room.cleared.connect(_on_room_cleared.bind(room))
		room.door_entered.connect(_on_door_entered.bind(room.grid_cell))
		add_child(room)
		rooms[room.grid_cell] = room
	GameState.rooms_total = rooms.size()
	_restore_map_state()

# Vuelca en cada sala lo que el guardado dice de ella. Se hace al construir el
# mapa, antes de que la jugadora entre en ninguna, para que una sala ya
# despejada no vuelva a tener enemigos.
func _restore_map_state() -> void:
	for cell in rooms:
		var room: RoomScript = rooms[cell]
		var saved: Dictionary = GameState.room_state(cell)
		room.saved_cleared = bool(saved.get("cleared", false))
		var taken: Array[int] = []
		for index in (saved.get("loot_taken", []) as Array):
			taken.append(int(index))
		room.saved_loot_taken = taken

# El estado del mapa se guarda al entrar en cada sala y al pausar, nunca a mitad
# de un combate: así «Continuar» siempre devuelve a la jugadora al empezar de
# una sala, con lo que tenía y lo que había dejado sin recoger.
func _save_progress() -> void:
	if not GameState.is_running:
		return
	for cell in rooms:
		var room: RoomScript = rooms[cell]
		if not room.is_active:
			continue
		GameState.note_room(cell, room.is_cleared, room.snapshot().get("loot_taken", []))
	SaveService.save_run()

# Encuadre de la cámara. La sala es más grande que el viewport, así que la
# cámara puede centrarla; el encuadre se calcula para que la jugadora se vea con
# tamaño y para que sobre sitio en los dos ejes. Sin margen, en un móvil la
# jugadora acababa pegada al borde de la pantalla al acercarse a un muro.
#   1.0 = se ve la sala entera; mayor que 1 = más cerca.
const CAMERA_FILL := 0.72
# Diez por ciento más lejos de la jugadora, a petición del playtest del 28-09:
# con el encuadre anterior se leía demasiado justa en el móvil. Se aplica como
# un factor sobre el zoom ya calculado, así que da igual la proporción de
# pantalla: el alejamiento es siempre el mismo.
const CAMERA_DISTANCE := 0.9

func _fit_camera(room_size: Vector2) -> void:
	var view: Vector2 = get_viewport_rect().size
	if view.x <= 0.0 or view.y <= 0.0 or room_size.x <= 0.0 or room_size.y <= 0.0:
		return
	# Acercarse lo justo para que la jugadora ocupe una parte de la pantalla,
	# pero sin pasarse: en el eje que manda, la vista tiene que ser más pequeña
	# que la sala, o la cámara no tiene margen y la empuja al borde. El tope de
	# 1.0 evita alejarse más de la cuenta en pantallas cuadradas.
	var zoom_x: float = view.x / (room_size.x * CAMERA_FILL)
	var zoom_y: float = view.y / (room_size.y * CAMERA_FILL)
	var zoom: float = minf(minf(zoom_x, zoom_y), 1.0) * CAMERA_DISTANCE
	camera.zoom = Vector2(zoom, zoom)

func _spawn_player() -> void:
	player = LelaScript.instantiate()
	# La jugadora NO crece con la sala: la sala se agranda para dar margen a la
	# cámara, y agrandar también el personaje lo que hace es ponerle media
	# pantalla. Se queda en su tamaño de diseño y sube un poco la velocidad para
	# que cruzar una sala más grande no alargue la partida.
	var k := RoomScript.SCALE
	player.move_speed = PLAYER_SPEED
	player.dash_speed = PLAYER_DASH_SPEED
	add_child(player)
	# La jugadora es hija del mapa, no de la sala, así que sin esto el suelo de
	# la sala la dibuja encima y desaparece bajo el mapa. El orden de hermanos
	# ya la pone la última, pero el z_index lo deja explícito y a salvo de que
	# alguien reordene el árbol.
	player.z_index = PLAYER_Z
	var start: RoomScript = rooms.get(START_CELL)
	# En el centro de la sala, no en la esquina: las esquinas de la pantalla las
	# cubren los joysticks táctiles, y aparecer debajo de uno hace que la jugadora
	# no se vea durante los primeros segundos.
	player.global_position = start.global_position + Vector2(480.0 * k.x, 270.0 * k.y)

# Entrar en una sala la despierta la primera vez y deja a la jugadora dentro.
func _enter_room(cell: Vector2i, from_direction: String) -> void:
	var room: RoomScript = rooms.get(cell)
	if room == null:
		return
	current_cell = cell
	if not visited.has(cell):
		visited[cell] = true
		GameState.rooms_visited = visited.size()
		# La puerta se pisa dentro de un callback de física, y ahí no se pueden
		# crear áreas nuevas: despertar la sala se encola un instante.
		_wake_room.call_deferred(room)
	if from_direction != "" and is_instance_valid(player):
		player.global_position = room.global_position + room.entry_position(from_direction)

func _wake_room(room: RoomScript) -> void:
	if not is_instance_valid(room):
		return
	room.activate()
	_populate_room(room)
	_save_progress()

# Botín y tienda se montan al despertar la sala, con lo que la jugadora lleve
# en ese momento: la pool nunca repite un objeto ya recogido.
func _populate_room(room: RoomScript) -> void:
	var data: Dictionary = room.room_data
	_drop_loot(room, data.get("loot", []) as Array)
	if String(data.get("kind", "")) == "workshop":
		_build_shop(room, data)
		GameState.show_toast("Taller: corta el nudo para abrir")

func _drop_loot(room: RoomScript, loot: Array) -> void:
	for i in mini(loot.size(), LOOT_SLOTS.size()):
		# El botín que ya se recogió antes del guardado no vuelve a aparecer.
		if i in (room.saved_loot_taken as Array):
			continue
		_drop_reward(room, LOOT_SLOTS[i], String(loot[i]))

func _drop_reward(room: RoomScript, pos: Vector2, kind: String) -> void:
	var pk := preload("res://gameplay/pickups/pickup.tscn").instantiate()
	pk.kind = kind
	room.add_child(pk)
	pk.position = pos
	room.loot_nodes.append(pk)

# --- Tienda del taller -------------------------------------------------------

func _build_shop(room: RoomScript, data: Dictionary) -> void:
	_shop_cards.clear()
	_shop_knot = null
	_spawn_counter(room)
	_spawn_knot(room)
	_spawn_shop_cards(room, data)
	_style_shop(GameState.shop_open)

# El mostrador: se ve cerrado hasta cortar el nudo.
func _spawn_counter(room: RoomScript) -> void:
	var counter := Polygon2D.new()
	counter.polygon = PackedVector2Array([
		Vector2(-240, -55), Vector2(240, -55), Vector2(240, 55), Vector2(-240, 55),
	])
	counter.color = Color(0.55, 0.42, 0.24)
	counter.position = COUNTER_POS
	room.add_child(counter)

	_shop_label = Label.new()
	_shop_label.position = Vector2(COUNTER_POS.x - 110, COUNTER_POS.y - 145)
	_shop_label.size = Vector2(220, 30)
	_shop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_label.add_theme_font_size_override("font_size", 18)
	room.add_child(_shop_label)

# El nudo: se corta con un tiro y cobra la entrada al cortarse.
func _spawn_knot(room: RoomScript) -> void:
	if GameState.shop_open:
		return
	var knot := preload("res://gameplay/pickups/shop_knot.gd").new()
	knot.position = KNOT_POS
	knot.opened.connect(_on_shop_opened)
	room.add_child(knot)
	_shop_knot = knot

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
func _spawn_shop_cards(room: RoomScript, data: Dictionary) -> void:
	var offers: Array = RoomGenerator.shop_offers_for(data, GameState.items)
	for i in mini(offers.size(), SHOP_SLOTS.size()):
		_spawn_card(room, String(offers[i]), SHOP_SLOTS[i], false)
	_spawn_card(room, REPAIR_ID, REPAIR_SLOT, true)

func _spawn_card(room: RoomScript, offer_id: String, pos: Vector2, is_repair: bool) -> void:
	var card := preload("res://gameplay/pickups/shop_offer.gd").new()
	card.offer_id = offer_id
	card.is_repair = is_repair
	card.enabled = GameState.shop_open
	room.add_child(card)
	card.position = pos
	_shop_cards.append(card)

# --- Mapa -------------------------------------------------------------------

func _neighbour(cell: Vector2i, direction: String) -> Vector2i:
	return cell + STEP.get(direction, Vector2i.ZERO)

func _on_door_entered(direction: String, from_cell: Vector2i) -> void:
	if not GameState.is_running or _transitioning or not is_instance_valid(player):
		return
	var target: Vector2i = _neighbour(from_cell, direction)
	var room: RoomScript = rooms.get(target)
	if room == null:
		return
	_transitioning = true
	var opposite := String(OPPOSITE.get(direction, "left"))
	_enter_room(target, opposite)
	_transitioning = false

func _on_room_cleared(room: RoomScript) -> void:
	if not GameState.is_running:
		return
	GameState.show_toast("Sala despejada")

# La cámara sigue a la jugadora por el mapa entero.
func _process(_delta: float) -> void:
	if is_instance_valid(player):
		camera.global_position = player.global_position
	# Los paneles congelan la partida: pausa y reinicio no deben actuar encima.
	if not _panel_open():
		if ($End as CanvasLayer).visible and Input.is_action_just_pressed("restart"):
			_start_new_run(randi())
		elif Input.is_action_just_pressed("pause") and not ($End as CanvasLayer).visible:
			get_tree().paused = not get_tree().paused
			if get_tree().paused:
				_save_progress()
	# El overlay es un espejo del estado real, nunca una variable aparte: si se
	# asigna a mano puede quedarse visible mientras la partida corre, o tapar
	# un panel. Ni con panel abierto ni con el resumen encima.
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
		_save_progress()

# Volver al menú deja la partida guardada, así que «Continuar» la recoge tal
# cual. Antes de irnos se guarda, que si no se perdería lo hecho desde la última
# sala.
func _on_back_to_menu() -> void:
	if not GameState.is_running:
		return
	_save_progress()
	GameState.resuming = false
	# Aplazado: el botón vive en la escena que se va a liberar, y cambiar de
	# escena desde dentro de su propio señal deja el nodo colgando.
	get_tree().call_deferred("change_scene_to_file", "res://gameplay/main/title.tscn")

func _is_back_pressed(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		return true
	return event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_BACK

func _on_run_ended(victory: bool) -> void:
	get_tree().paused = true
	$PauseOverlay.visible = false
	# La partida se acabó: el guardado se borra, o «Continuar» ofrecería volver a
	# una partida que ya no existe.
	SaveService.clear_run()
	SaveService.profile.runs = int(SaveService.profile.get("runs", 0)) + 1
	if victory:
		var best := float(SaveService.profile.get("best_time", 0.0))
		SaveService.profile.best_time = GameState.run_time if best <= 0.0 else minf(best, GameState.run_time)
	SaveService.save_profile()
	var label := $End/Label as Label
	($End as CanvasLayer).visible = true
	var mins := int(GameState.run_time) / 60
	var secs := int(GameState.run_time) % 60
	label.text = "%s\nTiempo %02d:%02d  Salas %d/%d  Bajas %d\nSemilla %s\n[R] reintentar" % [
		"¡Función completa!" if victory else "La función no ha terminado",
		mins, secs, GameState.rooms_visited, maxi(GameState.rooms_total, 1), GameState.kills,
		SaveService.export_seed()]
