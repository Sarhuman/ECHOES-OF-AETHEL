extends Node3D
## Mundo híbrido 2.5D de Echoes of Aethel — Fase 20: núcleo de jogabilidade de ARPG clássico.
## Clique: mover/atacar/pegar | Shift: atacar parado | Botão direito: habilidade | 1-4: poções | Alt: nomes dos itens.

signal target_changed(actor: CharacterBody3D)
signal mission_changed

const PLAYER_SCRIPT = preload("res://scripts/hybrid_player.gd")
const ENEMY_SCRIPT = preload("res://scripts/hybrid_enemy.gd")
const SAVE_VERSION: int = 6
var SAVE_PATH: String = AethelSavePaths.current()
const BELT_SLOTS: int = 4
const BELT_STACK: int = 4
const SKILL_IDS: Array = ["heavy_strike", "iron_guard", "echo_cleave"]
const RANK_PICK_SCALE: Array = [1.0, 1.2, 1.45]
const RANK_NAME_COLORS: Array = [Color("e8e8e8"), Color("8c8cff"), Color("c7b377")]

var player: CharacterBody3D
var enemies: Array[CharacterBody3D] = []
var status_label: Label
var hint_label: Label
var floating_layer: Control
var active_popups: Array[Dictionary] = []
var slain: int = 0
var game_over: bool = false
var region_id: String = "map_01"
var quest_started: bool = false
var quest_completed: bool = false
var map_02_cleared: bool = false
var npc: Node3D
var gate: Node3D
var rng := RandomNumberGenerator.new()
var inventory: AethelInventoryManager
var item_catalog: Dictionary = {}
var loot_generator: AethelLootGenerator
var dropped_items: Array[AethelDroppedItem] = []
var inventory_view: AethelInventoryView
var character_panel: AethelCharacterPanel
var progression: AethelProgressionManager
var skill_tree: AethelSkillTree
var skills_panel: PanelContainer
var skills_info: Label
var skills_rows: Dictionary = {}
var shop_panel: PanelContainer
var shop_column: VBoxContainer
var shop_tooltip: AethelItemTooltip
var shop_stock: Array = []
var hud: AethelHUDManager
var progression_label: Label
var gold: int = 0
var belt: Array = [{}, {}, {}, {}]
var right_skill_id: String = ""
var left_held: bool = false
var hold_mode: String = ""
var pickup_target: AethelDroppedItem = null
var hovered_enemy: CharacterBody3D = null
var hovered_drop: AethelDroppedItem = null
var message_until: float = 0.0
var transient_message: String = ""
var last_drink_time: float = 0.0
var merchant: StaticBody3D
var help_panel: PanelContainer
var message_label: Label
var audio: AethelAudioManager
var presented_target: CharacterBody3D
var quest_panel: PanelContainer
var quest_text: RichTextLabel
var death_overlay: Control
var _mission_signature: Array = []
var exploration: AethelExploration
var narrative: AethelNPCController
var workshop: Node3D
var stock_initialized := false
var pause_menu: AethelPauseMenu

func _ready() -> void:
	AethelInput.ensure_defaults()
	audio = AethelAudioManager.new()
	add_child(audio)
	rng.seed = 2047
	item_catalog = AethelItemCatalog.create_catalog()
	loot_generator = AethelLootGenerator.new(item_catalog)
	_build_world()
	_build_player()
	_build_ui()
	_build_resource_hud()
	_setup_inventory()
	_setup_rpg_systems()
	_build_narrative_nodes()
	_build_merchant()
	_build_workshop()
	narrative = AethelNPCController.new()
	add_child(narrative)
	narrative.setup(self)
	exploration = AethelExploration.new()
	add_child(exploration)
	exploration.setup(self)
	_setup_reactive_ui()
	var new_game: bool = bool(Engine.get_meta("aethel_new_game", false))
	Engine.remove_meta("aethel_new_game")
	if new_game or not _load_state(): _give_starting_gear()
	_grant_training_skills()
	pause_menu = AethelPauseMenu.new()
	add_child(pause_menu)
	pause_menu.save_requested.connect(_save_state)
	pause_menu.inspect_requested.connect(func() -> void: character_panel.show())
	pause_menu.options.preferences_changed.connect(hud.apply_settings)
	_roll_shop_stock()
	_refresh_all()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if "--smoke-gameplay" in OS.get_cmdline_user_args():
		print("SMOKE GAMEPLAY READY: player=%s inventory=%s hp=%d equipment=%d" % [player != null, inventory != null, player.hp, player.equipped.size()])

	if "--verify-build" in OS.get_cmdline_user_args():
		var probe := preload("res://src/core/build_smoke.gd").new()
		add_child(probe)
		probe.call_deferred("run")

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.92
	return m

func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool = true) -> void:
	var body := StaticBody3D.new() if solid else Node3D.new()
	parent.add_child(body)
	body.position = pos
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = _mat(color)
	body.add_child(mesh)
	if solid:
		var shape := CollisionShape3D.new()
		var cube_shape := BoxShape3D.new()
		cube_shape.size = size
		shape.shape = cube_shape
		body.add_child(shape)

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("151827")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("7684a2")
	env.ambient_light_energy = 0.34
	env.fog_enabled = true
	env.fog_light_color = Color("28283d")
	env.fog_density = 0.009
	environment.environment = env
	add_child(environment)
	_build_ground()
	# Arquitectura autoral de Vigília: praça pavimentada, ruínas góticas e caminhos livres.
	_build_vigilia_architecture()
	for p in [Vector3(-12,0,-12),Vector3(12,0,-12),Vector3(-12,0,12),Vector3(12,0,12)]:
		var torch := OmniLight3D.new()
		torch.position = p + Vector3(0,3.1,0)
		torch.light_color = Color("ff9944")
		torch.light_energy = 2.0
		torch.shadow_enabled = true
		torch.omni_range = 10.0
		add_child(torch)
		_box(self,p+Vector3(0,1.2,0),Vector3(0.95,2.4,0.95),Color("555566"))
		_box(self,p+Vector3(0,2.6,0),Vector3(1.22,0.3,1.22),Color("81716a"),false)
		_box(self,p+Vector3(0,2.85,0),Vector3(0.42,0.25,0.42),Color("ed863e"),false)

func _build_vigilia_architecture() -> void:
	# A via central fica livre para deslocamento e interação.
	for index in range(8):
		var z: float = -12.0 + float(index)*3.3
		for x in [-15.0,15.0]:
			_box(self,Vector3(x,1.25,z),Vector3(1.9,2.5,1.9),Color("555363"))
			_box(self,Vector3(x,2.62,z),Vector3(2.2,0.25,2.2),Color("89808a"),false)
			_box(self,Vector3(x,0.22,z),Vector3(2.3,0.44,2.3),Color("393a47"),false)
	# Seções de muralha em volta, interrompidas nas entradas.
	for z in [-16.0,16.0]:
		for x in [-12.0,-8.0,-4.0,4.0,8.0,12.0]:
			_box(self,Vector3(x,1.15,z),Vector3(3.6,2.3,0.9),Color("454452"))
			_box(self,Vector3(x,2.45,z),Vector3(3.8,0.28,1.12),Color("6d6470"),false)
	for x in [-10.5,10.5]:
		for z in [-9.0,9.0]:
			# Pedestais e estátuas como marcos legíveis, fora do caminho principal.
			_box(self,Vector3(x,0.45,z),Vector3(2.0,0.9,2.0),Color("615d66"))
			_box(self,Vector3(x,1.7,z),Vector3(0.72,1.8,0.72),Color("77737d"),false)
			_box(self,Vector3(x,2.75,z),Vector3(1.2,0.28,1.2),Color("99909a"),false)
	# Piso de blocos individualizados no centro: evita textura ampliada e ruído excessivo.
	var palette: Array[Color] = [Color("4d4a55"),Color("56515b"),Color("635b61"),Color("4a4752")]
	for iz in range(22):
		for ix in range(22):
			var p_x: float = (float(ix)-10.5)*1.28 + (0.19 if iz%2==0 else -0.19)
			var p_z: float = (float(iz)-10.5)*1.28
			var stone := MeshInstance3D.new()
			var stone_mesh := BoxMesh.new()
			stone_mesh.size = Vector3(1.20,0.06,1.20)
			stone.mesh = stone_mesh
			stone.position = Vector3(p_x,0.035,p_z)
			stone.material_override = _mat(palette[(ix*7+iz*3)%palette.size()])
			add_child(stone)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50,-30,0)
	sun.light_color = Color("8692c2")
	sun.light_energy = 0.32
	sun.shadow_enabled = true
	add_child(sun)

