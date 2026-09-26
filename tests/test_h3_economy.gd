extends SceneTree

# H3: economía de hilos — botín de sala, taller y jefe que suelta objeto.
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	var state: Node = root.get_node_or_null("GameState")
	var db: Node = root.get_node_or_null("SynergyDB")
	var generator: Node = root.get_node_or_null("RoomGenerator")
	_check(state != null, "GameState autoload no está disponible")
	_check(db != null, "SynergyDB autoload no está disponible")
	_check(generator != null, "RoomGenerator autoload no está disponible")
	if state == null or db == null or generator == null:
		quit(1)
		return

	db.reload()
	_check((db.validate_content() as Array).is_empty(), "la economía debe validar sin errores")

	# 1. Precios: todo el catálogo es comprable con la moneda de la partida.
	for item_id in db.items_data.keys():
		_check(db.get_price(String(item_id)) > 0, "objeto %s sin precio" % item_id)
	_check(db.get_repair_cost() > 0, "la reparación debe costar hilos")
	_check(db.get_repair_amount() > 0.0, "la reparación debe curar algo")

	# 2. Botín de sala: dentro del rango declarado y determinista por semilla.
	for run_seed in [1, 99, 2026]:
		var run: Dictionary = generator.generate_run(run_seed)
		var repeat: Dictionary = generator.generate_run(run_seed)
		_check(run == repeat, "semilla %d: el botín debe ser determinista" % run_seed)
		for room in run["rooms"]:
			for error in generator.validate_room(room):
				failures.append("semilla %d: %s" % [run_seed, error])
			var kind := String(room.get("kind", ""))
			var limits: Array = db.get_loot_range(kind)
			var loot: Array = room.get("loot", [])
			_check(loot.size() >= int(limits[0]) and loot.size() <= int(limits[1]),
				"sala %s: botín %d fuera de rango %s" % [kind, loot.size(), limits])

	# 3. Alguna sala de recompensa sí debe dejar hilos; sin ellos no hay taller.
	var total_loot := 0
	for room in (generator.generate_run(4242)["rooms"] as Array):
		total_loot += (room.get("loot", []) as Array).size()
	_check(total_loot > 0, "una partida debe dejar hilos en el suelo")

	# 4. El jefe siempre suelta un objeto alcanzable y distinto del arma inicial.
	var drops := {}
	for run_seed in range(1, 41):
		for room in (generator.generate_run(run_seed * 3571)["rooms"] as Array):
			if String(room.get("kind", "")) != "boss":
				continue
			var boss_drop := String(room.get("boss_drop", ""))
			_check(boss_drop != "", "el jefe debe soltar un objeto")
			_check(boss_drop != "scissors_basic", "el jefe no debe soltar el arma inicial")
			_check(not db.get_item(boss_drop).is_empty(), "boss_drop %s desconocido" % boss_drop)
			drops[boss_drop] = true
	_check(drops.size() >= 3, "el jefe debe poder soltar varios objetos distintos, no solo %d" % drops.size())

	# 5. Comprar: sin hilos no se compra; con hilos entra y se descuenta.
	state.start_run(9001)
	state.threads = 0
	var broke: Dictionary = state.get_buy_info("iron_magnet")
	_check(not bool(broke.get("allowed", false)), "sin hilos no se debe poder comprar")
	_check(String(broke.get("reason", "")) == "faltan hilos", "debe explicar que faltan hilos")
	var refused: Dictionary = state.buy_item("iron_magnet")
	_check(not bool(refused.get("ok", false)), "una compra sin hilos debe rechazarse")
	_check(not ("iron_magnet" in state.items), "una compra rechazada no debe entregar nada")
	_check(state.threads == 0, "una compra rechazada no debe tocar la moneda")

	state.threads = db.get_price("iron_magnet")
	var bought: Dictionary = state.buy_item("iron_magnet")
	_check(bool(bought.get("ok", false)), "con hilos suficientes la compra debe aceptarse")
	_check("iron_magnet" in state.items, "el objeto comprado debe entrar")
	_check(state.threads == 0, "la compra debe descontar exactamente su precio")

	# 6. Slot lleno: el taller ofrece cambio y solo gasta si se confirma.
	state.threads = 20
	_check(state.add_item("spring_jumper"), "debe entrar un segundo mecanismo")
	var full: Dictionary = state.get_buy_info("screws_cork")
	_check(bool(full.get("needs_swap", false)), "con el slot lleno debe pedir cambio")
	var candidates: Array = full.get("candidates", [])
	_check(candidates.size() == 2, "debe ofrecer los 2 mecanismos ocupados")
	var undecided: Dictionary = state.buy_item("screws_cork")
	_check(not bool(undecided.get("ok", false)), "sin elegir reemplazo no debe cobrar")
	_check(state.threads == 20, "un cambio sin confirmar no debe descontar hilos")
	var swapped: Dictionary = state.buy_item("screws_cork", "spring_jumper")
	_check(bool(swapped.get("ok", false)), "el cambio confirmado debe aceptarse")
	_check("screws_cork" in state.items, "el objeto comprado por cambio debe entrar")
	_check(not ("spring_jumper" in state.items), "el mecanismo elegido debe salir")
	_check(state.threads == 20 - db.get_price("screws_cork"), "el cambio debe descontar solo su precio")

	# 7. Reparar vida: cuesta hilos y nunca cura de más.
	state.life = 1.0
	var repair_price: int = int(db.get_repair_cost())
	_check(state.threads >= repair_price, "el test necesita hilos para reparar")
	_check(state.buy_repair(), "reparar con hilos suficientes debe funcionar")
	_check(state.life == minf(state.LIFE_MAX, 1.0 + db.get_repair_amount()), "la reparación debe curar el importe declarado")
	_check(state.threads == 20 - db.get_price("screws_cork") - repair_price, "la reparación debe descontar su precio")
	state.life = state.LIFE_MAX
	var pointless: Dictionary = state.get_repair_info()
	_check(not bool(pointless["allowed"]), "con la vida llena no se debe poder reparar")
	_check(not state.buy_repair(), "reparar con la vida llena debe rechazarse")

	# 8. El taller también pide partida en curso.
	state.end_run(false)
	paused = false
	var closed: Dictionary = state.get_buy_info("iron_magnet")
	_check(not bool(closed.get("allowed", false)), "sin partida no se debe poder comprar")

	# 9. Pool exclusiva del taller: solo se vende allí y gira entre partidas.
	var pool: Array = db.get_shop_pool()
	_check(pool.size() >= db.get_shop_offers_with_key(),
		"la pool del taller debe cubrir todas sus ofertas")
	var sold := {}
	for run_seed in range(1, 21):
		var run: Dictionary = generator.generate_run(run_seed * 1013)
		for room in (run["rooms"] as Array):
			var kind := String(room.get("kind", ""))
			var shop: Array = room.get("shop_offers", [])
			if kind == "workshop":
				_check(shop.size() == db.get_shop_offers_with_key(),
					"el taller debe exponer %d ofertas" % db.get_shop_offers_with_key())
			elif not shop.is_empty():
				_check(false, "solo la sala de taller expone su pool")
			for item_id in shop:
				_check(String(item_id) in pool, "el taller vende %s fuera de su pool" % item_id)
				_check(String(item_id) != "scissors_basic", "el taller no debe vender el arma inicial")
				sold[String(item_id)] = true
			for item_id in (room.get("offers", []) as Array):
				_check(not (String(item_id) in pool),
					"%s no debe caer gratis si pertenece a la pool del taller" % item_id)
	_check(sold.size() == pool.size(), "con 20 semillas debe girar toda la pool del taller (%d/%d)" % [sold.size(), pool.size()])

	# 10. La llave se compra con hilos y abre la tercera oferta al gastarla.
	state.start_run(9002)
	state.keys = 0
	state.threads = 0
	state.shop_extra_unlocked = false
	_check(state.visible_shop_offers(3) == db.get_shop_offers(), "sin llave solo se ven las ofertas base")
	var no_threads: Dictionary = state.get_key_info()
	_check(not bool(no_threads["allowed"]) and String(no_threads["reason"]) == "faltan hilos",
		"sin hilos la llave debe decir que faltan hilos")
	_check(not state.unlock_shop_offer(), "sin llave no se debe abrir la oferta extra")
	var no_key: Dictionary = state.get_unlock_info()
	_check(not bool(no_key["allowed"]) and String(no_key["reason"]) == "falta una llave",
		"debe explicar que falta una llave")
	state.threads = int(db.get_key_cost())
	_check(state.buy_key(), "con hilos suficientes la llave debe comprarse")
	_check(state.threads == 0, "la llave debe descontar su precio")
	_check(state.keys == 1, "la llave comprada debe sumarse")
	_check(not state.buy_key(), "con una llave ya comprada no se debe vender otra")
	_check(state.unlock_shop_offer(), "con una llave la oferta extra debe abrirse")
	_check(state.keys == 0, "la llave se gasta al abrir la oferta")
	_check(state.shop_extra_unlocked, "la oferta extra debe quedar abierta")
	_check(state.visible_shop_offers(3) == db.get_shop_offers_with_key(),
		"abierta debe enseñar todas las ofertas de la pool")
	_check(not state.get_unlock_info().get("allowed", false), "no se debe poder abrir dos veces")
	state.end_run(false)
	paused = false

	# 11. El panel del taller se pinta, congela la partida y se cierra limpio.
	await _run_shop_panel(state)

	if failures.is_empty():
		print("H3_ECONOMY_OK: botín de sala, taller y botín de jefe")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

