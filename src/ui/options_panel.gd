class_name AethelOptionsPanel
extends PanelContainer

func _ready() -> void:
	custom_minimum_size = Vector2(380, 230)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	add_child(rows)
	var title := Label.new()
	title.text = "OPÇÕES"
	rows.add_child(title)
	var fullscreen := CheckButton.new()
	fullscreen.text = "Tela cheia"
	fullscreen.button_pressed = AethelSettings.fullscreen
	fullscreen.toggled.connect(func(value: bool) -> void:
		AethelSettings.fullscreen = value
		AethelSettings.save_settings())
	rows.add_child(fullscreen)
	var volume_label := Label.new()
	volume_label.text = "Volume geral (áudio de produção pendente)"
	rows.add_child(volume_label)
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.05
	volume.value = AethelSettings.volume
	volume.value_changed.connect(func(value: float) -> void:
		AethelSettings.volume = value
		AethelSettings.save_settings())
	rows.add_child(volume)
	var interaction := OptionButton.new()
	interaction.add_item("Interagir: E", KEY_E)
	interaction.add_item("Interagir: F", KEY_F)
	interaction.select(1 if AethelSettings.interact_key == KEY_F else 0)
	interaction.item_selected.connect(func(index: int) -> void:
		AethelSettings.interact_key = KEY_F if index == 1 else KEY_E
		AethelSettings.save_settings())
	rows.add_child(interaction)
