class_name AethelSettings
extends RefCounted

static var loot_filters: Dictionary = {"common":true,"magic":true,"rare":true,"epic":true,"legendary":true,"gold":true,"consumable":true,"material":true}

static var channel_volumes: Dictionary = {"Music":0.6,"SFX":0.8,"UI":0.7,"Ambience":0.5}
static var hud_scale := 1.0
static var reduced_motion := false
static var shader_globes := true
static var window_size := Vector2i(1280,720)
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
		for key: String in loot_filters: loot_filters[key] = bool(config.get_value("loot",key,true))
		for bus: String in channel_volumes: channel_volumes[bus] = clampf(float(config.get_value("audio",bus,channel_volumes[bus])),0,1)
		hud_scale = clampf(float(config.get_value("interface","hud_scale",1)),0.85,1.1)
		reduced_motion = bool(config.get_value("interface","reduced_motion",false))
		shader_globes = bool(config.get_value("interface","shader_globes",true))
		var resolution: Variant = config.get_value("video","window_size",Vector2i(1280,720))
		window_size = resolution if resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)] else Vector2i(1280,720)
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
	AethelAudioManager.ensure_buses()
	for bus: String in channel_volumes:
		var index := AudioServer.get_bus_index(bus)
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(0.0001,float(channel_volumes[bus]))))
		AudioServer.set_bus_mute(index,float(channel_volumes[bus]) <= 0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, volume)))
	AudioServer.set_bus_mute(0, volume <= 0)
	AethelInput.bind_interact(interact_key)

static func save_settings() -> void:
	apply()
	var config := ConfigFile.new()
	config.set_value("video","window_size",window_size)
	for bus: String in channel_volumes: config.set_value("audio",bus,channel_volumes[bus])
	config.set_value("interface","hud_scale",hud_scale)
	config.set_value("interface","reduced_motion",reduced_motion)
	config.set_value("interface","shader_globes",shader_globes)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "remember_zoom", remember_zoom)
	config.set_value("video", "zoom", camera_zoom if remember_zoom else 12.0)
	config.set_value("audio", "volume", volume)
	config.set_value("input", "interact", interact_key)
	for key: String in loot_filters: config.set_value("loot",key,loot_filters[key])
	config.save(path())

static func apply_window_size() -> void:
	if DisplayServer.get_name() != "headless" and not fullscreen:
		DisplayServer.window_set_size(window_size)
