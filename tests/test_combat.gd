extends SceneTree
# godot --headless --path . --script res://tests/test_combat.gd
var failures: Array[String] = []

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _spawn_enemy(parent: Node, target: CharacterBody3D, at: Vector3, lvl: int, rank: int) -> CharacterBody3D:
	var enemy := CharacterBody3D.new()
	enemy.set_script(load("res://scripts/hybrid_enemy.gd"))
	enemy.setup(lvl, rank)
	parent.add_child(enemy)
	enemy.position = at
	enemy.target = target
	return enemy

func _initialize() -> void:
	seed(4242) # rolagens de acerto determinísticas
	var catalog: Dictionary = AethelItemCatalog.create_catalog()
	var world := Node3D.new()
	root.add_child(world)
	var player := CharacterBody3D.new()
	player.set_script(load("res://scripts/hybrid_player.gd"))
	world.add_child(player)
	await process_frame
	# --- atributos base (valores ao estilo clássico: 55 + 4*vit)
	_check(player.max_hp == 55 + 25 * 4, "vida base = 155 (%d)" % player.max_hp)
	_check(player.max_ether == 10 + 15, "éter base = 25 (%d)" % player.max_ether)
	# --- equipar: requisitos e troca
	var axe := AethelItemInstance.new(catalog["hand_axe"])
	var result: Dictionary = player.equip_item(axe)
	_check(result["ok"] and result["slot"] == "weapon", "equipar machado")
	var dmg_before: float = player.damage_max
	_check(absf(player.damage_min - 6.0 * 1.3) < 0.01 and absf(player.damage_max - 12.0 * 1.3) < 0.01, "dano = arma * (1+força/100)")
	var unique := AethelItemInstance.new(catalog["unq_sino"])
	var denied: Dictionary = player.equip_item(unique)
	_check(not denied["ok"] and "nível" in str(denied["reason"]), "único bloqueado por nível: " + str(denied.get("reason")))
	player.character_level = 8
	player.stats.strength = 35
	player.recalculate_stats()
	var swapped: Dictionary = player.equip_item(unique)
	_check(swapped["ok"] and swapped["replaced"] == axe, "troca de arma devolve a anterior")
	_check(player.damage_max > dmg_before * 1.5, "único aumenta bastante o dano (%f -> %f)" % [dmg_before, player.damage_max])
	_check(player.attack_speed_mult > 1.09, "velocidade de ataque do único")
	var back: AethelItemInstance = player.unequip_slot("weapon")
	_check(back == unique and not player.equipped.has("weapon"), "desequipar")
	player.character_level = 1
	player.stats.strength = 30
	player.equipped.clear()
	player.equip_item(axe)
	var ring_a := AethelItemInstance.new(catalog["plain_ring"])
	var ring_b := AethelItemInstance.new(catalog["plain_ring"])
	_check(player.equip_item(ring_a)["slot"] == "ring1" and player.equip_item(ring_b)["slot"] == "ring2", "dois anéis")
	# --- escudo e bloqueio
	var shield := AethelItemInstance.new(catalog["old_shield"])
	player.equip_item(shield)
	_check(player.block_chance > 40.0 and player.block_chance <= 75.0, "bloqueio estilo clássico: %f" % player.block_chance)
	player.unequip_slot("shield")
	# --- poções
	player.hp = 50
	player.ether = 5
	player.drink_potion(45, 30)
	_check(player.hp == 95 and player.ether == 25, "poções curam e respeitam o máximo (%d/%d)" % [player.hp, player.ether])
	# --- clique para mover
	player.global_position = Vector3.ZERO
	player.command_move(Vector3(5, 0, 0))
	for i in 120: await physics_frame
	_check(player.global_position.distance_to(Vector3(5, 0, 0)) < 0.5, "chega ao ponto clicado (%s)" % str(player.global_position))
	_check(not player.has_move_target, "limpa o destino ao chegar")
	# --- clique para atacar: persegue e mata
	player.global_position = Vector3.ZERO
	var enemy: CharacterBody3D = _spawn_enemy(world, player, Vector3(7, 0, 0), 1, 0)
	player.command_attack(enemy)
	for i in 420:
		await physics_frame
		if not is_instance_valid(enemy): break
	_check(not is_instance_valid(enemy), "ataque por clique persegue e mata a Rasura")
	_check(player.hp > 0, "jogador sobrevive a 1 Rasura de nível 1")
	# --- ataque em área mata grupo e erra/acerta por defesa
	for e in get_nodes_in_group("hybrid_enemies"): e.queue_free()
	await process_frame
	player.global_position = Vector3.ZERO
	player.hp = player.max_hp
	player.ether = player.max_ether
	var pack: Array[CharacterBody3D] = []
	for p in [Vector3(1.5, 0, 0), Vector3(-1.5, 0, 0), Vector3(0, 0, 1.5)]:
		var member := _spawn_enemy(world, player, p, 1, 0)
		pack.append(member)
	var cleave := AethelSkillData.new()
	cleave.skill_id = &"echo_cleave"
	cleave.ether_cost = 18
	cleave.cooldown = 4.0
	player.attack_cooldown = 0.0
	_check(player.use_skill(cleave) == "", "usar Corte do Eco")
	_check(player.ether == player.max_ether - 18, "gasta éter")
	_check(player.use_skill(cleave) != "", "habilidade entra em recarga")
	var damaged: int = 0
	for member in pack:
		if is_instance_valid(member) and member.hp < member.max_hp: damaged += 1
		elif not is_instance_valid(member): damaged += 1
	_check(damaged >= 2, "Corte do Eco atinge 360° (%d de 3 atingidos)" % damaged)
	# --- campeão: mais vida, mais XP
	var champion: CharacterBody3D = _spawn_enemy(world, player, Vector3(9, 0, 9), 5, 1)
	var normal: CharacterBody3D = _spawn_enemy(world, player, Vector3(9, 0, -9), 5, 0)
	_check(champion.max_hp > normal.max_hp * 2 and champion.xp_value >= normal.xp_value * 4, "campeão tem 2.6x vida e 4x XP")
	_check(champion.display_name().contains("Campeã"), "nome do campeão")
	# --- guarda de ferro reduz dano
	player.invulnerability = 0.0
	player.hp = 100
	player.guard_remaining = 5.0
	player.take_damage(50)
	_check(player.hp == 70, "guarda reduz 40%% do dano (hp=%d)" % player.hp)
	# --- morte
	var died: Array[bool] = [false]
	player.died.connect(func() -> void: died[0] = true)
	player.invulnerability = 0.0
	player.guard_remaining = 0.0
	player.take_damage(9999)
	_check(died[0] and player.hp == 0, "sinal de morte")
	if failures.is_empty():
		print("COMBAT TEST OK")
		quit(0)
	else:
		for message in failures: printerr("FALHA: ", message)
		quit(1)
