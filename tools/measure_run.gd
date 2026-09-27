# Arnés de medición del vertical slice (doc 07 §5, bitácora H3).
#
# No es un test de pass/fail: es un generador de informes. Sirve para decidir el
# balance del mapa (D-006) con números, sin meter a una persona a jugar 200
# partidas.
#
#   godot --headless --script tools/measure_run.gd --path . -- --seeds 200
#   godot --headless --script tools/measure_run.gd --path . -- --seed 12345
#
# Cada medida imprime sus números y el sesgo que tiene. Lo que no debe hacer es
# decidir el balance por su cuenta: eso se discute después de leer el informe.
extends SceneTree

const DEFAULT_SEEDS := 40
# Botín de enemigo, replicado de base_enemy._drop(): un único randf por muerte.
# Por debajo de 0.15 suelta un hilo, entre 0.15 y 0.25 un alfiler, nada más allá.
const DROP_ANY := 0.25
const DROP_THREAD := 0.15
# El taller se paga con un alfiler si hay; si no, con hilos (D-005).
const REPAIR_HEART_THRESHOLD := 2.0

var _syn: Node = null
var _gen: Node = null
var _problems: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_syn = load("res://core/synergy_db.gd").new()
	_syn.reload()
	_gen = load("res://core/room_generator.gd").new()
	# En headless los autoloads no existen todavía: se inyecta la base de contenido.
	_gen.set_content_db(_syn)
	var args := _args()
	var seeds: int = int(args.get("seeds", DEFAULT_SEEDS))
	var single: int = int(args.get("seed", -1))
	if single >= 0:
		print("== Arnés de medición — generador v%d, partida %d ==\n" % [
			int(_gen.GENERATOR_VERSION), single
		])
	else:
		print("== Arnés de medición — generador v%d, %d semillas ==\n" % [
			int(_gen.GENERATOR_VERSION), seeds
		])
	_measure_map(seeds, single)
	if single < 0:
		_measure_economy(seeds)
	_report_problems()
	_syn.free()
	_gen.free()
	quit(1 if not _problems.is_empty() else 0)

# --- Medida 1: forma del mapa -------------------------------------------------

# Qué salas hay, cómo se reparten y cuánta carga de combate trae cada partida.
# Si el mapa no valida para alguna semilla, aquí se ve: es un fallo real.
func _measure_map(seeds: int, single: int) -> void:
	if single >= 0:
		_dump_run(single, _gen.generate_run(single))
		return
	var kinds := {}
	var workshop_distance := []
	var enemy_counts := []
	var floor_threads := []
	var budgets := []
	var hp_totals := []
	var boss_items := {}
	var grid: Vector2i = Vector2i(_gen.GRID_COLS, _gen.GRID_ROWS)
	var room_total := 0
	for i in seeds:
		var run: Dictionary = _gen.generate_run(i)
		for error in _gen.validate_run(run):
			_problems.append("semilla %d: %s" % [i, error])
		for room in run["rooms"]:
			var kind := String(room.get("kind", ""))
			kinds[kind] = int(kinds.get(kind, 0)) + 1
			if kind == "workshop":
				workshop_distance.append(_manhattan(room.get("grid", Vector2i.ZERO), _gen.START_CELL))
			elif kind == "boss":
				var drop := String(room.get("boss_drop", ""))
				boss_items[drop] = int(boss_items.get(drop, 0)) + 1
		enemy_counts.append(_count_enemies(run))
		floor_threads.append(_count_floor_threads(run))
		budgets.append(_total_budget(run))
		hp_totals.append(_total_enemy_hp(run))
		room_total = (run["rooms"] as Array).size()
	print("-- Forma del mapa --")
	print("  rejilla %dx%d, %d salas por partida" % [grid.x, grid.y, room_total])
	for kind in _sorted(kinds):
		print("  tipo %-10s %d en total, %.2f por partida" % [
			kind, int(kinds[kind]), float(kinds[kind]) / float(seeds)
		])
	print("  distancia del taller al inicio: %s" % _range_text(workshop_distance))
	print("  enemigos por partida: %s" % _range_text(enemy_counts))
	print("  hilos en el suelo por partida: %s" % _range_text(floor_threads))
	print("  presupuesto de dificultad por partida: %s" % _range_text(budgets))
	print("  vida enemiga total por partida: %s" % _range_text(hp_totals))
	print("  objeto del jefe: %s" % _counts_text(boss_items))

