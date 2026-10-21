class_name AethelItemData
extends Resource

enum Rarity { NORMAL = 0, COMMON = 0, MAGIC = 1, RARE = 2, EPIC = 3, LEGENDARY = 4, UNIQUE = 4 }
@export var appearance_id: StringName
@export var allowed_classes: Array[StringName] = []
@export var item_id: StringName
@export var display_name: String = ""
@export var base_name: String = ""        # nome do tipo-base (para únicos e itens legados)
@export_multiline var description: String = ""
@export var icon: Texture2D
@export_range(1, 99, 1) var max_stack: int = 1
@export_range(1, 2, 1) var hands: int = 1
# Reserved authoring tags only; no set/socket/Sigil mechanics are enabled.
@export var future_feature_tags: PackedStringArray = []
@export_range(1, 10, 1) var width: int = 1
@export_range(1, 4, 1) var height: int = 1
@export var rarity: Rarity = Rarity.NORMAL
@export_range(1, 100, 1) var item_level: int = 1
@export var base_value: int = 0
@export var modifiers: Dictionary = {}    # legado: bonus_hp, bonus_ether, bonus_damage
@export var slot: String = ""             # weapon, shield, helm, armor, gloves, boots, belt, ring, amulet, charm
@export var kind: String = "equipment"    # equipment | potion
@export var gender: String = "m"
@export var damage_min: int = 0
@export var damage_max: int = 0
@export var defense: int = 0
@export var block_chance: int = 0
@export var req_level: int = 0
@export var req_strength: int = 0
@export var req_dexterity: int = 0
@export var heal_life: int = 0
@export var heal_mana: int = 0
var unique_affixes: Array = []            # [{stat, value}] fixos de itens únicos

func is_potion() -> bool:
	return kind == "potion"

func is_generic_base() -> bool:
	return kind == "equipment" and rarity == Rarity.NORMAL and modifiers.is_empty() and slot != "charm"
