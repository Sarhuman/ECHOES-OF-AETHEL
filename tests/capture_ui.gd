extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := OS.get_environment("AETHEL_CAPTURE_DIR").path_join(name + ".png")
	var error := root.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Falha na captura: " + path)
		quit(1)

func run() -> void:
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	await shot("menu")
	menu.queue_free()
	await process_frame
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	for resolution in [Vector2i(1280,720), Vector2i(1366,768), Vector2i(1280,800)]:
		root.size = resolution
		await shot("hud-%dx%d" % [resolution.x, resolution.y])
	root.size = Vector2i(1280,720)
	world.loot_generator.set_seed(2020)
	for quality in [0, 1, 2, 4]:
		world.inventory.add_item(world.loot_generator.roll_item(12, 1, 0, quality))
	world.inventory_view.refresh()
	world.inventory_view.visible = true
	world.character_panel.visible = true
	await shot("inventario-personagem")
	world.character_panel.visible = false
	world.skills_panel.visible = true
	await shot("habilidades")
	world.skills_panel.visible = false
	world.player.global_position = world.merchant.global_position + Vector3(2,0,1)
	root.get_camera_3d().snap_to_target()
	world.shop_panel.visible = true
	world._refresh_shop()
	await shot("loja")
	world.shop_panel.visible = false
	world.inventory_view.visible = false
	await shot("doma")
	world.help_panel.show()
	await shot("ajuda")
	world.help_panel.hide()
	world.player.ether = world.player.max_ether
	world._activate_skill("iron_guard")
	await physics_frame
	await physics_frame
	await shot("guarda-ativa")
	world.player.guard_remaining = 0
	world.quest_started = true
	world.region_id = "map_02"
	world._update_region()
	await shot("bairro")
	world.pause_menu.open()
	await shot("pausa")
	world.pause_menu.options.show()
	await shot("opcoes")
	world.pause_menu.resume()
	quit(0)
