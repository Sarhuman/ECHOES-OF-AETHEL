extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func shot(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := OS.get_environment("AETHEL_CAPTURE_DIR").path_join(filename + ".png")
	if root.get_texture().get_image().save_png(path) != OK: quit(1)

func run() -> void:
	var background := ColorRect.new()
	background.color = AethelUI.BACKGROUND
	root.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.position = Vector2(40,40)
	panel.size = Vector2(1160,600)
	root.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = "AETHEL · SINO E LIMIAR — FUNDAÇÃO VISUAL"
	title.theme_type_variation = "AethelNPCName"
	column.add_child(title)
	var note := Label.new()
	note.text = "Amostra de componentes de apresentação; retratos e ícones definitivos pendentes."
	column.add_child(note)
	var row := HBoxContainer.new()
	column.add_child(row)
	var palette := VBoxContainer.new()
	palette.custom_minimum_size.x = 350
	row.add_child(palette)
	for index in 5:
		var button := Button.new()
		button.text = ["Comum","Mágico","Raro","Épico","Lendário"][index]
		button.custom_minimum_size.y = 42
		AethelUI.style_slot(button,index)
		palette.add_child(button)
	var unavailable := Button.new()
	unavailable.text = "Indisponível"
	unavailable.disabled = true
	palette.add_child(unavailable)
	var icon = load("res://scenes/ui/item_icon.tscn").instantiate()
	palette.add_child(icon)
	var view := AethelDialogueView.new()
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(view)
	view.present("Maera Voss","A cidade conserva os sinos das horas que ainda não chegaram.",["Ouvir Maera","Encerrar conversa"],"◇ O Direito ao Impossível",null,"E / F · Interagir")
	view.focus_first_response()
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = resolution
		await shot("gothic-components-%dx%d" % [resolution.x,resolution.y])
	panel.queue_free()
	background.queue_free()
	await process_frame
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = resolution
		await shot("gothic-hud-%dx%d" % [resolution.x,resolution.y])
	world.inventory_view.show()
	world.inventory_view.equip_root.get_child(0).grab_focus()
	root.size = Vector2i(1280,720)
	await shot("gothic-inventory-1280x720")
	quit()
