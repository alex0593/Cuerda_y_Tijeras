# Room — plantilla jugable con entrada segura, puertas y spawn por presupuesto.
extends Node2D

signal cleared

@export var kind := "combat"
var enemies_to_spawn: Array = []
var spawned: Array = []
var is_cleared := false
var room_data: Dictionary = {}
var _ready_done := false

func setup(room: Dictionary) -> void:
	if _ready_done:
		push_error("Room.setup() must be called before adding the room to the tree")
		return
	room_data = room.duplicate(true)
	kind = String(room.get("kind", "combat"))
	enemies_to_spawn = (room.get("enemies", []) as Array).duplicate()

func _ready() -> void:
	_ready_done = true
	_spawn_walls()
	_spawn_player()
	_spawn_enemies()

func _process(_delta: float) -> void:
	if is_cleared or not GameState.is_running:
		return
	for e in spawned:
		if is_instance_valid(e):
			return
	_mark_cleared()

func _spawn_walls() -> void:
	# Sala 880x460 con muros simples. Entrada segura a la izquierda.
	var size := Vector2(880, 460)
	for data in [
		[Vector2(480, -10), Vector2(960, 20)], [Vector2(480, 550), Vector2(960, 20)],
		[Vector2(-10, 270), Vector2(20, 560)], [Vector2(970, 270), Vector2(20, 560)],
	]:
		var w := StaticBody2D.new()
		w.collision_layer = 32
		w.collision_mask = 7
		var c := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = data[1]
		c.shape = r
		w.position = data[0]
		add_child(w)
		var v := Polygon2D.new()
		var hs: Vector2 = data[1] * 0.5
		v.polygon = PackedVector2Array([-hs, Vector2(hs.x, -hs.y), hs, Vector2(-hs.x, hs.y)])
		v.color = Color(0.35, 0.30, 0.25)
		w.add_child(v)

func _spawn_player() -> void:
	var lela := preload("res://gameplay/player/lela.tscn").instantiate()
	add_child(lela)
	lela.position = Vector2(120, 270)

func _spawn_enemies() -> void:
	var x := 480.0
	for eid in enemies_to_spawn:
		var e: Node2D = null
		match String(eid):
			"tin_soldier":
				e = preload("res://gameplay/enemies/tin_soldier.tscn").instantiate()
			"music_box":
				e = preload("res://gameplay/enemies/music_box.tscn").instantiate()
			"caja_cero":
				e = preload("res://gameplay/enemies/boss_caja_cero.tscn").instantiate()
		if e:
			add_child(e)
			e.position = Vector2(x, 270)
			spawned.append(e)
			x += 120.0

func _mark_cleared() -> void:
	if is_cleared or not GameState.is_running:
		return
	is_cleared = true
	cleared.emit()
