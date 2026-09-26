# HUD discreto: vida (hilo rojo), tensión (muelle), rewind (relojes), item activo.
extends CanvasLayer

@onready var life_bar: ProgressBar = $Top/Left/Life
@onready var tension_bar: ProgressBar = $Top/Left/Tension
@onready var rewind_label: Label = $Top/Left/Rewind
@onready var inventory_label: Label = $Top/Left/Inventory
@onready var info: Label = $Top/Right/Info
@onready var toast: Label = $Toast

func _ready() -> void:
	GameState.tension_changed.connect(func(v): tension_bar.value = v)
	GameState.life_changed.connect(func(v): life_bar.value = v)
	GameState.rewind_charges_changed.connect(func(v): rewind_label.text = "⟲ x%d" % v)
	GameState.inventory_changed.connect(_refresh_inventory)
	GameState.synergy_formed.connect(_on_synergy)
	GameState.notice.connect(_on_notice)
	life_bar.max_value = GameState.LIFE_MAX
	life_bar.value = GameState.life
	tension_bar.max_value = GameState.TENSION_MAX
	tension_bar.value = GameState.tension
	rewind_label.text = "⟲ x%d" % GameState.rewind_charges
	_refresh_inventory()

func _refresh_inventory() -> void:
	var weapon: Array = GameState.get_slot_items("weapon")
	var mechanism: Array = GameState.get_slot_items("mechanism")
	var amulet: Array = GameState.get_slot_items("amulet")
	var consumable: Array = GameState.get_slot_items("consumable")
	inventory_label.text = "A:%s  M:%s  P:%s  C:%d" % [
		_format_items(weapon),
		_format_items(mechanism),
		_format_items(amulet),
		GameState.get_slot_charges("consumable")
	]

func _format_items(items: Array) -> String:
	if items.is_empty():
		return "-"
	var result := ""
	for i in items.size():
		if i > 0:
			result += " / "
		var item_id := String(items[i])
		result += String(SynergyDB.get_item(item_id).get("name", item_id))
	return result

func _process(_delta: float) -> void:
	info.text = "Sala %d  ⏱ %ds  ☠ %d  Hilos %d  Alfileres %d" % [
		GameState.rooms_visited, int(GameState.run_time), GameState.kills, GameState.threads, GameState.alfilers
	]

func _on_synergy(sid: String) -> void:
	var d: Dictionary = SynergyDB.get_synergy(sid)
	_show_toast("Sinergia: %s" % String(d.get("name", sid)))

func _on_notice(text: String) -> void:
	_show_toast(text)

func _show_toast(text: String) -> void:
	toast.text = text
	toast.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.6)
	t.tween_property(toast, "modulate:a", 0.0, 0.6)
