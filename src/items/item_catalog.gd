class_name AethelItemCatalog
extends RefCounted
## Catálogo: tipos-base, itens únicos e poções. IDs estáveis (usados em saves).

const BASES: Array = [
	{"id":"restorer_cape","name":"Capa do Restaurador","slot":"cape","w":2,"h":2,"def":3,"ilvl":1,"value":20,"gender":"f"},
	# --- armas (1 mão) ---
	{"id":"iron_axe","name":"Machado de Vigília","slot":"weapon","w":2,"h":3,"dmin":7,"dmax":13,"ilvl":1,"value":35},
	{"id":"hand_axe","name":"Machado de Mão","slot":"weapon","w":2,"h":3,"dmin":6,"dmax":12,"ilvl":1,"value":30},
	{"id":"short_sword","name":"Espada Curta","slot":"weapon","w":1,"h":3,"dmin":5,"dmax":11,"ilvl":1,"value":28,"gender":"f"},
	{"id":"iron_mace","name":"Maça de Ferro","slot":"weapon","w":1,"h":3,"dmin":8,"dmax":12,"ilvl":2,"value":34,"gender":"f","req_str":18},
	{"id":"long_sword","name":"Espada Longa","slot":"weapon","w":1,"h":3,"dmin":11,"dmax":20,"ilvl":5,"value":80,"gender":"f","req_lvl":5,"req_str":25,"req_dex":18},
	{"id":"war_axe","name":"Machado de Guerra","slot":"weapon","w":2,"h":3,"dmin":13,"dmax":24,"ilvl":8,"value":120,"req_lvl":8,"req_str":35},
	{"id":"spiked_flail","name":"Mangual de Espinhos","slot":"weapon","w":2,"h":3,"dmin":16,"dmax":30,"ilvl":12,"value":200,"req_lvl":12,"req_str":45},
	# --- escudos ---
	{"id":"old_shield","name":"Escudo dos Sinos","slot":"shield","w":2,"h":3,"def":9,"block":22,"ilvl":1,"value":40},
	{"id":"wood_shield","name":"Escudo de Madeira","slot":"shield","w":2,"h":2,"def":6,"block":18,"ilvl":1,"value":25},
	{"id":"iron_buckler","name":"Broquel de Ferro","slot":"shield","w":2,"h":2,"def":14,"block":26,"ilvl":6,"value":90,"req_lvl":6,"req_str":22},
	{"id":"tower_shield","name":"Escudo-Torre","slot":"shield","w":2,"h":4,"def":28,"block":32,"ilvl":11,"value":180,"req_lvl":11,"req_str":40},
	# --- armaduras ---
	{"id":"leather_cap","name":"Capuz de Couro","slot":"helm","w":2,"h":2,"def":3,"ilvl":1,"value":15,"gender":"m"},
	{"id":"iron_helm","name":"Elmo de Ferro","slot":"helm","w":2,"h":2,"def":12,"ilvl":6,"value":70,"req_lvl":6,"req_str":20},
	{"id":"quilted_armor","name":"Gibão Acolchoado","slot":"armor","w":2,"h":3,"def":8,"ilvl":1,"value":30},
	{"id":"scale_mail","name":"Cota de Escamas","slot":"armor","w":2,"h":3,"def":28,"ilvl":9,"value":150,"gender":"f","req_lvl":9,"req_str":38},
	{"id":"leather_gloves","name":"Luvas de Couro","slot":"gloves","w":2,"h":2,"def":2,"ilvl":1,"value":12,"gender":"f"},
	{"id":"chain_gloves","name":"Luvas de Malha","slot":"gloves","w":2,"h":2,"def":6,"ilvl":7,"value":60,"gender":"f","req_str":20},
	{"id":"leather_boots","name":"Botas de Couro","slot":"boots","w":2,"h":2,"def":2,"ilvl":1,"value":12,"gender":"f"},
	{"id":"chain_boots","name":"Botas de Malha","slot":"boots","w":2,"h":2,"def":6,"ilvl":7,"value":60,"gender":"f","req_str":20},
	{"id":"cloth_sash","name":"Faixa de Tecido","slot":"belt","w":2,"h":1,"def":2,"ilvl":1,"value":10,"gender":"f"},
	{"id":"plated_belt","name":"Cinto de Placas","slot":"belt","w":2,"h":1,"def":7,"ilvl":8,"value":65,"req_lvl":8,"req_str":25},
	# --- joias ---
	{"id":"plain_ring","name":"Anel Simples","slot":"ring","w":1,"h":1,"ilvl":1,"value":20},
	{"id":"plain_amulet","name":"Amuleto Simples","slot":"amulet","w":1,"h":1,"ilvl":1,"value":30},
]