func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.set_meta("walkable_ground", true)
	body.position = Vector3(0,-0.28,0)
	add_child(body)
	var tile := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(34,34)
	mesh.subdivide_width = 12
	mesh.subdivide_depth = 12
	tile.mesh = mesh
	tile.position.y = 0.28
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("c8bac0")
	mat.albedo_color = Color("373643")
	tile.material_override = mat
	body.add_child(tile)
	var shape := CollisionShape3D.new()
	var cube := BoxShape3D.new()
	cube.size = Vector3(34,0.5,34)
	shape.shape = cube
	body.add_child(shape)

func _build_narrative_nodes() -> void:
	npc = Node3D.new()
	npc.name = "MaeraVoss"
	add_child(npc)
	npc.position = Vector3(-4,0,2)
	var npc_visual: Node3D = Node3D.new()
	npc_visual.name = "MaeraVisual"
	npc_visual.set_script(preload("res://scripts/procedural_npc.gd"))
	npc.add_child(npc_visual)
	gate = Node3D.new()
	gate.name = "Portal"
	add_child(gate)
	gate.position = Vector3(11,0,0)
	_box(gate, Vector3(0,1.4,0), Vector3(0.35,2.8,2.3), Color("7962bd"), false)
	_update_region()

func _build_merchant() -> void:
	merchant = StaticBody3D.new()
	merchant.name = "DomaFerren"
	merchant.position = Vector3(-9,0,2)
	merchant.collision_layer = 8
	merchant.collision_mask = 2
	merchant.add_to_group("merchants")
	add_child(merchant)
	var body := CollisionShape3D.new()
	body.name = "BodyCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	body.shape = capsule
	body.position.y = 0.9
	merchant.add_child(body)
	var interaction := Area3D.new()
	interaction.name = "InteractionArea"
	interaction.collision_layer = 32
	interaction.collision_mask = 2
	var interaction_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3
	interaction_shape.shape = sphere
	interaction.add_child(interaction_shape)
	merchant.add_child(interaction)
	var model := Node3D.new()
	model.name = "DomaVisual"
	model.set_script(preload("res://scripts/procedural_npc.gd"))
	model.set("role", &"blacksmith")
	model.rotation.y = -3 * PI / 4
	merchant.add_child(model)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Bastiao"
	player.set_script(PLAYER_SCRIPT)
	add_child(player)
	player.position = Vector3(0, 0, 4)
	player.died.connect(_on_player_died)
	player.combat_event.connect(_on_combat_event)
	var camera := Camera3D.new()
	camera.set_script(preload("res://src/core/follow_camera.gd"))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.0
	# Projeção ortográfica inclinada; yaw 45°, pitch 35,264°, zoom inicial 12.
	camera.rotation_degrees = Vector3(-35.264, 45.0, 0.0)
	camera.position = Vector3(12.25, 12.25, 12.25)
	camera.current = true
	player.add_child(camera)
	camera.top_level = true
	camera.target = player
	camera.snap_to_target()
	var warm_light := OmniLight3D.new()
	warm_light.position = Vector3(0, 2.2, 0)
	warm_light.light_color = Color("ffae70")
	warm_light.light_energy = 0.75
	warm_light.omni_range = 7.5
	player.add_child(warm_light)

func _give_starting_gear() -> void:
	for starter_id: String in ["wood_shield", "quilted_armor", "leather_cap", "leather_gloves", "leather_boots", "restorer_cape"]:
		player.equip_item(AethelItemInstance.new(item_catalog[starter_id]))
	player.equip_item(AethelItemInstance.new(item_catalog["hand_axe"]))
	_add_potion(AethelItemInstance.new(item_catalog["hp_small"]))
	_add_potion(AethelItemInstance.new(item_catalog["hp_small"]))
	_add_potion(AethelItemInstance.new(item_catalog["mana_small"]))
	gold = 60
	player.restore_full()

# ---------------------------------------------------------------- inimigos
func _build_enemies() -> void:
	if exploration != null: exploration.build_encounters()

func _spawn_enemy(at_position: Vector3, level: int, rank: int) -> CharacterBody3D:
	var enemy := CharacterBody3D.new()
	enemy.set_script(ENEMY_SCRIPT)
	enemy.setup(level, rank)
	add_child(enemy)
	enemy.position = at_position
	enemy.target = player
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.combat_event.connect(_on_combat_event)
	enemies.append(enemy)
	return enemy

func _on_enemy_defeated(enemy: CharacterBody3D) -> void:
	if exploration != null and not exploration.defeat(enemy): return
	enemies.erase(enemy)
	slain += 1
	if region_id == "map_02" and slain >= 5: map_02_cleared = true
	progression.gain_xp(enemy.xp_value)
	_refresh_all()

func _on_player_died() -> void:
	game_over = true
	player.clear_commands()
	left_held = false
	narrative.close()
	exploration.pending = ""
	exploration.travel_panel.hide()
	for panel in [inventory_view,character_panel,skills_panel,shop_panel,quest_panel]: panel.hide()
	audio.play_cue("death")
	death_overlay.show()
	var buttons := death_overlay.find_children("*","Button",true,false)
	if not buttons.is_empty():
		buttons[0].disabled = not FileAccess.file_exists(SAVE_PATH)
		buttons[1 if buttons[0].disabled else 0].grab_focus()
	hud.refresh_skills()

# ---------------------------------------------------------------- interface
func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	floating_layer = Control.new()
	floating_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(floating_layer)
	floating_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	status_label = Label.new()
	status_label.position = Vector2(18,16)
	status_label.size = Vector2(400,26)
	status_label.add_theme_font_size_override("font_size", 20)
	_readable_label(status_label)
	root.add_child(status_label)
	hint_label = Label.new()
	hint_label.position = Vector2(18,46)
	hint_label.size = Vector2(400,60)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.add_theme_font_size_override("font_size", 15)
	_readable_label(hint_label)
	root.add_child(hint_label)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_readable_label(message_label)
	root.add_child(message_label)
	message_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	message_label.offset_left = -280
	message_label.offset_right = 280
	message_label.offset_top = -230
	message_label.offset_bottom = -175
	var help_button := Button.new()
	help_button.text = "H · Ajuda"
	help_button.focus_mode = Control.FOCUS_NONE
	root.add_child(help_button)
	help_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	help_button.offset_left = -122
	help_button.offset_right = -18
	help_button.offset_top = 16
	help_button.offset_bottom = 48
	help_button.pressed.connect(func() -> void: help_panel.visible = not help_panel.visible)
	help_panel = PanelContainer.new()
	help_panel.name = "ControlsHelp"
	root.add_child(help_panel)
	help_panel.set_anchors_preset(Control.PRESET_CENTER)
	help_panel.offset_left = -270
	help_panel.offset_right = 270
	help_panel.offset_top = -190
	help_panel.offset_bottom = 190
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 20)
	help_panel.add_child(margin)
	var help := Label.new()
	help.text = "CONTROLES — H para fechar\n\nWASD / setas ou clique no chão: mover\nClique no inimigo: aproximar e atacar\nShift + clique: atacar parado · J: ataque básico\nF1: Golpe · F2: Guarda (novamente: cancelar) · F3: Eco\nBotão direito: repetir a última habilidade\nQ: bloquear com escudo · Espaço: esquivar\nE / F: interagir (configurável) · L: loja de Doma\nI / Tab: mochila · C: personagem · K: habilidades\n1–4: poções · Alt: rótulos de itens\nRoda do mouse: zoom · F5/F9: salvar/carregar\nEsc: pausa · R: reiniciar após derrota"
	help.add_theme_font_size_override("font_size", 16)
	margin.add_child(help)
	help_panel.hide()

func _readable_label(label: Label) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("outline_size", 2)

func _build_resource_hud() -> void:
	hud = AethelHUDManager.new()
	hud.name = "ResourcesHUD"
	add_child(hud)
	hud.setup_player_listeners(player)
	hud.skill_selected.connect(func(index: int) -> void: _activate_skill(SKILL_IDS[index]))

