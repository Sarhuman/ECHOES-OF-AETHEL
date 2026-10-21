class_name AethelNPCController
extends Node
## Orchestrates existing world services; owns no inventory, currency or quest copy.
var world: Node3D
var definitions: Dictionary = {}
var dialogues: Dictionary = {}
var merchants: Dictionary = {}
var actors: Dictionary = {}
var choices: Dictionary = {}
var hub: Dictionary = {"doma": true}
var npc_states: Dictionary = {}
var visited: Array[String] = []
var reward_claimed := false
var view: AethelDialogueView
var active_id := ""
var node_id := ""
var options: Array[Dictionary] = []
var pending_id := ""
var approach_time := 0.0
var stalled := 0.0
var last_position := Vector3.ZERO
var last_hp := 0
var hovered := ""
const RANGE := 2.6

func setup(owner_world: Node3D) -> void:
	world = owner_world
	definitions = JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs.json"))
	dialogues = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogues.json"))
	merchants = JSON.parse_string(FileAccess.get_file_as_string("res://data/merchants.json"))
	actors = {"doma": world.merchant, "maera": world.npc}
	for id: String in actors:
		var actor: Node3D = actors[id]
		actor.set_meta("npc_id", id)
		var area := Area3D.new()
		area.name = "NPCPick"
		area.collision_layer = 64
		area.collision_mask = 0
		var shape := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.height = 2.1
		capsule.radius = 0.55
		shape.shape = capsule
		shape.position.y = 1.05
		area.add_child(shape)
		actor.add_child(area)
		var marker := Label3D.new()
		marker.name = "NPCIndicator"
		marker.text = definitions[id].name + (" ◇" if id == "maera" else " · E/F")
		marker.position.y = 2.65
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.font_size = 24
		marker.pixel_size = 0.007
		actor.add_child(marker)
	var canvas := CanvasLayer.new()
	canvas.layer = 4
	world.add_child(canvas)
	view = AethelDialogueView.new()
	view.position = Vector2(20,150)
	view.custom_minimum_size.x = 540
	canvas.add_child(view)
	view.hide()
	view.response_selected.connect(select_response)
	last_hp = world.player.hp

func available(id: String) -> bool:
	return actors.has(id) and actors[id].visible and npc_states.get(id,"available") == "available" and meets(definitions[id].availability)

func meets(conditions: Dictionary) -> bool:
	for key: String in conditions:
		var value: Variant = conditions[key]
		match key:
			"region":
				if world.region_id != value: return false
			"quest_started":
				if world.quest_started != value: return false
			"quest_completed":
				if world.quest_completed != value: return false
			"map_02_cleared":
				if world.map_02_cleared != value: return false
			"reward_claimed":
				if reward_claimed != value: return false
			"class":
				if String(world.player.class_id) != value: return false
			"act":
				if value != 1: return false # only Act I exists in this slice
			"attribute":
				if not value is Dictionary or not value.get("key","") in ["strength","dexterity","vitality","energy"]: return false
				if int(world.player.total_attribute(str(value.key))) < int(value.get("min",0)): return false
			"item":
				var found := false
				for row: Dictionary in world.inventory.entries():
					if String(row.instance.definition.item_id) == str(value): found = true
				for equipped: AethelItemInstance in world.player.equipped.values():
					if String(equipped.definition.item_id) == str(value): found = true
				if not found: return false
			"choice":
				if not value is Dictionary or choices.get(value.get("key","")) != value.get("value"): return false
			"service":
				if not hub.get(str(value),false): return false
			"corruption_min":
				if int(hub.get("corruption",0)) < int(value): return false
			"hub":
				if not value is Dictionary or hub.get(value.get("key","")) != value.get("value"): return false
			_: return false
	return true

func pick(screen: Vector2) -> String:
	# First hit includes terrain and enemies, so NPCs cannot be selected through walls.
	var hit: Dictionary = world._cursor_ray(screen,1 | 4 | 8 | 64,true)
	var collider: Node = hit.get("collider")
	while collider != null:
		if collider.has_meta("npc_id"):
			var id := str(collider.get_meta("npc_id"))
			return id if available(id) else ""
		collider = collider.get_parent()
	return ""

func request(id: String) -> bool:
	close()
	if world.game_over or not available(id): return false
	pending_id = id
	approach_time = 0
	stalled = 0
	last_position = world.player.global_position
	world.player.clear_commands()
	world.left_held = false
	world.pickup_target = null
	if world.player.global_position.distance_to(actors[id].global_position) <= RANGE and reachable(id):
		open_dialogue(id)
	else:
		world.player.command_move(actors[id].global_position)
	return true

func close() -> void:
	if not pending_id.is_empty(): world.player.clear_commands()
	pending_id = ""
	active_id = ""
	node_id = ""
	options.clear()
	if is_instance_valid(view): view.hide()
	world.player.interaction_input_locked = false

func tick(delta: float) -> void:
	world.player.interaction_input_locked = view.visible or world.shop_panel.visible
	var damaged: bool = world.player.hp < last_hp
	last_hp = world.player.hp
	if damaged or world.game_over or world.player.keyboard_active:
		close()
		world.shop_panel.hide()
	if not active_id.is_empty():
		if not available(active_id) or world.player.global_position.distance_to(actors[active_id].global_position) > RANGE + 0.5:
			close()
	if not pending_id.is_empty():
		if not available(pending_id) or is_instance_valid(world.player.attack_target):
			close()
		else:
			approach_time += delta
			if world.player.global_position.distance_to(last_position) < 0.003: stalled += delta
			else: stalled = 0
			last_position = world.player.global_position
			if world.player.global_position.distance_to(actors[pending_id].global_position) <= RANGE and reachable(pending_id):
				open_dialogue(pending_id)
			elif stalled > 1.5 or approach_time > 12:
				close()
				world._show_message("Caminho bloqueado. Aproxime-se por outro lado.")
	var next_hover: String = "" if world._mouse_over_ui(world.get_viewport().get_mouse_position()) else pick(world.get_viewport().get_mouse_position())
	if next_hover != hovered:
		hovered = next_hover
		for id: String in actors:
			var label: Label3D = actors[id].get_node("NPCIndicator")
			label.modulate = Color("f0d999") if hovered == id else Color("d3c3a3")

