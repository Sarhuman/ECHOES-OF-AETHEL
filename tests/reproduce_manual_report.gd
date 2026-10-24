extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await physics_frame
	await process_frame
	var player = world.player
	var camera := root.get_camera_3d()
	var enemy = world._spawn_enemy(player.position + Vector3(0,0,-1.3),1,2)
	enemy.set_physics_process(false)
	enemy.hp = 999
	enemy.max_hp = 999
	enemy.defense = 0
	await physics_frame
	var head := camera.unproject_position(enemy.global_position + Vector3(0,1.47 * 1.45,0))
	print("REPORT: zoom=",camera.size," head_click_selects=",world.pick_enemy_at(head) == enemy)
	var event := InputEventKey.new()
	event.keycode = KEY_F1
	event.pressed = true
	player.command_attack(enemy)
	player.rng.seed = 5
	world._unhandled_key_input(event)
	print("REPORT: F1_damage=",999 - enemy.hp," mana_spent=",player.max_ether - player.ether)
	print("REPORT: Doma_apron=",not world.get_node("DomaFerren").find_children("LeatherApron","Node3D",true,false).is_empty())
	quit(0)
