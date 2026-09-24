# Jefe Caja de Cero: fase 1 abanico + llave; fase 2 tres cajas (abanico, hilos, notas).
# Funciona con ataque inicial (doc 04/07).
extends "res://gameplay/enemies/base_enemy.gd"

var phase := 1
var _timer := 1.5

func _ready() -> void:
	super._ready()
	enemy_id = "caja_cero"
	max_hp = 120.0
	hp = max_hp

func _tick(delta: float) -> void:
	_timer -= delta
	velocity = Vector2.ZERO
	if hp < max_hp * 0.5 and phase == 1:
		phase = 2
		_timer = 1.0
		_flash = 0.5
	if _timer > 0.0:
		return
	if phase == 1:
		_timer = 1.6
		_fan()
	else:
		_timer = 1.2
		_fan()
		_threads()

func _fan() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	var base := Vector2.LEFT if p == null else (p.global_position - global_position).normalized()
	for k in [-2, -1, 0, 1, 2]:
		var s := preload("res://gameplay/projectiles/cut.tscn").instantiate()
		get_parent().add_child(s)
		s.global_position = global_position
		s.setup(base.rotated(k * 0.25), 170.0, 0.5, "enemy")

func _threads() -> void:
	for i in 3:
		var s := preload("res://gameplay/projectiles/cut.tscn").instantiate()
		get_parent().add_child(s)
		s.global_position = global_position + Vector2(0, -20 * i)
		s.setup(Vector2(0, 1).rotated(i * 0.6), 120.0, 0.5, "enemy")
