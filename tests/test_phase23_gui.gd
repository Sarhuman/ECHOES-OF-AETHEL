extends SceneTree
var failures: Array[String] = []
var checks := 0
var world: Node

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func frames(count: int = 2) -> void:
	for index in count: await process_frame

func motion(point: Vector2, previous: Vector2, held: bool) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.relative = point-previous
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	Input.parse_input_event(event)
	await frames()

func button(point: Vector2, pressed: bool) -> void:
	# Keep cursor update and release in the same dispatch, before OS cursor polling.
	var pointer := InputEventMouseMotion.new()
	pointer.position = point
	pointer.global_position = point
	pointer.button_mask = MOUSE_BUTTON_MASK_LEFT if not pressed else 0
	Input.parse_input_event(pointer)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	event.global_position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(event)
	await frames()

func drag(from: Vector2, to: Vector2) -> void:
	await motion(from,from,false)
	await button(from,true)
	await motion(from+Vector2(18,0),from,true)
	await motion(to,from+Vector2(18,0),true)
	check(root.gui_is_dragging(),"native drag started")
	await button(to,false)
	await frames(3)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames()

func cell(point: Vector2i) -> Vector2:
	return world.inventory_view.grid_root.global_position + Vector2(point)*48 + Vector2(8,8)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	Input.use_accumulated_input = false
	root.size = Vector2i(1280,720)
	Engine.set_meta("aethel_new_game",true)
	world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await frames(3)
	var view: AethelInventoryView = world.inventory_view
	var bag: AethelInventoryManager = world.inventory
	await key(KEY_I)
	check(view.visible,"I opens inventory")
	var ring := AethelItemInstance.new(world.item_catalog["plain_ring"],"gui-ring")
	var potion := AethelItemInstance.new(world.item_catalog["hp_small"],"gui-stack")
	potion.quantity = 4
	bag.place_item(ring,Vector2i.ZERO)
	bag.place_item(potion,Vector2i(1,0))
	await frames(3)
	await drag(cell(Vector2i.ZERO),cell(Vector2i(3,0)))
	check(bag.item_at(Vector2i(3,0)) == "gui-ring","native drag moves real item")
	await drag(cell(Vector2i(3,0)),cell(Vector2i(1,0)))
	check(bag.item_at(Vector2i(1,0)) == "gui-ring" and bag.item_at(Vector2i(3,0)) == "gui-stack","native drag swaps real items")
	var before := JSON.stringify(bag.serialize())
	await drag(cell(Vector2i(1,0)),Vector2(160,100))
	check(JSON.stringify(bag.serialize()) == before,"outside drop retains origin")
	var slot: Button = view.equip_root.get_child(world.player.SLOT_ORDER.find("ring2"))
	await drag(cell(Vector2i(1,0)),slot.get_global_rect().get_center())
	check(world.player.equipped.get("ring2") == ring and bag.find_item("gui-ring") == null,"drag equips exact ring slot")
	slot = view.equip_root.get_child(world.player.SLOT_ORDER.find("ring2"))
	await drag(slot.get_global_rect().get_center(),cell(Vector2i(5,0)))
	check(not world.player.equipped.has("ring2") and bag.item_at(Vector2i(5,0)) == "gui-ring","drag unequips into exact free cell")
	before = JSON.stringify(bag.serialize())
	slot = view.equip_root.get_child(world.player.SLOT_ORDER.find("helm"))
	await drag(cell(Vector2i(3,0)),slot.get_global_rect().get_center())
	check(JSON.stringify(bag.serialize()) == before and potion.quantity == 4,"potion rejected by equipment slot atomically")
	view.begin_keyboard_move("gui-ring")
	await key(KEY_DOWN)
	await key(KEY_ENTER)
	check(bag.item_at(Vector2i(0,1)) == "gui-ring","keyboard move commits through manager")
	view.begin_keyboard_move("gui-ring")
	before = JSON.stringify(bag.serialize())
	await key(KEY_ESCAPE)
	check(view.keyboard_payload.is_empty() and JSON.stringify(bag.serialize()) == before and not paused,"Esc cancels move without opening pause")
	var axe := AethelItemInstance.new(world.item_catalog["hand_axe"],"gui-large")
	bag.place_item(axe,Vector2i(6,0))
	await frames()
	await drag(cell(Vector2i(7,1)),cell(Vector2i(9,2)))
	check(bag._items["gui-large"]["origin"] == Vector2i(8,1),"multicell drag preserves grab anchor and fits bounds")
	await key(KEY_I)
	check(not view.visible,"I closes inventory")
	await key(KEY_I)
	check(view.visible,"I reopens inventory")
	print("PHASE23 GUI: %d checks, %d failures" % [checks,failures.size()])
	for failure in failures: printerr("FALHA: ",failure)
	quit(0 if failures.is_empty() else 1)
