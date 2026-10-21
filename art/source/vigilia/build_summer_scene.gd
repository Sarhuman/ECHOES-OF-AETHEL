extends SceneTree
## Original editable data authored with Summer's installed headless engine.
## No cloud, generated/downloaded third-party assets or Summer runtime classes.
var palette: Dictionary={}
var batches: Dictionary={}
func _init() -> void: call_deferred("run")
func material(id: String,color: Color) -> StandardMaterial3D:
	if not palette.has(id):
		var mat:=StandardMaterial3D.new()
		mat.resource_name=id
		mat.albedo_color=color
		mat.roughness=0.9
		palette[id]=mat
	return palette[id]
func box(parent: Node3D,id: String,at: Vector3,size: Vector3,mat: Material,solid:=false) -> Node3D:
	var body: Node3D=StaticBody3D.new() if solid else Node3D.new()
	body.name=id;body.position=at;parent.add_child(body)
	var mesh:=MeshInstance3D.new()
	var shape:=BoxMesh.new();shape.size=size
	mesh.mesh=shape;mesh.material_override=mat;body.add_child(mesh)
	if solid:
		var collider:=CollisionShape3D.new()
		var collision:=BoxShape3D.new();collision.size=size
		collider.shape=collision;body.add_child(collider)
	return body
func own(node: Node,root_node: Node) -> void:
	for child in node.get_children():
		child.owner=root_node
		own(child,root_node)
func save_scene(node: Node3D,path: String) -> bool:
	own(node,node)
	var packed:=PackedScene.new()
	return packed.pack(node)==OK and ResourceSaver.save(packed,path)==OK
func isolated() -> bool:
	var scene:=Node3D.new();scene.name="SummerIntegrationArea"
	scene.set_meta("source_engine",Engine.get_version_info().string)
	scene.set_meta("purpose","isolated compatibility test, not Vigilia")
	var stone:=material("stone",Color("74716a"))
	box(scene,"Floor",Vector3(0,-0.2,0),Vector3(12,0.4,12),stone,true)
	box(scene,"WallLeft",Vector3(-3.5,1.4,0),Vector3(5,2.8,0.35),stone,true)
	box(scene,"WallRight",Vector3(3.5,1.4,0),Vector3(5,2.8,0.35),stone,true)
	box(scene,"DoorLintel",Vector3(0,2.55,0),Vector3(2,0.5,0.35),material("bronze",Color("857044")),true)
	var ramp:=box(scene,"Ramp",Vector3(0,0.4,-2.5),Vector3(2.4,0.2,4.1231),stone,true)
	ramp.rotation.x=atan(0.25)
	box(scene,"Landing",Vector3(0,0.9,-5.25),Vector3(4,0.2,1.5),stone,true)
	var region:=NavigationRegion3D.new();region.name="NavigationRegion3D"
	var nav:=NavigationMesh.new()
	var vertices:=PackedVector3Array()
	var stops: Array[Vector2]=[Vector2(5,0),Vector2(0,0),Vector2(-0.5,0),Vector2(-2.5,0.5),Vector2(-4.5,1),Vector2(-5.5,1)]
	for stop: Vector2 in stops:
		vertices.append(Vector3(-0.65,stop.y,stop.x));vertices.append(Vector3(0.65,stop.y,stop.x))
	nav.set_vertices(vertices)
	for index in stops.size()-1: nav.add_polygon(PackedInt32Array([index*2,index*2+1,index*2+3,index*2+2]))
	region.navigation_mesh=nav;scene.add_child(region)
	var success:=save_scene(scene,"res://art/imported/vigilia/integration_test.tscn")
	scene.free()
	return success

func group(parent: Node3D,id: String,at:=Vector3.ZERO) -> Node3D:
	var node:=Node3D.new();node.name=id;node.position=at;parent.add_child(node)
	batches[node.get_instance_id()]={}
	return node
func part(node: Node3D,id: String,mesh: Mesh,at: Vector3,rotation:=Vector3.ZERO) -> void:
	var library: Dictionary=batches[node.get_instance_id()]
	if not library.has(id):
		var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES);surface.set_material(palette[id]);library[id]=surface
	library[id].append_from(mesh,0,Transform3D(Basis.from_euler(rotation),at))
