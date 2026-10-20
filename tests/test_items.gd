extends SceneTree
# godot --headless --path . --script res://tests/test_items.gd
var failures: Array[String] = []

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _initialize() -> void:
	var catalog: Dictionary = AethelItemCatalog.create_catalog()
	_check(catalog.has("hp_small") and catalog.has("unq_sino") and catalog.has("iron_axe"), "catálogo completo")
	var gen := AethelLootGenerator.new(catalog, 12345)
	var counts: Dictionary = {0: 0, 1: 0, 2: 0, 4: 0}
	var affix_ok: bool = true
	for i in 4000:
		var item: AethelItemInstance = gen.roll_item(10)
		_check(item != null, "roll_item não pode retornar null")
		if item == null: break
		counts[item.get_quality()] = int(counts.get(item.get_quality(), 0)) + 1
		var stats: Dictionary = {}
		for affix: Dictionary in item.affixes:
			if stats.has(affix["stat"]): affix_ok = false
			stats[affix["stat"]] = true
		match item.get_quality():
			AethelItemData.Rarity.MAGIC: _check(item.affixes.size() >= 1 and item.affixes.size() <= 2, "mágico tem 1-2 afixos")
			AethelItemData.Rarity.RARE: _check(item.affixes.size() >= 3, "raro tem 3+ afixos")
			AethelItemData.Rarity.NORMAL: _check(item.affixes.is_empty(), "normal sem afixos")
	_check(affix_ok, "sem stats repetidos no mesmo item")
	_check(counts[0] > counts[1] and counts[1] > counts[2] and counts[2] > counts[4], "raridade decrescente: %s" % str(counts))
	_check(counts[4] > 0, "únicos devem aparecer em 4000 rolagens")
	# serialização completa de afixos
	gen.set_seed(7)
	var rare: AethelItemInstance = gen.roll_item(12, 2, 0.0, AethelItemData.Rarity.RARE)
	_check(rare.get_quality() >= AethelItemData.Rarity.RARE, "qualidade mínima rara")
	var json_text: String = JSON.stringify(rare.serialize())
	var back: AethelItemInstance = AethelItemInstance.from_dict(JSON.parse_string(json_text), catalog)
	_check(back != null and back.display_name() == rare.display_name(), "nome preservado no JSON")
	_check(back.affixes.size() == rare.affixes.size() and back.stat_total("life") == rare.stat_total("life"), "afixos preservados no JSON")
	# nome de item mágico
	var magic := AethelItemInstance.new(catalog["hand_axe"])
	magic.quality = AethelItemData.Rarity.MAGIC
	magic.affixes = [{"id":"cortante","kind":"prefix","name":"Cortante","stat":"damage_pct","value":20},{"id":"furia","kind":"suffix","name":"de Fúria","stat":"attack_speed","value":9}]
	_check(magic.display_name() == "Machado de Mão Cortante de Fúria", "nome mágico: " + magic.display_name())
	_check(magic.stat_total("damage_pct") == 20.0, "stat_total soma afixos")
	# defesa melhorada
	var armor := AethelItemInstance.new(catalog["scale_mail"])
	armor.affixes = [{"id":"x","kind":"prefix","name":"Resistente","stat":"defense_pct","value":50},{"id":"y","kind":"suffix","name":"de Ferro","stat":"defense_flat","value":4}]
	_check(armor.defense_value() == 28 + 14 + 4, "defesa = base*(1+pct) + flat (%d)" % armor.defense_value())
	# itens únicos e legados
	var unique := AethelItemInstance.new(catalog["unq_sino"])
	_check(unique.display_name() == "Cutelo do Último Sino" and unique.stat_total("strength") == 8.0, "único com afixos fixos")
	var ring := AethelItemInstance.new(catalog["ether_ring"])
	_check(ring.stat_total("mana") == 18.0, "bônus legado convertido")
	# drops: campeão sempre dá item mágico+, chefe dá 3
	var champion_drops: Array = gen.roll_drops(8, 1)
	var champion_items: int = 0
	for entry: Dictionary in champion_drops:
		if entry["kind"] == "item" and entry["item"].get_quality() >= 1: champion_items += 1
	_check(champion_items >= 1, "campeão derruba item mágico ou melhor")
	var boss_items: int = 0
	for entry: Dictionary in gen.roll_drops(8, 2):
		if entry["kind"] == "item": boss_items += 1
	_check(boss_items >= 3, "chefe derruba 3+ itens")
	# magic find aumenta raros
	gen.set_seed(99)
	var base_rare: int = 0
	for i in 3000: if gen.roll_item(10, 0, 0.0).get_quality() >= 2: base_rare += 1
	gen.set_seed(99)
	var mf_rare: int = 0
	for i in 3000: if gen.roll_item(10, 0, 200.0).get_quality() >= 2: mf_rare += 1
	_check(mf_rare > base_rare, "magic find aumenta itens raros (%d -> %d)" % [base_rare, mf_rare])
	# atributos
	var stats := AethelCharacterStats.new()
	stats.unspent = 2
	_check(stats.spend("strength") and stats.strength == 31 and stats.unspent == 1, "gastar ponto de atributo")
	_check(not stats.spend("coragem"), "atributo inválido recusado")
	print("DISTRIBUIÇÃO (4000 itens, nível 10): ", counts)
	if failures.is_empty():
		print("ITEMS TEST OK")
		quit(0)
	else:
		for message in failures: printerr("FALHA: ", message)
		quit(1)
