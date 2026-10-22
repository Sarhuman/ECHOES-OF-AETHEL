class_name AethelOptionsPanel
extends PanelContainer
signal preferences_changed
var controls: Dictionary = {}
func _ready() -> void:
 custom_minimum_size = Vector2(420,284)
 var scroll := ScrollContainer.new()
 scroll.custom_minimum_size = Vector2(396,260)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus = true
 add_child(scroll)
 var rows := VBoxContainer.new()
 rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 rows.add_theme_constant_override("separation",8)
 scroll.add_child(rows)
 var title := Label.new()
 title.text = "CONFIGURAÇÕES · rolar para mais opções"
 rows.add_child(title)
 var fullscreen := CheckButton.new()
 fullscreen.text = "Tela cheia"
 fullscreen.button_pressed = AethelSettings.fullscreen
 fullscreen.toggled.connect(func(value: bool) -> void: AethelSettings.fullscreen=value; changed())
 rows.add_child(fullscreen)
 controls.fullscreen = fullscreen
 for bus: String in ["Master","Music","SFX","UI","Ambience"]:
  var label := Label.new()
  label.text = {"Master":"Volume geral","Music":"Música","SFX":"Efeitos","UI":"Interface","Ambience":"Ambiente"}[bus]
  rows.add_child(label)
  var volume := HSlider.new()
  volume.min_value=0; volume.max_value=1; volume.step=0.05
  volume.value = AethelSettings.volume if bus == "Master" else AethelSettings.channel_volumes[bus]
  volume.tooltip_text = label.text + " · setas ajustam"
  volume.value_changed.connect(func(value: float) -> void:
   if bus == "Master": AethelSettings.volume=value
   else: AethelSettings.channel_volumes[bus]=value
   changed())
  rows.add_child(volume)
  controls[bus] = volume
 var resolution := OptionButton.new()
 for text: String in ["1280 × 720","1600 × 900","1920 × 1080"]: resolution.add_item(text)
 resolution.select([Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)].find(AethelSettings.window_size))
 resolution.item_selected.connect(func(index: int) -> void:
  AethelSettings.window_size = [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)][index]
  changed()
  AethelSettings.apply_window_size())
 rows.add_child(resolution)
 controls.resolution=resolution
 var scale_option := OptionButton.new()
 for text: String in ["HUD: 85%","HUD: 100%","HUD: 110%"]: scale_option.add_item(text)
 scale_option.select(0 if AethelSettings.hud_scale < 1 else (2 if AethelSettings.hud_scale > 1 else 1))
 scale_option.item_selected.connect(func(index: int) -> void: AethelSettings.hud_scale=[0.85,1.0,1.1][index]; changed())
 rows.add_child(scale_option)
 controls.hud_scale=scale_option
 var motion := CheckButton.new()
 motion.text = "Reduzir animações da interface"
 motion.button_pressed = AethelSettings.reduced_motion
 motion.toggled.connect(func(value: bool) -> void: AethelSettings.reduced_motion=value; changed())
 rows.add_child(motion)
 controls.reduced_motion=motion
 var interaction := OptionButton.new()
 interaction.add_item("Interagir: E",KEY_E)
 interaction.add_item("Interagir: F",KEY_F)
 interaction.select(1 if AethelSettings.interact_key == KEY_F else 0)
 interaction.item_selected.connect(func(index: int) -> void: AethelSettings.interact_key=KEY_F if index==1 else KEY_E; changed())
 rows.add_child(interaction)
 controls.interaction=interaction
 var remember := CheckButton.new()
 remember.text = "Lembrar zoom da câmera"
 remember.button_pressed=AethelSettings.remember_zoom
 remember.toggled.connect(func(value: bool) -> void: AethelSettings.remember_zoom=value; changed())
 rows.add_child(remember)

func changed() -> void:
 AethelSettings.save_settings()
 preferences_changed.emit()
