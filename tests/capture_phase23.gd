extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func shot(name: String) -> void:
	for index in 4: await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(OS.get_environment("AETHEL_CAPTURE_DIR").path_join(name+".png")) != OK: quit(1)

func run() -> void:
	Engine.set_meta("aethel_new_game",true)
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	world.loot_generator.set_seed(2300)
	for index in 9:
		var enemy = world._spawn_enemy(Vector3(2,0,0),1,1)
		enemy.take_damage(99999)
		for drop in world.dropped_items.duplicate():
			if is_instance_valid(drop):
				world.player.position = drop.position + Vector3(0.5,0,0)
				world._collect_drop(drop)
		await process_frame
	world.inventory.auto_sort()
	world.inventory_view.show()
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = resolution
		world.inventory_view.tooltip.hide_item()
		await shot("fase23-loot-inventory-%dx%d" % [resolution.x,resolution.y])
		if world.inventory_view.item_root.get_child_count() > 0:
			world.inventory_view.item_root.get_child(0).grab_focus()
			await shot("fase23-comparison-%dx%d" % [resolution.x,resolution.y])
	world.queue_free()
	await process_frame
	root.size = Vector2i(1280,720)
	var panel := PanelContainer.new()
	root.add_child(panel)
	panel.position = Vector2(35,25)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = "FASE 23 · 43 ÍCONES VETORIAIS PRÓPRIOS — PLACEHOLDERS"
	column.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 10
	column.add_child(grid)
	var catalog := AethelItemCatalog.create_catalog()
	for id in AethelItemIcons.TEXTURES:
		var cell := VBoxContainer.new()
		cell.custom_minimum_size.x = 112
		grid.add_child(cell)
		var icon := TextureRect.new()
		icon.texture = AethelItemIcons.TEXTURES[id]
		icon.custom_minimum_size = Vector2(64,64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.add_child(icon)
		var label := Label.new()
		label.text = catalog[id].display_name if catalog.has(id) else str(id)
		label.custom_minimum_size = Vector2(112,26)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size",11)
		cell.add_child(label)
	await shot("fase23-icon-catalog")
	quit()
