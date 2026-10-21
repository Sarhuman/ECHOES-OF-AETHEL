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
func settle() -> void:
	for enemy in world.enemies:
		enemy.collision_layer=0
		enemy.collision_mask=1 # Keep floor collision/gravity; only remove blocking against Player.
		enemy.move_speed=0
		enemy.damage_min=0
		enemy.damage_max=0
	world.player.invulnerability=1000
func go(point: Vector3) -> void:
	world.player.command_move(point)
	for i in 900:
		await physics_frame
		if not world.player.has_move_target: break
	await process_frame
	check(world.player.position.distance_to(point)<0.6,"walk route to %s got %s"%[point,world.player.position])
	print("GUI27 WALK ",world.region_id," ",point," got ",world.player.position)
func profile_region() -> Dictionary:
	var samples: Array[float]=[]
	for i in 90:
		var before:=Time.get_ticks_usec()
		await process_frame
		samples.append((Time.get_ticks_usec()-before)/1000.0)
	samples.sort()
	return {"frame_median_ms":samples[45],"frame_p95_ms":samples[85],"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"objects":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),"enemy_count":world.enemies.size()}
func run() -> void:
	Input.use_accumulated_input=false
	root.size=Vector2i(1280,720)
	Engine.max_fps=60
	Engine.set_meta("aethel_new_game",true)
	world=load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await frames(10)
	var manager: AethelRegionManager=world.regions
	var metrics: Dictionary={"renderer":RenderingServer.get_video_adapter_name(),"resolution":"1920x1080","frame_cap":60,"fixture":"AI movement frozen; original light/shader settings"}
	world.player.position=world.npc.position+Vector3(1,0,0)
	await press(KEY_E)
	await press(KEY_ENTER)
	await press(KEY_ENTER)
	check(world.quest_started,"native Maera acceptance")
	for entry: Array in [["inventory",KEY_I],["character",KEY_C],["quests",KEY_U],["help",KEY_H]]:
		await click(world.hud.quick_buttons[entry[0]].get_global_rect().get_center())
		var panel: Control={"inventory":world.inventory_view,"character":world.character_panel,"quests":world.quest_panel,"help":world.help_panel}[entry[0]]
		check(panel.visible,"compact menu click "+str(entry[0]))
		await press(entry[1])
		check(not panel.visible,"compact menu shortcut "+str(entry[0]))
	await click(world.hud.quick_buttons.pause.get_global_rect().get_center())
	check(paused,"compact pause click")
	world.pause_menu.resume()
	world.player.hp=50
	var potion_before: int=world.belt[0].count
	await click(world.hud.belt_labels[0].get_parent().get_global_rect().get_center())
	check(world.player.hp>50 and world.belt[0].count==potion_before-1,"compact potion click uses real belt")
	world.player.restore_full()
	await press(KEY_M)
	check(manager.minimap.expanded,"native map expands")
	await press(KEY_M)
	check(not manager.minimap.enabled,"native map hides")
	await press(KEY_M)
	check(manager.minimap.enabled and not manager.minimap.expanded,"native map restores compact")
	for region: String in ["map_01","map_02","map_03","map_04"]:
		settle()
		var camera:=root.get_camera_3d()
		if region=="map_01": world.player.position=Vector3(-4,0,5)
		if region=="map_02": world.player.position=Vector3(-3,0,6)
		if region=="map_03": world.player.position=Vector3(9,1.5,-7)
		if region=="map_04": world.player.position=Vector3(0,0,10)
		camera.snap_to_target()
		manager.reveal()
		await frames(5)
		for resolution: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
			root.size=resolution
			await frames(5)
			check(root.get_visible_rect().encloses(manager.minimap.get_global_rect()),"map fits "+region)
			var panels: Array[Control]=[world.hud.resource_panel,world.hud.mission_tracker,world.hud.action_row,manager.minimap,world.hud.root.get_node("WorldToolbar")]
			for first in panels.size():
				check(root.get_visible_rect().encloses(panels[first].get_global_rect()),"compact HUD viewport bounds "+region)
				for second in range(first+1,panels.size()): check(not panels[first].get_global_rect().intersects(panels[second].get_global_rect()),"compact HUD panels do not overlap "+region)
			await shot("fase27-%s-%dx%d"%[region,resolution.x,resolution.y])
		if DisplayServer.get_name()!="headless" and OS.get_environment("AETHEL_FAST_CAPTURE").is_empty(): metrics[region]=await profile_region()
		if region=="map_04": break
		var connector: String={"map_01":"map_01_to_map_02","map_02":"map_02_to_map_03","map_03":"map_03_to_map_04"}[region]
		# Approach uses actual path following; final portal action is native E.
		await go(manager.connectors[connector].position)
		await press(KEY_E)
		check(world.region_id!="" and world.region_id!=region,"native region connector "+connector)
		print("GUI27 TRANSITION ",connector," got ",world.region_id," message ",world.transient_message)
		if world.region_id==region:
			for failure in failures: print("FALHA: "+failure)
			quit(1)
			return
	world.progression.gain_xp(50)
	await frames()
	check(world.hud.xp_bar.value==50 and "50%" in world.hud.xp_text.text,"rendered partial XP")
	await shot("fase27-xp-parcial-1920x1080")
	root.size=Vector2i(1280,720)
	await shot("fase27-xp-parcial-1280x720")
	world.hud.set_xp(world.progression.current_xp,world.progression.required_xp(world.progression.current_level))
	# Door opens through native interaction, then click routes into the archive.
	world.player.position=Vector3(0,0,8)
	await press(KEY_E)
	check(world.exploration.used.has("archive_door"),"native archive door")
	settle()
	await go(Vector3(0,0,-10))
	await press(KEY_M)
	await shot("fase27-arquivo-mapa-expandido")
	await press(KEY_M)
	await press(KEY_M)
	await press(KEY_F5)
	var before: Vector3=world.player.position
	world.player.position=Vector3(0,0,14)
	await press(KEY_F9)
	check(world.region_id=="map_04" and world.player.position.distance_to(before)<0.3,"native save load restores archive")
	for connector: String in ["map_04_to_map_03","map_03_to_map_02","map_02_to_map_01"]:
		settle()
		await go(manager.connectors[connector].position)
		await press(KEY_E)
	check(world.region_id=="map_01","native return to hub")
	world.player.position=world.merchant.position+Vector3(2,0,1)
	await press(KEY_E)
	check(world.narrative.view.visible,"Doma after full circuit")
	await shot("fase27-retorno-doma")
	print("PHASE27 GRAPHICS METRICS: "+JSON.stringify(metrics))
	if DisplayServer.get_name()!="headless" and OS.get_environment("AETHEL_FAST_CAPTURE").is_empty():
		var folder:=OS.get_environment("AETHEL_CAPTURE_DIR")
		if not folder.is_empty():
			var file:=FileAccess.open(folder.path_join("fase27-performance.json"),FileAccess.WRITE)
			file.store_string(JSON.stringify(metrics,"  "));file.close()
	for failure in failures: print("FALHA: "+failure)
	world.queue_free()
	await frames()
	print("PHASE27 GUI: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
