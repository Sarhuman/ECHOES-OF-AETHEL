class_name AethelCharacterPanel
extends PanelContainer
## Ficha do personagem: atributos com distribuição de pontos e estatísticas derivadas.

signal changed

var player: Node
var progression: Node
var _title: Label
var _xp_label: Label
var _unspent_label: Label
var _derived_label: Label
var _rows: Dictionary = {}
var _timer: float = 0.0

const ATTRIBUTE_NAMES: Dictionary = {"strength": "Força", "dexterity": "Destreza", "vitality": "Vitalidade", "energy": "Energia"}

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(330.0, 0.0)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	margin.add_child(column)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 17)
	column.add_child(_title)
	_xp_label = Label.new()
	_xp_label.add_theme_font_size_override("font_size", 13)
	column.add_child(_xp_label)
	for attribute: String in AethelCharacterStats.ATTRIBUTES:
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.custom_minimum_size = Vector2(250, 0)
		name_label.add_theme_font_size_override("font_size", 14)
		row.add_child(name_label)
		var plus := Button.new()
		plus.text = "+"
		plus.custom_minimum_size = Vector2(32, 24)
		var attr_name: String = attribute
		plus.pressed.connect(func() -> void: _spend(attr_name))
		row.add_child(plus)
		column.add_child(row)
		_rows[attribute] = {"label": name_label, "button": plus}
	_unspent_label = Label.new()
	_unspent_label.add_theme_font_size_override("font_size", 14)
	column.add_child(_unspent_label)
	column.add_child(HSeparator.new())
	_derived_label = Label.new()
	_derived_label.add_theme_font_size_override("font_size", 13)
	column.add_child(_derived_label)

func bind(target: Node, progression_manager: Node) -> void:
	player = target
	progression = progression_manager
	refresh()

func _spend(attribute: String) -> void:
	if player == null or not player.stats.spend(attribute): return
	player.recalculate_stats()
	refresh()
	changed.emit()

func refresh() -> void:
	if player == null or _title == null: return
	_title.text = "BASTIÃO — Nível %d" % player.character_level
	if progression != null:
		_xp_label.text = "Experiência: %d / %d" % [progression.current_xp, progression.required_xp(progression.current_level)]
	for attribute: String in AethelCharacterStats.ATTRIBUTES:
		var base: int = player.stats.get_attr(attribute)
		var bonus: int = int(player.sum_stat(attribute))
		var text: String = "%s: %d" % [ATTRIBUTE_NAMES[attribute], base]
		if bonus != 0: text += "  (%+d de itens)" % bonus
		_rows[attribute]["label"].text = text
		_rows[attribute]["button"].visible = player.stats.unspent > 0
	_unspent_label.text = "Pontos de atributo restantes: %d" % player.stats.unspent
	var lines: Array[String] = []
	lines.append("Vida %d/%d   Éter %d/%d   Fôlego %d" % [player.hp, player.max_hp, player.ether, player.max_ether, roundi(player.max_stamina)])
	lines.append("Dano: %d–%d" % [roundi(player.damage_min), roundi(player.damage_max)])
	lines.append("Precisão: %d   Defesa: %d   Bloqueio: %d%%" % [player.attack_rating, player.defense, roundi(player.block_chance)])
	lines.append("Vel. de ataque: %+d%%   Vel. de movimento: %+d%%" % [roundi((player.attack_speed_mult - 1.0) * 100.0), roundi((player.move_speed_mult - 1.0) * 100.0)])
	lines.append("Itens mágicos: %+d%%" % roundi(player.magic_find))
	_derived_label.text = "\n".join(lines)

func _process(delta: float) -> void:
	if not visible: return
	_timer += delta
	if _timer >= 0.3:
		_timer = 0.0
		refresh()
