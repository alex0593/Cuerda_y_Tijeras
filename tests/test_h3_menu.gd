extends SceneTree

# H3: el menú es el camino de verdad. Se arranca por la escena principal del
# proyecto, se juega, se sale al menú y se vuelve con «Continuar». Si eso no
# devuelve la partida donde estaba, el guardado no sirve de nada.
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
	_check(str(ProjectSettings.get_setting("application/run/main_scene", "")) == "res://gameplay/main/title.tscn",
		"el juego tiene que arrancar en el menú, no en la partida")
	save_service.call("clear_run")
	state.set("resuming", false)

	# --- 1. Menú sin partida guardada: «Continuar» apagado, «Nueva partida» no.
	await _goto("res://gameplay/main/title.tscn")
	_check(current_scene != null, "el menú tiene que cargar")
	_check(not paused, "el menú no puede dejar el árbol parado, que no hay nadie para quitarlo")
	var continue_btn := current_scene.get_node("Center/Buttons/Continue") as Button
	var new_btn := current_scene.get_node("Center/Buttons/New") as Button
	_check(continue_btn.disabled, "sin partida guardada, «Continuar» tiene que estar apagado")
	_check(not new_btn.disabled, "«Nueva partida» siempre se puede tocar")

	# --- 1b. Un guardado de otra versión no se puede continuar y no se ofrece.
	#        Pasó en el móvil: había un guardado viejo y el botón aparecía activo.
	save_service.call("clear_run")
	# Con la ruta absoluta: user:// puede no resolver igual desde un --script.
	var stale := FileAccess.open(ProjectSettings.globalize_path("user://partida-a.v1.json"), FileAccess.WRITE)
	if stale != null:
		stale.store_string(JSON.stringify({
			"version": 1, "seed": 12345, "generator_version": 4, "tension": 90.0,
			"life": 2.0, "rewind_charges": 1, "items": ["scissors_basic"],
			"item_charges": {}, "synergies": [], "rooms_visited": 3, "kills": 2,
			"threads": 7, "alfilers": 0, "shop_open": false, "run_time": 40.0,
			"cause_of_death": "",
		}))
		stale.close()
	_check(save_service.has_run(), "el archivo viejo está en disco")
	_check(not save_service.can_continue(), "un guardado de otra versión no se puede continuar")
	_check(save_service.run_summary().is_empty(), "y el menú no tiene nada que enseñar de él")
	await _goto("res://gameplay/main/title.tscn")
	_check((current_scene.get_node("Center/Buttons/Continue") as Button).disabled,
		"con un guardado viejo, «Continuar» tiene que estar apagado")
	save_service.call("clear_run")
	# Se vuelve al menú limpio: los botones de antes pertenecen a una escena ya
	# liberada, así que hay que volver a cogerlos.
	await _goto("res://gameplay/main/title.tscn")
	continue_btn = current_scene.get_node("Center/Buttons/Continue") as Button
	new_btn = current_scene.get_node("Center/Buttons/New") as Button

	# --- 2. «Nueva partida» entra en la partida con semilla nueva.
	new_btn.emit_signal("pressed")
	await _settle()
	var game := current_scene
	_check(_is_script(game, "game.gd"), "«Nueva partida» tiene que llevar a la partida: %s" % str(_name(game)))
	_check(get_nodes_in_group("player").size() == 1, "la partida tiene que tener una jugadora")
	_check((game.get("rooms") as Dictionary).size() == 9, "la partida arranca con el mapa de 9 salas")
	var run_seed := int(state.seed_value)

	# --- 3. Se juega un poco y se sale al menú desde la pausa.
	state.threads = 11
	var combat: Node = null
	var rooms: Dictionary = game.get("rooms")
	for cell in rooms:
		if String(rooms[cell].get("kind")) == "combat":
			combat = rooms[cell]
			break
	_check(combat != null, "debe haber una sala de combate")
	# La celda es un valor: el nodo de la sala morirá al cambiar de escena y no
	# se puede seguir usando.
	var combat_cell: Vector2i = combat.get("grid_cell")
	combat.call("activate")
	game.call("_populate_room", combat)
	await _settle()
	paused = true
	current_scene.get_node("PauseOverlay").visible = true
	current_scene.get_node("PauseOverlay/MenuBtn").emit_signal("pressed")
	await _settle()
	_check(_is_script(current_scene, "title.gd"), "el botón del menú tiene que llevar al menú")
	_check(save_service.has_run(), "volver al menú tiene que dejar la partida guardada")
	_check(not paused, "el menú tiene que quitar la pausa al entrar")
	var continue_now := current_scene.get_node("Center/Buttons/Continue") as Button
	_check(not continue_now.disabled, "con partida guardada, «Continuar» tiene que estar disponible")
	# El menú enseña lo que hay guardado, leyéndolo del archivo: al abrir el menú
	# no hay partida en memoria y sin esto salía siempre el 0 de partida nueva.
	var seed_text := (current_scene.get_node("Center/Seed") as Label).text
	_check(seed_text.contains("11 hilos"), "el menú tiene que enseñar los hilos guardados: %s" % seed_text)
	_check(not seed_text.contains("Semilla 0"), "no puede enseñar la semilla de partida nueva: %s" % seed_text)

	# --- 4. «Continuar» devuelve la partida donde estaba.
	current_scene.get_node("Center/Buttons/Continue").emit_signal("pressed")
	await _settle()
	var game2 := current_scene
	_check(_is_script(game2, "game.gd"), "«Continuar» tiene que entrar en la partida")
	_check(int(state.seed_value) == run_seed,
		"al continuar debe jugarse la misma semilla: %d != %d" % [int(state.seed_value), run_seed])
	_check(int(state.threads) == 11, "al continuar deben volver los mismos hilos")
	_check(get_nodes_in_group("player").size() == 1, "no puede haber dos jugadoras")
	_check(not bool(state.resuming), "reanudar solo se puede pedir una vez")
	# La sala de combate que se había tocado tiene que volver como estaba.
	var rooms2: Dictionary = game2.get("rooms")
	var back: Node = rooms2.get(combat_cell)
	_check(is_instance_valid(back), "al continuar tiene que volver la misma sala de combate")
	if is_instance_valid(back):
		back.call("activate")
		game2.call("_populate_room", back)
		await _settle()
		_check(bool(back.get("is_cleared")) or (back.get("spawned") as Array).size() > 0,
			"la sala de combate tiene que volver como estaba")

	save_service.call("clear_run")
	if failures.is_empty():
		print("H3_MENU_OK: menú, nueva partida, salida al menú y continuar")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _goto(path: String) -> void:
	change_scene_to_file(path)
	await _settle()

# Los cambios de escena están aplazados: hay que dejar correr los frames.
func _settle() -> void:
	for i in 8:
		await process_frame

func _is_script(node: Node, file: String) -> bool:
	if node == null:
		return false
	return str(node.get_script().resource_path).ends_with(file)

func _name(node: Node) -> String:
	return node.name if node != null else "nada"
