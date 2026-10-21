extends SceneTree
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for index in count: await physics_frame
	await process_frame
func run() -> void:
	if DisplayServer.get_name()=="headless": printerr("Requires a graphical renderer");quit(1);return
	root.size=Vector2i(1920,1080)
	Engine.max_fps=60
	Engine.set_meta("aethel_new_game",true)
	var world: Node3D=load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await frames(10)
	world.quest_started=true
	var metrics: Dictionary={"renderer":RenderingServer.get_video_adapter_name(),"resolution":"1920x1080","frame_cap":60,"fixture":"Final compact HUD; AI movement/combat collision neutralized, floor collision retained"}
	for id: String in world.regions.definitions:
		world.region_id=id
		world._update_region()
		world.player.position={"map_01":Vector3(-4,0,5),"map_02":Vector3(-3,0,6),"map_03":Vector3(9,1.5,-7),"map_04":Vector3(0,0,10)}[id]
		for enemy in world.enemies: enemy.move_speed=0;enemy.collision_layer=0;enemy.collision_mask=1
		world.player.invulnerability=1000
		root.get_camera_3d().snap_to_target()
		await frames(15)
		var samples: Array[float]=[]
		for frame in 90:
			var start:=Time.get_ticks_usec()
			await process_frame
			samples.append((Time.get_ticks_usec()-start)/1000.0)
		samples.sort()
		metrics[id]={"frame_median_ms":samples[45],"frame_p95_ms":samples[85],"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"objects":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),"enemy_count":world.enemies.size()}
	var file:=FileAccess.open("res://docs/evidence/fase27-performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"  "));file.close()
	print("REGION PROFILE: "+JSON.stringify(metrics))
	world.queue_free()
	await frames(3)
	quit()
