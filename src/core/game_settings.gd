class_name AethelSettings
extends RefCounted

static var fullscreen := false
static var volume := 0.8
static var interact_key: Key = KEY_E

static func path() -> String:
	var directory := OS.get_environment("AETHEL_TEST_SAVE_DIR")
	return directory.path_join("settings.cfg") if not directory.is_empty() else "user://settings.cfg"

static func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(path()) == OK:
		fullscreen = bool(config.get_value("video", "fullscreen", false))
		volume = clampf(float(config.get_value("audio", "volume", 0.8)), 0, 1)
		interact_key = KEY_F if int(config.get_value("input", "interact", KEY_E)) == KEY_F else KEY_E
	apply()

static func apply() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, volume)))
	AudioServer.set_bus_mute(0, volume <= 0)
	AethelInput.bind_interact(interact_key)

static func save_settings() -> void:
	apply()
	var config := ConfigFile.new()
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("audio", "volume", volume)
	config.set_value("input", "interact", interact_key)
	config.save(path())
