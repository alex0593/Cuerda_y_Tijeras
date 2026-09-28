# Room — sala jugable con puertas a las vecinas, entrada segura y spawn por
# presupuesto. La sala no tiene jugadora: la mueve el mapa (game.gd) y conserva
# su estado (enemigos, botín y tienda) una vez visitada.
extends Node2D

signal cleared
signal activated
signal door_entered(direction: String)

const ROOM_SIZE := Vector2(960, 540)
const WALL := 20.0
const DOOR_GAP := 100.0
# El interior de la sala está diseñado en 960x540 y el nodo se escala al tamaño
# real de la sala. Así una sala más grande no obliga a rehacer la colocación de
# muros, cobertura, puertas, botín y taller: se escala todo junto.
const DESIGN := Vector2(960, 540)
const SCALE := Vector2(1728.0 / 960.0, 972.0 / 540.0)
# Dónde aparece la jugadora al entrar por cada puerta, ya dentro de la sala.
const ENTRY_SPOTS := {
	"left": Vector2(110, 270),
	"right": Vector2(850, 270),
	"up": Vector2(480, 110),
	"down": Vector2(480, 430),
}
# Dónde está el hueco de cada puerta, ya dentro de la sala.
const DOOR_SPOTS := {
	"left": Vector2(28, 270),
	"right": Vector2(932, 270),
	"up": Vector2(480, 28),
	"down": Vector2(480, 512),
}

@export var kind := "combat"
@export var template := "open"
var enemies_to_spawn: Array = []
var spawned: Array = []
var is_cleared := false
var is_active := false
var room_data: Dictionary = {}
var room_seed := 0
var grid_cell := Vector2i.ZERO
var doors: Array = []
var door_areas: Dictionary = {}
var door_bodies: Dictionary = {}
var door_labels: Dictionary = {}
var rng := RandomNumberGenerator.new()
# Estado recuperado del guardado: la sala se reconstruye sin enemigos si ya
# estaba despejada, y sin el botín que ya se recogió (doc 09 §10).
var saved_cleared := false
var saved_loot_taken: Array[int] = []
# Los botines que esta sala ha puesto en el suelo, para saber cuáles siguen
# ahí: un botín recogido es un nodo liberado.
var loot_nodes: Array = []
var _ready_done := false

func setup(room: Dictionary) -> void:
	if _ready_done:
		push_error("Room.setup() must be called before adding the room to the tree")
		return
	room_data = room.duplicate(true)
	kind = String(room.get("kind", "combat"))
	template = String(room.get("template", "open"))
	grid_cell = room.get("grid", Vector2i.ZERO)
	doors = (room.get("doors", []) as Array).duplicate()
	room_seed = int(room.get("seed", 0))
	rng.seed = room_seed if room_seed != 0 else int(Time.get_ticks_usec())
	enemies_to_spawn = (room.get("enemies", []) as Array).duplicate()
	position = room.get("position", Vector2.ZERO)
	# El interior sigue en el espacio de diseño; el escalado lleva la sala al
	# tamaño real del mapa.
	scale = SCALE

func _ready() -> void:
	_ready_done = true
	_spawn_walls()
	_spawn_cover()
	_spawn_doors()
	# Las salas sin enemigos quedan abiertas desde el principio.
	if enemies_to_spawn.is_empty():
		_mark_cleared()

# La sala cobra vida la primera vez que se entra: enemigos, botín y tienda se
# montan con lo que la jugadora lleve en ese momento (doc 07 §13).
func activate() -> void:
	if is_active:
		return
	is_active = true
	activated.emit()
	# Una sala que ya estaba despejada al guardar vuelve despejada y sin
	# enemigos: si no, al continuar aparecían de nuevo los que ya mataste.
	if saved_cleared:
		_mark_cleared()
		return
	_spawn_enemies()

# Estado de la sala para el guardado: qué se ha limpiado y qué botín queda.
func snapshot() -> Dictionary:
	var taken: Array = []
	for i in loot_nodes.size():
		var node = loot_nodes[i]
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			taken.append(i)
	return {"cleared": is_cleared, "loot_taken": taken}

func _process(_delta: float) -> void:
	if not is_active or is_cleared or not GameState.is_running:
		return
	for e in spawned:
		if is_instance_valid(e):
			return
	_mark_cleared()

func _spawn_walls() -> void:
	var color := Color(0.35, 0.30, 0.25)
	# Muros con hueco donde hay puerta: si no, no se podría salir de la sala.
	_wall(Vector2(480, -10), Vector2(960, WALL), doors.has("up"), true, color)
	_wall(Vector2(480, 550), Vector2(960, WALL), doors.has("down"), true, color)
	_wall(Vector2(-10, 270), Vector2(WALL, 560), doors.has("left"), false, color)
	_wall(Vector2(970, 270), Vector2(WALL, 560), doors.has("right"), false, color)

