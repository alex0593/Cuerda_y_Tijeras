# RoomGenerator — generación con semilla (doc 07).
# Grafo pequeño para vertical slice: inicio -> combate -> tesoro/riesgo -> taller -> jefe.
extends Node

const GENERATOR_VERSION := 2

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
	return room

# Selección ponderada por rareza y sin repetir dentro de la misma sala.
# Devuelve identificadores estables de content/items.json, nunca balances hardcodeados.
func _pick_item_offers(rng: RandomNumberGenerator, count: int) -> Array:
	var pool: Array = []
	for item_id in _item_ids():
		if item_id in NON_REWARD_ITEMS:
			continue
		pool.append(item_id)
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
	return errors

func _unique_count(values: Array) -> int:
	var seen := {}
	for value in values:
		seen[value] = true
	return seen.size()
