class_name AethelInput
extends RefCounted

const KEYS: Dictionary = {
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
	"dodge": [KEY_SPACE], "interact": [KEY_E], "inventory": [KEY_I, KEY_TAB],
	"minimap": [KEY_M], "quests": [KEY_U], "character": [KEY_C], "skills": [KEY_K], "shop": [KEY_L], "pause": [KEY_ESCAPE],
	"potion_1": [KEY_1], "potion_2": [KEY_2], "potion_3": [KEY_3], "potion_4": [KEY_4],
	"skill_1": [KEY_F1], "skill_2": [KEY_F2], "skill_3": [KEY_F3],
	"attack_key": [KEY_J], "stand_attack": [KEY_SHIFT], "show_items": [KEY_ALT],
	"save": [KEY_F5], "load": [KEY_F9], "restart": [KEY_R], "block": [KEY_Q], "help": [KEY_H]
}

static func ensure_defaults() -> void:
	for action: String in KEYS:
		if InputMap.has_action(action): continue
		InputMap.add_action(action)
		for code: int in KEYS[action]:
			var event := InputEventKey.new()
			event.keycode = code
			InputMap.action_add_event(action, event)
	var mouse_actions: Dictionary = {"primary": MOUSE_BUTTON_LEFT, "secondary": MOUSE_BUTTON_RIGHT,
		"zoom_in": MOUSE_BUTTON_WHEEL_UP, "zoom_out": MOUSE_BUTTON_WHEEL_DOWN}
	for action: String in mouse_actions:
		if InputMap.has_action(action): continue
		InputMap.add_action(action)
		var event := InputEventMouseButton.new()
		event.button_index = mouse_actions[action]
		InputMap.action_add_event(action, event)

static func bind_interact(code: Key) -> void:
	ensure_defaults()
	InputMap.action_erase_events("interact")
	var event := InputEventKey.new()
	event.keycode = code
	InputMap.action_add_event("interact", event)
