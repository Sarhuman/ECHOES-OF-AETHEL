class_name AethelLootGenerator
extends RefCounted
## Geração de loot: qualidade (normal/mágico/raro/único), afixos, ouro e poções.

enum MonsterRank { NORMAL, CHAMPION, UNIQUE }

var rng := RandomNumberGenerator.new()
var catalog: Dictionary = {}
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/loot_tables.json"))

func _init(item_catalog: Dictionary = {}, seed_value: int = -1) -> void:
	catalog = item_catalog
	if seed_value >= 0: rng.seed = seed_value
	else: rng.randomize()

func set_seed(seed_value: int) -> void:
	rng.seed = seed_value

func _quality_roll(rank: int, magic_find: float, min_quality: int) -> int:
	rank = clampi(rank, 0, 2)
	var scale: float = 1 + clampf(magic_find, 0, 1000) / 100
	var weights: Array[float] = []
	for weight: Variant in rules.rarity_weights: weights.append(float(weight))
	for index in range(1, 5): weights[index] *= scale * (1 + rank * float(rules.quality_rank_bonus))
	var total := 0.0
	for weight in weights: total += weight
	var roll := rng.randf() * total
	for index in weights.size():
		roll -= weights[index]
		if roll < 0: return maxi(index, clampi(min_quality, 0, 4))
	return 4

func roll_item(monster_level: int, rank: int = 0, magic_find: float = 0.0, min_quality: int = 0) -> AethelItemInstance:
	rank = clampi(rank, 0, 2)
	monster_level = clampi(monster_level, 1, 100)
	var quality: int = _quality_roll(rank, magic_find, min_quality)
	var bases: Array = []
	for data: AethelItemData in AethelItemCatalog.generic_bases(catalog):
		if data.item_level <= monster_level + 1: bases.append(data)
	if bases.is_empty(): return null
	var base: AethelItemData = bases[rng.randi() % bases.size()]
	var item := AethelItemInstance.new(base)
	item.quality = quality
	item.item_level = monster_level
	if quality == AethelItemData.Rarity.MAGIC:
		var wanted: int = 1 if rng.randf() < 0.6 else 2
		_add_affixes(item, wanted, true)
	elif quality >= AethelItemData.Rarity.RARE:
		_add_affixes(item, (3 if rng.randf() < 0.55 else 4) if quality == 2 else (4 if quality == 3 else 5), false)
		item.custom_name = AethelAffixData.rare_name(rng)
	return item

func _add_affixes(item: AethelItemInstance, count: int, mixed_kinds_limit: bool) -> void:
	var slot: String = item.definition.slot
	var used_stats: Dictionary = {}
	var prefixes: int = 0
	var suffixes: int = 0
	var attempts: int = 0
	while item.affixes.size() < count and attempts < 40:
		attempts += 1
		var kind: String = "prefix" if rng.randf() < 0.5 else "suffix"
		if kind == "prefix" and prefixes >= (1 if mixed_kinds_limit else 3): kind = "suffix"
		if kind == "suffix" and suffixes >= (1 if mixed_kinds_limit else 3): kind = "prefix"
		if mixed_kinds_limit and prefixes >= 1 and suffixes >= 1: break
		var options: Array = []
		for affix: Dictionary in AethelAffixData.eligible(kind, slot, item.item_level):
			if not used_stats.has(affix["stat"]): options.append(affix)
		if options.is_empty(): continue
		var picked: Dictionary = options[rng.randi() % options.size()]
		used_stats[picked["stat"]] = true
		item.affixes.append(AethelAffixData.roll_affix(rng, picked))
		if kind == "prefix": prefixes += 1
		else: suffixes += 1

func _potion_for_level(level: int, wants_life: bool) -> AethelItemInstance:
	var tier: String = "small" if level <= 3 else ("medium" if level <= 8 else "large")
	if level >= 4 and level <= 6 and rng.randf() < 0.4: tier = "small"
	var key: String = ("hp_" if wants_life else "mana_") + tier
	if not catalog.has(key): return null
	return AethelItemInstance.new(catalog[key])

