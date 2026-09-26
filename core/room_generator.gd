# RoomGenerator — generación con semilla (doc 07).
# Grafo pequeño para vertical slice: inicio -> combate -> tesoro/riesgo -> taller -> jefe.
extends Node

const GENERATOR_VERSION := 5

const VERTICAL_SLICE_FLOW := ["start", "combat", "treasure", "risk", "combat", "workshop", "boss"]

# El arma inicial nunca se reparte: solo se conserva o se sustituye.
const NON_REWARD_ITEMS := ["scissors_basic"]
# Pesos por rareza, para que lo raro sea raro sin desaparecer del vertical slice.
const RARITY_WEIGHTS := {"común": 60, "especial": 30, "rara": 10}
const DEFAULT_RARITY_WEIGHT := 10

func generate_run(p_seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	var rooms: Array = []
	for i in VERTICAL_SLICE_FLOW.size():
		var kind: String = VERTICAL_SLICE_FLOW[i]
		rooms.append(_make_room(rng, i, kind))
	for i in rooms.size():
		var room: Dictionary = rooms[i]
		room["connections"] = [i + 1] if i < rooms.size() - 1 else []
		room["entry_safe"] = true
		room["exit_position"] = Vector2(920, 270)
		rooms[i] = room
	return {"seed": p_seed, "version": GENERATOR_VERSION, "rooms": rooms}

func _make_room(rng: RandomNumberGenerator, index: int, kind: String) -> Dictionary:
	var room := {"index": index, "kind": kind, "seed": rng.randi(), "enemies": [], "template": "open"}
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
	# Ninguna sala regala objetos: solo hilos en el suelo. Los objetos salen del
	# jefe y de la tienda del taller (doc 07 §12.1 y §13).
	# El taller expone su pool exclusiva, sorteada con la semilla.
	room["shop_offers"] = _pick_shop_offers(rng) if kind == "workshop" else []
	# Botín de hilos en el suelo: la moneda de la partida (content/economy.json).
	room["loot"] = _roll_loot(rng, kind)
	# El jefe siempre suelta un objeto del catálogo (decisión 2026-09-25).
	room["boss_drop"] = _pick_boss_drop(rng) if kind == "boss" else ""
	return room

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
	var pool: Array = []
	for item_id in _item_ids():
		if item_id in NON_REWARD_ITEMS or item_id in _shop_pool():
			continue
		pool.append(item_id)
	var drops := _draw_weighted(rng, pool, 1)
	return String(drops[0]) if not drops.is_empty() else ""

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

func validate_room(room: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not room.has("kind") or not room.has("enemies") or not room.has("template"):
		errors.append("room missing kind/template/enemies")
	# Regla doc 07: la entrada es segura, sin proyectil inicial sin aviso.
	if room.get("kind") == "start" and not (room.get("enemies", []) as Array).is_empty():
		errors.append("start room must have no enemies")
	if not room.has("seed") or not room.has("connections"):
		errors.append("room missing seed/connections")
	if room.get("kind") == "combat" and enemy_budget(room) > 2:
		errors.append("combat room exceeds difficulty budget")
	if room.get("kind") == "risk" and enemy_budget(room) > 3:
		errors.append("risk room exceeds difficulty budget")
	# Ninguna sala regala objetos: solo el jefe y la tienda del taller los sueltan.
	var kind := String(room.get("kind", ""))
	if not (room.get("offers", []) as Array).is_empty():
		errors.append("sala %d no debe ofrecer objetos gratis" % int(room.get("index", -1)))
	# Botín de hilos: cantidad dentro del rango de content/economy.json.
	var limits := _loot_range(kind)
	if int(limits[0]) < 0:
		errors.append("economy.json no define loot para %s" % kind)
	else:
		var loot: Array = room.get("loot", [])
		if loot.size() < int(limits[0]) or loot.size() > int(limits[1]):
			errors.append("sala %d debe soltar entre %d y %d hilos" % [int(room.get("index", -1)), int(limits[0]), int(limits[1])])
		for resource_id in loot:
			if not (String(resource_id) in ["thread", "key"]):
				errors.append("sala %d suelta recurso desconocido %s" % [int(room.get("index", -1)), resource_id])
	# El jefe suelta siempre un objeto alcanzable y distinto del arma inicial.
	var boss_drop := String(room.get("boss_drop", ""))
	if kind == "boss":
		if boss_drop == "" or _item(boss_drop).is_empty() or boss_drop in NON_REWARD_ITEMS or boss_drop in _shop_pool():
			errors.append("boss_drop debe ser un objeto alcanzable distinto del inicial")
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
	if drop != "" and not (drop in owned):
		return drop
	var pool: Array = []
	for item_id in _item_ids():
		var id := String(item_id)
		if id in NON_REWARD_ITEMS or id in _shop_pool() or id in owned:
			continue
		pool.append(id)
	if pool.is_empty():
		return ""
	var rng := RandomNumberGenerator.new()
	rng.seed = int(room.get("seed", 0)) + 7919
	var pick := _draw_weighted(rng, pool, 1)
	return String(pick[0]) if not pick.is_empty() else ""

func _unique_count(values: Array) -> int:
	var seen := {}
	for value in values:
		seen[value] = true
	return seen.size()
