extends SceneTree

# Smoke/unit test del estado real del autoload GameState.
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	var state: Node = root.get_node_or_null("GameState")
	_check(state != null, "GameState autoload no está disponible")
	if state == null:
		quit(1)
		return
	state.start_run(12345)
	_check(state.is_running, "start_run debe activar la partida")
	_check(state.tension == state.TENSION_MAX, "la tensión inicial debe estar llena")
	_check(state.try_consume_tension(4.0), "un disparo con tensión suficiente debe consumirse")
	_check(is_equal_approx(state.tension, 96.0), "el coste de disparo debe descontarse")
	_check(not state.try_consume_tension(100.0), "no se puede gastar más tensión de la disponible")

	state.tension = 20.0
	_check(is_equal_approx(state.try_consume_dash(12.0), 1.0), "dash completo con coste suficiente")
	state.tension = 5.0
	_check(is_equal_approx(state.try_consume_dash(12.0), 0.5), "dash reducido con tensión parcial")
	state.tension = 0.0
	_check(is_equal_approx(state.try_consume_dash(12.0), 0.0), "dash bloqueado sin tensión")

	state.life = 3.0
	state.apply_damage(1.0, "test")
	_check(is_equal_approx(state.life, 2.0), "el daño debe reducir vida")
	state.rewind_charges = 1
	_check(state.try_consume_rewind(), "una carga de rebobinado debe consumirse")
	state.life = 2.0
	state.apply_damage(1.0, "test")
	_check(is_equal_approx(state.life, 2.0), "rebobinado debe otorgar invulnerabilidad")
	var save_service: Node = root.get_node_or_null("SaveService")
	_check(save_service != null, "SaveService autoload no está disponible")
	if save_service != null:
		state.tension = 42.0
		state.rooms_visited = 2
		_check(save_service.save_run(), "save_run debe escribir la partida")
		state.tension = 0.0
		state.rooms_visited = 0
		_check(save_service.load_run(), "load_run debe leer la partida")
		_check(is_equal_approx(state.tension, 42.0), "load_run debe restaurar tensión")
		_check(state.rooms_visited == 2, "load_run debe restaurar progreso")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_service.RUN_PATH))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_service.RUN_PATH + ".bak"))

	# Disparo automático: tiene que apuntar al enemigo, no en la dirección del
	# movimiento. Con la opción puesta, moverse en huida no puede hacer que el
	# tiro salga de espaldas.
	var player = load("res://gameplay/player/lela.tscn").instantiate()
	root.add_child(player)
	await process_frame
	player.set_physics_process(false)
	var dummy = load("res://gameplay/enemies/tin_soldier.tscn").instantiate()
	root.add_child(dummy)
	await process_frame
	dummy.set_physics_process(false)
	dummy.global_position = player.global_position + Vector2(200, 0)
	save_service.settings["auto_fire"] = true
	player.velocity = Vector2(-220.0, 0.0)  # Huyendo del enemigo: justo el caso roto.
	player.call("_update_aim")
	_check(player.aim_dir.dot(Vector2.RIGHT) > 0.9,
		"con disparo automático la puntería debe ir al enemigo, no al movimiento")
	save_service.settings["auto_fire"] = false
	dummy.global_position = player.global_position + Vector2(4000, 0)
	player.call("_update_aim")
	_check(player.aim_dir.dot(Vector2.LEFT) > 0.9,
		"sin disparo automático se sigue apuntando al movimiento")
	save_service.settings.erase("auto_fire")
	if is_instance_valid(dummy):
		dummy.free()
	if is_instance_valid(player):
		player.free()

	state.end_run(false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	var first := rng.randi()
	rng.seed = 999
	_check(rng.randi() == first, "la misma semilla debe ser reproducible")
	if failures.is_empty():
		print("H0_RULES_OK: tensión, dash, daño, rebobinado y semilla")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
