extends Control
var continue_button: Button
var options: AethelOptionsPanel

func _ready() -> void:
	AethelInput.ensure_defaults()
	AethelSettings.load_settings()
	get_tree().paused = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = AethelUI.BACKGROUND
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rows := VBoxContainer.new()
	rows.custom_minimum_size.x = 480
	rows.add_theme_constant_override("separation", 12)
	center.add_child(rows)
	var title := Label.new()
	title.text = "ECHOES OF AETHEL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	rows.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "O Direito ao Impossível | Pré-alpha — Fase 25"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(subtitle)
	var start := _button(rows, "NOVO JOGO", func() -> void: start_game(true))
	continue_button = _button(rows, "CONTINUAR", func() -> void: start_game(false))
	continue_button.disabled = not FileAccess.file_exists(AethelSavePaths.current())
	_button(rows, "OPÇÕES", func() -> void: options.visible = not options.visible)
	options = AethelOptionsPanel.new()
	rows.add_child(options)
	options.hide()
	_button(rows, "SAIR", func() -> void: get_tree().quit())
	start.grab_focus()
	if "--smoke-gameplay" in OS.get_cmdline_user_args() or "--verify-build" in OS.get_cmdline_user_args():
		print("SMOKE MENU READY")
		call_deferred("start_game", true)

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func start_game(new_game: bool) -> void:
	Engine.set_meta("aethel_new_game", new_game)
	get_tree().change_scene_to_file("res://scenes/main.tscn")
