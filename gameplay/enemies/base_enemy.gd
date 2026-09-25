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
var _drop_rng := RandomNumberGenerator.new()
var _bind_left := 0.0
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
	modulate = Color(1, 0.5, 0.5) if _flash > 0.0 else Color.WHITE
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

func die() -> void:
	GameState.kills += 1
	_drop()
	queue_free()

func _drop() -> void:
	var roll := _drop_rng.randf()
	if roll < 0.25:
		var pk := preload("res://gameplay/pickups/pickup.tscn").instantiate()
		get_parent().add_child(pk)
		pk.global_position = global_position
		pk.kind = "thread" if roll < 0.15 else "key"

func _try_touch_player() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p and global_position.distance_to(p.global_position) < 26.0:
		if p.has_method("take_hit"):
			p.take_hit(touch_damage, enemy_id)
