extends Node3D
## NPC de produção inicial: silhueta original feita de primitivas Godot.
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
