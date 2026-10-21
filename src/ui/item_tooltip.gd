class_name AethelItemTooltip
extends PanelContainer
## Descrição do item no estilo ARPG: nome colorido pela qualidade, base, atributos, afixos e requisitos.

const QUALITY_NAMES: Array = ["Comum", "Mágico", "Raro", "Épico", "Lendário"]
const QUALITY_HEX: Array = AethelUI.RARITY_HEX
const SLOT_NAMES: Dictionary = {"weapon": "Arma", "shield": "Escudo", "helm": "Elmo", "armor": "Armadura", "gloves": "Luvas",
	"boots": "Botas", "belt": "Cinto", "ring": "Anel", "amulet": "Amuleto", "charm": "Talismã"}

var requirement_source: Node # jogador: para pintar de vermelho requisitos não cumpridos
var _text: RichTextLabel
var _cursor_offset: Vector2 = Vector2(18.0, 18.0)
var _focus_rect := Rect2()
var _keyboard_anchor := false
var _last_viewport := Vector2.ZERO
var _last_pointer := Vector2.INF

func _ready() -> void:
	theme_type_variation = "AethelSpeech"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	custom_minimum_size = Vector2(340.0, 180.0)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = false
	_text.scroll_active = true
	_text.add_theme_font_size_override("normal_font_size",14)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.custom_minimum_size = Vector2(240.0, 0.0)
	margin.add_child(_text)
	_text.get_v_scroll_bar().mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func build_text(item: AethelItemInstance) -> String:
	var data: AethelItemData = item.definition
	var quality: int = clampi(item.get_quality(), 0, QUALITY_HEX.size() - 1)
	var lines: Array[String] = []
	lines.append("[center][color=#%s][b]%s · %s[/b][/color]" % [QUALITY_HEX[quality], item.display_name(),QUALITY_NAMES[quality]])
	lines.append("Categoria: " + str({"equipment":"Equipamento","potion":"Poção","material":"Material","quest":"Missão"}.get(data.kind,data.kind)))
	if data.slot == "weapon": lines.append("Empunhadura: %d mão(s)" % data.hands)
	if not data.description.is_empty(): lines.append(data.description)
	if data.max_stack > 1: lines.append("Quantidade: %d / %d" % [item.quantity,data.max_stack])
	if requirement_source != null and data.kind == "equipment":
		var is_equipped := false
		for current: AethelItemInstance in requirement_source.equipped.values():
			if current.instance_id == item.instance_id: is_equipped = true
		if is_equipped: lines.append("[color=#f0d999]EQUIPADO[/color]")
		else:
			var issue: String = requirement_source.equipment_problem(item)
			if not issue.is_empty(): lines.append("[color=#ed9385]Não é possível equipar: %s[/color]" % issue)
	if item.display_name() != item.base_display_name():
		lines.append("[color=#b5a88e]%s[/color]" % item.base_display_name())
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
		if data.slot != "": lines.append("[color=#a39780]%s · %s[/color]" % [QUALITY_NAMES[quality], SLOT_NAMES.get(data.slot, data.slot)])
	lines.append("[color=#a39780]Valor: %d ouro[/color]" % item.gold_value())
	lines.append("[color=#a39780]Venda: %d ouro / unidade · Pilha: %d[/color]" % [maxi(1,int(item.gold_value()/4)),maxi(1,int(item.gold_value()/4))*item.quantity])
	return "\n".join(lines)

func _current(kind: String) -> int:
	if requirement_source == null: return 9999
	if kind == "level": return int(requirement_source.character_level)
	return int(requirement_source.total_attribute(kind))

func _requirement(label_text: String, needed: int, current: int) -> String:
	var color: String = "ff6060" if current < needed else "e8e8e8"
	return "[color=#%s]Requer %s: %d[/color]" % [color, label_text, needed]

func show_item(item: AethelItemInstance) -> void:
	theme_type_variation = "AethelSpeech"
	_keyboard_anchor = false
	if item == null or item.definition == null:
		hide_item()
		return
	_text.text = build_text(item)
	_fit_to_viewport()
	visible = true
	_update_position()

func show_item_at(item: AethelItemInstance, anchor_rect: Rect2) -> void:
	show_item(item)
	_focus_rect = anchor_rect
	_keyboard_anchor = true
	_update_position()

func show_comparison(item: AethelItemInstance, equipped: AethelItemInstance) -> void:
	# The caller chooses the equipped item; no slot or stat rules are duplicated here.
	show_item(item)
	if equipped != null:
		theme_type_variation = "AethelComparison"
		_text.text += "\n\n[center][b]EQUIPADO[/b][/center]\n" + build_text(equipped)
		_fit_to_viewport()
		_update_position()

func append_comparison(item: AethelItemInstance, equipped: AethelItemInstance) -> void:
	var current := equipped.comparison_values() if equipped != null else {}
	var proposed := item.comparison_values()
	var keys := proposed.keys()
	for key in current:
		if not key in keys: keys.append(key)
	keys.sort()
	var comparison := "[b]Comparação com %s[/b]" % (equipped.display_name() if equipped != null else "slot vazio")
	var changes := 0
	for key in keys:
		var difference := float(proposed.get(key,0))-float(current.get(key,0))
		if absf(difference) < 0.001: continue
		changes += 1
		comparison += "\n[color=#%s]%s: %+.1f[/color]" % ["a3d8ad" if difference > 0 else "ed9385",key,difference]
	if changes == 0: comparison += "\nSem diferenças nos valores comparados."
	comparison += "\nDeltas do item; dano base sem bônus do personagem."
	var lines := _text.text.split("\n")
	_text.text = lines[0] + "\n\n" + comparison + "\n\n" + "\n".join(lines.slice(1))
	_fit_to_viewport()

func hide_item() -> void:
	visible = false

func scroll_by(amount: float) -> void:
	var bar := _text.get_v_scroll_bar()
	bar.value += amount

func _process(_delta: float) -> void:
	if not visible: return
	var viewport_size := get_viewport_rect().size
	var pointer: Vector2 = _focus_rect.end if _keyboard_anchor else get_viewport().get_mouse_position()
	if viewport_size != _last_viewport:
		_fit_to_viewport()
		_update_position()
	elif pointer != _last_pointer: _update_position()

func _fit_to_viewport() -> void:
	# Fixed bounded reading area: content height depends on scrollbar width, so
	# resizing from get_content_height every frame can create a layout oscillation.
	var limits := get_viewport_rect().size-Vector2(24,24)
	custom_minimum_size = Vector2(minf(340,limits.x),minf(420,limits.y))
	size = custom_minimum_size
	_last_viewport = get_viewport_rect().size

func _update_position() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var pointer: Vector2 = _focus_rect.end if _keyboard_anchor else get_viewport().get_mouse_position()
	var proposed: Vector2 = pointer + _cursor_offset
	if proposed.x + size.x > viewport_size.x: proposed.x = pointer.x - size.x - _cursor_offset.x
	if proposed.y + size.y > viewport_size.y: proposed.y = pointer.y - size.y - _cursor_offset.y
	_last_pointer = pointer
	global_position = Vector2(clampf(proposed.x, 0.0, maxf(0.0, viewport_size.x - size.x)), clampf(proposed.y, 0.0, maxf(0.0, viewport_size.y - size.y)))
