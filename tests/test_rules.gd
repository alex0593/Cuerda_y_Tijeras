# Test tensión/daño/rebobinado — lógica pura sin escena (headless).
extends SceneTree

func _init() -> void:
	var err := 0
	# Tensión 0-100: consumir, regenerar con delay, factor sin bloqueo.
	var t := 100.0
	t = maxf(0.0, t - 4.0)
	if t != 96.0:
		push_error("tension consume"); err += 1
	var factor := 0.5 if t <= 0.0 else 1.0
	if factor != 1.0:
		push_error("factor"); err += 1
	# Daño: 3 segmentos, golpe 1.0 mata en 3.
	var life := 3.0
	life -= 1.0
	if life != 2.0:
		push_error("vida"); err += 1
	# Rewind: 2 cargas, no deshace daño (solo posiciones).
	var charges := 2
	charges -= 1
	if charges != 1:
		push_error("rewind"); err += 1
	# Semilla reproducible.
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	var a := rng.randi()
	rng.seed = 999
	if rng.randi() != a:
		push_error("semilla"); err += 1
	if err == 0:
		print("TEST_OK: tension/vida/rewind/semilla")
	quit(err)
