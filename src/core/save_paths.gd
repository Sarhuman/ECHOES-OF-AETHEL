class_name AethelSavePaths
extends RefCounted

static func current() -> String:
	var test_dir := OS.get_environment("AETHEL_TEST_SAVE_DIR")
	if not test_dir.is_empty():
		return test_dir.path_join("aethel_phase13_save.json")
	return "user://aethel_phase13_save.json"
