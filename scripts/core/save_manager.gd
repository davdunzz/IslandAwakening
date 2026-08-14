extends Node

const SAVE_PATH := "user://island_save.json"
const SETTINGS_PATH := "user://settings.json"
var settings := {"master": 0.85, "music": 0.65, "sensitivity": 0.0022, "quality": 1, "fullscreen": false, "vsync": true}

func _ready() -> void:
	load_settings()
	apply_settings()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game(player: Node = null) -> void:
	var data := MissionManager.serialize_state()
	if is_instance_valid(player):
		data.player_position = [player.global_position.x, player.global_position.y, player.global_position.z]
		data.health = player.health
		data.inventory = player.inventory
		data.weapon_slot = player.weapon_slot
		data.unlocked_weapons = player.weapon_system.unlocked
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(data, "\t"))

func load_game() -> Dictionary:
	if not has_save(): return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file else null
	return parsed if parsed is Dictionary else {}

func delete_save() -> void:
	if has_save(): DirAccess.remove_absolute(SAVE_PATH)

func save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(settings, "\t"))
	apply_settings()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH): return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file else null
	if parsed is Dictionary:
		for key in parsed: settings[key] = parsed[key]

func apply_settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(float(settings.master)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(float(settings.music)))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.vsync else DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	var viewport := get_viewport()
	if viewport:
		viewport.scaling_3d_scale = [0.65, 0.82, 1.0][clampi(int(settings.quality), 0, 2)]
