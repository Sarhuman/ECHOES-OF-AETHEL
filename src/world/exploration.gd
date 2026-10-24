class_name AethelExploration
extends Node
## World coordination only: existing inventory, Player stats, loot and save remain authoritative.
signal effect_changed(id: String,remaining: float,intensity: float)
var _effect_display := -1
const ENEMY_DAMAGE_TRAVEL_LOCK_MS := 5000
var last_enemy_damage_ms: int = -1
var world: Node3D
var data: Dictionary
var objects: Dictionary = {}
var used: Dictionary = {}
var killed: Dictionary = {}
var anchors: Array[String] = []
var buffs: Dictionary = {}
var pending := ""
var approach_time := 0.0
var last_position := Vector3.ZERO
var stalled := 0.0
var loot_canvas: CanvasLayer
var canvas: CanvasLayer
var filter_panel: PanelContainer
var travel_panel: PanelContainer
var effect_label: Label
var audio: AethelAudioManager
var object_labels: Dictionary={}
var labels: Dictionary = {}
var sound_clock := 0.0
var priority_sound_clock := 0.0
const NAMES := {"chest":"Baú","barrel":"Barril","urn":"Urna","remains":"Restos abandonados","tomb":"Túmulo","altar":"Altar de Ardósia","well":"Poço","anchor":"Âncora de Travessia","door":"Porta de bronze","lore":"Vestígio"}

func setup(owner_world: Node3D) -> void:
	world = owner_world
	world.player.enemy_damage_received.connect(_on_enemy_damage_received)
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/exploration.json"))
	loot_canvas = CanvasLayer.new()
	loot_canvas.layer = 2
	world.add_child(loot_canvas)
	canvas = CanvasLayer.new()
	canvas.layer = 3
	world.add_child(canvas)
	audio = world.audio
	for definition: Dictionary in data.objects:
		var actor := Area3D.new()
		actor.name = definition.id
		actor.set_meta("object_id",definition.id)
		actor.collision_layer = 128
		actor.collision_mask = 0
		world.add_child(actor)
		actor.position = point(definition.position)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.0,1.5,1.0)
		shape.shape = box
		shape.position.y = 0.6
		actor.add_child(shape)
		build_visual(actor,definition)
		if definition.kind=="door":
			var body := StaticBody3D.new()
			body.name="DoorBody"
			actor.add_child(body)
			var collision := CollisionShape3D.new()
			var door_shape := BoxShape3D.new()
			door_shape.size=Vector3(7.8,2.4,0.2)
			collision.shape=door_shape
			collision.position.y=1.2
			body.add_child(collision)
			world._box(actor,Vector3(0,1.2,0),Vector3(7.8,2.4,0.18),Color("655236"),false)
		objects[str(definition.id)] = actor
	build_ui()
	update_region()

func point(values: Array) -> Vector3:
	return Vector3(float(values[0]),float(values[1]),float(values[2]))

func definition_for(id: String) -> Dictionary:
	for row: Dictionary in data.objects:
		if row.id == id: return row
	return {}

func build_visual(actor: Node3D, definition: Dictionary) -> void:
	var color := Color("5c4f3c")
	var size := Vector3(0.95,0.65,0.65)
	match str(definition.kind):
		"altar": size = Vector3(0.7,1.1,0.7); color = Color("666373")
		"well": size = Vector3(1.2,0.55,1.2); color = Color("3d6670")
		"anchor": size = Vector3(0.8,0.2,0.8); color = Color("4850b8")
		"urn": size = Vector3(0.4,0.9,0.4)
		"barrel": size = Vector3(0.6,0.8,0.6)
		"remains": size = Vector3(0.5,0.15,1.2); color = Color("918371")
		"tomb": size = Vector3(0.7,0.4,1.25); color = Color("666373")
	world._box(actor,Vector3(0,size.y/2,0),size,color,false)
	world._box(actor,Vector3(0,size.y+0.05,0),Vector3(size.x+0.1,0.09,size.z+0.1),Color("b8a058"),false)
	var title := Label3D.new()
	title.name = "Title"
	title.text = NAMES[str(definition.kind)] + (" especial" if definition.get("table","") == "special_chest" else "")
	title.position.y = size.y+0.7
	title.font_size = 22
	title.pixel_size = 0.007
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	actor.add_child(title)

