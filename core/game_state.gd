# GameState — autoload con estado de partida (RunState).
# Fuente: documentacion/02, 05, 07. Valores de prueba, balance en content/.
extends Node

signal tension_changed(value: float)
signal life_changed(segments: float)
signal rewind_charges_changed(count: int)
signal item_added(item_id: String)
signal inventory_changed
signal synergy_formed(synergy_id: String)
signal run_ended(victory: bool)

const TENSION_MAX := 100.0
const TENSION_REGEN_DELAY := 0.6
const TENSION_REGEN_RATE := 22.0
const REWIND_MAX_CHARGES := 2
const REWIND_RECHARGE_TIME := 11.0
const REWIND_DURATION := 1.75
const LIFE_MAX := 3.0
const SLOT_CAPACITY := {"weapon": 1, "mechanism": 1, "amulet": 1, "consumable": 4}

var tension := TENSION_MAX
var life := LIFE_MAX
var rewind_charges := REWIND_MAX_CHARGES
var seed_value := 0
var generator_version := 1
var run_time := 0.0
var rooms_visited := 0
var kills := 0
var threads := 0
var keys := 0
var items: Array[String] = ["scissors_basic"]
var inventory: Dictionary = {}
var synergies: Array[String] = []
var cause_of_death := ""
var is_running := false

var _regen_cooldown := 0.0
var _rewind_cooldown := 0.0
var _invuln_time := 0.0

func _ready() -> void:
	set_process(true)

func _process(delta: float) -> void:
	if not is_running:
		return
	run_time += delta
	if _regen_cooldown > 0.0:
		_regen_cooldown -= delta
	else:
		if tension < TENSION_MAX:
			tension = minf(TENSION_MAX, tension + TENSION_REGEN_RATE * delta)
			tension_changed.emit(tension)
	if _rewind_cooldown > 0.0:
		_rewind_cooldown -= delta
		if _rewind_cooldown <= 0.0 and rewind_charges < REWIND_MAX_CHARGES:
			rewind_charges += 1
			rewind_charges_changed.emit(rewind_charges)
			if rewind_charges < REWIND_MAX_CHARGES:
				_rewind_cooldown = REWIND_RECHARGE_TIME
	if _invuln_time > 0.0:
		_invuln_time -= delta

func start_run(p_seed: int = 0) -> void:
	if SynergyDB.items_data.is_empty():
		SynergyDB.reload()
	seed_value = p_seed if p_seed != 0 else randi()
	generator_version = RoomGenerator.GENERATOR_VERSION
	tension = TENSION_MAX
	life = LIFE_MAX
	rewind_charges = REWIND_MAX_CHARGES
	run_time = 0.0
	rooms_visited = 0
	kills = 0
	threads = 0
	keys = 0
	items = ["scissors_basic"]
	_rebuild_inventory()
	synergies = []
	cause_of_death = ""
	is_running = true
	_regen_cooldown = 0.0
	_rewind_cooldown = 0.0
	_invuln_time = 0.0
	tension_changed.emit(tension)
	life_changed.emit(life)
	rewind_charges_changed.emit(rewind_charges)

func try_consume_tension(amount: float) -> bool:
	if amount <= 0.0 or tension < amount:
		return false
	tension = maxf(0.0, tension - amount)
	_regen_cooldown = TENSION_REGEN_DELAY
	tension_changed.emit(tension)
	return true

# Devuelve 0 si no hay tensión, 0.5 para un dash reducido y 1 para uno completo.
func try_consume_dash(required_cost: float) -> float:
	if required_cost <= 0.0 or tension <= 0.0:
		return 0.0
	var full := tension >= required_cost
	var cost := minf(required_cost, tension)
	tension = maxf(0.0, tension - cost)
	_regen_cooldown = TENSION_REGEN_DELAY
	tension_changed.emit(tension)
	return 1.0 if full else 0.5

func tension_factor() -> float:
	# A 0 de tensión: ralentizar y debilitar, sin bloquear (doc 02).
	if tension <= 0.0:
		return 0.5
	if tension < 25.0:
		return 0.75
	return 1.0

func can_dash_full() -> bool:
	return tension > 0.0

