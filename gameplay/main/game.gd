# Game — flujo vertical slice: menú mínimo -> salas -> jefe -> resumen.
extends Node2D

var flow: Dictionary = {}
var room_index := 0
var current_room: Node = null

@onready var hud: CanvasLayer = $HUD
@onready var touch: CanvasLayer = $TouchControls

func _ready() -> void:
	GameState.run_ended.connect(_on_run_ended)
	_start_new_run(randi())

func _start_new_run(p_seed: int) -> void:
	GameState.start_run(p_seed)
	flow = RoomGenerator.generate_run(p_seed)
	room_index = 0
	_spawn_current()

func _spawn_current() -> void:
	if current_room:
		current_room.queue_free()
		await get_tree().process_frame
	var data: Dictionary = (flow["rooms"] as Array)[room_index]
	var room := preload("res://gameplay/rooms/room.tscn").instantiate()
	add_child(room)
	move_child(room, 0)
	room.setup(data)
	room.cleared.connect(_on_room_cleared)
	current_room = room
	# Recompensa simple de vertical slice: primer cofre da tijeras precisión.
	if String(data.get("reward", "")) == "chest" or String(data.get("reward", "")) == "choice_2":
		_drop_reward(Vector2(760, 270), "item:scissors_precision")
	elif String(data.get("reward", "")) == "risk_chest":
		_drop_reward(Vector2(760, 200), "item:spring_jumper")
		_drop_reward(Vector2(760, 340), "item:iron_magnet")

func _drop_reward(pos: Vector2, kind: String) -> void:
	var pk := preload("res://gameplay/pickups/pickup.tscn").instantiate()
	current_room.add_child(pk)
	pk.global_position = pos
	pk.kind = kind

func _on_room_cleared() -> void:
	GameState.rooms_visited += 1
	SaveService.save_run()
	await get_tree().create_timer(0.8).timeout
	room_index += 1
	if room_index >= (flow["rooms"] as Array).size():
		GameState.end_run(true)
		return
	_spawn_current()

func _on_run_ended(victory: bool) -> void:
	var label := $End/Label as Label
	($End as CanvasLayer).visible = true
	var mins := int(GameState.run_time) / 60
	var secs := int(GameState.run_time) % 60
	label.text = "%s\nTiempo %02d:%02d  Salas %d  Kills %d\nSemilla %s\n[R] reintentar" % [
		"¡Función completa!" if victory else "La función no ha terminado",
		mins, secs, GameState.rooms_visited, GameState.kills, SaveService.export_seed()]
	set_process(true)

func _process(_delta: float) -> void:
	if ($End as CanvasLayer).visible and Input.is_key_pressed(KEY_R):
		($End as CanvasLayer).visible = false
		_start_new_run(randi())
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = not get_tree().paused
