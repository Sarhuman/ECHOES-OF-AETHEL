extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if DisplayServer.get_name()=="headless": quit(1);return
	var args:=OS.get_cmdline_user_args()
	if args.size()!=2 or args[1] not in ["GREYBOX","SUMMER"]: quit(1);return
	ProjectSettings.set_setting("aethel/world/vigilia_variant",args[1])
	Engine.set_meta("aethel_new_game",true);Engine.max_fps=60;root.size=Vector2i(1920,1080)
	var world: Node3D=load("res://scenes/main.tscn").instantiate();root.add_child(world)
	world.player.position=Vector3(-4,0,5);root.get_camera_3d().snap_to_target()
	for index in 30: await process_frame
	var samples: Array[float]=[]
	for index in 180:
		var start:=Time.get_ticks_usec();await process_frame;samples.append((Time.get_ticks_usec()-start)/1000.0)
	samples.sort()
	var mats: Dictionary={}
	for mesh: MeshInstance3D in world.find_children("*","MeshInstance3D",true,false):
		if not mesh.is_visible_in_tree() or mesh.mesh==null: continue
		for surface in mesh.mesh.get_surface_count():
			var mat: Material=mesh.get_active_material(surface)
			if mat!=null: mats[mat.get_instance_id()]=true
	var started:=Time.get_ticks_usec()
	for i in 100: world.regions.level.path(Vector3(0,0,4),Vector3(9,0,0))
	var nav_query_mean_us: float=(Time.get_ticks_usec()-started)/100.0
	var metrics: Dictionary={"variant":args[1],"renderer":RenderingServer.get_video_adapter_name(),"resolution":"1920x1080","fixture":"same idle hub at (-4,0,5), 30 warmup +180 frames, cap60; live physics; no enemies","median_ms":samples[90],"p95_ms":samples[171],"fps_from_median":1000.0/samples[90],"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),"video_memory_bytes":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED),"static_memory_bytes":OS.get_static_memory_usage(),"visible_mesh_materials":mats.size(),"lights":world.find_children("*","Light3D",true,false).size(),"cells":world.regions.level.cells.size(),"region_build_us":world.regions.level.build_usec,"mean_path_query_us":nav_query_mean_us}
	var file:=FileAccess.open(args[0],FileAccess.WRITE);file.store_string(JSON.stringify(metrics,"  "));file.close()
	print("VIGILIA PROFILE: "+JSON.stringify(metrics))
	world.queue_free();await process_frame;quit()
