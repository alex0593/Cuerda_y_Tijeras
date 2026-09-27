# RoomGenerator — generación con semilla (doc 07).
# Mapa del vertical slice: rejilla 3x3 de salas unidas por puertas.
# La jugadora camina por el mapa, vuelve a las salas que yalimpió y todas
# conservan su estado.
extends Node

const GENERATOR_VERSION := 7

# Rejilla de salas. El inicio y el jefe van en esquinas opuestas para que
# cruzar el mapa sea la decisión de ritmo de la partida.
const GRID_COLS := 3
const GRID_ROWS := 3
# La sala tiene que ser MÁS grande que el viewport en los dos ejes, o la cámara
# no tiene margen y empuja a la jugadora al borde de la pantalla en cuanto se
# acerca a un muro. Con stretch=expand, un móvil panorámico (2412x1080) deja el
# viewport en 960x430, así que 960x540 no daba ningún margen (doc 07 §5.1).
const ROOM_SIZE := Vector2(1280, 720)
const START_CELL := Vector2i(0, 0)
const BOSS_CELL := Vector2i(GRID_COLS - 1, GRID_ROWS - 1)
# Reparto de las salas libres: 3 combates, 1 tesoro y 2 riesgos.
const MAP_KINDS := ["combat", "treasure", "risk", "combat", "risk", "combat"]
const DOOR_DIRECTIONS := ["left", "right", "up", "down"]
# El arma inicial nunca se reparte: solo se conserva o se sustituye.
const NON_REWARD_ITEMS := ["scissors_basic"]
# Pesos por rareza, para que lo raro sea raro sin desaparecer del vertical slice.
const RARITY_WEIGHTS := {"común": 60, "especial": 30, "rara": 10}
const DEFAULT_RARITY_WEIGHT := 10

