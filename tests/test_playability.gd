extends SceneTree
var failures: Array[String] = []
var checks := 0
var world: Node3D

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for index in count: await physics_frame
	await process_frame

func press(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)

func point_cursor(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)

func target_at(point: Vector3, rank: int = 0) -> CharacterBody3D:
	var enemy: CharacterBody3D = world._spawn_enemy(point,1,rank)
	enemy.set_physics_process(false)
	enemy.hp = 9999
	enemy.max_hp = 9999
	enemy.defense = 0
	return enemy

func run() -> void:
	seed(2020)
	Input.use_accumulated_input = false
	world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await frames(2)
	var player: CharacterBody3D = world.player
	var camera: Camera3D = root.get_camera_3d()
	check(camera.projection == Camera3D.PROJECTION_ORTHOGONAL and absf(camera.size - 12) < 0.01, "enquadramento inicial mais amplo")
	var boss := target_at(Vector3(4,0,0),2)
	await frames(2)
	# Rank-2 target exercises the visible head of the large enemy without inventing a campaign boss.
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1366,768),Vector2i(1280,800)]:
		root.size = resolution
		await frames(2)
		for zoom in [10.0,12.0,18.0]:
			camera.set_zoom(zoom,false)
			camera.size = zoom
			camera.snap_to_target()
			await frames(2)
			var head := camera.unproject_position(boss.global_position + Vector3(0,1.47 * 1.45,0))
			check(world.pick_enemy_at(head) == boss, "raycast seleciona cabeca %s zoom %s" % [resolution,zoom])
			var floor_point := Vector3(2,0,2)
			var floor_click := camera.unproject_position(floor_point)
			var projected: Variant = world.ground_point_at(floor_click)
			check(projected != null and projected.distance_to(floor_point) < 0.05, "projecao do chao %s zoom %s" % [resolution,zoom])
	check(world.ground_point_at(Vector2(-10,-10)) == null, "clique fora da tela rejeitado")
	# A collider above the floor must not produce a destination behind its visible surface.
	var blocker := StaticBody3D.new()
	blocker.position = Vector3(-3,0,-2)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2,3,2)
	shape.shape = box
	shape.position.y = 1.5
	blocker.add_child(shape)
	world.add_child(blocker)
	await frames(2)
	check(world.ground_point_at(camera.unproject_position(blocker.position + Vector3(0,1.5,0))) == null, "obstaculo nao vira ponto de chao")
	blocker.queue_free()
	camera.set_zoom(12,false)
	camera.size = 12
	camera.snap_to_target()
	player.rng.seed = 5
	var start: Vector3 = player.position
	var before_distance := player.global_position.distance_to(boss.global_position)
	var head := camera.unproject_position(boss.global_position + Vector3(0,2.13,0))
	world._on_left_press(head)
	world._on_left_release()
	check(player.attack_target == boss and not player.has_move_target, "clique no alvo nao emite movimento de chao")
	await frames(5)
	check(player.position.distance_to(boss.position) < before_distance, "aproxima na direcao do alvo")
	check((player.position-start).dot(boss.position-start) > 0, "nao inverte direcao")
	for index in 180:
		if index % 10 == 0:
			world._on_left_press(camera.unproject_position(boss.global_position + Vector3(0,2.13,0)))
			world._on_left_release()
		await physics_frame
	check(boss.hp < 9999, "ataque aplicado apos aproximacao por clique repetido")
	var offset := boss.global_position - player.global_position
	offset.y = 0
	check(offset.length() <= player.ATTACK_REACH + 0.1 and offset.length() > 0.7, "para no alcance sem atravessar inimigo")
	check(player.facing.dot(offset.normalized()) > 0.95, "olha para o alvo ao atacar")
	check(player.velocity.length() < 0.01, "interrompe deslocamento no ataque")
	player.clear_commands()
	player.position = Vector3.ZERO
	boss.position = Vector3(0,0,-1.5)
	player.attack_cooldown = 0
	player.attack_recovery = 0
	camera.snap_to_target()
	await frames(2)
	Input.action_press("stand_attack")
	Input.action_press("primary")
	var stationary: Vector3 = player.position
	var before_hp: int = boss.hp
	point_cursor(camera.unproject_position(boss.position + Vector3(0,2.13,0)))
	world._on_left_press(camera.unproject_position(boss.position + Vector3(0,2.13,0)))
	await frames(75)
	Input.action_release("primary")
	Input.action_release("stand_attack")
	world._on_left_release()
	check(player.position.distance_to(stationary) < 0.05 and boss.hp < before_hp, "Shift clique ataca parado")
	# Real input dispatch, not direct calls to the skill implementation.
	player.attack_cooldown = 0
	player.attack_recovery = 0
	player.ether = player.max_ether
	player.clear_commands()
	point_cursor(camera.unproject_position(boss.position + Vector3(0,2.13,0)))
	player.rng.seed = 5
	before_hp = boss.hp
	await press(KEY_F1)
	check(boss.hp < before_hp and player.ether == player.max_ether-10, "F1 causa dano e consome recurso (hp %d -> %d, eter %d, mensagem %s)" % [before_hp,boss.hp,player.ether,world.transient_message])
	check(player.skill_cooldowns.get("heavy_strike",0) > 0 and player.attack_recovery > 0, "F1 anima e inicia recuperacao")
	var before_ether: int = player.ether
	before_hp = boss.hp
	await press(KEY_F1)
	check(player.ether == before_ether and boss.hp == before_hp, "cooldown impede gasto e dano repetidos")
	check("Recarga" in world.hud.skill_buttons[0].text, "HUD mostra cooldown")
	player.skill_cooldowns.clear()
	player.attack_cooldown = 0
	player.ether = 0
	await press(KEY_F3)
	check(player.ether == 0 and not player.skill_cooldowns.has("echo_cleave"), "sem eter nao inicia habilidade")
	check("Sem Éter" in world.hud.skill_buttons[2].text, "HUD mostra falta de recurso")
	player.ether = player.max_ether
	await press(KEY_F2)
	check(player.guard_remaining > 7.8, "F2 ativa guarda")
	player.invulnerability = 0
	player.hp = 100
	player.take_damage(50)
	check(player.hp == 70, "guarda reduz dano em 40 por cento")
	before_ether = player.ether
	await press(KEY_F2)
	check(player.guard_remaining == 0 and player.ether == before_ether, "F2 cancela sem cobrar novamente")
	player.skill_cooldowns.erase("iron_guard")
	player.ether = player.max_ether
	await press(KEY_F2)
	player.guard_remaining = 0.03
	await frames(8)
	check(player.guard_remaining == 0, "guarda expira")
	var ring: MeshInstance3D = player.get_node("BastiaoVisual/Model/GuardIndicator")
	check(not ring.visible, "indicador defensivo desativa")
	for enemy in world.enemies: enemy.queue_free()
	world.enemies.clear()
	await frames(2)
	player.position = Vector3.ZERO
	var pack: Array[CharacterBody3D] = []
	for point in [Vector3(1.5,0,0),Vector3(-1.5,0,0),Vector3(0,0,-1.5)]: pack.append(target_at(point))
	await frames(2)
	player.skill_cooldowns.clear()
	player.attack_cooldown = 0
	player.ether = player.max_ether
	player.rng.seed = 5
	await press(KEY_F3)
	var damaged := 0
	for enemy in pack:
		if enemy.hp < 9999: damaged += 1
	check(damaged >= 2 and player.ether == player.max_ether-18, "F3 aplica corte em area com custo")
	player.skill_cooldowns.clear()
	player.attack_cooldown = 0
	player.attack_recovery = 0
	player.ether = player.max_ether
	player.command_move(Vector3(8,0,0))
	await frames(2)
	await press(KEY_F1)
	check(not player.has_move_target and player.velocity.length() < 0.01, "habilidade interrompe movimento anterior")
	# Existing alternative inputs and merchant interaction remain usable.
	player.position = world.merchant.position + Vector3(2,0,0)
	await frames(3)
	check(world.merchant.get_node("InteractionArea").overlaps_body(player), "area de interacao independente do visual")
	check(not world.merchant.find_children("LeatherApron","Node3D",true,false).is_empty(), "Doma tem avental e silhueta humana")
	await press(KEY_E)
	check(world.shop_panel.visible, "E abre loja de Doma")
	await press(KEY_L)
	check(not world.shop_panel.visible, "L continua alternando loja")
	AethelInput.bind_interact(KEY_F)
	await press(KEY_F)
	check(world.shop_panel.visible, "interacao reconfigurada para F preservada")
	world.shop_panel.hide()
	AethelInput.bind_interact(KEY_E)
	check(not world.help_panel.visible, "ajuda recolhida por padrao")
	await press(KEY_H)
	check(world.help_panel.visible, "H abre ajuda")
	await press(KEY_H)
	check(not world.help_panel.visible, "H fecha ajuda")
	check(world.progression_label.get_global_rect().position.y > root.size.y-120, "informacao do personagem fora do topo")
	# Clicking a HUD skill must not make Space activate that button instead of dodging.
	var button_point: Vector2 = world.hud.skill_buttons[0].get_global_rect().get_center()
	point_cursor(button_point)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = button_point
	click.global_position = button_point
	click.pressed = true
	Input.parse_input_event(click)
	await process_frame
	click = click.duplicate()
	click.pressed = false
	Input.parse_input_event(click)
	await frames(20)
	player.attack_cooldown = 0
	player.attack_recovery = 0
	player.skill_cooldowns.clear()
	player.ether = player.max_ether
	player.stamina = player.max_stamina
	var before_dodge: Vector3 = player.position
	await press(KEY_SPACE)
	await frames(10)
	check(player.position.distance_to(before_dodge) > 0.5 and player.ether == player.max_ether, "Espaco apos clicar habilidade esquiva sem executar botao focado")

	for action in ["move_left","move_right","move_up","move_down","inventory","interact","primary","secondary","dodge","block","save","load","pause"]:
		check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), "controle preservado " + action)
	camera.set_zoom(999,false)
	check(camera.zoom_target == 18, "limite de afastamento")
	camera.set_zoom(-1,false)
	check(camera.zoom_target == 10, "limite de aproximacao")
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	camera._unhandled_input(wheel)
	check(camera.zoom_target == 11, "roda afasta camera")
	camera.set_zoom(15,true)
	AethelSettings.camera_zoom = 12
	AethelSettings.load_settings()
	check(AethelSettings.camera_zoom == 15, "preferencia de zoom persistida")
	player.position = Vector3(999,0,-999)
	camera.snap_to_target()
	var focus_point: Vector3 = camera.global_position - camera.follow_offset
	check(absf(focus_point.x) <= 13 and absf(focus_point.z) <= 13, "limites de acompanhamento")
	print("PLAYABILITY: %d verificacoes, %d falhas" % [checks,failures.size()])
	for message in failures: printerr("FALHA: ",message)
	quit(0 if failures.is_empty() else 1)
