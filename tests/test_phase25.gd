extends SceneTree
var world: Node3D
var checks := 0
var failures: Array[String] = []
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func frames(count: int = 3) -> void:
	for i in count: await physics_frame
	await process_frame
func _initialize() -> void: call_deferred("run")
func signature(rows: Array) -> Array:
	var result: Array = []
	for row: Dictionary in rows:
		result.append({"kind":row.kind,"gold":row.get("amount",0),"item":row.item.serialize() if row.has("item") else {}})
	return result
func run() -> void:
	root.size = Vector2i(1280,720)
	Engine.set_meta("aethel_new_game",true)
	world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await frames(6)
	var ex: AethelExploration = world.exploration
	var generator: AethelLootGenerator = world.loot_generator
	check(generator.validate_rules(),"valid authored reward tables")
	var context := {"id":"seeded-test","level":2,"rank":2,"region":"map_02","difficulty":"test","table":"elite","magic_find":0}
	generator.set_seed(2500)
	var first: Array = signature(generator.roll_rewards(context))
	generator.set_seed(2500)
	check(first == signature(generator.roll_rewards(context)),"seed reproduces qualities affixes and instance IDs")
	check(first.size() >= 3,"elite guaranteed equipment")
	var qualities: Dictionary = {}
	var materials := 0
	for rank in 3:
		var rewards := 0
		for i in 100:
			context.rank = rank
			context.table = ["normal","champion","elite"][rank]
			var rows := generator.roll_rewards(context)
			rewards += rows.size()
			for row: Dictionary in rows:
				if row.has("item"):
					check(world.item_catalog.has(String(row.item.definition.item_id)),"valid catalog reward")
					qualities[row.item.get_quality()] = true
					if row.item.definition.kind == "material": materials += 1
		check(rewards > 0,"rewards category %d" % rank)
	check(qualities.size() == 5,"all five canonical qualities generated")
	check(materials > 0,"materials generated from existing catalog")
	var prior: Variant = generator.rules.tables.normal.weights.gold
	generator.rules.tables.normal.weights.gold = -1
	check(not generator.validate_rules() and generator.roll_rewards(context).is_empty(),"invalid weights rejected")
	generator.rules.tables.normal.weights.gold = prior
	context.region = "missing"
	check(generator.roll_rewards(context).is_empty(),"unknown region cannot generate rewards")
	world.quest_started = true
	check(ex.activate("district_chest") == false,"cannot activate object in another region")
	world.player.position = ex.objects.vigilia_anchor.position + Vector3(0,0,1)
	check(ex.activate("vigilia_anchor") and "vigilia_anchor" in ex.anchors,"discover hub anchor")
	check(not ex.travel("vigilia_anchor","district_anchor"),"undiscovered destination rejected")
	ex.travel_panel.hide()
	world.region_id = "map_02"
	world._update_region()
	await frames()
	check(world.enemies.size() == 5,"moderate authored five-enemy encounter")
	var elite: CharacterBody3D
	var champion: CharacterBody3D
	var minions := 0
	for enemy in world.enemies:
		enemy.set_physics_process(false)
		if enemy.rank == 2: elite = enemy
		if enemy.rank == 1: champion = enemy
		if str(enemy.get_meta("leader_id","")) == "elite_1": minions += 1
	check(elite != null and minions == 2,"elite has two configured associated minions")
	check(champion != null and "fast" in champion.modifiers and "resistant" in champion.modifiers,"champion modifiers registered")
	check(champion.move_speed > 2.65*1.1 and champion.defense > 16,"speed and defense modifiers applied")
	check(elite.damage_min > 6 and "brutal" in elite.modifiers,"brutal damage modifier")
	world.player.position = elite.position + Vector3(0,0,1)
	world.player.invulnerability = 0
	world.player.guard_remaining = 0
	var before_hp: int = world.player.hp
	elite._tick_modifiers(2.1)
	check(world.player.hp < before_hp,"corrupted periodic damage is functional")
	var protected: CharacterBody3D
	for enemy in world.enemies:
		if enemy != elite and enemy.ward_remaining > 0: protected = enemy; break
	check(protected != null,"guardian grants temporary nearby ally protection")
	var ally_hp: int = protected.hp
	protected.take_damage(10)
	check(protected.hp == ally_hp-8,"guardian mitigates actual damage")
	protected._tick_modifiers(3)
	check(protected.ward_remaining == 0,"guardian protection expires")
	# Special source stays locked until its entire encounter is defeated.
	world.player.position = ex.objects.district_special.position + Vector3(0,0,1)
	check(not ex.activate("district_special"),"special chest encounter condition")
	var killed_id: String = str(world.enemies[0].get_meta("spawn_id"))
	world.enemies[0].take_damage(100000)
	await frames()
	var drop_count: int = world.dropped_items.size()
	world.region_id = "map_01"
	world._update_region()
	world.region_id = "map_02"
	world._update_region()
	await frames()
	check(world.enemies.size() == 4 and not world.enemies.any(func(enemy: CharacterBody3D) -> bool: return enemy.get_meta("spawn_id") == killed_id),"partial encounter deaths survive reentry")
	check(world.dropped_items.size() == drop_count,"reentry does not duplicate killed enemy rewards")
	for enemy in world.enemies.duplicate(): enemy.take_damage(100000)
	await frames()
	check(ex.encounter_complete("echo_guard") and world.map_02_cleared,"encounter completion verified")
	world.player.position = ex.objects.district_special.position + Vector3(0,0,1)
	before_hp = world.dropped_items.size()
	check(ex.activate("district_special"),"special chest opens after encounter")
	check(world.dropped_items.size() > before_hp,"special chest produces real pending drops")
	var chest_count: int = world.dropped_items.size()
	check(not ex.activate("district_special") and world.dropped_items.size() == chest_count,"chest opens once")
	for id in ["district_chest","district_barrel","district_urn","district_remains","district_tomb"]:
		world.player.position = ex.objects[id].position + Vector3(0,0,1)
		check(ex.activate(id),"reusable container "+id)
	# Collection checks transfer confirmation, distance and live ownership.
	for row: Dictionary in world.inventory.entries(): world.inventory.remove_item(row.instance.instance_id)
	world.player.position = Vector3(0,0,5)
	var item := AethelItemInstance.new(world.item_catalog.short_sword)
	var drop: AethelDroppedItem = world._spawn_drop({"kind":"item","item":item},world.player.position)
	world.player.position = drop.position + Vector3(0.5,0,0)
	check(world._collect_drop(drop) and world.inventory.find_item(item.instance_id) == item,"collection transfers real instance")
	check(not world._collect_drop(drop),"collected object cannot replay transfer")
	var gold_drop: AethelDroppedItem = world._spawn_drop({"kind":"gold","amount":17},world.player.position)
	world.player.position = gold_drop.position + Vector3(0.5,0,0)
	var gold_before: int = world.gold
	check(world._collect_drop(gold_drop) and world.gold == gold_before+17,"gold credited once")
	check(not world._collect_drop(gold_drop) and world.gold == gold_before+17,"gold cannot be replayed")
	var overflow: AethelDroppedItem = world._spawn_drop({"kind":"item","item":AethelItemInstance.new(world.item_catalog.short_sword)},world.player.position)
	world.player.position = overflow.position + Vector3(0.5,0,0)
	world.inventory.grid_width = 1
	world.inventory.grid_height = 1
	check(not world._collect_drop(overflow) and world.dropped_items.has(overflow) and not overflow.is_queued_for_deletion(),"full bag preserves ground reward")
	world.inventory.grid_width = 10
	world.inventory.grid_height = 4
	world.player.position = overflow.position+Vector3(6,0,0)
	check(not world._collect_drop(overflow),"remote transfer rejected")
	for key: String in AethelSettings.loot_filters: AethelSettings.loot_filters[key] = false
	ex.present_drops(true)
	check(not overflow.visible and world.dropped_items.has(overflow),"filter hides without destroying")
	for key: String in AethelSettings.loot_filters: AethelSettings.loot_filters[key] = true
	ex.present_drops(true)
	check(overflow.visible,"filter can reveal existing loot")
	# Well bounded uses; altar duration integrates Player damage and is saved as remaining game time.
	world.player.position = ex.objects.district_well.position + Vector3(0,0,1)
	world.player.hp = 10
	world.player.ether = 0
	world.player.stamina = 0
	check(ex.activate("district_well") and world.player.hp > 10 and world.player.ether > 0 and world.player.stamina == world.player.max_stamina,"well restores three resources")
	check(ex.activate("district_well") and not ex.activate("district_well"),"well two-use limit")
	world.player.position = ex.objects.district_altar.position + Vector3(0,0,1)
	check(ex.activate("district_altar") and world.player.exploration_reduction == 0.2,"altar grants resistance effect")
	world.player.hp = world.player.max_hp
	world.player.invulnerability = 0
	before_hp = world.player.hp
	world.player.take_damage(10)
	check(world.player.hp == before_hp-8,"altar changes actual incoming damage")
	check(not ex.activate("district_altar"),"altar cannot be reused")
	world.player.position = ex.objects.district_anchor.position + Vector3(0,0,1)
	check(ex.activate("district_anchor"),"discover hostile anchor")
	# Enemy DOT earlier in this fixture starts the real-time travel lock.
	while ex.recent_enemy_damage_active():
		OS.delay_msec(10)
		await process_frame
	check(ex.travel("district_anchor","vigilia_anchor") and world.region_id == "map_01","travel to discovered hub")
	world._save_state()
	var expected: Dictionary = ex.serialize()
	var expected_gold: int = world.gold
	ex.used.clear()
	ex.killed.clear()
	ex.anchors.clear()
	ex.buffs.clear()
	check(world._load_state(),"load exploration through existing save")
	check(ex.used == expected.used and ex.killed == expected.killed,"containers and encounters persist")
	check(ex.anchors.size() == 2 and world.gold == expected_gold,"anchors and balance persist")
	check(world.dropped_items.size() == expected.drops.size(),"pending ground loot survives load")
	check(float(ex.buffs.get("remaining",0)) > 0 and world.player.exploration_reduction == 0.2,"active effect remaining time persists")
	var count: int = world.dropped_items.size()
	check(world._load_state() and world.dropped_items.size() == count,"repeated load does not duplicate ground loot")
	await frames() # Independent travel inputs occur on separate frames.
	world.player.position = ex.objects.vigilia_anchor.position + Vector3(0,0,1)
	check(ex.travel("vigilia_anchor","district_anchor") and world.enemies.is_empty(),"saved cleared region stays cleared")
	world.player.position = ex.objects.district_special.position + Vector3(0,0,1)
	check(not ex.activate("district_special"),"saved chest cannot repeat rewards")
	ex.tick(31)
	check(world.player.exploration_reduction == 0,"altar expires without permanent stat drift")
	var malformed: Dictionary = ex.serialize()
	malformed.used["district_well"] = 999
	check(not ex.valid_state(malformed),"invalid object use counts rejected")
	world.queue_free()
	await frames()
	for message in failures: print("FALHA: "+message)
	print("PHASE25: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
