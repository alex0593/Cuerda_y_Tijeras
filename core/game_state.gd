# GameState — autoload con estado de partida (RunState).
# Fuente: documentacion/02, 05, 07. Valores de prueba, balance en content/.
extends Node

signal tension_changed(value: float)
signal life_changed(segments: float)
signal rewind_charges_changed(count: int)
signal item_added(item_id: String)
signal synergy_formed(synergy_id: String)
signal run_ended(victory: bool)

const TENSION_MAX := 100.0
const TENSION_REGEN_DELAY := 0.6
const TENSION_REGEN_RATE := 22.0
const REWIND_MAX_CHARGES := 2
const REWIND_RECHARGE_TIME := 11.0
const REWIND_DURATION := 1.75
const LIFE_MAX := 3.0

var tension := TENSION_MAX
var life := LIFE_MAX
var rewind_charges := REWIND_MAX_CHARGES
var seed_value := 0
var generator_version := 1
var run_time := 0.0
var rooms_visited := 0
var kills := 0
var items: Array[String] = ["scissors_basic"]
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
	seed_value = p_seed if p_seed != 0 else randi()
	generator_version = RoomGenerator.GENERATOR_VERSION
	tension = TENSION_MAX
	life = LIFE_MAX
	rewind_charges = REWIND_MAX_CHARGES
	run_time = 0.0
	rooms_visited = 0
	kills = 0
	items = ["scissors_basic"]
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
	if tension <= 0.0:
		return false
	tension = maxf(0.0, tension - amount)
	_regen_cooldown = TENSION_REGEN_DELAY
	tension_changed.emit(tension)
	return true

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
	if _rewind_cooldown <= 0.0:
		_rewind_cooldown = REWIND_RECHARGE_TIME
	return true

func add_item(item_id: String) -> void:
	if item_id in items:
		return
	items.append(item_id)
	item_added.emit(item_id)
	_check_synergies(item_id)

func _check_synergies(new_item: String) -> void:
	var formed: Array[String] = SynergyDB.check_for_item(items, new_item)
	for s in formed:
		if not s in synergies:
			synergies.append(s)
			synergy_formed.emit(s)

func end_run(victory: bool) -> void:
	is_running = false
	run_ended.emit(victory)
