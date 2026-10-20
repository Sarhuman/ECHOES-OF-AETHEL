class_name AethelEquipmentVisual
extends Node3D
## Visual-only equipment slot resolver. Attach as a child of AethelCharacterVisual.
## No inventory, stat or drop decisions are made here.

signal appearance_changed(slot: StringName, appearance_id: StringName, rarity_id: StringName)

const RARITIES: Array[StringName] = [&"common", &"magic", &"rare", &"epic", &"legendary"]
const SLOTS: Array[StringName] = [&"helmet", &"chest", &"gloves", &"boots", &"cape", &"weapon_main", &"offhand"]

@export var slot_root_path: NodePath = NodePath("..")
var _equipped: Dictionary = {}

func apply_equipment(slot: StringName, appearance_id: StringName, rarity_id: StringName) -> bool:
    if not SLOTS.has(slot) or not RARITIES.has(rarity_id):
        push_warning("EquipmentVisual: unknown slot or rarity")
        return false
    if String(appearance_id).is_empty():
        return clear_equipment(slot)
    var root := get_node_or_null(slot_root_path)
    if root == null:
        push_warning("EquipmentVisual: slot root missing")
        return false
    # Only pre-authored scene nodes are allowed; never load resource paths from loot payloads.
    var candidate := root.get_node_or_null(NodePath("EquipmentVisuals/%s/%s" % [slot, appearance_id]))
    if candidate == null or not candidate is Node3D:
        push_warning("EquipmentVisual: missing pre-authored appearance for %s" % slot)
        return false
    _hide_slot(root, slot)
    (candidate as Node3D).visible = true
    _equipped[slot] = {"appearance_id": appearance_id, "rarity_id": rarity_id}
    appearance_changed.emit(slot, appearance_id, rarity_id)
    return true

func clear_equipment(slot: StringName) -> bool:
    if not SLOTS.has(slot):
        return false
    var root := get_node_or_null(slot_root_path)
    if root == null:
        return false
    _hide_slot(root, slot)
    _equipped.erase(slot)
    appearance_changed.emit(slot, &"", &"common")
    return true

func snapshot() -> Dictionary:
    return _equipped.duplicate(true)

func _hide_slot(root: Node, slot: StringName) -> void:
    var group := root.get_node_or_null(NodePath("EquipmentVisuals/%s" % slot))
    if group == null:
        return
    for child in group.get_children():
        if child is Node3D:
            (child as Node3D).visible = false
