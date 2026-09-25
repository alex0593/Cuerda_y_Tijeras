# Note — nota orbital de Caja de música. El efecto cambia con trapped_notes.
extends Area2D

var player: Node2D = null
var orbit_angle := 0.0
var orbit_radius := 62.0
var orbit_speed := 2.4
var damage := 8.0
var pinned := false
var _hit_cooldowns: Dictionary = {}

func setup(p_player: Node2D, p_damage: float, p_pinned: bool) -> void:
	player = p_player
	damage = p_damage
	pinned = p_pinned
	if pinned:
		orbit_radius = 44.0
		orbit_speed = 1.4
		damage *= 1.5

func set_pinned(value: bool) -> void:
	if pinned == value:
		return
	pinned = value
	orbit_radius = 44.0 if pinned else 62.0
	orbit_speed = 1.4 if pinned else 2.4
	damage = 12.0 if pinned else 8.0

func _ready() -> void:
	monitoring = false
	monitorable = false
	add_to_group("music_note")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	orbit_angle += orbit_speed * delta
	global_position = player.global_position + Vector2.from_angle(orbit_angle) * orbit_radius
	for id in _hit_cooldowns.keys():
		_hit_cooldowns[id] = maxf(0.0, float(_hit_cooldowns[id]) - delta)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not (enemy is Node2D) or not enemy.has_method("take_hit"):
			continue
		var id := (enemy as Node).get_instance_id()
		if float(_hit_cooldowns.get(id, 0.0)) > 0.0:
			continue
		if global_position.distance_to((enemy as Node2D).global_position) < 20.0:
			_hit_cooldowns[id] = 0.6
			enemy.take_hit(damage * GameState.tension_factor(), "note", global_position)
