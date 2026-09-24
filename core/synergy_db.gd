# SynergyDB — datos de objetos y sinergias (doc 05).
# Los números son de prueba. Balance en content/items.json (fuente editable).
extends Node

const ITEMS := {
	"scissors_basic": {"name": "Tijeras de taller", "slot": "weapon", "tags": ["cut"], "tension_cost": 4.0, "damage": 10.0, "fire_interval": 0.30, "projectile_speed": 420.0},
	"scissors_precision": {"name": "Tijeras de precisión", "slot": "weapon", "tags": ["cut", "precision"], "tension_cost": 4.0, "damage": 10.0, "fire_interval": 0.28, "projectile_speed": 460.0},
	"spring_jumper": {"name": "Resorte saltador", "slot": "mechanism", "tags": ["movement", "spring"], "tension_cost": 2.0, "dash_bonus": 40.0},
	"iron_magnet": {"name": "Imán de hierro", "slot": "mechanism", "tags": ["magnet", "metal"], "tension_cost": 0.0, "pickup_radius": 96.0},
	"music_box": {"name": "Caja de música", "slot": "amulet", "tags": ["music"], "tension_cost": 1.0, "orbit_damage": 8.0, "orbit_time": 3.0},
	"glass_eye": {"name": "Ojo de vidrio", "slot": "amulet", "tags": ["light", "reveal"], "tension_cost": 0.0, "crit_bonus": 0.15},
	"taut_thread": {"name": "Hilo tensado", "slot": "amulet", "tags": ["thread"], "tension_cost": 1.0, "bind_time": 0.8},
	"screws_cork": {"name": "Tornillos y corcho", "slot": "mechanism", "tags": ["bounce"], "tension_cost": 0.0, "bounces": 1},
	"toy_glue": {"name": "Pegamento de juguete", "slot": "amulet", "tags": ["glue"], "tension_cost": 0.0, "stick_time": 3.0},
	"repair_coil": {"name": "Bobina de reparación", "slot": "consumable", "tags": ["heal"], "tension_cost": 0.0, "heal": 1.0, "charges": 1},
}

# sinergia_id -> {needs: [item_a, item_b], name, effect}
const SYNERGIES := {
	"impulse_scissors": {"needs": ["scissors_precision", "spring_jumper"], "name": "Tijeras de impulso", "effect": "dash_attack_wave"},
	"living_stitches": {"needs": ["scissors_precision", "taut_thread"], "name": "Puntadas vivas", "effect": "thread_trail"},
	"magnet_recovery": {"needs": ["iron_magnet", "screws_cork"], "name": "Recuperación magnética", "effect": "returning_shots"},
	"clock_rhythm": {"needs": ["music_box", "spring_jumper"], "name": "Ritmo de reloj", "effect": "orbit_speed_dash"},
	"trapped_notes": {"needs": ["music_box", "taut_thread"], "name": "Notas atrapadas", "effect": "pinned_notes"},
	"revealing_light": {"needs": ["glass_eye", "shadow"], "name": "Luz reveladora", "effect": "reveal_outline"},
	"adhesive_orbit": {"needs": ["toy_glue", "screws_cork"], "name": "Órbita adhesiva", "effect": "orbiting_traps"},
	"impulse_repair": {"needs": ["spring_jumper", "repair_coil"], "name": "Reparación con impulso", "effect": "tension_to_dash"},
	"loaded_melody": {"needs": ["iron_magnet", "music_box"], "name": "Melodía cargada", "effect": "wide_orbit_damage"},
}

const MAX_RELATIONS_PER_ITEM := 2

func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})

func check_for_item(owned: Array, new_item: String) -> Array[String]:
	var out: Array[String] = []
	for sid in SYNERGIES.keys():
		var needs: Array = SYNERGIES[sid]["needs"]
		if new_item in needs:
			var other: String = needs[0] if needs[1] == new_item else needs[1]
			# "shadow" es etiqueta/enemigo, no objeto: no se forma por inventario.
			if other == "shadow":
				continue
			if other in owned and not sid in out:
				out.append(sid)
	return out

func validate_content() -> Array[String]:
	var errors: Array[String] = []
	for sid in SYNERGIES.keys():
		var needs: Array = SYNERGIES[sid]["needs"]
		for n in needs:
			if n != "shadow" and not n in ITEMS:
				errors.append("synergy %s needs unknown item %s" % [sid, n])
	for iid in ITEMS.keys():
		var d: Dictionary = ITEMS[iid]
		if not d.has("slot") or not d.has("tags"):
			errors.append("item %s missing slot/tags" % iid)
	return errors
