extends Node3D
## Test/integration wrapper. No damage, statistics, input, movement or physics.
@export var main_bone := "hand_r"
@export var offhand_bone := "hand_l"
var skeleton: Skeleton3D
func _ready() -> void:
	for node in find_children("*","Skeleton3D",true,false): skeleton=node;break
	if skeleton==null: return
	for pair: Array in [["SocketMain",main_bone],["SocketOffhand",offhand_bone]]:
		if skeleton.find_bone(pair[1])<0: continue
		var socket:=BoneAttachment3D.new()
		socket.name=pair[0]
		socket.bone_name=pair[1]
		skeleton.add_child(socket)
	var adapter:=AethelEquipmentVisual.new()
	adapter.name="EquipmentAdapter"
	adapter.preserve_authored_materials=true
	add_child(adapter)
	for entry: Array in [["helmet","helmet","Helmet"],["chest","chest","Chest"],["gloves","gloves","Gloves"],["boots","boots","Boots"],["cape","cape","Cape"],["weapon_main","sword","Sword"],["weapon_main","axe","Axe"],["weapon_main","mace","Mace"],["offhand","shield","Shield"]]:
		var target:=find_child(entry[2],true,false)
		if target is Node3D: adapter.register_placeholder(StringName(entry[0]),StringName(entry[1]),[target])
	var player:=find_child("AnimationPlayer",true,false) as AnimationPlayer
	if player!=null:
		for id: StringName in player.get_animation_list():
			player.get_animation(id).loop_mode=Animation.LOOP_LINEAR if id in [&"idle",&"walk",&"run",&"block"] else Animation.LOOP_NONE
