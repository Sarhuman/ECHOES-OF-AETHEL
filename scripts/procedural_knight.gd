extends Node3D
## Visual autoral low-poly, sem FBX nem recursos externos.
## As partes articuladas se movem pela velocidade real do CharacterBody3D.
var elapsed: float = 0.0
var current_facing: Vector3 = Vector3(0, 0, -1)
var torso: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var cloak: Node3D
var is_moving: bool = false
var _action_remaining := 0.0
var _visual_state: StringName = &"idle"
var _death_tween: Tween

func _material(hex_code: String, metallic: float = 0.0) -> StandardMaterial3D:
 var result: StandardMaterial3D = StandardMaterial3D.new()
 result.albedo_color = Color(hex_code)
 result.metallic = metallic
 result.roughness = 0.58
 return result

func _box(parent: Node3D, local_pos: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
 var piece: MeshInstance3D = MeshInstance3D.new()
 var box_mesh: BoxMesh = BoxMesh.new()
 box_mesh.size = dimensions
 piece.mesh = box_mesh
 piece.material_override = material
 piece.position = local_pos
 parent.add_child(piece)
 return piece

func _sphere(parent: Node3D, local_pos: Vector3, radius: float, material: Material) -> MeshInstance3D:
 var piece: MeshInstance3D = MeshInstance3D.new()
 var sphere_mesh: SphereMesh = SphereMesh.new()
 sphere_mesh.radius = radius
 sphere_mesh.height = radius * 2.0
 piece.mesh = sphere_mesh
 piece.material_override = material
 piece.position = local_pos
 parent.add_child(piece)
 return piece

func _ready() -> void:
 var steel: Material = _material("667887", 0.65)
 var highlight: Material = _material("aab5c0", 0.7)
 var dark_steel: Material = _material("293341", 0.65)
 var blue: Material = _material("253c60")
 var gold: Material = _material("bd914c", 0.7)
 var leather: Material = _material("563c31")
 torso = Node3D.new()
 torso.name = "TorsoPivot"
 add_child(torso)
 _box(torso, Vector3(0, 1.16, 0), Vector3(0.61, 0.69, 0.35), blue)
 var chest := _box(torso, Vector3(0, 1.16, 0), Vector3(0.7, 0.72, 0.40), steel)
 _box(torso, Vector3(0, 1.2, -0.215), Vector3(0.48, 0.51, 0.065), blue)
 _box(torso, Vector3(0, 1.2, -0.255), Vector3(0.06, 0.45, 0.065), gold)
 _box(torso, Vector3(0, 1.19, -0.257), Vector3(0.28, 0.055, 0.07), gold)
 _box(torso, Vector3(0, 0.77, 0), Vector3(0.75, 0.13, 0.48), leather)
 _sphere(torso, Vector3(0, 1.77, 0), 0.25, dark_steel)
 var helmet := _box(torso, Vector3(0, 1.9, 0), Vector3(0.49, 0.23, 0.46), steel)
 _box(torso, Vector3(0, 1.75, -0.245), Vector3(0.42, 0.10, 0.065), highlight)
 var crest := _box(torso, Vector3(0, 2.025, -0.01), Vector3(0.09, 0.13, 0.48), gold)
 cloak = Node3D.new()
 cloak.name = "CloakPivot"
 cloak.position = Vector3(0,1.48,0.24)
 torso.add_child(cloak)
 _box(cloak, Vector3(0,-0.56,0.14), Vector3(0.79,1.17,0.13), blue)
 left_leg = _limb("LeftLeg", Vector3(-0.23,0.70,0), steel, 0.67, 0.23)
 right_leg = _limb("RightLeg", Vector3(0.23,0.70,0), steel, 0.67, 0.23)
 left_arm = _limb("LeftArm", Vector3(-0.49,1.49,0), steel, 0.67, 0.22)
 right_arm = _limb("RightArm", Vector3(0.49,1.49,0), steel, 0.67, 0.22)
 _sphere(left_arm, Vector3(0,-0.09,0), 0.20, highlight)
 _sphere(right_arm, Vector3(0,-0.09,0), 0.20, highlight)
 _make_axe(right_arm, leather, steel, highlight)
 _make_shield(left_arm, blue, gold, highlight)
 var adapter := AethelEquipmentVisual.new()
 adapter.name = "EquipmentAdapter"
 add_child(adapter)
 adapter.register_placeholder(&"chest", &"chest", [chest])
 crest.set_meta("rune_trim", true)
 adapter.register_placeholder(&"helmet", &"helmet", [helmet, crest])
 adapter.register_placeholder(&"cape", &"cape", [cloak])
 var gauntlets: Array = []
 for arm in [left_arm, right_arm]:
  gauntlets.append(_box(arm, Vector3(0,-0.58,0), Vector3(0.29,0.25,0.28), steel))
 adapter.register_placeholder(&"gloves", &"gloves", gauntlets)
 var boots: Array = []
 for leg in [left_leg, right_leg]:
  boots.append(_box(leg, Vector3(0,-0.59,-0.09), Vector3(0.34,0.24,0.40), dark_steel))
 adapter.register_placeholder(&"boots", &"boots", boots)
 adapter.register_placeholder(&"weapon_main", &"axe", [right_arm.get_node("Axe")])
 adapter.register_placeholder(&"offhand", &"shield", [left_arm.get_node("Shield")])
 var sword := _box(right_arm, Vector3(0,-0.95,-0.12), Vector3(0.12,1.18,0.10), highlight)
 adapter.register_placeholder(&"weapon_main", &"sword", [sword])
 var mace_handle := _box(right_arm, Vector3(0,-0.92,-0.12), Vector3(0.09,0.9,0.09), leather)
 var mace_head := _sphere(right_arm, Vector3(0,-1.36,-0.12), 0.23, steel)
 adapter.register_placeholder(&"weapon_main", &"mace", [mace_handle, mace_head])

func _limb(label_name: String, pivot: Vector3, surface: Material, length: float, thickness: float) -> Node3D:
 var part: Node3D = Node3D.new()
 part.name = label_name
 part.position = pivot
 torso.add_child(part)
 _box(part, Vector3(0,-length * 0.5,0), Vector3(thickness,length,thickness), surface)
 _box(part, Vector3(0,-length + 0.065,-0.065), Vector3(thickness + 0.08,0.18,thickness + 0.16), surface)
 return part

func _make_axe(hand: Node3D, handle_mat: Material, blade_mat: Material, edge_mat: Material) -> void:
 var weapon: Node3D = Node3D.new()
 weapon.name = "Axe"
 hand.add_child(weapon)
 weapon.position = Vector3(0,-0.62,-0.12)
 _box(weapon, Vector3(0,-0.07,0), Vector3(0.075,0.94,0.075), handle_mat)
 _box(weapon, Vector3(0.21,0.29,0), Vector3(0.48,0.35,0.15), blade_mat)
 _box(weapon, Vector3(0.46,0.27,0), Vector3(0.08,0.48,0.10), edge_mat)
 _box(weapon, Vector3(0,0.30,0), Vector3(0.14,0.19,0.14), blade_mat)

func _make_shield(hand: Node3D, base_mat: Material, edge_mat: Material, emblem_mat: Material) -> void:
 var shield: Node3D = Node3D.new()
 shield.name = "Shield"
 hand.add_child(shield)
 shield.position = Vector3(-0.15,-0.51,-0.28)
 _box(shield, Vector3.ZERO, Vector3(0.65,0.78,0.13), edge_mat)
 _box(shield, Vector3(0,0,-0.085), Vector3(0.54,0.65,0.07), base_mat)
 _box(shield, Vector3(0,0,-0.14), Vector3(0.065,0.48,0.025), emblem_mat)
 _box(shield, Vector3(0,0.05,-0.14), Vector3(0.31,0.065,0.025), emblem_mat)

func set_motion(world_velocity: Vector3, look_direction: Vector3, delta: float) -> void:
 if _visual_state == &"death": return
 _action_remaining = maxf(0, _action_remaining - delta)
 is_moving = Vector2(world_velocity.x,world_velocity.z).length() > 0.2
 if look_direction.length_squared() > 0.001:
  current_facing = look_direction.normalized()
  rotation.y = atan2(-current_facing.x, -current_facing.z)
 if _action_remaining > 0:
  return
 if is_moving:
  elapsed += delta * 10.0
  var pace: float = sin(elapsed) * 0.58
  left_leg.rotation.x = pace
  right_leg.rotation.x = -pace
  left_arm.rotation.x = -pace * 0.60
  right_arm.rotation.x = pace * 0.60
  torso.position.y = absf(sin(elapsed)) * 0.055
  cloak.rotation.x = 0.10 + sin(elapsed * 0.7) * 0.06
 else:
  elapsed += delta * 1.3
  left_leg.rotation.x = lerpf(left_leg.rotation.x,0.0, minf(1.0, delta * 9.0))
  right_leg.rotation.x = lerpf(right_leg.rotation.x,0.0, minf(1.0, delta * 9.0))
  left_arm.rotation.x = lerpf(left_arm.rotation.x,0.0, minf(1.0, delta * 9.0))
  right_arm.rotation.x = lerpf(right_arm.rotation.x,0.0, minf(1.0, delta * 9.0))
  torso.position.y = sin(elapsed) * 0.02
  cloak.rotation.x = 0.025

func play_attack() -> void:
 if not is_instance_valid(right_arm):
  return
 var tween: Tween = create_tween()
 tween.tween_property(right_arm,"rotation:x", -1.25, 0.11)
 tween.tween_property(right_arm,"rotation:x", 0.35, 0.16)
 tween.tween_property(right_arm,"rotation:x", 0.0, 0.15)

func reset_after_load() -> void:
 # Explicit revival entry point; ordinary animation requests cannot leave death.
 if _death_tween != null:
  _death_tween.kill()
  _death_tween = null
 _visual_state = &"idle"
 _action_remaining = 0.0
 is_moving = false
 torso.rotation = Vector3.ZERO
 left_arm.rotation = Vector3.ZERO
 right_arm.rotation = Vector3.ZERO
 left_leg.rotation = Vector3.ZERO
 right_leg.rotation = Vector3.ZERO
 set_guard_active(false)

func play_state(state: StringName) -> void:
 if _visual_state == &"death": return
 _visual_state = state
 _action_remaining = 0.45
 match state:
  &"attack_1", &"attack_2":
   play_attack()
   if state == &"attack_2": torso.rotation.y = 0.15
  &"block": left_arm.rotation.x = -1.1
  &"dodge": torso.rotation.x = -0.3
  &"hit": torso.rotation.z = 0.15
  &"death":
   _death_tween = create_tween()
   _death_tween.tween_property(torso, "rotation:z", 1.5, 0.35)
 if state != &"death":
  var recovery := create_tween()
  recovery.tween_interval(0.3)
  recovery.tween_property(torso, "rotation", Vector3.ZERO, 0.12)

var guard_ring: MeshInstance3D
func set_guard_active(active: bool) -> void:
 if guard_ring == null:
  guard_ring = MeshInstance3D.new()
  guard_ring.name = "GuardIndicator"
  var ring := TorusMesh.new()
  ring.inner_radius = 0.60
  ring.outer_radius = 0.66
  guard_ring.mesh = ring
  guard_ring.position.y = 0.08
  var material := StandardMaterial3D.new()
  material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  material.albedo_color = Color("c5a963")
  guard_ring.material_override = material
  add_child(guard_ring)
 guard_ring.visible = active
