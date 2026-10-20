class_name AethelHUDManager
extends CanvasLayer
signal skill_selected(index: int)
var skill_buttons: Array[Button] = []

var resource_panel: PanelContainer
var hp_bar: ProgressBar
var ether_bar: ProgressBar
var hp_text: Label
var ether_text: Label
var stamina_bar: ProgressBar
var stamina_text: Label
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

func _make_skill_bar() -> void:
	var row := HBoxContainer.new()
	root.add_child(row)
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_left = -210
	row.offset_right = 210
	row.offset_top = -166
	row.offset_bottom = -110
	for index in 3:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.text = ["F1 Golpe", "F2 Guarda", "F3 Eco"][index]
		button.custom_minimum_size = Vector2(138, 54)
		button.tooltip_text = "Clique ou F1–F3: executar. Botão direito repete a última técnica."
		var selected := index
		button.pressed.connect(func() -> void: skill_selected.emit(selected))
		row.add_child(button)
		skill_buttons.append(button)

func update_skills(selected: String, unlocked: Dictionary, ids: Array, actor: Node = null, catalog: Dictionary = {}) -> void:
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
		button.text = "%s\n%s" % [["F1 GOLPE", "F2 GUARDA", "F3 ECO"][index], state]
		button.disabled = not unlocked.has(id) or (actor != null and actor.hp <= 0)
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", color)
		button.add_theme_color_override("font_disabled_color", Color("a7b1bc"))
		var style := StyleBoxFlat.new()
		style.bg_color = Color("17202f")
		style.border_color = Color("91afc4") if id == selected else Color("586674")
		style.set_border_width_all(2 if id == selected else 1)
		button.add_theme_stylebox_override("normal", style)

func _make_resource_panel() -> void:
	resource_panel = PanelContainer.new()
	resource_panel.name = "ResourcePanel"
	resource_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(resource_panel)
	resource_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	resource_panel.offset_left = 18
	resource_panel.offset_right = 350
	resource_panel.offset_top = -158
	resource_panel.offset_bottom = -18
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color("121723ef")
	backing.border_color = Color("8b7957")
	backing.set_border_width_all(1)
	backing.set_content_margin_all(12)
	resource_panel.add_theme_stylebox_override("panel", backing)
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", 6)
	resource_panel.add_child(rows)
	var life := _resource_row(rows, "VIDA", Color("bc4049"), 28)
	hp_bar = life[0]
	hp_text = life[1]
	var ether := _resource_row(rows, "ÉTER", Color("376fc0"), 24)
	ether_bar = ether[0]
	ether_text = ether[1]
	var stamina := _resource_row(rows, "FÔLEGO", Color("a87d36"), 24)
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
	background.bg_color = Color("262b35")
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
	if _player != null:
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
	_update_resource(hp_bar, hp_text, current, maximum)

func _on_ether_changed(current: float, maximum: float, _instant: bool = false) -> void:
	_update_resource(ether_bar, ether_text, current, maximum)

func _on_stamina_changed(current: float, maximum: float) -> void:
	_update_resource(stamina_bar, stamina_text, current, maximum)

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
