extends SceneTree
var checks:=0
var failures: Array[String]=[]
var world: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func frames(count:=4) -> void:
	for i in count: await physics_frame
	await process_frame
func physics_signature(level: Node3D) -> Array[String]:
	var rows: Array[String]=[]
	for collider: CollisionShape3D in level.find_children("*","CollisionShape3D",true,false):
		var shape: Shape3D=collider.shape
		rows.append(str(collider.global_transform)+str(shape.get_class())+str(shape.size if shape is BoxShape3D else shape.get_debug_mesh().get_aabb()))
	rows.sort();return rows
func approach(id: String) -> void:
	world.narrative.request(id)
	for i in 420:
		await physics_frame
		if world.narrative.view.visible: break
	check(world.narrative.view.visible and world.narrative.active_id==id,"actual path approach reaches "+id)
func run() -> void:
	var regions_hash:=FileAccess.get_sha256("res://data/regions.json")
	ProjectSettings.set_setting("aethel/world/vigilia_variant","GREYBOX")
	Engine.set_meta("aethel_new_game",true)
	world=load("res://scenes/main.tscn").instantiate();root.add_child(world);await frames(8)
	var actor: CharacterBody3D=world.player
	var manager: AethelRegionManager=world.regions
	var shapes:=physics_signature(manager.level)
	var old_cells: Dictionary=manager.level.cells.duplicate(true)
	var old_polygons: int=manager.level.navigation.navigation_mesh.get_polygon_count()
	var landmarks: Array=[world.npc.position,world.merchant.position,manager.connectors.map_01_to_map_02.position]
	var old_camera_size: float=root.get_camera_3d().size
	check(manager.active_vigilia_variant=="GREYBOX" and manager.level.presentation_asset==null,"original playable greybox remains available")
	ProjectSettings.set_setting("aethel/world/vigilia_variant","SUMMER")
	world._update_region();await frames()
	check(manager.active_vigilia_variant=="SUMMER" and manager.level.presentation_asset!=null,"Summer scene integrated into existing coordinator")
	check(manager.level.cells==old_cells and manager.level.navigation.navigation_mesh.get_polygon_count()==old_polygons,"same AStar cells heights and native navigation polygons")
	check(physics_signature(manager.level)==shapes,"all world collision shapes and transforms preserved")
	check([world.npc.position,world.merchant.position,manager.connectors.map_01_to_map_02.position]==landmarks,"NPCs and regional connector stay at original positions")
	check(root.get_camera_3d().projection==Camera3D.PROJECTION_ORTHOGONAL and root.get_camera_3d().size==old_camera_size,"same orthographic camera and zoom")
	check(manager.level.presentation_occluders.size()==7,"five building and two roof/gate occlusion bounds")
	var source: Node3D=load("res://art/imported/vigilia/vigilia_summer.tscn").instantiate()
	check(str(source.get_meta("source_engine","")).contains("custom_build"),"architecture authored with installed Summer")
	check(source.find_children("*","CollisionObject3D",true,false).is_empty() and source.find_children("*","NavigationRegion3D",true,false).is_empty(),"imported architecture cannot own physics or navigation")
	check(source.find_children("*","Light3D",true,false).size()==2,"only two added local lights")
	var materials: Dictionary={}
	for mesh: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count(): materials[mesh.mesh.surface_get_material(surface).get_instance_id()]=true
	check(materials.size()==7 and source.find_children("*","MeshInstance3D",true,false).size()<64,"seven shared materials with batched building meshes")
	source.free()
	check(manager.validate_graph().is_empty(),"same canonical graph")
	var ether: int=actor.ether
	check(not actor.use_skill(world.skill_tree.catalog.heavy_strike).is_empty() and actor.ether==ether,"safe hub still denies offensive skills without cost")
	actor.position=Vector3(-5,0,5);await frames()
	await approach("maera")
	world.narrative.select_response(0);world.narrative.select_response(0)
	check(world.quest_started,"Maera acceptance still updates existing quest")
	world.narrative.close()
	await approach("doma")
	world.narrative.select_response(0)
	check(world.shop_panel.visible,"Doma dialogue opens existing commerce")
	world.gold=2000
	var offered: AethelItemInstance=world.shop_stock[0]
	var price: int=world._buy_price(offered)
	world._purchase(offered,false)
	check(world.gold==2000-price and world.inventory.find_item(offered.instance_id)==offered,"atomic purchase through existing inventory")
	world.shop_panel.hide();world.narrative.close()
	actor.position=Vector3(3,0,7);await frames()
	check(world.exploration.activate("vigilia_anchor"),"same travel anchor discovered")
	manager.reveal()
	var revealed: Dictionary=manager.revealed.duplicate(true)
	world._save_state()
	actor.position=Vector3(0,0,4)
	check(world._load_state() and actor.position.distance_to(Vector3(3,0,7))<0.1,"save load preserves position in same region")
	check(manager.revealed==revealed and world.inventory.find_item(offered.instance_id)!=null,"fog and inventory persistence preserved")
	var payload: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(world.SAVE_PATH))
	check(int(payload.version)==6 and not payload.has("vigilia_variant"),"no save migration or presentation-owned state")
	actor.position=manager.connectors.map_01_to_map_02.position
	check(manager.transition("map_01_to_map_02"),"native district transition")
	await frames()
	check(world.region_id=="map_02" and manager.allows_combat() and manager.level.presentation_asset==null,"other region unchanged and hostile")
	actor.position=manager.connectors.map_02_to_map_01.position
	check(manager.transition("map_02_to_map_01"),"native hub return")
	await frames()
	check(world.region_id=="map_01" and not manager.allows_combat() and manager.active_vigilia_variant=="SUMMER","variant and safe policy restored on return")
	actor.position=Vector3(-12,0,-12);root.get_camera_3d().snap_to_target();await frames(10)
	manager.tick(0.2)
	var faded_imported:=false
	for mesh in manager._occluders:
		if mesh.get_parent().has_meta("occlusion_bounds") and mesh.material_override!=null and mesh.material_override.transparency==BaseMaterial3D.TRANSPARENCY_ALPHA: faded_imported=true
	check(faded_imported,"roof bounds fade imported architecture without extra collider")
	ProjectSettings.set_setting("aethel/world/vigilia_variant","GREYBOX")
	world._update_region();await frames()
	check(manager.active_vigilia_variant=="GREYBOX" and physics_signature(manager.level)==shapes,"rollback to original scene with identical collision")
	var invalid_root:=Node3D.new();var invalid_body:=StaticBody3D.new();invalid_root.add_child(invalid_body);invalid_body.owner=invalid_root
	var invalid:=PackedScene.new();invalid.pack(invalid_root);invalid_root.free()
	manager.level.presentation_scene=invalid;manager.level.apply_presentation()
	check(manager.level.presentation_asset==null,"invalid presentation with collision rejected before substitution")
	check(FileAccess.get_sha256("res://data/regions.json")==regions_hash,"authoritative region data untouched")
	world.queue_free();await frames()
	for failure in failures: print("FALHA: "+failure)
	print("PHASE27.3: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
