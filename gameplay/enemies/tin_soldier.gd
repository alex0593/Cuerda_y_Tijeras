# Soldado de estaño: avanza, avisa, carga. Se rompe escudo por detrás/dash.
extends "res://gameplay/enemies/base_enemy.gd"

var _state := "chase"
var _timer := 0.0
var _facing := Vector2.LEFT
var shield := 8.0
var shield_broken := false
@onready var telegraph: Line2D = $Telegraph
@onready var shield_visual: Line2D = $Shield

func _ready() -> void:
	super._ready()
	enemy_id = "tin_soldier"
	max_hp = 24.0
	hp = max_hp
	move_speed = 75.0
	shield_visual.visible = true

func adjust_damage(amount: float, from_position: Vector2) -> float:
	if shield_broken:
		return amount * 1.25
	var incoming := (from_position - global_position).normalized()
	if incoming.dot(_facing) > 0.25:
		shield = maxf(0.0, shield - amount * 0.5)
		if shield <= 0.0:
			shield_broken = true
			shield_visual.visible = false
		return amount * 0.25
	shield_broken = true
	shield_visual.visible = false
	return amount * 1.25

func _tick(delta: float) -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return
	var to: Vector2 = (p.global_position - global_position)
	_timer -= delta
	match _state:
		"chase":
			telegraph.visible = false
			_facing = to.normalized()
			velocity = _facing * move_speed
			if to.length() < 180.0 and _timer <= 0.0:
				_state = "telegraph"
				_timer = 0.5 # aviso legible (doc 04)
				velocity = Vector2.ZERO
		"telegraph":
			telegraph.visible = true
			_facing = to.normalized()
			telegraph.rotation = _facing.angle()
			velocity = Vector2.ZERO
			modulate = Color(1, 0.85, 0.3)
			if _timer <= 0.0:
				_state = "charge"
				_timer = 0.45
		"charge":
			telegraph.visible = false
			_facing = to.normalized()
			velocity = _facing * 260.0
			if _timer <= 0.0:
				_state = "chase"
				_timer = 1.2
