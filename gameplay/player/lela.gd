# Lela — CharacterBody2D. Movimiento 8 dir, dash con i-frames, disparo, rebobinado.
# Controles: Android joysticks (ui/touch_controls) + escritorio WASD/ratón (doc 09.8).
extends CharacterBody2D

signal fired
signal dashed
signal rewound

@export var move_speed := 220.0
@export var dash_speed := 520.0
@export var dash_time := 0.16
@export var dash_cooldown := 0.45

const SHOT_COST := 4.0
const DASH_COST := 12.0

var aim_dir := Vector2.RIGHT
var _dash_left := 0.0
var _dash_cd := 0.0
var _fire_cd := 0.0
var _rewind_active := 0.0
var _history: Array = [] # [{pos, vel}] últimos ~2s a 60Hz
var fire_interval := 0.30
var projectile_speed := 420.0
var damage := 10.0

@onready var sprite: Polygon2D = $Body
@onready var muzzle: Marker2D = $Muzzle

func _ready() -> void:
	add_to_group("player")
	_apply_items()

func _apply_items() -> void:
	if "scissors_precision" in GameState.items:
		var d: Dictionary = SynergyDB.get_item("scissors_precision")
		fire_interval = float(d.get("fire_interval", 0.28))
		projectile_speed = float(d.get("projectile_speed", 460.0))
		damage = float(d.get("damage", 10.0))
	if "spring_jumper" in GameState.items:
		dash_speed = 560.0

func _physics_process(delta: float) -> void:
	if not GameState.is_running:
		return
	_push_history()
	if _rewind_active > 0.0:
		_rewind_active -= delta
		_do_rewind_step()
		return
	var move := _read_move()
	var want_fire := _read_fire()
	var want_dash := _read_dash_pressed()
	if want_dash and _dash_cd <= 0.0:
		_try_dash()
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_fire_cd = maxf(0.0, _fire_cd - delta)
	if _dash_left > 0.0:
		_dash_left -= delta
		velocity = aim_dir * dash_speed * GameState.tension_factor() if move == Vector2.ZERO else move * dash_speed * GameState.tension_factor()
	else:
		velocity = move * move_speed * GameState.tension_factor()
	move_and_slide()
	_update_aim()
	if want_fire and _fire_cd <= 0.0:
		_try_fire()
	if Input.is_action_just_pressed("rewind"):
		_try_rewind()
	if Input.is_action_just_pressed("use_item"):
		_try_use_consumable()

func _read_move() -> Vector2:
	var t := _touch_move()
	if t != Vector2.ZERO:
		return t
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

func _touch() -> Node:
	return get_tree().get_first_node_in_group("touch")

func _touch_move() -> Vector2:
	var t := _touch()
	if t and t.get("move_vec") != Vector2.ZERO:
		return t.get("move_vec")
	return Vector2.ZERO

func _touch_aim() -> Vector2:
	var t := _touch()
	if t and t.get("aim_active"):
		return t.get("aim_vec")
	return Vector2.ZERO

func _read_fire() -> bool:
	if Input.is_action_pressed("fire"):
		return true
	if _touch_aim() != Vector2.ZERO:
		return true
	if SaveService.settings.get("auto_fire", false):
		return _nearest_enemy_dir() != Vector2.ZERO
	return false

func _read_dash_pressed() -> bool:
	return Input.is_action_just_pressed("dash")

func _update_aim() -> void:
	var ta := _touch_aim()
	if ta != Vector2.ZERO:
		aim_dir = ta
	else:
		var m := get_global_mouse_position() - global_position
		if Input.is_action_pressed("fire") and m.length() > 4.0:
			aim_dir = m.normalized()
		elif velocity.length() > 10.0:
			aim_dir = velocity.normalized()
	rotation = 0.0
	if muzzle:
		muzzle.position = aim_dir * 26.0

func _nearest_enemy_dir() -> Vector2:
	var best := Vector2.ZERO
	var best_d := 420.0
	for e in get_tree().get_nodes_in_group("enemy"):
		if e is Node2D:
			var d: float = global_position.distance_to((e as Node2D).global_position)
			if d < best_d:
				best_d = d
				best = ((e as Node2D).global_position - global_position).normalized()
	return best

func _try_fire() -> void:
	if not GameState.try_consume_tension(SHOT_COST):
		return
	_fire_cd = fire_interval
	fired.emit()
	var cut := preload("res://gameplay/projectiles/cut.tscn").instantiate()
	get_parent().add_child(cut)
	cut.global_position = muzzle.global_position if muzzle else global_position
	cut.setup(aim_dir, projectile_speed, damage, "player")

func _try_dash() -> void:
	var can_full: bool = GameState.can_dash_full()
	if not GameState.try_consume_tension(DASH_COST if can_full else 0.0):
		return
	_dash_left = dash_time * (1.0 if can_full else 0.5)
	_dash_cd = dash_cooldown
	# i-frames breves (doc 02).
	$CollisionShape2D.set_deferred("disabled", true)
	await get_tree().create_timer(dash_time + 0.05).timeout
	if is_instance_valid($CollisionShape2D):
		$CollisionShape2D.disabled = false
	dashed.emit()
	PlatformService.vibrate("short")

func _try_rewind() -> void:
	if not GameState.try_consume_rewind():
		return
	# Rebobina 1.5-2s: solo posición/proyectiles reversibles, sin deshacer daño (doc 02).
	_rewind_active = 0.25 # ventana de invulnerabilidad + reversión visual
	rewound.emit()
	PlatformService.vibrate("double")
	get_tree().call_group("projectile_enemy", "rewind_step", _history)

func _push_history() -> void:
	_history.append({"pos": global_position, "vel": velocity})
	var max_n := int(GameState.REWIND_DURATION * 60.0)
	while _history.size() > max_n:
		_history.pop_front()

func _do_rewind_step() -> void:
	if _history.size() > 10:
		var target: Dictionary = _history[_history.size() - 10]
		global_position = target["pos"]
		velocity = target["vel"]
		for i in 10:
			if not _history.is_empty():
				_history.pop_back()
	else:
		_history.clear()

func _try_use_consumable() -> void:
	if "repair_coil" in GameState.items:
		GameState.heal(1.0)
		GameState.items.erase("repair_coil")
		# Sinergia resorte+bobina: parte de tensión en dash (doc 05).
		if "spring_jumper" in GameState.items:
			_dash_cd = 0.0

func take_hit(amount: float, source: String) -> void:
	GameState.apply_damage(amount, source)
	modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.12).timeout
	modulate = Color.WHITE
