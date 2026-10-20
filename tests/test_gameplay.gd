extends SceneTree
# godot --headless --path . --script res://tests/test_gameplay.gd
# Regressão de jogabilidade na cena principal (sem renderização).
var failures: Array[String] = []
var SAVE_FILE: String = AethelSavePaths.current()

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _clean_save() -> void:
	for path in [SAVE_FILE, SAVE_FILE + ".bak", SAVE_FILE + ".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)

func _screen_of(world: Node3D, point: Vector3) -> Vector2:
	return root.get_viewport().get_camera_3d().unproject_position(point)

func _initialize() -> void:
	seed(777)
	_clean_save()
	var world: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	await physics_frame
	var player: CharacterBody3D = world.player
	var camera: Camera3D = root.get_viewport().get_camera_3d()
	# --- câmera dimétrica clássica (pitch 30°, yaw 45°)
	_check(absf(camera.rotation_degrees.x + 35.264) < 0.01 and absf(camera.rotation_degrees.y - 45.0) < 0.01, "câmera 35,264°/45°")
	# --- equipamento e poções iniciais
	_check(player.equipped.has("weapon"), "começa com arma equipada")
	var potions: int = 0
	for slot: Dictionary in world.belt: potions += int(slot.get("count", 0))
	_check(potions == 3, "começa com 3 poções no cinto (%d)" % potions)
	# --- W sobe na tela
	var start: Vector3 = player.global_position
	_key(KEY_W, true)
	for i in 10: await physics_frame
	_key(KEY_W, false)
	var moved: Vector2 = _screen_of(world, player.global_position) - _screen_of(world, start)
	_check(moved.y < -1.0 and absf(moved.x) < absf(moved.y) * 0.1, "W sobe na tela (x=%s y=%s)" % [moved.x, moved.y])
	await create_timer(0.3).timeout
	# --- dash parado
	player.stamina = 100.0
	var before: Vector3 = player.global_position
	_key(KEY_SPACE, true)
	for i in 6: await physics_frame
	_key(KEY_SPACE, false)
	_check(player.global_position.distance_to(before) > 0.5, "dash parado se move")
	# --- ponto do chão sob o cursor e clique para mover
	player.global_position = Vector3(0, 0, 4)
	var target_point := Vector3(3, 0, 1)
	var cursor: Vector2 = _screen_of(world, target_point)
	var ground: Variant = world.ground_point_at(cursor)
	_check(ground != null and (ground as Vector3).distance_to(target_point) < 0.05, "ground_point_at inverte a projeção da câmera")
	world._on_left_press(cursor)
	world._on_left_release()
	for i in 90: await physics_frame
	_check(player.global_position.distance_to(target_point) < 0.6, "clique move até o ponto (%s)" % str(player.global_position))
	# --- mapa 02: escolha de inimigo por clique, combate, loot
	world.quest_started = true
	world.region_id = "map_02"
	world._update_region()
	_check(world.enemies.size() == 5, "map_02 tem 5 inimigos")
	var champions: int = 0
	for enemy in world.enemies:
		if enemy.rank == 1: champions += 1
	_check(champions == 1, "um campeão entre as Rasuras")
	var first: CharacterBody3D = world.enemies[0]
	var picked: CharacterBody3D = world.pick_enemy_at(_screen_of(world, first.global_position + Vector3(0, 0.9, 0)))
	_check(picked == first, "pick_enemy_at acha a Rasura sob o cursor")
	_check(world.pick_enemy_at(Vector2(-500, -500)) == null, "nada sob o cursor fora da tela")
	player.hp = player.max_hp
	for e in world.enemies.duplicate():
		e.take_damage(9999)
	await process_frame
	_check(world.slain == 5 and world.map_02_cleared, "5 mortes limpam a região")
	_check(world.dropped_items.size() >= 1, "inimigos derrubam algo (%d)" % world.dropped_items.size())
	_check(player.character_level >= 2 and player.stats.unspent >= 5, "subiu de nível e ganhou 5 atributos (nv %d, pts %d)" % [player.character_level, player.stats.unspent])
	_check(player.hp == player.max_hp, "subir de nível restaura a vida")
	# --- coletar por clique (ouro/poção/item) e por E
	var gold_before: int = world.gold
	var inventory_before: int = world.inventory.entries().size()
	var belt_before: int = 0
	for slot: Dictionary in world.belt: belt_before += int(slot.get("count", 0))
	for drop in world.dropped_items.duplicate():
		player.global_position = drop.global_position + Vector3(0.5, 0, 0)
		var drop_screen: Vector2 = _screen_of(world, drop.global_position + Vector3(0, 0.5, 0))
		_check(world.pick_drop_at(drop_screen) == drop, "pick_drop_at acha o drop")
		world._collect_drop(drop)
	await process_frame
	var belt_after: int = 0
	for slot: Dictionary in world.belt: belt_after += int(slot.get("count", 0))
	_check(world.gold > gold_before or world.inventory.entries().size() > inventory_before or belt_after > belt_before, "coletou os drops")
	# --- região limpa não respawna e drops somem no hub
	world.region_id = "map_01"
	world._update_region()
	world.region_id = "map_02"
	world._update_region()
	_check(world.enemies.size() == 0, "região limpa não respawna")
	# --- poções
	player.hp = 40
	var drink_slot: int = -1
	for index in 4:
		var entry: Dictionary = world.belt[index]
		if not entry.is_empty() and str(entry["kind"]).begins_with("hp_"): drink_slot = index
	if drink_slot >= 0:
		world.last_drink_time = 0.0
		world._drink_belt(drink_slot)
		_check(player.hp > 40, "poção de vida cura (%d)" % player.hp)
	# --- distribuir atributo e equipar item do inventário
	var strength_before: int = player.stats.strength
	world.character_panel._spend("strength")
	_check(player.stats.strength == strength_before + 1, "gastar ponto de Força")
	for entry: Dictionary in world.inventory.entries(): world.inventory.remove_item(entry["instance"].instance_id) # evita mochila cheia por loot aleatório
	var sword := AethelItemInstance.new(world.item_catalog["short_sword"])
	world.inventory.add_item(sword)
	world._on_equip_requested(sword.instance_id)
	_check(player.equipped["weapon"] == sword, "equipar espada pela mochila")
	_check(world.inventory.find_item(sword.instance_id) == null, "item equipado sai da grade")
	var old_weapon_found: bool = false
	for entry: Dictionary in world.inventory.entries():
		if entry["instance"].definition.item_id == &"hand_axe": old_weapon_found = true
	_check(old_weapon_found, "arma anterior volta para a mochila")
	world._on_unequip_requested("weapon")
	_check(not player.equipped.has("weapon") and world.inventory.find_item(sword.instance_id) != null, "desequipar devolve à mochila")
	world._on_equip_requested(sword.instance_id)
	# --- habilidade no botão direito
	world.skill_tree.unlocked["heavy_strike"] = true
	world._select_right_skill("heavy_strike")
	_check(world.right_skill_id == "heavy_strike", "selecionar habilidade do botão direito")
	# --- save/load v3 com afixos, cinto e equipamento
	var rare: AethelItemInstance = world.loot_generator.roll_item(10, 2, 0.0, AethelItemData.Rarity.RARE)
	world.inventory.add_item(rare)
	var rare_name: String = rare.display_name()
	var rare_life: float = rare.stat_total("life")
	world.gold = 321
	world._save_state()
	world.gold = 1
	world.inventory.remove_item(rare.instance_id)
	player.equipped.clear()
	world.belt = [{}, {}, {}, {}]
	_check(world._load_state(), "carregar save v3")
	_check(world.gold == 321, "ouro restaurado")
	_check(player.equipped.has("weapon") and player.equipped["weapon"].definition.item_id == &"short_sword", "equipamento restaurado")
	var restored: bool = false
	for entry: Dictionary in world.inventory.entries():
		var item: AethelItemInstance = entry["instance"]
		if item.display_name() == rare_name and item.stat_total("life") == rare_life: restored = true
	_check(restored, "item raro com afixos restaurado (%s)" % rare_name)
	_check(world.map_02_cleared and world.right_skill_id == "heavy_strike", "flags e habilidade restauradas")
	# --- migração de save v2 (equipado por referência)
	var legacy := {"version": 2, "progression": {"level": 3, "xp": 5, "points": 2}, "skills": [], "gold": 9, "region_id": "map_01",
		"inventory": {"items": [{"id": "old-1", "item_id": "iron_axe", "x": 0, "y": 0}]}, "equipped": {"weapon": "old-1"}}
	var legacy_file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy))
	legacy_file.close()
	_check(world._load_state(), "carregar save v2")
	_check(player.equipped.has("weapon") and world.inventory.find_item("old-1") == null, "migração v2: item equipado não fica duplicado")
	_check(player.stats.unspent == 10 and player.character_level == 3, "migração v2: devolve pontos de atributo (%d)" % player.stats.unspent)
	# --- morte
	player.invulnerability = 0.0
	player.guard_remaining = 0.0
	player.take_damage(99999)
	_check(world.game_over, "derrota marca game over")
	_clean_save()
	if failures.is_empty():
		print("GAMEPLAY TEST OK")
		quit(0)
	else:
		for message in failures: printerr("FALHA: ", message)
		quit(1)
