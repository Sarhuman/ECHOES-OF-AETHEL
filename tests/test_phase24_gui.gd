extends SceneTree
var world: Node3D
var failures: Array[String] = []
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func frames(count: int = 4) -> void:
	for i in count: await process_frame
func press(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)
func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames()
	await RenderingServer.frame_post_draw
	var folder: String = OS.get_environment("AETHEL_CAPTURE_DIR")
	if not folder.is_empty():
		check(root.get_texture().get_image().save_png(folder.path_join(name+".png")) == OK,"save capture")
func run() -> void:
	root.size = Vector2i(1280,720)
	Engine.set_meta("aethel_new_game",true)
	world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await frames(30)
	world.player.position = world.merchant.position + Vector3(2,0,1)
	await frames(20)
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = resolution
		await frames(10)
		await shot("fase24-workshop-%dx%d" % [resolution.x,resolution.y])
		await press(KEY_E)
		check(world.narrative.view.visible,"E opens Doma dialogue")
		check(root.get_visible_rect().encloses(world.narrative.view.get_global_rect()),"dialogue fits viewport")
		await shot("fase24-dialogue-%dx%d" % [resolution.x,resolution.y])
		await press(KEY_DOWN)
		await press(KEY_ENTER)
		check(world.narrative.node_id == "doma_workshop","keyboard navigates response branch")
		await press(KEY_ESCAPE)
		check(not world.narrative.view.visible,"Esc closes dialogue before pause")
		check(not paused,"closing conversation does not pause game")
		world.gold = 1200
		await press(KEY_L)
		check(world.shop_panel.visible,"L opens shop")
		check(root.get_visible_rect().encloses(world.shop_panel.get_global_rect()),"shop fits viewport")
		var button: Button = world.shop_column.get_child(4)
		button.grab_focus()
		await frames()
		check(world.shop_tooltip.visible,"keyboard focus opens comparison tooltip")
		await shot("fase24-shop-%dx%d" % [resolution.x,resolution.y])
		var before: int = world.gold
		await press(KEY_ENTER)
		check(world.gold < before,"native Enter purchases real item")
		await press(KEY_L)
		world.shop_tooltip.hide_item()
		check(not world.shop_panel.visible,"L closes shop")
	world.queue_free()
	await frames()
	for message in failures: print("FALHA: " + message)
	print("PHASE24 GUI: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