func _on_combat_event(world_position: Vector3, message: String, kind: String) -> void:
	audio.play_cue({"damage":"hit","hurt":"hurt","heal":"heal","mana":"heal","attack":"attack","miss":"ui"}.get(kind,"buff"))
	if message.is_empty(): return
	if active_popups.size() >= 32:
		active_popups[0].label.queue_free()
		active_popups.pop_front()
	var colors: Dictionary = {"damage": Color("ffda75"), "hurt": Color("ff7777"), "heal": Color("77ff99"), "mana": Color("77aaff"), "buff": Color("ffd24a"), "miss": Color("d4d4d4"),"elemental": Color("9ad6ff"),"critical": Color("f0d999"),"immune": Color("cccccc"),"xp": Color("c6aff0"),"gold": Color("e8cc65")}
	var label := Label.new()
	label.text = message
	label.add_theme_font_size_override("font_size",24 if kind == "critical" else 20)
	label.add_theme_color_override("font_color", colors.get(kind, Color("d4d4d4")))
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	floating_layer.add_child(label)
	active_popups.append({"label": label, "position": world_position, "age": 0.0})

func _show_message(text_value: String) -> void:
	transient_message = text_value
	message_label.text = text_value
	message_until = Time.get_ticks_msec() / 1000.0 + 2.0

func _refresh_all() -> void:
	if progression == null or player == null: return
	if progression_label != null:
		progression_label.text = "Bastião · Nível %d · Ouro %d" % [progression.current_level, gold]
	if hud != null:
		hud.update_skills(right_skill_id, skill_tree.unlocked, SKILL_IDS, player, skill_tree.catalog)
		hud.update_belt(belt, item_catalog)
	if inventory_view != null:
		inventory_view.gold_text = "Ouro: %d" % gold
		inventory_view.refresh()
	if character_panel != null: character_panel.refresh()
	_refresh_skills_panel()
	_check_mission_change()

func _mouse_over_ui(position: Vector2) -> bool:
	if death_overlay != null and death_overlay.visible: return true
	if quest_panel != null and quest_panel.visible and quest_panel.get_global_rect().has_point(position): return true
	if exploration != null and exploration.blocks_ui(position): return true
	if narrative != null and narrative.view.visible: return true
	for panel in [inventory_view, character_panel, skills_panel, shop_panel, help_panel]:
		if panel != null and panel.visible and panel.get_global_rect().has_point(position): return true
	return false

# ---------------------------------------------------------------- escolha por mouse
func _cursor_ray(screen: Vector2, mask: int, areas: bool = false) -> Dictionary:
	var camera := get_viewport().get_camera_3d()
	if camera == null or not get_viewport().get_visible_rect().has_point(screen): return {}
	var origin := camera.project_ray_origin(screen)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(screen) * 200, mask)
	query.collide_with_areas = areas
	return get_world_3d().direct_space_state.intersect_ray(query)

func ground_point_at(screen: Vector2) -> Variant:
	var hit := _cursor_ray(screen, 1)
	if hit.is_empty(): return null
	var collider := hit["collider"] as Node
	if collider == null or not collider.get_meta("walkable_ground", false): return null
	var point: Vector3 = hit["position"]
	return Vector3(point.x, 0, point.z)

func pick_enemy_at(screen: Vector2) -> CharacterBody3D:
	var hit := _cursor_ray(screen, 1 | 4 | 16, true)
	if hit.is_empty(): return null
	var collider := hit["collider"] as Node
	while collider != null:
		if collider is CharacterBody3D and collider.is_in_group("hybrid_enemies"):
			return collider if collider.hp > 0 and not collider.is_queued_for_deletion() else null
		collider = collider.get_parent()
	return null

func pick_drop_at(screen: Vector2) -> AethelDroppedItem:
	var camera := get_viewport().get_camera_3d()
	if camera == null: return null
	var best: AethelDroppedItem = null
	var best_distance: float = INF
	for drop in dropped_items:
		if not is_instance_valid(drop) or drop.is_queued_for_deletion() or not drop.visible or (exploration != null and not exploration.visible_drop(drop)): continue
		if exploration != null and exploration.labels.has(drop.get_instance_id()) and exploration.labels[drop.get_instance_id()].label.visible and drop.get_meta("label_rect",Rect2()).has_point(screen): return drop
		var distance: float = camera.unproject_position(drop.global_position + Vector3(0, 0.5, 0)).distance_to(screen)
		if distance < 34.0 and distance < best_distance:
			best = drop
			best_distance = distance
	return best

func _unhandled_input(event: InputEvent) -> void:
	if game_over or not event is InputEventMouseButton: return
	if event.is_action("primary"):
		if event.pressed: _on_left_press(event.position)
		else: _on_left_release()
	elif event.is_action_pressed("secondary"):
		_cast_right_skill(event.position)

func _on_left_press(screen: Vector2) -> void:
	if _mouse_over_ui(screen): return
	if narrative != null: narrative.close()
	if exploration != null: exploration.pending = ""
	left_held = true
	pickup_target = null
	var enemy := pick_enemy_at(screen)
	if Input.is_action_pressed("stand_attack"):
		hold_mode = "stand"
		var aim: Variant = enemy.global_position if enemy != null else ground_point_at(screen)
		if aim != null: player.command_stand_attack(aim)
		return
	if enemy != null:
		hold_mode = "attack"
		player.command_attack(enemy)
		return
	var npc_id: String = narrative.pick(screen) if narrative != null else ""
	if not npc_id.is_empty():
		narrative.request(npc_id)
		return
	var drop := pick_drop_at(screen)
	if drop != null:
		hold_mode = "pickup"
		pickup_target = drop
		player.command_move(drop.global_position)
		return
	var object_id: String = exploration.pick(screen) if exploration != null else ""
	if not object_id.is_empty():
		exploration.request(object_id)
		return
	var point: Variant = ground_point_at(screen)
	if point != null:
		hold_mode = "move"
		player.command_move(point)

func _on_left_release() -> void:
	left_held = false
	if hold_mode == "stand": player.stop_stand_attack()
	hold_mode = ""

func _apply_hold() -> void:
	if player.keyboard_active or (hold_mode != "move" and hold_mode != "stand"): return
	var screen := get_viewport().get_mouse_position()
	var enemy := pick_enemy_at(screen) if hold_mode == "stand" else null
	var aim: Variant = enemy.global_position if enemy != null else ground_point_at(screen)
	if aim == null: return
	if hold_mode == "stand": player.command_stand_attack(aim)
	elif player.global_position.distance_to(aim) > 0.45: player.command_move(aim)

func _activate_skill(skill_id: String, screen: Variant = null) -> void:
	if not skill_tree.unlocked.has(skill_id):
		_show_message("Habilidade indisponível")
		return
	var focus: Node3D = player.attack_target if is_instance_valid(player.attack_target) else null
	if screen is Vector2 and not _mouse_over_ui(screen):
		var under_cursor := pick_enemy_at(screen)
		if under_cursor != null: focus = under_cursor
	var aim: Variant = focus.global_position if focus != null else (ground_point_at(screen) if screen is Vector2 and not _mouse_over_ui(screen) else null)
	if aim != null:
		var direction: Vector3 = aim - player.global_position
		direction.y = 0
		if direction.length() > 0.01: player.facing = direction.normalized()
	var problem: String = player.use_skill(skill_tree.catalog[skill_id])
	if not problem.is_empty():
		_show_message(problem)
	else:
		left_held = false
		hold_mode = ""
		right_skill_id = skill_id
		_show_message("Guarda encerrada" if skill_id == "iron_guard" and player.guard_remaining <= 0 else skill_tree.catalog[skill_id].display_name)
		_refresh_skills_panel()

func _cast_right_skill(screen: Vector2) -> void:
	if narrative != null:
		if narrative.view.visible: return
		narrative.close()
	if right_skill_id.is_empty():
		_show_message("Use F1–F3 para executar uma habilidade")
		return
	_activate_skill(right_skill_id, screen)

func _grant_training_skills() -> void:
	# Existing three techniques are available in this test slice; no new skill rules.
	for id: String in SKILL_IDS: skill_tree.unlocked[id] = true
	if right_skill_id.is_empty(): right_skill_id = "heavy_strike"

