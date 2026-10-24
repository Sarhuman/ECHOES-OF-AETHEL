extends SceneTree
var checks := 0
var failures: Array[String] = []
var world: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func frames(count: int = 4) -> void:
	for i in count: await physics_frame
	await process_frame
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
func click(position: Vector2) -> void:
	position = root.get_final_transform() * position
	for pressed: bool in [true,false]:
		var move := InputEventMouseMotion.new()
		move.position = position
		move.global_position = position
		move.button_mask = MOUSE_BUTTON_MASK_LEFT if not pressed else 0
		Input.parse_input_event(move)
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = position
		event.global_position = position
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames(2)
func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames()
	await RenderingServer.frame_post_draw
	var folder := OS.get_environment("AETHEL_CAPTURE_DIR")
	if not folder.is_empty(): check(root.get_texture().get_image().save_png(folder.path_join(name+".png")) == OK,"capture "+name)
func run() -> void:
	Input.use_accumulated_input = false
	root.size = Vector2i(1280,720)
	Engine.set_meta("aethel_new_game",true)
	world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await frames(10)
	var ex: AethelExploration = world.exploration
	world.player.position = world.npc.position + Vector3(1,0,0)
	await press(KEY_E)
	await press(KEY_ENTER)
	await press(KEY_ENTER)
	check(world.quest_started,"accept Maera investigation via native keyboard")
	world.player.position = ex.objects.vigilia_anchor.position+Vector3(0,0,1)
	await press(KEY_E)
	check("vigilia_anchor" in ex.anchors and ex.travel_panel.visible,"native E discovers anchor")
	await press(KEY_ESCAPE)
	check(not ex.travel_panel.visible and not paused,"Esc closes travel before pause")
	world.player.position = world.gate.position+Vector3(-1,0,0)
	await press(KEY_E)
	check(world.region_id == "map_02","native E crosses existing portal")
	for enemy in world.enemies: enemy.set_physics_process(false)
	var camera := root.get_camera_3d()
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = resolution
		world.player.position = Vector3(-4,0,6)
		camera.snap_to_target()
		await frames(5)
		await shot("fase25-encounter-%dx%d" % [resolution.x,resolution.y])
	world.player.position = Vector3(0,0,8)
	camera.snap_to_target()
	await frames()
	var object_screen: Vector2 = camera.unproject_position(ex.objects.district_chest.position+Vector3(0,0.5,0))
	check(ex.pick(object_screen) == "district_chest","camera selects container")
	await click(object_screen)
	for i in 180:
		await physics_frame
		if ex.used.has("district_chest"): break
	check(ex.used.has("district_chest"),"native click approaches and opens chest")
	# Real defeated enemies provide loot for presentation and collection checks.
	for enemy in world.enemies.duplicate(): enemy.take_damage(enemy.hp*2)
	await frames(60)
	await frames()
	check(world.dropped_items.size() > 0,"real encounter has ground rewards")
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = resolution
		world.player.position = Vector3(-6,0,4)
		camera.snap_to_target()
		await frames(8)
		Input.action_press("show_items")
		await frames(4)
		var rects: Array[Rect2] = []
		for row: Dictionary in ex.labels.values():
			if not row.label.visible: continue
			var rect: Rect2 = row.label.get_global_rect()
			for other: Rect2 in rects: check(not rect.intersects(other),"ground names do not overlap")
			rects.append(rect)
		await shot("fase25-loot-%dx%d" % [resolution.x,resolution.y])
		Input.action_release("show_items")
		await press(KEY_O)
		check(ex.filter_panel.visible,"native O opens filter")
		var gold_check: CheckButton = ex.filter_panel.get_child(0).get_child(6)
		await click(gold_check.get_global_rect().get_center())
		check(not AethelSettings.loot_filters.gold,"native filter toggles gold")
		var ground_gold := 0
		for drop in world.dropped_items:
			if drop.is_gold():
				ground_gold += 1
				check(not drop.visible,"filtered gold remains hidden")
		check(world.dropped_items.size() > 0,"filter never deletes ground rewards")
		await shot("fase25-filter-%dx%d" % [resolution.x,resolution.y])
		await click(gold_check.get_global_rect().get_center())
		await press(KEY_O)
	var chosen: AethelDroppedItem
	for drop: AethelDroppedItem in world.dropped_items:
		if drop.item != null and drop.item.definition.kind == "equipment": chosen = drop; break
	check(chosen != null,"equipment available for native collection")
	world.player.position = chosen.position+Vector3(0.6,0,0)
	camera.snap_to_target()
	Input.action_press("show_items")
	await frames(8)
	var chosen_id: String = chosen.item.instance_id
	var chosen_slot: String = world.player.slot_for(chosen.item)
	await click(ex.labels[chosen.get_instance_id()].label.get_global_rect().get_center())
	await frames(10)
	check(world.inventory.find_item(chosen_id) != null and not is_instance_valid(chosen),"native click collects actual ground equipment")
	Input.action_release("show_items")
	world.player.position = ex.objects.district_altar.position+Vector3(0,0,1)
	await press(KEY_E)
	check(world.player.exploration_reduction > 0,"native E activates altar")
	world.player.position = ex.objects.district_well.position+Vector3(0,0,1)
	world.player.hp = 20
	await press(KEY_E)
	check(world.player.hp > 20,"native E uses well")
	world.player.position = ex.objects.district_anchor.position+Vector3(0,0,1)
	await press(KEY_E)
	check("district_anchor" in ex.anchors,"native E discovers hostile anchor")
	var destination: Button = ex.travel_panel.get_child(0).get_child(1)
	await click(destination.get_global_rect().get_center())
	check(world.region_id == "map_01","native travel destination returns hub")
	await press(KEY_I)
	check(world.inventory_view.visible,"inventory available after exploration")
	world.inventory_view.item_root.get_child(0).grab_focus()
	await press(KEY_ENTER)
	check(world.player.equipped.has(chosen_slot) and world.player.equipped[chosen_slot].instance_id == chosen_id,"native inventory equips explored reward")
	await press(KEY_I)
	await press(KEY_F5)
	var count: int = world.dropped_items.size()
	await press(KEY_F9)
	check(world.dropped_items.size() == count and ex.killed.size() == 5,"native save/load preserves exploration")
	world.queue_free()
	await frames()
	for message in failures: print("FALHA: "+message)
	print("PHASE25 GUI: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
