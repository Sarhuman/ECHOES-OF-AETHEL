class_name AethelInventoryItemButton
extends Button
var view: AethelInventoryView
var uid := ""
var equipment_slot := ""
var _hover_point := Vector2.ZERO
var _hover_uid := ""
var _hover_token := -1

func _get_drag_data(at_position: Vector2) -> Variant:
	if uid.is_empty() or view == null: return null
	var data := {"owner":view.inventory.get_instance_id(),"uid":uid,"slot":equipment_slot,
		"token":Time.get_ticks_usec(),
		"source":"bag" if equipment_slot.is_empty() else "equipment",
		"anchor":Vector2i(at_position / float(view.SLOT_SIZE)) if equipment_slot.is_empty() else Vector2i.ZERO}
	var preview := Label.new()
	preview.text = "Mover: " + view.item_name(uid,equipment_slot)
	preview.add_theme_color_override("font_color",AethelUI.FOCUS)
	set_drag_preview(preview)
	view.tooltip.hide_item()
	return data

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if view == null or not view.accepts_payload(data): return false
	var point := at_position
	if not Rect2(Vector2.ZERO,size).has_point(point):
		point = get_global_transform().affine_inverse()*view.last_pointer
	if Rect2(Vector2.ZERO,size).has_point(point):
		_hover_point = point
		_hover_uid = str(data["uid"])
		_hover_token = int(data.get("token",-2))
	return _hover_uid == str(data["uid"]) and _hover_token == int(data.get("token",-2))

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position,data): return
	if not equipment_slot.is_empty(): view.equipment_drop_requested.emit(data,equipment_slot)
	else:
		var point := at_position
		# Native cursor coordinates can be unavailable on streamed/synthetic release.
		# Reuse only a valid local hover for this exact payload, never an arbitrary cell.
		if not Rect2(Vector2.ZERO,size).has_point(point):
			if _hover_uid != str(data["uid"]) or _hover_token != int(data.get("token",-2)): return
			point = _hover_point
		var local := view.grid_root.get_global_transform().affine_inverse() * (get_global_transform()*point)
		view.inventory_drop_requested.emit(data,Vector2i((local / float(view.SLOT_SIZE)).floor()) - data.get("anchor",Vector2i.ZERO))
	_hover_uid = ""
	_hover_token = -1

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_DELETE and not uid.is_empty() and equipment_slot.is_empty():
		view.discard_requested.emit(uid)
		accept_event()
		return
	if not uid.is_empty() and view.tooltip.visible:
		if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			view.tooltip.scroll_by(-100 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 100)
			accept_event()
		if event is InputEventKey and event.pressed and event.keycode in [KEY_PAGEUP,KEY_PAGEDOWN]:
			view.tooltip.scroll_by(-180 if event.keycode == KEY_PAGEUP else 180)
			accept_event()
	if not view.keyboard_payload.is_empty() and event is InputEventKey and event.pressed:
		if event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
			view.move_keyboard_cursor(event.keycode)
			accept_event()
	if event is InputEventKey and event.pressed and event.keycode == KEY_M and not uid.is_empty() and equipment_slot.is_empty():
		view.begin_keyboard_move(uid)
		accept_event()
