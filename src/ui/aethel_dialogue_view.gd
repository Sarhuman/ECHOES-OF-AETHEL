class_name AethelDialogueView
extends PanelContainer
## View only: caller supplies lines/options and handles all narrative decisions.
signal response_selected(index: int)
var npc_name: Label
var interaction: Label
var portrait: TextureRect
var speech: RichTextLabel
var responses: VBoxContainer
var quest: Label

func _ready() -> void:
	theme_type_variation = "AethelDialogue"
	custom_minimum_size = Vector2(420,0)
	var column := VBoxContainer.new()
	add_child(column)
	npc_name = Label.new()
	npc_name.theme_type_variation = "AethelNPCName"
	column.add_child(npc_name)
	quest = Label.new()
	quest.theme_type_variation = "AethelQuest"
	column.add_child(quest)
	var row := HBoxContainer.new()
	column.add_child(row)
	var frame := PanelContainer.new()
	frame.theme_type_variation = "AethelPortrait"
	row.add_child(frame)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(64,80)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = preload("res://assets/ui/aethel_portal.svg")
	frame.add_child(portrait)
	var bubble := PanelContainer.new()
	bubble.theme_type_variation = "AethelSpeech"
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bubble)
	speech = RichTextLabel.new()
	speech.custom_minimum_size = Vector2(260,80)
	speech.fit_content = true
	speech.scroll_active = false
	bubble.add_child(speech)
	interaction = Label.new()
	column.add_child(interaction)
	responses = VBoxContainer.new()
	column.add_child(responses)

func present(speaker: String, line: String, choices: Array[String], quest_hint: String = "", image: Texture2D = null, interaction_hint: String = "") -> void:
	npc_name.text = speaker
	speech.text = line
	quest.text = quest_hint
	quest.visible = not quest_hint.is_empty()
	interaction.text = interaction_hint
	interaction.visible = not interaction_hint.is_empty()
	portrait.texture = image if image != null else preload("res://assets/ui/aethel_portal.svg")
	for child in responses.get_children():
		responses.remove_child(child)
		child.queue_free()
	for index in choices.size():
		var button := Button.new()
		button.text = choices[index]
		button.custom_minimum_size.y = 40
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(func() -> void: response_selected.emit(index))
		responses.add_child(button)
	show()

func focus_first_response() -> void:
	if responses.get_child_count() > 0: responses.get_child(0).grab_focus()
