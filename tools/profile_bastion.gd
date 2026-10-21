extends SceneTree
## Reproducible idle-hub presentation benchmark, never a combat benchmark.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	root.size=Vector2i(1920,1080)
	Engine.max_fps=60
	Engine.set_meta("aethel_new_game",true)
	var world: Node3D=load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.player.position=Vector3(-4,0,5)
	root.get_camera_3d().snap_to_target()
	for index in 30: await process_frame
	var samples: Array[float]=[]
	for index in 180:
		var start:=Time.get_ticks_usec()
		await process_frame
		samples.append((Time.get_ticks_usec()-start)/1000.0)
	samples.sort()
	var metrics: Dictionary={"renderer":RenderingServer.get_video_adapter_name(),"resolution":"1920x1080","region":"map_01","position":[-4,0,5],"fixture":"idle hub, live physics, no enemies; cap 60; 30 warmup + 180 measured frames","median_ms":samples[90],"p95_ms":samples[171],"fps_from_median":1000.0/samples[90],"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),"video_memory_bytes":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED),"static_memory_bytes":OS.get_static_memory_usage(),"animation_skinning_cpu_ms":null}
	var arguments:=OS.get_cmdline_user_args()
	if arguments.size()!=1: quit(1); return
	var file:=FileAccess.open(arguments[0],FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"  "));file.close()
	print("BASTION PROFILE: "+JSON.stringify(metrics))
	world.queue_free()
	for index in 3: await process_frame
	quit()