# Un muro con hueco centrado si en ese lado hay puerta.
func _wall(at: Vector2, size: Vector2, has_door: bool, horizontal: bool, color: Color) -> void:
	if not has_door:
		_spawn_static_box(at, size, color)
		return
	if horizontal:
		var segment := (size.x - DOOR_GAP) * 0.5
		_spawn_static_box(Vector2(at.x - size.x * 0.5 + segment * 0.5, at.y), Vector2(segment, size.y), color)
		_spawn_static_box(Vector2(at.x + size.x * 0.5 - segment * 0.5, at.y), Vector2(segment, size.y), color)
	else:
		var segment := (size.y - DOOR_GAP) * 0.5
		_spawn_static_box(Vector2(at.x, at.y - size.y * 0.5 + segment * 0.5), Vector2(size.x, segment), color)
		_spawn_static_box(Vector2(at.x, at.y + size.y * 0.5 - segment * 0.5), Vector2(size.x, segment), color)

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
	visual.polygon = PackedVector2Array([-half, Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)])
	visual.color = color
	body.add_child(visual)
	return body

# Cada puerta es un cierre que se abre al limpiar la sala y un hueco por el que
# se pasa a la vecina. El cierre no bloquea nunca el retour: al limpiarse queda
# abierto para siempre.
func _spawn_doors() -> void:
	for direction in doors:
		var dir := String(direction)
		var at: Vector2 = DOOR_SPOTS.get(dir, Vector2(480, 270))
		var vertical := dir == "left" or dir == "right"
		var body := StaticBody2D.new()
		body.collision_layer = 32
		body.collision_mask = 7
		body.position = at
		var collision := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(20, 120) if vertical else Vector2(120, 20)
		collision.shape = rectangle
		body.add_child(collision)
		var visual := Polygon2D.new()
		var half := Vector2(8, 60) if vertical else Vector2(60, 8)
		visual.polygon = PackedVector2Array([
			Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
			Vector2(half.x, half.y), Vector2(-half.x, half.y),
		])
		visual.color = Color(0.55, 0.20, 0.16)
		body.add_child(visual)
		add_child(body)
		door_bodies[dir] = body

		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 1
		area.monitoring = false
		area.position = at
		var area_collision := CollisionShape2D.new()
		var area_shape := CircleShape2D.new()
		area_shape.radius = 38.0
		area_collision.shape = area_shape
		area.add_child(area_collision)
		area.body_entered.connect(_on_door_body_entered.bind(dir))
		add_child(area)
		door_areas[dir] = area

		var label := Label.new()
		label.text = "CERRADA"
		label.size = Vector2(120, 26)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Color(0.75, 0.30, 0.25))
		label.position = at + (Vector2(0, -74) if vertical else Vector2(0, -50))
		add_child(label)
		door_labels[dir] = label

# Punto de aparición al entrar por una puerta concreta, en coordenadas de mundo:
# el interior está en el espacio de diseño, así que hay que aplicarle el
# escalado de la sala.
func entry_position(direction: String) -> Vector2:
	var at: Vector2 = ENTRY_SPOTS.get(direction, Vector2(480, 270))
	return Vector2(at.x * SCALE.x, at.y * SCALE.y)

func _on_door_body_entered(body: Node, direction: String) -> void:
	if is_cleared and body.is_in_group("player"):
		door_entered.emit(direction)

func _open_doors() -> void:
	for dir in door_areas.keys():
		var area = door_areas[dir] as Area2D
		if area and not area.monitoring:
			area.set_deferred("monitoring", true)
		var body = door_bodies[dir] as Node2D
		# Sin esto el cierre sigue bloqueando el paso y la puerta no se abre.
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision:
			collision.set_deferred("disabled", true)
		for child in body.get_children():
			if child is Polygon2D:
				(child as Polygon2D).color = Color(0.35, 0.65, 0.35)
		var label = door_labels[dir] as Label
		if label:
			label.text = "ABIERTA"
			label.add_theme_color_override("font_color", Color(0.20, 0.55, 0.25))

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
		# La sala se agranda para dar margen a la cámara, pero los enemigos
		# conservan su tamaño y su alcance: si no, crecerían con la sala y el
		# combate cambiaría sin tocar el balance.
		e.scale = Vector2.ONE / SCALE
		e.set("drop_rng_seed", room_seed + i * 7919)
		if eid == "caja_cero":
			# El jefe suelta un objeto que la jugadora no lleve ya (doc 07 §12.1).
			var boss_drop := RoomGenerator.boss_drop_for(room_data, GameState.items)
			if not boss_drop.is_empty():
				e.set("guaranteed_drop", "item:%s" % boss_drop)
				e.set("win_on_pickup", true)
		add_child(e)
		e.position = points[i % points.size()]
		spawned.append(e)

func _mark_cleared() -> void:
	if is_cleared or not GameState.is_running:
		return
	is_cleared = true
	_open_doors()
	cleared.emit()
