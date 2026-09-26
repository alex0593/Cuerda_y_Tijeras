extends SceneTree

# H3: economía de hilos — botín de sala, tienda del taller y jefe que suelta objeto.
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
	_check(db.get_entry_cost() > 0, "entrar a la tienda debe costar hilos")

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

	# 3. Las salas ya no regalan objetos: solo dejan hilos para la tienda.
	var total_loot := 0
	for room in (generator.generate_run(4242)["rooms"] as Array):
		total_loot += (room.get("loot", []) as Array).size()
		_check((room.get("offers", []) as Array).is_empty(), "las salas no deben ofrecer objetos gratis")
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
			_check(not (String(boss_drop) in db.get_shop_pool()), "el jefe no debe soltar lo exclusivo del taller")
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

	# 6. Sin límite de huecos: todo lo que aparece se puede llevar.
	state.threads = 20
	_check(state.add_item("spring_jumper"), "debe entrar un mecanismo")
	_check(state.add_item("screws_cork"), "debe entrar un segundo mecanismo")
	_check(state.add_item("taut_thread"), "debe entrar un amuleto")
	_check(state.add_item("music_box"), "debe entrar un segundo amuleto")
	_check(state.items.size() >= 6, "el inventario debe admitir todos los objetos")

	# 7. Reparar vida: cuesta hilos y nunca cura de más.
	state.life = 1.0
	var repair_price: int = int(db.get_repair_cost())
	_check(state.threads >= repair_price, "el test necesita hilos para reparar")
	_check(state.buy_repair(), "reparar con hilos suficientes debe funcionar")
	_check(state.life == minf(state.LIFE_MAX, 1.0 + db.get_repair_amount()), "la reparación debe curar el importe declarado")
	_check(state.threads == 20 - repair_price, "la reparación debe descontar su precio")
	state.life = state.LIFE_MAX
	var pointless: Dictionary = state.get_repair_info()
	_check(not bool(pointless["allowed"]), "con la vida llena no se debe poder reparar")
	_check(not state.buy_repair(), "reparar con la vida llena debe rechazarse")

	# 8. La tienda también pide partida en curso.
	state.end_run(false)
	paused = false
	var closed: Dictionary = state.get_buy_info("iron_magnet")
	_check(not bool(closed.get("allowed", false)), "sin partida no se debe poder comprar")
	_check(not state.buy_shop_entry().get("ok", false), "sin partida no se debe poder abrir la tienda")

	# 9. Pool exclusiva del taller: 2 ofertas por partida y fuera lo que ya llevas.
	var pool: Array = db.get_shop_pool()
	_check(pool.size() >= db.get_shop_offers(), "la pool del taller debe cubrir sus ofertas")
	var sold := {}
	for run_seed in range(1, 21):
		var run: Dictionary = generator.generate_run(run_seed * 1013)
		for room in (run["rooms"] as Array):
			var kind := String(room.get("kind", ""))
			var shop: Array = room.get("shop_offers", [])
			if kind == "workshop":
				_check(shop.size() == db.get_shop_offers(),
					"el taller debe exponer %d ofertas" % db.get_shop_offers())
			elif not shop.is_empty():
				_check(false, "solo la sala de taller expone su pool")
			for item_id in shop:
				_check(String(item_id) in pool, "el taller vende %s fuera de su pool" % item_id)
				sold[String(item_id)] = true
	_check(sold.size() == pool.size(), "con 20 semillas debe girar toda la pool del taller (%d/%d)" % [sold.size(), pool.size()])
	# Lo que ya llevas no vuelve a aparecer: la tienda repone con la semilla.
	state.start_run(9003)
	state.add_item("scissors_precision")
	var workshop: Dictionary = (generator.generate_run(9003)["rooms"] as Array)[5]
	var refreshed: Array = generator.shop_offers_for(workshop, state.items)
	_check(refreshed.size() == db.get_shop_offers(), "la tienda debe seguir ofreciendo %d objetos" % db.get_shop_offers())
	_check(not ("scissors_precision" in refreshed), "un objeto ya llevado no debe volver a ofrecerse")
	state.end_run(false)
	paused = false

	# 10. Entrar a la tienda cuesta un alfiler, o forzarla con hilos.
	state.start_run(9002)
	state.alfilers = 0
	state.threads = 0
	_check(not state.buy_shop_entry().get("ok", false), "sin alfiler ni hilos no se debe poder abrir")
	_check(String(state.get_entry_info().get("reason", "")) == "faltan hilos", "debe explicar que faltan hilos")
	state.threads = int(db.get_entry_cost())
	_check(state.buy_shop_entry().get("ok", false), "con hilos suficientes se debe poder forzar la tienda")
	_check(state.shop_open, "la tienda debe quedar abierta")
	_check(state.threads == 0, "forzar la tienda debe descontar sus hilos")
	_check(not state.buy_shop_entry().get("ok", false), "abierta no se debe poder abrir dos veces")
	state.start_run(9004)
	state.alfilers = 1
	_check(state.buy_shop_entry().get("ok", false), "con un alfiler se debe poder abrir")
	_check(state.alfilers == 0, "el alfiler se gasta al abrir")
	_check(state.shop_open, "la tienda debe quedar abierta")
	_check(String(state.get_entry_hint()) == "un alfiler o %d hilos" % db.get_entry_cost(),
		"el aviso debe decir qué falta para abrir")
	state.end_run(false)
	paused = false

	# 11. La tienda en la sala: nudo, ofertas en el suelo y compra al pisar.
	await _run_shop_scene(state)

	# 12. El overlay de pausa es un espejo del estado real de la partida.
	var scene = load("res://gameplay/main/game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	var overlay := scene.get_node_or_null("PauseOverlay") as CanvasLayer
	_check(overlay != null, "game.tscn debe tener el overlay de pausa")
	scene._unhandled_input(_back_event())
	await process_frame
	_check(bool(paused) and overlay != null and overlay.visible, "pausar debe mostrar el overlay")
	# Reanudar lo hace el botón Ⅱ de TouchControls; aquí se simula.
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

	if failures.is_empty():
		print("H3_ECONOMY_OK: botín de sala, tienda y botín de jefe")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

# Ejercita la tienda del taller de verdad: nudo, ofertas en el suelo y autocompra.
func _run_shop_scene(state: Node) -> void:
	var db: Node = root.get_node_or_null("SynergyDB")
	var generator: Node = root.get_node_or_null("RoomGenerator")
	var scene = load("res://gameplay/main/game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	# Saltamos a la sala de taller para probar la tienda sin jugar la partida.
	scene.room_index = 5
	scene._spawn_current()
	await process_frame
	await process_frame

	var workshop: Dictionary = {}
	for room in (generator.generate_run(4242)["rooms"] as Array):
		if String(room.get("kind", "")) == "workshop":
			workshop = room
	_check(not workshop.is_empty(), "debe existir la sala de taller")

	# Cerrada: el nudo está y las ofertas no se pueden tocar.
	_check(_find_label(scene.current_room, "TIENDA CERRADA") != null,
		"el mostrador debe indicar que la tienda está cerrada")
	var knots := _find_by_script(scene.current_room, "res://gameplay/pickups/shop_knot.gd")
	_check(knots.size() == 1, "la tienda cerrada debe tener un nudo")
	var cards := _find_by_script(scene.current_room, "res://gameplay/pickups/shop_offer.gd")
	_check(cards.size() == 3, "la tienda debe exponer 2 objetos y la reparación")
	for card in cards:
		_check(not bool(card.get("enabled")), "cerrada no se debe poder comprar")

	# Sin alfiler ni hilos el nudo no se corta.
	state.threads = 0
	state.alfilers = 0
	var shot: Area2D = Area2D.new()
	shot.add_to_group("projectile_player")
	(knots[0] as Node).emit_signal("area_entered", shot)
	await process_frame
	_check(not state.shop_open, "sin recursos el nudo no debe abrir la tienda")

	# Un tiro corta el nudo y cobra la entrada.
	state.threads = 20
	(knots[0] as Node).emit_signal("area_entered", shot)
	await process_frame
	_check(state.shop_open, "cortar el nudo debe abrir la tienda")
	_check(state.threads == 20 - int(db.get_entry_cost()), "abrir la tienda debe descontar sus hilos")
	for card in cards:
		_check(bool(card.get("enabled")), "abierta se debe poder comprar")

	# Pisar una oferta la compra si hay hilos.
	var player: Node = scene.current_room.get_tree().get_first_node_in_group("player")
	var item_card: Node = null
	var repair_card: Node = null
	for card in cards:
		if bool(card.get("is_repair")):
			repair_card = card
		elif item_card == null:
			item_card = card
	_check(item_card != null and repair_card != null, "debe haber oferta de objeto y de reparación")
	var price: int = int(db.get_price(String(item_card.get("offer_id"))))
	var threads_before: int = state.threads
	(item_card as Node).emit_signal("body_entered", player)
	await process_frame
	_check(state.threads == threads_before - price, "pisar una oferta debe descontar exactamente su precio")
	_check(String(item_card.get("offer_id")) in state.items, "el objeto comprado debe entrar")
	_check(not bool(item_card.get("enabled")), "una oferta comprada debe desaparecer del suelo")

	# La reparación también se compra al pisarla.
	state.life = 1.0
	threads_before = state.threads
	(repair_card as Node).emit_signal("body_entered", player)
	await process_frame
	_check(state.life > 1.0, "pisar la reparación debe curar")
	_check(state.threads == threads_before - int(db.get_repair_cost()), "la reparación debe descontar su precio")
	shot.queue_free()

	state.end_run(false)
	paused = false
	if is_instance_valid(scene):
		scene.free()
	for i in 3:
		await process_frame

func _find_by_script(node: Node, path: String) -> Array:
	var out: Array = []
	for child in node.find_children("*", "Node", true, false):
		var script: Script = child.get_script()
		if script and String((script as Script).resource_path) == path:
			out.append(child)
	return out

func _find_label(node: Node, text: String) -> Label:
	for child in node.find_children("*", "Label", true, false):
		if (child as Label).text == text:
			return child
	return null

func _back_event() -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = KEY_BACK
	key.pressed = true
	return key
