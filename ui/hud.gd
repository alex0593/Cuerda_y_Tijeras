# HUD discreto: vida (hilo rojo), tensión (muelle), rewind (relojes), item activo.
extends CanvasLayer

@onready var life_bar: ProgressBar = $Top/Left/Life
@onready var tension_bar: ProgressBar = $Top/Left/Tension
@onready var rewind_label: Label = $Top/Left/Rewind
@onready var info: Label = $Top/Right/Info
@onready var toast: Label = $Toast

func _ready() -> void:
	GameState.tension_changed.connect(func(v): tension_bar.value = v)
	GameState.life_changed.connect(func(v): life_bar.value = v)
	GameState.rewind_charges_changed.connect(func(v): rewind_label.text = "⟲ x%d" % v)
	GameState.synergy_formed.connect(_on_synergy)
	life_bar.max_value = GameState.LIFE_MAX
	life_bar.value = GameState.life
	tension_bar.max_value = GameState.TENSION_MAX
	tension_bar.value = GameState.tension
	rewind_label.text = "⟲ x%d" % GameState.rewind_charges

func _process(_delta: float) -> void:
	info.text = "Sala %d  ⏱ %ds  ☠ %d  Hilos %d  Llaves %d" % [
		GameState.rooms_visited, int(GameState.run_time), GameState.kills, GameState.threads, GameState.keys
	]

func _on_synergy(sid: String) -> void:
	var d: Dictionary = SynergyDB.SYNERGIES.get(sid, {})
	toast.text = "Sinergia: %s" % String(d.get("name", sid))
	toast.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.6)
	t.tween_property(toast, "modulate:a", 0.0, 0.6)
