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
func hover(point: Vector2) -> void:
	var event:=InputEventMouseMotion.new()
	event.position=root.get_final_transform()*point
	event.global_position=event.position
	Input.parse_input_event(event)
	await frames(3)
func run() -> void:
	Input.use_accumulated_input=false
	root.size=Vector2i(1280,720)
	Engine.set_meta("aethel_new_game",true)
	world=load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await frames(10)
	for enemy in world.enemies: enemy.set_physics_process(false)
	for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		root.size=resolution
		for scale_value in [0.85,1.0,1.1]:
			AethelSettings.hud_scale=scale_value
			world.hud.apply_settings()
			await frames(5)
			check(root.get_visible_rect().encloses(world.hud.resource_panel.get_global_rect()),"resource bounds %s %s"%[resolution,scale_value])
		await shot("fase26-hud-%dx%d"%[resolution.x,resolution.y])
	root.size=Vector2i(1280,720)
	AethelSettings.hud_scale=1.0
	world.hud.apply_settings()
	for row: Dictionary in world.inventory.entries(): world.inventory.remove_item(row.instance.instance_id)
	var item:=AethelItemInstance.new(world.item_catalog.wood_shield,"gui-discard")
	item.custom_name="Eco de Vidro"
	item.quality=AethelItemData.Rarity.RARE
	world.inventory.add_item(item)
	world._refresh_all()
	await press(KEY_I)
	await frames()
	var button: AethelInventoryItemButton
	for candidate in world.inventory_view.find_children("*","Button",true,false):
		if candidate is AethelInventoryItemButton and candidate.uid==item.instance_id: button=candidate
	check(button!=null,"bag item button")
	if button!=null:
		await hover(button.get_global_rect().get_center())
		var tooltip: AethelItemTooltip=world.inventory_view.tooltip
		check(tooltip.visible,"native hover opens glass tooltip")
		var rect:=tooltip.get_global_rect()
		for i in 60:
			await process_frame
			check(tooltip.visible and tooltip.get_global_rect()==rect,"stationary native tooltip")
		await shot("fase26-inventario-tooltip")
		button.grab_focus()
		await press(KEY_DELETE)
		check(world.inventory.find_item(item.instance_id)==null,"native Delete discards selected bag item")
		var found:=false
		for drop in world.dropped_items:
			if drop.item!=null and drop.item.instance_id==item.instance_id: found=true
		check(found,"discard exists on ground")
	world.inventory_view.hide()
	world.player.position=world.merchant.position+Vector3(1,0,0)
	world.shop_panel.show()
	world._refresh_shop()
	await frames()
	var shield: Button
	for candidate in world.shop_panel.find_children("*","Button",true,false):
		if "Escudo de Madeira" in candidate.text: shield=candidate
	check(shield!=null,"blacksmith shield button")
	if shield!=null:
		await hover(shield.get_global_rect().get_center())
		var rect: Rect2=world.shop_tooltip.get_global_rect()
		for i in 60:
			await process_frame
			check(world.shop_tooltip.visible and world.shop_tooltip.get_global_rect()==rect,"native shop tooltip stable")
		await shot("fase26-ferreiro-tooltip")
	world.shop_panel.hide()
	world.shop_tooltip.hide_item()
	await press(KEY_U)
	check(world.quest_panel.visible,"native journal shortcut")
	await shot("fase26-diario")
	world.quest_panel.hide()
	await press(KEY_ESCAPE)
	check(paused,"native pause shortcut")
	await shot("fase26-pausa")
	world.pause_menu.resume()
	world.queue_free()
	await frames()
	for failure in failures: print("FALHA: "+failure)
	print("PHASE26 GUI: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