# Una partida entera, sala a sala: la vista de detalle para reproducir un caso.
func _dump_run(run_seed: int, run: Dictionary) -> void:
	var room_size: Vector2 = run.get("room_size", Vector2.ZERO)
	print("-- Partida %d — rejilla %s, salas %dx%d, versión %d --" % [
		run_seed, str(run.get("grid", Vector2i.ZERO)), int(room_size.x), int(room_size.y),
		int(run.get("version", 0))
	])
	for error in _gen.validate_run(run):
		_problems.append("semilla %d: %s" % [run_seed, error])
	print("  celda  tipo        hilos  puertas           enemigos")
	for room in run["rooms"]:
		var cell: Vector2i = room.get("grid", Vector2i.ZERO)
		var names: Array[String] = []
		for enemy_id in (room.get("enemies", []) as Array):
			names.append(String(enemy_id))
		var extra := ""
		if String(room.get("kind", "")) == "workshop":
			extra = "  ofertas %s" % str(room.get("shop_offers", []))
		elif String(room.get("kind", "")) == "boss":
			extra = "  suelta %s" % String(room.get("boss_drop", ""))
		print("  %-6s %-11s %5d  %-17s %s%s" % [
			"(%d,%d)" % [cell.x, cell.y], String(room.get("kind", "")),
			(room.get("loot", []) as Array).size(),
			",".join(PackedStringArray(room.get("doors", []))),
			",".join(PackedStringArray(names)), extra,
		])

# --- Medida 2: economía y botín -----------------------------------------------

# Cuántos hilos entra en una partida y qué se puede hacer con ellos. Cuenta el
# botín del suelo y el que soltarían los enemigos al limpiarlas todas, tal como
# lo decide base_enemy._drop() con su RNG por enemigo: así el total es exacto,
# no una estimación.
func _measure_economy(seeds: int) -> void:
	var floor_only := []
	var with_drops := []
	var pins := []
	var can_buy := []
	var affords_two := []
	var after_shop := []
	for i in seeds:
		var run: Dictionary = _gen.generate_run(i)
		var floor_threads := _count_floor_threads(run)
		var drops := _enemy_drops(run)
		var total_threads := floor_threads + int(drops["threads"])
		floor_only.append(floor_threads)
		with_drops.append(total_threads)
		pins.append(int(drops["pins"]))
		var buy := _best_purchase(total_threads, int(drops["pins"]))
		can_buy.append(int(buy["affordable_items"]))
		affords_two.append(1 if int(buy["affordable_items"]) >= 2 else 0)
		after_shop.append(int(buy["left"]))
	print("-- Economía y botín --")
	print("  (asume limpiar el mapa entero; en una partida real se muere antes)")
	print("  hilos solo del suelo: %s" % _range_text(floor_only))
	print("  hilos con el botín de los enemigos: %s" % _range_text(with_drops))
	print("  alfileres: %s" % _range_text(pins))
	print("  entrada al taller: %d hilos o 1 alfiler" % int(_syn.get_entry_cost()))
	print("  objetos comprables por partida: %s" % _range_text(can_buy))
	print("  partidas que pagan 2 objetos: %.0f%%" % _percent(affords_two, seeds))
	print("  hilos que quedan tras la compra: %s" % _range_text(after_shop))
	print("  leer: si 'objetos comprables' es 0 casi siempre, la tienda es decorativa;")
	print("  si nunca llega a 2, la segunda compra es inalcanzable por diseño.")
	_report_depth_curve(seeds)

# El total de la partida no es la cifra que decide si la tienda funciona: lo que
# importa es cuánto hay cuando la jugadora llega al taller. Se acumulan las salas
# por distancia a la entrada, que es el orden natural en que se explorers, y se
# dice cuántos hilos hay al llegar a cada profundidad.
func _report_depth_curve(seeds: int) -> void:
	var depth := int(_gen.GRID_COLS + _gen.GRID_ROWS - 2)
	var threads_at := []
	var workshop_at := []
	for d in depth + 1:
		threads_at.append([])
		workshop_at.append([])
	for i in seeds:
		var run: Dictionary = _gen.generate_run(i)
		var start: Vector2i = _gen.START_CELL
		var ordered: Array = (run["rooms"] as Array).duplicate()
		ordered.sort_custom(func(a, b): return _manhattan(
			a.get("grid", Vector2i.ZERO), start) < _manhattan(b.get("grid", Vector2i.ZERO), start))
		var threads := 0
		for d in ordered.size():
			var room: Dictionary = ordered[d]
			threads += _room_threads(room)
			if d <= depth:
				threads_at[d].append(threads)
				if String(room.get("kind", "")) == "workshop":
					workshop_at[d].append(threads)
	print("  -- al llegar a cada profundidad (0 = solo el inicio) --")
	for d in depth + 1:
		var line := "  %d salas: %s" % [d, _range_text(threads_at[d])]
		if not workshop_at[d].is_empty():
			line += "   (taller aquí en %.0f%% de las partidas)" % _share(workshop_at[d].size(), seeds)
		print(line)

