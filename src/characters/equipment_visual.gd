class_name AethelEquipmentVisual
extends Node3D
## Visual-only equipment slot resolver. Attach as a child of AethelCharacterVisual.
## No inventory, stat or drop decisions are made here.

signal appearance_changed(slot: StringName, appearance_id: StringName, rarity_id: StringName)

const RARITIES: Array[StringName] = [&"common", &"magic", &"rare", &"epic", &"legendary"]
const SLOTS: Array[StringName] = [&"helmet", &"chest", &"gloves", &"boots", &"cape", &"weapon_main", &"offhand"]

@export var slot_root_path: NodePath = NodePath("..")
@export var preserve_authored_materials := false
var _equipped: Dictionary = {}

func apply_equipment(slot: StringName, appearance_id: StringName, rarity_id: StringName) -> bool:
    if not SLOTS.has(slot) or not RARITIES.has(rarity_id):
        push_warning("EquipmentVisual: unknown slot or rarity")
        return false
    if String(appearance_id).is_empty():
        return clear_equipment(slot)
    if not String(appearance_id).is_valid_identifier():
        return false
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
    _set_targets(candidate, true, rarity_id)
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
            _set_targets(child, false, &"common")

func register_placeholder(slot: StringName, appearance_id: StringName, targets: Array) -> void:
    # Called only by authored model code. Loot can only select an existing identifier.
    var root := get_node_or_null(slot_root_path)
    if root == null or not SLOTS.has(slot) or not String(appearance_id).is_valid_identifier(): return
    var library := root.get_node_or_null("EquipmentVisuals")
    if library == null:
        library = Node3D.new()
        library.name = "EquipmentVisuals"
        root.add_child(library)
    var group := library.get_node_or_null(NodePath(String(slot)))
    if group == null:
        group = Node3D.new()
        group.name = slot
        library.add_child(group)
    var entry := Node3D.new()
    entry.name = appearance_id
    entry.set_meta("placeholder_targets", targets)
    group.add_child(entry)
    entry.hide()
    _set_targets(entry, false, &"common")

func _set_targets(entry: Node, enabled: bool, rarity: StringName) -> void:
    var accents: Array[Color] = [Color("7f8c94"), Color("7c95b8"), Color("bda772"), Color("9172ab"), Color("c19a52")]
    var index := RARITIES.find(rarity)
    for target: Node3D in entry.get_meta("placeholder_targets", []):
        if not is_instance_valid(target): continue
        target.visible = enabled
        if enabled and target is MeshInstance3D and not preserve_authored_materials:
            var mesh := target as MeshInstance3D
            if not mesh.has_meta("base_material"):
                mesh.set_meta("base_material", mesh.material_override)
            var base: Material = mesh.get_meta("base_material")
            if base is StandardMaterial3D:
                var material := base.duplicate() as StandardMaterial3D
                material.albedo_color = accents[maxi(0, index)]
                # Small marked trim pieces only; never glow the entire suit.
                if target.has_meta("rune_trim") and index >= 3:
                    material.emission_enabled = true
                    material.emission = accents[index]
                    material.emission_energy_multiplier = 0.35
                mesh.material_override = material
