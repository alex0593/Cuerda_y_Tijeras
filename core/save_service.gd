# SaveService — guardado local versionado y portable (doc 09.10).
# Usa user://, sin rutas absolutas ni APIs de plataforma en el núcleo.
extends Node

const PROFILE_PATH := "user://profile.v1.json"
const SETTINGS_PATH := "user://settings.v1.json"
const RUN_PATH := "user://partida-a.v1.json"
const FORMAT_VERSION := 1

var settings := {
	"music_volume": 0.8, "sfx_volume": 0.9, "assist_aim": false,
	"auto_fire": false, "vibration": true, "high_contrast": false,
	"reduce_flashes": false, "joystick_scale": 1.0,
}
var profile := {"unlocked_items": ["scissors_basic"], "seen_synergies": [], "best_time": 0.0, "runs": 0}

func _ready() -> void:
	load_settings()
	load_profile()

func load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				for k in parsed.keys():
					if k in settings:
						settings[k] = parsed[k]

func save_settings() -> bool:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(settings))
	return true

func load_profile() -> void:
	if FileAccess.file_exists(PROFILE_PATH):
		var f := FileAccess.open(PROFILE_PATH, FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary and int(parsed.get("version", 0)) == FORMAT_VERSION:
				for k in parsed.keys():
					if k in profile:
						profile[k] = parsed[k]

func save_profile() -> bool:
	var data := profile.duplicate()
	data["version"] = FORMAT_VERSION
	var f := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	return true

func save_run() -> bool:
	if not GameState.is_running:
		return false
	var data := {
		"version": FORMAT_VERSION,
		"generator_version": GameState.generator_version,
		"seed": GameState.seed_value,
		"tension": GameState.tension,
		"life": GameState.life,
		"items": GameState.items,
		"synergies": GameState.synergies,
		"rooms_visited": GameState.rooms_visited,
		"run_time": GameState.run_time,
	}
	# Copia antes de migrar/sobrescribir (doc 09).
	if FileAccess.file_exists(RUN_PATH):
		var old := FileAccess.open(RUN_PATH, FileAccess.READ)
		if old:
			var bak := FileAccess.open(RUN_PATH + ".bak", FileAccess.WRITE)
			if bak:
				bak.store_string(old.get_as_text())
	var f := FileAccess.open(RUN_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	return true

func load_run() -> bool:
	if not FileAccess.file_exists(RUN_PATH):
		return false
	var f := FileAccess.open(RUN_PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary):
		return _try_restore_backup()
	if int(parsed.get("version", 0)) != FORMAT_VERSION:
		return _try_restore_backup()
	GameState.start_run(int(parsed.get("seed", 0)))
	GameState.tension = float(parsed.get("tension", 100.0))
	GameState.life = float(parsed.get("life", 3.0))
	GameState.items.assign(parsed.get("items", ["scissors_basic"]))
	GameState.synergies.assign(parsed.get("synergies", []))
	GameState.rooms_visited = int(parsed.get("rooms_visited", 0))
	GameState.run_time = float(parsed.get("run_time", 0.0))
	return true

func _try_restore_backup() -> bool:
	if FileAccess.file_exists(RUN_PATH + ".bak"):
		var f := FileAccess.open(RUN_PATH + ".bak", FileAccess.READ)
		if f:
			var parsed = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary and int(parsed.get("version", 0)) == FORMAT_VERSION:
				return load_run_backup(parsed)
	return false

func load_run_backup(parsed: Dictionary) -> bool:
	GameState.start_run(int(parsed.get("seed", 0)))
	return true

func export_seed() -> String:
	return "%d-v%d" % [GameState.seed_value, GameState.generator_version]
