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
