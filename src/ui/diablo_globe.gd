class_name AethelGlobe
extends Control

@export var liquid_texture: Texture2D
@export var frame_texture: Texture2D
@export var liquid_color: Color = Color.WHITE
var progress: TextureProgressBar
var amount_label: Label
var _tween: Tween

func _ready() -> void:
 custom_minimum_size = Vector2(160, 160)
 size = Vector2(160, 160)
 mouse_filter = Control.MOUSE_FILTER_STOP
 progress = TextureProgressBar.new()
 progress.position = Vector2.ZERO
 progress.size = Vector2(160,160)
 progress.fill_mode = TextureProgressBar.FILL_BOTTOM_TO_TOP
 progress.texture_progress = liquid_texture
 progress.tint_progress = liquid_color
 progress.max_value = 100
 progress.value = 100
 progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(progress)
 var frame := TextureRect.new()
 frame.texture = frame_texture
 frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 frame.position = Vector2.ZERO
 frame.size = Vector2(160,160)
 frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(frame)
 amount_label = Label.new()
 amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 amount_label.position = Vector2.ZERO
 amount_label.size = Vector2(160,160)
 amount_label.add_theme_font_size_override("font_size", 17)
 amount_label.add_theme_color_override("font_shadow_color", Color.BLACK)
 amount_label.add_theme_constant_override("shadow_offset_x", 2)
 amount_label.add_theme_constant_override("shadow_offset_y", 2)
 amount_label.visible = false
 amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(amount_label)
 mouse_entered.connect(func() -> void: amount_label.visible = true)
 mouse_exited.connect(func() -> void: amount_label.visible = false)

func update_value(current: float, maximum: float, instant: bool = false) -> void:
 if progress == null: return
 if _tween != null and _tween.is_running(): _tween.kill()
 var safe_max: float = maxf(1.0, maximum)
 var safe_current: float = clampf(current, 0.0, safe_max)
 progress.max_value = safe_max
 amount_label.text = "%d / %d" % [roundi(safe_current), roundi(maximum)]
 if instant:
  progress.value = safe_current
  return
 _tween = create_tween()
 _tween.tween_property(progress, "value", safe_current, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
