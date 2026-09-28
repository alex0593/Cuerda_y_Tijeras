extends SceneTree

# H3: el guardado tiene que devolver la partida tal cual estaba, mapa
# incluido. Es lo que sostiene «Continuar»: si al volver el mapa apareciera en
# blanco, el guardado sería una mentira y la jugadora perdería lo que había
# hecho sin enterarse.
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	var state: Node = root.get_node_or_null("GameState")
	var save_service: Node = root.get_node_or_null("SaveService")
	_check(state != null and save_service != null, "hacen falta los autoloads")
	if state == null or save_service == null:
		quit(1)
		return
	_wipe(save_service)

	# --- 1. Se juega un poco: una sala con enemigos, se limpian y se recoge hilo.
	var scene = load("res://gameplay/main/game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("_start_new_run", 5150)
	for i in 4:
		await process_frame
	var rooms: Dictionary = scene.get("rooms")
	var combat_cell := Vector2i(-1, -1)
	for cell in rooms:
		if String(rooms[cell].get("kind")) == "combat":
			combat_cell = cell
			break
	_check(combat_cell != Vector2i(-1, -1), "debe haber una sala de combate")
	var combat: Node = rooms[combat_cell]
	combat.call("activate")
	scene.call("_populate_room", combat)
	await process_frame
	var loot_before: int = (combat.get("loot_nodes") as Array).size()
	_check(loot_before > 0, "la sala de combate debe dejar hilos en el suelo")
	for enemy in (combat.get("spawned") as Array):
		if is_instance_valid(enemy):
			enemy.call("take_hit", 9999.0, "test")
	for i in 3:
		await process_frame
	_check(bool(combat.get("is_cleared")), "la sala debe quedar despejada")
	# Se recoge el primer hilo para que el guardado tenga algo que recordar.
	var first_loot = (combat.get("loot_nodes") as Array)[0] as Node2D
	var player = get_first_node_in_group("player") as Node2D
	state.threads = 7
	player.global_position = first_loot.global_position
	for i in 5:
		await physics_frame
	_check(int(state.threads) == 8, "el hilo del suelo tiene que recogerse")
	# Una sala visitada más más, para que el mapa tenga varias entradas.
	var second: Node = null
	for cell in rooms:
		var room = rooms[cell]
		if room != combat and String(room.get("kind")) in ["risk", "treasure"]:
			second = room
			break
	second.call("activate")
	scene.call("_populate_room", second)
	for i in 3:
		await process_frame

	# --- 2. Estado que hay que recuperar
	var saved_threads := int(state.threads)
	var saved_items: Array = (state.items as Array).duplicate()
	var visited_count := int(state.rooms_visited)
	scene.call("_save_progress")
	var saved_state: Dictionary = (state.map_state as Dictionary).duplicate(true)
	_check(saved_state.size() >= 2, "el guardado tiene que acordarse de varias salas, tiene %d" % saved_state.size())
	_check(save_service.has_run(), "entrar en una sala tiene que dejar partida guardada")
	_check(saved_state.has("%d,%d" % [combat_cell.x, combat_cell.y]),
		"la sala despejada tiene que estar en el estado del mapa")

	# --- 3. Se tira la partida y se vuelve con el menú
	if is_instance_valid(scene):
		scene.free()
	for i in 5:
		await process_frame
		state.set("is_running", false)
	_check(save_service.load_run(), "el guardado tiene que poder leerse")
	_check(int(state.threads) == saved_threads, "al continuar deben volver los mismos hilos")
	_check((state.items as Array) == saved_items, "al continuar deben volver los mismos objetos")
	_check(int(state.rooms_visited) == visited_count, "al continuar deben volver las salas visitadas")
	_check((state.map_state as Dictionary).size() == saved_state.size(), "al continuar debe volver el estado del mapa")

	# --- 4. La partida reconstruida deja el mapa como estaba
	# Así es como lo hará el menú: cargar la partida, marcar que se continúa y
	# entrar en la escena. Su _ready tiene que respetar la partida guardada.
	state.set("resuming", true)
	state.set("map_state", saved_state)
	var scene2 = load("res://gameplay/main/game.tscn").instantiate()
	root.add_child(scene2)
	for i in 5:
		await process_frame
	_check(int(state.seed_value) == 5150, "al continuar debe jugarse la misma semilla: %d" % int(state.seed_value))
	_check(not bool(state.resuming), "reanudar solo se puede pedir una vez")
	var rooms2: Dictionary = scene2.get("rooms")
	# La misma celda que en la primera partida: si no, se compararían salas
	# distintas y el botín no cuadraría por culpa del test.
	var combat2: Node = rooms2.get(combat_cell)
	_check(is_instance_valid(combat2), "al continuar debe volver la misma sala de combate")
	combat2.call("activate")
	scene2.call("_populate_room", combat2)
	for i in 3:
		await process_frame
	_check(bool(combat2.get("is_cleared")), "una sala ya despejada vuelve despejada")
	_check((combat2.get("spawned") as Array).is_empty()
		or not is_instance_valid((combat2.get("spawned") as Array)[0]),
		"una sala ya despejada no puede volver a tener enemigos")
	var loot_after: int = (combat2.get("loot_nodes") as Array).size()
	_check(loot_after == loot_before - 1, "el hilo ya recogido no debe volver a aparecer: quedaban %d de %d" % [loot_after, loot_before])

	# --- 5. Al terminar la partida, el guardado desaparece
	state.set("is_running", true)
	scene2.call("_on_run_ended", false)
	_check(not save_service.has_run(), "una partida terminada no se puede continuar")
	_wipe(save_service)
	if is_instance_valid(scene2):
		scene2.free()
	for i in 3:
		await process_frame
	if failures.is_empty():
		print("H3_SAVE_OK: el guardado devuelve el mapa, el botín y la partida")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _wipe(save_service: Node) -> void:
	save_service.call("clear_run")