func build_ui() -> void:
	effect_label = Label.new()
	effect_label.position = Vector2(20,280)
	effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(effect_label)
	filter_panel = PanelContainer.new()
	filter_panel.position = Vector2(1000,90)
	canvas.add_child(filter_panel)
	var column := VBoxContainer.new()
	filter_panel.add_child(column)
	var title := Label.new()
	title.text = "Filtro de loot · O"
	column.add_child(title)
	for key: String in AethelSettings.loot_filters:
		var check := CheckButton.new()
		check.text = {"common":"Comum","magic":"Mágico","rare":"Raro","epic":"Épico","legendary":"Lendário","gold":"Ouro","consumable":"Consumíveis","material":"Materiais"}[key]
		check.button_pressed = bool(AethelSettings.loot_filters[key])
		check.toggled.connect(func(value: bool) -> void:
			AethelSettings.loot_filters[key] = value
			AethelSettings.save_settings())
		column.add_child(check)
	filter_panel.hide()
	travel_panel = PanelContainer.new()
	travel_panel.position = Vector2(460,140)
	canvas.add_child(travel_panel)
	travel_panel.hide()
	travel_panel.visibility_changed.connect(_sync_travel_input_lock)

func blocks_ui(screen: Vector2) -> bool:
	return (filter_panel.visible and filter_panel.get_global_rect().has_point(screen)) or travel_panel.visible

func update_region() -> void:
	pending = ""
	travel_panel.hide()
	for id: String in objects:
		var actor: Area3D = objects[id]
		actor.visible = definition_for(id).region == world.region_id
		actor.collision_layer = 128 if actor.visible else 0
		if definition_for(id).kind=="door" and used.has(id): actor.hide(); actor.collision_layer=0
		if definition_for(id).kind=="door":
			actor.get_node("DoorBody").collision_layer=1 if actor.visible else 0
			world.regions.level.set_archive_door(used.has(id))
	refresh_objects()

func refresh_objects() -> void:
	for id: String in objects:
		var row := definition_for(id)
		var title: Label3D = objects[id].get_node("Title")
		var suffix := ""
		if row.kind == "anchor": suffix = " ✓" if id in anchors else " · descobrir"
		elif int(used.get(id,0)) >= int(row.get("uses",1)): suffix = " · esgotado" if row.kind in ["altar","well"] else " · aberto"
		title.text = str(NAMES[str(row.kind)]) + (" especial" if row.get("table","") == "special_chest" else "") + suffix
		title.modulate = Color("9a968c") if not suffix.is_empty() and not row.kind == "anchor" else AethelUI.TEXT

func pick(screen: Vector2) -> String:
	var hit: Dictionary = world._cursor_ray(screen,1 | 4 | 8 | 64 | 128,true)
	var actor: Node = hit.get("collider")
	if actor != null and actor.has_meta("object_id") and actor.visible: return str(actor.get_meta("object_id"))
	return ""

