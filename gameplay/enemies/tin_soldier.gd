# Soldado de estaño: avanza, avisa, carga. Se rompe escudo por detrás/dash.
extends "res://gameplay/enemies/base_enemy.gd"

var _state := "chase"
var _timer := 0.0

func _ready() -> void:
	super._ready()
	enemy_id = "tin_soldier"
	max_hp = 24.0
	hp = max_hp
	move_speed = 75.0

func _tick(delta: float) -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return
	var to: Vector2 = (p.global_position - global_position)
	_timer -= delta
	match _state:
		"chase":
			velocity = to.normalized() * move_speed
			if to.length() < 180.0 and _timer <= 0.0:
				_state = "telegraph"
				_timer = 0.5 # aviso legible (doc 04)
				velocity = Vector2.ZERO
		"telegraph":
			velocity = Vector2.ZERO
			modulate = Color(1, 0.85, 0.3)
			if _timer <= 0.0:
				_state = "charge"
				_timer = 0.45
		"charge":
			velocity = to.normalized() * 260.0
			if _timer <= 0.0:
				_state = "chase"
				_timer = 1.2