func beam(node: Node3D,id: String,at: Vector3,size: Vector3,rotation:=Vector3.ZERO) -> void:
	var mesh:=BoxMesh.new();mesh.size=size;part(node,id,mesh,at,rotation)
func finish(node: Node3D,occludes:=false) -> void:
	var bounds:=AABB();var first:=true
	for id: String in batches[node.get_instance_id()]:
		var mesh:=MeshInstance3D.new();mesh.name=id
		mesh.mesh=batches[node.get_instance_id()][id].commit()
		node.add_child(mesh)
		bounds=mesh.mesh.get_aabb() if first else bounds.merge(mesh.mesh.get_aabb());first=false
	if occludes: node.set_meta("occlusion_bounds",bounds)
	batches.erase(node.get_instance_id())
func arch(node: Node3D,at: Vector3,width:=1.8,height:=2.4,depth:=0.25) -> void:
	var radius:=width*0.5
	for side in [-1,1]: beam(node,"stone",at+Vector3(side*(radius+0.12),height*0.4,0),Vector3(0.24,height*0.8,depth))
	for segment in 9:
		var angle:=PI*segment/8
		beam(node,"stone",at+Vector3(cos(angle)*radius,height*0.8+sin(angle)*radius,0),Vector3(0.32,0.24,depth),Vector3(0,0,angle-PI/2))
func window(node: Node3D,at: Vector3,echo:=false,outward_z:=-1.0) -> void:
	beam(node,"iron",at,Vector3(0.6,0.85,0.055))
	for side in [-1,1]: beam(node,"timber",at+Vector3(side*0.35,0,0.04*outward_z),Vector3(0.1,1.0,0.09))
	beam(node,"bronze",at+Vector3(0,0,0.05*outward_z),Vector3(0.045,0.8,0.04))
	beam(node,"bronze",at+Vector3(0,0.08,0.05*outward_z),Vector3(0.58,0.045,0.04))
	beam(node,"stone",at+Vector3(0,-0.5,0.025*outward_z),Vector3(0.87,0.13,0.18))
	if echo:
		for side in [-1,1]: beam(node,"echo",at+Vector3(side*0.43,0.16,0.005),Vector3(0.045,1.14,0.04))
		beam(node,"echo",at+Vector3(0,0.73,0.005),Vector3(0.9,0.045,0.04))
func roof(node: Node3D,at: Vector3,width: float,depth: float,height:=0.8) -> void:
	var shape:=PrismMesh.new();shape.size=Vector3(width,height,depth)
	part(node,"roof",shape,at)
	for side in [-1,1]:
		beam(node,"timber",at+Vector3(side*width/4,0,-depth/2-0.015),Vector3(sqrt(width*width/4+height*height),0.10,0.12),Vector3(0,0,-side*atan(height/(width/2))))
