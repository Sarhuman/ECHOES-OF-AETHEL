class_name AethelInventoryView
extends Control
## Mochila 10x4 com lista de equipamento. Esquerdo: equipar/desequipar. Direito: vender (loja aberta).

signal equip_requested(instance_id: String)
signal unequip_requested(slot: String)
signal sell_requested(instance_id: String)

const SLOT_SIZE: int = 48
const SLOT_LABELS: Dictionary = {"cape": "Capa", "weapon": "Arma", "shield": "Escudo", "helm": "Elmo", "armor": "Armadura", "gloves": "Luvas",
	"boots": "Botas", "belt": "Cinto", "ring1": "Anel 1", "ring2": "Anel 2", "amulet": "Amuleto", "charm": "Talismã"}

var inventory: AethelInventoryManager
var player: Node
var grid_root: Control
var item_root: Control
var equip_root: Control
var info_label: Label
var tooltip: AethelItemTooltip
var gold_text: String = ""

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_layout()
	var panel := Panel.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var title := Label.new()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = "MOCHILA   |   Clique: equipar   |   Botão direito: vender (loja aberta)   |   I: fechar"
	title.position = Vector2(18, 14)
	add_child(title)
	grid_root = Control.new()
	grid_root.position = Vector2(18, 50)
	grid_root.size = Vector2(480, 192)
	add_child(grid_root)
	for y in range(4):
		for x in range(10):
			var square := ColorRect.new()
			square.color = Color("1b222d") if (x + y) % 2 == 0 else Color("252f3b")
			square.position = Vector2(x, y) * float(SLOT_SIZE)
			square.size = Vector2(SLOT_SIZE - 2, SLOT_SIZE - 2)
			square.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid_root.add_child(square)
	item_root = Control.new()
	item_root.size = grid_root.size
	item_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid_root.add_child(item_root)
	equip_root = Control.new()
	equip_root.position = Vector2(514, 50)
	equip_root.size = Vector2(232, 340)
	add_child(equip_root)
	info_label = Label.new()
	info_label.position = Vector2(18, 256)
	info_label.size = Vector2(480, 130)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info_label)
	tooltip = AethelItemTooltip.new()
	tooltip.name = "ItemTooltip"
	tooltip.requirement_source = player
	add_child(tooltip)

func _layout() -> void:
	set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	offset_left = -780.0
	offset_right = -20.0
	offset_top = -230.0
	offset_bottom = 170.0

func bind_inventory(manager: AethelInventoryManager) -> void:
	inventory = manager
	if not manager.inventory_updated.is_connected(refresh): manager.inventory_updated.connect(refresh)
	refresh()

func bind_player(target: Node) -> void:
	player = target
	if tooltip != null: tooltip.requirement_source = target

func _item_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.16)
	style.border_color = Color(color.r, color.g, color.b, 0.75)
	style.set_border_width_all(1)
	return style

func _attach_tooltip(button: Control, item: AethelItemInstance) -> void:
	button.mouse_entered.connect(func() -> void: tooltip.show_item(item))
	button.mouse_exited.connect(func() -> void: tooltip.hide_item())

func refresh() -> void:
	if item_root == null or inventory == null: return
	if tooltip != null: tooltip.hide_item()
	for node in item_root.get_children(): node.queue_free()
	for entry: Dictionary in inventory.entries():
		var item: AethelItemInstance = entry["instance"]
		var origin: Vector2i = entry["origin"]
		var color: Color = AethelDroppedItem.COLORS[clampi(item.get_quality(), 0, 4)]
		var button := Button.new()
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.text = item.display_name()
		button.clip_text = true
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 11)
		button.add_theme_color_override("font_color", color)
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, _item_style(color))
		button.position = Vector2(origin) * float(SLOT_SIZE)
		button.size = Vector2(item.definition.width, item.definition.height) * float(SLOT_SIZE) - Vector2(2, 2)
		var uid: String = item.instance_id
		button.pressed.connect(func() -> void: equip_requested.emit(uid))
		button.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
				sell_requested.emit(uid)
		)
		_attach_tooltip(button, item)
		item_root.add_child(button)
	_refresh_equipment()
	if info_label != null:
		var lines: Array[String] = [gold_text]
		if player != null:
			lines.append("Dano %d–%d  |  Defesa %d  |  Bloqueio %d%%" % [roundi(player.damage_min), roundi(player.damage_max), player.defense, roundi(player.block_chance)])
		info_label.text = "\n".join(lines)

func _refresh_equipment() -> void:
	if equip_root == null: return
	for node in equip_root.get_children(): node.queue_free()
	if player == null: return
	var row: int = 0
	for slot: String in player.SLOT_ORDER:
		var item: AethelItemInstance = player.equipped.get(slot)
		var button := Button.new()
		button.position = Vector2(0, row * 28)
		button.size = Vector2(232, 26)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 12)
		if item == null:
			button.text = "%s: —" % SLOT_LABELS[slot]
			button.add_theme_color_override("font_color", Color("707070"))
		else:
			var color: Color = AethelDroppedItem.COLORS[clampi(item.get_quality(), 0, 4)]
			button.text = "%s: %s" % [SLOT_LABELS[slot], item.display_name()]
			button.add_theme_color_override("font_color", color)
			for state in ["normal", "hover", "pressed", "focus"]:
				button.add_theme_stylebox_override(state, _item_style(color))
			_attach_tooltip(button, item)
		var slot_name: String = slot
		button.pressed.connect(func() -> void: unequip_requested.emit(slot_name))
		equip_root.add_child(button)
		row += 1
