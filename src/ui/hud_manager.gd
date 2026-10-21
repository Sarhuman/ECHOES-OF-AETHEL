class_name AethelHUDManager
extends CanvasLayer
signal skill_selected(index: int)
var skill_buttons: Array[Button] = []

var resource_panel: PanelContainer
var hp_bar: Range
var ether_bar: Range
var hp_text: Label
var ether_text: Label
var stamina_bar: ProgressBar
var stamina_text: Label
var life_globe: AethelGlobe
var ether_globe: AethelGlobe
var stamina_row: VBoxContainer
var skill_row: HBoxContainer
var effect_row: HBoxContainer
var effect_badges: Dictionary = {}
var xp_text: Label
var target_details: Label
var boss_box: PanelContainer
var boss_name: Label
var boss_bar: ProgressBar
var target_actor: CharacterBody3D
var _world: Node3D
var _progression: Node
var _skill_cache: Array = []
var presentation_updates := 0
var _player: Node

var root: Control
var belt_labels: Array[Label] = []
var xp_bar: ProgressBar
var target_box: Control
var target_name: Label
var target_bar: ProgressBar
var skill_label: Label

func _ready() -> void:
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_make_resource_panel()
	_make_belt()
	_make_xp_bar()
	_make_target_bar()
	_make_skill_label()
	_make_skill_bar()
	_make_effects()
	apply_settings()

func _make_skill_bar() -> void:
	skill_row = HBoxContainer.new()
	var row := skill_row
	root.add_child(row)
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_left = -210
	row.offset_right = 210
	row.offset_top = -166
	row.offset_bottom = -110
	for index in 3:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.icon = [preload("res://assets/ui/skills/strike.svg"),preload("res://assets/ui/skills/guard.svg"),preload("res://assets/ui/skills/cleave.svg")][index]
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width",24)
		button.text = ["F1 Golpe", "F2 Guarda", "F3 Eco"][index]
		button.custom_minimum_size = Vector2(138, 54)
		button.tooltip_text = "Clique ou F1–F3: executar. Botão direito repete a última técnica."
		var selected := index
		button.pressed.connect(func() -> void: skill_selected.emit(selected))
		row.add_child(button)
		skill_buttons.append(button)

func update_skills(selected: String, unlocked: Dictionary, ids: Array, actor: Node = null, catalog: Dictionary = {}) -> void:
	var cache: Array = []
	for index in skill_buttons.size():
		var button := skill_buttons[index]
		var id: String = ids[index]
		var state := "Indisponível"
		var color := Color("92a3b0")
		if unlocked.has(id):
			state = "Pronto"
			color = Color("e4ebf2")
			if actor != null and catalog.has(id):
				var skill: AethelSkillData = catalog[id]
				var issue: String = actor.skill_problem(skill)
				if id == "iron_guard" and actor.guard_remaining > 0:
					state = "Ativa %.1fs" % actor.guard_remaining
					color = Color("a3e4c3")
				elif issue == "Em recarga":
					state = "Recarga %.1fs" % float(actor.skill_cooldowns.get(id, 0))
					color = Color("e4c083")
				elif not issue.is_empty():
					state = issue
					color = Color("e7a5a5")
				else: state = "Pronto · %d Éter" % skill.ether_cost
		var snapshot: Array = [id,state,color,unlocked.has(id),actor.hp <= 0 if actor != null else false,id == selected]
		cache.append(snapshot)
		if index < _skill_cache.size() and _skill_cache[index] == snapshot: continue
		presentation_updates += 1
		button.text = "%s\n%s" % [["F1 GOLPE", "F2 GUARDA", "F3 ECO"][index], state]
		button.disabled = not unlocked.has(id) or (actor != null and actor.hp <= 0)
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", color)
		button.add_theme_color_override("font_disabled_color", Color("a7b1bc"))
		var style := AethelUI.panel(AethelUI.SURFACE,AethelUI.UNIQUE_REFERENCE if id == selected else AethelUI.BRASS,2 if id == selected else 1)
		style.set_content_margin_all(4)
		button.add_theme_stylebox_override("normal", style)

	_skill_cache = cache

