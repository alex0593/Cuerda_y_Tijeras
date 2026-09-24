# Validador ejecutable en Godot headless: comprueba sinergias y generación.
extends SceneTree

func _init() -> void:
	var err := 0
	var syn = load("res://core/synergy_db.gd").new()
	var gen = load("res://core/room_generator.gd").new()
	for e in syn.validate_content():
		push_error(e)
		err += 1
	var run: Dictionary = gen.generate_run(12345)
	if (run["rooms"] as Array).size() != 6:
		push_error("flow debe tener 6 salas")
		err += 1
	for r in run["rooms"]:
		for e in gen.validate_room(r):
			push_error(e)
			err += 1
	# Sinergia conocida: tijeras+resorte
	var formed: Array = syn.check_for_item(["scissors_precision"], "spring_jumper")
	if not "impulse_scissors" in formed:
		push_error("falta sinergia impulse_scissors")
		err += 1
	syn.free()
	gen.free()
	if err == 0:
		print("VALIDATE_OK: sinergias + generación")
	quit(err)
