extends SceneTree
var world: Node3D
var checks:=0
var failures: Array[String]=[]
var resolution: String
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func frames(count:=4) -> void:
	for i in count: await physics_frame
	await process_frame
func shot(id: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	var path: String=OS.get_environment("AETHEL_CAPTURE_DIR").path_join("fase27-2-"+id+"-"+resolution+".png")
	check(root.get_texture().get_image().save_png(path)==OK,"real viewport capture "+id)
func run() -> void:
	Engine.set_meta("aethel_new_game",true)
	world=load("res://scenes/main.tscn").instantiate();root.add_child(world)
	await frames(8)
	var actor: CharacterBody3D=world.player
	var visual: AethelCharacterVisual=actor.get_node("BastiaoVisual")
	var caption:=Label.new()
	caption.position=Vector2(300,125)
	caption.add_theme_font_size_override("font_size",15)
	caption.add_theme_color_override("font_shadow_color",Color.BLACK)
	world.hud.root.add_child(caption)
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=dimensions;resolution="%dx%d"%[dimensions.x,dimensions.y]
		world.region_id="map_01";world._update_region()
		actor.position=Vector3(-4,0,5)
		actor.hp=actor.max_hp;actor.restore_full()
		visual.definition=load("res://data/characters/bastion_visual.tres")
		visual.select_mode("PLACEHOLDER")
		caption.text="PLACEHOLDER ATUAL · arte de produção pendente"
		root.get_camera_3d().snap_to_target()
		for view: String in ["front","back","profile"]:
			actor.facing={"front":Vector3(1,0,1),"back":Vector3(-1,0,-1),"profile":Vector3(1,0,-1)}[view].normalized()
			await frames()
			await shot("placeholder-"+view)
		visual.definition=load("res://data/characters/bastion_fixture_visual.tres")
		check(visual.select_mode("IMPORTED_MODEL"),"imported fixture selected "+resolution)
		caption.text="TESTE DE PIPELINE · tokens azuis · NÃO É ARTE DO BASTIÃO"
		for pair: Array in [["helmet","helmet"],["chest","chest"],["gloves","gloves"],["boots","boots"],["cape","cape"],["weapon_main","sword"],["offhand","shield"]]:
			visual.equipment_adapter().apply_equipment(StringName(pair[0]),StringName(pair[1]),&"common")
		for view: String in ["front","back","profile"]:
			actor.facing={"front":Vector3(1,0,1),"back":Vector3(-1,0,-1),"profile":Vector3(1,0,-1)}[view].normalized()
			await frames()
			await shot("fixture-"+view)
		var start: Vector3=actor.position
		actor.command_move(start+Vector3(3,0,0))
		await frames(12)
		check(actor.position.distance_to(start)>0.3,"live actor movement with imported model")
		await shot("fixture-movement")
		actor.clear_commands()
		world.quest_started=true;world.region_id="map_03";world._update_region()
		actor.position=Vector3(0,0,5)
		root.get_camera_3d().snap_to_target()
		await frames()
		var enemy: CharacterBody3D=world._spawn_enemy(actor.position+Vector3(0,0,-1.5),1,0)
		enemy.hp=1000;enemy.max_hp=1000;enemy.defense=0
		actor.facing=Vector3.FORWARD
		actor.attack_cooldown=0;actor.attack_recovery=0
		actor._try_attack()
		await frames(2)
		await shot("fixture-basic-combat")
		actor.attack_cooldown=0;actor.attack_recovery=0;actor.skill_cooldowns.clear();actor.ether=actor.max_ether
		var hp_before: int=enemy.hp
		for seed_value in 100:
			seed(seed_value)
			if randf()<0.5: seed(seed_value);break
		check(actor.use_skill(world.skill_tree.catalog.heavy_strike).is_empty(),"live heavy skill")
		check(enemy.hp<hp_before,"heavy skill deals actual damage; AI not neutralized")
		await frames(2)
		await shot("fixture-heavy-combat")
		actor.attack_cooldown=0;actor.attack_recovery=0;actor.skill_cooldowns.clear();actor.ether=actor.max_ether
		actor.use_skill(world.skill_tree.catalog.iron_guard)
		await frames(2)
		await shot("fixture-shield")
		actor.position=Vector3(-9,0,-3)
		root.get_camera_3d().snap_to_target()
		await frames(10)
		world.regions.tick(0.2)
		check(not world.regions._occluders.is_empty(),"real wall occlusion still active")
		await shot("fixture-occlusion")
		visual.select_mode("PLACEHOLDER")
		check(visual.mode=="PLACEHOLDER","fallback after live graphics")
	world.queue_free();await frames()
	for failure in failures: print("FALHA: "+failure)
	print("PHASE27.2 GUI: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
