extends SceneTree
var checks:=0
var failures: Array[String]=[]
var actor: CharacterBody3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func frames(count:=4) -> void:
	for i in count: await physics_frame
	await process_frame
func move_towards(point: Vector3,limit:=240) -> void:
	for i in limit:
		await physics_frame
		var flat:=Vector3(point.x-actor.position.x,0,point.z-actor.position.z)
		if flat.length()<0.12: break
		actor.velocity=flat.normalized()*2.5;actor.velocity.y=-8
		actor.move_and_slide()
		actor.get_node("BastiaoVisual").set_motion(actor.velocity,flat.normalized(),1.0/60)
func run() -> void:
	root.size=Vector2i(1280,720)
	var stage:=load("res://art/imported/vigilia/integration_test.tscn").instantiate() as Node3D
	root.add_child(stage)
	check(str(stage.get_meta("source_engine","")).contains("custom_build"),"resource really authored by installed Summer build")
	check(stage.has_node("Floor") and stage.has_node("DoorLintel") and stage.has_node("Ramp"),"editable floor wall door ramp nodes survived round trip")
	var nav: NavigationRegion3D=stage.get_node("NavigationRegion3D")
	check(nav.navigation_mesh.get_polygon_count()==5,"navigation polygons survived round trip")
	actor=CharacterBody3D.new();actor.name="IsolatedTestActor";actor.collision_layer=2;actor.collision_mask=1
	var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=0.32;capsule.height=1.6;shape.shape=capsule;shape.position.y=0.8;actor.add_child(shape)
	var visual:=AethelCharacterVisual.new();visual.name="BastiaoVisual";visual.definition=load("res://data/characters/bastion_visual.tres");actor.add_child(visual)
	stage.add_child(actor);actor.position=Vector3(0,0.05,4)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=12
	camera.position=Vector3(12.25,12.25,12.25);stage.add_child(camera);camera.look_at(Vector3.ZERO);camera.current=true
	var environment:=WorldEnvironment.new();var settings:=Environment.new();settings.background_mode=Environment.BG_COLOR;settings.background_color=Color("191722");settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;settings.ambient_light_color=Color("b9bfce");settings.ambient_light_energy=0.7;environment.environment=settings;stage.add_child(environment)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-50,-30,0);light.shadow_enabled=true;stage.add_child(light)
	await frames(6)
	NavigationServer3D.map_force_update(nav.get_navigation_map())
	var path:=NavigationServer3D.map_get_path(nav.get_navigation_map(),Vector3(0,0,4),Vector3(0,1,-5.2),true)
	check(path.size()>=2,"native NavigationRegion3D path crosses doorway and ramp")
	for point: Vector3 in path: await move_towards(point)
	print("ISOLATED RAMP ARRIVAL: ",actor.position," path ",path)
	check(actor.position.z < -4.9 and absf(actor.position.y-1)<0.15,"matching hero capsule really traverses doorway and climbs ramp")
	await move_towards(Vector3(0,0,4))
	check(actor.position.z>3.7 and absf(actor.position.y)<0.15,"real ramp descent and return")
	actor.position=Vector3(3,0.05,1.5)
	await move_towards(Vector3(3,0,-2),100)
	check(actor.position.z>0.45,"wall blocks test capsule outside doorway")
	actor.position=Vector3(0,0,2)
	var metrics: Dictionary={"renderer":RenderingServer.get_video_adapter_name(),"headless":DisplayServer.get_name()=="headless","frames":90}
	if DisplayServer.get_name()!="headless":
		var samples: Array[float]=[]
		for i in 90:
			var start:=Time.get_ticks_usec();await process_frame;samples.append((Time.get_ticks_usec()-start)/1000.0)
		samples.sort();metrics.median_ms=samples[45];metrics.p95_ms=samples[85];metrics.draw_calls=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME);metrics.primitives=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
			root.size=dimensions;await frames();await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png("res://docs/evidence/fase27-3-isolated-%dx%d.png"%[dimensions.x,dimensions.y])==OK,"real rendered isolated scene "+str(dimensions))
	var report: Dictionary={"passed":failures.is_empty(),"checks":checks,"failures":failures,"scene":"Summer-authored integration_test.tscn","scene_sha256":FileAccess.get_sha256("res://art/imported/vigilia/integration_test.tscn"),"consumer_engine":Engine.get_version_info().string,"metrics":metrics,"scope":"isolated test actor, same capsule and visual; not a second gameplay controller"}
	var file:=FileAccess.open("res://docs/evidence/fase27-3-isolated-headless.json" if DisplayServer.get_name()=="headless" else "res://docs/evidence/fase27-3-isolated.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	for failure in failures: print("FALHA: "+failure)
	print("SUMMER ISOLATED: %d checks, %d failures"%[checks,failures.size()])
	stage.queue_free();await frames();quit(0 if failures.is_empty() else 1)
