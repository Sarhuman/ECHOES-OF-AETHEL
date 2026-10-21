extends SceneTree
func _initialize() -> void: call_deferred("run")
func measure(actor: Node3D) -> Dictionary:
	var bounds:=AABB()
	var valid:=false
	for mesh: MeshInstance3D in actor.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh==null: continue
		var box: AABB=(actor.global_transform.affine_inverse()*mesh.global_transform)*mesh.mesh.get_aabb()
		bounds=bounds.merge(box) if valid else box
		valid=true
	return {"height":bounds.size.y,"width":bounds.size.x,"depth":bounds.size.z,"lowest_y":bounds.position.y,"scope":"all mesh variants including hidden equipment, current rest/idle pose; not canonical dimensions"}
func run() -> void:
	Engine.set_meta("aethel_new_game",true)
	var world: Node3D=load("res://scenes/main.tscn").instantiate();root.add_child(world)
	await physics_frame;await process_frame
	var report: Dictionary={"bastion":measure(world.player),"maera":measure(world.npc),"doma":measure(world.merchant)}
	for rank_value in 3:
		var enemy: Node3D=world._spawn_enemy(Vector3(-6+rank_value*3,0,6),1,rank_value)
		report[["rasura","champion","elite"][rank_value]]=measure(enemy)
	var file:=FileAccess.open("res://docs/evidence/fase27-2-scale.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "));file.close()
	print("SCALE AUDIT: "+JSON.stringify(report))
	world.queue_free();await process_frame
	quit()
