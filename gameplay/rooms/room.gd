# Room — plantilla jugable con entrada segura, puertas y spawn por presupuesto.
extends Node2D

signal cleared
signal exit_reached

@export var kind := "combat"
@export var template := "open"
var enemies_to_spawn: Array = []
var spawned: Array = []
var is_cleared := false
var room_data: Dictionary = {}
var room_seed := 0
var rng := RandomNumberGenerator.new()
var door_body: StaticBody2D = null
var door_visual: Polygon2D = null
var exit_area: Area2D = null
var exit_hint: Label = null
var _ready_done := false

func setup(room: Dictionary) -> void:
	if _ready_done:
		push_error("Room.setup() must be called before adding the room to the tree")
		return
	room_data = room.duplicate(true)
	kind = String(room.get("kind", "combat"))
	template = String(room.get("template", "open"))
	room_seed = int(room.get("seed", 0))
	rng.seed = room_seed if room_seed != 0 else int(Time.get_ticks_usec())
	enemies_to_spawn = (room.get("enemies", []) as Array).duplicate()

func _ready() -> void:
	_ready_done = true
	_spawn_walls()
	_spawn_cover()
	_spawn_exit()
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
	for data in [
		[Vector2(480, -10), Vector2(960, 20)], [Vector2(480, 550), Vector2(960, 20)],
		[Vector2(-10, 270), Vector2(20, 560)], [Vector2(970, 270), Vector2(20, 560)],
	]:
		_spawn_static_box(data[0], data[1], Color(0.35, 0.30, 0.25))

func _spawn_cover() -> void:
	var obstacles: Array = []
	match template:
		"cross":
			obstacles = [
				[Vector2(430, 175), Vector2(170, 24)],
				[Vector2(430, 365), Vector2(170, 24)],
				[Vector2(350, 270), Vector2(24, 150)],
				[Vector2(510, 270), Vector2(24, 150)],
			]
		"pillar":
			obstacles = [
				[Vector2(400, 150), Vector2(56, 56)],
				[Vector2(580, 150), Vector2(56, 56)],
				[Vector2(400, 390), Vector2(56, 56)],
				[Vector2(580, 390), Vector2(56, 56)],
			]
	for data in obstacles:
		_spawn_static_box(data[0], data[1], Color(0.43, 0.36, 0.30))

func _spawn_static_box(position: Vector2, box_size: Vector2, color: Color) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 32
	body.collision_mask = 7
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = box_size
	collision.shape = rectangle
	body.position = position
	add_child(body)
	body.add_child(collision)
	var visual := Polygon2D.new()
	var half := box_size * 0.5
	visual.polygon = PackedVector2Array([-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)])
	visual.color = color
	body.add_child(visual)
	return body

func _spawn_exit() -> void:
	door_body = StaticBody2D.new()
	door_body.collision_layer = 32
	door_body.collision_mask = 7
	door_body.position = Vector2(940, 270)
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(20, 120)
	collision.shape = rectangle
	door_body.add_child(collision)
	add_child(door_body)
	door_visual = Polygon2D.new()
	door_visual.polygon = PackedVector2Array([
		Vector2(-8, -60), Vector2(8, -60), Vector2(8, 60), Vector2(-8, 60)
	])
	door_visual.color = Color(0.55, 0.20, 0.16)
	door_body.add_child(door_visual)
	exit_area = Area2D.new()
	exit_area.collision_layer = 0
	exit_area.collision_mask = 1
	exit_area.monitoring = false
	exit_area.position = Vector2(900, 270)
	var exit_collision := CollisionShape2D.new()
	var exit_shape := CircleShape2D.new()
	exit_shape.radius = 42.0
	exit_collision.shape = exit_shape
	exit_area.add_child(exit_collision)
	exit_area.body_entered.connect(_on_exit_body_entered)
	add_child(exit_area)
	exit_hint = Label.new()
	exit_hint.text = "SALIDA CERRADA"
	exit_hint.position = Vector2(820, 205)
	exit_hint.size = Vector2(120, 28)
	exit_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exit_hint.add_theme_color_override("font_color", Color(0.55, 0.20, 0.16))
	add_child(exit_hint)

func _spawn_player() -> void:
	var lela := preload("res://gameplay/player/lela.tscn").instantiate()
	add_child(lela)
	lela.position = Vector2(120, 270)

func _spawn_enemies() -> void:
	var points: Array[Vector2] = [
		Vector2(560, 150), Vector2(700, 220), Vector2(590, 390), Vector2(790, 350)
	]
	if kind == "boss":
		points = [Vector2(720, 270)]
	for i in enemies_to_spawn.size():
		var eid := String(enemies_to_spawn[i])
		var e: Node2D = null
		match eid:
			"tin_soldier":
				e = preload("res://gameplay/enemies/tin_soldier.tscn").instantiate()
			"music_box":
				e = preload("res://gameplay/enemies/music_box.tscn").instantiate()
			"caja_cero":
				e = preload("res://gameplay/enemies/boss_caja_cero.tscn").instantiate()
		if e == null:
			continue
		e.set("drop_rng_seed", room_seed + i * 7919)
		add_child(e)
		e.position = points[i % points.size()]
		spawned.append(e)

func _on_exit_body_entered(body: Node) -> void:
	if is_cleared and body.is_in_group("player"):
		exit_reached.emit()

func _open_exit() -> void:
	if is_instance_valid(door_body):
		var collision := door_body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision:
			collision.set_deferred("disabled", true)
	if is_instance_valid(door_visual):
		door_visual.color = Color(0.35, 0.65, 0.35)
	if is_instance_valid(exit_hint):
		exit_hint.text = "SALIDA ABIERTA →"
		exit_hint.add_theme_color_override("font_color", Color(0.20, 0.55, 0.25))
	if is_instance_valid(exit_area):
		exit_area.monitoring = true
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if player and global_position.distance_to(player.global_position) < 60.0:
			call_deferred("_emit_exit_reached")

func _emit_exit_reached() -> void:
	exit_reached.emit()

func _mark_cleared() -> void:
	if is_cleared or not GameState.is_running:
		return
	is_cleared = true
	_open_exit()
	cleared.emit()
