# Bot que juega una partida de verdad en headless (doc 07 §5, bitácora H3).
#
# Mide lo que el arnés de números no puede: si el mapa se puede terminar, cuánto
# tarda y en qué sala se cae. Usa la escena real (game.tscn) y el código real de
# la jugadora: no simula nada, pulsa las mismas acciones que un dedo.
#
#   godot --headless --script tools/measure_play.gd --path . -- --runs 10
#
# SESGO, y hay que leerlo antes que los números: el bot no esquiva, no usa el
# rebobinado para salvar una situación y no elige rutas. Es un jugador
# competente, no uno bueno. Si sobrevive, el juego es más fácil de lo que
# parece; si muere, no demuestra que sea demasiado difícil. Por eso los números
# van juntos con la partida que juega una persona, nunca solos.
extends SceneTree

# Tope por partida: el objetivo del slice son 5-10 min, así que a los 8 minutos
# una partida que sigue viva ya es un dato, no un bug.
const MAX_SECONDS := 480.0
const DEFAULT_RUNS := 8
const STEP := 1.0 / 60.0
# Radio de alarma: por debajo, el bot hace dash para_no salirse de un golpe.
const PANIC_DISTANCE := 60.0
# Distancia a la que considera que la sala está limpia y toca cambiar de sala.
const ROOM_CLEAR_RADIUS := 0.0

const MOVES := ["move_left", "move_right", "move_up", "move_down"]

var _state: Node = null
var _db: Node = null
var _save: Node = null
var _results: Array = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_state = root.get_node_or_null("GameState")
	_db = root.get_node_or_null("SynergyDB")
	_save = root.get_node_or_null("SaveService")
	if _state == null or _db == null or _save == null:
		push_error("el bot necesita los autoloads: GameState, SynergyDB y SaveService")
		quit(1)
		return
	var args := _args()
	var runs: int = int(args.get("runs", DEFAULT_RUNS))
	var limit := float(args.get("max", MAX_SECONDS))
	print("== Bot — %d partidas, tope de %.0f s por partida ==\n" % [runs, limit])
	# Apuntar automáticamente es una opción real del juego (doc 08 §11): el bot la
	# usa para disparar de verdad al enemigo más cercano, ya que no sabe
	# manejar el ratón ni un joystick de puntería.
	_save.settings["auto_fire"] = true
	for i in runs:
		var result: Dictionary = await _play_one(i, limit)
		_results.append(result)
		_print_result(i, result)
	_report()
	quit(0)

# --- Una partida -------------------------------------------------------------

