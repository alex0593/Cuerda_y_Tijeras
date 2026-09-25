extends SceneTree

# H3: cambiar objetos cuando el slot está lleno, sin perder nada sin querer.
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _back_event() -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = KEY_BACK
	key.pressed = true
	return key

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	var state: Node = root.get_node_or_null("GameState")
	_check(state != null, "GameState autoload no está disponible")
	if state == null:
		quit(1)
		return

	# 1. Un slot lleno ya no se rellena solo ni descarta nada por su cuenta.
	state.start_run(555)
	_check(state.add_item("spring_jumper"), "debe entrar el primer mecanismo")
	_check(state.add_item("iron_magnet"), "debe entrar el segundo mecanismo")
	_check(not state.add_item("screws_cork"), "un tercer mecanismo debe rechazarse")
	_check("screws_cork" not in state.items, "el rechazo no debe descartar nada")
	_check(state.items.size() == 3, "el inventario no debe perder objetos al rechazar")

	# 2. El rechazo informa del slot lleno y ofrece a quién cambiar.
	var info: Dictionary = state.get_swap_info("screws_cork")
	_check(bool(info.get("needs_swap", false)), "un slot lleno debe admitir cambio")
	_check(String(info.get("slot", "")) == "mechanism", "el slot del objeto debe ser mechanism")
	var candidates: Array = info.get("candidates", [])
	_check(candidates.size() == 2, "debe ofrecer los 2 mecanismos que llevas")
	_check("spring_jumper" in candidates and "iron_magnet" in candidates, "los candidatos deben ser los objetos del slot")

	# 3. Cambiar sustituye exactamente el objeto elegido.
	_check(state.swap_item("screws_cork", "iron_magnet"), "el cambio debe aceptarse")
	_check("screws_cork" in state.items, "el objeto nuevo debe entrar")
	_check(not ("iron_magnet" in state.items), "el objeto elegido debe salir")
	_check("spring_jumper" in state.items, "el otro objeto del slot debe conservarse")

	# 4. No se puede cambiar por un objeto que no está en ese slot.
	_check(not state.swap_item("music_box", "screws_cork"), "no se debe cambiar fuera del slot")
	_check(not state.swap_item("music_box", "scissors_basic"), "el arma no es candidata de un amuleto")

	# 5. Las restricciones siguen mandando sobre el cambio.
	state.life = state.LIFE_MAX
	var heal_info: Dictionary = state.get_swap_info("repair_coil")
	_check(not bool(heal_info.get("needs_swap", false)), "con la vida llena no se debe ofrecer cambio")
	_check(String(heal_info.get("reason", "")) != "", "debe explicar por qué no se puede")

	# 6. Sin cambio, nada se pierde: el objeto se queda en el suelo.
	state.life = 1.0
	_check(state.add_item("music_box"), "debe entrar un amuleto")
	_check(state.add_item("toy_glue"), "debe entrar un segundo amuleto")
	var stuck: Dictionary = state.get_swap_info("taut_thread")
	_check(bool(stuck.get("needs_swap", false)), "el segundo amuleto debe admitir cambio")
	_check(state.items.size() == 5, "no debe perderse nada antes de decidir")

	# 7. El caso que bloqueaba contenido: con los dos amuletos ocupados,
	#    cambiar el pegamento por el hilo completa "notas atrapadas".
	_check(not ("trapped_notes" in state.synergies), "caja de música + pegamento no forma la sinergia")
	_check(state.swap_item("taut_thread", "toy_glue"), "debe poder cambiar el pegamento por el hilo")
	_check("taut_thread" in state.items, "el hilo tensado debe entrar")
	_check(not ("toy_glue" in state.items), "el pegamento debe salir")
	_check("trapped_notes" in state.synergies, "el cambio debe formar notas atrapadas")

	state.end_run(false)
	await _run_touch_buttons()
	await _run_back_button()

func _run_touch_buttons() -> void:
	# Los botones no deben quedarse el toque: si lo hacen, la jugadora nunca
	# puede pausar, hacer dash ni rebobinar en el móvil.
	var scene = load("res://gameplay/main/game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var touch = scene.get_node_or_null("TouchControls")
	_check(touch != null, "debe existir TouchControls")
	if touch == null:
		return
	touch.visible = true
	var state: Node = root.get_node_or_null("GameState")
	# Cada botón tiene que dejar pasar el evento.
	for button_name in ["Dash", "Rewind"]:
		var button = touch.get_node_or_null("Right/" + button_name) as Control
		_check(button != null, "falta el botón %s" % button_name)
		if button:
			_check(button.mouse_filter == Control.MOUSE_FILTER_IGNORE,
				"%s debe ignorar el toque para que _unhandled_input lo reciba" % button_name)
	for button_name in ["Pause", "Restart"]:
		var button = touch.get_node_or_null(button_name) as Control
		_check(button != null, "falta el botón %s" % button_name)
		if button:
			_check(button.mouse_filter == Control.MOUSE_FILTER_IGNORE,
				"%s debe ignorar el toque para que _unhandled_input lo reciba" % button_name)

	# Un toque sobre el botón de pausa debe pausar de verdad.
	var pause_button = touch.get_node_or_null("Pause") as Control
	if pause_button:
		var centre := pause_button.get_global_rect().get_center()
		var action := String(touch.call("_ui_action_at", centre))
		_check(action == "pause", "el centro del botón debe mapearse a la acción pause")

	state.end_run(false)
	paused = false
	if is_instance_valid(scene):
		scene.free()
	for i in 3:
		await process_frame

func _run_back_button() -> void:
	# El botón atrás de Android no debe cerrar la app ni perder la partida.
	var scene = load("res://gameplay/main/game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var state: Node = root.get_node_or_null("GameState")
	_check(state != null and bool(state.is_running), "debe haber partida en curso")

	# En Android el botón atrás llega como KEYCODE_BACK.
	scene._unhandled_input(_back_event())
	await process_frame
	_check(bool(paused), "el botón atrás debe pausar, no cerrar la app")
	_check(state != null and bool(state.is_running), "la partida no debe perderse con atrás")

	scene._unhandled_input(_back_event())
	await process_frame
	_check(bool(paused), "atrás con la partida ya pausada no debe hacer nada")

	# Con el panel de cambio abierto, atrás debe cerrar solo el panel.
	paused = false
	var panel = scene.get_node_or_null("SwapPanel")
	_check(panel != null, "debe existir el panel de cambio")
	if panel:
		panel.call("open", null, "spring_jumper", ["scissors_precision"])
		await process_frame
		_check(bool(paused), "el panel debe congelar la partida")
		scene._unhandled_input(_back_event())
		await process_frame
		_check(not bool(panel.get("is_open")), "atrás debe cerrar el panel de cambio")
		_check(not bool(paused), "cerrar el panel debe reanudar la partida")
		_check(state != null and bool(state.is_running), "cerrar el panel no debe perder la partida")

	state.end_run(false)
	paused = false
	if is_instance_valid(scene):
		scene.free()
	for i in 3:
		await process_frame
	if failures.is_empty():
		print("H3_SWAP_OK: cambio de objetos, cancelación segura y botón atrás")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
