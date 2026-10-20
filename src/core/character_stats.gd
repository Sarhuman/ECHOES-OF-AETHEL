class_name AethelCharacterStats
extends RefCounted
## Atributos do personagem (classe Bastião). 5 pontos por nível.

const POINTS_PER_LEVEL: int = 5
const BASE: Dictionary = {"strength": 30, "dexterity": 20, "vitality": 25, "energy": 10}
const ATTRIBUTES: Array = ["strength", "dexterity", "vitality", "energy"]

var strength: int = 30
var dexterity: int = 20
var vitality: int = 25
var energy: int = 10
var unspent: int = 0

func get_attr(name: String) -> int:
	return int(get(name))

func spend(name: String) -> bool:
	if unspent < 1 or not (name in ATTRIBUTES): return false
	set(name, get_attr(name) + 1)
	unspent -= 1
	return true

func serialize() -> Dictionary:
	return {"strength": strength, "dexterity": dexterity, "vitality": vitality, "energy": energy, "unspent": unspent}

func restore(data: Dictionary) -> void:
	strength = clampi(int(data.get("strength", BASE["strength"])), 1, 999)
	dexterity = clampi(int(data.get("dexterity", BASE["dexterity"])), 1, 999)
	vitality = clampi(int(data.get("vitality", BASE["vitality"])), 1, 999)
	energy = clampi(int(data.get("energy", BASE["energy"])), 1, 999)
	unspent = clampi(int(data.get("unspent", 0)), 0, 999)
