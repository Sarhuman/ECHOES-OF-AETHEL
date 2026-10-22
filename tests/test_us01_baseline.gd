extends SceneTree
## Parsing and input regression for US-01; never uses the player's profile.
var failures: Array[String] = []
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func scan(folder: String) -> void:
	for filename in DirAccess.get_files_at(folder):
		if filename.ends_with(".gd"):
			var path := folder.path_join(filename)
			var script := load(path) as GDScript
			check(script != null and script.can_instantiate(), "parse script " + path)
	for directory in DirAccess.get_directories_at(folder): scan(folder.path_join(directory))

func press(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if OS.get_environment("AETHEL_TEST_SAVE_DIR").is_empty():
		printerr("US01 requires an isolated save directory")
		quit(1)
		return
	for folder in ["res://src", "res://scripts", "res://tests", "res://tools"]: scan(folder)
	var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	check(menu.is_inside_tree(), "initial menu loads")
	menu.queue_free()
	await process_frame
	var world: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	await physics_frame
	check(world.inventory_view is AethelInventoryView, "global inventory class loads")
	check(world.inventory_view.cells.size() > 0, "typed inventory buttons created")
	check(world.inventory_view.has_signal("equipment_drop_requested"), "public equipment signal preserved")
	world.gold = 321
	await press(KEY_F5)
	check(FileAccess.file_exists(AethelSavePaths.current()), "F5 writes isolated save")
	world.gold = 1
	await press(KEY_F9)
	check(world.gold == 321, "F9 restores existing save through input")
	check(not paused, "F9 does not pause standalone runtime")
	world.queue_free()
	await process_frame
	print("US01 BASELINE: %d checks, %d failures" % [checks, failures.size()])
	for failure in failures: printerr("FALHA: ", failure)
	quit(0 if failures.is_empty() else 1)

