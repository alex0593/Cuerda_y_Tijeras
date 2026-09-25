# Game — flujo vertical slice: menú mínimo -> salas -> jefe -> resumen.
extends Node2D

var flow: Dictionary = {}
var room_index := 0
var current_room: Node = null
var _transitioning := false
var _run_serial := 0

@onready var hud: CanvasLayer = $HUD
@onready var touch: CanvasLayer = $TouchControls
@onready var swap_panel: CanvasLayer = $SwapPanel

func _ready() -> void:
	# El coordinator debe seguir recibiendo entrada mientras el árbol está pausado
	# para poder cerrar la pausa o reintentar desde el resumen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.run_ended.connect(_on_run_ended)
	GameState.swap_requested.connect(_on_swap_requested)
	_start_new_run(randi())

func _on_swap_requested(pickup: Node, new_item_id: String, candidates: Array) -> void:
	# Solo tiene sentido cambiar objetos con la partida en curso.
	if not GameState.is_running or not is_instance_valid(swap_panel):
		return
	swap_panel.call("open", pickup, new_item_id, candidates)

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
	# Configurar y conectar antes de add_child: _ready() se ejecuta al entrar al árbol.
	room.setup(data)
	room.cleared.connect(_on_room_cleared)
	room.exit_reached.connect(_on_room_exit)
	current_room = room
	add_child(room)
	move_child(room, 0)
	_drop_offers(data.get("offers", []) as Array)
	# Las salas sin enemigos se completan después de añadir sus recompensas.
	if (data.get("enemies", []) as Array).is_empty():
		room.call("_mark_cleared")

# Las ofertas vienen del generador con semilla (doc 05): la jugadora decide
# cuáles recoger antes de salir por la puerta, así que se dejan todas en el suelo.
func _drop_offers(offers: Array) -> void:
	var slots: Array[Vector2] = [
		Vector2(320, 150), Vector2(600, 150), Vector2(860, 150),
		Vector2(420, 400), Vector2(700, 400),
	]
	for i in mini(offers.size(), slots.size()):
		_drop_reward(slots[i], "item:%s" % String(offers[i]))

func _drop_reward(pos: Vector2, kind: String) -> void:
	var pk := preload("res://gameplay/pickups/pickup.tscn").instantiate()
	pk.kind = kind
	current_room.add_child(pk)
	pk.global_position = pos

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
	# El panel de cambio congela la partida: pausa y reinicio no deben actuar encima.
	if is_instance_valid(swap_panel) and bool(swap_panel.get("is_open")):
		return
	if ($End as CanvasLayer).visible and Input.is_action_just_pressed("restart"):
		_start_new_run(randi())
		return
	if Input.is_action_just_pressed("pause") and not ($End as CanvasLayer).visible:
		get_tree().paused = not get_tree().paused
		$PauseOverlay.visible = get_tree().paused
