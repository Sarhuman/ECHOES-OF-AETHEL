extends SceneTree
var failures: Array[String] = []

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func count_orbs(node: Node) -> int:
	var count := 1 if node is AethelGlobe else 0
	for child in node.get_children(): count += count_orbs(child)
	return count

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var hud = world.hud
	check(hud.root.find_children("ResourcePanel", "PanelContainer", true, false).size() == 1, "painel unico")
	check(count_orbs(hud.root) == 2, "dois globos reativos ativos")
	check(hud.resource_panel.find_children("*", "ProgressBar", true, false).size() == 1, "barra compacta de folego junto aos globos")
	world.player.hp_changed.emit(45, 100, true)
	world.player.ether_changed.emit(12, 40, true)
	world.player.stamina_changed.emit(30, 100)
	check(hud.hp_bar.value == 45 and "45 / 100" in hud.hp_text.text, "vida sinalizada")
	check(hud.ether_bar.value == 12 and "12 / 40" in hud.ether_text.text, "eter sinalizado")
	check(hud.stamina_bar.value == 30 and "30 / 100" in hud.stamina_text.text, "folego sinalizado")
	for resolution in [Vector2i(1280,720), Vector2i(1366,768), Vector2i(1280,800)]:
		root.size = resolution
		await process_frame
		await process_frame
		var bounds: Rect2 = hud.resource_panel.get_global_rect()
		check(Rect2(Vector2.ZERO, Vector2(resolution)).encloses(bounds), "painel dentro da tela %s" % resolution)
		check(not bounds.intersects(world.inventory_view.get_global_rect()), "mochila nao sobrepoe recursos %s" % resolution)
	check(load("res://src/characters/character_visual.gd") != null, "modulo visual carrega")
	check(load("res://src/characters/equipment_visual.gd") != null, "modulo equipamento carrega")
	world.queue_free()
	await process_frame
	if failures.is_empty():
		print("HUD REVISION TEST OK")
	else:
		for message in failures: printerr("FALHA: ", message)
	quit(0 if failures.is_empty() else 1)
