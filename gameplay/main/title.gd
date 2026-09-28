# Menú principal: donde empieza el juego. Sin cuentas ni configuración
# obligatoria: dos botones y el resto cuando haya algo que mostrar (doc 08 §2).
extends Control

@onready var continue_btn: Button = $Center/Buttons/Continue
@onready var new_btn: Button = $Center/Buttons/New
@onready var menu_btn: Button = $Center/Buttons/Menu
@onready var seed_label: Label = $Center/Seed
@onready var hint_label: Label = $Center/Hint

const GAME_SCENE := "res://gameplay/main/game.tscn"

func _ready() -> void:
	# El menú tiene que funcionar con el árbol parado: es lo primero que se ve.
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_btn_from_game()
	new_btn.pressed.connect(_on_new)
	continue_btn.pressed.connect(_on_continue)
	menu_btn.pressed.connect(_on_menu)
	menu_btn.visible = false
	_refresh()

# Si se está saliendo de una partida con el botón del menú, la partida se queda
# en un segundo plano y solo hay que quita paused. El botón solo aparece si de
# verdad había una partida en marcha.
func pause_btn_from_game() -> void:
	get_tree().paused = false
	GameState.resuming = false

func _refresh() -> void:
	var has_save: bool = SaveService.has_run()
	continue_btn.disabled = not has_save
	# Un botón apagado que no se distingue de uno activo es un botón que alguien
	# toca a ciegas. El tema por defecto apenas cambia el color.
	continue_btn.modulate = Color(1, 1, 1, 1) if has_save else Color(1, 1, 1, 0.4)
	# «Volver al menú» solo tiene sentido si había una partida en marcha: en el
	# menú no hay de dónde volver.
	menu_btn.visible = bool(GameState.is_running)
	seed_label.visible = has_save
	if has_save:
		seed_label.text = "Semilla %s  ·  %d hilos  ·  %d alfileres" % [
			SaveService.export_seed(), GameState.threads, GameState.alfilers
		]
	var names := _item_names()
	hint_label.visible = not names.is_empty()
	if not names.is_empty():
		hint_label.text = "Objetos: %s" % ", ".join(names)

func _item_names() -> PackedStringArray:
	var names := PackedStringArray()
	for item_id in GameState.items:
		var id := String(item_id)
		if id == "scissors_basic":
			continue
		names.append(String(SynergyDB.get_item(id).get("name", id)))
	return names

# Nueva partida: la que había guardada deja de existir, porque «Continuar»
# tendría que ofrecer un mapa que ya no tiene nada que ver.
func _on_new() -> void:
	SaveService.clear_run()
	GameState.map_state.clear()
	GameState.resuming = false
	_change_to_game()

# Continuar: se carga la partida y se marca que hay que seguir, para que la
# escena del juego la reanude en vez de empezar una nueva.
func _on_continue() -> void:
	if not SaveService.load_run():
		_refresh()
		return
	GameState.resuming = true
	_change_to_game()

# Volver al menú desde una partida en curso: la partida sigue guardada, así que
# «Continuar» la recoge tal cual.
func _on_menu() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://gameplay/main/title.tscn")

# Aplazado: los botones viven en la escena que se libera al cambiar.
func _change_to_game() -> void:
	get_tree().call_deferred("change_scene_to_file", GAME_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_menu()
