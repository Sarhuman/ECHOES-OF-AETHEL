class_name AethelAffixData
extends RefCounted
## Tabelas de afixos (prefixos e sufixos) no estilo ARPG clássico.
## "cats" filtra por categoria do equipamento; "slots" (opcional) restringe a slots exatos.

const CATEGORY: Dictionary = {
	"cape": "armor", "weapon": "weapon", "shield": "shield", "helm": "armor", "armor": "armor", "gloves": "armor",
	"boots": "armor", "belt": "armor", "ring": "jewelry", "amulet": "jewelry", "charm": "jewelry",
}

const AFFIXES: Array = [
	# --- prefixos ---
	{"id":"cortante","kind":"prefix","name":"Cortante","stat":"damage_pct","min":15,"max":30,"ilvl":1,"cats":["weapon"]},
	{"id":"brutal","kind":"prefix","name":"Brutal","stat":"damage_pct","min":31,"max":60,"ilvl":10,"cats":["weapon"]},
	{"id":"cruel","kind":"prefix","name":"Cruel","stat":"damage_add","min":2,"max":5,"ilvl":2,"cats":["weapon"]},
	{"id":"implacavel","kind":"prefix","name":"Implacável","stat":"damage_add","min":6,"max":12,"ilvl":10,"cats":["weapon"]},
	{"id":"resistente","kind":"prefix","name":"Resistente","stat":"defense_pct","min":15,"max":35,"ilvl":1,"cats":["armor","shield"]},
	{"id":"reforcado","kind":"prefix","name":"Reforçado","stat":"defense_pct","min":36,"max":70,"ilvl":9,"cats":["armor","shield"]},
	{"id":"robusto","kind":"prefix","name":"Robusto","stat":"vitality","min":2,"max":5,"ilvl":3,"cats":["armor","shield","jewelry"]},
	{"id":"vigoroso","kind":"prefix","name":"Vigoroso","stat":"life","min":8,"max":20,"ilvl":1,"cats":["armor","shield","jewelry"]},
	{"id":"etereo","kind":"prefix","name":"Etéreo","stat":"mana","min":8,"max":20,"ilvl":1,"cats":["armor","jewelry","weapon"]},
	{"id":"agil","kind":"prefix","name":"Ágil","stat":"dexterity","min":2,"max":5,"ilvl":3,"cats":["weapon","armor","jewelry"]},
	{"id":"rapido","kind":"prefix","name":"Rápido","stat":"move_speed","min":8,"max":15,"ilvl":4,"slots":["boots"]},
	{"id":"furioso","kind":"prefix","name":"Furioso","stat":"attack_speed","min":8,"max":15,"ilvl":5,"slots":["weapon","gloves"]},
	# --- sufixos ---
	{"id":"forca","kind":"suffix","name":"de Força","stat":"strength","min":2,"max":6,"ilvl":2,"cats":["weapon","armor","shield","jewelry"]},
	{"id":"energia","kind":"suffix","name":"de Energia","stat":"energy","min":2,"max":6,"ilvl":2,"cats":["armor","jewelry","weapon"]},
	{"id":"ferro","kind":"suffix","name":"de Ferro","stat":"defense_flat","min":3,"max":12,"ilvl":1,"cats":["armor","shield"]},
	{"id":"brasas","kind":"suffix","name":"de Brasas","stat":"damage_add","min":1,"max":4,"ilvl":1,"cats":["weapon","jewelry"]},
	{"id":"vida","kind":"suffix","name":"de Vida","stat":"life","min":10,"max":30,"ilvl":4,"cats":["armor","shield","jewelry"]},
	{"id":"eter","kind":"suffix","name":"de Éter","stat":"mana","min":10,"max":30,"ilvl":4,"cats":["armor","jewelry"]},
	{"id":"sorte","kind":"suffix","name":"de Sorte","stat":"find_magic","min":8,"max":25,"ilvl":5,"cats":["armor","jewelry"]},
	{"id":"fortaleza","kind":"suffix","name":"de Fortaleza","stat":"stamina","min":10,"max":30,"ilvl":3,"cats":["armor","jewelry"]},
	{"id":"vento","kind":"suffix","name":"de Vento","stat":"move_speed","min":6,"max":12,"ilvl":3,"slots":["boots"]},
	{"id":"furia","kind":"suffix","name":"de Fúria","stat":"attack_speed","min":6,"max":12,"ilvl":4,"slots":["weapon","gloves"]},
]

const RARE_FIRST: Array = ["Lamento","Presa","Sussurro","Ruína","Cicatriz","Guardião","Eco","Vigília","Rastro","Véu"]
const RARE_SECOND: Array = ["de Cinzas","do Nunca","de Vidro","de Cobre","do Atlas","das Portas","de Sal","do Sino","da Maré","dos Ausentes"]

const STAT_LABELS: Dictionary = {
	"damage_pct": "%+d%% Dano melhorado", "damage_add": "%+d de Dano", "defense_flat": "%+d Defesa",
	"defense_pct": "%+d%% Defesa melhorada", "life": "%+d Vida", "mana": "%+d Éter",
	"strength": "%+d Força", "dexterity": "%+d Destreza", "vitality": "%+d Vitalidade", "energy": "%+d Energia",
	"attack_speed": "%+d%% Velocidade de ataque", "move_speed": "%+d%% Velocidade de movimento",
	"find_magic": "%+d%% de chance de itens mágicos", "stamina": "%+d Fôlego",
}

static func category_of(slot: String) -> String:
	return str(CATEGORY.get(slot, ""))

static func eligible(kind: String, slot: String, ilvl: int) -> Array:
	var result: Array = []
	var cat: String = category_of(slot)
	for affix: Dictionary in AFFIXES:
		if affix["kind"] != kind or int(affix["ilvl"]) > ilvl: continue
		if affix.has("slots"):
			if slot in affix["slots"]: result.append(affix)
		elif cat in affix["cats"]:
			result.append(affix)
	return result

static func roll_affix(rng: RandomNumberGenerator, affix: Dictionary) -> Dictionary:
	return {"id": affix["id"], "kind": affix["kind"], "name": affix["name"], "stat": affix["stat"],
		"value": rng.randi_range(int(affix["min"]), int(affix["max"]))}

static func rare_name(rng: RandomNumberGenerator) -> String:
	return "%s %s" % [RARE_FIRST[rng.randi() % RARE_FIRST.size()], RARE_SECOND[rng.randi() % RARE_SECOND.size()]]

static func describe(stat: String, value: float) -> String:
	var template: String = str(STAT_LABELS.get(stat, stat + " %+d"))
	return template % int(value)
