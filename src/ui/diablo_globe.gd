class_name AethelGlobe
extends Control
## Presentation-only: authoritative values arrive through update_value, never global state.
@export var liquid_texture: Texture2D
@export var frame_texture: Texture2D
@export var liquid_color := Color.WHITE
var resource_title := ""
var progress: TextureProgressBar
var amount_label: Label
var surface: ColorRect
var shader_material: ShaderMaterial
var _tween: Tween
var display_ratio := 1.0:
 set(value):
  display_ratio = clampf(value,0,1)
  if shader_material != null: shader_material.set_shader_parameter("fill",display_ratio)

func _ready() -> void:
 custom_minimum_size = Vector2(140,128)
 size = custom_minimum_size
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 progress = TextureProgressBar.new()
 progress.position = Vector2(8,0)
 progress.size = Vector2(124,124)
 progress.fill_mode = TextureProgressBar.FILL_BOTTOM_TO_TOP
 progress.texture_progress = liquid_texture if liquid_texture != null else preload("res://assets/ui/globe_liquid.png")
 progress.tint_progress = liquid_color
 progress.max_value = 100
 progress.value = 100
 progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
 progress.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 add_child(progress)
 surface = ColorRect.new()
 surface.position = Vector2(8,0)
 surface.size = Vector2(124,124)
 surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
 shader_material = ShaderMaterial.new()
 shader_material.shader = preload("res://assets/shaders/aethel_globe.gdshader")
 shader_material.set_shader_parameter("liquid_color",liquid_color)
 surface.material = shader_material
 add_child(surface)
 var frame := TextureRect.new()
 frame.texture = frame_texture if frame_texture != null else preload("res://assets/ui/globe_frame.png")
 frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 frame.position = Vector2(8,0)
 frame.size = Vector2(124,124)
 frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(frame)
 amount_label = Label.new()
 amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 amount_label.size = Vector2(140,124)
 amount_label.add_theme_font_size_override("font_size",14)
 amount_label.add_theme_color_override("font_color",AethelUI.TEXT)
 amount_label.add_theme_color_override("font_outline_color",AethelUI.BACKGROUND)
 amount_label.add_theme_constant_override("outline_size",4)
 amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(amount_label)
 set_shader_enabled(AethelSettings.shader_globes)

func set_shader_enabled(enabled: bool) -> void:
 if surface == null: return
 surface.visible = enabled
 progress.visible = not enabled

func update_value(current: float,maximum: float,instant: bool = false) -> void:
 if progress == null: return
 var safe_max := maxf(1,maximum)
 var safe_current := clampf(current,0,maxf(0,maximum))
 var ratio := safe_current/safe_max
 progress.max_value = safe_max
 progress.value = safe_current
 amount_label.text = "%s\n%d / %d\n%d%%" % [resource_title,roundi(safe_current),roundi(maximum),roundi(ratio*100)]
 if _tween != null and _tween.is_running(): _tween.kill()
 if instant or AethelSettings.reduced_motion or is_equal_approx(ratio,display_ratio):
  display_ratio = ratio
  shader_material.set_shader_parameter("activity",0)
  return
 shader_material.set_shader_parameter("activity",1)
 _tween = create_tween()
 _tween.tween_property(self,"display_ratio",ratio,0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
 _tween.tween_callback(func() -> void: shader_material.set_shader_parameter("activity",0))
