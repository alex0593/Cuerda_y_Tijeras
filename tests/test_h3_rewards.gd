extends SceneTree

# H3: reparto de recompensas. Ningún objeto puede quedar inalcanzable.
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

	# 1. Ninguna sala regala objetos: solo el jefe y la tienda del taller los sueltan.
	for run_seed in [1, 99, 2026, 777777]:
		var run: Dictionary = generator.generate_run(run_seed)
		for room in run["rooms"]:
			for error in generator.validate_room(room):
				failures.append("semilla %d: %s" % [run_seed, error])
			_check((room.get("offers", []) as Array).is_empty(), "las salas ya no ofrecen objetos gratis")

	# 2. Cobertura: con suficientes semillas, todos los objetos deben salir alguna vez.
	#    La tienda pone 2 de su pool exclusiva y el jefe 1 del resto del catálogo.
	var reachable := {}
	var item_ids: Array = db.items_data.keys()
	for run_seed in range(1, 61):
		var run: Dictionary = generator.generate_run(run_seed * 7717)
		for room in run["rooms"]:
			for item_id in room.get("shop_offers", []):
				reachable[String(item_id)] = true
			var drop := String(room.get("boss_drop", ""))
			if drop != "":
				reachable[drop] = true
	for item_id in item_ids:
		if item_id == "scissors_basic":
			continue
		_check(reachable.has(item_id), "objeto inalcanzable en 60 semillas: %s" % item_id)

	# 2b. El jefe nunca suelta un consumible. Ganar no puede consistir en recoger
	#     una bobina de reparación, y ese objeto se compra en el taller.
	for run_seed in range(1, 121):
		var run: Dictionary = generator.generate_run(run_seed * 331)
		for room in run["rooms"]:
			var drop := String(room.get("boss_drop", ""))
			if drop == "":
				continue
			_check(String(db.get_item(drop).get("slot", "")) != "consumable",
				"el jefe no debe soltar un consumible: %s (semilla %d)" % [drop, run_seed])
		# Y el reemplazo en tiempo de partida tampoco puede caer en un consumible.
		var owned := ["scissors_basic"]
		var fallback := String(generator.boss_drop_for(
			{"seed": run_seed, "boss_drop": "repair_coil"}, owned))
		_check(fallback != "repair_coil", "boss_drop_for no debe devolver un consumible")

	# 3. Determinismo: la misma semilla ofrece los mismos objetos.
	var a: Dictionary = generator.generate_run(4242)
	var b: Dictionary = generator.generate_run(4242)
	_check(a == b, "la misma semilla debe ofrecer los mismos objetos")

	# 4. Las sinergias de dos objetos reales deben ser alcanzables con el pool.
	var synergy_ids: Array = db.synergies_data.keys()
	for synergy_id in synergy_ids:
		var needs: Array = db.synergies_data[synergy_id].get("needs", [])
		var pair_offerable := true
		for required in needs:
			if String(required) == "shadow":
				pair_offerable = false
		_check(pair_offerable or String(needs[0]) == "shadow" or String(needs[1]) == "shadow",
			"sinergia %s debe usar objetos reales o la entidad shadow" % synergy_id)
		if not pair_offerable:
			continue
		# Los dos componentes deben poder aparecer en partidas distintas del pool.
		for required in needs:
			_check(String(required) in reachable or String(required) == "scissors_basic",
				"componente de sinergía inalcanzable: %s" % required)

	# 5. La jugadora puede recoger varios objetos de la misma sala.
	state.start_run(31337)
	_check(state.add_item("spring_jumper"), "debe admitir un mecanismo")
	_check(state.add_item("iron_magnet"), "debe admitir un segundo mecanismo (D-002)")
	_check(state.add_item("music_box"), "debe admitir un amuleto")
	_check(state.add_item("taut_thread"), "debe admitir un segundo amuleto (D-002)")
	_check(state.items.size() >= 5, "el inventario debe admitir 5 objetos activos")
	state.end_run(false)

	if failures.is_empty():
		print("H3_OK: recompensas por semilla, cobertura total y elección de objetos")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
