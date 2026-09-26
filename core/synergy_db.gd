# SynergyDB — fuente runtime de objetos, sinergias y enemigos.
# La fuente editable es content/*.json; no se duplican balances en este archivo.
extends Node

const ITEMS_PATH := "res://content/items.json"
const ENEMIES_PATH := "res://content/enemies.json"
const ECONOMY_PATH := "res://content/economy.json"
const MAX_RELATIONS_PER_ITEM := 2
const RARITIES := ["común", "especial", "rara"]

var items_data: Dictionary = {}
var synergies_data: Dictionary = {}
var enemies_data: Dictionary = {}
var economy_data: Dictionary = {}
var content_errors: Array[String] = []

func _ready() -> void:
	reload()

func reload() -> bool:
	content_errors.clear()
	_load_items()
	_load_enemies()
	_load_economy()
	return content_errors.is_empty()

func _load_items() -> void:
	var parsed := _read_json(ITEMS_PATH)
	if parsed.is_empty():
		content_errors.append("No se pudo leer %s" % ITEMS_PATH)
		return
	var raw_items: Variant = parsed.get("items")
	var raw_synergies: Variant = parsed.get("synergies")
	if not (raw_items is Dictionary) or not (raw_synergies is Dictionary):
		content_errors.append("items.json requiere los mapas items y synergies")
		return
	items_data = _copy_dictionary(raw_items)
	synergies_data = _copy_dictionary(raw_synergies)

func _load_enemies() -> void:
	var parsed := _read_json(ENEMIES_PATH)
	if parsed.is_empty():
		content_errors.append("No se pudo leer %s" % ENEMIES_PATH)
		return
	var raw_enemies: Variant = parsed.get("enemies")
	if not (raw_enemies is Dictionary):
		content_errors.append("enemies.json requiere el mapa enemies")
		return
	enemies_data = _copy_dictionary(raw_enemies)

func _load_economy() -> void:
	var parsed := _read_json(ECONOMY_PATH)
	if parsed.is_empty():
		content_errors.append("No se pudo leer %s" % ECONOMY_PATH)
		return
	economy_data = _copy_dictionary(parsed)

func _copy_dictionary(source) -> Dictionary:
	var copy: Dictionary = {}
	for key in source.keys():
		copy[key] = source[key]
	return copy

func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func get_item(item_id: String) -> Dictionary:
	return items_data.get(item_id, {})

func get_synergy(synergy_id: String) -> Dictionary:
	return synergies_data.get(synergy_id, {})

func get_enemy(enemy_id: String) -> Dictionary:
	return enemies_data.get(enemy_id, {})

func get_enemy_cost(enemy_id: String) -> int:
	return int(get_enemy(enemy_id).get("cost", 1))

# --- Economía de la partida (doc 07 §12): todo desde content/economy.json.

func get_price(item_id: String) -> int:
	var rarity := String(get_item(item_id).get("rarity", "común"))
	return int(_map(economy_data.get("prices", {})).get(rarity, 0))

func get_repair_cost() -> int:
	return int(_map(economy_data.get("shop", {})).get("repair_cost", 0))

func get_repair_amount() -> float:
	return float(_map(economy_data.get("shop", {})).get("repair_amount", 0.0))

# Precio en hilos de forzar la tienda del taller cuando no hay alfiler.
func get_entry_cost() -> int:
	return int(_map(economy_data.get("shop", {})).get("entry_cost", 0))

# Ofertas que expone la tienda del taller en cada partida.
func get_shop_offers() -> int:
	return int(_map(economy_data.get("shop", {})).get("offers", 0))

# Pool exclusiva del taller: estos objetos no se ofrecen gratis en ninguna sala.
func get_shop_pool() -> Array:
	var value = economy_data.get("shop_pool", null)
	return value if value is Array else []

# Rango [mín, máx] de hilos que suelta una sala; [-1, -1] si el tipo no existe.
func get_loot_range(room_kind: String) -> Array:
	var value = _map(economy_data.get("loot", {})).get(room_kind, null)
	if not (value is Array) or (value as Array).size() != 2:
		return [-1, -1]
	var lo := int(value[0])
	var hi := int(value[1])
	if lo < 0 or hi < lo:
		return [-1, -1]
	return [lo, hi]

func _map(value) -> Dictionary:
	return value if value is Dictionary else {}

