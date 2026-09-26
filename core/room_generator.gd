# RoomGenerator — generación con semilla (doc 07).
# Grafo pequeño para vertical slice: inicio -> combate -> tesoro/riesgo -> taller -> jefe.
extends Node

const GENERATOR_VERSION := 4

const VERTICAL_SLICE_FLOW := ["start", "combat", "treasure", "risk", "combat", "workshop", "boss"]

# Reparto de objetos: salas que ofrecen objetos y cuántas opciones dejan en el suelo.
# La jugadora decide cuáles recoger antes de salir por la puerta.
const REWARD_ROOM_KINDS := ["combat", "treasure", "risk", "workshop"]
const REWARD_OFFER_COUNT := 3
# El arma inicial no se ofrece: solo se conserva o se sustituye.
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
	# Las salas de recompensa ofrecen objetos reales; el resto, nada.
	room["offers"] = _pick_item_offers(rng, REWARD_OFFER_COUNT) if kind in REWARD_ROOM_KINDS else []
	# El taller expone su pool exclusiva: se sortea entera para que la tercera
	# oferta no cambie cuando se desbloquea con una llave (doc 07 §13).
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

func _pick_boss_drop(rng: RandomNumberGenerator) -> String:
	var drops: Array = _pick_item_offers(rng, 1)
	return String(drops[0]) if not drops.is_empty() else ""

# Selección ponderada por rareza y sin repetir dentro de la misma sala.
# Devuelve identificadores estables de content/items.json, nunca balances hardcodeados.
func _pick_item_offers(rng: RandomNumberGenerator, count: int) -> Array:
	var pool: Array = []
	for item_id in _item_ids():
		# La pool del taller no se reparte gratis: solo está a la venta allí.
		if item_id in NON_REWARD_ITEMS or item_id in _shop_pool():
			continue
		pool.append(item_id)
	return _draw_weighted(rng, pool, count)

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
	return db.get_shop_offers_with_key() if db else 0

func _shop_visible_count() -> int:
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
	# Las ofertas son identificadores estables y no se repiten dentro de la sala.
	var offers: Array = room.get("offers", [])
	var kind := String(room.get("kind", ""))
	if kind in REWARD_ROOM_KINDS and offers.size() != REWARD_OFFER_COUNT:
		errors.append("reward room %d debe ofrecer %d objetos" % [int(room.get("index", -1)), REWARD_OFFER_COUNT])
	if offers.size() != _unique_count(offers):
		errors.append("reward room %d ofrece objetos repetidos" % int(room.get("index", -1)))
	for item_id in offers:
		if _item(String(item_id)).is_empty():
			errors.append("reward room ofrece objeto desconocido %s" % item_id)
		elif String(item_id) in _shop_pool():
			errors.append("la pool del taller no se reparte gratis (%s)" % item_id)
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
	if wanted < _shop_visible_count():
		errors.append("economy.json no permite mostrar %d de %d ofertas" % [_shop_visible_count(), wanted])
	for item_id in shop_offers:
		var offer := String(item_id)
		if not (offer in _shop_pool()):
			errors.append("el taller vende %s fuera de su pool" % offer)
		elif _item(offer).is_empty():
			errors.append("el taller vende objeto desconocido %s" % offer)
		elif db != null and int(db.get_price(offer)) <= 0:
			errors.append("el taller vende %s sin precio" % offer)
	return errors

func _unique_count(values: Array) -> int:
	var seen := {}
	for value in values:
		seen[value] = true
	return seen.size()
