class_name AethelSettings
extends RefCounted

static var fullscreen := false
static var volume := 0.8
static var camera_zoom := 12.0
static var remember_zoom := true
static var interact_key: Key = KEY_E

static func path() -> String:
	var directory := OS.get_environment("AETHEL_TEST_SAVE_DIR")
	return directory.path_join("settings.cfg") if not directory.is_empty() else "user://settings.cfg"

static func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(path()) == OK:
		remember_zoom = bool(config.get_value("video", "remember_zoom", true))
		camera_zoom = clampf(float(config.get_value("video", "zoom", 12)), 10, 18) if remember_zoom else 12.0
		fullscreen = bool(config.get_value("video", "fullscreen", false))
		volume = clampf(float(config.get_value("audio", "volume", 0.8)), 0, 1)
		interact_key = KEY_F if int(config.get_value("input", "interact", KEY_E)) == KEY_F else KEY_E
	apply()

static func apply() -> void:
	if DisplayServer.get_name() != "headless":
		var desired := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != desired: DisplayServer.window_set_mode(desired)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, volume)))
	AudioServer.set_bus_mute(0, volume <= 0)
	AethelInput.bind_interact(interact_key)

static func save_settings() -> void:
	apply()
	var config := ConfigFile.new()
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "remember_zoom", remember_zoom)
	config.set_value("video", "zoom", camera_zoom if remember_zoom else 12.0)
	config.set_value("audio", "volume", volume)
	config.set_value("input", "interact", interact_key)
	config.save(path())
