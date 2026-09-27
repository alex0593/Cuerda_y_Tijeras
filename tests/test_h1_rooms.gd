extends SceneTree

# H1: mapa de salas — generación, puertas entre vecinas, estado que se conserva
# y escudo del soldado.
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

	# 1. El mapa: 9 salas, esquinas fijas y puertas simétricas.
	if generator != null:
		for run_seed in [777, 4242, 99001]:
			var run: Dictionary = generator.generate_run(run_seed)
			var repeat: Dictionary = generator.generate_run(run_seed)
			_check(run == repeat, "la misma semilla debe generar el mismo mapa")
			for error in generator.validate_run(run):
				failures.append("semilla %d: %s" % [run_seed, error])
			for room in run["rooms"]:
				for error in generator.validate_room(room):
					failures.append("semilla %d: %s" % [run_seed, error])
			_check((run["rooms"] as Array).size() == 9, "el mapa debe tener 9 salas")

	var scene = load("res://gameplay/main/game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	# 2. El mapa existe entero desde el principio, pero solo despierta la de inicio.
	_check((scene.rooms as Dictionary).size() == 9, "el mapa debe tener 9 salas en escena")
	_check(int(state.rooms_total) == 9, "el estado debe conocer el tamaño del mapa")
	var start = scene.rooms.get(Vector2i(0, 0))
	_check(is_instance_valid(start), "debe existir la sala de inicio")
	_check(is_instance_valid(start) and String(start.kind) == "start", "el inicio va en la esquina")
	_check(scene.current_cell == Vector2i(0, 0), "la jugadora empieza en el inicio")
	_check(is_instance_valid(start) and start.is_active, "la sala de inicio debe estar activa")
	_check(is_instance_valid(start) and start.is_cleared, "el inicio no tiene enemigos: debe estar despejado")
	var player = get_first_node_in_group("player") as Node2D
	_check(player != null, "debe existir una única jugadora")
	_check((get_nodes_in_group("player") as Array).size() == 1, "el mapa no puede duplicar a la jugadora")
	# La jugadora es hija del mapa, no de la sala: si se dibuja antes que el
	# suelo, desaparece bajo el mapa y no se ve en absoluto.
	var floor = (start.get_node_or_null("Floor") as Node2D) if is_instance_valid(start) else null
	_check(is_instance_valid(floor) and player.z_index > floor.z_index,
		"la jugadora se dibuja por encima del suelo de la sala")

	# 3. Una sala sin visitar está dormida: sin enemigos ni botín.
	var combat: Node = null
	for cell in scene.rooms:
		var room = scene.rooms[cell]
		if String(room.kind) == "combat":
			combat = room
			break
	_check(combat != null, "el mapa debe tener salas de combate")
	if combat == null:
		quit(1)
		return
	_check(not combat.is_active, "una sala sin visitar no debe tener enemigos")
	combat.activate()
	await process_frame
	_check((combat.spawned as Array).size() > 0, "combate debe tener enemigos")
	_check(not combat.is_cleared, "con enemigos vivos la puerta debe seguir cerrada")
	var locked := false
	for dir in combat.door_areas.keys():
		if not (combat.door_areas[dir] as Area2D).monitoring:
			locked = true
	_check(locked, "las puertas deben empezar cerradas")

	# 3b. Encuadre: la jugadora tiene que verse con tamaño y no salirse de la
	#     pantalla ni al pegarse a un muro. En un móvil panorámico el viewport
	#     es más bajo que la sala y, sin margen, el personaje salía pegado al
	#     borde y era difícil de encontrar.
	var cam = scene.get("camera")
	var view: Vector2 = scene.get_viewport_rect().size
	_check(cam.zoom.x > 0.0, "el encuadre tiene que ser válido")
	var visible_world: Vector2 = view / cam.zoom
	# La vista tiene que ser más pequeña que la sala en el eje que manda: si no,
	# la cámara se queda sin margen y empuja a la jugadora al borde.
	var room_size: Vector2 = scene.flow.get("room_size", Vector2(1280, 720))
	_check(visible_world.x <= room_size.x or visible_world.y <= room_size.y,
		"la vista debe ser más pequeña que la sala en al menos un eje: vista %s, sala %s" % [str(visible_world.round()), str(room_size)])
	# Pegada a la esquina de la sala, la jugadora sigue dentro de la pantalla.
	# La conversión a píxeles de pantalla tiene que multiplicar por el zoom: el
	# centro de la cámara va en unidades de mundo y la vista en píxeles.
	player.global_position = start.global_position + Vector2(60, 60)
	await process_frame
	await process_frame
	var centre: Vector2 = cam.get_screen_center_position()
	var on_screen: Vector2 = (player.global_position - centre) * cam.zoom + view * 0.5
	_check(on_screen.x > 0.0 and on_screen.x < view.x and on_screen.y > 0.0 and on_screen.y < view.y,
		"la jugadora no puede salirse de la pantalla: está en %s de %s" % [str(on_screen.round()), str(view.round())])
	# Y tiene que ocupar una parte visible de la pantalla, no ser una mota. En un
	# móvil panorámico mide alrededor del 5%; en el viewport cuadrado del test
	# headless baja, porque ahí se ve mucho más mundo.
	var share: float = 36.0 * cam.zoom.y / view.y
	_check(share > 0.02, "la jugadora ocupa solo el %.1f%% de la pantalla: es demasiado pequeña" % (share * 100.0))
	player.global_position = start.global_position + Vector2(864, 486)
	await process_frame

	# 4. Limpiar la sala abre sus puertas y no se deshace.
	for enemy in combat.spawned:
		if is_instance_valid(enemy):
			enemy.take_hit(9999.0, "test")
	await process_frame
	await process_frame
	_check(combat.is_cleared, "la sala debe quedar marcada como completada")
	var opened := 0
	for dir in combat.door_areas.keys():
		if (combat.door_areas[dir] as Area2D).monitoring:
			opened += 1
	_check(opened == (combat.doors as Array).size(), "limpiar la sala debe abrir todas sus puertas")
	var unlocked := true
	for dir in combat.door_bodies.keys():
		var shape = (combat.door_bodies[dir] as Node2D).get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape and not shape.disabled:
			unlocked = false
	_check(unlocked, "abrir la puerta tiene que quitar el cierre, no solo el color")

	# 5. Cruzar una puerta lleva a la vecina y despierta su contenido.
	var direction := "right" if "right" in (combat.doors as Array) else String(combat.doors[0])
	var next_cell: Vector2i = combat.grid_cell + scene.STEP.get(direction, Vector2i.ZERO)
	combat.emit_signal("door_entered", direction)
	for i in 3:
		await process_frame
	_check(scene.current_cell == next_cell, "cruzar la puerta debe llevar a la sala vecina")
	_check(scene.visited.has(next_cell), "la sala vecina debe quedar como visitada")
	var neighbour = scene.rooms.get(next_cell)
	_check(is_instance_valid(neighbour) and neighbour.is_active, "al entrar, la vecina debe despertar")
	_check(int(state.rooms_visited) == 2, "el HUD debe contar las salas visitadas")

	# 6. Volver: la sala conserva su estado y los enemigos no reaparecen.
	neighbour.emit_signal("door_entered", String(scene.OPPOSITE.get(direction, "left")))
	for i in 3:
		await process_frame
	await process_frame
	_check(scene.current_cell == combat.grid_cell, "se puede volver a la sala anterior")
	_check(combat.is_cleared, "la sala debe seguir despejada al volver")
	var alive := 0
	for enemy in combat.spawned:
		if is_instance_valid(enemy):
			alive += 1
	_check(alive == 0, "los enemigos muertos no deben reaparecer")

	# 7. Las salas no regalan objetos: solo hilos en el suelo.
	_check((neighbour.room_data.get("offers", []) as Array).is_empty(), "las salas ya no ofrecen objetos gratis")
	var pickups: Array = []
	for child in neighbour.get_children():
		if child.is_in_group("pickup"):
			pickups.append(child)
	_check(not pickups.is_empty(), "la sala debe dejar hilos en el suelo")
	if not pickups.is_empty() and player:
		var threads_before: int = state.threads
		player.global_position = (pickups[0] as Node2D).global_position
		for i in 4:
			await physics_frame
		_check(int(state.threads) > threads_before, "la jugadora debe recoger el hilo del suelo")

	# 8. Escudo: frontal reduce el daño y trasero lo rompe.
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
		print("H1_OK: mapa, puertas, estado de salas y escudo")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
