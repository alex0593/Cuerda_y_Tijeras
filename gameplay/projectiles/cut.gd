# cut.tscn proyectil del jugador. Rebote opcional (tornillos), retorno magnético.
extends Area2D

var dir := Vector2.RIGHT
var speed := 420.0
var damage := 10.0
var bounces_left := 0
var life := 1.2
var from := "player"
var _history: Array[Vector2] = []

func setup(p_dir: Vector2, p_speed: float, p_damage: float, p_from: String) -> void:
	dir = p_dir.normalized()
	speed = p_speed
	damage = p_damage
	from = p_from
	if p_from == "player" and "screws_cork" in GameState.items:
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
	_history.append(global_position)
	var max_samples := maxi(1, int(GameState.REWIND_DURATION * 60.0))
	while _history.size() > max_samples:
		_history.pop_front()
	position += dir * speed * delta

func _on_body(body: Node, normal: Vector2 = Vector2.ZERO) -> void:
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
			var bounce_normal := normal if normal.length_squared() > 0.001 else Vector2.UP
			dir = dir.bounce(bounce_normal).normalized()
			rotation = dir.angle()
			life = 0.6
		else:
			queue_free()
	elif from == "enemy" and body.is_in_group("player") and body.has_method("take_hit"):
		body.take_hit(0.5, "enemy_shot")
		queue_free()

func _on_area(_a: Area2D) -> void:
	pass

func rewind_step(duration: float) -> void:
	if _history.is_empty():
		return
	var sample_count := maxi(1, int(duration * 60.0))
	var target_index := maxi(0, _history.size() - sample_count)
	global_position = _history[target_index]
	_history.clear()
