class_name AethelRegionLevel
extends Node3D
## Authored region composition. Physics, navigation and map outline share one definition.
@export var region_id := "map_01"
@export var presentation_scene: PackedScene
var presentation_asset: Node3D
var presentation_occluders: Array[Node3D]=[]
var definition: Dictionary
var cells: Dictionary = {}
var graph := AStar3D.new()
var point_ids: Dictionary = {}
var materials: Dictionary = {}
var navigation: NavigationRegion3D
var build_usec := 0
var seed_value := 2701
var decorative_positions: Array[Vector3] = []

func _ready() -> void:
	var started := Time.get_ticks_usec()
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions.json"))
	for row: Dictionary in source.regions:
		if row.id == region_id: definition = row
	build_cells()
	build_geometry()
	batch_boundaries()
	build_navigation()
	apply_presentation()
	build_usec = Time.get_ticks_usec()-started

func height_at(x: float,z: float) -> float:
	if region_id == "map_03" and x >= 7 and x <= 13:
		if z < -2: return 1.5
		if z <= 4: return (4-z)*0.25
	return 0.0

func build_cells() -> void:
	for area: Array in definition.floors:
		for x in range(int(area[0]),int(area[0]+area[2])):
			for z in range(int(area[1]),int(area[1]+area[3])):
				var key := Vector2i(x,z)
				var blocked := false
				for obstacle: Array in definition.blocks+definition.get("nav_blocks",[]):
					if Rect2(Vector2(obstacle[0],obstacle[1]),Vector2(obstacle[2],obstacle[3])).grow(0.45).has_point(Vector2(x+0.5,z+0.5)): blocked=true
				if not blocked: cells[key]=height_at(x+0.5,z+0.5)
	# Eight-way routing, with diagonal corner cutting explicitly prohibited.
	for key: Vector2i in cells:
		var id := graph.get_available_point_id()
		point_ids[key]=id
		graph.add_point(id,Vector3(key.x+0.5,cells[key],key.y+0.5))
	for key: Vector2i in cells:
		for delta: Vector2i in [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(-1,1)]:
			var other := key+delta
			if not cells.has(other) or absf(cells[key]-cells[other])>0.45: continue
			if delta.x != 0 and delta.y != 0:
				if not cells.has(key+Vector2i(delta.x,0)) or not cells.has(key+Vector2i(0,delta.y)): continue
				if absf(cells[key+Vector2i(delta.x,0)]-cells[key])>0.45 or absf(cells[key+Vector2i(0,delta.y)]-cells[key])>0.45: continue
			graph.connect_points(point_ids[key],point_ids[other])

func material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color=color
		mat.roughness=0.95
		materials[key]=mat
	return materials[key]

func box(at: Vector3,dimensions: Vector3,color: Color,solid := true,ground := false) -> Node3D:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	add_child(body)
	body.position=at
	if ground: body.set_meta("walkable_ground",true)
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size=dimensions
	mesh.mesh=shape
	mesh.material_override=material(color)
	mesh.visibility_range_end=65
	body.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		var cube := BoxShape3D.new()
		cube.size=dimensions
		collision.shape=cube
		body.add_child(collision)
	return body

