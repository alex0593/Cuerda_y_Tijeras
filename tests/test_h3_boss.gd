extends SceneTree

# H3: jefe Caja de Cero — dos fases con aviso visible y contraataque.
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
	state.start_run(777)

	var boss: Node = load("res://gameplay/enemies/boss_caja_cero.tscn").instantiate()
	root.add_child(boss)
	await process_frame
	boss.set_physics_process(false)  # el test conduce _tick a mano
	_check(int(boss.max_hp) == 120, "el jefe debe tener 120 de vida")
	_check(boss.hp == boss.max_hp, "el jefe debe empezar con la vida llena")
	_check(boss.phase == 1, "el jefe debe empezar en fase 1")

	# Regresión: los disparos enemigos deben poder herir a la jugadora. Antes de
	# corregirse quedaban con las capas del jugador y no llegaban a dañarla.
	var shot: Node = load("res://gameplay/projectiles/cut.tscn").instantiate()
	shot.setup(Vector2.RIGHT, 200.0, 0.5, "enemy")
	_check(int(shot.collision_layer) == 8, "el disparo enemigo debe ir en la capa de proyectil enemigo")
	_check(int(shot.collision_mask) == 1, "el disparo enemigo debe buscar la capa de la jugadora")
	_check(shot.is_in_group("projectile_enemy"), "el disparo enemigo debe estar en su propio grupo")
	_check(not shot.is_in_group("projectile_player"), "el disparo enemigo no puede quedar en el grupo de la jugadora")
	shot.setup(Vector2.RIGHT, 420.0, 10.0, "player")
	_check(int(shot.collision_mask) == 34, "el disparo de la jugadora debe buscar enemigos y muros")
	_check(shot.is_in_group("projectile_player"), "el disparo de la jugadora debe quedar en su grupo")
	shot.queue_free()

	# Fase 1: la ráfaga avisa antes de salir.
	boss._timer = 0.0
	boss._tick(0.016)
	_check(boss._telegraph > 0.0, "la ráfaga debe avisarse antes de salir")
	var fan_only := _enemy_projectiles()
	boss._telegraph = 0.01
	boss._tick(0.02)
	_check(_enemy_projectiles() > fan_only, "la fase 1 debe lanzar un abanico")

	# Fase 2: al bajar del 50 % se abre y ataca más rápido.
	boss.hp = boss.max_hp * 0.4
	boss._tick(0.016)
	_check(boss.phase == 2, "bajo el 50 % debe pasar a fase 2")
	boss._timer = 0.0
	boss._tick(0.016)
	_check(boss._telegraph > 0.0, "la fase 2 también debe avisar antes de disparar")
	var before_phase2 := _enemy_projectiles()
	boss._telegraph = 0.01
	boss._tick(0.02)
	# 5 del abanico + 3 de la lluvia de hilos.
	_check(_enemy_projectiles() - before_phase2 == 8, "la fase 2 debe lanzar abanico e hilos")

	# Contraataque: interrumpir el aviso cancela la ráfaga y hace daño extra.
	boss._timer = 0.0
	boss._tick(0.016)
	_check(boss._telegraph > 0.0, "debe estar avisando de nuevo")
	var hp_before: float = boss.hp
	boss.take_hit(10.0, "cut", boss.global_position)
	_check(boss._telegraph <= 0.0, "interrumpir el aviso debe cancelar la ráfaga")
	_check(is_equal_approx(boss.hp, hp_before - 15.0), "el contraataque debe hacer daño extra")
	var cancelled := _enemy_projectiles()
	boss._tick(0.02)
	boss._tick(0.02)
	_check(_enemy_projectiles() == cancelled, "una ráfaga cancelada no debe disparar")

	# Sin aviso no hay contraataque: el daño es el normal.
	boss._timer = 0.0
	boss._tick(0.016)
	boss._telegraph = 0.01
	boss._tick(0.02)  # dispara la ráfaga
	hp_before = boss.hp
	boss.take_hit(10.0, "cut", boss.global_position)
	_check(is_equal_approx(boss.hp, hp_before - 10.0), "sin aviso el daño debe ser el normal")

	# Al morir suelta el objeto garantizado de la sala.
	boss.set("guaranteed_drop", "item:spring_jumper")
	boss.set("win_on_pickup", true)
	boss.take_hit(9999.0, "cut", boss.global_position)
	for i in 3:
		await process_frame
	_check(not is_instance_valid(boss), "el jefe debe morir")
	_check(state.kills == 1, "la baja del jefe debe contar")
	var dropped: Node = null
	for pk in get_nodes_in_group("pickup"):
		if String(pk.get("kind")) == "item:spring_jumper":
			dropped = pk
	_check(dropped != null, "el jefe debe soltar el objeto garantizado de la semilla")

	# Recoger ese objeto cierra la partida: es la victoria del vertical slice.
	var victory := {"won": false}
	state.run_ended.connect(func(v: bool) -> void: victory["won"] = v, CONNECT_ONE_SHOT)
	var player: Node = load("res://gameplay/player/lela.tscn").instantiate()
	root.add_child(player)
	await process_frame
	if dropped != null:
		player.global_position = dropped.global_position
		for i in 5:
			await physics_frame
	_check(bool(victory["won"]), "recoger el botín del jefe debe cerrar la partida con victoria")
	_check(not bool(state.is_running), "tras la victoria la partida termina")
	if is_instance_valid(player):
		player.free()

	state.end_run(false)
	if failures.is_empty():
		print("H3_BOSS_OK: dos fases, aviso visible y contraataque")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _enemy_projectiles() -> int:
	return get_nodes_in_group("projectile_enemy").size()
