# Jefe Caja de Cero (doc 04/07): dos fases con aviso visible y contraataque.
# Fase 1: abanico de cortes. Fase 2 (bajo el 50 %): abanico + lluvia de hilos.
# Contraataque: interrumpir el aviso cancela la ráfaga y hace daño extra.
extends "res://gameplay/enemies/base_enemy.gd"

const TELEGRAPH_TIME := 0.6
const PHASE1_GAP := 1.6
const PHASE2_GAP := 1.2
const INTERRUPT_GAP := 1.4
const INTERRUPT_BONUS := 1.5

var phase := 1
var _timer := 1.5
# _telegraph lo declara BaseEnemy: aquí es el aviso visible de cada ráfaga.

func _ready() -> void:
	super._ready()
	enemy_id = "caja_cero"
	max_hp = 120.0
	hp = max_hp

func _tick(delta: float) -> void:
	velocity = Vector2.ZERO
	if hp < max_hp * 0.5 and phase == 1:
		phase = 2
		_flash = 0.6
		_timer = 1.0
	# Mientras avisa se queda quieta: el aviso tiene que leerse en móvil.
	if _telegraph > 0.0:
		_telegraph -= delta
		_expose_key(true)
		if _telegraph <= 0.0:
			_fire()
			_expose_key(false)
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_telegraph = TELEGRAPH_TIME
	_timer = PHASE1_GAP if phase == 1 else PHASE2_GAP

# La llave central es el aviso: crece y se enciende antes de cada ráfaga.
func _expose_key(exposed: bool) -> void:
	var key := get_node_or_null("Key") as Polygon2D
	if key == null:
		return
	key.scale = Vector2(1.8, 1.8) if exposed else Vector2.ONE
	key.color = Color(1.0, 0.85, 0.35) if exposed else Color(0.79, 0.64, 0.15)

func _fire() -> void:
	_fan()
	if phase == 2:
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

# Contraataque: cortar la llave mientras avisa cancela la ráfaga y hace daño extra.
func take_hit(amount: float, source: String, from_position: Vector2 = Vector2.ZERO) -> void:
	if _telegraph > 0.0:
		_telegraph = 0.0
		_expose_key(false)
		_timer = INTERRUPT_GAP
		amount *= INTERRUPT_BONUS
	super.take_hit(amount, source, from_position)
