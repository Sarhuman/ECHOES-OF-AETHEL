extends SceneTree
var checks := 0
var failures: Array[String] = []
var world: Node3D
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func frames(count: int = 3) -> void:
	for i in count: await physics_frame
	await process_frame
func _initialize() -> void: call_deferred("run")
func option(text: String) -> int:
	for i in world.narrative.options.size():
		if text in str(world.narrative.options[i].text): return i
	return -1
func run() -> void:
	root.size = Vector2i(1280,720)
	Engine.set_meta("aethel_new_game",true)
	world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await frames(6)
	var n: AethelNPCController = world.narrative
	check(n.definitions.size() == 5,"five canonical NPC integration definitions")
	check(n.definitions.teren.role.contains("sem voz"),"Teren remains voiceless")
	check(not n.actors.has("sive") and not n.actors.has("iro"),"later-act NPCs not misplaced")
	check(world.workshop.get_node_or_null("Anvil") != null and world.workshop.get_node_or_null("Furnace") != null,"workshop props")
	check(world.workshop.get_node_or_null("EquipmentDisplay") != null,"equipment display")
	var camera := root.get_camera_3d()
	world.player.position = Vector3(-5,0,5)
	await frames(20)
	var screen: Vector2 = camera.unproject_position(world.merchant.global_position + Vector3(0,1,0))
	check(n.pick(screen) == "doma","camera ray selects Doma")
	world._on_left_press(screen)
	check(n.pending_id == "doma" and not n.view.visible,"distant click approaches without opening")
	check(world.player.move_target.distance_to(world.merchant.position) < 2.6 and world.regions.level.valid_position(world.player.move_target),"approach target is navigable within NPC reach, no reversed direction")
	for i in 240:
		await physics_frame
		if n.view.visible: break
	check(n.view.visible and n.active_id == "doma","actual movement reaches Doma and opens dialogue")
	check(not world.player.has_move_target,"movement stops at conversation")
	check(world.player.facing.dot((world.merchant.position-world.player.position).normalized()) > 0.8,"faces NPC")
	check(n.view.responses.get_child_count() == 3,"dialogue response buttons")
	n.select_response(1)
	check(n.node_id == "doma_workshop","branch navigation")
	check(option("Já conversamos") == -1,"conditional response initially hidden")
	n.select_response(0)
	n.select_response(1)
	check(option("Já conversamos") >= 0,"choice unlocks conditional response")
	n.close()
	check(not n.view.visible,"close dialogue")
	check(n.meets({"class":"bastion","act":1}),"class and act conditions")
	check(n.meets({"attribute":{"key":"strength","min":1}}),"attribute condition")
	check(not n.meets({"unknown":true}),"unknown conditions fail closed")
	check(not n.meets({"corruption_min":10}),"future corruption threshold")
	check(n.portrait_for("doma") != null,"portrait fallback")
	world.gold = 2000
	world.player.position = world.merchant.position + Vector3(2,0,0)
	n.request("doma")
	n.select_response(0)
	check(world.shop_panel.visible and not n.view.visible,"dialogue opens real shop")
	check(world.shop_stock.size() == 9,"deterministic act-one stock")
	for row: Dictionary in world.inventory.entries(): world.inventory.remove_item(row.instance.instance_id)
	var offered: AethelItemInstance = world.shop_stock[0]
	var price: int = world._buy_price(offered)
	world._purchase(offered,false)
	check(world.gold == 2000-price and world.inventory.find_item(offered.instance_id) == offered,"purchase atomic delivery and debit")
	check(not world.shop_stock.has(offered),"purchased stock removed")
	var balance: int = world.gold
	world._purchase(offered,false)
	check(world.gold == balance,"stale purchase rejected")
	var other: AethelItemInstance = world.shop_stock[0]
	world.gold = 0
	world._purchase(other,false)
	check(world.gold == 0 and world.shop_stock.has(other),"insufficient gold preserves stock")
	world.gold = 2000
	world.inventory.grid_width = 1
	world.inventory.grid_height = 1
	world._purchase(other,false)
	check(world.gold == 2000 and world.shop_stock.has(other),"full bag preserves gold and stock")
	world.inventory.grid_width = 10
	world.inventory.grid_height = 4
	world._on_sell_requested(offered.instance_id)
	check(world.inventory.find_item(offered.instance_id) == null and world.gold > 2000,"sale removes exact instance and credits gold")
	var after_sale: int = world.gold
	world._on_sell_requested(offered.instance_id)
	check(world.gold == after_sale,"stale sale not paid twice")
	var quest := AethelItemInstance.new(world.item_catalog.quest_seal)
	world.inventory.add_item(quest)
	world._on_sell_requested(quest.instance_id)
	check(world.inventory.find_item(quest.instance_id) == quest and world.gold == after_sale,"quest item sale blocked")
	var locked := AethelItemInstance.new(world.item_catalog.plain_ring)
	world.inventory.add_item(locked)
	locked.definition.sale_locked = true
	world._on_sell_requested(locked.instance_id)
	check(world.inventory.find_item(locked.instance_id) == locked,"locked item sale blocked")
	locked.definition.sale_locked = false
	world.player.position = Vector3(5,0,5)
	world._purchase(other,false)
	world._on_sell_requested(locked.instance_id)
	check(world.gold == after_sale and world.inventory.find_item(locked.instance_id) == locked,"remote trade rejected")
	n.npc_states.doma = "unavailable"
	check(not n.request("doma"),"unavailable NPC rejected")
	n.npc_states.clear()
	world.player.position = world.npc.position + Vector3(1.5,0,0)
	n.request("maera")
	check(not world.quest_started,"opening dialogue does not autoaccept")
	n.select_response(option("Investigar"))
	check(world.quest_started and n.node_id == "maera_objective","explicit quest acceptance")
	check(n.view.speech.text.contains("provisório"),"demo objective explicitly labelled")
	n.close()
	n.request("maera")
	check(option("Relatar") == -1,"report unavailable before verified objective")
	n.close()
	world.region_id = "map_02"
	world._update_region()
	await frames(6)
	check(world.workshop.find_children("*","StaticBody3D",true,false).all(func(body: StaticBody3D) -> bool: return body.collision_layer == 0),"hidden workshop has no invisible collisions in map02")
	var victims: Array = world.enemies.duplicate()
	for enemy in victims: enemy.take_damage(100000)
	await frames(4)
	check(world.map_02_cleared and world.slain >= 5,"actual enemy defeats verify objective")
	world.player.position = world.gate.position + Vector3(0,0,-1)
	world._interact()
	check(world.region_id == "map_01" and not world.quest_completed,"return alone does not complete quest")
	world.player.position = world.npc.position + Vector3(1.5,0,0)
	n.request("maera")
	var reward_before: int = world.gold
	var report := option("Relatar")
	check(report >= 0,"return unlocks report")
	n.select_response(report)
	check(world.quest_completed and n.reward_claimed and world.gold == reward_before+60,"report grants reward once")
	n.close()
	n.request("maera")
	check(option("Relatar") == -1,"reward response no longer available")
	n.close()
	n.hub.doma = false
	n.npc_states.doma = "unavailable"
	world._save_state()
	var expected_gold: int = world.gold
	var expected_stock: int = world.shop_stock.size()
	var expected_uid: String = world.shop_stock[0].instance_id
	n.choices.clear()
	n.reward_claimed = false
	world.gold = 0
	world.shop_stock.clear()
	check(world._load_state(),"load existing save pipeline")
	check(world.gold == expected_gold and n.reward_claimed and world.quest_completed,"reward and balance persist")
	check(not n.hub.doma and n.npc_states.doma == "unavailable","service and NPC availability persist")
	n.hub.doma = true
	n.npc_states.clear()
	check(n.choices.get("doma_workshop") == "remember","dialogue choice persists")
	check(world.shop_stock.size() == expected_stock and world.shop_stock[0].instance_id == expected_uid,"stock instance identity persists")
	check(world._load_state() and world.gold == expected_gold,"repeat load does not repeat reward")
	world.shop_stock.clear()
	world._save_state()
	check(world._load_state() and world.shop_stock.is_empty(),"exhausted stock does not restock on load")
	var saved: Dictionary = world._read_save_payload(world.SAVE_PATH)
	saved.narrative.reward_claimed = false
	check(not world._valid_save(saved),"inconsistent reward state rejected")
	var legacy: Dictionary = n.serialize()
	check(n.valid_state(legacy),"narrative state validation")
	legacy.choices["arbitrary_script"] = "res://bad.gd"
	check(not n.valid_state(legacy),"unknown persisted choice rejected")
	# Occlusion must reject both picking and nearby interaction through a wall.
	n.hub.doma = true
	n.npc_states.clear()
	world.player.position = world.merchant.position + Vector3(2,0,0)
	var obstruction := StaticBody3D.new()
	obstruction.collision_layer = 1
	world.add_child(obstruction)
	obstruction.position = world.merchant.position + Vector3(1,1,0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.3,2,3)
	shape.shape = box
	obstruction.add_child(shape)
	await frames()
	check(not n.reachable("doma"),"obstacle blocks conversation line of sight")
	n.request("doma")
	check(not n.view.visible,"no nearby dialogue through obstacle")
	n.close()
	obstruction.queue_free()
	await frames()
	world.player.position = Vector3(0,0,4)
	n.request("doma")
	world.player.keyboard_active = true
	n.tick(0.01)
	check(n.pending_id.is_empty(),"manual movement cancels approach")
	world.player.keyboard_active = false
	# Blocked path is cancelled with no teleport or remote dialogue.
	world.player.position = Vector3(0,0,4)
	n.request("doma")
	world.player.clear_commands()
	n.tick(1.6)
	check(n.pending_id.is_empty() and not n.view.visible,"stalled approach cancelled")
	world.player.position = world.merchant.position + Vector3(2,0,0)
	n.request("doma")
	n.last_hp = world.player.hp + 1
	n.tick(0.01)
	check(not n.view.visible,"damage interrupts conversation")
	world.queue_free()
	await frames()
	for message in failures: print("FALHA: "+message)
	print("PHASE24: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
