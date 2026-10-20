extends SceneTree
var failures: Array[String] = []
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _initialize() -> void:
	call_deferred("run")

func write_payload(path: String, data: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func run() -> void:
	AethelInput.ensure_defaults()
	var catalog := AethelItemCatalog.create_catalog()
	var ids: Dictionary = {}
	for key: String in catalog:
		var data: AethelItemData = catalog[key]
		check(not ids.has(data.item_id) and String(data.item_id) == key, "catalogo tem IDs unicos")
		ids[data.item_id] = true
		check(data.width >= 1 and data.height >= 1, "dimensoes de item validas")
	var definitions := AethelClassDefinition.definitions()
	check(definitions.size() == 5, "cinco contratos de classe")
	var playable := 0
	for definition in definitions:
		if definition.playable: playable += 1
	check(playable == 1 and definitions[0].class_id == &"bastion", "somente Bastiao jogavel")
	var generator := AethelLootGenerator.new(catalog, 2020)
	var counts := [0,0,0,0,0]
	for index in 5000:
		var item := generator.roll_item(12)
		check(item != null and item.get_quality() in range(5), "drop valido")
		counts[item.get_quality()] += 1
	for count: int in counts: check(count > 0, "cinco qualidades geradas")
	print("DISTRIBUICAO CONSOLIDADA: ", counts)
	var epic := generator.roll_item(12, 0, 0, 3)
	check(epic.get_quality() >= 3, "qualidade minima epica")
	var invalid := AethelItemInstance.from_dict({"item_id":"hand_axe", "quality":{}, "ilvl":1}, catalog)
	check(invalid == null, "tipo invalido em item rejeitado")
	var restored := AethelItemInstance.from_dict({"item_id":"hand_axe", "quality":3, "ilvl":12,
		"affixes":[{"id":"cortante", "value":999999}, {"id":"arquivo_arbitrario", "value":999999}]}, catalog)
	check(restored.affixes.size() == 1 and restored.stat_total("damage_pct") == 30, "afixos validados e limitados")
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	await physics_frame
	var player = world.player
	var visual: AethelCharacterVisual = player.get_node("BastiaoVisual")
	var adapter := visual.equipment_adapter()
	var model_id := visual._model.get_instance_id()
	var armor := AethelItemInstance.new(catalog["quilted_armor"])
	armor.quality = 3
	var helm := AethelItemInstance.new(catalog["leather_cap"])
	helm.quality = 0
	var axe := AethelItemInstance.new(catalog["hand_axe"])
	axe.quality = 4
	player.equip_item(armor)
	player.equip_item(helm)
	player.equip_item(axe)
	var appearance := adapter.snapshot()
	check(appearance[&"chest"]["rarity_id"] == &"epic", "peitoral epico independente")
	check(appearance[&"helmet"]["rarity_id"] == &"common", "elmo comum independente")
	check(appearance[&"weapon_main"]["rarity_id"] == &"legendary", "arma lendaria independente")
	check(not adapter.apply_equipment(&"weapon_main", &"../../Model", &"rare"), "caminho arbitrario rejeitado")
	check(adapter.snapshot() == appearance, "referencia invalida preserva aparencia")
	var sword := AethelItemInstance.new(catalog["short_sword"])
	player.equip_item(sword)
	check(adapter.snapshot()[&"weapon_main"]["appearance_id"] == &"sword", "troca visual de arma")
	check(visual._model.get_instance_id() == model_id, "troca nao recria modelo")
	player.unequip_slot("weapon")
	check(not adapter.snapshot().has(&"weapon_main"), "desequipar remove aparencia")
	var restricted := AethelItemData.new()
	restricted.item_id = &"test_restricted"
	restricted.slot = "weapon"
	restricted.allowed_classes = [&"weaver"]
	check(not player.equip_item(AethelItemInstance.new(restricted))["ok"], "restricao de classe")
	player.equip_item(sword)
	player.equipped["shield"] = AethelItemInstance.new(catalog["wood_shield"])
	player.manual_block = true
	player.stamina = 100
	player.invulnerability = 0
	player.rng.seed = 5
	var blocked := false
	for index in 20:
		if player.receive_attack(10, 999999, 99) == "block": blocked = true
	check(blocked and player.stamina < 100, "bloqueio manual consome folego")
	player.manual_block = false
	world.gold = 123
	player.stamina = 44
	world._save_state()
	world.gold = 321
	world._save_state()
	write_payload(world.SAVE_PATH, {"version":4, "inventory":[]})
	world.gold = 0
	check(world._load_state() and world.gold == 123, "save invalido recupera backup")
	check(absf(player.stamina - 44) < 0.1, "save restaura folego")
	check(not world._valid_save({"version":4,"equipped":{"weapon":{"item_id":"inexistente"}}}), "save com recurso ausente rejeitado")
	write_payload(world.SAVE_PATH, {"version":4,"class_id":"bastion","position":[999999,0,999999],"region_id":"map_01"})
	check(world._load_state() and player.position.length() < 30, "posicao invalida usa spawn seguro")
	AethelInput.bind_interact(KEY_F)
	var event := InputEventKey.new()
	event.keycode = KEY_F
	event.pressed = true
	check(event.is_action_pressed("interact"), "interacao reconfiguravel")
	AethelInput.bind_interact(KEY_E)
	world.pause_menu.open()
	check(paused and world.pause_menu.overlay.visible, "pausa interrompe simulacao")
	var frozen: Vector3 = player.position
	await process_frame
	await process_frame
	check(player.position == frozen, "jogador parado durante pausa")
	world.pause_menu.resume()
	check(not paused and not world.pause_menu.overlay.visible, "retomar")
	world.pause_menu.return_to_menu()
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://scenes/main_menu.tscn", "retorno ao menu")
	var menu = current_scene
	check(not menu.continue_button.disabled, "continuar habilitado com save")
	menu.start_game(true)
	await process_frame
	await process_frame
	check(current_scene.scene_file_path == "res://scenes/main.tscn" and current_scene.gold == 60, "novo jogo nao carrega sessao anterior")
	print("CONSOLIDATION: %d verificacoes, %d falhas" % [checks, failures.size()])
	for message in failures: printerr("FALHA: ", message)
	quit(0 if failures.is_empty() else 1)
