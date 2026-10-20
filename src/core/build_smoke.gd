extends Node
## Opt-in release verification. Runs only with an isolated save directory.
var failures: Array[String] = []
var checks := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value: failures.append(description)

func frames(count: int) -> void:
	for index in count: await get_tree().physics_frame
	await get_tree().process_frame

func press(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)

func run() -> void:
	if OS.get_environment("AETHEL_TEST_SAVE_DIR").is_empty():
		printerr("BUILD SMOKE requires AETHEL_TEST_SAVE_DIR")
		get_tree().quit(1)
		return
	await frames(3)
	var world = get_parent()
	var player = world.player
	var camera := get_viewport().get_camera_3d()
	check(world.hud != null and world.hud.is_inside_tree(), "HUD loaded")
	check(camera != null and camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "orthographic camera")
	var start: Vector3 = player.position
	Input.action_press("move_right")
	await frames(15)
	Input.action_release("move_right")
	check(player.position.distance_to(start) > 0.2, "movement input")
	player.position = Vector3.ZERO
	player.clear_commands()
	var enemy = world._spawn_enemy(Vector3(0,0,-3),1,2)
	enemy.set_physics_process(false)
	enemy.hp = 9999
	enemy.max_hp = 9999
	enemy.defense = 0
	player.rng.seed = 5
	camera.snap_to_target()
	await frames(3)
	var head: Vector2 = camera.unproject_position(enemy.position + Vector3(0,2.13,0))
	check(world.pick_enemy_at(head) == enemy, "large enemy picking")
	world._on_left_press(head)
	world._on_left_release()
	await frames(180)
	check(enemy.hp < 9999, "click approach and attack")
	player.clear_commands()
	player.position = Vector3.ZERO
	enemy.position = Vector3(0,0,-1.5)
	player.attack_cooldown = 0
	player.attack_recovery = 0
	player.ether = player.max_ether
	player.attack_target = enemy
	var hp_before: int = enemy.hp
	await press(KEY_F1)
	check(enemy.hp < hp_before, "F1 damage")
	await press(KEY_F2)
	check(player.guard_remaining > 0, "F2 guard")
	player.attack_cooldown = 0
	player.attack_recovery = 0
	player.ether = player.max_ether
	hp_before = enemy.hp
	await press(KEY_F3)
	check(enemy.hp < hp_before, "F3 damage")
	check(world.merchant.get_node_or_null("InteractionArea") != null, "Doma interaction")
	world.pause_menu.open()
	check(get_tree().paused, "pause")
	get_tree().paused = false
	print("BUILD SMOKE: %d checks, %d failures" % [checks,failures.size()])
	for failure in failures: printerr("FALHA: ",failure)
	get_tree().quit(0 if failures.is_empty() else 1)
