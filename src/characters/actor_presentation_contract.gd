class_name AethelActorPresentationContract
extends Resource
## Metres, Y-up, origin at feet. Visual swaps never change actor physics.
@export var capsule_radius := 0.32
@export var capsule_height := 1.6
@export var visual_scale := 1.0
@export var feet := Vector3.ZERO
@export var weapon := Vector3(0.45,1.0,-0.2)
@export var label := Vector3(0,2.4,0)
@export var health := Vector3(0,2.15,0)

static func profile(category: String, rank: int = 0) -> Dictionary:
	var resource: Resource=load("res://data/characters/%s_contract.tres"%category)
	var factor: float = resource.visual_scale*([1.0,1.2,1.45][clampi(rank,0,2)] if category=="enemy" else 1.0)
	return {"category":category,"scale":factor,"radius":resource.capsule_radius*factor,"height":resource.capsule_height*factor,"feet":resource.feet,"weapon":resource.weapon*factor,"label":resource.label*factor,"health":resource.health*factor}

static func install(actor: Node3D, category: String, rank: int = 0) -> Dictionary:
	var data := profile(category,rank)
	actor.set_meta("presentation_contract",data)
	var anchors := Node3D.new()
	anchors.name="PresentationAnchors"
	actor.add_child(anchors)
	for id: String in ["feet","weapon","label","health"]:
		var marker := Marker3D.new()
		marker.name=id
		marker.position=data[id]
		anchors.add_child(marker)
	return data
