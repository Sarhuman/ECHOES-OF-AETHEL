class_name AethelInventoryView
extends Control
signal equip_requested(instance_id: String)
signal unequip_requested(slot: String)
signal discard_requested(instance_id: String)
signal sell_requested(instance_id: String)
signal inventory_drop_requested(payload: Dictionary, destination: Vector2i)
# Emitted by AethelInventoryItemButton through its owning view.
@warning_ignore("unused_signal")
signal equipment_drop_requested(payload: Dictionary, slot: String)
const SLOT_SIZE := 48
const SLOT_LABELS := {"cape":"Capa","weapon":"Arma principal","shield":"Mão secundária","helm":"Elmo","armor":"Peitoral","gloves":"Luvas","boots":"Botas","belt":"Cinto","ring1":"Anel 1","ring2":"Anel 2","amulet":"Amuleto","charm":"Talismã"}
var inventory: AethelInventoryManager
var player: Node
var grid_root: Control
var item_root: Control
var equip_root: Control
var info_label: Label
var tooltip: AethelItemTooltip
var gold_text := ""
var selected_uid := ""
var keyboard_payload: Dictionary = {}
var cells: Array[Button] = []
var _grid_dimensions := Vector2i.ZERO
var _keyboard_cell := Vector2i.ZERO
var _cursor: Panel
var last_pointer := Vector2.INF

func _input(event: InputEvent) -> void:
 if visible and event is InputEventMouse: last_pointer = event.position

func _ready() -> void:
 hide()
 mouse_filter = Control.MOUSE_FILTER_STOP
 set_anchors_preset(Control.PRESET_CENTER_RIGHT)
 offset_left = -780
 offset_right = -20
 offset_top = -240
 offset_bottom = 200
 var panel := Panel.new()
 add_child(panel)
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var title := Label.new()
 title.text = "MOCHILA · EQUIPAMENTOS"
 title.theme_type_variation = "AethelNPCName"
 title.position = Vector2(18,14)
 add_child(title)
 var close := Button.new()
 close.text = "Fechar [I]"
 close.position = Vector2(630,10)
 close.pressed.connect(func() -> void: hide())
 add_child(close)
 var discard := Button.new()
 discard.text = "Largar [Del]"
 discard.position = Vector2(500,10)
 discard.tooltip_text = "Largar a pilha selecionada no chão. Pode ser recolhida novamente."
 discard.pressed.connect(func() -> void:
  if not selected_uid.is_empty(): discard_requested.emit(selected_uid))
 add_child(discard)
 var sort := Button.new()
 sort.text = "Organizar"
 sort.position = Vector2(18,46)
 sort.pressed.connect(func() -> void:
  if inventory != null and not inventory.auto_sort():
   info_label.text = "Não foi possível organizar. Itens e posições foram preservados."
   flash_invalid())
 add_child(sort)
 var help := Label.new()
 help.text = "Arraste · Enter: equipar · M: mover · Esc: cancelar"
 help.add_theme_font_size_override("font_size",12)
 help.position = Vector2(160,58)
 add_child(help)
 var scroll := ScrollContainer.new()
 scroll.follow_focus = true
 scroll.position = Vector2(18,90)
 scroll.size = Vector2(480,200)
 add_child(scroll)
 grid_root = Control.new()
 scroll.add_child(grid_root)
 item_root = Control.new()
 item_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 grid_root.add_child(item_root)
 _cursor = Panel.new()
 _cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
 _cursor.add_theme_stylebox_override("panel",AethelUI.slot_style(0,"focus"))
 _cursor.size = Vector2.ONE*(SLOT_SIZE-2)
 grid_root.add_child(_cursor)
 _cursor.hide()
 equip_root = Control.new()
 equip_root.position = Vector2(514,50)
 equip_root.size = Vector2(232,350)
 add_child(equip_root)
 info_label = Label.new()
 info_label.position = Vector2(18,300)
 info_label.size = Vector2(480,120)
 info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 info_label.add_theme_font_size_override("font_size",14)
 add_child(info_label)
 tooltip = AethelItemTooltip.new()
 tooltip.requirement_source = player
 add_child(tooltip)
 visibility_changed.connect(func() -> void:
  keyboard_payload.clear()
  _cursor.hide()
  if not visible: tooltip.hide_item())

