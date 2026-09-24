# cut.tscn proyectil del jugador. Rebote opcional (tornillos), retorno magnético.
extends Area2D

var dir := Vector2.RIGHT
var speed := 420.0
var damage := 10.0
var bounces_left := 0
var life := 1.2
var from := "player"

func setup(p_dir: Vector2, p_speed: float, p_damage: float, p_from: String) -> void:
	dir = p_dir.normalized()
	speed = p_speed
	damage = p_damage
	from = p_from
	if "screws_cork" in GameState.items:
		bounces_left = 1
	rotation = dir.angle()

func _ready() -> void:
	add_to_group("projectile_player" if from == "player" else "projectile_enemy")
	collision_layer = 4 if from == "player" else 8
	collision_mask = 34 if from == "player" else 1
	body_entered.connect(_on_body)
	area_entered.connect(_on_area)

func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	# Sinergia imán+rebotes: retorno agresivo.
	if from == "player" and "magnet_recovery" in GameState.synergies and life < 0.6:
		var p := get_tree().get_first_node_in_group("player") as Node2D
		if p:
			dir = (p.global_position - global_position).normalized()
			rotation = dir.angle()
	position += dir * speed * delta

func _on_body(body: Node) -> void:
	if from == "player" and body.is_in_group("enemy") and body.has_method("take_hit"):
		var mult := 1.0
		if "glass_eye" in GameState.items and body.get("weak_point_exposed"):
			mult = 1.15
		body.take_hit(damage * mult * GameState.tension_factor(), "cut")
		if "taut_thread" in GameState.items and body.has_method("bind"):
			body.bind(0.8)
		queue_free()
	elif from == "player" and body is StaticBody2D:
		if bounces_left > 0:
			bounces_left -= 1
			dir = dir.bounce(Vector2.UP)
			rotation = dir.angle()
			life = 0.6
		else:
			queue_free()
	elif from == "enemy" and body.is_in_group("player") and body.has_method("take_hit"):
		body.take_hit(0.5, "enemy_shot")
		queue_free()

func _on_area(_a: Area2D) -> void:
	pass

func rewind_step(_history: Array) -> void:
	# Rebobinado revierte proyectiles reversibles unos pasos (doc 02).
	position -= dir * speed * 0.12
