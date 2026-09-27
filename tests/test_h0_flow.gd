extends SceneTree

# H0 smoke test: monta la escena real y verifica que el mapa arranca con una
# única jugadora en la sala de inicio, con puertas y con una vecina de combate
# a la que se puede caminar y que despierta sus enemigos.
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	var state: Node = root.get_node_or_null("GameState")
	var scene = load("res://gameplay/main/game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	_check((get_nodes_in_group("player") as Array).size() == 1, "debe existir exactamente un jugador al inicio")
	_check((scene.rooms as Dictionary).size() == 9, "el mapa debe tener 9 salas")
	var start = scene.rooms.get(Vector2i(0, 0))
	_check(is_instance_valid(start), "debe existir la sala de inicio")
	_check(is_instance_valid(start) and start.is_active, "la sala de inicio debe despertar sola")
	_check(is_instance_valid(start) and start.is_cleared, "el inicio no tiene enemigos y queda abierto")

	# Al pisar una puerta la vecina despierta con su contenido y la jugadora pasa.
	var direction := "right" if "right" in (start.doors as Array) else String(start.doors[0])
	var neighbour = scene.rooms.get(Vector2i(0, 0) + scene.STEP.get(direction, Vector2i.ZERO))
	_check(is_instance_valid(neighbour), "el inicio debe tener al menos una puerta")
	if is_instance_valid(neighbour):
		_check(not neighbour.is_active, "una sala sin visitar no debe tener enemigos")
		start.emit_signal("door_entered", direction)
		await process_frame
		await physics_frame
		_check(neighbour.is_active, "al entrar la sala debe despertar")
		if String(neighbour.kind) == "combat":
			_check((neighbour.spawned as Array).size() > 0, "la sala de combate debe tener enemigos")
		_check((get_nodes_in_group("player") as Array).size() == 1, "debe seguir habiendo una única jugadora")
		_check(int(state.rooms_visited) == 2, "deben contar dos salas visitadas")
		_check(scene.current_cell == neighbour.grid_cell, "la jugadora debe estar en la sala vecina")

	if is_instance_valid(scene):
		scene.free()
	for i in 10:
		await process_frame
		await physics_frame
	if failures.is_empty():
		print("H0_SMOKE_OK: mapa + jugador + puertas + sala de combate")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