# Hilos que deja una sala: los del suelo más los que sueltan sus enemigos.
func _room_threads(room: Dictionary) -> int:
	var total := 0
	for resource_id in (room.get("loot", []) as Array):
		if String(resource_id) == "thread":
			total += 1
	var room_seed := int(room.get("seed", 0))
	for i in (room.get("enemies", []) as Array).size():
		var rng := RandomNumberGenerator.new()
		rng.seed = room_seed + i * 7919
		if rng.randf() < DROP_THREAD:
			total += 1
	return total

# Cuántos objetos de la pool se pueden pagar con lo que entra en una partida.
# Se paga la entrada (con alfiler si hay) y luego lo más barato primero, que es
# lo que haría alguien que quiere llevarse algo. Los precios salen de
# content/items.json, no de aquí.
func _best_purchase(threads: int, pins: int) -> Dictionary:
	var left := threads
	var spent := 0
	if pins > 0:
		pins -= 1  # Un alfiler abre la entrada sin pagar (D-005).
	else:
		left -= int(_syn.get_entry_cost())
		spent = int(_syn.get_entry_cost())
	var prices: Array[int] = []
	for item_id in (_syn.get_shop_pool() as Array):
		prices.append(int(_syn.get_price(String(item_id))))
	prices.sort()
	var bought := 0
	for price in prices:
		if left < price:
			break
		left -= price
		spent += price
		bought += 1
	return {"affordable_items": bought, "spent": spent, "left": left}

# Botín exacto que soltarían los enemigos: mismas semillas y mismo orden de
# aparición que usa la sala, un randf por muerte.
func _enemy_drops(run: Dictionary) -> Dictionary:
	var threads := 0
	var pins := 0
	for room in (run.get("rooms", []) as Array):
		var room_seed := int(room.get("seed", 0))
		var enemies: Array = room.get("enemies", [])
		for i in enemies.size():
			# El jefe suelta su objeto garantizado y además pasa por esta ruleta.
			var rng := RandomNumberGenerator.new()
			rng.seed = room_seed + i * 7919
			var roll := rng.randf()
			if roll >= DROP_ANY:
				continue
			if roll < DROP_THREAD:
				threads += 1
			else:
				pins += 1
	return {"threads": threads, "pins": pins}

func _percent(flags: Array, total: int) -> float:
	var hits := 0
	for flag in flags:
		hits += int(flag)
	return 100.0 * float(hits) / float(maxi(1, total))

# Porcentaje que representa una cuenta sobre un total de partidas.
func _share(count: int, total: int) -> float:
	return 100.0 * float(count) / float(maxi(1, total))

# --- Utilidades ---------------------------------------------------------------

func _count_enemies(run: Dictionary) -> int:
	var total := 0
	for room in (run.get("rooms", []) as Array):
		total += (room.get("enemies", []) as Array).size()
	return total

func _count_floor_threads(run: Dictionary) -> int:
	var total := 0
	for room in (run.get("rooms", []) as Array):
		for resource_id in (room.get("loot", []) as Array):
			if String(resource_id) == "thread":
				total += 1
	return total

# enemy_budget() espera una sala, no el mapa entero: hay que sumar sala a sala.
func _total_budget(run: Dictionary) -> int:
	var total := 0
	for room in (run.get("rooms", []) as Array):
		total += int(_gen.enemy_budget(room))
	return total

# Vida real de todos los enemigos de la partida: es lo que decide cuánto tarda
# en limpiarse el mapa, más que el presupuesto de dificultad.
func _total_enemy_hp(run: Dictionary) -> int:
	var total := 0
	for room in (run.get("rooms", []) as Array):
		for enemy_id in (room.get("enemies", []) as Array):
			total += int(_syn.get_enemy(String(enemy_id)).get("hp", 0))
	return total

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

# "min-max (media con un decimal)": aquí se describe una distribución de partidas,
# no una precisión de laboratorio. El redondeo a un decimal es a propósito.
func _range_text(values: Array) -> String:
	if values.is_empty():
		return "sin datos"
	var min_v: int = values[0]
	var max_v: int = values[0]
	var total := 0.0
	for value in values:
		min_v = mini(min_v, int(value))
		max_v = maxi(max_v, int(value))
		total += float(value)
	return "%d-%d (media %.1f)" % [min_v, max_v, total / float(values.size())]

func _counts_text(counts: Dictionary) -> String:
	var parts: Array[String] = []
	for key in _sorted(counts):
		parts.append("%s %d" % [key, int(counts[key])])
	return ", ".join(PackedStringArray(parts))

func _sorted(source: Dictionary) -> Array:
	var keys: Array = source.keys()
	keys.sort()
	return keys

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

func _report_problems() -> void:
	if _problems.is_empty():
		return
	print("-- Problemas (%d) --" % _problems.size())
	for problem in _problems:
		print("  " + problem)
