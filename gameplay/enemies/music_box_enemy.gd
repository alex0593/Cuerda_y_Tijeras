# Caja de música: fija, patrón circular, núcleo vulnerable. Silenciar la detiene.
extends "res://gameplay/enemies/base_enemy.gd"

var _timer := 1.0

func _ready() -> void:
	super._ready()
	enemy_id = "music_box"
	max_hp = 30.0
	hp = max_hp
	move_speed = 0.0

func _tick(delta: float) -> void:
	velocity = Vector2.ZERO
	_timer -= delta
	if _timer <= 0.0:
		_timer = 2.2
		_fire_ring()

func _fire_ring() -> void:
	for i in 8:
		var a := TAU * float(i) / 8.0
		var s := preload("res://gameplay/projectiles/cut.tscn").instantiate()
		get_parent().add_child(s)
		s.global_position = global_position
		s.setup(Vector2(cos(a), sin(a)), 140.0, 0.5, "enemy")
