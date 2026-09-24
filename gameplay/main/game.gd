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
	_spawn_current()

func _spawn_current() -> void:
	if is_instance_valid(current_room):
		if current_room.cleared.is_connected(_on_room_cleared):
			current_room.cleared.disconnect(_on_room_cleared)
		current_room.free()
	_transitioning = false
	var data: Dictionary = (flow["rooms"] as Array)[room_index]
	var room := preload("res://gameplay/rooms/room.tscn").instantiate()
	# Configurar y conectar antes de add_child: _ready() se ejecuta al entrar al árbol.
	room.setup(data)
	room.cleared.connect(_on_room_cleared)
	current_room = room
	add_child(room)
	move_child(room, 0)
	# Recompensa simple de vertical slice: primer cofre da tijeras precisión.
	if String(data.get("reward", "")) == "chest" or String(data.get("reward", "")) == "choice_2":
		_drop_reward(Vector2(760, 270), "item:scissors_precision")
	elif String(data.get("reward", "")) == "risk_chest":
		_drop_reward(Vector2(760, 200), "item:spring_jumper")
		_drop_reward(Vector2(760, 340), "item:iron_magnet")
	# Las salas sin enemigos se completan después de añadir sus recompensas.
	if (data.get("enemies", []) as Array).is_empty():
		room.call("_mark_cleared")

func _drop_reward(pos: Vector2, kind: String) -> void:
	var pk := preload("res://gameplay/pickups/pickup.tscn").instantiate()
	current_room.add_child(pk)
	pk.global_position = pos
	pk.kind = kind

func _on_room_cleared() -> void:
	if not GameState.is_running or _transitioning:
		return
	_transitioning = true
	var serial := _run_serial
	GameState.rooms_visited += 1
	SaveService.save_run()
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
	if ($End as CanvasLayer).visible and Input.is_action_just_pressed("restart"):
		_start_new_run(randi())
		return
	if Input.is_action_just_pressed("pause") and not ($End as CanvasLayer).visible:
		get_tree().paused = not get_tree().paused
