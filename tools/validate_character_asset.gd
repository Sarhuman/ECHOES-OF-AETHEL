extends SceneTree
## CLI: --headless --path . --script res://tools/validate_character_asset.gd -- res://data/characters/candidate.tres
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.size()!=1 or not args[0].begins_with("res://") or not args[0].ends_with(".tres"):
		printerr("Provide one project-authored visual definition .tres");quit(1);return
	var definition:=load(args[0]) as AethelCharacterVisualDefinition
	if definition==null or definition.imported_scene==null:
		printerr("No imported candidate assigned");quit(1);return
	var model:=definition.imported_scene.instantiate() as Node3D
	if model==null: quit(1);return
	root.add_child(model)
	await process_frame
	var result:=AethelVisualAssetValidator.inspect(model,definition)
	print("CHARACTER ASSET: "+JSON.stringify(result))
	model.queue_free()
	await process_frame
	quit(0 if result.valid else 1)
