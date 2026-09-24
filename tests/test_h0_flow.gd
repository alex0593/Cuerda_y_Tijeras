extends SceneTree

# H0 smoke test: monta la escena real y verifica que el flujo llega a una sala
# de combate con jugador y enemigos después de resolver la sala inicial.
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	var scene = load("res://gameplay/main/game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	_check(get_nodes_in_group("player").size() == 1, "debe existir exactamente un jugador al inicio")
	# La sala inicial se resuelve de forma diferida; después debe aparecer combate.
	await create_timer(1.2).timeout
	var current = scene.current_room
	_check(is_instance_valid(current), "debe existir una sala actual")
	if is_instance_valid(current):
		_check(String(current.kind) == "combat", "el flujo debe pasar de start a combat")
		_check(current.spawned.size() > 0, "la sala de combate debe tener enemigos")
		_check(get_nodes_in_group("player").size() == 1, "debe existir un jugador en combate")
	_check(scene.get("room_index") == 1, "el índice de sala debe avanzar una vez")
	if is_instance_valid(scene):
		scene.free()
	for i in 10:
		await process_frame
		await physics_frame
	if failures.is_empty():
		print("H0_SMOKE_OK: start -> combat, player + enemies")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
