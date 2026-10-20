class_name AethelLootGenerator
extends RefCounted
## Geração de loot: qualidade (normal/mágico/raro/único), afixos, ouro e poções.

enum MonsterRank { NORMAL, CHAMPION, UNIQUE }

var rng := RandomNumberGenerator.new()
var catalog: Dictionary = {}

func _init(item_catalog: Dictionary = {}, seed_value: int = -1) -> void:
	catalog = item_catalog
	if seed_value >= 0: rng.seed = seed_value
	else: rng.randomize()

func set_seed(seed_value: int) -> void:
	rng.seed = seed_value

func _quality_roll(rank: int, magic_find: float, min_quality: int) -> int:
	rank = clampi(rank, 0, 2)
	var scale: float = 1 + clampf(magic_find, 0, 1000) / 100
	var weights: Array[float] = [55, 27, 12, 5, 1]
	for index in range(1, 5): weights[index] *= scale * (1 + rank * 0.8)
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
	if quality == AethelItemData.Rarity.UNIQUE:
		var pool: Array = []
		for data: AethelItemData in AethelItemCatalog.uniques(catalog):
			if data.item_level <= monster_level + 2: pool.append(data)
		if pool.is_empty(): pass # sem unico autoral elegivel: lendario gerado a partir de base
		else:
			var unique_def: AethelItemData = pool[rng.randi() % pool.size()]
			var unique_item := AethelItemInstance.new(unique_def)
			unique_item.quality = AethelItemData.Rarity.UNIQUE
			unique_item.item_level = monster_level
			return unique_item
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
	return rng.randi_range(4, 10) * maxi(1, level) * [1, 3, 8][rank]

func roll_drops(monster_level: int, rank: int = 0, magic_find: float = 0.0) -> Array:
	## Retorna [{kind:"gold",amount}, {kind:"potion",item}, {kind:"item",item}]
	rank = clampi(rank, 0, 2)
	monster_level = clampi(monster_level, 1, 100)
	var drops: Array = []
	var rolls: int = [1, 2, 4][rank]
	if rank >= MonsterRank.CHAMPION:
		var guaranteed: int = 1 if rank == MonsterRank.CHAMPION else 3
		for i in guaranteed:
			var guaranteed_item: AethelItemInstance = roll_item(monster_level, rank, magic_find, AethelItemData.Rarity.MAGIC)
			if guaranteed_item != null: drops.append({"kind": "item", "item": guaranteed_item})
	for i in rolls:
		if rng.randf() >= (0.55 if rank == MonsterRank.NORMAL else 0.75): continue
		var roll: float = rng.randf()
		if roll < 0.50:
			drops.append({"kind": "gold", "amount": roll_gold(monster_level, rank)})
		elif roll < 0.72:
			var potion: AethelItemInstance = _potion_for_level(monster_level, rng.randf() < 0.6)
			if potion != null: drops.append({"kind": "potion", "item": potion})
		else:
			var item: AethelItemInstance = roll_item(monster_level, rank, magic_find)
			if item != null: drops.append({"kind": "item", "item": item})
	return drops
