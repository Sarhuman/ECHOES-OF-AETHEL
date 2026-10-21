class_name AethelPauseMenu
extends CanvasLayer

signal inspect_requested
signal save_requested
var overlay: Control
var options: AethelOptionsPanel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	overlay = ColorRect.new()
	(overlay as ColorRect).color = Color(AethelUI.BACKGROUND,0.94)
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rows := VBoxContainer.new()
	rows.custom_minimum_size.x = 400
	rows.add_theme_constant_override("separation", 10)
	center.add_child(rows)
	var title := Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	rows.add_child(title)
	_button(rows, "RETOMAR", resume)
	_button(rows, "ATRIBUTOS", func() -> void: resume(); inspect_requested.emit())
	_button(rows, "SALVAR", func() -> void: save_requested.emit())
	_button(rows, "OPÇÕES", func() -> void: options.visible = not options.visible)
	options = AethelOptionsPanel.new()
	rows.add_child(options)
	options.hide()
	_button(rows, "VOLTAR AO MENU", return_to_menu)
	_button(rows, "SAIR", func() -> void: get_tree().quit())
	overlay.hide()

func _button(parent: Node, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 40
	button.pressed.connect(action)
	parent.add_child(button)

func open() -> void:
	overlay.show()
	get_tree().paused = true
	var first := overlay.find_children("*","Button",true,false)
	if not first.is_empty(): first[0].grab_focus()

func resume() -> void:
	get_tree().paused = false
	overlay.hide()
	options.hide()

func return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if overlay.visible and event.is_action_pressed("pause"):
		resume()
		get_viewport().set_input_as_handled()
