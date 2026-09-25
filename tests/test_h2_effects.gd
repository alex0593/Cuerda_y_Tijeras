extends SceneTree

# H2: efectos de objeto y sinergias en escenas reales.
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
	state.start_run(303)
	state.add_item("scissors_precision")
	state.add_item("spring_jumper")
	state.add_item("music_box")
	state.add_item("taut_thread")
	_check("impulse_scissors" in state.synergies, "debe formarse tijeras de impulso")
	_check("trapped_notes" in state.synergies, "debe formarse notas atrapadas")

	var lela = load("res://gameplay/player/lela.tscn").instantiate()
	root.add_child(lela)
	await process_frame
	await physics_frame
	_check(get_nodes_in_group("music_note").size() == 1, "Caja de música debe crear una nota orbital")
	lela._spawn_cut(Vector2.RIGHT, lela.global_position, 300.0, 5.0)
	await process_frame
	_check(get_nodes_in_group("projectile_player").size() >= 1, "_spawn_cut debe crear un proyectil")
	lela._try_dash()
	await create_timer(0.35).timeout
	_check(get_nodes_in_group("projectile_player").size() >= 8, "tijeras de impulso deben crear una onda de dash")

	state.end_run(false)
	if is_instance_valid(lela):
		lela.free()
	for projectile in get_nodes_in_group("projectile_player"):
		projectile.queue_free()
	for note in get_nodes_in_group("music_note"):
		note.queue_free()
	if failures.is_empty():
		print("H2_EFFECTS_OK: nota, ondas de dash y sinergias")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
