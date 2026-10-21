extends SceneTree
var failures: Array[String] = []
var checks := 0
var catalog: Dictionary

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func item(id: String, uid: String, count: int = 1) -> AethelItemInstance:
	var result := AethelItemInstance.new(catalog[id],uid)
	result.quantity = count
	return result

func frames(count: int = 2) -> void:
	for index in count: await physics_frame
	await process_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	catalog = AethelItemCatalog.create_catalog()
	var categories: Dictionary = {}
	var manifest: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/items/icons/manifest.json"))
	for row: Dictionary in manifest: categories[row["category"]] = true
	check(manifest.size() >= 30 and categories.size() == 6,"thirty icons in six categories")
	for definition: AethelItemData in catalog.values(): check(definition.icon != null,"catalog icon " + String(definition.item_id))
	var manager := AethelInventoryManager.new()
	root.add_child(manager)
	manager.grid_width = 2
	manager.grid_height = 2
	var potion := item("hp_small","stack",15)
	check(manager.add_item(potion),"add stack")
	check(manager.add_item(item("hp_small","merge",5)) and potion.quantity == 20 and manager.entries().size() == 1,"stack without duplicate entries")
	check(not manager.add_item(item("hp_small","merge",5)) and potion.quantity == 20,"absorbed ID cannot be replayed")
	check(not manager.add_item(potion),"duplicate ID rejected")
	check(manager.add_item(item("mana_small","mana")),"second item")
	check(manager.add_item(item("plain_ring","ring")),"third item")
	check(manager.add_item(item("plain_amulet","amulet")),"fourth item")
	var before := JSON.stringify(manager.serialize())
	check(not manager.add_item(item("hp_small","overflow")) and JSON.stringify(manager.serialize()) == before,"full stack and full bag atomic")
	check(manager.move_item("stack",Vector2i(1,0)) and manager.item_at(Vector2i.ZERO) == "mana","swap positions")
	before = JSON.stringify(manager.serialize())
	check(not manager.move_item("stack",Vector2i(2,0)) and JSON.stringify(manager.serialize()) == before,"invalid move preserves everything")
	check(manager.take_one("stack") and potion.quantity == 19,"remove one unit")
	check(manager.remove_item("ring") and manager.find_item("ring") == null,"remove item")
	check(manager.auto_sort() and manager.occupied_count() == 3,"sort conserves items")
	var restored := AethelInventoryManager.new()
	root.add_child(restored)
	var payload := manager.serialize()
	payload["items"].append(payload["items"][0].duplicate(true))
	payload["items"].append({"id":"unknown","item_id":"does_not_exist"})
	restored.restore(payload,catalog)
	check(restored.entries().size() == 3 and restored.find_item("stack").quantity == 19,"load quantities and reject duplicate/unknown IDs")
	check(AethelItemInstance.from_dict({"item_id":"hp_small","quantity":-1},catalog) == null,"negative stack rejected")
	check(AethelItemInstance.from_dict({"item_id":"hp_small","quantity":1.5},catalog) == null,"fractional stack rejected")
	check(AethelItemInstance.from_dict({"item_id":"hp_small"},catalog).quantity == 1,"old item migrates to one")
	var world = load("res://scenes/main.tscn").instantiate()
	Engine.set_meta("aethel_new_game",true)
	root.add_child(world)
	current_scene = world
	await frames()
	var player = world.player
	var bag: AethelInventoryManager = world.inventory
	var view: AethelInventoryView = world.inventory_view
	check(view.cells.size() == 40,"default real forty-cell grid")
	view.show()
	var sword := item("short_sword","sword")
	check(bag.add_item(sword),"add actual equipment")
	var old_weapon: AethelItemInstance = player.equipped["weapon"]
	var old_damage: float = player.damage_min
	world._on_equip_requested(sword.instance_id,"weapon")
	check(player.equipped["weapon"] == sword and bag.find_item("sword") == null and bag.find_item(old_weapon.instance_id) != null,"equip transfers ownership")
	check(player.damage_min != old_damage,"derived attributes updated")
	var adapter: AethelEquipmentVisual = player.get_node("BastiaoVisual").equipment_adapter()
	check(adapter.snapshot()[&"weapon_main"]["appearance_id"] == &"sword","visual socket updated")
	var snapshot := JSON.stringify(bag.serialize())
	world._on_equip_requested("sword","weapon")
	check(JSON.stringify(bag.serialize()) == snapshot and player.equipped["weapon"] == sword,"stale equip replay cannot duplicate")
	var ring := item("plain_ring","ring2")
	bag.add_item(ring)
	world._on_equip_requested("ring2","ring2")
	check(player.equipped.get("ring2") == ring,"explicit second ring target")
	var incompatible := item("leather_boots","incompatible")
	bag.add_item(incompatible)
	snapshot = JSON.stringify(bag.serialize())
	world._on_equip_requested("incompatible","helm")
	check(JSON.stringify(bag.serialize()) == snapshot and bag.find_item("incompatible") != null,"wrong slot rejects without mutation")
	var restricted := item("long_sword","restricted")
	check(not player.equipment_problem(restricted).is_empty(),"level requirement")
	var data := catalog["short_sword"].duplicate() as AethelItemData
	data.allowed_classes = [&"another_class"]
	check(player.equipment_problem(AethelItemInstance.new(data)) == "Classe incompatível","class requirement")
	data.allowed_classes.clear()
	data.req_strength = 999
	check(not player.equipment_problem(AethelItemInstance.new(data)).is_empty(),"strength requirement")
	data.req_strength = 0
	data.req_dexterity = 999
	check(not player.equipment_problem(AethelItemInstance.new(data)).is_empty(),"dexterity requirement")
	data.req_dexterity = 0
	data.hands = 2
	check(not player.equipment_problem(AethelItemInstance.new(data)).is_empty(),"two hands blocked by shield")
	var saved_shield: AethelItemInstance = player.equipped["shield"]
	player.equipped.erase("shield")
	var saved_weapon: AethelItemInstance = player.equipped["weapon"]
	player.equipped["weapon"] = AethelItemInstance.new(data)
	check(not player.equipment_problem(saved_shield,"shield").is_empty(),"shield blocked by two-hand weapon")
	player.equipped["weapon"] = saved_weapon
	player.equipped["shield"] = saved_shield
	view.tooltip.show_item(sword)
	view.tooltip.append_comparison(sword,old_weapon)
	check("Dano base médio: -1.0" in view.tooltip._text.text,"numeric comparison from actual item values")
	var serialized := sword.serialize()
	world._save_state()
	world._on_unequip_requested("weapon")
	check(not player.equipped.has("weapon") and bag.find_item("sword") != null,"unequip transfers to bag")
	check(world._load_state() and player.equipped["weapon"].serialize() == serialized,"save/load IDs equipment modifiers")
	var material := item("bronze_shard","persistent-stack",17)
	check(bag.add_item(material),"material stack uses same manager")
	var stack_origin: Vector2i = bag._items["persistent-stack"]["origin"]
	world._save_state()
	bag.remove_item("persistent-stack")
	check(world._load_state() and bag.find_item("persistent-stack").quantity == 17 and bag._items["persistent-stack"]["origin"] == stack_origin,"stack quantity and position persist in real save")
	# Real defeated enemy invokes existing loot generation and collection, not UI fixtures.
	for entry in bag.entries(): bag.remove_item(entry["instance"].instance_id)
	world.loot_generator.set_seed(2023)
	var generated := false
	for index in 8:
		var enemy = world._spawn_enemy(Vector3(2,0,0),1,1)
		enemy.take_damage(99999)
		await frames()
		for drop in world.dropped_items.duplicate():
			if not is_instance_valid(drop) or drop.is_gold() or drop.item.definition.kind != "equipment": continue
			player.position = drop.position + Vector3(0.5,0,0)
			var dropped: AethelItemInstance = drop.item
			check(world._collect_drop(drop) and bag.find_item(dropped.instance_id) == dropped,"defeat real enemy then collect actual loot")
			world._on_equip_requested(dropped.instance_id)
			var slot: String = player.slot_for(dropped)
			check(player.equipped.get(slot) == dropped,"equip actual generated loot")
			world._save_state()
			check(world._load_state() and player.equipped[slot].serialize() == dropped.serialize(),"generated loot ID quality and affixes persist")
			generated = true
			break
		if generated: break
	check(generated,"enemy-to-save loop exercised")
	world.progression.current_level = 9
	player.character_level = 9
	player.equipped["weapon"] = item("war_axe","dependent-weapon")
	player.equipped["amulet"] = item("unq_amuleto","supporting-amulet")
	player.recalculate_stats()
	world._save_state()
	check(world._load_state() and player.equipped.get("weapon") != null and player.equipped["weapon"].instance_id == "dependent-weapon","load validates requirements after all equipment bonuses")
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = resolution
		view.show()
		view.tooltip.show_item(sword)
		view.tooltip.append_comparison(sword,old_weapon)
		await frames()
		check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(view.get_global_rect()),"inventory fits resolution")
		check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(view.tooltip.get_global_rect()),"tooltip fits resolution")
	var long_data := catalog["plain_ring"].duplicate() as AethelItemData
	long_data.description = "Descrição extensa para testar leitura e rolagem.\n".repeat(100)
	view.tooltip.show_item(AethelItemInstance.new(long_data))
	await frames(4)
	check(view.tooltip.size.y <= root.get_visible_rect().size.y-24,"long tooltip stays within viewport")
	view.tooltip.scroll_by(180)
	check(view.tooltip._text.get_v_scroll_bar().value > 0,"long tooltip can scroll")
	# Fill every bag cell: both equipment exchange and removal must be lossless failures.
	for entry in bag.entries(): bag.remove_item(entry["instance"].instance_id)
	for index in 40: bag.add_item(item("plain_ring","full-%d" % index))
	var equipped_before: Dictionary = player.equipped.duplicate()
	snapshot = JSON.stringify(bag.serialize())
	world._on_unequip_requested("weapon",Vector2i.ZERO)
	check(player.equipped == equipped_before and JSON.stringify(bag.serialize()) == snapshot,"failed unequip preserves full inventory")
	world._on_equip_requested("full-0","ring1")
	# If the ring slot was empty, transfer legitimately frees a cell; no overwrites occur.
	var ids: Dictionary = {}
	for entry in bag.entries(): ids[entry["instance"].instance_id] = true
	for equipped: AethelItemInstance in player.equipped.values():
		check(not ids.has(equipped.instance_id),"unique ownership across bag and equipment")
		ids[equipped.instance_id] = true
	for entry in bag.entries(): bag.remove_item(entry["instance"].instance_id)
	bag.grid_width = 2
	bag.grid_height = 3
	var narrow := item("short_sword","narrow")
	bag.place_item(narrow,Vector2i.ZERO)
	for index in 3: bag.place_item(item("plain_ring","block-%d" % index),Vector2i(1,index))
	player.equipped["weapon"] = item("hand_axe","wide-outgoing")
	player.recalculate_stats()
	equipped_before = player.equipped.duplicate()
	snapshot = JSON.stringify(bag.serialize())
	world._on_equip_requested("narrow","weapon")
	check(player.equipped == equipped_before and JSON.stringify(bag.serialize()) == snapshot,"larger outgoing item cannot overwrite full bag during swap")
	print("PHASE23: %d checks, %d failures" % [checks,failures.size()])
	for failure in failures: printerr("FALHA: ",failure)
	quit(0 if failures.is_empty() else 1)