func reachable(actor: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(world.player.global_position+Vector3.UP,actor.global_position+Vector3(0,0.5,0),1 | 8)
	if actor.has_node("DoorBody"): query.exclude=[actor.get_node("DoorBody").get_rid()]
	return world.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func request(id: String) -> bool:
	if not objects.has(id) or not objects[id].visible or world.game_over: return false
	world.narrative.close()
	pending = id
	world.player.clear_commands()
	world.pickup_target = null
	world.left_held = false
	approach_time = 0
	stalled = 0
	last_position = world.player.global_position
	if world.player.global_position.distance_to(objects[id].global_position) <= 2.5: return activate(id)
	var destination: Vector3=objects[id].global_position
	if definition_for(id).kind=="door": destination+=Vector3(0,0,2)
	world.player.command_move(destination)
	return true

func activate(id: String) -> bool:
	pending = ""
	if not objects.has(id) or not objects[id].visible or world.game_over: return false
	if world.player.global_position.distance_to(objects[id].global_position) > 2.5:
		if definition_for(id).kind == "anchor": world._show_message("Aproxime-se da âncora para viajar")
		return false
	if not reachable(objects[id]):
		if definition_for(id).kind == "anchor": world._show_message("O caminho até a âncora está obstruído")
		return false
	var row := definition_for(id)
	world.player.clear_commands()
	var offset: Vector3 = objects[id].global_position-world.player.global_position
	if offset.length() > 0.01: world.player.facing = offset.normalized()
	if row.kind == "lore":
		used[id]=1
		world.regions.known_pois[id]=true
		world._show_message(str(row.get("text","Um registro aguarda interpretação.")))
		return true
	if row.kind == "door":
		used[id]=1
		world.regions.opened_doors[id]=true
		objects[id].get_node("DoorBody").collision_layer=0
		world.regions.level.set_archive_door(true)
		objects[id].hide()
		objects[id].collision_layer=0
		world._show_message("Porta aberta")
		return true
	if row.kind == "anchor":
		if not id in anchors: anchors.append(id)
		feedback(objects[id].global_position,"Travessia descoberta","anchor")
		refresh_objects()
		open_travel(id)
		return true
	if int(used.get(id,0)) >= int(row.get("uses",1)):
		world._show_message("Este objeto já foi utilizado")
		return false
	if row.has("requires_encounter") and not encounter_complete(str(row.requires_encounter)):
		world._show_message("Derrote os guardiões do baú primeiro")
		return false
	# Confirm source consumption before publishing any rewards; all rewards remain on the ground until collected.
	used[id] = int(used.get(id,0))+1
	match str(row.kind):
		"altar":
			buffs = {"remaining":float(row.duration),"reduction":float(row.reduction),"source":id}
			apply_buffs()
			feedback(objects[id].global_position,"Resistência temporária","altar")
		"well":
			world.player.drink_potion(roundi(world.player.max_hp*float(row.life)),roundi(world.player.max_ether*float(row.ether)))
			world.player.stamina = minf(world.player.max_stamina,world.player.stamina+world.player.max_stamina*float(row.stamina))
			world.player.stamina_changed.emit(world.player.stamina,world.player.max_stamina)
			feedback(objects[id].global_position,"Recursos restaurados","well")
		_:
			spawn_rewards(id,{"id":id,"level":2,"rank":0,"region":row.region,"difficulty":"test","table":row.table,"magic_find":world.player.magic_find},objects[id].global_position)
			feedback(objects[id].global_position,"Contêiner aberto","chest")
			var tween: Tween = objects[id].create_tween()
			tween.tween_property(objects[id],"rotation:y",0.15,0.15)
	refresh_objects()
	return true

func _on_enemy_damage_received(_amount: int) -> void:
	last_enemy_damage_ms = Time.get_ticks_msec()
	if travel_panel != null and travel_panel.visible: _reject_combat_travel()

func recent_enemy_damage_active() -> bool:
	return last_enemy_damage_ms >= 0 and Time.get_ticks_msec() - last_enemy_damage_ms < ENEMY_DAMAGE_TRAVEL_LOCK_MS

func travel_combat_active() -> bool:
	if recent_enemy_damage_active(): return true
	for enemy in world.enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.hp <= 0: continue
		if enemy.target == world.player and (enemy.ai_state in [&"chase", &"search", &"attack"] or enemy.windup_active or (enemy.ai_state == &"hit" and enemy.search_remaining > 0.0)): return true
	return false

func _sync_travel_input_lock() -> void:
	var dialogue_open: bool = world.narrative != null and world.narrative.view.visible
	var shop_open: bool = world.shop_panel != null and world.shop_panel.visible
	world.player.interaction_input_locked = travel_panel.visible or dialogue_open or shop_open

func close_travel() -> void:
	travel_panel.hide()
	_sync_travel_input_lock()

func _reject_combat_travel() -> bool:
	if not travel_combat_active(): return false
	close_travel()
	world._show_message("Travessia indisponível durante combate")
	return true

func open_travel(source: String) -> void:
	if world.game_over or _reject_combat_travel(): return
	world.player.clear_commands()
	world.left_held = false
	world.hold_mode = ""
	for child in travel_panel.get_children(): travel_panel.remove_child(child); child.queue_free()
	var column := VBoxContainer.new()
	travel_panel.add_child(column)
	var title := Label.new()
	title.text = "Âncoras de Travessia · destinos descobertos"
	column.add_child(title)
	if not anchors.any(func(id: String) -> bool: return id != source):
		var empty := Label.new()
		empty.text = "Nenhum outro destino descoberto. Explore e ative outra âncora."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size.x = 340
		column.add_child(empty)
	for id: String in anchors:
		if id == source: continue
		var button := Button.new()
		button.text = str(world.regions.definitions[definition_for(id).region].name)
		button.pressed.connect(func() -> void: travel(source,id))
		column.add_child(button)
	var close := Button.new()
	close.text = "Fechar"
	close.pressed.connect(close_travel)
	column.add_child(close)
	travel_panel.show()
	world.player.interaction_input_locked = true
	world.player.keyboard_active = false
	close.grab_focus()

func _travel_unavailable(reason: String) -> bool:
	world._show_message(reason)
	return false

func travel(source: String,destination: String) -> bool:
	if _reject_combat_travel(): return false
	if not source in anchors or not destination in anchors or not objects.has(source) or not objects.has(destination):
		return _travel_unavailable("Descubra as âncoras de origem e destino antes de viajar")
	if world.game_over: return _travel_unavailable("Não é possível viajar após a derrota")
	if not objects[source].visible: return _travel_unavailable("A âncora de origem não está nesta região")
	if world.player.global_position.distance_to(objects[source].global_position) > 2.5:
		return _travel_unavailable("Aproxime-se da âncora para viajar")
	if not reachable(objects[source]): return _travel_unavailable("O caminho até a âncora está obstruído")
	if definition_for(destination).region == "map_02" and not world.quest_started:
		return _travel_unavailable("Converse com Maera para liberar a travessia ao Bairro")
	if not world.regions.move_to(str(definition_for(destination).region),objects[destination].position+Vector3(0,0,1.4)):
		return _travel_unavailable("Aguarde a travessia atual terminar" if world.regions.transitioning else "Não foi possível acessar o destino")
	feedback(world.player.position,"Travessia concluída","anchor")
	return true

func build_encounters() -> void:
	for group: Dictionary in data.encounters:
		if bool(world.regions.definitions[world.region_id].safe): return
		if world.enemies.size()>=int(world.regions.definitions[world.region_id].enemy_limit): return
		if group.region != world.region_id or (bool(group.get("quest_required",false)) and not world.quest_started): continue
		# Test fixtures can enter the slice directly; real portal access is quest gated.
		for member: Dictionary in group.members:
			if killed.has(str(member.id)) or member.get("type","") != "rasura": continue
			var enemy: CharacterBody3D = world._spawn_enemy(point(member.position),int(member.level),int(member.rank))
			enemy.set_meta("encounter_id",str(group.id))
			enemy.set_meta("spawn_id",str(member.id))
			enemy.set_meta("loot_table",str(member.table))
			enemy.set_meta("reward_scale",float(group.get("reward_scale",1.0)))
			enemy.set_meta("leader_id",str(member.get("leader","")))
			enemy.monster_name = str(member.get("name","Rasura"))
			enemy.max_hp = maxi(1,roundi(enemy.max_hp*float(member.get("health_scale",1))))
			enemy.hp = enemy.max_hp
			enemy.configure_modifiers(member.modifiers,data.modifier_definitions)

func encounter_complete(id: String) -> bool:
	for group: Dictionary in data.encounters:
		if group.id != id: continue
		for member: Dictionary in group.members:
			if not killed.has(str(member.id)): return false
		return true
	return false

func defeat(enemy: CharacterBody3D) -> bool:
	var id := str(enemy.get_meta("spawn_id",""))
	if not id.is_empty():
		if killed.has(id): return false
		killed[id] = true
	var context := {"id":id if not id.is_empty() else "runtime","level":enemy.level,"rank":enemy.rank,"region":world.region_id,"difficulty":"test","table":str(enemy.get_meta("loot_table",["normal","champion","elite"][enemy.rank])),"magic_find":world.player.magic_find,"reward_scale":float(enemy.get_meta("reward_scale",1.0))}
	spawn_rewards(id,context,enemy.global_position)
	feedback(enemy.global_position,"Elite derrotada" if enemy.rank == 2 else "Rasura desfeita","elite" if enemy.rank == 2 else "death")
	return true

func spawn_rewards(id: String,context: Dictionary,position: Vector3) -> void:
	# Stable sources have an isolated deterministic seed; unrelated drop calls cannot reroll them.
	var generator: AethelLootGenerator = world.loot_generator
	var previous: int = generator.rng.state
	if not id.is_empty(): generator.set_seed(absi(("aethel25:"+id).hash()))
	var rewards: Array = generator.roll_rewards(context)
	for entry: Dictionary in rewards: world._spawn_drop(entry,position)
	if not id.is_empty(): generator.rng.state = previous

func visible_drop(drop: AethelDroppedItem) -> bool:
	if str(drop.get_meta("region","")) != world.region_id: return false
	var filters: Dictionary = AethelSettings.loot_filters
	if drop.is_gold(): return bool(filters.gold)
	if drop.item == null: return false
	if drop.item.definition.is_potion(): return bool(filters.consumable)
	if drop.item.definition.kind == "material": return bool(filters.material)
	return bool(filters[["common","magic","rare","epic","legendary"][clampi(drop.item.get_quality(),0,4)]])

func present_drops(alt: bool) -> void:
	var placed: Array[Rect2] = []
	var camera: Camera3D = world.get_viewport().get_camera_3d()
	for drop: AethelDroppedItem in world.dropped_items:
		if not is_instance_valid(drop) or drop.is_queued_for_deletion(): continue
		var id: int = drop.get_instance_id()
		if not labels.has(id):
			var new_label := Label.new()
			new_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			new_label.add_theme_font_size_override("font_size",14)
			loot_canvas.add_child(new_label)
			labels[id] = {"label":new_label,"drop":drop}
		var label: Label = labels[id].label
		var display: bool = visible_drop(drop)
		drop.visible = display
		drop.label.hide()
		label.visible = display and (alt or drop.time_alive < 4 or drop.default_label_visible() or world.hovered_drop == drop)
		if not label.visible: continue
		label.text = drop.display_text()
		label.add_theme_color_override("font_color",drop.accent_color())
		label.add_theme_color_override("font_outline_color",Color("0b0a08"))
		label.add_theme_constant_override("outline_size",4)
		label.size = label.get_minimum_size()
		var screen: Vector2 = camera.unproject_position(drop.global_position+Vector3(0,0.5,0))
		if not Rect2(Vector2.ZERO,Vector2(1280,720)).has_point(screen) or camera.is_position_behind(drop.global_position):
			label.hide()
			continue
		var base := Vector2(clampf(screen.x-label.size.x/2,4,1280-label.size.x-4),clampf(screen.y,140,510-label.size.y))
		if filter_panel.visible and filter_panel.get_global_rect().intersects(Rect2(base,label.size)):
			base.x = maxf(4,filter_panel.position.x-label.size.x-12)
		var found := false
		var rect := Rect2(base,label.size)
		for attempt in range(34):
			var offset: float = ceili(attempt/2.0)*23.0 * (-1 if attempt%2 else 1)
			var candidate := Rect2(base+Vector2(0,offset),label.size)
			if candidate.position.y < 140 or candidate.end.y > 520: continue
			var overlaps := false
			for other: Rect2 in placed:
				if candidate.intersects(other.grow(2)): overlaps = true; break
			if overlaps: continue
			rect = candidate
			found = true
			break
		if not found:
			label.hide()
			continue
		label.position = rect.position
		drop.set_meta("label_rect",rect)
		placed.append(rect)
	for id: int in labels.keys():
		if not is_instance_valid(labels[id].drop) or labels[id].drop.is_queued_for_deletion():
			labels[id].label.queue_free()
			labels.erase(id)

func apply_buffs() -> void:
	var seconds: int = ceili(float(buffs.get("remaining",0)))
	if seconds != _effect_display:
		_effect_display = seconds
		effect_changed.emit("altar",float(buffs.get("remaining",0)),float(buffs.get("reduction",0)))
	world.player.exploration_reduction = float(buffs.get("reduction",0)) if float(buffs.get("remaining",0)) > 0 else 0.0

func tick(delta: float) -> void:
	if travel_panel.visible: _reject_combat_travel()
	_sync_travel_input_lock()
	sound_clock = maxf(0,sound_clock-delta)
	priority_sound_clock = maxf(0,priority_sound_clock-delta)
	if float(buffs.get("remaining",0)) > 0:
		buffs.remaining = maxf(0,float(buffs.remaining)-delta)
		apply_buffs()
	effect_label.visible=world.dropped_items.any(func(drop: AethelDroppedItem) -> bool: return is_instance_valid(drop) and not drop.is_queued_for_deletion() and visible_drop(drop))
	effect_label.text = "Altar de Ardósia: resistência %ds · O: filtro de loot" % ceili(float(buffs.remaining)) if float(buffs.get("remaining",0)) > 0 else "O: filtro de loot"
	if not pending.is_empty():
		if world.game_over or world.player.keyboard_active or is_instance_valid(world.player.attack_target): pending = ""
		else:
			approach_time += delta
			stalled = stalled+delta if world.player.global_position.distance_to(last_position) < 0.003 else 0.0
			last_position = world.player.global_position
			if world.player.global_position.distance_to(objects[pending].global_position) <= 2.5: activate(pending)
			elif stalled > 1.5 or approach_time > 12:
				pending = ""
				world.player.clear_commands()
				world._show_message("Caminho bloqueado até o objeto")
	if travel_panel.visible and world.player.keyboard_active: travel_panel.hide()

func feedback(position: Vector3,text: String,kind: String) -> void:
	if not text.is_empty(): world._on_combat_event(position+Vector3(0,1,0),text,"buff")
	if kind in ["rare","elite","anchor"]:
		if priority_sound_clock > 0: return
		priority_sound_clock = 0.4
	elif sound_clock > 0: return
	sound_clock = 0.12
	audio.play_cue(kind)

func serialize() -> Dictionary:
	var drops: Array = []
	for drop: AethelDroppedItem in world.dropped_items:
		if not is_instance_valid(drop) or drop.is_queued_for_deletion(): continue
		drops.append({"id":drop.drop_id,"region":str(drop.get_meta("region")),"position":[drop.position.x,drop.position.y,drop.position.z],"gold":drop.gold_amount,"item":drop.item.serialize() if drop.item != null else {}})
	return {"used":used.duplicate(),"killed":killed.duplicate(),"anchors":anchors.duplicate(),"buffs":buffs.duplicate(),"drops":drops}

func valid_state(payload: Variant) -> bool:
	if not payload is Dictionary: return false
	for key in ["used","killed","buffs"]:
		if not payload.get(key,{}) is Dictionary: return false
	for key in ["anchors","drops"]:
		if not payload.get(key,[]) is Array: return false
	for id: Variant in payload.get("used",{}):
		var row := definition_for(str(id))
		var count: Variant = payload.used[id]
		if row.is_empty() or not (count is int or count is float) or not is_finite(float(count)) or float(count) != floorf(float(count)) or count < 0 or count > int(row.get("uses",1)): return false
	var enemy_ids: Dictionary = {}
	for group: Dictionary in data.encounters:
		for member: Dictionary in group.members: enemy_ids[str(member.id)] = true
	for id: Variant in payload.get("killed",{}):
		if not enemy_ids.has(str(id)) or payload.killed[id] != true: return false
	for id: Variant in payload.get("anchors",[]):
		if not id is String or definition_for(id).get("kind","") != "anchor": return false
	var effects: Dictionary = payload.get("buffs",{})
	if not effects.is_empty():
		if effects.get("source","") != "district_altar": return false
		for key in ["remaining","reduction"]:
			if not (effects.get(key) is int or effects.get(key) is float) or not is_finite(float(effects[key])): return false
		if effects.remaining < 0 or effects.remaining > 30 or effects.reduction != 0.2: return false
	var ids: Dictionary = {}
	var item_ids: Dictionary = {}
	for row: Variant in payload.get("drops",[]):
		if not row is Dictionary or not row.get("id") is String or row.id.is_empty() or ids.has(row.id): return false
		ids[row.id] = true
		if not world.regions.definitions.has(str(row.get("region",""))) or not row.get("position") is Array or row.position.size() != 3: return false
		for coordinate: Variant in row.position:
			if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)) or absf(float(coordinate)) > 20: return false
		if not (row.get("gold") is int or row.get("gold") is float) or not is_finite(float(row.gold)) or row.gold < 0 or row.gold > 1000000 or floorf(float(row.gold)) != row.gold: return false
		if not row.get("item",{}) is Dictionary: return false
		if row.gold == 0:
			var item := AethelItemInstance.from_dict(row.item,world.item_catalog)
			if item == null or item_ids.has(item.instance_id): return false
			item_ids[item.instance_id] = true
		elif not row.item.is_empty(): return false
	return true

