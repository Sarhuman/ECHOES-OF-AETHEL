extends SceneTree
# Bot de balanceamento: godot --headless --path . --script res://tests/balance_bot.gd
# Joga o Bairro que Faltava clicando nos inimigos mais próximos e bebendo poções com vida baixa.
func _initialize() -> void:
	var save_path: String = AethelSavePaths.current()
	var results: Array[String] = []
	var wins: int = 0
	var trials: int = 10
	for trial in trials:
		seed(1000 + trial)
		if FileAccess.file_exists(save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
		var world: Node3D = load("res://scenes/main.tscn").instantiate()
		root.add_child(world)
		await process_frame
		world.loot_generator.set_seed(500 + trial)
		var player: CharacterBody3D = world.player
		player.rng.seed = 9000 + trial
		world.quest_started = true
		world.region_id = "map_02"
		world._update_region()
		var frames: int = 0
		var potions_used: int = 0
		while frames < 3600 and not world.game_over and world.slain < 5:
			await physics_frame
			frames += 1
			if frames % 20 == 0:
				var nearest: CharacterBody3D = null
				var best: float = INF
				for enemy in world.enemies:
					if is_instance_valid(enemy):
						var d: float = enemy.global_position.distance_to(player.global_position)
						if d < best:
							best = d
							nearest = enemy
				if nearest != null and not is_instance_valid(player.attack_target): player.command_attack(nearest)
				if player.hp < player.max_hp * 0.4:
					for index in 4:
						var entry: Dictionary = world.belt[index]
						if not entry.is_empty() and str(entry["kind"]).begins_with("hp_"):
							world.last_drink_time = 0.0
							world._drink_belt(index)
							potions_used += 1
							break
		var won: bool = world.slain >= 5 and not world.game_over
		if won: wins += 1
		results.append("trial %d: %s em %.1fs | vida %d/%d | nível %d | poções %d | drops %d" % [trial, "VITÓRIA" if won else "derrota/tempo", frames / 60.0, player.hp, player.max_hp, player.character_level, potions_used, world.dropped_items.size()])
		world.queue_free()
		await process_frame
	for line in results: print(line)
	print("VITÓRIAS: %d/%d" % [wins, trials])
	if FileAccess.file_exists(save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	quit(0 if wins == trials else 1)
