class_name AethelItemTooltip
extends PanelContainer
## Descrição do item no estilo ARPG: nome colorido pela qualidade, base, atributos, afixos e requisitos.

const QUALITY_NAMES: Array = ["Comum", "Mágico", "Raro", "Épico", "Lendário"]
const QUALITY_HEX: Array = ["e8e8e8", "8c8cff", "ffff64", "b885ec", "c7b377"]
const SLOT_NAMES: Dictionary = {"weapon": "Arma", "shield": "Escudo", "helm": "Elmo", "armor": "Armadura", "gloves": "Luvas",
	"boots": "Botas", "belt": "Cinto", "ring": "Anel", "amulet": "Amuleto", "charm": "Talismã"}

var requirement_source: Node # jogador: para pintar de vermelho requisitos não cumpridos
var _text: RichTextLabel
var _cursor_offset: Vector2 = Vector2(18.0, 18.0)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	custom_minimum_size = Vector2(260.0, 0.0)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.custom_minimum_size = Vector2(240.0, 0.0)
	margin.add_child(_text)
	visible = false

func build_text(item: AethelItemInstance) -> String:
	var data: AethelItemData = item.definition
	var quality: int = clampi(item.get_quality(), 0, QUALITY_HEX.size() - 1)
	var lines: Array[String] = []
	lines.append("[center][color=#%s][b]%s[/b][/color]" % [QUALITY_HEX[quality], item.display_name()])
	if item.display_name() != item.base_display_name():
		lines.append("[color=#a0a0a0]%s[/color]" % item.base_display_name())
	if data.is_potion():
		if data.heal_life > 0: lines.append("Recupera %d de Vida" % data.heal_life)
		if data.heal_mana > 0: lines.append("Recupera %d de Éter" % data.heal_mana)
	else:
		if data.damage_max > 0: lines.append("Dano: %d a %d" % [data.damage_min, data.damage_max])
		if data.defense > 0:
			var shown: int = item.defense_value()
			lines.append("Defesa: %d" % shown if shown == data.defense else "Defesa: [color=#8c8cff]%d[/color]" % shown)
		if data.block_chance > 0: lines.append("Chance de bloquear: %d%%" % data.block_chance)
		var requirements: Array[String] = []
		if data.req_level > 0: requirements.append(_requirement("Nível", data.req_level, _current("level")))
		if data.req_strength > 0: requirements.append(_requirement("Força", data.req_strength, _current("strength")))
		if data.req_dexterity > 0: requirements.append(_requirement("Destreza", data.req_dexterity, _current("dexterity")))
		lines.append_array(requirements)
		var color: String = "c7b377" if quality == AethelItemData.Rarity.UNIQUE else "8c8cff"
		for row: Dictionary in item.all_modifiers():
			lines.append("[color=#%s]%s[/color]" % [color, AethelAffixData.describe(str(row["stat"]), float(row["value"]))])
		if data.slot != "": lines.append("[color=#808080]%s · %s[/color]" % [QUALITY_NAMES[quality], SLOT_NAMES.get(data.slot, data.slot)])
	lines.append("[color=#808080]Valor: %d ouro[/color]" % item.gold_value())
	return "\n".join(lines)

func _current(kind: String) -> int:
	if requirement_source == null: return 9999
	if kind == "level": return int(requirement_source.character_level)
	return int(requirement_source.total_attribute(kind))

func _requirement(label_text: String, needed: int, current: int) -> String:
	var color: String = "ff6060" if current < needed else "e8e8e8"
	return "[color=#%s]Requer %s: %d[/color]" % [color, label_text, needed]

func show_item(item: AethelItemInstance) -> void:
	if item == null or item.definition == null:
		hide_item()
		return
	_text.text = build_text(item)
	reset_size()
	visible = true
	_update_position()

func hide_item() -> void:
	visible = false

func _process(_delta: float) -> void:
	if visible: _update_position()

func _update_position() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var pointer: Vector2 = get_viewport().get_mouse_position()
	var proposed: Vector2 = pointer + _cursor_offset
	if proposed.x + size.x > viewport_size.x: proposed.x = pointer.x - size.x - _cursor_offset.x
	if proposed.y + size.y > viewport_size.y: proposed.y = pointer.y - size.y - _cursor_offset.y
	global_position = Vector2(clampf(proposed.x, 0.0, maxf(0.0, viewport_size.x - size.x)), clampf(proposed.y, 0.0, maxf(0.0, viewport_size.y - size.y)))