func build_geometry() -> void:
	var palette: Array[Color] = [Color("514b48"),Color("41404f"),Color("36505a"),Color("383444")]
	var index := int(region_id.right(2))-1
	var floor_color := palette[index]
	# Each horizontal tile is batched, not a separate scene node/material.
	var instance := MultiMeshInstance3D.new()
	var batch := MultiMesh.new()
	batch.transform_format=MultiMesh.TRANSFORM_3D
	batch.use_colors=true
	var tile := BoxMesh.new()
	tile.size=Vector3(0.96,0.08,0.96)
	batch.mesh=tile
	batch.instance_count=cells.size()
	var mat := material(Color.WHITE).duplicate() as StandardMaterial3D
	mat.vertex_color_use_as_albedo=true
	instance.material_override=mat
	instance.multimesh=batch
	instance.set_meta("region_floor",true)
	add_child(instance)
	var n := 0
	for key: Vector2i in cells:
		batch.set_instance_transform(n,Transform3D(Basis.IDENTITY,Vector3(key.x+0.5,float(cells[key])-0.02,key.y+0.5)))
		batch.set_instance_color(n,floor_color.lightened(float(posmod(key.x*7+key.y*3,5))*0.025))
		n+=1
	# Authored floor areas have matching collision. The courtyard terrace/ramp replaces its base collision.
	for area: Array in definition.floors:
		if region_id == "map_03":
			box(Vector3(-3.5,-0.3,0),Vector3(21,0.6,32),floor_color,true,true)
			box(Vector3(13.5,-0.3,0),Vector3(1,0.6,32),floor_color,true,true)
			box(Vector3(10,-0.3,10),Vector3(6,0.6,12),floor_color,true,true)
			box(Vector3(10,1.2,-9),Vector3(6,0.6,14),floor_color,true,true)
			var ramp := box(Vector3(10,0.45,1),Vector3(6,0.6,6.185),floor_color,true,true)
			ramp.rotation.x=atan(0.25)
			# Architectural stair treads use the continuous ramp collider for reliable CharacterBody traversal.
			for step in 6:
				box(Vector3(10,step*0.25+0.04,3.5-step),Vector3(5.8,0.08,0.9),Color("6e777b"),false)
			# Exposed terrace sides are not climbable shortcuts.
			box(Vector3(6.8,0.6,-9),Vector3(0.25,1.2,14),Color("535257"))
			break
		box(Vector3(area[0]+area[2]/2.0,-0.3,area[1]+area[3]/2.0),Vector3(area[2],0.6,area[3]),floor_color,true,true)
	for obstacle: Array in definition.blocks:
		var center := Vector3(obstacle[0]+obstacle[2]/2.0,1.2,obstacle[1]+obstacle[3]/2.0)
		var structure:=box(center,Vector3(obstacle[2],2.4,obstacle[3]),Color("53505a"))
		structure.set_meta("region_block_index",definition.blocks.find(obstacle))
		var roof:=box(center+Vector3(0,1.3,0),Vector3(obstacle[2]+0.2,0.2,obstacle[3]+0.2),Color("74656c"),false)
		remove_child(roof)
		structure.add_child(roof)
		roof.position=Vector3(0,1.3,0) # Occlusion fades the roof and body together.
	# Boundaries follow the authored floor union. Low front walls preserve isometric visibility.
	for key: Vector2i in cells:
		for delta: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			if cells.has(key+delta): continue
			var outside := true
			for area: Array in definition.floors:
				if Rect2(Vector2(area[0],area[1]),Vector2(area[2],area[3])).has_point(Vector2(key+delta)+Vector2(0.5,0.5)): outside=false
			if not outside: continue
			var h := 1.0 if delta.x>0 or delta.y>0 else 2.2
			var boundary := box(Vector3(key.x+0.5+delta.x*0.5,float(cells[key])+h/2,key.y+0.5+delta.y*0.5),Vector3(0.18 if delta.x!=0 else 1.0,h,0.18 if delta.y!=0 else 1.0),Color("48444e"))
			boundary.set_meta("batch_boundary",true)
	if region_id == "map_01":
		# Bell tower, inhabited bronze lanterns, repair benches; services keep their established positions.
		for x in [-10.0,10.0]:
			box(Vector3(x,1.7,-10),Vector3(2,3.4,2),Color("62575a")).set_meta("legacy_hub_detail",true)
		box(Vector3(-10,4,-10),Vector3(1.4,1.3,1.4),Color("9a7b45"),false).set_meta("legacy_hub_detail",true)
		box(Vector3(-10,5,-10),Vector3(2.5,0.4,2.5),Color("3a3226"),false).set_meta("legacy_hub_detail",true)
		for z in [-8.0,8.0]:
			box(Vector3(-13,0.5,z),Vector3(2,1,2),Color("7e6b54"))
	elif region_id == "map_03":
		var stair_fill:=OmniLight3D.new()
		stair_fill.position=Vector3(10,3,1)
		stair_fill.light_color=Color("a5bfd0")
		stair_fill.light_energy=1.0
		stair_fill.omni_range=8
		stair_fill.shadow_enabled=false
		add_child(stair_fill)
	elif region_id == "map_04":
		for z in [-9.0,-4.0,1.0]:
			for x in [-3.0,3.0]:
				box(Vector3(x,0.8,z),Vector3(0.65,1.6,2),Color("685f51"))
		for x in [-8.0,8.0]: box(Vector3(x,1.6,-13),Vector3(1,3.2,1),Color("86744f"))
		var marker := Marker3D.new()
		marker.name="FuturePorteiroEvent"
		marker.position=Vector3(0,0,-15)
		add_child(marker)
	# Reproducible optional decoration. Never adds collision or changes route/events.
	var random := RandomNumberGenerator.new()
	random.seed=seed_value+region_id.hash()
	var keys := cells.keys()
	for i in 14:
		var key: Vector2i=keys[random.randi_range(0,keys.size()-1)]
		var at := Vector3(key.x+0.5,cells[key]+0.04,key.y+0.5)
		decorative_positions.append(at)
		box(at,Vector3(0.45,0.05,0.3),Color("99866a") if region_id=="map_04" else Color("716070"),false)
	for row: Dictionary in definition.pois:
		var at := Vector3(row.position[0],row.position[1],row.position[2])
		box(at+Vector3(0,0.5,0),Vector3(0.5,1,0.5),Color("867854"),false)
	for at: Vector3 in [Vector3(-6,2.6,6),Vector3(6,2.6,-8)]:
		var lamp := OmniLight3D.new()
		lamp.position=at
		lamp.light_color=Color("ffaf60") if region_id=="map_01" else Color("8b84c4")
		lamp.light_energy=1.3
		lamp.omni_range=7
		lamp.shadow_enabled=false
		add_child(lamp)