func _make_resource_panel() -> void:
	resource_panel = PanelContainer.new()
	resource_panel.name = "ResourcePanel"
	resource_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(resource_panel)
	resource_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	resource_panel.offset_left = 18
	resource_panel.offset_right = 350
	resource_panel.offset_top = -194
	resource_panel.offset_bottom = -18
	resource_panel.add_theme_stylebox_override("panel",AethelUI.panel(AethelUI.BACKGROUND,AethelUI.BRASS))
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation",2)
	resource_panel.add_child(column)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)
	life_globe = AethelGlobe.new()
	life_globe.resource_title = "VIDA"
	life_globe.liquid_color = AethelUI.LIFE
	row.add_child(life_globe)
	ether_globe = AethelGlobe.new()
	ether_globe.resource_title = "ÉTER"
	ether_globe.liquid_color = AethelUI.ETHER
	row.add_child(ether_globe)
	hp_bar = life_globe.progress
	hp_text = life_globe.amount_label
	ether_bar = ether_globe.progress
	ether_text = ether_globe.amount_label
	var stamina := _resource_row(column,"FÔLEGO",AethelUI.STAMINA,22)
	stamina_bar = stamina[0]
	stamina_text = stamina[1]

func _resource_row(parent: Control, title: String, color: Color, height: int) -> Array:
	var bar := ProgressBar.new()
	bar.name = title
	bar.custom_minimum_size = Vector2(306, height)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = AethelUI.SURFACE
	bar.add_theme_stylebox_override("background", background)
	parent.add_child(bar)
	var text := Label.new()
	text.text = title
	text.set_meta("resource_title", title)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 14)
	text.add_theme_color_override("font_shadow_color", Color.BLACK)
	text.add_theme_constant_override("shadow_offset_x", 1)
	text.add_theme_constant_override("shadow_offset_y", 1)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(text)
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return [bar, text]

func _update_resource(bar: ProgressBar, text: Label, current: float, maximum: float) -> void:
	bar.max_value = maxf(1, maximum)
	bar.value = clampf(current, 0, maximum)
	text.text = "%s  %d / %d" % [text.get_meta("resource_title"), roundi(current), roundi(maximum)]

func setup_player_listeners(player: Node) -> void:
	if is_instance_valid(_player):
		if _player.hp_changed.is_connected(_on_hp_changed): _player.hp_changed.disconnect(_on_hp_changed)
		if _player.ether_changed.is_connected(_on_ether_changed): _player.ether_changed.disconnect(_on_ether_changed)
		if _player.stamina_changed.is_connected(_on_stamina_changed): _player.stamina_changed.disconnect(_on_stamina_changed)
	_player = player
	player.hp_changed.connect(_on_hp_changed)
	player.ether_changed.connect(_on_ether_changed)
	if player.has_signal("stamina_changed"):
		player.stamina_changed.connect(_on_stamina_changed)
	_on_hp_changed(player.hp, player.max_hp, true)
	_on_ether_changed(player.ether, player.max_ether, true)
	_on_stamina_changed(player.stamina, player.max_stamina)

func _on_hp_changed(current: float, maximum: float, _instant: bool = false) -> void:
	life_globe.update_value(current,maximum,_instant)

func _on_ether_changed(current: float, maximum: float, _instant: bool = false) -> void:
	ether_globe.update_value(current,maximum,_instant)

func _on_stamina_changed(current: float, maximum: float) -> void:
	_update_resource(stamina_bar, stamina_text, current, maximum)
	if current < 8: stamina_text.text += " · BAIXO"