func restore(payload: Dictionary,legacy_cleared: bool) -> void:
	used.clear()
	for id: String in payload.get("used",{}): used[id] = int(payload.used[id])
	killed = payload.get("killed",{}).duplicate()
	anchors.clear()
	for id: String in payload.get("anchors",[]):
		if not id in anchors: anchors.append(id)
	buffs = payload.get("buffs",{}).duplicate()
	if payload.is_empty() and legacy_cleared:
		for group: Dictionary in data.encounters:
			if group.region!="map_02": continue
			for member: Dictionary in group.members: killed[str(member.id)] = true
	for drop: AethelDroppedItem in world.dropped_items:
		if is_instance_valid(drop): drop.queue_free()
	world.dropped_items.clear()
	for row: Dictionary in payload.get("drops",[]):
		var drop := AethelDroppedItem.new()
		drop.drop_id = str(row.id)
		drop.position = point(row.position)
		drop.gold_amount = int(row.gold)
		if drop.gold_amount == 0: drop.item = AethelItemInstance.from_dict(row.item,world.item_catalog)
		drop.set_meta("region",str(row.region))
		world.add_child(drop)
		world.dropped_items.append(drop)
	apply_buffs()
	refresh_objects()


func present_object_labels() -> void:
	var camera := world.get_viewport().get_camera_3d()
	var placed: Array[Rect2]=[]
	for id: String in objects:
		var actor: Area3D=objects[id]
		var title: Label3D=actor.get_node("Title")
		title.visible=false
		if not object_labels.has(id):
			var new_label:=Label.new()
			new_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
			new_label.add_theme_font_size_override("font_size",14)
			new_label.add_theme_color_override("font_color",AethelUI.TEXT)
			new_label.add_theme_color_override("font_outline_color",Color("0b0a08"))
			new_label.add_theme_constant_override("outline_size",5)
			loot_canvas.add_child(new_label)
			object_labels[id]=new_label
		var label: Label=object_labels[id]
		label.hide()
		if not actor.visible or world.inventory_view.visible or world.narrative.view.visible or world.shop_panel.visible: continue
		if actor.position.distance_to(world.player.position)>12 or camera.is_position_behind(actor.position) or not reachable(actor): continue
		var screen: Vector2=camera.unproject_position(actor.position+Vector3(0,1.2,0))
		if not Rect2(0,70,1280,550).has_point(screen): continue
		label.text=title.text
		label.size=label.get_minimum_size()
		var base:=Vector2(clampf(screen.x-label.size.x/2,12,1260-label.size.x),clampf(screen.y,70,620-label.size.y))
		var found:=false
		for attempt in 18:
			var candidate:=Rect2(base-Vector2(0,attempt*(label.size.y+5)),label.size)
			if candidate.position.y<70: break
			var hud_overlap:=false
			for panel: Control in [world.hud.resource_panel,world.hud.mission_tracker,world.hud.action_row,world.hud.root.get_node("WorldToolbar"),world.regions.minimap]:
				if panel.visible and candidate.intersects(panel.get_global_rect()): hud_overlap=true;break
			if hud_overlap: continue
			var overlaps:=false
			for other: Rect2 in placed:
				if candidate.intersects(other.grow(3)): overlaps=true;break
			if overlaps: continue
			label.position=candidate.position
			placed.append(candidate)
			found=true
			break
		label.visible=found