func check_for_item(owned: Array, new_item: String) -> Array[String]:
	var formed: Array[String] = []
	for sid in synergies_data.keys():
		var definition: Dictionary = synergies_data[sid]
		var needs: Array = definition.get("needs", [])
		if needs.size() != 2 or not (new_item in needs):
			continue
		var other := String(needs[0] if String(needs[1]) == new_item else needs[1])
		# "shadow" es una interacción especial, no un objeto de inventario.
		if other == "shadow":
			continue
		if other in owned:
			formed.append(String(sid))
	return formed

func validate_content() -> Array[String]:
	var errors: Array[String] = content_errors.duplicate()
	if items_data.is_empty():
		errors.append("items_data está vacío")
	if synergies_data.is_empty():
		errors.append("synergies_data está vacío")
	for item_id in items_data.keys():
		var item: Dictionary = items_data[item_id]
		for field in ["name", "description", "slot", "rarity", "tags", "restriction", "effect", "max_charges"]:
			if not item.has(field):
				errors.append("objeto %s incompleto: falta %s" % [item_id, field])
		if not (String(item.get("slot", "")) in ["weapon", "mechanism", "amulet", "consumable"]):
			errors.append("objeto %s tiene slot inválido" % item_id)
		if not (String(item.get("rarity", "")) in ["común", "especial", "rara"]):
			errors.append("objeto %s tiene rareza inválida" % item_id)
		if int(item.get("max_charges", 0)) <= 0:
			errors.append("objeto %s necesita max_charges positivo" % item_id)
	var relation_counts := {}
	for synergy_id in synergies_data.keys():
		var definition: Dictionary = synergies_data[synergy_id]
		var needs: Array = definition.get("needs", [])
		if not definition.has("name") or not definition.has("effect"):
			errors.append("sinergia %s incompleta" % synergy_id)
		if needs.size() != 2:
			errors.append("sinergia %s debe tener exactamente dos requisitos" % synergy_id)
		for required in needs:
			var id := String(required)
			if id != "shadow" and get_item(id).is_empty():
				errors.append("sinergia %s requiere objeto desconocido %s" % [synergy_id, id])
			if id != "shadow":
				relation_counts[id] = int(relation_counts.get(id, 0)) + 1
	for item_id in relation_counts.keys():
		if int(relation_counts[item_id]) > MAX_RELATIONS_PER_ITEM:
			errors.append("objeto %s supera %d relaciones" % [item_id, MAX_RELATIONS_PER_ITEM])
	for enemy_id in enemies_data.keys():
		var enemy: Dictionary = enemies_data[enemy_id]
		if not enemy.has("name") or not enemy.has("hp") or not enemy.has("cost"):
			errors.append("enemigo %s incompleto" % enemy_id)
	if economy_data.is_empty():
		errors.append("economy_data está vacío")
	else:
		var prices := _map(economy_data.get("prices", {}))
		for rarity in RARITIES:
			if int(prices.get(rarity, 0)) <= 0:
				errors.append("economy.json necesita precio positivo para %s" % rarity)
		if get_repair_cost() <= 0:
			errors.append("economy.json necesita repair_cost positivo")
		if get_repair_amount() <= 0.0:
			errors.append("economy.json necesita repair_amount positivo")
		if get_entry_cost() <= 0:
			errors.append("economy.json necesita entry_cost positivo")
		var offers := get_shop_offers()
		if offers <= 0:
			errors.append("economy.json necesita offers positivo")
		var pool := get_shop_pool()
		if pool.size() < offers:
			errors.append("economy.json shop_pool necesita al menos %d objetos" % offers)
		var seen := {}
		for value in pool:
			var pool_item := String(value)
			if not items_data.is_empty() and not items_data.has(pool_item):
				errors.append("economy.json shop_pool pide %s desconocido" % pool_item)
			if pool_item == "scissors_basic":
				errors.append("economy.json no puede vender el arma inicial")
			if seen.has(pool_item):
				errors.append("economy.json shop_pool repite %s" % pool_item)
			seen[pool_item] = true
		var loot := _map(economy_data.get("loot", {}))
		if loot.is_empty():
			errors.append("economy.json requiere el mapa loot")
		for room_kind in loot.keys():
			var limits := get_loot_range(String(room_kind))
			if int(limits[0]) < 0:
				errors.append("economy.json loot %s no es un rango [mín, máx] válido" % room_kind)
	return errors
