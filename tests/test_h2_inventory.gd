extends SceneTree

# H2: contenido runtime, slots, restricciones, cargas y dependencias de sinergias.
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	var state: Node = root.get_node_or_null("GameState")
	var db: Node = root.get_node_or_null("SynergyDB")
	_check(state != null, "GameState autoload no está disponible")
	_check(db != null, "SynergyDB autoload no está disponible")
	if state == null or db == null:
		quit(1)
		return
	db.reload()
	_check((db.validate_content() as Array).is_empty(), "el contenido runtime debe ser válido")
	_check(db.items_data.size() == 10, "deben cargarse 10 objetos")
	_check(db.synergies_data.size() == 7, "deben cargarse 7 sinergias")
	_check(db.enemies_data.size() == 3, "deben cargarse 3 enemigos")

	state.start_run(2026)
	_check((state.get_slot_items("weapon") as Array).has("scissors_basic"), "el arma inicial debe ocupar el slot weapon")
	# Sin límite de huecos: todo lo que aparece se puede llevar, y la tijera de
	# precisión es una mejora que se aplica al tenerla (doc 07 §13).
	_check(state.add_item("scissors_precision"), "la tijera de precisión debe entrar sin sustituir nada")
	_check((state.items as Array).has("scissors_basic"), "el arma inicial se conserva: no hay límite que lo expulse")
	_check(state.add_item("spring_jumper"), "mecanismo debe ocupar su slot")
	_check(state.add_item("iron_magnet"), "el segundo mecanismo debe caber")
	_check(state.add_item("taut_thread"), "amuleto debe ocupar su slot")
	_check(state.add_item("music_box"), "el segundo amuleto debe caber")
	_check("trapped_notes" in state.synergies, "música + hilo deben formar notas atrapadas")

	state.life = 2.0
	_check(state.add_item("repair_coil"), "bobina debe ser consumible con vida incompleta")
	_check(state.add_item("repair_coil"), "la bobina debe apilarse hasta max_charges")
	_check(int(state.item_charges.get("repair_coil", 0)) == 2, "deben existir dos cargas")
	_check(state.consume_item("repair_coil"), "consumir una carga debe funcionar")
	_check(int(state.item_charges.get("repair_coil", 0)) == 1, "la carga restante debe conservarse")
	_check(state.consume_item("repair_coil"), "la segunda carga debe consumirse")
	_check(not (state.items as Array).has("repair_coil"), "al agotarse debe desaparecer el consumible")
	state.life = state.LIFE_MAX
	_check(not state.add_item("repair_coil"), "la restricción full_life debe bloquear el uso")

	# El consumible tiene que ser usable de verdad, con el botón táctil y sin
	# clavar el objeto en el código: se recorre el hueco, no se busca por id.
	var player = load("res://gameplay/player/lela.tscn").instantiate()
	root.add_child(player)
	await process_frame
	player.set_physics_process(false)
	state.life = 1.0
	_check(state.add_item("repair_coil"), "con vida baja la bobina debe poder comprarse")
	_check(int(state.get_slot_charges("consumable")) == 1, "una compra son una carga")
	player.call("_try_use_consumable")
	_check(is_equal_approx(state.life, 2.0), "usar el consumible tiene que curar un segmento")
	_check(int(state.get_slot_charges("consumable")) == 0, "usarlo debe gastar la carga")
	_check(not (state.items as Array).has("repair_coil"), "al gastar la última carga debe desaparecer")
	player.call("_try_use_consumable")
	_check(is_equal_approx(state.life, 2.0), "sin consumible no debe curar")
	# Con la vida llena no hace nada: ni cura ni gasta carga. Primero se compra,
	# porque con la vida llena la bobina ni siquiera se puede añadir.
	_check(state.add_item("repair_coil"), "la bobina debe poder volver a comprarse")
	state.life = state.LIFE_MAX
	player.call("_try_use_consumable")
	_check(int(state.get_slot_charges("consumable")) == 1, "con la vida llena no debe gastar carga")
	if is_instance_valid(player):
		player.free()

	var impulse: Array = db.check_for_item(["scissors_precision"], "spring_jumper")
	_check(impulse.has("impulse_scissors"), "tijeras + resorte deben formar tijeras de impulso")
	var stitches: Array = db.check_for_item(["scissors_precision"], "taut_thread")
	_check(stitches.has("living_stitches"), "tijeras + hilo deben formar puntadas vivas")

	state.end_run(false)
	if failures.is_empty():
		print("H2_OK: runtime content, slots, restricciones, cargas y sinergias")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
