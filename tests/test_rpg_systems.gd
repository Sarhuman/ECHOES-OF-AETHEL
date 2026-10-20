extends SceneTree
# godot --headless --path . --script res://tests/test_rpg_systems.gd
# Usa checagens explícitas: qualquer falha encerra com código 1 (assert não garante isso).
var failures: Array[String] = []

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _initialize() -> void:
	var progress := AethelProgressionManager.new()
	root.add_child(progress)
	progress.gain_xp(100)
	_check(progress.current_level == 2, "XP 100 deve levar ao nível 2")
	_check(progress.skill_points == 1, "subir de nível dá 1 ponto")
	var skills := AethelSkillTree.new()
	root.add_child(skills)
	skills.configure(progress)
	_check(skills.unlock("heavy_strike"), "desbloquear Golpe Pesado")
	_check(progress.skill_points == 0, "ponto gasto")
	_check(not skills.unlock("heavy_strike"), "não desbloqueia duas vezes")
	var restored := AethelProgressionManager.new()
	root.add_child(restored)
	restored.restore(progress.serialize())
	_check(restored.current_level == 2, "restore da progressão")
	var inventory := AethelInventoryManager.new()
	root.add_child(inventory)
	var catalog: Dictionary = AethelItemCatalog.create_catalog()
	var item := AethelItemInstance.new(catalog["iron_axe"])
	_check(inventory.add_item(item), "adicionar machado")
	_check(not inventory.add_item(item), "mesmo item não entra duas vezes")
	var loaded := AethelInventoryManager.new()
	root.add_child(loaded)
	loaded.restore(inventory.serialize(), catalog)
	_check(loaded.entries().size() == 1, "restore do inventário")
	_check(loaded.occupied_count() == 6, "machado ocupa 2x3 células")
	# Save com posição inválida não pode perder o item
	var recovered := AethelInventoryManager.new()
	root.add_child(recovered)
	recovered.restore({"items":[{"id":"a1","item_id":"iron_axe","x":-1,"y":-1},{"id":"a2","item_id":"iron_axe","x":9,"y":3}]}, catalog)
	_check(recovered.entries().size() == 2, "itens com posição inválida devem ser recolocados")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("RPG SYSTEMS TEST OK")
		quit(0)
	else:
		for message in failures:
			printerr("FALHA: ", message)
		quit(1)
