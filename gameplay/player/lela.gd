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
const REWIND_VISUAL_TIME := 0.25

var aim_dir := Vector2.RIGHT
var _dash_left := 0.0
var _dash_cd := 0.0
var _fire_cd := 0.0
var _rewind_active := 0.0
var _rewind_from := Vector2.ZERO
var _rewind_to := Vector2.ZERO
var _rewind_velocity := Vector2.ZERO
var _music_note: Node2D = null
var _history: Array = [] # snapshots de posición/velocidad, como máximo 1.75 s
var fire_interval := 0.30
var projectile_speed := 420.0
var damage := 10.0

@onready var sprite: Polygon2D = $Body
@onready var muzzle: Marker2D = $Muzzle

func _ready() -> void:
	add_to_group("player")
	GameState.item_added.connect(_on_item_added)
	_apply_items()

func _on_item_added(_item_id: String) -> void:
	_apply_items()

func _apply_items() -> void:
	if "scissors_precision" in GameState.items:
		var d: Dictionary = SynergyDB.get_item("scissors_precision")
		fire_interval = float(d.get("fire_interval", 0.28))
		projectile_speed = float(d.get("projectile_speed", 460.0))
		damage = float(d.get("damage", 10.0))
	if "spring_jumper" in GameState.items:
		dash_speed = 560.0
	_ensure_music_note()

func _ensure_music_note() -> void:
	var wanted := "music_box" in GameState.items
	if wanted and not is_instance_valid(_music_note):
		var note = preload("res://gameplay/projectiles/note.tscn").instantiate()
		note.setup(self, damage, "trapped_notes" in GameState.synergies)
		get_parent().add_child(note)
		_music_note = note
	elif wanted and is_instance_valid(_music_note):
		_music_note.set_pinned("trapped_notes" in GameState.synergies)
	elif not wanted and is_instance_valid(_music_note):
		_music_note.queue_free()
		_music_note = null

func _physics_process(delta: float) -> void:
	if not GameState.is_running:
		return
	_push_history()
	if _rewind_active > 0.0:
		_do_rewind_step(delta)
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
	elif SaveService.settings.get("auto_fire", false):
		# Con disparo automático hay que apuntar al enemigo más cercano. Sin esto
		# se dispara en la dirección del movimiento, que es justo hacia donde se
		# aleja la jugadora: el tiro sale de espaldas.
		var target := _nearest_enemy_dir()
		if target != Vector2.ZERO:
			aim_dir = target
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
	_spawn_cut(aim_dir, muzzle.global_position if muzzle else global_position, projectile_speed, damage)

func _spawn_cut(direction: Vector2, origin: Vector2, cut_speed: float, cut_damage: float) -> void:
	var cut := preload("res://gameplay/projectiles/cut.tscn").instantiate()
	get_parent().add_child(cut)
	cut.global_position = origin
	cut.setup(direction, cut_speed, cut_damage, "player")

func _try_dash() -> void:
	var dash_scale := GameState.try_consume_dash(DASH_COST)
	if dash_scale <= 0.0:
		return
	_dash_left = dash_time * dash_scale
	_dash_cd = dash_cooldown
	# i-frames breves (doc 02).
	$CollisionShape2D.set_deferred("disabled", true)
	await get_tree().create_timer(dash_time + 0.05).timeout
	if is_instance_valid($CollisionShape2D):
		$CollisionShape2D.disabled = false
	if "impulse_scissors" in GameState.synergies:
		for i in 8:
			_spawn_cut(Vector2.from_angle(TAU * float(i) / 8.0), global_position, projectile_speed * 0.7, damage * 0.55)
	dashed.emit()
	PlatformService.vibrate("short")

func _try_rewind() -> void:
	if _rewind_active > 0.0 or _history.size() < 2:
		return
	var sample_count := maxi(1, int(GameState.REWIND_DURATION * 60.0))
	var target_index := maxi(0, _history.size() - sample_count)
	var target: Dictionary = _history[target_index]
	if not GameState.try_consume_rewind():
		return
	_rewind_from = global_position
	_rewind_to = target["pos"]
	_rewind_velocity = target["vel"]
	_rewind_active = REWIND_VISUAL_TIME
	_history.clear()
	# Los proyectiles de ambos bandos son reversibles durante este intervalo.
	get_tree().call_group("projectile_player", "rewind_step", GameState.REWIND_DURATION)
	get_tree().call_group("projectile_enemy", "rewind_step", GameState.REWIND_DURATION)
	rewound.emit()
	PlatformService.vibrate("double")

func _push_history() -> void:
	if _rewind_active > 0.0:
		return
	_history.append({"pos": global_position, "vel": velocity})
	var max_n := int(GameState.REWIND_DURATION * 60.0)
	while _history.size() > max_n:
		_history.pop_front()

func _do_rewind_step(delta: float) -> void:
	_rewind_active = maxf(0.0, _rewind_active - delta)
	var progress := 1.0 - _rewind_active / REWIND_VISUAL_TIME
	# Suaviza el salto sin convertir el rebobinado en una teletransportación abrupta.
	var eased := progress * progress * (3.0 - 2.0 * progress)
	global_position = _rewind_from.lerp(_rewind_to, eased)
	velocity = _rewind_velocity if _rewind_active <= 0.0 else Vector2.ZERO
	if _rewind_active <= 0.0:
		move_and_slide()

func _try_use_consumable() -> void:
	if GameState.life >= GameState.LIFE_MAX:
		return
	# Se recorre el hueco de consumibles en vez de clavar un objeto: así el
	# botón sirve con cualquier consumible que se añada al catálogo, y no solo
	# con la bobina de reparación.
	for item_id in GameState.get_slot_items("consumable"):
		var id := String(item_id)
		var effect := String(SynergyDB.get_item(id).get("effect", ""))
		if effect != "heal_segment":
			continue
		GameState.heal(float(SynergyDB.get_item(id).get("heal", 1.0)))
		GameState.consume_item(id)
		# Sinergia resorte+bobina: parte de tensión en dash (doc 05).
		if "spring_jumper" in GameState.items:
			_dash_cd = 0.0
		return

func take_hit(amount: float, source: String) -> void:
	GameState.apply_damage(amount, source)
	modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.12).timeout
	modulate = Color.WHITE