func generate_run(p_seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	var plan := _plan_rooms(rng)
	var rooms: Array = []
	for row in GRID_ROWS:
		for col in GRID_COLS:
			var cell := Vector2i(col, row)
			rooms.append(_make_room(rng, cell, String(plan[cell])))
	return {
		"seed": p_seed,
		"version": GENERATOR_VERSION,
		"grid": Vector2i(GRID_COLS, GRID_ROWS),
		"room_size": ROOM_SIZE,
		"rooms": rooms,
	}

# Decide qué tipo de sala va en cada celda: inicio y jefe fijos, el taller lejos
# de la entrada y las demás repartidas y barajadas con la semilla.
func _plan_rooms(rng: RandomNumberGenerator) -> Dictionary:
	var plan := {}
	plan[START_CELL] = "start"
	plan[BOSS_CELL] = "boss"
	var free: Array[Vector2i] = []
	for row in GRID_ROWS:
		for col in GRID_COLS:
			var cell := Vector2i(col, row)
			if cell != START_CELL and cell != BOSS_CELL:
				free.append(cell)
	free = _shuffled(rng, free)
	var far: Array[Vector2i] = []
	for cell in free:
		if _manhattan(cell, START_CELL) >= 2:
			far.append(cell)
	if far.is_empty():
		far = free
	plan[far[0]] = "workshop"
	var kinds: Array = _shuffled(rng, MAP_KINDS.duplicate())
	var next := 0
	for cell in free:
		if plan.has(cell):
			continue
		plan[cell] = kinds[next % kinds.size()]
		next += 1
	return plan

func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

# Baraja con el generador de la semilla: Array.shuffle() usa el aleatorio
# global y rompería el determinismo del mapa.
func _shuffled(rng: RandomNumberGenerator, source: Array) -> Array:
	var out: Array = source.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out

func _make_room(rng: RandomNumberGenerator, cell: Vector2i, kind: String) -> Dictionary:
	var room := {
		"index": _index_of(cell),
		"grid": cell,
		"position": Vector2(cell.x * ROOM_SIZE.x, cell.y * ROOM_SIZE.y),
		"kind": kind,
		"seed": rng.randi(),
		"enemies": [],
		"template": "open",
		"doors": _doors_for(cell),
		"entry_safe": kind == "start",
	}
	match kind:
		"start":
			room["template"] = "safe_entry"
		"combat":
			room["template"] = "open" if rng.randf() < 0.5 else "cross"
			room["enemies"] = _pick_enemies(rng, 2)
		"treasure":
			room["template"] = "open"
		"risk":
			room["template"] = "pillar"
			room["enemies"] = _pick_enemies(rng, 3)
		"workshop":
			room["template"] = "open"
		"boss":
			room["template"] = "boss_arena"
			room["enemies"] = ["caja_cero"]
	# Botín de hilos en el suelo: la moneda de la partida (content/economy.json).
	room["loot"] = _roll_loot(rng, kind)
	# La tienda del taller sortea su pool con la semilla.
	room["shop_offers"] = _pick_shop_offers(rng) if kind == "workshop" else []
	# El jefe siempre suelta un objeto del catálogo (decisión 2026-09-25).
	room["boss_drop"] = _pick_boss_drop(rng) if kind == "boss" else ""
	return room

func _index_of(cell: Vector2i) -> int:
	return cell.y * GRID_COLS + cell.x

func _doors_for(cell: Vector2i) -> Array:
	var out: Array = []
	if cell.x > 0:
		out.append("left")
	if cell.x < GRID_COLS - 1:
		out.append("right")
	if cell.y > 0:
		out.append("up")
	if cell.y < GRID_ROWS - 1:
		out.append("down")
	return out

# Hilos que la sala deja en el suelo; el rango vive en content/economy.json.
func _roll_loot(rng: RandomNumberGenerator, kind: String) -> Array:
	var limits := _loot_range(kind)
	if int(limits[0]) < 0:
		return []  # validate_room lo denuncia
	var loot: Array = []
	for i in rng.randi_range(int(limits[0]), int(limits[1])):
		loot.append("thread")
	return loot

# El jefe suelta un objeto del catálogo que no sea de la pool del taller:
# lo especial se compra en la tienda y lo común lo regala el jefe (doc 07 §13).
func _pick_boss_drop(rng: RandomNumberGenerator) -> String:
	var drops := _draw_weighted(rng, _boss_reward_pool(), 1)
	return String(drops[0]) if not drops.is_empty() else ""

# Lo que el jefe puede soltar: objetos del catálogo que no se conservan ni se
# compran en el taller. Un consumible no vale como recompensa final —la bobina
# de reparación se compra en el taller— y menos como objeto que cierra la
# partida: ganar no puede consistir en recoger una bobina de reparación.
func _boss_reward_pool() -> Array:
	var pool: Array = []
	for item_id in _item_ids():
		var id := String(item_id)
		if id in NON_REWARD_ITEMS or id in _shop_pool():
			continue
		if String(_item(id).get("slot", "")) == "consumable":
			continue
		pool.append(id)
	return pool

func _is_consumable(item_id: String) -> bool:
	return String(_item(item_id).get("slot", "")) == "consumable"

# Ofertas de la compra: se dibujan de la pool exclusiva de content/economy.json.
func _pick_shop_offers(rng: RandomNumberGenerator) -> Array:
	return _draw_weighted(rng, _shop_pool(), _shop_offer_count())

func _draw_weighted(rng: RandomNumberGenerator, source: Array, count: int) -> Array:
	var pool: Array = []
	for item_id in source:
		pool.append(String(item_id))
	var offers: Array = []
	while offers.size() < count and not pool.is_empty():
		var weights: Array = []
		var total := 0
		for item_id in pool:
			var weight := int(RARITY_WEIGHTS.get(String(_item(item_id).get("rarity", "")), DEFAULT_RARITY_WEIGHT))
			weights.append(weight)
			total += weight
		var roll := rng.randi_range(1, maxi(1, total))
		var accumulated := 0
		var chosen_index := pool.size() - 1
		for i in weights.size():
			accumulated += int(weights[i])
			if roll <= accumulated:
				chosen_index = i
				break
		offers.append(String(pool[chosen_index]))
		pool.remove_at(chosen_index)
	return offers

func _pick_enemies(rng: RandomNumberGenerator, budget: int) -> Array:
	var pool := ["tin_soldier", "tin_soldier", "music_box"]
	var out: Array = []
	var spent := 0
	var guard := 0
	while spent < budget and guard < 10:
		guard += 1
		var e: String = pool[rng.randi_range(0, pool.size() - 1)]
		var cost: int = _enemy_cost(e)
		if spent + cost <= budget:
			out.append(e)
			spent += cost
	if out.is_empty():
		out.append("tin_soldier")
	return out

# El generador lee el contenido del autoload SynergyDB, pero las herramientas
# headless (--script) se ejecutan antes de que existan los autoloads, así que
# permiten inyectar la base de contenido explícitamente.
var _injected_db: Node = null

func set_content_db(db: Node) -> void:
	_injected_db = db

func _content_db() -> Node:
	if is_instance_valid(_injected_db):
		return _injected_db
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var root := (loop as SceneTree).root
		if root:
			return root.get_node_or_null("SynergyDB")
	return null

func _enemy_cost(enemy_id: String) -> int:
	var db := _content_db()
	return db.get_enemy_cost(enemy_id) if db else 1

func _item_ids() -> Array:
	var db := _content_db()
	return db.items_data.keys() if db else []

func _item(item_id: String) -> Dictionary:
	var db := _content_db()
	return db.get_item(item_id) if db else {}

func _loot_range(kind: String) -> Array:
	var db := _content_db()
	return db.get_loot_range(kind) if db else [-1, -1]

# Pool exclusiva del taller y cuántas de sus ofertas se sortean por partida.
func _shop_pool() -> Array:
	var db := _content_db()
	return db.get_shop_pool() if db else []

func _shop_offer_count() -> int:
	var db := _content_db()
	return db.get_shop_offers() if db else 0

func enemy_budget(room: Dictionary) -> int:
	var total := 0
	for enemy_id in (room.get("enemies", []) as Array):
		total += _enemy_cost(String(enemy_id))
	return total

# Ofertas de la tienda para esta partida: fuera las que ya lleva la jugadora.
# Se reponen desde la pool con la semilla de la sala, así que el sorteo no
# cambia y siempre hay opciones nuevas que coger (doc 07 §13).
func shop_offers_for(room: Dictionary, owned: Array) -> Array:
	var wanted := _shop_offer_count()
	var out: Array = []
	for item_id in (room.get("shop_offers", []) as Array):
		var id := String(item_id)
		if not (id in owned) and not (id in out):
			out.append(id)
	var pool: Array = []
	for item_id in _shop_pool():
		var id := String(item_id)
		if not (id in owned) and not (id in out):
			pool.append(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(room.get("seed", 0))
	while out.size() < wanted and not pool.is_empty():
		var pick := _draw_weighted(rng, pool, 1)
		if pick.is_empty():
			break
		out.append(String(pick[0]))
		pool.erase(String(pick[0]))
	return out

# Botín del jefe para esta partida: nunca un objeto que ya lleves.
func boss_drop_for(room: Dictionary, owned: Array) -> String:
	var drop := String(room.get("boss_drop", ""))
	if drop != "" and not (drop in owned) and not _is_consumable(drop):
		return drop
	var pool: Array = []
	for item_id in _boss_reward_pool():
		if not (String(item_id) in owned):
			pool.append(String(item_id))
	if pool.is_empty():
		return ""
	var rng := RandomNumberGenerator.new()
	rng.seed = int(room.get("seed", 0)) + 7919
	var pick := _draw_weighted(rng, pool, 1)
	return String(pick[0]) if not pick.is_empty() else ""

func validate_room(room: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var cell: Vector2i = room.get("grid", Vector2i(-1, -1))
	var kind := String(room.get("kind", ""))
	if not room.has("kind") or not room.has("enemies") or not room.has("template"):
		errors.append("room missing kind/template/enemies")
	if not room.has("seed"):
		errors.append("room missing seed")
	if cell.x < 0 or cell.x >= GRID_COLS or cell.y < 0 or cell.y >= GRID_ROWS:
		errors.append("sala fuera de la rejilla: %s" % cell)
	# La posición en el mundo es la celda por el tamaño de sala.
	var expected := Vector2(cell.x * ROOM_SIZE.x, cell.y * ROOM_SIZE.y)
	if Vector2(room.get("position", Vector2(-1, -1))) != expected:
		errors.append("la posición de la sala %s no cuadra con la rejilla" % cell)
	# Regla doc 07: la entrada es segura, sin proyectil inicial sin aviso.
	if kind == "start" and not (room.get("enemies", []) as Array).is_empty():
		errors.append("start room must have no enemies")
	if kind == "combat" and enemy_budget(room) > 2:
		errors.append("combat room exceeds difficulty budget")
	if kind == "risk" and enemy_budget(room) > 3:
		errors.append("risk room exceeds difficulty budget")
	# Las puertas tienen que ser exactamente las vecinas de la celda.
	var doors: Array = room.get("doors", [])
	if doors.size() != _unique_count(doors):
		errors.append("sala %s repite puerta" % cell)
	for direction in _doors_for(cell):
		if not (direction in doors):
			errors.append("sala %s pierde la puerta %s" % [cell, direction])
	for direction in doors:
		if not (String(direction) in _doors_for(cell)):
			errors.append("sala %s tiene la puerta %s sin vecino" % [cell, direction])
	# Ninguna sala regala objetos: solo el jefe y la tienda del taller los sueltan.
	if not (room.get("offers", []) as Array).is_empty():
		errors.append("sala %s no debe ofrecer objetos gratis" % cell)
	# Botín de hilos: cantidad dentro del rango de content/economy.json.
	var limits := _loot_range(kind)
	if int(limits[0]) < 0:
		errors.append("economy.json no define loot para %s" % kind)
	else:
		var loot: Array = room.get("loot", [])
		if loot.size() < int(limits[0]) or loot.size() > int(limits[1]):
			errors.append("sala %s debe soltar entre %d y %d hilos" % [cell, int(limits[0]), int(limits[1])])
		for resource_id in loot:
			if not (String(resource_id) in ["thread", "key"]):
				errors.append("sala %s suelta recurso desconocido %s" % [cell, resource_id])
	# El jefe suelta siempre un objeto alcanzable y distinto del arma inicial.
	var boss_drop := String(room.get("boss_drop", ""))
	if kind == "boss":
		if boss_drop == "" or _item(boss_drop).is_empty() or boss_drop in NON_REWARD_ITEMS or boss_drop in _shop_pool():
			errors.append("boss_drop debe ser un objeto alcanzable distinto del inicial")
		elif _is_consumable(boss_drop):
			# Ganar no puede consistir en recoger una bobina de reparación: el
			# consumible se compra en el taller y no ocupa un hueco de los tres.
			errors.append("boss_drop no puede ser un consumible: %s" % boss_drop)
	elif boss_drop != "":
		errors.append("solo la sala de jefe define boss_drop")
	# El taller vende su propia pool: ofertas únicas, con precio y alcanzables.
	var shop_offers: Array = room.get("shop_offers", [])
	var wanted := _shop_offer_count()
	var db := _content_db()
	if kind == "workshop":
		if shop_offers.size() != wanted:
			errors.append("el taller debe componer %d ofertas de su pool" % wanted)
	elif not shop_offers.is_empty():
		errors.append("solo la sala de taller define shop_offers")
	if shop_offers.size() != _unique_count(shop_offers):
		errors.append("el taller repite ofertas")
	for item_id in shop_offers:
		var offer := String(item_id)
		if not (offer in _shop_pool()):
			errors.append("el taller vende %s fuera de su pool" % offer)
		elif _item(offer).is_empty():
			errors.append("el taller vende objeto desconocido %s" % offer)
		elif db != null and int(db.get_price(offer)) <= 0:
			errors.append("el taller vende %s sin precio" % offer)
	return errors

# El mapa entero debe ser coherente: cobertura de la rejilla, esquinas fijas y
# puertas simétricas, para que nunca se pueda entrar en una sala imposible.
func validate_run(run: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var rooms: Array = run.get("rooms", [])
	if Vector2i(run.get("grid", Vector2i.ZERO)) != Vector2i(GRID_COLS, GRID_ROWS):
		errors.append("la rejilla debe ser %dx%d" % [GRID_COLS, GRID_ROWS])
	if rooms.size() != GRID_COLS * GRID_ROWS:
		errors.append("el mapa debe tener %d salas" % (GRID_COLS * GRID_ROWS))
	var seen := {}
	var starts := 0
	var bosses := 0
	var workshops := 0
	for room in rooms:
		var cell: Vector2i = room.get("grid", Vector2i(-1, -1))
		seen[cell] = true
		var kind := String(room.get("kind", ""))
		if kind == "start":
			starts += 1
			if cell != START_CELL:
				errors.append("la sala de inicio debe estar en la esquina")
		elif kind == "boss":
			bosses += 1
			if cell != BOSS_CELL:
				errors.append("el jefe debe estar en la esquina opuesta")
		elif kind == "workshop":
			workshops += 1
			if _manhattan(cell, START_CELL) < 2:
				errors.append("el taller debe estar a dos pasos o más de la entrada")
	for row in GRID_ROWS:
		for col in GRID_COLS:
			if not seen.has(Vector2i(col, row)):
				errors.append("falta la sala %s" % Vector2i(col, row))
	if starts != 1 or bosses != 1 or workshops != 1:
		errors.append("debe haber un inicio, un jefe y un taller (hay %d/%d/%d)" % [starts, bosses, workshops])
	return errors

func _unique_count(values: Array) -> int:
	var seen := {}
	for value in values:
		seen[value] = true
	return seen.size()
