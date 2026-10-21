extends Node3D
## NPC de produção inicial: silhueta original feita de primitivas Godot.
@export var role: StringName = &"cartographer"
var motion_phase: float = 0.0
var figure: Node3D

func _mat(code: String) -> StandardMaterial3D:
 var mat: StandardMaterial3D = StandardMaterial3D.new()
 mat.albedo_color = Color(code)
 mat.roughness = 0.87
 return mat

func _part(parent: Node3D, where: Vector3, size: Vector3, color: String) -> void:
 var piece: MeshInstance3D = MeshInstance3D.new()
 var mesh: BoxMesh = BoxMesh.new()
 mesh.size = size
 piece.mesh = mesh
 piece.position = where
 piece.material_override = _mat(color)
 parent.add_child(piece)

func _ready() -> void:
 figure = Node3D.new()
 add_child(figure)
 if role == &"blacksmith":
  _build_blacksmith()
  return
 _part(figure,Vector3(0,0.92,0),Vector3(0.73,1.25,0.44),"354d65")
 _part(figure,Vector3(0,1.45,-0.22),Vector3(0.60,0.19,0.11),"bb8b58")
 _part(figure,Vector3(0,1.72,0),Vector3(0.42,0.44,0.41),"b69279")
 _part(figure,Vector3(0,1.92,0.05),Vector3(0.53,0.22,0.49),"34252b")
 _part(figure,Vector3(-0.48,1.18,0),Vector3(0.22,0.70,0.28),"26384c")
 _part(figure,Vector3(0.48,1.18,0),Vector3(0.22,0.70,0.28),"26384c")
 _part(figure,Vector3(0,0.48,0.21),Vector3(0.75,0.65,0.21),"253045")
 _part(figure,Vector3(0,1.08,-0.29),Vector3(0.40,0.28,0.035),"6c91b0")

func _process(delta: float) -> void:
 motion_phase += delta
 figure.position.y = sin(motion_phase * 1.8) * 0.025

func _build_blacksmith() -> void:
 # Authored placeholder: separate work clothes, apron, skin, hair and hammer.
 _part(figure,Vector3(0,1.13,0),Vector3(0.72,0.70,0.40),"766147")
 _part(figure,Vector3(-0.23,0.43,0),Vector3(0.27,0.66,0.32),"32363d")
 _part(figure,Vector3(0.23,0.43,0),Vector3(0.27,0.66,0.32),"32363d")
 _part(figure,Vector3(-0.23,0.10,-0.08),Vector3(0.32,0.20,0.48),"382d27")
 _part(figure,Vector3(0.23,0.10,-0.08),Vector3(0.32,0.20,0.48),"382d27")
 var head := MeshInstance3D.new()
 var sphere := SphereMesh.new()
 sphere.radius = 0.23
 sphere.height = 0.47
 head.mesh = sphere
 head.position.y = 1.73
 head.material_override = _mat("c39774")
 figure.add_child(head)
 _part(figure,Vector3(0,1.94,0.04),Vector3(0.42,0.12,0.40),"48382d")
 _part(figure,Vector3(0,1.63,-0.20),Vector3(0.35,0.20,0.13),"554034")
 _part(figure,Vector3(-0.49,1.15,0),Vector3(0.25,0.62,0.29),"b58a69")
 _part(figure,Vector3(0.49,1.15,0),Vector3(0.25,0.62,0.29),"b58a69")
 var apron := Node3D.new()
 apron.name = "LeatherApron"
 figure.add_child(apron)
 _part(apron,Vector3(0,0.99,-0.23),Vector3(0.59,0.89,0.08),"5c3929")
 _part(apron,Vector3(0,1.43,-0.23),Vector3(0.36,0.19,0.06),"8a623d")
 _part(apron,Vector3(0,1.05,-0.28),Vector3(0.60,0.075,0.05),"b79461")
 _part(apron,Vector3(0,0.84,-0.29),Vector3(0.30,0.22,0.04),"754d31")
 _part(figure,Vector3(0.49,0.72,-0.15),Vector3(0.07,0.62,0.07),"795337")
 _part(figure,Vector3(0.49,0.43,-0.15),Vector3(0.40,0.19,0.22),"8a8f92")

 # Protective gloves, worn apron stitching, iron shoulder guard and bronze buckle.
 _part(figure,Vector3(-0.49,0.88,-0.02),Vector3(0.28,0.28,0.33),"41352a")
 _part(figure,Vector3(0.49,0.88,-0.02),Vector3(0.28,0.28,0.33),"41352a")
 _part(figure,Vector3(-0.40,1.47,0),Vector3(0.42,0.13,0.48),"50585a")
 for x in [-0.24,0.24]:
  _part(apron,Vector3(x,0.99,-0.281),Vector3(0.015,0.7,0.012),"ac8a62")
 _part(apron,Vector3(0,1.05,-0.32),Vector3(0.12,0.10,0.025),"9b8559")
