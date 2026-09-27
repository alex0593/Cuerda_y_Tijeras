# Base enemigo con aviso, debilidad y sin objeto obligatorio (doc 04).
extends CharacterBody2D
class_name BaseEnemy

@export var enemy_id := "tin_soldier"
@export var max_hp := 20.0
@export var touch_damage := 0.5
@export var move_speed := 70.0

var hp := 20.0
var weak_point_exposed := false
var drop_rng_seed := 0
# Botín garantizado ("item:<id>", "thread"...): el jefe siempre suelta algo.
var guaranteed_drop := ""
var _drop_rng := RandomNumberGenerator.new()
var _bind_left := 0.0
var _thread_left := 0.0
var _thread_tick := 0.0
var _flash := 0.0
var _telegraph := 0.0

func _ready() -> void:
	add_to_group("enemy")
	_drop_rng.seed = drop_rng_seed
	hp = max_hp

func _physics_process(delta: float) -> void:
	if not GameState.is_running:
		velocity = Vector2.ZERO
		return
	_flash = maxf(0.0, _flash - delta)
	_bind_left = maxf(0.0, _bind_left - delta)
	if _thread_left > 0.0:
		_thread_left -= delta
		_thread_tick -= delta
		if _thread_tick <= 0.0:
			_thread_tick = 0.5
			hp -= 2.0
			_flash = 0.08
			if hp <= 0.0:
				die()
				return
	modulate = Color(1, 0.5, 0.5) if _flash > 0.0 else Color.WHITE
	if "glass_eye" in GameState.items:
		weak_point_exposed = true
	if _bind_left > 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_tick(delta)
	move_and_slide()
	_try_touch_player()

func _tick(_delta: float) -> void:
	pass

func adjust_damage(amount: float, _from_position: Vector2) -> float:
	return amount

func take_hit(amount: float, _source: String, from_position: Vector2 = Vector2.ZERO) -> void:
	amount = adjust_damage(amount, from_position)
	hp -= amount
	_flash = 0.12
	if "glass_eye" in GameState.items:
		weak_point_exposed = true
	if hp <= 0.0:
		die()

func bind(t: float) -> void:
	_bind_left = maxf(_bind_left, t)

func thread_mark(t: float) -> void:
	_thread_left = maxf(_thread_left, t)
	_thread_tick = minf(_thread_tick, 0.1)

func die() -> void:
	GameState.kills += 1
	_drop()
	queue_free()

func _drop() -> void:
	if guaranteed_drop != "":
		_spawn_pickup(guaranteed_drop, global_position)
	var roll := _drop_rng.randf()
	if roll < 0.25:
		_spawn_pickup("thread" if roll < 0.15 else "key", global_position)

func _spawn_pickup(pickup_kind: String, at: Vector2) -> void:
	var pk := preload("res://gameplay/pickups/pickup.tscn").instantiate()
	pk.kind = pickup_kind
	# El botín nace dentro del impacto que mata al enemigo, justo cuando Godot
	# está cerrando las consultas de física y no admite un área nueva. Encolarlo
	# evita el error y deja el botín igual, un instante después.
	var parent := get_parent()
	if not is_instance_valid(parent):
		pk.queue_free()
		return
	parent.add_child.call_deferred(pk)
	pk.set_deferred("global_position", at)

func _try_touch_player() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p and global_position.distance_to(p.global_position) < 26.0:
		if p.has_method("take_hit"):
			p.take_hit(touch_damage, enemy_id)
