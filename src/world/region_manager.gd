class_name AethelRegionManager
extends Node
## Single region coordinator, owned by the existing world. No second scene tree/game state.
signal region_changed(id: String)
var world: Node3D
var definitions: Dictionary={}
var level: AethelRegionLevel
var connectors: Dictionary={}
var transitioning := false
var origin := ""
var visited: Array[String]=[]
var revealed: Dictionary={}
var known_pois: Dictionary={}
var opened_doors: Dictionary={}
var world_seed := 2701
var minimap: AethelMinimap
var last_cell := Vector3i(999,999,999)
var active_floor := 0
var reveal_updates := 0
var transition_count := 0
var max_transition_usec := 0
var veil: ColorRect
var veil_label: Label
var _tick := 0.0
var pending_connector := ""
var _occluders: Array[GeometryInstance3D]=[]

func setup(owner_world: Node3D) -> void:
	world=owner_world
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/regions.json"))
	for row: Dictionary in data.regions: definitions[str(row.id)]=row

func validate_graph() -> Array[String]:
	var errors: Array[String]=[]
	for id: String in definitions:
		var row: Dictionary=definitions[id]
		if not ResourceLoader.exists(row.scene): errors.append("Missing scene "+id)
		for exit: Dictionary in row.exits:
			if not definitions.has(exit.destination): errors.append("Missing destination "+exit.id); continue
			if not definitions[exit.destination].entries.has(exit.arrival): errors.append("Missing arrival "+exit.id)
			var returns := false
			for back: Dictionary in definitions[exit.destination].exits:
				if back.destination==id: returns=true
			if not returns: errors.append("No return "+exit.id)
	return errors

func load_region(id: String) -> bool:
	if not definitions.has(id): return false
	var started := Time.get_ticks_usec()
	for mesh in _occluders:
		if is_instance_valid(mesh): set_faded(mesh,false)
	_occluders.clear()
	if is_instance_valid(level):
		remove_child(level)
		level.free()
	connectors.clear()
	level=load(definitions[id].scene).instantiate()
	level.seed_value=world_seed
	add_child(level)
	if not id in visited: visited.append(id)
	for row: Dictionary in definitions[id].exits:
		var marker := Area3D.new()
		marker.name=str(row.id)
		marker.set_meta("connector_id",str(row.id))
		marker.collision_layer=256
		marker.collision_mask=0
		level.add_child(marker)
		marker.position=point(row.position)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size=Vector3(1.5,2.5,1.5)
		shape.shape=box
		shape.position.y=1.1
		marker.add_child(shape)
		level.box(marker.position+Vector3(-0.9,1.3,0),Vector3(0.35,2.6,0.6),Color("807153"),false)
		level.box(marker.position+Vector3(0.9,1.3,0),Vector3(0.35,2.6,0.6),Color("807153"),false)
		level.box(marker.position+Vector3(0,2.6,0),Vector3(2.2,0.3,0.6),Color("b8a058"),false)
		var title := Label3D.new()
		title.text="E/F · "+str(definitions[row.destination].name)
		title.position.y=3
		title.font_size=30
		title.pixel_size=0.008
		title.modulate=Color("fff0ca")
		title.outline_size=10
		title.no_depth_test=true
		title.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		marker.add_child(title)
		connectors[str(row.id)]=marker
	pending_connector=""
	last_cell=Vector3i(999,999,999)
	max_transition_usec=maxi(max_transition_usec,Time.get_ticks_usec()-started)
	region_changed.emit(id)
	return true

func attach_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer=1
	world.add_child(canvas)
	minimap=AethelMinimap.new()
	minimap.manager=self
	canvas.add_child(minimap)
	var transition_canvas := CanvasLayer.new()
	transition_canvas.layer=50
	world.add_child(transition_canvas)
	veil=ColorRect.new()
	veil.color=Color(0.04,0.03,0.025,0.35)
	veil.mouse_filter=Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_canvas.add_child(veil)
	veil_label=Label.new()
	veil_label.position=Vector2(440,310)
	veil_label.size=Vector2(400,60)
	veil_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	veil_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	veil_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	veil.add_child(veil_label)
	veil.hide()

func point(values: Array) -> Vector3:
	return Vector3(values[0],values[1],values[2])

func allows_combat() -> bool:
	return not bool(definitions.get(world.region_id,{}).get("safe",true)) and not transitioning

func connector_definition(id: String) -> Dictionary:
	for row: Dictionary in definitions[world.region_id].exits:
		if row.id==id: return row
	return {}

