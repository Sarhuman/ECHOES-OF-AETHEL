extends SceneTree
# godot --headless --path . --script res://tests/test_ui_smoke.gd
# Abre todos os painéis e mostra tooltips para detectar erros de runtime na interface.
var failures: Array[String] = []

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _initialize() -> void:
	seed(5)
	var save_path: String = AethelSavePaths.current()
	if FileAccess.file_exists(save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var world: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	var player: CharacterBody3D = world.player
	# preenche mochila com itens de todos os tipos de qualidade
	for quality in [0, 1, 2, 4]:
		for i in 6:
			var item: AethelItemInstance = world.loot_generator.roll_item(12, 1, 0.0, quality)
			if item != null: world.inventory.add_item(item)
	player.global_position = Vector3(-9, 0, 4)
	for panel in [world.inventory_view, world.character_panel, world.skills_panel, world.shop_panel]:
		panel.visible = true
	world._refresh_all()
	world._refresh_shop()
	await process_frame
	await process_frame
	_check(world.inventory_view.item_root.get_child_count() >= 1, "mochila desenha itens")
	_check(world.inventory_view.equip_root.get_child_count() == 12, "lista de equipamento tem 12 slots")
	# tooltip de cada item da mochila
	var tooltip: AethelItemTooltip = world.inventory_view.tooltip
	for entry: Dictionary in world.inventory.entries():
		tooltip.show_item(entry["instance"])
		_check(tooltip.visible and tooltip._text.text.length() > 10, "tooltip tem texto")
	var unique := AethelItemInstance.new(world.item_catalog["unq_sino"])
	tooltip.show_item(unique)
	_check("Cutelo do Último Sino" in tooltip._text.text and "Requer" in tooltip._text.text, "tooltip do único mostra nome e requisitos")
	tooltip.show_item(AethelItemInstance.new(world.item_catalog["hp_small"]))
	_check("Recupera 45" in tooltip._text.text, "tooltip de poção")
	tooltip.hide_item()
	# painéis esquerdos exclusivos
	world.character_panel.visible = false
	world._toggle_left_panel(world.character_panel)
	_check(world.character_panel.visible and not world.skills_panel.visible and not world.shop_panel.visible, "painéis esquerdos são exclusivos")
	world.skills_panel.visible = false
	world._toggle_left_panel(world.skills_panel)
	_check(world.skills_panel.visible and not world.character_panel.visible, "alternar para habilidades")
	# loja: comprar poção, comprar equipamento e vender
	world.player.position = world.merchant.position + Vector3(2,0,0)
	world.gold = 500
	world.shop_panel.visible = false
	world._toggle_left_panel(world.shop_panel)
	var belt_potions: int = 0
	var potion := AethelItemInstance.new(world.item_catalog["hp_small"])
	world._purchase(potion, true)
	for slot: Dictionary in world.belt: belt_potions += int(slot.get("count", 0))
	_check(belt_potions == 4 and world.gold == 475, "comprar poção (%d, ouro %d)" % [belt_potions, world.gold])
	for entry: Dictionary in world.inventory.entries(): world.inventory.remove_item(entry["instance"].instance_id)
	var stock_item: AethelItemInstance = world.shop_stock[0]
	var price: int = world._buy_price(stock_item)
	var gold_before: int = world.gold
	world._purchase(stock_item, false)
	_check(world.gold == gold_before - price and world.inventory.find_item(stock_item.instance_id) != null, "comprar equipamento")
	world._on_sell_requested(stock_item.instance_id)
	_check(world.inventory.find_item(stock_item.instance_id) == null and world.gold > gold_before - price, "vender equipamento")
	# cinto cheio: potão extra cai para a mochila
	for index in 4: world.belt[index] = {"kind": "hp_small", "count": 4}
	_check(world._add_potion(AethelItemInstance.new(world.item_catalog["hp_small"])), "potão excedente vai para a mochila")
	# HUD
	world.hud.show_target("Rasura Campeã", 50, 100, Color("8c8cff"))
	_check(world.hud.target_box.visible, "barra do alvo")
	world.hud.hide_target()
	await process_frame
	# Alt mostra rótulos de itens comuns
	var drop := AethelDroppedItem.new()
	drop.item = AethelItemInstance.new(world.item_catalog["hand_axe"])
	world.add_child(drop)
	world.dropped_items.append(drop)
	_check(not drop.default_label_visible(), "item comum não mostra rótulo por padrão")
	var gold_drop := AethelDroppedItem.new()
	gold_drop.gold_amount = 42
	world.add_child(gold_drop)
	await process_frame
	_check(gold_drop.label.text == "42 Ouro" and gold_drop.default_label_visible(), "pilha de ouro mostra rótulo")
	if FileAccess.file_exists(save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	if failures.is_empty():
		print("UI SMOKE TEST OK")
		quit(0)
	else:
		for message in failures: printerr("FALHA: ", message)
		quit(1)
