extends SceneTree
var world: Node3D
var checks := 0
var failures: Array[String]=[]
var metrics: Dictionary={}
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	checks+=1
	if not ok: failures.append(text)
func frames(count:=4) -> void:
	for i in count: await physics_frame
	await process_frame
func walk(to: Vector3,limit:=600) -> void:
	world.player.command_move(to)
	for i in limit:
		await physics_frame
		if not world.player.has_move_target: break
	await process_frame
func verify_offense() -> void:
	var actor: CharacterBody3D=world.player
	var target: CharacterBody3D=world._spawn_enemy(actor.position+Vector3(0,0,-1.4),1,0)
	target.set_physics_process(false)
	target.hp=99999;target.max_hp=99999;target.defense=0
	actor.facing=Vector3(0,0,-1)
	for id: String in ["heavy_strike","echo_cleave"]:
		actor.ether=actor.max_ether
		actor.attack_cooldown=0;actor.attack_recovery=0
		actor.skill_cooldowns.clear()
		var before: int=actor.ether
		var hp_before: int=target.hp
		for candidate in 100:
			seed(candidate)
			if randf()<0.5: seed(candidate); break
		check(actor.use_skill(world.skill_tree.catalog[id]).is_empty(),"offensive skill allowed at destination "+world.region_id+" "+id)
		check(target.hp<hp_before,"destination causes real damage "+world.region_id+" "+id)
		check(actor.ether==before-world.skill_tree.catalog[id].ether_cost,"destination spends actual cost "+id)
	actor.skills_changed.emit()
	check(not "Zona segura" in world.hud.skill_buttons[0].text and not "Zona segura" in world.hud.skill_buttons[2].text,"destination HUD clears safe text "+world.region_id)
	world.enemies.erase(target)
	target.queue_free()
	actor.attack_recovery=0;actor.attack_cooldown=0
	actor.clear_commands()

func freeze() -> void:
	for enemy in world.enemies:
		enemy.move_speed=0
		enemy.damage_min=0
		enemy.damage_max=0
	world.player.invulnerability=1000