func house(parent: Node3D,index: int,rectangle: Array) -> void:
	var w: float=rectangle[2];var d: float=rectangle[3]
	var node:=group(parent,"BlockVisual%d"%index,Vector3(rectangle[0]+w/2,0,rectangle[1]+d/2))
	beam(node,"stone",Vector3(0,1.3,0),Vector3(w,2.6,d))
	beam(node,"dark_stone",Vector3(0,0.18,0),Vector3(w+0.05,0.36,d+0.05))
	# Small masonry joints and repairs, batched per building/material.
	for row in 5:
		beam(node,"dark_stone",Vector3(0,row*0.44+0.42,-d/2-0.012),Vector3(w,0.025,0.035))
		for col in 3:
			var x: float=-w/2+0.3+col*(w/3)+0.12*(row%2)
			beam(node,"dark_stone",Vector3(x,row*0.44+0.64,-d/2-0.015),Vector3(0.022,0.42,0.035))
	for side in [-1,1]:
		beam(node,"timber",Vector3(side*(w/2-0.07),1.45,-d/2-0.06),Vector3(0.14,2.5,0.13))
	beam(node,"timber",Vector3(0,2.53,-d/2-0.07),Vector3(w+0.1,0.14,0.15))
	window(node,Vector3(0,1.6,-d/2-0.07),index==3)
	window(node,Vector3(-w*0.25,1.5,d/2+0.07),index==3,1.0)
	for side in [-1,1]: beam(node,"timber",Vector3(side*(w/2-0.07),1.45,d/2+0.06),Vector3(0.14,2.5,0.13))
	beam(node,"timber",Vector3(0,2.53,d/2+0.07),Vector3(w+0.1,0.14,0.15))
	beam(node,"timber",Vector3(w*0.23,0.75,d/2+0.025),Vector3(0.68,1.5,0.055))
	for y in [0.35,1.1]: beam(node,"iron",Vector3(w*0.23,y,d/2+0.065),Vector3(0.7,0.05,0.045))
	if index==0:
		beam(node,"timber",Vector3(0,2.8,0),Vector3(2.15,0.16,2.15))
		for x in [-0.72,0.72]:
			for z in [-0.72,0.72]: beam(node,"timber",Vector3(x,3.85,z),Vector3(0.18,2.0,0.18))
		beam(node,"iron",Vector3(0,4.7,0),Vector3(1.7,0.18,0.18))
		var bell:=CylinderMesh.new();bell.top_radius=0.24;bell.bottom_radius=0.48;bell.height=0.65;bell.radial_segments=16
		part(node,"bronze",bell,Vector3(0,4.12,0))
		var rim:=TorusMesh.new();rim.inner_radius=0.41;rim.outer_radius=0.48;rim.rings=16;rim.ring_segments=8
		part(node,"bronze",rim,Vector3(0,3.81,0))
		beam(node,"iron",Vector3(0,3.8,0),Vector3(0.1,0.38,0.1))
		roof(node,Vector3(0,5.05,0),2.7,2.6,0.75)
	else: roof(node,Vector3(0,2.95,0),w+0.3,d+0.3,0.75)
	finish(node,true)
func build_library() -> bool:
	DirAccess.make_dir_recursive_absolute("res://art/imported/vigilia/modules")
	for id in ["floor","street","curb","wall","door_arch","window","column","roof","stairs","ramp","timber_frame","lantern","echo_inlay"]:
		var root_node:=Node3D.new();root_node.name=id
		var node:=group(root_node,"Geometry")
		match id:
			"door_arch": arch(node,Vector3.ZERO)
			"window": window(node,Vector3(0,1.5,0))
			"roof": roof(node,Vector3(0,0.4,0),2.4,2.4)
			"stairs":
				for step in 6: beam(node,"stone",Vector3(0,step*0.15+0.075,-step*0.3),Vector3(1.8,0.15,0.3))
			"ramp": beam(node,"stone",Vector3(0,0.4,0),Vector3(2.0,0.2,3.0),Vector3(atan(0.25),0,0))
			"column": beam(node,"stone",Vector3(0,1.2,0),Vector3(0.3,2.4,0.3))
			"wall": beam(node,"stone",Vector3(0,1.2,0),Vector3(3,2.4,0.3))
			"curb": beam(node,"dark_stone",Vector3(0,0.06,0),Vector3(1,0.12,0.2))
			"timber_frame":
				for x in [-0.8,0.8]: beam(node,"timber",Vector3(x,1.1,0),Vector3(0.15,2.2,0.15))
				beam(node,"timber",Vector3(0,2.2,0),Vector3(1.8,0.15,0.15))
			"lantern":
				beam(node,"iron",Vector3(0,1.1,0),Vector3(0.08,2.2,0.08));beam(node,"bronze",Vector3(0,2.2,0),Vector3(0.28,0.4,0.28))
			"echo_inlay": beam(node,"echo",Vector3(0,0.02,0),Vector3(0.8,0.03,0.035))
			_: beam(node,"stone",Vector3(0,0.02,0),Vector3(0.96,0.04,0.96))
		finish(node)
		if not save_scene(root_node,"res://art/imported/vigilia/modules/"+id+".tscn"): root_node.free();return false
		root_node.free()
	return true
