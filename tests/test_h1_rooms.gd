extends SceneTree

# H1: verificación de generación, salida de sala, recompensas y escudo.
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	var state: Node = root.get_node_or_null("GameState")
	_check(state != null, "GameState autoload no está disponible")
	var generator: Node = root.get_node_or_null("RoomGenerator")
	_check(generator != null, "RoomGenerator autoload no está disponible")
	if generator != null:
		var first: Dictionary = generator.generate_run(777)
		var second: Dictionary = generator.generate_run(777)
		_check(first == second, "la misma semilla debe generar el mismo recorrido")
		for room in first["rooms"]:
			for error in generator.validate_room(room):
				failures.append(error)

	var scene = load("res://gameplay/main/game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await create_timer(1.2).timeout
	var room = scene.current_room
	_check(is_instance_valid(room), "debe existir una sala de combate")
	_check(is_instance_valid(room) and String(room.kind) == "combat", "H1 debe llegar a combate")
	_check(is_instance_valid(room) and room.spawned.size() > 0, "combate debe tener enemigos")
	_check(is_instance_valid(room) and not room.exit_area.monitoring, "la salida debe empezar cerrada")

	# Simulamos que la jugadora completa el combate y camina a la salida.
	room.call("_mark_cleared")
	await process_frame
	_check(room.is_cleared, "la sala debe quedar marcada como completada")
	_check(room.exit_area.monitoring, "limpiar la sala debe abrir la salida")
	_check(room.exit_hint.text.contains("ABIERTA"), "la sala debe indicar salida abierta")
	var player = get_first_node_in_group("player") as Node2D
	_check(player != null, "debe existir jugador para probar la salida")
	if player:
		player.global_position = Vector2(900, 270)
		await physics_frame
		await physics_frame
	await create_timer(1.0).timeout
	_check(scene.room_index >= 2, "entrar en la salida debe avanzar de sala")
	_check(is_instance_valid(scene.current_room) and String(scene.current_room.kind) == "treasure", "la siguiente sala debe ser treasure")

	# La sala de tesoro deja los objetos que ofrece el generador; Cogemos el primero
	# y comprobamos que entra en el inventario por identificador de contenido.
	var treasure = scene.current_room
	var pickups: Array = treasure.find_children("*", "Area2D", true, false)
	_check(not pickups.is_empty(), "treasure debe crear pickups de recompensa")
	if not pickups.is_empty() and player:
		var offered: Array = treasure.room_data.get("offers", [])
		_check(offered.size() == 3, "treasure debe ofrecer 3 objetos")
		player.global_position = (pickups[0] as Node2D).global_position
		await physics_frame
		await physics_frame
		_check(not offered.is_empty() and String(offered[0]) in state.items, "el jugador debe recoger el objeto ofrecido")

	# Escudo: frontal reduce el daño y trasero lo rompe.
	var soldier = load("res://gameplay/enemies/tin_soldier.tscn").instantiate()
	soldier.set("drop_rng_seed", 123)
	root.add_child(soldier)
	await process_frame
	soldier.set_physics_process(false)
	soldier._facing = Vector2.RIGHT
	var front_damage: float = soldier.adjust_damage(10.0, soldier.global_position + Vector2(100, 0))
	_check(front_damage < 10.0, "el escudo debe reducir daño frontal")
	var rear_damage: float = soldier.adjust_damage(10.0, soldier.global_position - Vector2(100, 0))
	_check(soldier.shield_broken, "un impacto trasero debe romper el escudo")
	_check(rear_damage > front_damage, "el impacto trasero debe causar más daño")

	state.end_run(false)
	paused = false
	if is_instance_valid(scene):
		scene.free()
	if is_instance_valid(soldier):
		soldier.free()
	for i in 5:
		await process_frame
	if failures.is_empty():
		print("H1_OK: generación, salida, recompensa y escudo")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
