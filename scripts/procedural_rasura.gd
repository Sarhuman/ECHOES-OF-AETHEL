extends Node3D
var presentation_rank := 0
var phase: float = 0.0
var body: Node3D

func _ready() -> void:
 body = Node3D.new()
 add_child(body)
 var dark: StandardMaterial3D = StandardMaterial3D.new()
 dark.albedo_color = Color("352244")
 var glow: StandardMaterial3D = StandardMaterial3D.new()
 glow.albedo_color = [Color("9675da"),Color("829cff"),Color("e0b66b")][presentation_rank]
 glow.emission_enabled = true
 glow.emission = Color("453179")
 glow.emission_energy_multiplier = 0.9
 var cloak: MeshInstance3D = MeshInstance3D.new()
 var cloak_mesh: CylinderMesh = CylinderMesh.new()
 cloak_mesh.top_radius = 0.22
 cloak_mesh.bottom_radius = 0.48
 cloak_mesh.height = 1.24
 cloak.mesh = cloak_mesh
 cloak.position.y = 0.67
 cloak.material_override = dark
 body.add_child(cloak)
 var mask: MeshInstance3D = MeshInstance3D.new()
 var mask_mesh: SphereMesh = SphereMesh.new()
 mask_mesh.radius = 0.23
 mask_mesh.height = 0.46
 mask.mesh = mask_mesh
 mask.position.y = 1.47
 mask.material_override = glow
 body.add_child(mask)
 for side in [-1,1]:
  var claw: MeshInstance3D = MeshInstance3D.new()
  var claw_mesh: BoxMesh = BoxMesh.new()
  claw_mesh.size = Vector3(0.12,0.65,0.15)
  claw.mesh = claw_mesh
  claw.position = Vector3(float(side)*0.44,0.87,-0.17)
  claw.rotation.z = float(side) * 0.37
  claw.material_override = glow
  body.add_child(claw)

 # Rank silhouette belongs only to this replaceable visual.
 for side in [-1,1] if presentation_rank>0 else []:
  var crest := MeshInstance3D.new()
  var shape := BoxMesh.new()
  shape.size=Vector3(0.18,0.5 if presentation_rank==1 else 0.8,0.2)
  crest.mesh=shape
  crest.position=Vector3(side*0.34,1.5,-0.02)
  crest.rotation.z=side*0.5
  crest.material_override=glow
  body.add_child(crest)

func _process(delta: float) -> void:
 phase += delta
 body.position.y = sin(phase * 3.1) * 0.10
 body.rotation.y = sin(phase * 0.6) * 0.12