func bind_inventory(manager: AethelInventoryManager) -> void:
 inventory = manager
 if not manager.inventory_updated.is_connected(refresh): manager.inventory_updated.connect(refresh)
 refresh()

func bind_player(actor: Node) -> void:
 player = actor
 if tooltip != null: tooltip.requirement_source = actor

func accepts_payload(data: Variant) -> bool:
 if inventory == null or not data is Dictionary or data.get("owner") != inventory.get_instance_id(): return false
 if data.get("source") == "bag": return inventory.find_item(str(data.get("uid",""))) != null
 if data.get("source") == "equipment" and player != null:
  var item: AethelItemInstance = player.equipped.get(str(data.get("slot","")))
  return item != null and item.instance_id == str(data.get("uid",""))
 return false

func item_name(uid: String, slot: String = "") -> String:
 var item: AethelItemInstance = inventory.find_item(uid) if slot.is_empty() else player.equipped.get(slot)
 return item.display_name() if item != null else ""

func begin_keyboard_move(uid: String) -> void:
 keyboard_payload = {"owner":inventory.get_instance_id(),"uid":uid,"source":"bag","anchor":Vector2i.ZERO}
 info_label.text = "Escolha uma célula com Tab/setas e Enter. Esc cancela."
 _keyboard_cell = Vector2i.ZERO
 _cursor.position = Vector2.ZERO
 _cursor.show()
 grid_root.move_child(_cursor,grid_root.get_child_count()-1)
 if not cells.is_empty(): cells[0].grab_focus()

func move_keyboard_cursor(key: Key) -> void:
 var delta := {KEY_LEFT:Vector2i.LEFT,KEY_RIGHT:Vector2i.RIGHT,KEY_UP:Vector2i.UP,KEY_DOWN:Vector2i.DOWN}
 _keyboard_cell += delta[key]
 _keyboard_cell.x = clampi(_keyboard_cell.x,0,inventory.grid_width-1)
 _keyboard_cell.y = clampi(_keyboard_cell.y,0,inventory.grid_height-1)
 _cursor.position = Vector2(_keyboard_cell)*SLOT_SIZE
 cells[_keyboard_cell.y*inventory.grid_width+_keyboard_cell.x].grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
 if visible and event.is_action_pressed("ui_cancel") and not keyboard_payload.is_empty():
  keyboard_payload.clear()
  _cursor.hide()
  refresh()
  get_viewport().set_input_as_handled()

func _clear(parent: Node) -> void:
 for child in parent.get_children():
  parent.remove_child(child)
  child.queue_free()

func _build_cells() -> void:
 var dimensions := Vector2i(inventory.grid_width,inventory.grid_height)
 if dimensions == _grid_dimensions: return
 for cell in cells:
  grid_root.remove_child(cell)
  cell.queue_free()
 cells.clear()
 _grid_dimensions = dimensions
 grid_root.custom_minimum_size = Vector2(dimensions)*SLOT_SIZE
 grid_root.size = grid_root.custom_minimum_size
 item_root.size = grid_root.size
 for y in dimensions.y:
  for x in dimensions.x:
   var button := AethelInventoryItemButton.new()
   button.view = self
   button.position = Vector2(x,y)*SLOT_SIZE
   button.size = Vector2.ONE*(SLOT_SIZE-2)
   button.add_theme_stylebox_override("normal",AethelUI.slot_style(0,"normal"))
   var cell := Vector2i(x,y)
   button.tooltip_text = "Célula %d, %d" % [x+1,y+1]
   button.pressed.connect(func() -> void:
    if not keyboard_payload.is_empty():
     var payload := keyboard_payload.duplicate()
     keyboard_payload.clear()
     _cursor.hide()
     inventory_drop_requested.emit(payload,cell))
   grid_root.add_child(button)
   grid_root.move_child(button,0)
   cells.append(button)

func _show_item(item: AethelItemInstance, button: Control, _keyboard: bool) -> void:
 selected_uid = item.instance_id
 tooltip.show_item_at(item,button.get_global_rect())
 if player != null and inventory.find_item(item.instance_id) != null and item.definition.kind == "equipment":
  var slot: String = player.slot_for(item)
  var equipped: AethelItemInstance = player.equipped.get(slot)
  tooltip.append_comparison(item,equipped)

