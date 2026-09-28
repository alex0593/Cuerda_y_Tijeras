# Captura del juego en la laptop, para verificar el encuadre y la interfaz sin
# instalar en el móvil. Necesita display: en headless el viewport no devuelve
# textura.
#
#   godot --path . --resolution 2412x1080 --script tools/screenshot.gd -- --out /tmp/juego.png
#   godot --path . --resolution 2412x1080 --script tools/screenshot.gd -- --room combat --seed 7919
#
# --room start   la sala de inicio, donde aparece la jugadora (por defecto)
#       combat   una sala de combate con enemigos despiertos
#       item     lo mismo, con una bobina de reparación y la vida a 1
# --out  ruta del PNG; por defecto user://screenshot.png
extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := _args()
	var out := String(args.get("out", "user://screenshot.png"))
	var run_seed := int(args.get("seed", 4242))
	var room_kind := String(args.get("room", "start"))

	var scene = load("res://gameplay/main/game.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.call("_start_new_run", run_seed)
	for i in 45:
		await process_frame
	var touch = get_first_node_in_group("touch") as CanvasLayer
	if touch != null:
		touch.visible = true
	match room_kind:
		"combat", "item":
			_enter_active_room(scene)
			if room_kind == "item":
				_prepare_item(scene)
	await create_timer(0.4).timeout
	_report(scene)
	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("sin textura: hace falta un display, no headless")
		quit(1)
		return
	var err := image.save_png(out)
	if err != OK:
		push_error("no se pudo guardar en %s (código %d)" % [out, err])
		quit(1)
		return
	print("captura guardada en ", ProjectSettings.globalize_path(out))
	quit(0)

# Despierta la primera sala con contenido, la activa y deja dentro a la jugadora.
func _enter_active_room(scene: Node) -> void:
	var state = root.get_node_or_null("GameState")
	var player = scene.get("player")
	for cell in (scene.get("rooms") as Dictionary):
		var room = (scene.get("rooms") as Dictionary)[cell]
		if String(room.get("kind")) == "start":
			continue
		room.call("activate")
		scene.call("_populate_room", room)
		player.global_position = room.global_position + Vector2(480.0 * room.scale.x, 270.0 * room.scale.y)
		return
	state  # el estado solo se usa para dejar la firma explícita

# Deja a la jugadora con vida baja y una bobina, para ver el botón de consumible.
func _prepare_item(scene: Node) -> void:
	var state = root.get_node_or_null("GameState")
	state.life = 1.0
	state.add_item("repair_coil")
	for i in 3:
		await process_frame

# Los números del encuadre: si esto cambia, el encuadre ha cambiado.
func _report(scene: Node) -> void:
	var cam = scene.get("camera")
	var view: Vector2 = scene.get_viewport_rect().size
	var room_size: Vector2 = scene.flow.get("room_size", Vector2.ZERO)
	var visible: Vector2 = view / cam.zoom
	var player = scene.get("player")
	var on_screen: Vector2 = (player.global_position - cam.get_screen_center_position()) * cam.zoom + view * 0.5
	print("viewport=%s zoom=%.3f visible=%s" % [str(view.round()), cam.zoom.x, str(visible.round())])
	print("sala=%s margen_h=%d margen_v=%d" % [
		str(room_size.round()), int(room_size.x - visible.x), int(room_size.y - visible.y)
	])
	print("jugadora=%s en_pantalla=%s de %s" % [str(player.global_position.round()), str(on_screen.round()), str(view.round())])
	print("la jugadora ocupa el %.1f%% del alto de la pantalla" % (36.0 * cam.zoom.y / view.y * 100.0))
	var touch = get_first_node_in_group("touch") as CanvasLayer
	if touch != null:
		var btn = touch.get_node_or_null("UseItem") as Button
		if btn != null:
			print("boton de consumible: visible=%s texto=%s deshabilitado=%s" % [btn.visible, btn.text, btn.disabled])

func _args() -> Dictionary:
	var out := {}
	var argv := OS.get_cmdline_user_args()
	var i := 0
	while i < argv.size():
		var token := String(argv[i])
		if token.begins_with("--"):
			var key := token.trim_prefix("--")
			if i + 1 < argv.size() and not String(argv[i + 1]).begins_with("--"):
				out[key] = argv[i + 1]
				i += 2
			else:
				out[key] = true
				i += 1
		else:
			i += 1
	return out