func apply_presentation() -> void:
	if presentation_scene==null or region_id!="map_01": return
	var asset:=presentation_scene.instantiate() as Node3D
	if asset==null: return
	# This layer is presentation only. Reject geometry that could change routes/state.
	for kind: String in ["CollisionObject3D","CollisionShape3D","NavigationRegion3D","NavigationAgent3D","Camera3D"]:
		if not asset.find_children("*",kind,true,false).is_empty():
			asset.free();return
	add_child(asset);presentation_asset=asset
	for body: Node3D in get_children():
		if body.get_meta("region_floor",false): body.hide()
		if body.has_meta("region_block_index"):
			var replacement:=asset.get_node_or_null("BlockVisual%d"%int(body.get_meta("region_block_index"))) as Node3D
			if replacement!=null:
				for mesh: GeometryInstance3D in body.find_children("*","GeometryInstance3D",true,false): mesh.hide()
				replacement.reparent(body,true)
				presentation_occluders.append(replacement)
		if body.get_meta("legacy_hub_detail",false):
			for mesh: GeometryInstance3D in body.find_children("*","GeometryInstance3D",true,false): mesh.hide()
	for child: Node3D in asset.get_children():
		if child.has_meta("occlusion_bounds"): presentation_occluders.append(child)

func build_navigation() -> void:
	navigation=NavigationRegion3D.new()
	var mesh := NavigationMesh.new()
	var vertices := PackedVector3Array()
	var vertex_ids: Dictionary={}
	var polygons: Array[PackedInt32Array]=[]
	for key: Vector2i in cells:
		var polygon := PackedInt32Array()
		for offset: Vector2i in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(1,0)]:
			var corner := key+offset
			var v := Vector3(corner.x,height_at(corner.x,corner.y),corner.y)
			if not vertex_ids.has(v): vertex_ids[v]=vertices.size(); vertices.append(v)
			polygon.append(vertex_ids[v])
		polygons.append(polygon)
	mesh.set_vertices(vertices)
	for polygon in polygons: mesh.add_polygon(polygon)
	navigation.navigation_mesh=mesh
	add_child(navigation)

