# RoomGenerator — generación con semilla (doc 07).
# Grafo pequeño para vertical slice: inicio -> combate -> tesoro/riesgo -> taller -> jefe.
extends Node

const GENERATOR_VERSION := 1

const VERTICAL_SLICE_FLOW := ["start", "combat", "treasure", "risk", "workshop", "boss"]

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
	var room := {"index": index, "kind": kind, "seed": rng.randi(), "enemies": [], "reward": "", "template": "open"}
	match kind:
		"start":
			room["template"] = "safe_entry"
			room["reward"] = ""
		"combat":
			room["template"] = "open" if rng.randf() < 0.5 else "cross"
			room["enemies"] = _pick_enemies(rng, 2)
			room["reward"] = "choice_2"
		"treasure":
			room["template"] = "open"
			room["reward"] = "chest"
		"risk":
			room["template"] = "pillar"
			room["enemies"] = _pick_enemies(rng, 3)
			room["reward"] = "risk_chest"
		"workshop":
			room["template"] = "open"
			room["reward"] = "workshop"
		"boss":
			room["template"] = "boss_arena"
			room["enemies"] = ["caja_cero"]
			room["reward"] = "boss"
	return room

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

func _content_db() -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("SynergyDB")
	return null

func _enemy_cost(enemy_id: String) -> int:
	var db := _content_db()
	return db.get_enemy_cost(enemy_id) if db else 1

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
	return errors