# ---------------------------------------------------------------- loop
func _process(delta: float) -> void:
	if narrative != null: narrative.tick(delta)
	if exploration != null: exploration.tick(delta)
	var camera := get_viewport().get_camera_3d()
	for index in range(active_popups.size() - 1, -1, -1):
		var popup: Dictionary = active_popups[index]
		popup["age"] += delta
		var label: Label = popup["label"]
		if popup["age"] >= 0.85:
			label.queue_free()
			active_popups.remove_at(index)
			continue
		if is_instance_valid(camera):
			label.position = camera.unproject_position(popup["position"] + Vector3(0, popup["age"] * 1.5, 0)) - Vector2(28, 0)
		label.modulate.a = 1.0 - popup["age"] / 0.85
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var over_ui: bool = _mouse_over_ui(mouse)
	hovered_enemy = null if over_ui else pick_enemy_at(mouse)
	hovered_drop = null if over_ui else pick_drop_at(mouse)
	var alt_held: bool = Input.is_action_pressed("show_items")
	for drop in dropped_items:
		if is_instance_valid(drop): drop.set_label_visible(alt_held or drop.default_label_visible() or drop == hovered_drop)
	if exploration != null: exploration.present_drops(alt_held)
	var focus: CharacterBody3D = player.attack_target as CharacterBody3D if is_instance_valid(player.attack_target) else hovered_enemy
	var selected: CharacterBody3D = focus if is_instance_valid(focus) and not game_over else null
	if selected != presented_target:
		presented_target = selected
		target_changed.emit(selected)
	if left_held and not Input.is_action_pressed("primary"): _on_left_release()
	if left_held and not game_over: _apply_hold()
	if is_instance_valid(pickup_target):
		if player.keyboard_active or is_instance_valid(player.attack_target): pickup_target = null
		elif player.global_position.distance_to(pickup_target.global_position) < 1.7: _collect_drop(pickup_target)
		elif not player.has_move_target:
			pickup_target = null
			_show_message("Caminho bloqueado até o loot")
	else:
		pickup_target = null
	if shop_panel.visible and (not narrative.available("doma") or not narrative.hub.get("doma",false) or player.global_position.distance_to(merchant.global_position) > 3.0):
		shop_panel.visible = false
	status_label.text = "VIGÍLIA / PRAÇA DOS SINOS" if region_id == "map_01" else "BAIRRO QUE FALTAVA  |  Rasuras %d / 5" % slain
	if region_id == "map_01":
		hint_label.text = "E: conversar com Maera" if player.global_position.distance_to(npc.global_position) < 2.8 else "Procure Maera (marcador azul)."
		if quest_started: hint_label.text = "Investigação provisória: atravesse o portal, derrote 5 Rasuras e retorne a Maera."
		if quest_completed: hint_label.text = "Investigação provisória registrada. Missão canônica ainda pendente."
		if player.global_position.distance_to(gate.global_position) < 2.8: hint_label.text = "E: entrar no Bairro que Faltava" if quest_started else "Converse com Maera antes de sair."
		if player.global_position.distance_to(merchant.global_position) < 3.0: hint_label.text = "E: falar com Doma (L: loja)"
	else:
		hint_label.text = "Derrote 5 Rasuras. Clique nos itens para pegar. E: retornar pelo portal."
		if slain >= 5: hint_label.text = "Bairro estabilizado! E perto do portal para voltar a Vigília."
	if AethelSettings.interact_key == KEY_F: hint_label.text = hint_label.text.replace("E:", "F:")
	if game_over:
		status_label.text += "  |  DERROTA — R para reiniciar"
	elif slain >= 5 and region_id == "map_02":
		status_label.text += "  |  ÁREA LIBERADA"
	message_label.visible = message_until > Time.get_ticks_msec() / 1000.0

# ---------------------------------------------------------------- teclas
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if game_over and event.is_action_pressed("pause"): return
	if narrative != null and narrative.view.visible:
		if event.is_action_pressed("pause") or event.is_action_pressed("interact"):
			narrative.close()
			get_viewport().set_input_as_handled()
		return
	if exploration != null:
		if event.keycode == KEY_O:
			exploration.filter_panel.visible = not exploration.filter_panel.visible
			return
		if event.is_action_pressed("pause"):
			exploration.pending = ""
			if exploration.travel_panel.visible:
				exploration.travel_panel.hide()
				return
	if event.is_action_pressed("pause") and narrative != null: narrative.close()
	if event.is_action_pressed("pause"):
		for panel in [inventory_view, character_panel, skills_panel, shop_panel,quest_panel]: panel.visible = false
		player.clear_commands()
		left_held = false
		pause_menu.open()
		get_viewport().set_input_as_handled()
		return
	if game_over:
		if event.is_action_pressed("restart"):
			Engine.set_meta("aethel_new_game", true)
			get_tree().reload_current_scene()
		return
	if event.is_action_pressed("quests"):
		quest_panel.visible = not quest_panel.visible
		_refresh_quest_panel()
	elif event.is_action_pressed("inventory"):
		audio.play_cue("inventory",true)
		inventory_view.visible = not inventory_view.visible
		if inventory_view.visible: inventory_view.refresh()
	elif event.is_action_pressed("character"): _toggle_left_panel(character_panel)
	elif event.is_action_pressed("skills"): _toggle_left_panel(skills_panel)
	elif event.is_action_pressed("shop"): _try_open_shop()
	elif event.is_action_pressed("help"): help_panel.visible = not help_panel.visible
	elif event.is_action_pressed("attack_key"): player._try_attack()
	elif event.is_action_pressed("save"): _save_state()
	elif event.is_action_pressed("load"):
		if _load_state(): _refresh_all()
	elif event.is_action_pressed("interact"): _interact()
	else:
		for index in 4:
			if event.is_action_pressed("potion_%d" % (index + 1)): _drink_belt(index)
		for index in 3:
			if event.is_action_pressed("skill_%d" % (index + 1)): _activate_skill(SKILL_IDS[index], get_viewport().get_mouse_position())

func _interact() -> void:
	if narrative != null:
		var pointed: String = narrative.pick(get_viewport().get_mouse_position())
		if not pointed.is_empty():
			narrative.request(pointed)
			return
	if exploration != null:
		var nearest := ""
		var distance := 2.5
		for id: String in exploration.objects:
			var actor: Node3D = exploration.objects[id]
			if actor.visible and player.global_position.distance_to(actor.global_position) < distance:
				nearest = id
				distance = player.global_position.distance_to(actor.global_position)
		if not nearest.is_empty(): exploration.request(nearest); return
		var object_id: String = exploration.pick(get_viewport().get_mouse_position())
		if not object_id.is_empty(): exploration.request(object_id); return
	if _collect_nearest_drop(): return
	if region_id == "map_01":
		if is_instance_valid(merchant) and player.global_position.distance_to(merchant.global_position) < 3:
			narrative.request("doma")
		elif player.global_position.distance_to(gate.global_position) < 2.8 and quest_started:
			region_id = "map_02"
			_update_region()
		elif player.global_position.distance_to(npc.global_position) < 2.8:
			narrative.request("maera")
	else:
		if player.global_position.distance_to(gate.global_position) < 2.8:
			region_id = "map_01"
			_update_region()

func _toggle_left_panel(panel: Control) -> void:
	var opening: bool = not panel.visible
	for other in [character_panel, skills_panel, shop_panel]: other.visible = false
	panel.visible = opening
	if opening: _refresh_all()

# ---------------------------------------------------------------- regiões
func _update_region() -> void:
	if exploration != null: exploration.update_region()
	if narrative != null: narrative.close()
	if workshop != null:
		workshop.visible = region_id == "map_01"
		for body: StaticBody3D in workshop.find_children("*","StaticBody3D",true,false):
			body.collision_layer = 1 if workshop.visible else 0
	if is_instance_valid(merchant):
		merchant.visible = region_id == "map_01"
		merchant.collision_layer = 8 if merchant.visible else 0
	for drop in dropped_items:
		if is_instance_valid(drop): drop.visible = str(drop.get_meta("region", region_id)) == region_id
	for enemy in enemies:
		if is_instance_valid(enemy): enemy.queue_free()
	enemies.clear()
	pickup_target = null
	if region_id == "map_01":
		player.position = Vector3(0, 0, 4)
		npc.visible = true
		gate.position = Vector3(11, 0, 0)
	else:
		player.position = Vector3(0, 0, 9)
		npc.visible = false
		gate.position = Vector3(0, 0, 12)
		slain = exploration.killed.size() if exploration != null else 0
		_build_enemies()
	player.clear_commands()


# ---------------------------------------------------------------- inventário, itens e poções
func _setup_inventory() -> void:
	inventory = AethelInventoryManager.new()
	inventory.name = "Inventory"
	add_child(inventory)
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	canvas.name = "InventoryLayer"
	add_child(canvas)
	inventory_view = AethelInventoryView.new()
	inventory_view.name = "InventoryView"
	canvas.add_child(inventory_view)
	inventory_view.bind_player(player)
	inventory_view.bind_inventory(inventory)
	inventory_view.equip_requested.connect(_on_equip_requested)
	inventory_view.unequip_requested.connect(_on_unequip_requested)
	inventory_view.sell_requested.connect(_on_sell_requested)
	inventory_view.discard_requested.connect(_on_discard_requested)
	inventory_view.inventory_drop_requested.connect(_on_inventory_drop)
	inventory_view.equipment_drop_requested.connect(_on_equipment_drop)