func apply_damage(amount: float, source: String = "") -> void:
	if _invuln_time > 0.0 or not is_running:
		return
	life = maxf(0.0, life - amount)
	_invuln_time = 0.8
	life_changed.emit(life)
	if life <= 0.0:
		cause_of_death = source
		end_run(false)

func heal(amount: float) -> void:
	life = minf(LIFE_MAX, life + amount)
	life_changed.emit(life)

func try_consume_rewind() -> bool:
	if rewind_charges <= 0:
		return false
	rewind_charges -= 1
	rewind_charges_changed.emit(rewind_charges)
	# Rebobinado es una ventana de escape: evita recibir daño durante la reversión.
	_invuln_time = maxf(_invuln_time, REWIND_DURATION)
	if _rewind_cooldown <= 0.0:
		_rewind_cooldown = REWIND_RECHARGE_TIME
	return true

func _rebuild_inventory() -> void:
	inventory = {"weapon": [], "mechanism": [], "amulet": [], "consumable": []}
	for item_id in items:
		var slot := String(SynergyDB.get_item(item_id).get("slot", ""))
		if slot in inventory:
			var slot_items: Array = inventory[slot]
			slot_items.append(item_id)
	inventory_changed.emit()

func get_slot_items(slot: String) -> Array:
	return (inventory.get(slot, []) as Array).duplicate()

func add_item(item_id: String) -> bool:
	if (item_id in items):
		return false
	var item_data := SynergyDB.get_item(item_id)
	if item_data.is_empty():
		push_error("Objeto desconocido: %s" % item_id)
		return false
	var slot := String(item_data.get("slot", ""))
	var slot_items: Array = inventory.get(slot, [])
	var capacity := int(SLOT_CAPACITY.get(slot, 0))
	if capacity <= 0:
		push_error("Objeto sin slot válido: %s" % item_id)
		return false
	if slot_items.size() >= capacity:
		if slot == "weapon" and not slot_items.is_empty():
			items.erase(String(slot_items[0]))
		else:
			return false
	items.append(item_id)
	_rebuild_inventory()
	_recompute_synergies()
	item_added.emit(item_id)
	return true

func remove_item(item_id: String) -> void:
	items.erase(item_id)
	_rebuild_inventory()
	_recompute_synergies()

func add_resource(resource_id: String) -> void:
	match resource_id:
		"thread":
			threads += 1
		"key":
			keys += 1

func _recompute_synergies() -> void:
	var next: Array[String] = []
	for item_id in items:
		for synergy_id in SynergyDB.check_for_item(items, String(item_id)):
			if not (synergy_id in next):
				next.append(synergy_id)
	for synergy_id in next:
		if not (synergy_id in synergies):
			synergy_formed.emit(synergy_id)
	synergies = next

func restore_run(data: Dictionary) -> void:
	start_run(int(data.get("seed", 0)))
	generator_version = int(data.get("generator_version", generator_version))
	tension = clampf(float(data.get("tension", TENSION_MAX)), 0.0, TENSION_MAX)
	life = clampf(float(data.get("life", LIFE_MAX)), 0.0, LIFE_MAX)
	rewind_charges = clampi(int(data.get("rewind_charges", REWIND_MAX_CHARGES)), 0, REWIND_MAX_CHARGES)
	run_time = maxf(0.0, float(data.get("run_time", 0.0)))
	rooms_visited = maxi(0, int(data.get("rooms_visited", 0)))
	kills = maxi(0, int(data.get("kills", 0)))
	threads = maxi(0, int(data.get("threads", 0)))
	keys = maxi(0, int(data.get("keys", 0)))
	items = ["scissors_basic"]
	var saved_items: Array = data.get("items", [])
	for item_id in saved_items:
		var id := String(item_id)
		if (id in items) or SynergyDB.get_item(id).is_empty():
			continue
		items.append(id)
	_rebuild_inventory()
	synergies = []
	var saved_synergies: Array = data.get("synergies", [])
	for synergy_id in saved_synergies:
		var sid := String(synergy_id)
		if not SynergyDB.get_synergy(sid).is_empty() and not (sid in synergies):
			synergies.append(sid)
	cause_of_death = String(data.get("cause_of_death", ""))
	tension_changed.emit(tension)
	life_changed.emit(life)
	rewind_charges_changed.emit(rewind_charges)

func end_run(victory: bool) -> void:
	if not is_running:
		return
	is_running = false
	run_ended.emit(victory)