# Ejercita ui/shop_panel.gd de verdad: construir los botones, congelar y comprar.
func _run_shop_panel(state: Node) -> void:
	var content: Node = root.get_node_or_null("SynergyDB")
	var generator: Node = root.get_node_or_null("RoomGenerator")
	var scene = load("res://gameplay/main/game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var panel = scene.get_node_or_null("ShopPanel")
	_check(panel != null, "debe existir el panel del taller en game.tscn")
	if panel == null:
		if is_instance_valid(scene):
			scene.free()
		return

	# Las ofertas salen de la sala de taller de una partida con semilla.
	var offers: Array = []
	for room in (generator.generate_run(4242)["rooms"] as Array):
		if String(room.get("kind", "")) == "workshop":
			offers = room.get("shop_offers", []) as Array
	_check(offers.size() == int(content.get_shop_offers_with_key()),
		"el taller debe sortear todas las ofertas de su pool")

	_check(not bool(panel.get("is_open")), "el taller debe arrancar cerrado")
	state.threads = 20
	state.keys = 0
	state.shop_extra_unlocked = false
	var overlay := scene.get_node_or_null("PauseOverlay") as CanvasLayer
	_check(overlay != null, "game.tscn debe tener el overlay de pausa")

	# Pausa manual: el overlay es un espejo del estado real de la partida.
	scene._unhandled_input(_back_event())
	await process_frame
	_check(bool(paused) and overlay != null and overlay.visible, "pausar debe mostrar el overlay")

	# El taller se abre por encima de esa pausa: no debe heredar el texto.
	panel.call("open", offers)
	await process_frame
	_check(bool(panel.get("is_open")), "el taller debe abrirse")
	_check(bool(paused), "el taller debe congelar la partida")
	_check(overlay != null and not overlay.visible, "el overlay de pausa no debe tapar el taller")

	# Solo se enseñan las ofertas expuestas, no todo el catálogo.
	var body: Control = panel.get("_body")
	_check(body != null and body.get_child_count() >= 3, "el taller debe pintar catálogo y acciones")
	var expected: int = state.visible_shop_offers(offers.size())
	_check(expected == int(content.get_shop_offers()), "sin llave deben verse %d ofertas" % content.get_shop_offers())
	var buttons: Array = _grid_buttons(body)
	_check(buttons.size() == expected, "el taller debe ofrecer %d objetos, no %d" % [expected, buttons.size()])

	var key_button: Button = null
	var unlock_button: Button = null
	if body.get_child_count() >= 3:
		var first_row := body.get_child(1) as Container
		var second_row := body.get_child(2) as Container
		_check(first_row != null and first_row.get_child_count() == 2, "debe haber reparación y compra de llave")
		_check(second_row != null and second_row.get_child_count() == 2, "debe haber oferta extra y salir")
		if first_row != null and first_row.get_child_count() >= 2:
			key_button = first_row.get_child(1) as Button
		if second_row != null and second_row.get_child_count() >= 1:
			unlock_button = second_row.get_child(0) as Button
	_check(key_button != null and not key_button.disabled, "con hilos la llave debe estar a la venta")
	_check(unlock_button != null and unlock_button.disabled, "sin llave la oferta extra debe estar bloqueada")

	# La llave se compra aquí y abre la tercera oferta al gastarla.
	var threads_before: int = state.threads
	if key_button != null:
		key_button.pressed.emit()
	await process_frame
	_check(state.keys == 1, "el taller debe entregar la llave comprada")
	_check(state.threads == threads_before - int(content.get_key_cost()), "la llave debe descontar su precio")
	unlock_button = null
	if body.get_child_count() >= 3:
		var row := body.get_child(2) as Container
		if row != null and row.get_child_count() >= 1:
			unlock_button = row.get_child(0) as Button
	_check(unlock_button != null and not unlock_button.disabled, "con una llave la oferta extra debe abrirse")
	if unlock_button != null:
		unlock_button.pressed.emit()
	await process_frame
	_check(state.shop_extra_unlocked, "la oferta extra debe quedar abierta")
	_check(state.keys == 0, "la llave se gasta al abrir la oferta")
	buttons = _grid_buttons(body)
	_check(buttons.size() == offers.size(), "abierta debe enseñar las %d ofertas sorteadas" % offers.size())

	# Pulsar una opción compra o pasa a elegir a quién reemplazar.
	threads_before = state.threads
	var pressed := false
	for button in buttons:
		var candidate := button as Button
		if candidate and not candidate.disabled:
			candidate.pressed.emit()
			pressed = true
			break
	_check(pressed, "con hilos debe haber al menos una opción comprable")
	await process_frame
	_check(bool(panel.get("is_open")), "comprar no debe cerrar el taller")
	_check(state.threads <= threads_before, "comprar nunca debe sumar hilos")

	# El botón atrás cierra solo el panel y devuelve el control a la partida.
	scene._unhandled_input(_back_event())
	await process_frame
	_check(not bool(panel.get("is_open")), "atrás debe cerrar el taller")
	_check(not bool(paused), "cerrar el taller debe reanudar la partida")
	_check(bool(state.is_running), "cerrar el taller no debe perder la partida")
	_check(overlay != null and not overlay.visible, "cerrar el taller no debe dejar el overlay de pausa pegado")

	# Si algo reanuda por otro camino (p. ej. el cierre de un panel), el texto
	# de pausa no puede quedarse en pantalla mientras la partida corre.
	scene._unhandled_input(_back_event())
	await process_frame
	_check(bool(paused) and overlay != null and overlay.visible, "pausar de nuevo debe mostrar el overlay")
	paused = false
	await process_frame
	_check(overlay != null and not overlay.visible, "el overlay debe desaparecer al reanudar")
	_check(not bool(paused), "la partida debe quedar corriendo")

	state.end_run(false)
	paused = false
	if is_instance_valid(scene):
		scene.free()
	for i in 3:
		await process_frame

func _grid_buttons(body: Control) -> Array:
	var out: Array = []
	if body == null or body.get_child_count() < 1:
		return out
	var wrapper := body.get_child(0) as CenterContainer
	if wrapper == null or wrapper.get_child_count() < 1:
		return out
	var grid := wrapper.get_child(0) as GridContainer
	if grid == null:
		return out
	for child in grid.get_children():
		out.append(child)
	return out

func _back_event() -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = KEY_BACK
	key.pressed = true
	return key
