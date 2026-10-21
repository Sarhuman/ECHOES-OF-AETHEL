extends Node
## Opt-in release verification. Runs only with an isolated save directory.
var failures: Array[String] = []
var checks := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value: failures.append(description)

func frames(count: int) -> void:
	for index in count: await get_tree().physics_frame
	await get_tree().process_frame

func press(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)

func run() -> void:
	if OS.get_environment("AETHEL_TEST_SAVE_DIR").is_empty():
		printerr("BUILD SMOKE requires AETHEL_TEST_SAVE_DIR")
		get_tree().quit(1)
		return
	await frames(3)
	var world = get_parent()
	var player = world.player
	var camera := get_viewport().get_camera_3d()
	check(world.hud != null and world.hud.is_inside_tree(), "HUD loaded")
	check(camera != null and camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "orthographic camera")
	var start: Vector3 = player.position
	Input.action_press("move_right")
	await frames(15)
	Input.action_release("move_right")
	check(player.position.distance_to(start) > 0.2, "movement input")
	world.region_id="map_03"
	world._update_region()
	player.position = Vector3.ZERO
	player.clear_commands()
	var enemy = world._spawn_enemy(Vector3(0,0,-3),1,2)
	enemy.set_physics_process(false)
	enemy.hp = 9999
	enemy.max_hp = 9999
	enemy.defense = 0
	player.rng.seed = 5
	camera.snap_to_target()
	await frames(3)
	var head: Vector2 = camera.unproject_position(enemy.position + Vector3(0,2.13,0))
	check(world.pick_enemy_at(head) == enemy, "large enemy picking")
	world._on_left_press(head)
	world._on_left_release()
	await frames(180)
	check(enemy.hp < 9999, "click approach and attack")
	player.clear_commands()
	player.position = Vector3.ZERO
	enemy.position = Vector3(0,0,-1.5)
	player.attack_cooldown = 0
	player.attack_recovery = 0
	player.ether = player.max_ether
	player.attack_target = enemy
	var hp_before: int = enemy.hp
	prepare_hit()
	await press(KEY_F1)
	check(enemy.hp < hp_before, "F1 damage")
	await press(KEY_F2)
	check(player.guard_remaining > 0, "F2 guard")
	player.attack_cooldown = 0
	player.attack_recovery = 0
	player.ether = player.max_ether
	hp_before = enemy.hp
	prepare_hit()
	await press(KEY_F3)
	check(enemy.hp < hp_before, "F3 damage")
	check(world.merchant.get_node_or_null("InteractionArea") != null, "Doma interaction")
	player.clear_commands()
	player.attack_recovery = 0
	world.region_id="map_01"
	world._update_region()
	player.position = world.merchant.position + Vector3(2,0,0)
	world.narrative.request("doma")
	check(world.narrative.view.visible,"Doma dialogue data exported")
	world.narrative.select_response(0)
	check(world.shop_panel.visible,"Doma response opens store")
	world.gold = 1000
	var offer: AethelItemInstance = world.shop_stock[0]
	var price: int = world._buy_price(offer)
	for row: Dictionary in world.inventory.entries(): world.inventory.remove_item(row.instance.instance_id)
	world._purchase(offer,false)
	check(world.inventory.find_item(offer.instance_id) != null and world.gold == 1000-price,"release purchase")
	world._save_state()
	world.gold = 0
	check(world._load_state() and world.gold == 1000-price and world.inventory.find_item(offer.instance_id) != null,"release save/load transaction")
	check(not world.shop_stock.any(func(item: AethelItemInstance) -> bool: return item.instance_id == offer.instance_id),"release stock persisted")
	world.shop_panel.hide()
	world.quest_started = true
	var ex: AethelExploration = world.exploration
	player.position = ex.objects.vigilia_anchor.position+Vector3(0,0,1)
	check(ex.activate("vigilia_anchor"),"release anchor discovery")
	ex.travel_panel.hide()
	world.region_id = "map_02"
	world._update_region()
	for actor in world.enemies: actor.set_physics_process(false)
	player.position = ex.objects.district_chest.position+Vector3(0,0,1)
	check(ex.activate("district_chest") and not ex.activate("district_chest"),"release chest single use")
	player.position = ex.objects.district_well.position+Vector3(0,0,1)
	player.hp = 20
	check(ex.activate("district_well") and player.hp > 20,"release well")
	player.position = ex.objects.district_altar.position+Vector3(0,0,1)
	check(ex.activate("district_altar") and player.exploration_reduction > 0,"release altar")
	player.position = ex.objects.district_anchor.position+Vector3(0,0,1)
	check(ex.activate("district_anchor") and ex.travel("district_anchor","vigilia_anchor"),"release fast travel")
	world._save_state()
	var drop_count: int = world.dropped_items.size()
	check(world._load_state() and ex.used.has("district_chest") and ex.anchors.size() == 2 and world.dropped_items.size() == drop_count,"release exploration persistence")
	check(world.hud.hp_bar != null and world.hud.ether_bar != null,"release compact resources")
	check(AudioServer.get_bus_index("UI") >= 0 and AudioServer.get_bus_index("Ambience") >= 0,"release audio channels")
	var discard := AethelItemInstance.new(world.item_catalog.wood_shield,"release-discard")
	world.inventory.add_item(discard)
	world._on_discard_requested(discard.instance_id)
	check(world.inventory.find_item(discard.instance_id) == null,"release discard removes bag item")
	check(world.dropped_items.any(func(drop: AethelDroppedItem) -> bool: return drop.item != null and drop.item.instance_id == discard.instance_id),"release discard ground ownership")
	world.shop_tooltip.show_item_at(discard,Rect2(20,400,300,40))
	await frames(3)
	var tooltip_rect: Rect2 = world.shop_tooltip.get_global_rect()
	await frames(20)
	check(world.shop_tooltip.get_global_rect() == tooltip_rect,"release stable tooltip")
	await frames(3)
	check(world.regions.validate_graph().is_empty(),"release graph connections")
	check(not world.regions.allows_combat(),"release safe hub")
	check(world.regions.active_vigilia_variant=="SUMMER" and world.regions.level.presentation_asset!=null,"release Summer-authored architecture")
	check(world.regions.level.presentation_occluders.size()==7,"release roof occlusion bounds")
	check(world.regions.level.cells.size()==988,"release unchanged hub navigation cells")
	for connector: String in ["map_01_to_map_02","map_02_to_map_03","map_03_to_map_04"]:
		player.position=world.regions.connectors[connector].position
		check(world.regions.transition(connector),"release canonical transition "+connector)
		await frames(3)
	check(world.region_id=="map_04" and world.regions.allows_combat(),"release archive offensive policy")
	var visual: AethelCharacterVisual=player.get_node("BastiaoVisual")
	check(visual.mode=="PLACEHOLDER","release keeps original character default")
	var production_definition:=visual.definition
	visual.definition=load("res://data/characters/bastion_fixture_visual.tres")
	check(visual.select_mode("IMPORTED_MODEL") and visual.last_validation.valid,"release imports rig clips sockets and provenance")
	visual.definition=production_definition
	check(visual.select_mode("PLACEHOLDER"),"release reversible visual fallback")
	world.pause_menu.open()
	check(get_tree().paused, "pause")
	get_tree().paused = false
	print("BUILD SMOKE: %d checks, %d failures" % [checks,failures.size()])
	for failure in failures: printerr("FALHA: ",failure)
	get_tree().quit(0 if failures.is_empty() else 1)

func prepare_hit() -> void:
	# Enemy receive_hit uses global randf, independently of player.rng.
	# Control only this diagnostic's next hit roll; preserve actual combat rules.
	for candidate in range(100):
		seed(candidate)
		if randf() < 0.5:
			seed(candidate)
			return