func _spawn_drop(entry: Dictionary, at_position: Vector3) -> AethelDroppedItem:
	var drop := AethelDroppedItem.new()
	if entry["kind"] == "gold": drop.gold_amount = int(entry["amount"])
	else: drop.item = entry["item"]
	var angle: float = rng.randf() * TAU
	drop.position = at_position + Vector3(cos(angle), 0.0, sin(angle)) * rng.randf_range(0.35, 1.1)
	drop.position.y = 0.0
	drop.set_meta("region", region_id)
	add_child(drop)
	dropped_items.append(drop)
	if exploration != null:
		exploration.feedback(drop.global_position,"Recompensa rara" if drop.item != null and drop.item.get_quality() >= 2 else "", "rare" if drop.item != null and drop.item.get_quality() >= 2 else "drop")
	return drop

func _collect_drop(drop: AethelDroppedItem) -> bool:
	if not is_instance_valid(drop) or drop.is_queued_for_deletion() or not dropped_items.has(drop) or str(drop.get_meta("region", region_id)) != region_id: return false
	if player.global_position.distance_to(drop.global_position) > 2.6 or (exploration != null and not exploration.reachable(drop)): return false
	if drop.is_gold():
		gold += drop.gold_amount
		_show_message("+%d ouro" % drop.gold_amount)
	elif drop.item.definition.is_potion():
		if not _add_potion(drop.item):
			_show_message("Cinto e mochila cheios")
			return false
	else:
		if not inventory.add_item(drop.item):
			_show_message("Mochila cheia")
			return false
		_show_message("Coletado: " + drop.item.display_name())
	if exploration != null: exploration.feedback(drop.global_position,"Coletado","pickup")
	dropped_items.erase(drop)
	drop.queue_free()
	if pickup_target == drop: pickup_target = null
	_refresh_all()
	return true

func _collect_nearest_drop() -> bool:
	var best: AethelDroppedItem = null
	var best_distance: float = 2.6
	for drop in dropped_items:
		if not is_instance_valid(drop) or drop.is_queued_for_deletion() or str(drop.get_meta("region", region_id)) != region_id or (exploration != null and not exploration.visible_drop(drop)): continue
		var distance: float = player.global_position.distance_to(drop.global_position)
		if distance < best_distance:
			best = drop
			best_distance = distance
	return best != null and _collect_drop(best)

func _add_potion(item: AethelItemInstance, allow_inventory: bool = true) -> bool:
	var plan := belt.duplicate(true)
	var remaining := item.quantity
	var kind := String(item.definition.item_id)
	for index in range(BELT_SLOTS):
		var row: Dictionary = plan[index]
		if row.is_empty(): row = {"kind":kind,"count":0}
		if row.get("kind") != kind: continue
		var amount := mini(remaining,BELT_STACK-int(row["count"]))
		row["count"] += amount
		if amount > 0: plan[index] = row
		remaining -= amount
	if remaining > 0:
		if not allow_inventory: return false
		var original := item.quantity
		item.quantity = remaining
		if not inventory.add_item(item):
			item.quantity = original
			return false
	belt = plan
	if hud != null: hud.update_belt(belt,item_catalog)
	return true

func _drink_belt(index: int) -> void:
	if index < 0 or index >= BELT_SLOTS or player.hp <= 0: return
	var slot: Dictionary = belt[index]
	if slot.is_empty():
		_show_message("Cinto vazio")
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - last_drink_time < 0.4: return
	var data: AethelItemData = item_catalog[str(slot["kind"])]
	if data.heal_life > 0 and data.heal_mana == 0 and player.hp >= player.max_hp:
		_show_message("Vida já está cheia")
		return
	if data.heal_mana > 0 and data.heal_life == 0 and player.ether >= player.max_ether:
		_show_message("Éter já está cheio")
		return
	last_drink_time = now
	player.drink_potion(data.heal_life, data.heal_mana)
	slot["count"] = int(slot["count"]) - 1
	if int(slot["count"]) <= 0: belt[index] = {}
	hud.update_belt(belt, item_catalog)

func _inventory_failure(message: String) -> void:
	_show_message(message)
	inventory_view.flash_invalid()

func _on_equip_requested(uid: String, requested_slot: String = "") -> void:
	var item := inventory.find_item(uid)
	if item == null:
		_inventory_failure("Item indisponível")
		return
	if item.definition.is_potion():
		if not requested_slot.is_empty():
			_inventory_failure("Poções vão para o cinto, não para equipamentos")
			return
		var unit := AethelItemInstance.new(item.definition)
		if _add_potion(unit,false): inventory.take_one(uid)
		else: _inventory_failure("Cinto cheio")
		_refresh_all()
		return
	var slot: String = requested_slot if not requested_slot.is_empty() else player.slot_for(item)
	var problem: String = player.equipment_problem(item,slot)
	if not problem.is_empty():
		_inventory_failure(problem)
		return
	var replaced: AethelItemInstance = player.equipped.get(slot)
	if not inventory.exchange(uid,replaced):
		_inventory_failure("Sem espaço na mochila para trocar")
		return
	player.equip_item(item,slot)
	_refresh_all()

func _on_unequip_requested(slot: String, destination: Vector2i = Vector2i(-1,-1)) -> void:
	var item: AethelItemInstance = player.equipped.get(slot)
	if item == null: return
	var placed: bool = inventory.add_item(item) if destination.x < 0 else inventory.place_item(item,destination)
	if not placed:
		_inventory_failure("Destino ocupado ou mochila cheia")
		return
	player.unequip_slot(slot)
	_refresh_all()

func _on_inventory_drop(payload: Dictionary, destination: Vector2i) -> void:
	if not inventory_view.accepts_payload(payload): return
	if payload.get("source") == "equipment":
		var slot: String = str(payload.get("slot",""))
		var item: AethelItemInstance = player.equipped.get(slot)
		if item == null or item.instance_id != str(payload.get("uid","")): return
		_on_unequip_requested(slot,destination)
	elif not inventory.move_item(str(payload.get("uid","")),destination):
		_inventory_failure("Não é possível mover ou trocar para essa posição")

func _on_equipment_drop(payload: Dictionary, slot: String) -> void:
	if not inventory_view.accepts_payload(payload): return
	if payload.get("source") != "bag":
		_inventory_failure("Mova para a mochila antes de trocar de slot")
		return
	_on_equip_requested(str(payload.get("uid","")),slot)

func _on_sell_requested(uid: String) -> void:
	if not _trade_available():
		_show_message("Abra a loja (L) perto de Doma para vender")
		return
	var item: AethelItemInstance = inventory.find_item(uid)
	if item == null: return
	if item.definition.kind == "quest" or item.definition.sale_locked:
		_inventory_failure("Este item não pode ser vendido")
		return
	var price: int = maxi(1, item.gold_value() / 4) * item.quantity
	if not inventory.remove_item(uid): return
	gold += price
	audio.play_cue("trade")
	_show_message("Vendido: %s por %d ouro" % [item.display_name(), price])
	_refresh_shop()
	_refresh_all()

# ---------------------------------------------------------------- progressão, habilidades e loja
func _setup_rpg_systems() -> void:
	progression = AethelProgressionManager.new()
	progression.name = "ProgressionManager"
	player.add_child(progression)
	progression.leveled_up.connect(_on_level_up)
	progression.experience_gained.connect(func(amount: int) -> void: _on_combat_event(player.global_position+Vector3(0,2,0),"+%d XP" % amount,"xp"))
	skill_tree = AethelSkillTree.new()
	skill_tree.name = "SkillTree"
	player.add_child(skill_tree)
	skill_tree.configure(progression)
	var ui := CanvasLayer.new()
	ui.name = "RPGMenuLayer"
	ui.layer = 6
	add_child(ui)
	progression_label = Label.new()
	progression_label.add_theme_font_size_override("font_size", 14)
	_readable_label(progression_label)
	ui.add_child(progression_label)
	progression_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	progression_label.offset_left = -300
	progression_label.offset_right = -18
	progression_label.offset_top = -88
	progression_label.offset_bottom = -62
	progression_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	character_panel = AethelCharacterPanel.new()
	character_panel.position = Vector2(20, 150)
	ui.add_child(character_panel)
	character_panel.bind(player, progression)
	character_panel.changed.connect(_refresh_all)
	_build_skills_panel(ui)
	_build_shop_panel(ui)