func roll_gold(level: int, rank: int = 0) -> int:
	return rng.randi_range(int(rules.gold_range[0]),int(rules.gold_range[1])) * maxi(1,level) * int(rules.tables[["normal","champion","elite"][clampi(rank,0,2)]].gold_scale)

func roll_drops(monster_level: int, rank: int = 0, magic_find: float = 0.0) -> Array:
	return roll_rewards({"id":"legacy","level":monster_level,"rank":rank,"region":"map_02","difficulty":"test","table":["normal","champion","elite"][clampi(rank,0,2)],"magic_find":magic_find})

func validate_rules() -> bool:
	if rules.get("rarity_weights",[]).size() != 5: return false
	var total := 0.0
	for weight: Variant in rules.rarity_weights:
		if not (weight is int or weight is float) or not is_finite(float(weight)) or float(weight) < 0: return false
		total += float(weight)
	if total <= 0: return false
	for table: Dictionary in rules.tables.values():
		if table.rolls < 0 or table.rolls > 20 or table.guaranteed < 0 or table.guaranteed > 5: return false
		if table.chance < 0 or table.chance > 1 or table.gold_scale <= 0: return false
		var sum := 0.0
		for key: String in table.weights:
			if not key in ["gold","potion","equipment","material"] or float(table.weights[key]) < 0: return false
			sum += float(table.weights[key])
		if sum <= 0: return false
	for id: String in rules.materials:
		if not catalog.has(id) or catalog[id].kind != "material": return false
	return true

func roll_rewards(context: Dictionary) -> Array:
	var drops: Array = []
	if not validate_rules(): return drops
	if not rules.tables.has(str(context.get("table",""))) or not str(context.get("region","")) in rules.regions: return drops
	if not rules.difficulty_scales.has(str(context.get("difficulty",""))) or str(context.get("id","")).is_empty(): return drops
	var table: Dictionary = rules.tables[str(context.table)]
	var level: int = clampi(int(context.get("level",1)),1,100)
	var rank: int = clampi(int(context.get("rank",0)),0,2)
	var magic_find: float = clampf(float(context.get("magic_find",0)),0,1000)
	var reward_scale: float = clampf(float(context.get("reward_scale",1)),0.1,3.0) * float(rules.difficulty_scales[str(context.difficulty)])
	for i in int(table.guaranteed):
		var item := roll_item(level,rank,magic_find,int(table.minimum_quality))
		if item != null: drops.append({"kind":"item","item":item})
	var total := 0.0
	for weight: Variant in table.weights.values(): total += float(weight)
	for i in int(table.rolls):
		if rng.randf() >= float(table.chance): continue
		var roll := rng.randf() * total
		var category := ""
		for key: String in table.weights:
			roll -= float(table.weights[key])
			if roll < 0:
				category = key
				break
		match category:
			"gold": drops.append({"kind":"gold","amount":maxi(1,roundi(rng.randi_range(int(rules.gold_range[0]),int(rules.gold_range[1])) * level * float(table.gold_scale) * reward_scale))})
			"potion":
				var potion := _potion_for_level(level,rng.randf() < float(rules.potion_life_chance))
				if potion != null: drops.append({"kind":"potion","item":potion})
			"equipment":
				var item := roll_item(level,rank,magic_find,int(table.minimum_quality))
				if item != null: drops.append({"kind":"item","item":item})
			"material":
				var id: String = rules.materials[rng.randi_range(0,rules.materials.size()-1)]
				if catalog.has(id): drops.append({"kind":"item","item":AethelItemInstance.new(catalog[id])})
	for index in drops.size():
		if drops[index].has("item"): drops[index].item.instance_id = "loot-%s-%d-%d" % [str(context.id),rng.randi(),index]
	return drops
