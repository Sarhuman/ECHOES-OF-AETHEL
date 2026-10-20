extends SceneTree
var failures: Array[String] = []
var checks := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value: failures.append(description)

func luminance(color: Color) -> float:
	var linear := color.srgb_to_linear()
	return linear.r * 0.2126 + linear.g * 0.7152 + linear.b * 0.0722

func contrast(a: Color, b: Color) -> float:
	return (maxf(luminance(a),luminance(b)) + 0.05) / (minf(luminance(a),luminance(b)) + 0.05)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var theme := load("res://assets/ui/aethel_theme.tres") as Theme
	check(theme != null and ProjectSettings.get_setting("gui/theme/custom") == "res://assets/ui/aethel_theme.tres", "global reusable theme")
	for state in ["normal","hover","pressed","focus","disabled"]: check(theme.has_stylebox(state,"Button"),"button state " + state)
	check(theme.get_stylebox("focus","Button").border_color == AethelUI.FOCUS,"focus distinct from hover")
	for variant in ["AethelDialogue","AethelSpeech","AethelPortrait","AethelComparison"]:
		check(theme.get_type_variation_base(variant) == "PanelContainer","reusable variant " + variant)
	check(AethelUI.RARITY_COLORS.size() == 5 and AethelUI.RARITY_TEXT.size() == 5,"five qualities preserved")
	check(AethelUI.RARITY_COLORS[1] == Color("4850b8") and AethelUI.RARITY_COLORS[2] == Color("d0c020"),"official rarity accents")
	for color: Color in AethelUI.RARITY_TEXT: check(contrast(color,AethelUI.BACKGROUND) >= 4.5,"rarity text contrast")
	check(contrast(AethelUI.TEXT,AethelUI.SURFACE) >= 4.5,"body text contrast")
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	check(world.hud.skill_buttons[0].focus_mode == Control.FOCUS_NONE,"HUD does not capture Space after clicking")
	var inventory = world.inventory_view
	inventory.show()
	await process_frame
	var button: Button = inventory.equip_root.get_child(world.player.SLOT_ORDER.find("weapon"))
	button.grab_focus()
	await process_frame
	check(button.has_focus(),"inventory keyboard focus")
	check(inventory.tooltip.visible and inventory.tooltip._keyboard_anchor,"focus automatically shows item tooltip")
	var item = world.player.equipped.get("weapon")
	check(item != null,"existing inventory item available")
	inventory.tooltip.show_item_at(item,button.get_global_rect())
	check(inventory.tooltip.visible and inventory.tooltip._keyboard_anchor,"keyboard tooltip anchor")
	inventory.tooltip.show_comparison(item,item)
	check("EQUIPADO" in inventory.tooltip._text.text,"comparison view uses existing item formatter")
	inventory.flash_invalid()
	check(inventory.modulate == AethelUI.INVALID,"invalid action feedback")
	var dialogue := AethelDialogueView.new()
	root.add_child(dialogue)
	dialogue.position = Vector2(40,40)
	dialogue.present("Maera Voss","Texto de teste.",["Ouvir","Voltar"],"Missão de teste")
	var received: Array[int] = []
	dialogue.response_selected.connect(func(index: int) -> void: received.append(index))
	dialogue.responses.get_child(1).grab_focus()
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	await process_frame
	check(received == [1],"keyboard response emits index without narrative side effects")
	dialogue.focus_first_response()
	check(dialogue.responses.get_child(0).has_focus(),"dialogue keyboard focus")
	dialogue.present("Doma Ferren","Outro texto.",["Negociar"])
	check(dialogue.responses.get_child_count() == 1 and not dialogue.quest.visible,"view reused for another NPC")
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size = resolution
		await process_frame
		check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(dialogue.get_global_rect()),"dialogue fits " + str(resolution))
		check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(world.hud.resource_panel.get_global_rect()),"resources fit " + str(resolution))
	print("GOTHIC UI: %d checks, %d failures" % [checks,failures.size()])
	for failure in failures: printerr("FALHA: ",failure)
	quit(0 if failures.is_empty() else 1)
