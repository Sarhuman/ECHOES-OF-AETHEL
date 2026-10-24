class_name AethelItemInstance
extends RefCounted

const LEGACY_STATS: Dictionary = {"bonus_hp": "life", "bonus_ether": "mana", "bonus_damage": "damage_add"}

var instance_id: String
var definition: AethelItemData
var quality: int = -1           # -1 = usa a qualidade da definição
var affixes: Array = []         # [{id, kind, name, stat, value}]
var custom_name: String = ""    # nome gerado de itens raros
var item_level: int = 1
var quantity: int = 1

func _init(data: AethelItemData, uid: String = "") -> void:
	definition = data
	instance_id = uid if not uid.is_empty() else _new_id()
	if data != null: item_level = data.item_level

static func _new_id() -> String:
	return "%s-%d" % [str(Time.get_ticks_usec()), randi_range(100000, 999999)]

func get_quality() -> int:
	if quality >= 0: return quality
	return int(definition.rarity) if definition != null else 0

func base_display_name() -> String:
	if definition == null: return ""
	return definition.base_name if not definition.base_name.is_empty() else definition.display_name

func display_name() -> String:
	if definition == null: return ""
	match get_quality():
		AethelItemData.Rarity.UNIQUE:
			return custom_name if not custom_name.is_empty() else definition.display_name
		AethelItemData.Rarity.EPIC, AethelItemData.Rarity.RARE:
			return custom_name if not custom_name.is_empty() else base_display_name()
		AethelItemData.Rarity.MAGIC:
			var text: String = base_display_name()
			var prefix: String = ""
			var suffix: String = ""
			for affix: Dictionary in affixes:
				if affix.get("kind", "") == "prefix" and prefix.is_empty(): prefix = str(affix.get("name", ""))
				elif affix.get("kind", "") == "suffix" and suffix.is_empty(): suffix = str(affix.get("name", ""))
			if not prefix.is_empty(): text += " " + prefix
			if not suffix.is_empty(): text += " " + suffix
			return text
	return definition.display_name

func all_modifiers() -> Array:
	## Lista unificada [{stat, value}] de afixos gerados, fixos de únicos e bônus legados.
	var rows: Array = []
	for affix: Dictionary in affixes: rows.append({"stat": str(affix["stat"]), "value": float(affix["value"])})
	if definition != null:
		for fixed: Dictionary in definition.unique_affixes: rows.append({"stat": str(fixed["stat"]), "value": float(fixed["value"])})
		for key: String in definition.modifiers:
			if LEGACY_STATS.has(key) and float(definition.modifiers[key]) != 0.0:
				rows.append({"stat": LEGACY_STATS[key], "value": float(definition.modifiers[key])})
	return rows

func stat_total(stat: String) -> float:
	var total: float = 0.0
	for row: Dictionary in all_modifiers():
		if row["stat"] == stat: total += float(row["value"])
	return total

func defense_value() -> int:
	if definition == null: return 0
	return roundi(float(definition.defense) * (1.0 + stat_total("defense_pct") / 100.0)) + int(stat_total("defense_flat"))

func comparison_values() -> Dictionary:
	var values := {"Dano base médio":(definition.damage_min+definition.damage_max)/2.0,"Defesa":float(defense_value()),"Bloqueio base (%)":float(definition.block_chance)}
	var names := {"strength":"Força","dexterity":"Destreza","vitality":"Vitalidade","energy":"Energia","life":"Vida","mana":"Éter","damage_pct":"Dano (%)","damage_add":"Dano adicional","attack_speed":"Velocidade de ataque (%)","move_speed":"Movimento (%)","find_magic":"Descoberta mágica (%)","stamina":"Fôlego"}
	for row: Dictionary in all_modifiers():
		var label: String = names.get(row["stat"],str(row["stat"]))
		values[label] = float(values.get(label,0)) + float(row["value"])
	return values

func gold_value() -> int:
	if definition == null: return 0
	var mult: float = 1.0 + 0.55 * float(affixes.size()) + (3.0 if get_quality() == AethelItemData.Rarity.UNIQUE else 0.0)
	return maxi(1, roundi(float(definition.base_value) * mult))

func serialize() -> Dictionary:
	return {"id": instance_id, "item_id": String(definition.item_id), "quality": quality,
		"name": custom_name, "ilvl": item_level, "quantity": quantity, "affixes": affixes.duplicate(true)}

func stacks_with(other: AethelItemInstance) -> bool:
	if other == null or definition.max_stack <= 1 or definition.item_id != other.definition.item_id: return false
	var a := serialize()
	var b := other.serialize()
	for field in ["id","quantity","x","y"]:
		a.erase(field)
		b.erase(field)
	return a == b

static func from_dict(data: Dictionary, catalog: Dictionary) -> AethelItemInstance:
	for field in ["id","item_id","name"]:
		if data.has(field) and not data[field] is String: return null
	for field: String in ["quality", "ilvl", "x", "y", "quantity"]:
		if data.has(field) and not (data[field] is int or data[field] is float): return null
		if data.has(field) and (not is_finite(float(data[field])) or float(data[field]) != floorf(float(data[field]))): return null
	var key: String = str(data.get("item_id", ""))
	if not catalog.has(key): return null
	var instance := AethelItemInstance.new(catalog[key], str(data.get("id", "")))
	instance.quantity = int(data.get("quantity",1))
	if instance.quantity < 1 or instance.quantity > instance.definition.max_stack: return null
	instance.quality = clampi(int(data.get("quality", -1)), -1, 4)
	instance.custom_name = str(data.get("name", ""))
	instance.item_level = clampi(int(data.get("ilvl", instance.item_level)), 1, 100)
	var restored: Array = []
	var raw_affixes: Variant = data.get("affixes", [])
	if not raw_affixes is Array: return null
	var stats_seen: Dictionary = {}
	for raw: Variant in raw_affixes:
		if not raw is Dictionary: continue
		if not (raw.get("value", 0) is int or raw.get("value", 0) is float): continue
		for authored: Dictionary in AethelAffixData.AFFIXES:
			if str(raw.get("id", "")) != str(authored["id"]): continue
			var eligible: Array = AethelAffixData.eligible(str(authored["kind"]), instance.definition.slot, instance.item_level)
			if not authored in eligible or stats_seen.has(authored["stat"]) or restored.size() >= 5: break
			stats_seen[authored["stat"]] = true
			restored.append({"id": authored["id"], "kind": authored["kind"], "name": authored["name"],
				"stat": authored["stat"], "value": clampi(int(raw.get("value", 0)), int(authored["min"]), int(authored["max"]))})
			break
	instance.affixes = restored
	return instance