func _make_belt() -> void:
	var container := Control.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(container)
	container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	container.offset_left = -94.0
	container.offset_right = 94.0
	container.offset_top = -104.0
	container.offset_bottom = -58.0
	for index in range(4):
		var slot := Panel.new()
		slot.position = Vector2(float(index) * 48.0, 0.0)
		slot.size = Vector2(44.0, 44.0)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(slot)
		var label := Label.new()
		label.position = Vector2(0.0, 2.0)
		label.size = Vector2(44.0, 40.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(label)
		belt_labels.append(label)
	update_belt([], {})

func update_belt(belt: Array, catalog: Dictionary) -> void:
	for index in range(belt_labels.size()):
		var label: Label = belt_labels[index]
		var entry: Dictionary = belt[index] if index < belt.size() else {}
		if entry.is_empty():
			label.text = "%d" % (index + 1)
			label.add_theme_color_override("font_color", Color("707070"))
			continue
		var data: AethelItemData = catalog.get(str(entry["kind"]))
		var is_life: bool = data != null and data.heal_life > 0
		label.text = "%d\n%s%d" % [index + 1, "V" if is_life else "É", int(entry["count"])]
		label.add_theme_color_override("font_color", Color("ff6a6a") if is_life else Color("6a9cff"))

func _make_xp_bar() -> void:
	xp_bar = ProgressBar.new()
	xp_bar.show_percentage = false
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_bar.max_value = 100.0
	root.add_child(xp_bar)
	xp_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	xp_bar.offset_top = -8.0
	xp_bar.offset_bottom = -2.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color("d9b84a")
	xp_bar.add_theme_stylebox_override("fill", style)

func set_xp(current: int, required: int) -> void:
	if xp_bar == null: return
	xp_bar.max_value = float(maxi(1, required))
	xp_bar.value = float(current)
	if xp_text != null: xp_text.text = "Nível %d · XP %d / %d" % [_progression.current_level if is_instance_valid(_progression) else 1,current,required]

func _make_target_bar() -> void:
	target_box = Control.new()
	target_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(target_box)
	target_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	target_box.offset_left = -190.0
	target_box.offset_right = 190.0
	target_box.offset_top = 12.0
	target_box.offset_bottom = 60.0
	target_name = Label.new()
	target_name.size = Vector2(380.0, 24.0)
	target_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_name.add_theme_font_size_override("font_size", 17)
	target_name.add_theme_color_override("font_shadow_color", Color.BLACK)
	target_name.add_theme_constant_override("shadow_offset_x", 1)
	target_name.add_theme_constant_override("shadow_offset_y", 1)
	target_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_box.add_child(target_name)
	target_bar = ProgressBar.new()
	target_bar.position = Vector2(20.0, 28.0)
	target_bar.size = Vector2(340.0, 14.0)
	target_bar.show_percentage = false
	target_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("b8302f")
	target_bar.add_theme_stylebox_override("fill", style)
	target_box.add_child(target_bar)
	target_details = Label.new()
	target_details.position = Vector2(-50,48)
	target_details.size = Vector2(480,40)
	target_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_details.add_theme_font_size_override("font_size",12)
	target_details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_box.add_child(target_details)
	boss_box = PanelContainer.new()
	root.add_child(boss_box)
	boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_box.offset_left = -220
	boss_box.offset_right = 220
	boss_box.offset_top = 88
	boss_box.offset_bottom = 158
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_box.add_theme_stylebox_override("panel",AethelUI.panel(AethelUI.BACKGROUND,AethelUI.RARE,2))
	var boss_column := VBoxContainer.new()
	boss_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_box.add_child(boss_column)
	boss_name = Label.new()
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_column.add_child(boss_name)
	boss_bar = ProgressBar.new()
	boss_bar.custom_minimum_size = Vector2(416,22)
	boss_bar.show_percentage = true
	boss_column.add_child(boss_bar)
	boss_box.hide()
	target_box.visible = false

func show_target(display_name: String, current: int, maximum: int, color: Color) -> void:
	if target_box == null: return
	target_box.visible = true
	target_name.text = display_name
	target_name.add_theme_color_override("font_color", color)
	target_bar.max_value = float(maxi(1, maximum))
	target_bar.value = float(maxi(0, current))

func hide_target() -> void:
	if target_box != null: target_box.visible = false
	if boss_box != null: boss_box.hide()

func _make_skill_label() -> void:
	skill_label = Label.new()
	skill_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	skill_label.add_theme_font_size_override("font_size", 14)
	root.add_child(skill_label)
	skill_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skill_label.offset_left = -330.0
	skill_label.offset_right = -18.0
	skill_label.offset_top = -54.0
	skill_label.offset_bottom = -18.0

func set_right_skill(text_value: String) -> void:
	if skill_label != null: skill_label.text = text_value

func _make_effects() -> void:
	effect_row = HBoxContainer.new()
	effect_row.add_theme_constant_override("separation",6)
	root.add_child(effect_row)
	effect_row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	effect_row.offset_left = -210
	effect_row.offset_right = 210
	effect_row.offset_top = -214
	effect_row.offset_bottom = -178
	xp_text = Label.new()
	xp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(xp_text)
	xp_text.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	xp_text.offset_left = -200
	xp_text.offset_right = 200
	xp_text.offset_top = -40
	xp_text.offset_bottom = -15

func show_effect(id: String,remaining: float,intensity: float) -> void:
	if remaining <= 0:
		if effect_badges.has(id): effect_badges[id].queue_free(); effect_badges.erase(id)
		return
	if not effect_badges.has(id):
		var badge := Button.new()
		badge.focus_mode = Control.FOCUS_NONE
		badge.custom_minimum_size = Vector2(160,32)
		badge.icon = preload("res://assets/ui/aethel_portal.svg")
		badge.expand_icon = true
		badge.add_theme_constant_override("icon_max_width",20)
		effect_row.add_child(badge)
		effect_badges[id] = badge
	var name: String = {"guard":"Guarda","altar":"Altar de Ardósia"}.get(id,id)
	effect_badges[id].text = "%s · %ds" % [name,ceili(remaining)]
	effect_badges[id].tooltip_text = "%s\nDuração: %ds\nRedução de dano: %d%%" % [name,ceili(remaining),roundi(intensity*100)]

func bind_world(world: Node3D) -> void:
	if _world == world: return
	_world = world
	_progression = world.progression
	_progression.xp_changed.connect(set_xp)
	_progression.leveled_up.connect(_level_up)
	world.player.skills_changed.connect(refresh_skills)
	world.player.effect_changed.connect(show_effect)
	world.exploration.effect_changed.connect(show_effect)
	world.target_changed.connect(bind_target)
	world.skill_tree.skills_updated.connect(refresh_skills)
	set_xp(_progression.current_xp,_progression.required_xp(_progression.current_level))
	refresh_skills()

func refresh_skills() -> void:
	if is_instance_valid(_world): update_skills(_world.right_skill_id,_world.skill_tree.unlocked,_world.SKILL_IDS,_world.player,_world.skill_tree.catalog)

func _level_up(_level: int) -> void:
	set_xp(_progression.current_xp,_progression.required_xp(_progression.current_level))
	if not AethelSettings.reduced_motion:
		xp_text.modulate = AethelUI.FOCUS
		create_tween().tween_property(xp_text,"modulate",Color.WHITE,0.5)

func bind_target(actor: CharacterBody3D) -> void:
	if target_actor == actor: return
	if is_instance_valid(target_actor):
		if target_actor.damaged.is_connected(_target_damaged): target_actor.damaged.disconnect(_target_damaged)
		if target_actor.presentation_changed.is_connected(_target_refresh): target_actor.presentation_changed.disconnect(_target_refresh)
		if target_actor.tree_exiting.is_connected(_target_removed): target_actor.tree_exiting.disconnect(_target_removed)
	target_actor = actor
	if not is_instance_valid(actor): hide_target(); return
	actor.damaged.connect(_target_damaged)
	actor.presentation_changed.connect(_target_refresh)
	actor.tree_exiting.connect(_target_removed)
	_target_refresh()

func _target_damaged(_actor: CharacterBody3D) -> void:
	_target_refresh()

func _target_removed() -> void:
	target_actor = null
	hide_target()

func _target_refresh() -> void:
	if not is_instance_valid(target_actor) or target_actor.hp <= 0: hide_target(); return
	var category: String = str(target_actor.get_meta("category",["common","champion","elite"][target_actor.rank]))
	var title: String = {"common":"Comum","champion":"Campeão","elite":"Elite","miniboss":"Mini-chefe","boss":"Chefe"}.get(category,"Comum")
	show_target(target_actor.monster_name+" · "+title,target_actor.hp,target_actor.max_hp,AethelUI.RARITY_TEXT[mini(target_actor.rank,4)])
	var modifiers: Array[String] = []
	for id: String in target_actor.modifiers: modifiers.append(str(target_actor.modifier_rules[id].name))
	target_details.text = " · ".join(modifiers)
	if target_actor.ward_remaining > 0: target_details.text += " · Proteção %ds" % ceili(target_actor.ward_remaining)
	boss_box.visible = category in ["miniboss","boss"]
	if boss_box.visible:
		boss_name.text = target_actor.monster_name+" · "+title
		boss_bar.max_value = target_actor.max_hp
		boss_bar.value = maxi(0,target_actor.hp)
		target_box.hide()

func apply_settings() -> void:
	if resource_panel == null: return
	resource_panel.pivot_offset = Vector2(0,resource_panel.size.y)
	resource_panel.scale = Vector2.ONE*AethelSettings.hud_scale
	if skill_row != null:
		skill_row.pivot_offset = Vector2(210,54)
		skill_row.scale = Vector2.ONE*AethelSettings.hud_scale
	life_globe.set_shader_enabled(AethelSettings.shader_globes)
	ether_globe.set_shader_enabled(AethelSettings.shader_globes)