func _play_one(run_index: int, limit: float) -> Dictionary:
	_release_all()
	var run_seed := 7919 * (run_index + 1)
	var victory := {"won": false}
	var scene = load("res://gameplay/main/game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	# La escena arranca con una semilla aleatoria; se reinicia con la suya para
	# que la partida sea reproducible.
	scene.call("_start_new_run", run_seed)
	await process_frame
	await physics_frame
	_state.run_ended.connect(func(won: bool) -> void: victory["won"] = won, CONNECT_ONE_SHOT)
	var player: Node2D = scene.get("player")
	var elapsed := 0.0
	var stuck_at := ""
	var last_cell: Vector2i = scene.get("current_cell")
	var same_cell_frames := 0
	while bool(_state.is_running) and elapsed < limit:
		await physics_frame
		elapsed += STEP
		if player == null or not is_instance_valid(player):
			player = get_first_node_in_group("player") as Node2D
			continue
		_drive(scene, player)
		# Si la jugadora lleva mucho rato en la misma sala, algo la ha parado:
		# una puerta cerrada que no se abre o un enemigo al que no se llega.
		var cell: Vector2i = scene.get("current_cell")
		if cell == last_cell:
			same_cell_frames += 1
			if same_cell_frames == 60 * 12:
				stuck_at = "atascada en la sala %s (%s)" % [cell, _room_kind(scene, cell)]
		else:
			same_cell_frames = 0
			stuck_at = ""
		last_cell = cell
	_release_all()
	var result := {
		"seed": run_seed,
		"time": elapsed,
		"won": bool(victory["won"]),
		"timeout": bool(_state.is_running),
		"rooms": int(_state.rooms_visited),
		"threads": int(_state.threads),
		"items": (_state.items as Array).size(),
		"cause": String(_state.cause_of_death),
		"stuck": stuck_at,
	}
	# El resumen congela el árbol: hay que soltarlo antes de la siguiente partida.
	paused = false
	_state.set("is_running", false)
	if is_instance_valid(scene):
		scene.free()
	for i in 4:
		await process_frame
		await physics_frame
	return result

# --- Conducción ---------------------------------------------------------------

# El bot no ejecuta llamadas internas de la jugadora: pulsa las mismas acciones
# que un dedo, así que todo el código de Dash, tensión y disparo se ejercita
# igual que en una partida real.
func _drive(scene: Node, player: Node2D) -> void:
	var room = _current_room(scene)
	var enemies := _living_enemies(room)
	if not enemies.is_empty():
		_fight(player, enemies)
		return
	# Sala limpia:-heading hacia la puerta que lleva a la siguiente sala.
	var target := _next_cell(scene)
	if target == Vector2i(-99, -99):
		_release_all()
		return
	var goal := _door_point(room, target)
	_hold(player.global_position.direction_to(goal))

# Pelea: mantener media distancia, disparar al más cercano y hacer dash si se
# acerca demasiado. No esquiva proyectiles ni busca cobertura: eso es lo que
# hace que este bot pierda más partidas que una persona.
func _fight(player: Node2D, enemies: Array) -> void:
	var closest: Node2D = enemies[0]
	var best := INF
	for enemy in enemies:
		var d: float = player.global_position.distance_to((enemy as Node2D).global_position)
		if d < best:
			best = d
			closest = enemy as Node2D
	var away := player.global_position.direction_to(closest.global_position).rotated(PI)
	if best < PANIC_DISTANCE:
			# Demasiado cerca: dash para atrás. Un solo frame, como un toque.
		_tap("dash")
		_hold(away)
	elif best < 190.0:
		# Distancia media: retirarse en perpendicular para no ser un blanco fijo.
		_hold(Vector2(-away.y, away.x))
	else:
		_hold(away)

# A qué sala conviene ir ahora. Prioridades, en orden:
#   1. el jefe, si ya está todo lo demás despejado;
#   2. el taller, si no se ha abierto y queda a un paso o menos;
#   3. la sala sin limpiar más cercana.
func _next_cell(scene: Node) -> Vector2i:
	var here: Vector2i = scene.get("current_cell")
	var rooms: Dictionary = scene.get("rooms")
	var boss := Vector2i(-1, -1)
	var workshop := Vector2i(-1, -1)
	var pending: Array[Vector2i] = []
	for cell in rooms:
		var room = rooms[cell]
		if String(room.get("kind")) == "boss":
			boss = cell
		elif String(room.get("kind")) == "workshop" and not _shop_visited(scene, cell):
			workshop = cell
		elif not room.is_cleared and cell != here:
			pending.append(cell)
	if pending.is_empty():
		return boss if boss != here else Vector2i(-99, -99)
	if workshop != Vector2i(-1, -1) and _manhattan(workshop, here) <= 1:
		return workshop
	pending.sort_custom(func(a, b): return _manhattan(a, here) < _manhattan(b, here))
	return pending[0]

func _shop_visited(scene: Node, cell: Vector2i) -> bool:
	var room = (scene.get("rooms") as Dictionary).get(cell)
	return room != null and bool(room.get("is_active"))

# Punto del interior de la sala por el que se sale hacia la vecina.
func _door_point(room: Node, target: Vector2i) -> Vector2:
	var here: Vector2i = room.get("grid_cell")
	var step: Vector2i = target - here
	if step == Vector2i(0, 0):
		return (room as Node2D).global_position + Vector2(480, 270)
	var centre := Vector2(480, 270)
	if step.x != 0:
		centre.x = 960.0 if step.x > 0 else 0.0
	if step.y != 0:
		centre.y = 540.0 if step.y > 0 else 0.0
	return (room as Node2D).global_position + centre

# --- Entrada simulada --------------------------------------------------------

func _hold(direction: Vector2) -> void:
	for move in MOVES:
		Input.action_release(move)
	if direction.length() < 0.2:
		return
	# Un joystick digital: si un eje manda, el otro se anula.
	var wanted: Array[String] = []
	if absf(direction.x) > 0.38:
		wanted.append("right" if direction.x > 0.0 else "left")
	if absf(direction.y) > 0.38:
		wanted.append("up" if direction.y > 0.0 else "down")
	for token in wanted:
		Input.action_press("move_" + token)

# Un toque: se pulsa la acción y se suelta al siguiente paso, como un dedo.
func _tap(action: String) -> void:
	Input.action_press(action)
	Input.action_release(action)

func _release_all() -> void:
	for move in MOVES:
		Input.action_release(move)
	Input.action_release("dash")
	Input.action_release("fire")

# --- Utilidades ---------------------------------------------------------------

func _current_room(scene: Node) -> Node:
	var cell: Vector2i = scene.get("current_cell")
	return (scene.get("rooms") as Dictionary).get(cell)

func _room_kind(scene: Node, cell: Vector2i) -> String:
	var room = (scene.get("rooms") as Dictionary).get(cell)
	return String(room.get("kind")) if room != null else "?"

# Solo los enemigos de la sala en la que está la jugadora: los de las salas
# dormidas no existen todavía, y los de las ya despejadas, no.
func _living_enemies(room: Node) -> Array:
	var out: Array = []
	if room == null or not room.get("is_active"):
		return out
	for enemy in (room.get("spawned") as Array):
		if is_instance_valid(enemy) and float(enemy.get("hp")) > 0.0:
			out.append(enemy)
	return out

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func _print_result(index: int, result: Dictionary) -> void:
	var outcome := "victoria" if bool(result["won"]) else ("sin terminar" if bool(result["timeout"]) else "derrota")
	print("  partida %d (semilla %d): %s en %d:%02d, %d salas, %d hilos, %d objetos%s%s" % [
		index, int(result["seed"]), outcome, int(result["time"]) / 60, int(result["time"]) % 60,
		int(result["rooms"]), int(result["threads"]), int(result["items"]),
		"" if String(result["cause"]) == "" else ", muerta por %s" % String(result["cause"]),
		"" if String(result["stuck"]) == "" else " — %s" % String(result["stuck"]),
	])

func _report() -> void:
	if _results.is_empty():
		return
	var wins := 0
	var timeouts := 0
	var times := []
	var rooms := []
	var stopped := {}
	for result in _results:
		if bool(result["won"]):
			wins += 1
		if bool(result["timeout"]):
			timeouts += 1
		times.append(int(result["time"]))
		rooms.append(int(result["rooms"]))
		if not bool(result["won"]) and String(result["cause"]) != "":
			stopped[String(result["cause"])] = int(stopped.get(String(result["cause"]), 0)) + 1
	print("\n-- Resumen del bot --")
	print("  victorias: %d de %d" % [wins, _results.size()])
	print("  sin terminar en el tope: %d" % timeouts)
	print("  duración: %d-%d s (media %.0f)" % [_min(times), _max(times), _mean(times)])
	print("  salas visitadas: %d-%d (media %.0f)" % [_min(rooms), _max(rooms), _mean(rooms)])
	if not stopped.is_empty():
		var parts: Array[String] = []
		var keys: Array = stopped.keys()
		keys.sort()
		for key in keys:
			parts.append("%s %d" % [key, int(stopped[key])])
		print("  contraria: %s" % ", ".join(PackedStringArray(parts)))
	print("  recuerda: el bot no esquiva. Sus números son un piso, no una media.")

func _min(values: Array) -> int:
	var out: int = int(values[0])
	for value in values:
		out = mini(out, int(value))
	return out

func _max(values: Array) -> int:
	var out: int = int(values[0])
	for value in values:
		out = maxi(out, int(value))
	return out

func _mean(values: Array) -> float:
	var total := 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())

func _args() -> Dictionary:
	var out := {}
	var argv := OS.get_cmdline_user_args()
	var i := 0
	while i < argv.size():
		var token := String(argv[i])
		if token.begins_with("--"):
			var key := token.trim_prefix("--")
			if i + 1 < argv.size() and not String(argv[i + 1]).begins_with("--"):
				out[key] = argv[i + 1]
				i += 2
			else:
				out[key] = true
				i += 1
		else:
			i += 1
	return out