func vigilia() -> bool:
	var layout: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://layout.json"))
	for pair: Array in [["stone","8a8171"],["dark_stone","4b4843"],["timber","423128"],["roof","3c464e"],["iron","292d30"],["bronze","9b7c4b"],["echo","536b74"]]: material(pair[0],Color(pair[1]))
	DirAccess.make_dir_recursive_absolute("res://art/imported/vigilia/materials")
	for id: String in palette:
		if ResourceSaver.save(palette[id],"res://art/imported/vigilia/materials/"+id+".tres",ResourceSaver.FLAG_CHANGE_PATH)!=OK: return false
	var scene:=Node3D.new();scene.name="VigiliaSummerArchitecture"
	scene.set_meta("source_engine",Engine.get_version_info().string);scene.set_meta("art_status","ART_REVIEW_PENDING")
	for index in layout.blocks.size(): house(scene,index,layout.blocks[index])
	var paving:=group(scene,"GroundOverlay")
	for x in range(-16,16):
		for z in range(-16,16):
			var id: String="stone" if (x*x+z*z<40 or z in [-1,0,1]) else "dark_stone"
			beam(paving,id,Vector3(x+0.5,0.015,z+0.5),Vector3(0.95,0.035,0.95))
	# Two imperfect rings: architectural echo motif, no new narrative interaction.
	for n in 20:
		var angle:=TAU*n/20
		beam(paving,"bronze",Vector3(cos(angle)*3.1,0.04,sin(angle)*3.1+4),Vector3(0.85,0.02,0.055),Vector3(0,-angle-PI/2,0))
		if n%3!=0: beam(paving,"echo",Vector3(cos(angle)*3.3+0.18,0.04,sin(angle)*3.3+4),Vector3(0.5,0.02,0.035),Vector3(0,-angle-PI/2,0))
	finish(paving)
	var canopy:=group(scene,"ForgeCanopy",Vector3(-11,0,-3))
	for side in [-1,1]: beam(canopy,"timber",Vector3(side*1.0,1.25,0),Vector3(0.13,2.5,0.13))
	roof(canopy,Vector3(0,2.65,0),2.7,2.3,0.45)
	beam(canopy,"stone",Vector3(0,2.3,-0.15),Vector3(0.6,1.8,0.6))
	finish(canopy,true)
	var gate:=group(scene,"EastGate",Vector3(11,0,0));arch(gate,Vector3.ZERO,1.8,2.2,0.45);finish(gate,true)
	var signs:=group(scene,"RepairsAndLamps")
	for at: Vector3 in [Vector3(-5,0,1),Vector3(8,0,-1)]:
		beam(signs,"iron",at+Vector3(0,1.2,0),Vector3(0.07,2.4,0.07))
		beam(signs,"bronze",at+Vector3(0,2.4,0),Vector3(0.26,0.35,0.26))
		var light:=OmniLight3D.new();light.position=at+Vector3(0,2.3,0);light.light_color=Color("f6c98e");light.light_energy=0.7;light.omni_range=4;light.shadow_enabled=false;scene.add_child(light)
	finish(signs)
	for id: String in layout.landmarks:
		var marker:=Marker3D.new();marker.name="Reference_"+id
		var pos: Array=layout.landmarks[id];marker.position=Vector3(pos[0],pos[1],pos[2]);scene.add_child(marker)
	var success:=save_scene(scene,"res://art/imported/vigilia/vigilia_summer.tscn") and build_library()
	scene.free();return success
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://art/imported/vigilia")
	var args:=OS.get_cmdline_user_args()
	var success:=args.size()==1 and (isolated() if args[0]=="ISOLATED" else vigilia() if args[0]=="VIGILIA" else false)
	print("SUMMER AUTHORING: "+JSON.stringify({"success":success,"mode":args[0] if args.size()>0 else "missing","engine":Engine.get_version_info().string,"binary":OS.get_executable_path()}))
	quit(0 if success else 1)