func _on_level_up(level: int) -> void:
	player.character_level = level
	player.stats.unspent += AethelCharacterStats.POINTS_PER_LEVEL
	player.recalculate_stats()
	player.restore_full()
	_roll_shop_stock()
	audio.play_cue("level")
	_show_message("Nível %d! +%d atributos, +1 habilidade" % [level, AethelCharacterStats.POINTS_PER_LEVEL])
	_refresh_all()

func _build_skills_panel(ui: CanvasLayer) -> void:
	skills_panel = PanelContainer.new()
	skills_panel.position = Vector2(20, 150)
	skills_panel.custom_minimum_size = Vector2(330, 0)
	ui.add_child(skills_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	skills_panel.add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	skills_info = Label.new()
	skills_info.add_theme_font_size_override("font_size", 14)
	column.add_child(skills_info)
	for skill_id in SKILL_IDS:
		var id: String = skill_id
		var skill: AethelSkillData = skill_tree.catalog[id]
		var title := Label.new()
		title.text = "%s  (nv. %d, %d éter)" % [skill.display_name, skill.required_level, skill.ether_cost]
		title.add_theme_font_size_override("font_size", 14)
		column.add_child(title)
		var description := Label.new()
		description.text = skill.description
		description.add_theme_font_size_override("font_size", 12)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.custom_minimum_size = Vector2(300, 0)
		column.add_child(description)
		var buttons := HBoxContainer.new()
		var unlock := Button.new()
		unlock.text = "Desbloquear"
		unlock.pressed.connect(func() -> void:
			if skill_tree.unlock(id):
				_show_message("Habilidade liberada: " + skill.display_name)
				if right_skill_id.is_empty(): _select_right_skill(id)
			else: _show_message("Nível, pontos ou requisito insuficiente")
			_refresh_all()
		)
		buttons.add_child(unlock)
		var equip := Button.new()
		equip.text = "Botão direito"
		equip.pressed.connect(func() -> void: _select_right_skill(id))
		buttons.add_child(equip)
		column.add_child(buttons)
		skills_rows[id] = {"unlock": unlock, "equip": equip}
	skills_panel.visible = false

func _select_right_skill(skill_id: String) -> void:
	if not skill_tree.unlocked.has(skill_id):
		_show_message("Habilidade ainda não liberada")
		return
	right_skill_id = skill_id
	_refresh_skills_panel()

func _refresh_skills_panel() -> void:
	if skill_tree == null or skills_info == null: return
	skills_info.text = "HABILIDADES  |  Pontos disponíveis: %d" % progression.skill_points
	for id: String in skills_rows:
		var unlocked: bool = skill_tree.unlocked.has(id)
		skills_rows[id]["unlock"].disabled = unlocked
		skills_rows[id]["unlock"].text = "Liberada" if unlocked else "Desbloquear"
		skills_rows[id]["equip"].disabled = not unlocked
		skills_rows[id]["equip"].text = "Botão direito ✓" if id == right_skill_id else "Botão direito"
	if hud != null:
		hud.set_right_skill("Botão direito: %s" % skill_tree.catalog[right_skill_id].display_name if not right_skill_id.is_empty() else "Botão direito: —")

func _build_shop_panel(ui: CanvasLayer) -> void:
	shop_panel = PanelContainer.new()
	shop_panel.position = Vector2(20, 150)
	shop_panel.custom_minimum_size = Vector2(330, 0)
	ui.add_child(shop_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	shop_panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.name = "StockScroll"
	scroll.custom_minimum_size = Vector2(330,300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	margin.add_child(scroll)
	shop_column = VBoxContainer.new()
	shop_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(shop_column)
	shop_tooltip = AethelItemTooltip.new()
	shop_tooltip.requirement_source = player
	ui.add_child(shop_tooltip)
	shop_panel.visible = false

func _roll_shop_stock() -> void:
	if stock_initialized: return
	stock_initialized = true
	shop_stock.clear()
	for id: String in narrative.merchants.doma.stock:
		shop_stock.append(AethelItemInstance.new(item_catalog[id]))
	_refresh_shop()

func _trade_available() -> bool:
	return not game_over and shop_panel.visible and narrative.reachable("doma") and narrative.available("doma") and bool(narrative.hub.get("doma",false)) and player.global_position.distance_to(merchant.global_position) <= 3.0

func _buy_price(item: AethelItemInstance) -> int:
	return item.gold_value() * (1 if item.definition.is_potion() else int(narrative.merchants.doma.price_multiplier)) * item.quantity

func _refresh_shop() -> void:
	if shop_column == null: return
	for node in shop_column.get_children():
		shop_column.remove_child(node)
		node.queue_free()
	var title := Label.new()
	title.text = "Doma Ferren — Ferreiro\nOuro: %d" % gold
	shop_column.add_child(title)
	for potion_id: String in narrative.merchants.doma.unlimited_potions:
		if potion_id == "hp_medium" and progression != null and progression.current_level < 4: continue
		var potion := AethelItemInstance.new(item_catalog[potion_id])
		_add_shop_button(potion, true)
	for item: AethelItemInstance in shop_stock:
		_add_shop_button(item, false)
	var hint := Label.new()
	hint.text = "Venda itens com o botão direito na mochila (I)."
	hint.add_theme_font_size_override("font_size", 12)
	shop_column.add_child(hint)

func _add_shop_button(item: AethelItemInstance, is_stock_potion: bool) -> void:
	var button := Button.new()
	button.text = "%s — %d ouro" % [item.display_name(), _buy_price(item)]
	button.icon = item.definition.icon
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width",24)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_color_override("font_color", AethelDroppedItem.COLORS[clampi(item.get_quality(), 0, 4)])
	button.pressed.connect(func() -> void: _purchase(item, is_stock_potion))
	button.mouse_entered.connect(func() -> void: _shop_inspect(item,button))
	button.focus_entered.connect(func() -> void: _shop_inspect(item,button))
	button.focus_exited.connect(func() -> void: shop_tooltip.hide_item())
	button.mouse_exited.connect(func() -> void: shop_tooltip.hide_item())
	shop_column.add_child(button)

func _try_open_shop() -> void:
	if game_over or not narrative.available("doma") or not narrative.reachable("doma") or not bool(narrative.hub.get("doma",false)) or player.global_position.distance_to(merchant.global_position) > 3.0:
		_show_message("Aproxime-se do ferreiro Doma em Vigília")
		return
	narrative.close()
	_toggle_left_panel(shop_panel)
	player.interaction_input_locked = shop_panel.visible
	if shop_panel.visible:
		player.clear_commands()
		player.keyboard_active = false
	_refresh_shop()

func _purchase(item: AethelItemInstance, is_stock_potion: bool) -> void:
	if not _trade_available() or item == null: return
	if is_stock_potion:
		if not String(item.definition.item_id) in narrative.merchants.doma.unlimited_potions: return
		if item.definition.item_id == &"hp_medium" and progression.current_level < 4: return
		if item.definition != item_catalog.get(String(item.definition.item_id)) or item.quantity != 1: return
	elif not shop_stock.has(item):
		_show_message("Mercadoria indisponível")
		return
	var price: int = _buy_price(item)
	if gold < price:
		_show_message("Ouro insuficiente")
		return
	var bought: AethelItemInstance = item
	if is_stock_potion: bought = AethelItemInstance.new(item.definition)
	var stored: bool = _add_potion(bought) if bought.definition.is_potion() else inventory.add_item(bought)
	if not stored:
		_show_message("Mochila cheia")
		return
	gold -= price
	if not is_stock_potion: shop_stock.erase(item)
	audio.play_cue("trade")
	_show_message("Compra realizada: " + bought.display_name())
	_refresh_shop()
	_refresh_all()

# ---------------------------------------------------------------- save / load (versão 3)
func _save_state() -> void:
	var equipment: Dictionary = {}
	for slot in player.equipped:
		var item: AethelItemInstance = player.equipped[slot]
		equipment[slot] = item.serialize()
	var payload: Dictionary = {"version": SAVE_VERSION, "character_id": player.character_id, "class_id": String(player.class_id), "position": [player.position.x, player.position.y, player.position.z], "stamina": player.stamina, "progression": progression.serialize(), "skills": skill_tree.serialize(),
		"stats": player.stats.serialize(), "gold": gold, "region_id": region_id, "quest_started": quest_started,
		"quest_completed": quest_completed, "map_02_cleared": map_02_cleared, "slain": slain, "hp": player.hp,
		"ether": player.ether, "inventory": inventory.serialize(), "equipped": equipment, "belt": belt, "right_skill": right_skill_id, "exploration": exploration.serialize(), "narrative": narrative.serialize(), "shop_stock": shop_stock.map(func(item: AethelItemInstance) -> Dictionary: return item.serialize())}
	var file := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		_show_message("Falha ao abrir arquivo de save")
		return
	file.store_string(JSON.stringify(payload))
	file.flush()
	file.close()
	var absolute_tmp: String = ProjectSettings.globalize_path(SAVE_PATH + ".tmp")
	var absolute_target: String = ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(SAVE_PATH): DirAccess.copy_absolute(absolute_target, absolute_target + ".bak")
	var move_err: Error = DirAccess.rename_absolute(absolute_tmp, absolute_target)
	_show_message("Jogo salvo" if move_err == OK else "Falha ao confirmar save")

func _read_save_payload(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary: return {}
	var data: Dictionary = parsed
	if not _valid_save(data): return {}
	return data

func _valid_save(data: Dictionary) -> bool:
	if not data.get("version") is float and not data.get("version") is int: return false
	if int(data["version"]) < 1 or int(data["version"]) > SAVE_VERSION: return false
	for key: String in ["progression", "stats", "inventory", "equipped"]:
		if data.has(key) and not data[key] is Dictionary: return false
	for key: String in ["skills", "belt", "position"]:
		if data.has(key) and not data[key] is Array: return false
	for key: String in ["gold", "hp", "ether", "stamina", "slain"]:
		if data.has(key) and not (data[key] is int or data[key] is float): return false
	if data.has("class_id") and str(data["class_id"]) != "bastion": return false
	for key: String in ["progression", "stats"]:
		for value: Variant in data.get(key, {}).values():
			if not (value is int or value is float): return false
	var entries: Variant = data.get("inventory", {}).get("items", [])
	if not entries is Array: return false
	for entry: Variant in entries:
		if not entry is Dictionary: return false
		if AethelItemInstance.from_dict(entry, item_catalog) == null: return false
	for entry: Variant in data.get("equipped", {}).values():
		if entry is Dictionary:
			if AethelItemInstance.from_dict(entry, item_catalog) == null: return false
		elif not entry is String: return false
	for entry: Variant in data.get("belt", []):
		if not entry is Dictionary: return false
		if entry.has("count") and not (entry["count"] is float or entry["count"] is int): return false
	if int(data.version) >= 5 and (not data.has("narrative") or not data.has("shop_stock")): return false
	if data.has("narrative") and not narrative.valid_state(data.narrative): return false
	if int(data.version) >= 5 and bool(data.get("quest_completed",false)) != bool(data.narrative.get("reward_claimed",false)): return false
	if data.has("shop_stock"):
		if not data.shop_stock is Array or data.shop_stock.size() > narrative.merchants.doma.stock.size(): return false
		var seen: Dictionary = {}
		for row: Variant in data.shop_stock:
			if not row is Dictionary: return false
			var item := AethelItemInstance.from_dict(row,item_catalog)
			if item == null or seen.has(item.instance_id): return false
			if not String(item.definition.item_id) in narrative.merchants.doma.stock or item.quantity != 1: return false
			for owned: Dictionary in data.get("inventory",{}).get("items",[]):
				if str(owned.get("id","")) == item.instance_id: return false
			for owned: Variant in data.get("equipped",{}).values():
				if owned is Dictionary and str(owned.get("id","")) == item.instance_id: return false
			seen[item.instance_id] = true
	if int(data.version) >= 6 and not data.has("exploration"): return false
	if data.has("exploration"):
		if not exploration.valid_state(data.exploration): return false
		var owned_ids: Dictionary = {}
		for row: Dictionary in data.get("inventory",{}).get("items",[]): owned_ids[str(row.get("id",""))] = true
		for row: Variant in data.get("equipped",{}).values():
			if row is Dictionary: owned_ids[str(row.get("id",""))] = true
		for row: Dictionary in data.get("shop_stock",[]): owned_ids[str(row.get("id",""))] = true
		for row: Dictionary in data.exploration.get("drops",[]):
			if int(row.gold) == 0 and owned_ids.has(str(row.item.get("id",""))): return false
	return true

func _load_state() -> bool:
	var payload := _read_save_payload(SAVE_PATH)
	if payload.is_empty(): payload = _read_save_payload(SAVE_PATH + ".bak")
	if payload.is_empty(): return false
	progression.restore(payload.get("progression", {}))
	skill_tree.restore(payload.get("skills", []))
	_grant_training_skills()
	player.character_level = progression.current_level
	if payload.has("stats"):
		player.stats.restore(payload["stats"])
	else:
		player.stats = AethelCharacterStats.new() # save antigo: devolve os pontos dos níveis já ganhos
		player.stats.unspent = (progression.current_level - 1) * AethelCharacterStats.POINTS_PER_LEVEL
	gold = maxi(0, int(payload.get("gold", 0)))
	quest_started = bool(payload.get("quest_started", false))
	quest_completed = bool(payload.get("quest_completed", false))
	narrative.restore(payload.get("narrative",{}),quest_completed)
	shop_stock.clear()
	stock_initialized = payload.has("shop_stock")
	for row: Dictionary in payload.get("shop_stock",[]): shop_stock.append(AethelItemInstance.from_dict(row,item_catalog))
	_roll_shop_stock()
	_refresh_shop()
	map_02_cleared = bool(payload.get("map_02_cleared", false))
	exploration.restore(payload.get("exploration",{}),map_02_cleared)
	var saved_region: String = str(payload.get("region_id", "map_01"))
	region_id = saved_region if saved_region in ["map_01", "map_02"] else "map_01"
	_update_region()
	inventory.restore(payload.get("inventory", {}), item_catalog)
	player.equipped.clear()
	var slots: Dictionary = payload.get("equipped", {})
	for slot in slots:
		var entry: Variant = slots[slot]
		var item: AethelItemInstance = null
		if entry is Dictionary:
			item = AethelItemInstance.from_dict(entry, item_catalog)
		else: # versão 2: referência a um item que ficava duplicado na mochila
			item = inventory.find_item(str(entry))
		if item != null and str(slot) in player.SLOT_ORDER:
			var expected: String = "ring" if str(slot) in ["ring1", "ring2"] else str(slot)
			if item.definition.slot != expected: continue
			if item.quantity != 1: continue
			var repeated := false
			for other: AethelItemInstance in player.equipped.values():
				if other.instance_id == item.instance_id: repeated = true
			if repeated: continue
			inventory.remove_item(item.instance_id)
			player.equipped[str(slot)] = item
	# All equipped bonuses must be available before validating requirements.
	# A weapon may legitimately depend on an amulet appearing later in the save.
	var changed := true
	while changed:
		changed = false
		for slot in player.equipped.keys():
			var equipped_item: AethelItemInstance = player.equipped[slot]
			var problem: String = player.requirement_problem(equipped_item)
			if str(slot) == "shield" and player.equipped.has("weapon") and player.equipped["weapon"].definition.hands == 2: problem = "Incompatible offhand"
			if not problem.is_empty():
				player.equipped.erase(slot)
				inventory.add_item(equipped_item)
				changed = true
	belt = [{}, {}, {}, {}]
	var saved_belt: Array = payload.get("belt", [])
	for index in range(mini(BELT_SLOTS, saved_belt.size())):
		var row: Variant = saved_belt[index]
		if row is Dictionary and item_catalog.has(str(row.get("kind", ""))) and item_catalog[str(row["kind"])].is_potion() and int(row.get("count", 0)) > 0:
			belt[index] = {"kind": str(row["kind"]), "count": clampi(int(row["count"]), 1, BELT_STACK)}
	var saved_skill: String = str(payload.get("right_skill", ""))
	right_skill_id = saved_skill if skill_tree.unlocked.has(saved_skill) else ""
	player.recalculate_stats()
	player.character_id = str(payload.get("character_id", "restorer_bastion"))
	player.stamina = clampf(float(payload.get("stamina", player.max_stamina)), 0, player.max_stamina)
	player.stamina_changed.emit(player.stamina, player.max_stamina)
	var saved_position: Array = payload.get("position", [])
	if saved_position.size() == 3 and saved_position.all(func(value: Variant) -> bool: return value is float or value is int):
		var point := Vector3(float(saved_position[0]), 0, float(saved_position[2]))
		if is_finite(point.x) and is_finite(point.z) and absf(point.x) < 13 and absf(point.z) < 13:
			var query := PhysicsShapeQueryParameters3D.new()
			var capsule := CapsuleShape3D.new()
			capsule.radius = 0.35
			capsule.height = 1.6
			query.shape = capsule
			query.transform = Transform3D(Basis.IDENTITY, point + Vector3(0,0.9,0))
			query.exclude = [player.get_rid()]
			if get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty(): player.position = point
	player.hp = clampi(int(payload.get("hp", player.max_hp)), 0, player.max_hp)
	player.ether = clampi(int(payload.get("ether", player.max_ether)), 0, player.max_ether)
	player.hp_changed.emit(float(player.hp), float(player.max_hp))
	player.ether_changed.emit(float(player.ether), float(player.max_ether))
	game_over = player.hp <= 0
	if death_overlay != null: death_overlay.visible = game_over
	player.clear_commands()
	_show_message("Save carregado")
	return true

func _shop_inspect(item: AethelItemInstance, button: Button) -> void:
	shop_tooltip.show_item_at(item,button.get_global_rect())
	var slot: String = player.slot_for(item)
	if player.equipped.has(slot): shop_tooltip.append_comparison(item,player.equipped[slot])

func _build_workshop() -> void:
	workshop = Node3D.new()
	workshop.name = "DomaWorkshop"
	add_child(workshop)
	# Place solids behind Doma; keep the approach from the plaza clear.
	var anvil := Node3D.new()
	anvil.name = "Anvil"
	workshop.add_child(anvil)
	anvil.position = Vector3(-10,0,-0.6)
	_box(anvil,Vector3(0,0.35,0),Vector3(0.65,0.7,0.6),Color("3a3226"))
	_box(anvil,Vector3(0,0.82,0),Vector3(1.4,0.26,0.52),Color("737877"))
	_box(anvil,Vector3(0.85,0.84,0),Vector3(0.4,0.13,0.25),Color("737877"),false)
	var forge := Node3D.new()
	forge.name = "Furnace"
	workshop.add_child(forge)
	forge.position = Vector3(-11,0,-3)
	_box(forge,Vector3(0,0.4,0),Vector3(1.8,0.8,1.3),Color("302c29"))
	_box(forge,Vector3(-0.72,1.2,0),Vector3(0.35,1.1,1.3),Color("47413b"))
	_box(forge,Vector3(0.72,1.2,0),Vector3(0.35,1.1,1.3),Color("47413b"))
	_box(forge,Vector3(0,1.85,0),Vector3(1.8,0.3,1.3),Color("47413b"))
	_box(forge,Vector3(0,1.02,0.2),Vector3(1.0,0.15,0.6),Color("e78c38"),false)
	var light := OmniLight3D.new()
	light.position = Vector3(0,1.4,0.8)
	light.light_color = Color("ff9b49")
	light.light_energy = 2
	light.omni_range = 5
	forge.add_child(light)
	var bench := Node3D.new()
	bench.name = "ToolBench"
	workshop.add_child(bench)
	bench.position = Vector3(-7.5,0,-2)
	_box(bench,Vector3(0,0.6,0),Vector3(2.1,1.2,0.8),Color("493a2c"))
	for x in [-0.65,0.0,0.65]:
		_box(bench,Vector3(x,1.28,0),Vector3(0.08,0.08,0.6),Color("817a69"),false)
		_box(bench,Vector3(x,1.28,-0.27),Vector3(0.28,0.16,0.15),Color("5c6365"),false)
	var rack := Node3D.new()
	rack.name = "EquipmentDisplay"
	workshop.add_child(rack)
	rack.position = Vector3(-6,0,-3.5)
	_box(rack,Vector3(0,0.9,0),Vector3(0.2,1.8,0.7),Color("493a2c"))
	for x in [-0.32,0.32]:
		_box(rack,Vector3(x,1.4,-0.42),Vector3(0.1,1.3,0.08),Color("8c9290"),false)
		_box(rack,Vector3(x,0.95,-0.42),Vector3(0.4,0.09,0.09),Color("9f8552"),false)

func _setup_reactive_ui() -> void:
	hud.bind_world(self)
	player.skill_used.connect(func(_id: String) -> void: audio.play_cue("skill"))
	player.equipment_changed.connect(func() -> void: hud.refresh_skills())
	var canvas := CanvasLayer.new()
	canvas.layer = 7
	add_child(canvas)
	quest_panel = PanelContainer.new()
	quest_panel.position = Vector2(20,150)
	quest_panel.custom_minimum_size = Vector2(410,250)
	canvas.add_child(quest_panel)
	var column := VBoxContainer.new()
	quest_panel.add_child(column)
	var title := Label.new()
	title.text = "MISSÕES · U"
	column.add_child(title)
	quest_text = RichTextLabel.new()
	quest_text.custom_minimum_size = Vector2(386,185)
	quest_text.bbcode_enabled = true
	quest_text.scroll_active = true
	column.add_child(quest_text)
	var close := Button.new()
	close.text = "Fechar"
	close.pressed.connect(quest_panel.hide)
	column.add_child(close)
	quest_panel.hide()
	mission_changed.connect(_refresh_quest_panel)
	var toolbar := HBoxContainer.new()
	hud.root.add_child(toolbar)
	toolbar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	toolbar.offset_left = -370
	toolbar.offset_right = -18
	toolbar.offset_top = -180
	toolbar.offset_bottom = -138
	for entry: Array in [["I Mochila","inventory"],["C Atributos","character"],["U Missões","quests"],["Esc Pausa","pause"]]:
		var button := Button.new()
		button.text = entry[0]
		button.add_theme_font_size_override("font_size",12)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void:
			if game_over: return
			match str(entry[1]):
				"inventory": inventory_view.visible = not inventory_view.visible
				"character": _toggle_left_panel(character_panel)
				"quests": quest_panel.visible = not quest_panel.visible; _refresh_quest_panel()
				"pause": player.clear_commands(); pause_menu.open()
			audio.play_cue("ui",true))
		toolbar.add_child(button)
	_build_death_interface()

func _check_mission_change() -> void:
	if narrative == null: return
	var signature: Array = [quest_started,quest_completed,map_02_cleared,slain,narrative.reward_claimed]
	if signature == _mission_signature: return
	_mission_signature = signature
	mission_changed.emit()

func _refresh_quest_panel() -> void:
	if quest_text == null: return
	if not quest_started:
		quest_text.text = "Converse com Maera Voss para conhecer o objetivo disponível."
		return
	quest_text.text = "[b]Investigação do Bairro — provisória[/b]\n"
	quest_text.text += "Uma Porta para Ninguém: âncoras e decisão canônica ainda não implementadas.\n\n"
	if quest_completed:
		quest_text.text += "Relatório entregue a Maera.\nRecompensa recebida: 60 ouro." if narrative.reward_claimed else "Investigação registrada em save legado; sem recompensa retroativa."
	elif map_02_cleared: quest_text.text += "Objetivo: retornar e relatar a Maera.\nRasuras: 5 / 5.\nRecompensa prevista: 60 ouro, uma vez."
	else: quest_text.text += "Objetivo: atravessar o portal e investigar as Rasuras.\nRasuras: %d / 5.\nRecompensa prevista: 60 ouro, uma vez." % mini(slain,5)

func _build_death_interface() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	death_overlay = ColorRect.new()
	(death_overlay as ColorRect).color = Color(AethelUI.BACKGROUND,0.92)
	layer.add_child(death_overlay)
	death_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	death_overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 430
	center.add_child(column)
	var title := Label.new()
	title.text = "DERROTA\nSeu último save permanece disponível."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	for text: String in ["CARREGAR ÚLTIMO SAVE","NOVO JOGO · R","MENU PRINCIPAL"]:
		var button := Button.new()
		button.text = text
		button.custom_minimum_size.y = 44
		button.disabled = text.begins_with("CARREGAR") and not FileAccess.file_exists(SAVE_PATH)
		button.pressed.connect(func() -> void:
			if text.begins_with("CARREGAR"):
				if _load_state(): _refresh_all()
			elif text.begins_with("NOVO"):
				Engine.set_meta("aethel_new_game",true)
				get_tree().reload_current_scene()
			else: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
		column.add_child(button)
	death_overlay.hide()

func _on_discard_requested(uid: String) -> void:
	if game_over: return
	var item: AethelItemInstance = inventory.find_item(uid)
	if item == null: return
	if item.definition.kind == "quest" or item.definition.sale_locked:
		_inventory_failure("Este item protegido não pode ser largado")
		return
	var drop: AethelDroppedItem = _spawn_drop({"kind":"item","item":item},player.global_position)
	drop.position = player.global_position
	if not inventory.remove_item(uid):
		dropped_items.erase(drop)
		drop.queue_free()
		return
	inventory_view.selected_uid = ""
	inventory_view.tooltip.hide_item()
	_show_message("Largado no chão: " + item.display_name())
	_refresh_all()
