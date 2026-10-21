extends "res://tests/test_phase27_gui.gd"
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await frames();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://docs/evidence/fase27-3-"+name+".png")==OK,"real viewport "+name)
func approach_click(id: String) -> void:
	var actor: Node3D=world.narrative.actors[id]
	await click(root.get_camera_3d().unproject_position(actor.global_position+Vector3.UP))
	for i in 420:
		await physics_frame
		if world.narrative.view.visible: break
	check(world.narrative.view.visible and world.narrative.active_id==id,"native click and actual approach "+id)
func run() -> void:
	Input.use_accumulated_input=false;Engine.max_fps=60
	ProjectSettings.set_setting("aethel/world/vigilia_variant","SUMMER")
	Engine.set_meta("aethel_new_game",true)
	world=load("res://scenes/main.tscn").instantiate();root.add_child(world);await frames(8)
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=dimensions
		var suffix:="%dx%d"%[dimensions.x,dimensions.y]
		for variant: String in ["GREYBOX","SUMMER"]:
			ProjectSettings.set_setting("aethel/world/vigilia_variant",variant)
			world._update_region();world.player.position=Vector3(-4,0,5);root.get_camera_3d().snap_to_target();await frames(10)
			await shot(variant.to_lower()+"-plaza-"+suffix)
		await approach_click("doma")
		await press(KEY_ENTER)
		check(world.shop_panel.visible,"native Doma shop in Summer variant")
		await shot("doma-shop-"+suffix)
		await press(KEY_ESCAPE)
		if world.pause_menu.overlay.visible: world.pause_menu.resume()
		world.shop_panel.hide();world.narrative.close()
		await approach_click("maera")
		await shot("maera-dialogue-"+suffix)
		if not world.quest_started:
			await press(KEY_ENTER);await press(KEY_ENTER)
		world.narrative.close()
		check(world.quest_started,"mission remains accepted")
		await go(Vector3(3,0,7));await press(KEY_E)
		check(world.exploration.anchors.has("vigilia_anchor"),"native anchor activation")
		await shot("anchor-"+suffix)
		var close_button: Button=world.exploration.travel_panel.find_children("*","Button",true,false)[-1]
		await click(close_button.get_global_rect().get_center())
		check(not world.exploration.travel_panel.visible,"native close anchor menu")
		world.player.position=Vector3(-12,0,-12);root.get_camera_3d().snap_to_target();await frames(10);world.regions.tick(0.2)
		await shot("bell-occlusion-"+suffix)
		world.player.position=Vector3(-6,0,-10);root.get_camera_3d().set_zoom(18,false);root.get_camera_3d().snap_to_target();await frames(24)
		await shot("bell-detail-"+suffix)
		root.get_camera_3d().set_zoom(12,false);await frames(24)
		world.player.position=Vector3(8,0,-9);root.get_camera_3d().snap_to_target();await frames(10)
		await shot("east-street-"+suffix)
		world.player.position=Vector3(8,0,0);root.get_camera_3d().snap_to_target();await frames()
		await go(world.regions.connectors.map_01_to_map_02.position);await press(KEY_E)
		check(world.region_id=="map_02" and world.regions.allows_combat(),"native exit retains hostile policy")
		await frames()
		await go(world.regions.connectors.map_02_to_map_01.position);await press(KEY_E)
		check(world.region_id=="map_01" and world.regions.active_vigilia_variant=="SUMMER","native return restores hub variant")
		await press(KEY_F5);world.player.position=Vector3(0,0,4);await press(KEY_F9)
		check(world.region_id=="map_01" and world.regions.active_vigilia_variant=="SUMMER","native save load with architecture")
		await press(KEY_M);await shot("minimap-"+suffix);await press(KEY_M);await press(KEY_M)
	world.queue_free();await frames()
	for failure in failures: print("FALHA: "+failure)
	print("PHASE27.3 GUI: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
