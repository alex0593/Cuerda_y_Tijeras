extends SceneTree

# H3: el resumen tiene que contar qué pasó, no solo cuánto duró (doc 08 §2).
# Y tiene que tener sus propios botones: los del HUD quedan debajo de la capa
# del resumen, así que en móvil al terminar no había manera de seguir jugando.
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
	# El perfil empieza limpio para que se vea lo que esta partida aporta.
	save_service.profile = {"unlocked_items": ["scissors_basic"], "seen_synergies": [], "best_time": 0.0, "runs": 0}

	var scene = load("res://gameplay/main/game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("_start_new_run", 909)
	for i in 4:
		await process_frame

	# --- 1. Derrota: dice qué llevaba, las sinergias y qué la mató.
	state.add_item("scissors_precision")
	state.add_item("spring_jumper")
	state.set("life", 1.0)
	state.set("cause_of_death", "caja_cero")
	scene.call("_on_run_ended", false)
	await process_frame
	var box = scene.get_node("End/Box")
	_check(bool(scene.get_node("End").visible), "el resumen tiene que verse al terminar")
	var title := (box.get_node("Title") as Label).text
	_check(title.contains("no ha terminado"), "el título tiene que decir que se perdió: %s" % title)
	var objects := (box.get_node("Objects") as Label)
	_check(objects.visible, "el resumen tiene que decir qué objetos llevabas")
	_check(objects.text.contains("Tijeras de precisión") and objects.text.contains("Resorte saltador"),
		"los objetos se tienen que ver por su nombre, no por su id: %s" % objects.text)
	var synergies := (box.get_node("Synergies") as Label)
	_check(synergies.visible, "el resumen tiene que decir las sinergias formadas")
	_check(synergies.text.contains("Tijeras de impulso"),
		"las sinergias se tienen que ver por su nombre: %s" % synergies.text)
	var cause := (box.get_node("Cause") as Label)
	_check(cause.visible, "al perder hay que decir de qué")
	_check(cause.text.contains("Caja de Cero"), "la causa se tiene que contar en palabras: %s" % cause.text)
	_check((box.get_node("Seed") as Label).text.contains("909"), "el resumen tiene que llevar la semilla")
	var stats_text := (box.get_node("Stats") as Label).text
	_check(stats_text.contains("Salas %d/%d" % [int(state.rooms_visited), 9]),
		"el resumen tiene las salas visitadas: %s" % stats_text)
	_check(stats_text.contains("Bajas %d" % int(state.kills)), "el resumen tiene las bajas: %s" % stats_text)
	_check((box.get_node("Stats") as Label).text.contains("Tiempo"), "el resumen tiene la duración")

	# --- 2. Lo descubierto pasa al perfil, que es lo que hay detrás de la colección.
	var unlocked: Array = save_service.profile.get("unlocked_items", [])
	var seen: Array = save_service.profile.get("seen_synergies", [])
	_check(unlocked.has("scissors_precision") and unlocked.has("spring_jumper"),
		"lo que llevas tiene que pasar al perfil: %s" % str(unlocked))
	_check(seen.has("impulse_scissors"), "las sinergias formadas tienen que pasar al perfil: %s" % str(seen))
	_check(int(save_service.profile.get("runs", 0)) == 1, "el perfil tiene que contar la partida")

	# --- 3. El resumen tiene botones propios, y son los únicos que se ven.
	var retry := box.get_node("Buttons/Retry") as Button
	var menu := box.get_node("Buttons/Menu") as Button
	_check(retry.visible and menu.visible, "el resumen necesita sus botones para seguir jugando")
	_check(not save_service.has_run(), "una partida terminada no se puede continuar")

	# --- 4. Victoria: no hay causa de muerte que contar.
	(box.get_node("Cause") as Label).text = "Causa: algo"
	(scene.get_node("End") as CanvasLayer).visible = false
	state.set("cause_of_death", "")
	scene.call("_on_run_ended", true)
	await process_frame
	_check(not (box.get_node("Cause") as Label).visible, "en victoria no hay causa de muerte que enseñar")
	_check((box.get_node("Title") as Label).text.contains("Caja de Cero"),
		"el título de victoria tiene que nombrar al jefe: %s" % (box.get_node("Title") as Label).text)
	_check(float(save_service.profile.get("best_time", 0.0)) > 0.0, "una victoria tiene que guardar el mejor tiempo")

	# --- 5. Reintentar desde el resumen arranca una partida de verdad.
	(scene.get_node("End") as CanvasLayer).visible = false
	(box.get_node("Buttons/Retry") as Button).emit_signal("pressed")
	for i in 8:
		await process_frame
	_check(not bool(scene.get_node("End").visible), "reintentar tiene que cerrar el resumen")
	_check(get_nodes_in_group("player").size() == 1, "reintentar tiene que haber metido a la jugadora")
	_check((scene.get("rooms") as Dictionary).size() == 9, "reintentar tiene que haber montado el mapa")

	save_service.call("clear_run")
	if is_instance_valid(scene):
		scene.free()
	for i in 3:
		await process_frame
	if failures.is_empty():
		print("H3_SUMARIO_OK: el resumen cuenta la partida y deja seguir jugando")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