func run() -> void:
	root.size=Vector2i(1280,720)
	Engine.set_meta("aethel_new_game",true)
	world=load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await frames(8)
	var visual: AethelCharacterVisual=world.player.get_node("BastiaoVisual")
	var actor_position: Vector3=world.player.position
	var actor_hp: int=world.player.hp
	var actor_shape: Shape3D=world.player.find_children("*","CollisionShape3D",false,false)[0].shape
	visual.replace_model(preload("res://scenes/characters/bastion_placeholder.tscn"))
	await frames()
	check(world.player.position.distance_to(actor_position)<0.05 and world.player.hp==actor_hp,"model replacement preserves actor position and health")
	check(world.player.find_children("*","CollisionShape3D",false,false)[0].shape==actor_shape,"model replacement preserves physical shape")
	check(world.player.has_node("PresentationAnchors/weapon") and world.player.has_node("PresentationAnchors/health"),"stable gameplay independent anchors")
	var presentation_toolbar: Control=world.hud.root.get_node("WorldToolbar")
	check(absf(presentation_toolbar.get_global_rect().end.x-world.regions.minimap.get_global_rect().end.x)<1,"toolbar aligned with minimap right edge")
	var manager: AethelRegionManager=world.regions
	check(manager.validate_graph().is_empty(),"graph destination scene arrival and reverse links")
	world.hud.set_xp(50,100)
	await frames()
	check(world.hud.xp_bar.value==50 and "50%" in world.hud.xp_text.text,"partial XP has real fill and adjacent percentage")
	check(world.hud.xp_bar.size.y<=8,"XP bar is thin")
	check(world.hud.resource_panel.size.x<=262 and world.hud.mission_tracker.size.x<=262,"compact left panels are about 260px")
	world.hud.set_xp(0,100)
	check(manager.definitions.size()==4,"four canonical initial regions")
	check(world.enemies.is_empty() and not manager.allows_combat(),"hub explicit safe policy no encounters")
	var ether: int=world.player.ether
	world.player._try_attack()
	check(world.player.attack_cooldown==0,"hub basic attack blocked")
	check(not world.player.use_skill(world.skill_tree.catalog.heavy_strike).is_empty() and world.player.ether==ether,"safe offensive skill preserves cost")
	check(world.narrative.available("doma") and world.narrative.available("maera"),"safe hub services available")
	world.player.position=Vector3(11,0,0)
	check(not manager.transition("map_01_to_map_02"),"quest unlock required")
	world.quest_started=true
	check(manager.transition("map_01_to_map_02"),"hub to district")
	check(not manager.transition("map_02_to_map_03"),"same frame transition guard")
	await frames()
	freeze()
	check(world.region_id=="map_02" and manager.origin=="map_01","origin and destination")
	check(world.player.position.distance_to(Vector3(0,0,9))<0.2,"stable destination arrival")
	var toolbar: Control=world.hud.root.get_node("WorldToolbar")
	for scale_value in [0.85,1.0,1.1]:
		AethelSettings.hud_scale=scale_value
		world.hud.apply_settings()
		await frames()
		for button in world.hud.skill_buttons: check(not button.get_global_rect().intersects(toolbar.get_global_rect()),"skill and toolbar rectangles separate at scale %s"%scale_value)
	AethelSettings.hud_scale=1.0
	world.hud.apply_settings()
	check(manager.connectors.size()==2 and not manager.connectors.has("map_02_to_map_04"),"no canonical courtyard bypass")
	check(world.enemies.size()==5,"phase25 encounter integrated")
	for group: Dictionary in world.exploration.data.encounters:
		if group.region=="map_02":
			for member: Dictionary in group.members: check(manager.point(member.position).distance_to(world.player.position)>=8,"arrival has eight meter encounter buffer")
	verify_offense()
	# Explicit round trip exercises safe policy on both transitions before reaching the dungeon.
	world.player.position=Vector3(0,0,12)
	check(manager.transition("map_02_to_map_01"),"policy regression return to hub")
	await frames()
	check(not manager.allows_combat(),"hub restrictions restored after return")
	world.player.position=Vector3(11,0,0)
	check(manager.transition("map_01_to_map_02"),"policy regression leave hub again")
	await frames()
	freeze()
	verify_offense()
	var start := Vector3(-3,0,0)
	var target := Vector3(8,0,0)
	world.player.position=start
	var path := manager.level.path(start,target)
	check(path.size()>10,"route detours around authored building")
	for waypoint in path: check(manager.level.valid_position(waypoint),"path stays on navigable floor")
	await walk(target)
	check(world.player.position.distance_to(target)<0.5,"CharacterBody follows detour without crossing walls")
	check(not manager.level.valid_position(Vector3(3,0,0)),"building excluded from navigation")
	world.player.command_move(Vector3(1000,0,1000))
	check(not world.player.has_move_target,"invalid automatic destination rejected")
	world.exploration.present_object_labels()
	var label_rects: Array[Rect2]=[]
	for label: Label in world.exploration.object_labels.values():
		if not label.visible: continue
		var rect:=label.get_global_rect()
		for other in label_rects: check(not rect.intersects(other),"nearby object labels separate")
		for button in world.hud.skill_buttons: check(not rect.intersects(button.get_global_rect()),"anchor and object labels clear skills")
		label_rects.append(rect)
	var cache: int=manager.reveal_updates
	manager.reveal()
	manager.reveal()
	check(manager.reveal_updates<=cache+1,"stationary fog avoids per-cell per-frame rebuild")
	check(not manager.discovered(Vector3(-14,0,-14)),"unvisited far area remains unknown")
	world.player.position=world.exploration.objects.district_anchor.position+Vector3(0,0,1)
	check(world.exploration.activate("district_anchor"),"real district anchor discovery")
	world.exploration.travel_panel.hide()
	world.player.position=Vector3(12,0,-13)
	check(manager.transition("map_02_to_map_03"),"district to canonical courtyard")
	await frames()
	freeze()
	world.player.position=Vector3(10,0,6)
	await frames()
	await walk(Vector3(10,1.5,-9),900)
	check(absf(world.player.position.y-1.5)<0.2 and world.player.position.z < -8.4,"real ramp ascent and gravity on terrace")
	manager.reveal()
	check(manager.active_floor==1,"height selects independent fog floor")
	var upper_key := manager.floor_key("map_03",1)
	check(manager.revealed.has(upper_key),"upper floor knowledge registered")
	check(not manager.revealed.get(manager.floor_key("map_03",0),{}).has("10,-9"),"upper floor not leaked into lower knowledge")
	var camera := root.get_camera_3d()
	camera.snap_to_target()
	await frames()
	var hit: Variant=world.ground_point_at(camera.unproject_position(Vector3(10,1.5,-7)))
	check(hit is Vector3 and hit.y>1.3,"ground ray preserves height")
	manager.tick(0.2)
	check(not manager._occluders.is_empty(),"nearby enemy torso occlusion fades the urban block")
	for mesh in manager._occluders: check(mesh.material_override.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA,"occlusion alpha material supports Compatibility")
	await walk(Vector3(10,0,6),900)
	check(absf(world.player.position.y)<0.2 and world.player.position.z>5.4,"ramp descent")
	world.player.position=Vector3(0,0,-14)
	check(manager.transition("map_03_to_map_04"),"courtyard to archive")
	await frames()
	freeze()
	verify_offense()
	check(manager.level.navigation.navigation_mesh.get_polygon_count()>100,"archive native 3D navigation geometry")
	check(manager.level.path(Vector3(0,0,14),Vector3(0,0,-14)).is_empty(),"closed door blocks route")
	world.player.position=Vector3(0,0,8)
	check(world.exploration.activate("archive_door"),"door distance and access")
	check(not manager.level.path(Vector3(0,0,14),Vector3(0,0,-14)).is_empty(),"door opens route")
	await walk(Vector3(0,0,-14),900)
	check(world.player.position.z < -13.4,"archive initial rooms reach future arena")
	check(manager.level.get_node_or_null("FuturePorteiroEvent")!=null,"future narrative hook without boss")
	for enemy in world.enemies.duplicate(): enemy.take_damage(999999)
	await frames()
	check(world.slain==0 and not world.map_02_cleared,"archive kills do not advance district investigation")
	world.player.position=world.exploration.objects.archive_reward.position+Vector3(0,0,1)
	check(world.exploration.activate("archive_reward"),"archive encounter reward")
	var drops: int=world.dropped_items.size()
	check(not world.exploration.activate("archive_reward") and world.dropped_items.size()==drops,"no duplicate reward")
	var inventory_snapshot: Dictionary=world.inventory.serialize()
	world._save_state()
	var saved_knowledge := manager.revealed.duplicate(true)
	check(world._load_state(),"world save load")
	await frames()
	freeze()
	check(world.region_id=="map_04" and manager.level.valid_position(world.player.position),"save restores region and valid position")
	var preserved := true
	for key: String in saved_knowledge:
		for cell: String in saved_knowledge[key]:
			if not manager.revealed.get(key,{}).has(cell): preserved=false
	check(preserved and manager.opened_doors.has("archive_door"),"knowledge and door persist")
	check(world.inventory.serialize()==inventory_snapshot and world.dropped_items.size()==drops,"save preserves inventory and drops once")
	check(world._load_state() and world.dropped_items.size()==drops,"repeat load cannot duplicate rewards")
	var payload: Dictionary=world._read_save_payload(world.SAVE_PATH)
	payload.position=[999,999,999]
	var file := FileAccess.open(world.SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(payload)); file.close()
	check(world._load_state() and world.player.position.distance_to(Vector3(0,0,14))<0.2,"invalid save position safe fallback")
	# Old v6 saves remain accepted without the optional world knowledge extension.
	payload.erase("world_regions")
	check(world._valid_save(payload),"legacy v6 accepted")
	for id: String in ["map_04_to_map_03","map_03_to_map_02","map_02_to_map_01"]:
		world.player.position=manager.connectors[id].position+Vector3(0,0,-1)
		check(manager.transition(id),"return link "+id)
		await frames()
	check(world.region_id=="map_01" and world.narrative.available("doma"),"complete sequence returns to accessible hub")
	for id: String in manager.definitions:
		manager.load_region(id)
		var row: Dictionary=manager.definitions[id]
		for entry: Array in row.entries.values(): check(manager.level.valid_position(manager.point(entry)),"arrival on navigation "+id)
		metrics[id]={"cells":manager.level.cells.size(),"build_ms":manager.level.build_usec/1000.0,"nodes":manager.level.find_children("*","",true,false).size()}
		var positions:=manager.level.decorative_positions.duplicate()
		manager.load_region(id)
		check(positions==manager.level.decorative_positions,"reproducible decoration "+id)
	var malformed: Dictionary=manager.serialize().duplicate(true)
	malformed.seed="bad"
	check(not manager.valid_state(malformed),"invalid world seed rejected")
	malformed=manager.serialize().duplicate(true)
	malformed.revealed={"map_99:0":{}}
	check(not manager.valid_state(malformed),"unknown fog region rejected")
	metrics["max_transition_ms"]=manager.max_transition_usec/1000.0
	world.exploration.restore({},true)
	check(world.exploration.killed.size()==5,"legacy cleared flag migrates only district encounters")
	check(not world.exploration.killed.has("map_04_guard_0"),"legacy migration preserves new dungeon encounters")
	print("PHASE27 METRICS: "+JSON.stringify(metrics))
	for failure in failures: print("FALHA: "+failure)
	world.queue_free()
	await frames()
	print("PHASE27: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