func _attach_tooltip(button: Control, item: AethelItemInstance) -> void:
 button.mouse_entered.connect(func() -> void: _show_item(item,button,false))
 button.mouse_exited.connect(func() -> void:
  if not button.has_focus(): tooltip.hide_item())
 button.focus_entered.connect(func() -> void: _show_item(item,button,true))
 button.focus_exited.connect(tooltip.hide_item)

func refresh() -> void:
 if item_root == null or inventory == null: return
 tooltip.hide_item()
 _build_cells()
 _clear(item_root)
 for entry: Dictionary in inventory.entries():
  var item: AethelItemInstance = entry["instance"]
  var button := AethelInventoryItemButton.new()
  button.view = self
  button.uid = item.instance_id
  button.clip_contents = true
  button.position = Vector2(entry["origin"])*SLOT_SIZE
  button.size = Vector2(item.definition.width,item.definition.height)*SLOT_SIZE-Vector2(2,2)
  AethelUI.style_slot(button,item.get_quality())
  var icon := TextureRect.new()
  icon.texture = item.definition.icon
  icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.position = Vector2(4,3)
  icon.size = Vector2(button.size.x-8,button.size.y-20)
  icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
  button.add_child(icon)
  var name_label := Label.new()
  name_label.text = item.display_name()
  name_label.position = Vector2(3,button.size.y-18)
  name_label.size = Vector2(button.size.x-6,16)
  name_label.clip_text = true
  name_label.add_theme_font_size_override("font_size",11)
  name_label.add_theme_color_override("font_color",AethelUI.RARITY_TEXT[item.get_quality()])
  name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  button.add_child(name_label)
  if item.definition.max_stack > 1:
   var count := Label.new()
   count.text = "×%d" % item.quantity
   count.add_theme_font_size_override("font_size",12)
   count.position = Vector2(3,0)
   count.mouse_filter = Control.MOUSE_FILTER_IGNORE
   button.add_child(count)
  var uid := item.instance_id
  button.pressed.connect(func() -> void: equip_requested.emit(uid))
  button.gui_input.connect(func(event: InputEvent) -> void:
   if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT: sell_requested.emit(uid))
  _attach_tooltip(button,item)
  item_root.add_child(button)
 _refresh_equipment()
 info_label.text = "%s · %d / %d células\nEnter: equipar / retirar · Del: largar no chão · Direito: vender\nM + célula: mover / trocar · Organizar: ordenar sem perder itens" % [gold_text,inventory.occupied_count(),inventory.grid_width*inventory.grid_height]
 if player != null: info_label.text += "\nDano %.1f–%.1f · Defesa %d · Bloqueio %.0f%%" % [player.damage_min,player.damage_max,player.defense,player.block_chance]

func _refresh_equipment() -> void:
 _clear(equip_root)
 if player == null: return
 for index in player.SLOT_ORDER.size():
  var slot: String = player.SLOT_ORDER[index]
  var item: AethelItemInstance = player.equipped.get(slot)
  var button := AethelInventoryItemButton.new()
  button.view = self
  button.equipment_slot = slot
  button.position = Vector2(0,index*29)
  button.size = Vector2(232,27)
  button.add_theme_font_size_override("font_size",12)
  button.alignment = HORIZONTAL_ALIGNMENT_LEFT
  button.clip_text = true
  button.text = SLOT_LABELS[slot] + ": —"
  if item != null:
   button.uid = item.instance_id
   button.text = "✓ " + SLOT_LABELS[slot] + ": " + item.display_name()
   button.icon = item.definition.icon
   button.expand_icon = true
   button.add_theme_constant_override("icon_max_width",20)
   AethelUI.style_slot(button,item.get_quality())
   _attach_tooltip(button,item)
  button.pressed.connect(func() -> void: unequip_requested.emit(slot))
  equip_root.add_child(button)

func flash_invalid() -> void:
 if not is_inside_tree(): return
 modulate = AethelUI.INVALID
 create_tween().tween_property(self,"modulate",Color.WHITE,0.16)
