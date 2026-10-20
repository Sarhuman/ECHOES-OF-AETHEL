extends SceneTree

func _initialize() -> void:
	AethelInput.ensure_defaults()
	for action: String in AethelInput.KEYS:
		ProjectSettings.set_setting("input/" + action, {"deadzone": 0.2, "events": InputMap.action_get_events(action)})
	for action: String in ["primary", "secondary"]:
		ProjectSettings.set_setting("input/" + action, {"deadzone": 0.2, "events": InputMap.action_get_events(action)})
	quit(0 if ProjectSettings.save() == OK else 1)