func open_dialogue(id: String) -> void:
	if not available(id) or not reachable(id) or world.player.global_position.distance_to(actors[id].global_position) > RANGE: return
	pending_id = ""
	active_id = id
	world.player.clear_commands()
	world.player.velocity = Vector3.ZERO
	world.player.keyboard_active = false
	world.player.interaction_input_locked = true
	var offset: Vector3 = actors[id].global_position - world.player.global_position
	offset.y = 0
	if offset.length() > 0.01: world.player.facing = offset.normalized()
	for panel in [world.shop_panel,world.character_panel,world.skills_panel,world.inventory_view]: panel.hide()
	show_node(str(definitions[id].dialogue))

func portrait_for(id: String, expression: String = "default") -> Texture2D:
	# Authored symbolic IDs only; never load resource paths supplied by save data.
	var config: Dictionary = definitions[id].portraits
	var token: String = str(config.get("expressions",{}).get(expression,config.get("states",{}).get(npc_states.get(id,"available"),config.get("acts",{}).get("1",config.get("default","fallback")))))
	match token:
		"doma": return preload("res://assets/npcs/doma.svg")
		"maera": return preload("res://assets/npcs/maera.svg")
		_: return preload("res://assets/ui/aethel_portal.svg")

func show_node(id: String) -> void:
	if not dialogues.has(id) or str(dialogues[id].speaker) != active_id:
		close()
		return
	node_id = id
	if not id in visited: visited.append(id)
	var data: Dictionary = dialogues[id]
	options.clear()
	var labels: Array[String] = []
	for response: Dictionary in data.responses:
		if meets(response.conditions):
			options.append(response)
			labels.append(str(response.text))
	view.present(str(definitions[active_id].name),str(data.text),labels,str(definitions[active_id].quest_indicator),portrait_for(active_id),"Enter: selecionar • Esc: encerrar")
	view.focus_first_response()

func select_response(index: int) -> void:
	if not view.visible or index < 0 or index >= options.size() or not available(active_id): return
	if not reachable(active_id) or world.player.global_position.distance_to(actors[active_id].global_position) > RANGE: close(); return
	var response: Dictionary = options[index]
	if not meets(response.conditions): show_node(node_id); return
	for effect: Dictionary in response.effects:
		if not str(effect.get("type","")) in ["shop","choice","start_investigation","finish_investigation"]: return
		if effect.type == "shop" and active_id != "doma": return
		if effect.type == "choice" and not str(effect.get("key","")) in ["doma_workshop"]: return
		if effect.type == "start_investigation" and active_id != "maera": return
		if effect.type == "finish_investigation" and (active_id != "maera" or not world.quest_started or not world.map_02_cleared or reward_claimed): return
	var wants_shop := false
	for effect: Dictionary in response.effects:
		match str(effect.type):
			"shop": wants_shop = true
			"choice": choices[str(effect.key)] = str(effect.value)
			"start_investigation": world.quest_started = true
			"finish_investigation":
				reward_claimed = true
				world.quest_completed = true
				world.gold += 60
				world._show_message("Investigação provisória concluída: +60 ouro")
	world._refresh_all()
	if bool(response.end): close()
	else: show_node(str(response.next))
	if wants_shop: world._try_open_shop()

func serialize() -> Dictionary:
	return {"choices": choices.duplicate(true),"hub":hub.duplicate(true),"npc_states":npc_states.duplicate(true),"visited":visited.duplicate(),"reward_claimed":reward_claimed}

func valid_state(data: Variant) -> bool:
	if not data is Dictionary: return false
	for key in ["choices","hub","npc_states"]:
		if not data.get(key,{}) is Dictionary: return false
	if not data.get("visited",[]) is Array or not data.get("reward_claimed",false) is bool: return false
	for id: Variant in data.get("visited",[]):
		if not id is String or not dialogues.has(id): return false
	for id: Variant in data.get("choices",{}):
		if id != "doma_workshop" or data.choices[id] != "remember": return false
	for id: Variant in data.get("hub",{}):
		if id == "doma":
			if not data.hub[id] is bool: return false
		elif id == "corruption":
			if not (data.hub[id] is int or data.hub[id] is float) or not is_finite(float(data.hub[id])): return false
		else: return false
	for id: Variant in data.get("npc_states",{}):
		if not definitions.has(id) or not data.npc_states[id] in ["available","unavailable"]: return false
	return true

func restore(data: Dictionary, legacy_completed: bool) -> void:
	close()
	choices = data.get("choices",{}).duplicate(true)
	hub = data.get("hub",{"doma":true}).duplicate(true)
	npc_states = data.get("npc_states",{}).duplicate(true)
	visited.clear()
	for id: String in data.get("visited",[]): visited.append(id)
	# Legacy completion never awards retroactive currency on load.
	reward_claimed = bool(data.get("reward_claimed",legacy_completed))

func reachable(id: String) -> bool:
	if not actors.has(id): return false
	var start: Vector3 = world.player.global_position + Vector3.UP
	var finish: Vector3 = actors[id].global_position + Vector3.UP
	var query := PhysicsRayQueryParameters3D.create(start,finish,1 | 8)
	var hit: Dictionary = world.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == actors[id]