func unlocked(row: Dictionary) -> bool:
	return row.get("condition","")=="" or (row.condition=="quest_started" and world.quest_started)

func transition(id: String) -> bool:
	if transitioning or world.game_over: return false
	var row := connector_definition(id)
	if row.is_empty() or not connectors.has(id): return false
	if world.player.position.distance_to(connectors[id].position)>2.8 or not world.exploration.reachable(connectors[id]): return false
	if not unlocked(row): world._show_message("Converse com Maera antes de sair."); return false
	return move_to(str(row.destination),point(definitions[row.destination].entries[row.arrival]))

func move_to(id: String,at: Vector3) -> bool:
	if transitioning or not definitions.has(id) or world.game_over: return false
	transitioning=true
	origin=world.region_id
	world.player.clear_commands()
	world.left_held=false
	world.hold_mode=""
	world.pickup_target=null
	world.region_id=id
	world._update_region()
	world.player.position=level.safe_position(at)
	world.player.velocity=Vector3.ZERO
	world.get_viewport().get_camera_3d().snap_to_target()
	if veil!=null:
		veil_label.text="Travessia · "+str(definitions[id].name)
		veil.modulate.a=1
		veil.show()
		var fade := create_tween()
		fade.tween_property(veil,"modulate:a",0.0,0.3 if not AethelSettings.reduced_motion else 0.05)
		fade.tween_callback(veil.hide)
	transition_count+=1
	reveal()
	world._refresh_all()
	world._save_state()
	world._show_message("Travessia: "+str(definitions[id].name))
	# Guard stays active for the remainder of this frame, rejecting duplicate input.
	call_deferred("finish_transition")
	return true

func finish_transition() -> void:
	transitioning=false
	world.player.skills_changed.emit()

func pick(screen: Vector2) -> String:
	var hit: Dictionary=world._cursor_ray(screen,1 | 8 | 256,true)
	var collider: Node=hit.get("collider")
	return str(collider.get_meta("connector_id","")) if collider!=null else ""

func request(id: String) -> void:
	if not connectors.has(id): return
	if world.player.position.distance_to(connectors[id].position)<=2.8: transition(id); return
	world.narrative.close()
	world.exploration.pending=""
	pending_connector=id
	world.player.command_move(connectors[id].position)

func interact() -> bool:
	for id: String in connectors:
		if world.player.position.distance_to(connectors[id].position)<2.8:
			transition(id)
			return true
	return false

func tick(delta: float) -> void:
	if not is_instance_valid(level): return
	_tick+=delta
	if _tick<0.1: return
	_tick=0
	reveal()
	if not pending_connector.is_empty() and connectors.has(pending_connector):
		if world.player.keyboard_active or world.game_over: pending_connector=""
		elif world.player.position.distance_to(connectors[pending_connector].position)<=2.8: transition(pending_connector)
		elif not world.player.has_move_target: pending_connector=""
	# No processing distant enemy AI; only the current region is instantiated.
	for enemy in world.enemies:
		if is_instance_valid(enemy) and enemy.has_meta("spawn_id"): enemy.set_physics_process(enemy.position.distance_to(world.player.position)<25)
	for mesh in _occluders:
		if is_instance_valid(mesh): set_faded(mesh,false)
	_occluders.clear()
	var camera := world.get_viewport().get_camera_3d()
	var targets: Array[Vector3]=[world.player.global_position+Vector3.UP]
	for enemy in world.enemies:
		if is_instance_valid(enemy) and enemy.position.distance_to(world.player.position)<12: targets.append(enemy.global_position+Vector3(0,0.8,0))
	for target: Vector3 in targets:
		var query := PhysicsRayQueryParameters3D.create(camera.global_position,target,1)
		# Up to four successive walls; leave walkable floor opaque.
		for obstruction in 4:
			var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty() or hit.collider.get_meta("walkable_ground",false): break
			for mesh: GeometryInstance3D in hit.collider.find_children("*","GeometryInstance3D",true,false):
				set_faded(mesh,true)
				_occluders.append(mesh)
			var excluded := query.exclude
			excluded.append(hit.collider.get_rid())
			query.exclude=excluded
	world.exploration.present_object_labels()
	if minimap!=null: minimap.queue_redraw()

func floor_id(at: Vector3) -> int: return 1 if at.y>1.1 else 0
func cell_key(cell: Vector2i) -> String: return "%d,%d"%[cell.x,cell.y]
func floor_key(region: String,floor_index: int) -> String: return region+":"+str(floor_index)

