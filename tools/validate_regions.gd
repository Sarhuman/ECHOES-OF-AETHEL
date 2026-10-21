extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var manager:=AethelRegionManager.new()
	root.add_child(manager)
	manager.setup(Node3D.new())
	var errors:=manager.validate_graph()
	var canonical: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/maps.json"))
	var ids: Dictionary={}
	for row: Dictionary in canonical.maps: ids[str(row.id)]=row.name
	for id: String in manager.definitions:
		var row: Dictionary=manager.definitions[id]
		if not ids.has(id) or ids[id]!=row.name: errors.append("Canonical ID/name mismatch "+id)
		manager.load_region(id)
		manager.level.set_archive_door(true)
		for entry: Array in row.entries.values():
			if not manager.level.valid_position(manager.point(entry)): errors.append("Invalid arrival "+id)
		for exit: Dictionary in row.exits:
			if manager.level.path(manager.point(row.spawn),manager.point(exit.position)).is_empty(): errors.append("Unreachable connector "+exit.id)
	manager.world.free()
	manager.queue_free()
	for error in errors: printerr(error)
	print("REGION GRAPH: ",errors.size()," errors")
	quit(0 if errors.is_empty() else 1)