const UNIQUES: Array = [
	{"id":"unq_sino","name":"Cutelo do Último Sino","base":"Machado de Guerra","slot":"weapon","w":2,"h":3,"dmin":15,"dmax":26,"ilvl":8,"value":400,"req_lvl":8,"req_str":30,
		"fixed":[{"stat":"damage_pct","value":45},{"stat":"strength","value":8},{"stat":"attack_speed","value":10}]},
	{"id":"unq_egide","name":"Égide de Vigília","base":"Escudo dos Sinos","slot":"shield","w":2,"h":3,"def":22,"block":30,"ilvl":6,"value":350,"req_lvl":6,"req_str":18,
		"gender":"f","fixed":[{"stat":"defense_pct","value":40},{"stat":"life","value":25},{"stat":"vitality","value":5}]},
	{"id":"unq_mascara","name":"Máscara sem Rosto","base":"Elmo de Ferro","slot":"helm","w":2,"h":2,"def":18,"ilvl":7,"value":320,"req_lvl":7,"req_str":20,
		"gender":"f","fixed":[{"stat":"vitality","value":8},{"stat":"mana","value":20},{"stat":"find_magic","value":15}]},
	{"id":"unq_anel","name":"Anel da Linha Única","base":"Anel Simples","slot":"ring","w":1,"h":1,"ilvl":5,"value":300,"req_lvl":5,
		"fixed":[{"stat":"find_magic","value":25},{"stat":"mana","value":20},{"stat":"energy","value":6}]},
	{"id":"unq_amuleto","name":"Amuleto do Atlas Aberto","base":"Amuleto Simples","slot":"amulet","w":1,"h":1,"ilvl":9,"value":420,"req_lvl":9,
		"fixed":[{"stat":"strength","value":6},{"stat":"dexterity","value":6},{"stat":"life","value":30}]},
]

const POTIONS: Array = [
	{"id":"hp_small","name":"Poção de Vida Menor","life":45,"value":25,"ilvl":1},
	{"id":"hp_medium","name":"Poção de Vida","life":100,"value":60,"ilvl":4},
	{"id":"hp_large","name":"Poção de Vida Maior","life":180,"value":120,"ilvl":9},
	{"id":"mana_small","name":"Poção de Éter Menor","mana":30,"value":25,"ilvl":1},
	{"id":"mana_medium","name":"Poção de Éter","mana":70,"value":60,"ilvl":4},
	{"id":"mana_large","name":"Poção de Éter Maior","mana":130,"value":120,"ilvl":9},
]

static func create_catalog() -> Dictionary:
	var result: Dictionary = {}
	for spec: Dictionary in BASES:
		var data := _make(spec)
		data.rarity = AethelItemData.Rarity.NORMAL
		result[str(data.item_id)] = data
	for spec: Dictionary in UNIQUES:
		var data := _make(spec)
		data.rarity = AethelItemData.Rarity.UNIQUE
		data.base_name = str(spec.get("base", ""))
		var fixed: Array = []
		for row: Dictionary in spec["fixed"]: fixed.append({"stat": row["stat"], "value": row["value"]})
		data.unique_affixes = fixed
		result[str(data.item_id)] = data
	for spec: Dictionary in POTIONS:
		var data := AethelItemData.new()
		data.item_id = StringName(spec["id"])
		data.display_name = str(spec["name"])
		data.kind = "potion"
		data.gender = "f"
		data.width = 1
		data.height = 1
		data.heal_life = int(spec.get("life", 0))
		data.heal_mana = int(spec.get("mana", 0))
		data.base_value = int(spec["value"])
		data.item_level = int(spec["ilvl"])
		result[str(data.item_id)] = data
	# Itens legados (saves das fases anteriores)
	var ring := AethelItemData.new()
	ring.item_id = &"ether_ring"
	ring.display_name = "Anel dos Ecos"
	ring.slot = "ring"
	ring.rarity = AethelItemData.Rarity.MAGIC
	ring.modifiers = {"bonus_ether": 18}
	ring.base_value = 60
	result["ether_ring"] = ring
	var charm := AethelItemData.new()
	charm.item_id = &"worn_charm"
	charm.display_name = "Amuleto Desgastado"
	charm.slot = "charm"
	charm.width = 1
	charm.height = 2
	charm.modifiers = {"bonus_hp": 8, "bonus_ether": 3}
	charm.base_value = 10
	result["worn_charm"] = charm
	return result

static func _make(spec: Dictionary) -> AethelItemData:
	var data := AethelItemData.new()
	data.item_id = StringName(spec["id"])
	data.display_name = str(spec["name"])
	data.slot = str(spec["slot"])
	var visual_slots: Dictionary = {"weapon":"axe", "shield":"shield", "helm":"helmet", "armor":"chest", "gloves":"gloves", "boots":"boots", "cape":"cape"}
	data.appearance_id = StringName(visual_slots.get(data.slot, ""))
	if "sword" in str(data.item_id): data.appearance_id = &"sword"
	elif "mace" in str(data.item_id) or "flail" in str(data.item_id): data.appearance_id = &"mace"
	data.width = int(spec.get("w", 1))
	data.height = int(spec.get("h", 1))
	data.damage_min = int(spec.get("dmin", 0))
	data.damage_max = int(spec.get("dmax", 0))
	data.defense = int(spec.get("def", 0))
	data.block_chance = int(spec.get("block", 0))
	data.item_level = int(spec.get("ilvl", 1))
	data.base_value = int(spec.get("value", 10))
	data.req_level = int(spec.get("req_lvl", 0))
	data.req_strength = int(spec.get("req_str", 0))
	data.req_dexterity = int(spec.get("req_dex", 0))
	data.gender = str(spec.get("gender", "m"))
	return data

static func generic_bases(catalog: Dictionary) -> Array:
	var result: Array = []
	for data: AethelItemData in catalog.values():
		if data.is_generic_base(): result.append(data)
	return result

static func uniques(catalog: Dictionary) -> Array:
	var result: Array = []
	for data: AethelItemData in catalog.values():
		if data.rarity == AethelItemData.Rarity.UNIQUE: result.append(data)
	return result
