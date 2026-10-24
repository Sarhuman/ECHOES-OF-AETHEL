class_name AethelUI
extends RefCounted
## Presentation tokens only. Never changes item quality, stats or inventory rules.
const BACKGROUND := Color("0b0a08")
const SURFACE := Color("1f1a13")
const BRONZE := Color("3a3226")
const BRASS := Color("5c4f3c")
const TEXT := Color("d3c3a3")
const FOCUS := Color("f0d999")
const INVALID := Color("ed9385")
const MAGIC := Color("4850b8")
const RARE := Color("d0c020")
const SET_REFERENCE := Color("00b400")
const UNIQUE_REFERENCE := Color("b8a058")
const EPIC := Color("a779c6")
const LEGENDARY := Color("de9e54")
const RARITY_COLORS := [TEXT, MAGIC, RARE, EPIC, LEGENDARY]
# Semantic colors stay exact on frames; brighter text companions improve contrast.
const RARITY_TEXT := [TEXT, Color("a3a9ff"), RARE, Color("c9a4e4"), Color("efba7a")]
const RARITY_HEX := ["d3c3a3", "a3a9ff", "d0c020", "c9a4e4", "efba7a"]
const SPACE := 6
const MARGIN := 12
const LIFE := Color("8f303b")
const ETHER := Color("304e85")
const STAMINA := Color("695123")

static func panel(fill: Color = SURFACE, border: Color = BRASS, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_content_margin_all(MARGIN)
	style.set_corner_radius_all(2)
	return style

static func slot_style(quality: int, state: String) -> StyleBoxFlat:
	var accent: Color = RARITY_COLORS[clampi(quality,0,4)]
	var style := panel(BACKGROUND.lerp(accent,0.08),accent)
	style.set_content_margin_all(3)
	if state == "hover": style.bg_color = SURFACE.lerp(accent,0.12)
	if state == "pressed": style.bg_color = BRONZE
	if state == "focus":
		style.bg_color = Color.TRANSPARENT
		style.border_color = FOCUS
		style.set_border_width_all(2)
	if state == "disabled":
		style.bg_color = BACKGROUND
		style.border_color = BRONZE
	return style

static func style_slot(button: Button, quality: int) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state,slot_style(quality,state))
	button.add_theme_color_override("font_color",RARITY_TEXT[clampi(quality,0,4)])
	button.add_theme_color_override("font_hover_color",Color("fff0cd"))
	button.add_theme_color_override("font_focus_color",FOCUS)

static func create_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 16
	for type_name in ["Label", "Button", "CheckButton", "OptionButton", "RichTextLabel", "LineEdit", "PopupMenu"]:
		theme.set_color("font_color",type_name,TEXT)
		theme.set_color("font_shadow_color",type_name,Color.BLACK)
		theme.set_constant("shadow_offset_x",type_name,1)
		theme.set_constant("shadow_offset_y",type_name,2)
	for type_name in ["Panel", "PanelContainer", "PopupPanel"]:
		theme.set_stylebox("panel",type_name,panel())
	theme.set_color("default_color","RichTextLabel",TEXT)
	for type_name in ["Button", "OptionButton", "CheckButton"]:
		theme.set_stylebox("normal",type_name,panel(SURFACE))
		theme.set_stylebox("hover",type_name,panel(BRONZE,UNIQUE_REFERENCE))
		theme.set_stylebox("pressed",type_name,panel(BACKGROUND,UNIQUE_REFERENCE))
		theme.set_stylebox("disabled",type_name,panel(BACKGROUND,BRONZE))
		theme.set_stylebox("focus",type_name,panel(Color.TRANSPARENT,FOCUS,2))
		theme.set_color("font_hover_color",type_name,Color("fff0cd"))
		theme.set_color("font_focus_color",type_name,FOCUS)
		theme.set_color("font_disabled_color",type_name,Color("a39780"))
	for type_name in ["VBoxContainer", "HBoxContainer"]: theme.set_constant("separation",type_name,SPACE)
	theme.set_stylebox("panel","TooltipPanel",panel(BACKGROUND,BRASS))
	theme.set_color("font_color","TooltipLabel",TEXT)
	theme.set_font_size("font_size","TooltipLabel",14)
	theme.set_stylebox("background","ProgressBar",panel(BACKGROUND,BRONZE))
	theme.set_stylebox("fill","ProgressBar",panel(BRASS,BRASS))
	for variant in ["AethelDialogue", "AethelSpeech", "AethelPortrait", "AethelComparison"]:
		theme.set_type_variation(variant,"PanelContainer")
		theme.set_stylebox("panel",variant,panel(BACKGROUND if variant == "AethelSpeech" else SURFACE))
	theme.set_type_variation("AethelNPCName","Label")
	theme.set_color("font_color","AethelNPCName",FOCUS)
	theme.set_font_size("font_size","AethelNPCName",19)
	theme.set_type_variation("AethelQuest","Label")
	theme.set_color("font_color","AethelQuest",UNIQUE_REFERENCE)
	return theme