func reveal() -> void:
	var at: Vector3=world.player.position
	active_floor=floor_id(at)
	var cell := Vector2i(floori(at.x),floori(at.z))
	var signature := Vector3i(cell.x,active_floor,cell.y)
	if signature==last_cell: return
	last_cell=signature
	reveal_updates+=1
	var key := floor_key(world.region_id,active_floor)
	if not revealed.has(key): revealed[key]={}
	for x in range(cell.x-4,cell.x+5):
		for z in range(cell.y-4,cell.y+5):
			var candidate := Vector2i(x,z)
			if candidate.distance_to(cell)>4 or not level.cells.has(candidate): continue
			if floor_id(Vector3(x,level.cells[candidate],z))!=active_floor: continue
			revealed[key][cell_key(candidate)]=true
	for row: Dictionary in definitions[world.region_id].pois:
		if point(row.position).distance_to(at)<3: known_pois[str(row.id)]=true

func discovered(at: Vector3) -> bool:
	var key := floor_key(world.region_id,floor_id(at))
	return revealed.get(key,{}).has(cell_key(Vector2i(floori(at.x),floori(at.z))))

func serialize() -> Dictionary:
	return {"seed":world_seed,"origin":origin,"visited":visited,"revealed":revealed,"known_pois":known_pois,"doors":opened_doors}

func valid_state(data: Variant) -> bool:
	if not data is Dictionary: return false
	if not data.get("seed",2701) is float and not data.get("seed",2701) is int: return false
	if not is_finite(float(data.get("seed",2701))) or float(data.get("seed",2701))!=floorf(float(data.get("seed",2701))) or absf(float(data.get("seed",2701)))>2147483647: return false
	if not data.get("origin","") is String or (data.get("origin","")!="" and not definitions.has(data.origin)): return false
	if not data.get("visited",[]) is Array or data.get("visited",[]).size()>definitions.size(): return false
	for id: Variant in data.get("visited",[]):
		if not id is String or not definitions.has(id): return false
	for key: String in ["revealed","known_pois","doors"]:
		if not data.get(key,{}) is Dictionary: return false
	if data.get("revealed",{}).size()>8: return false
	for key: Variant in data.get("revealed",{}):
		if not key is String or key.get_slice_count(":")!=2 or not definitions.has(key.get_slice(":",0)) or not key.get_slice(":",1) in ["0","1"]: return false
		var cells_data: Variant=data.revealed[key]
		if not cells_data is Dictionary or cells_data.size()>1600: return false
		for cell: Variant in cells_data:
			if not cell is String or cell.get_slice_count(",")!=2 or not cell.get_slice(",",0).is_valid_int() or not cell.get_slice(",",1).is_valid_int() or cells_data[cell]!=true: return false
			if absi(int(cell.get_slice(",",0)))>20 or absi(int(cell.get_slice(",",1)))>20: return false
	var poi_ids: Dictionary={}
	for definition: Dictionary in definitions.values():
		for poi: Dictionary in definition.pois: poi_ids[str(poi.id)]=true
	for id: Variant in data.get("known_pois",{}):
		if not poi_ids.has(str(id)) or data.known_pois[id]!=true: return false
	for id: Variant in data.get("doors",{}):
		if id!="archive_door" or data.doors[id]!=true: return false
	return true

func restore(data: Dictionary) -> void:
	world_seed=int(data.get("seed",2701))
	origin=str(data.get("origin",""))
	visited.assign(data.get("visited",[]))
	revealed=data.get("revealed",{}).duplicate(true)
	known_pois=data.get("known_pois",{}).duplicate()
	opened_doors=data.get("doors",{}).duplicate()
	last_cell=Vector3i(999,999,999)

func set_faded(mesh: GeometryInstance3D,faded: bool) -> void:
	if not mesh is MeshInstance3D: return
	# GeometryInstance transparency is renderer-dependent; material alpha works in Compatibility.
	if not mesh.has_meta("aethel_solid_material"):
		var original: Material=mesh.material_override
		if not original is StandardMaterial3D: return
		mesh.set_meta("aethel_solid_material",original)
		var translucent:=original.duplicate() as StandardMaterial3D
		translucent.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		translucent.albedo_color.a=0.2
		translucent.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
		mesh.set_meta("aethel_faded_material",translucent)
	mesh.material_override=mesh.get_meta("aethel_faded_material") if faded else mesh.get_meta("aethel_solid_material")
