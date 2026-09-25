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
	_check(state.add_item("scissors_precision"), "una nueva arma debe entrar en el slot")
	_check(not (state.items as Array).has("scissors_basic"), "reemplazar arma debe retirar la anterior")
	_check(state.add_item("spring_jumper"), "mecanismo debe ocupar su slot")
	_check(state.add_item("iron_magnet"), "el segundo mecanismo provisional debe caber")
	_check(state.add_item("taut_thread"), "amuleto debe ocupar su slot")
	_check(state.add_item("music_box"), "el segundo amuleto provisional debe caber")
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