func valid_position(at: Vector3) -> bool:
	if not at.is_finite(): return false
	var key := Vector2i(floori(at.x),floori(at.z))
	if not cells.has(key) or absf(at.y-height_at(at.x,at.z))>=0.7: return false
	# Capsule clearance also applies to restored positions at wall/cell boundaries.
	for offset: Vector2 in [Vector2(0.34,0),Vector2(-0.34,0),Vector2(0,0.34),Vector2(0,-0.34)]:
		var neighbor:=Vector2i(floori(at.x+offset.x),floori(at.z+offset.y))
		if not cells.has(neighbor) or absf(float(cells[neighbor])-float(cells[key]))>0.5: return false
	return true

func safe_position(at: Vector3) -> Vector3:
	if valid_position(at): return Vector3(at.x,height_at(at.x,at.z),at.z)
	var spawn: Array=definition.spawn
	return Vector3(spawn[0],spawn[1],spawn[2])

func path(from: Vector3,to: Vector3) -> PackedVector3Array:
	var key := Vector2i(floori(to.x),floori(to.z))
	if not valid_position(to) or not point_ids.has(key): return PackedVector3Array()
	var start := graph.get_closest_point(from)
	if start<0: return PackedVector3Array()
	var result := graph.get_point_path(start,point_ids[key])
	if result.size()>1:
		var clear_segment:=true
		var steps:=maxi(1,ceili(from.distance_to(result[1])/0.15))
		for index in steps+1:
			var sample:=from.lerp(result[1],float(index)/steps)
			sample.y=height_at(sample.x,sample.z)
			if not valid_position(sample): clear_segment=false;break
		if clear_segment: result.remove_at(0)
	if not result.is_empty(): result.append(Vector3(to.x,height_at(to.x,to.z),to.z))
	return result

func set_archive_door(opened: bool) -> void:
	if region_id!="map_04": return
	for x in range(-4,4):
		var key := Vector2i(x,6)
		if point_ids.has(key): graph.set_point_disabled(point_ids[key],not opened)

func batch_boundaries() -> void:
	var groups: Dictionary={}
	for body in get_children():
		if not body.get_meta("batch_boundary",false): continue
		var mesh: MeshInstance3D=body.get_child(0)
		var key: String=str(mesh.mesh.size)
		if not groups.has(key): groups[key]=[]
		groups[key].append({"transform":body.transform,"mesh":mesh.mesh,"material":mesh.material_override})
		body.remove_child(mesh)
		mesh.free()
	for rows: Array in groups.values():
		var instance := MultiMeshInstance3D.new()
		var batch := MultiMesh.new()
		batch.transform_format=MultiMesh.TRANSFORM_3D
		batch.mesh=rows[0].mesh
		batch.instance_count=rows.size()
		for index in rows.size(): batch.set_instance_transform(index,rows[index].transform)
		instance.multimesh=batch
		instance.material_override=rows[0].material
		instance.visibility_range_end=65
		add_child(instance)

func approach(from: Vector3,target: Vector3,distance:=1.8) -> Vector3:
	var direction:=from-target
	direction.y=0
	if direction.length()<0.1: direction=Vector3.FORWARD
	for index in 16:
		var candidate:=target+direction.normalized().rotated(Vector3.UP,index*TAU/16.0)*distance
		candidate.y=height_at(candidate.x,candidate.z)
		if not path(from,candidate).is_empty(): return candidate
	return Vector3.INF
