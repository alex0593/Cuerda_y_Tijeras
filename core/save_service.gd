# SaveService — guardado local versionado y portable (doc 09.10).
# Usa user://, sin rutas absolutas ni APIs de plataforma en el núcleo.
extends Node

const PROFILE_PATH := "user://profile.v1.json"
const SETTINGS_PATH := "user://settings.v1.json"
const RUN_PATH := "user://partida-a.v1.json"
const FORMAT_VERSION := 2

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
		"rewind_charges": GameState.rewind_charges,
		"items": GameState.items,
		"item_charges": GameState.item_charges,
		"synergies": GameState.synergies,
		"rooms_visited": GameState.rooms_visited,
		"kills": GameState.kills,
		"threads": GameState.threads,
		"alfilers": GameState.alfilers,
		"shop_open": GameState.shop_open,
		"run_time": GameState.run_time,
		"cause_of_death": GameState.cause_of_death,
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
	var parsed := _read_run_file(RUN_PATH)
	if not _valid_run_data(parsed):
		return _try_restore_backup()
	GameState.restore_run(parsed)
	return true

func has_run() -> bool:
	return FileAccess.file_exists(RUN_PATH)

func _read_run_file(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}

func _valid_run_data(data: Dictionary) -> bool:
	return (
		not data.is_empty()
		and int(data.get("version", 0)) == FORMAT_VERSION
		and int(data.get("generator_version", 0)) > 0
		and data.get("items", []) is Array
		and data.get("item_charges", {}) is Dictionary
		and data.get("synergies", []) is Array
	)

func _try_restore_backup() -> bool:
	var parsed := _read_run_file(RUN_PATH + ".bak")
	if not _valid_run_data(parsed):
		return false
	GameState.restore_run(parsed)
	return true

func load_run_backup(parsed: Dictionary) -> bool:
	if not _valid_run_data(parsed):
		return false
	GameState.restore_run(parsed)
	return true

func export_seed() -> String:
	return "%d-v%d" % [GameState.seed_value, GameState.generator_version]
