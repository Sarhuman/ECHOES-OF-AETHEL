extends CharacterBody3D
## Bastião: movimento por clique/WASD, ataque com mira no mouse, atributos, equipamento e habilidades.
signal hp_changed(current: float, maximum: float)
signal ether_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal skills_changed
signal skill_used(id: String)
signal cooldown_changed(id: String,remaining: float)
signal effect_changed(id: String,remaining: float,intensity: float)
signal equipment_changed
signal died
signal combat_event(position: Vector3, message: String, kind: String)

const CAMERA_YAW: float = PI / 4.0 # mesmo yaw da câmera em hybrid_world.gd
const DASH_STAMINA_COST: float = 24.0
const STAMINA_REGEN_PER_SECOND: float = 17.0
const ETHER_REGEN_PER_SECOND: float = 1.0
const ATTACK_RADIUS: float = 2.25
const ATTACK_REACH: float = 1.95
const SLOT_ORDER: Array = ["weapon", "shield", "helm", "armor", "gloves", "boots", "belt", "ring1", "ring2", "amulet", "charm", "cape"]

var character_level: int = 1
var class_id: StringName = &"bastion"
var character_id: String = "restorer_bastion"
var combo_step: int = 0
var manual_block: bool = false
var stats := AethelCharacterStats.new()
var equipped: Dictionary = {}
var rng := RandomNumberGenerator.new()

var hp: int = 155
var max_hp: int = 155
var ether: int = 25
var max_ether: int = 25
var stamina: float = 105.0
var max_stamina: float = 105.0
var speed: float = 6.5
var move_speed_mult: float = 1.0
var attack_speed_mult: float = 1.0
var magic_find: float = 0.0
var defense: int = 0
var attack_rating: int = 100
var block_chance: float = 0.0
var damage_min: float = 1.0
var damage_max: float = 2.0

var attack_cooldown: float = 0.0
var invulnerability: float = 0.0
var dash_remaining: float = 0.0
var guard_remaining: float = 0.0
var skill_cooldowns: Dictionary = {}
var _ui_signature: Array = []
var _cooldown_display: Dictionary = {}
var _guard_display := -1
var exploration_reduction := 0.0
var interaction_input_locked := false
var facing := Vector3(0, 0, -1)
var keyboard_active: bool = false

var move_target: Vector3 = Vector3.ZERO
var has_move_target: bool = false
var attack_target: Node3D = null
var stand_attack: bool = false
var stand_direction: Vector3 = Vector3.ZERO
var navigation_path := PackedVector3Array()
var navigation_index := 0
var navigation_repath := 0.0
var _stuck_time: float = 0.0
var attack_recovery := 0.0

func _ready() -> void:
	AethelInput.ensure_defaults()
	collision_layer = 2
	collision_mask = 1 | 4 | 8
	rng.randomize()
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	var presentation := AethelActorPresentationContract.install(self,"hero")
	capsule.radius = presentation.radius
	capsule.height = presentation.height
	collision.shape = capsule
	collision.position.y = 0.8
	add_child(collision)
	var visual := AethelCharacterVisual.new()
	visual.name = "BastiaoVisual"
	visual.definition = preload("res://data/characters/bastion_visual.tres")
	visual.model_scene = visual.definition.model_scene
	add_child(visual)
	recalculate_stats()
	restore_full()

# ---------------------------------------------------------------- atributos e equipamento
func sum_stat(stat: String) -> float:
	var total: float = 0.0
	for value in equipped.values():
		var item: AethelItemInstance = value
		total += item.stat_total(stat)
	return total

func total_attribute(attribute: String) -> int:
	return stats.get_attr(attribute) + int(sum_stat(attribute))

func requirement_problem(item: AethelItemInstance) -> String:
	var data: AethelItemData = item.definition
	if not data.allowed_classes.is_empty() and not class_id in data.allowed_classes: return "Classe incompatível"
	if data.req_level > character_level: return "Requer nível %d" % data.req_level
	if data.req_strength > total_attribute("strength"): return "Requer %d de Força" % data.req_strength
	if data.req_dexterity > total_attribute("dexterity"): return "Requer %d de Destreza" % data.req_dexterity
	return ""

func slot_for(item: AethelItemInstance) -> String:
	var slot: String = item.definition.slot
	if slot == "ring":
		if not equipped.has("ring1"): return "ring1"
		if not equipped.has("ring2"): return "ring2"
		return "ring1"
	return slot

func equipment_problem(item: AethelItemInstance, target_slot: String = "") -> String:
	if item == null or item.definition == null or item.definition.is_potion() or item.definition.slot.is_empty():
		return "Este item não pode ser equipado"
	var problem: String = requirement_problem(item)
	if not problem.is_empty(): return problem
	var slot: String = target_slot if not target_slot.is_empty() else slot_for(item)
	if not slot in SLOT_ORDER: return "Slot inválido"
	var expected := "ring" if slot in ["ring1","ring2"] else slot
	if item.definition.slot != expected: return "Slot incompatível"
	if item.quantity != 1: return "Separe a pilha antes de equipar"
	for current: AethelItemInstance in equipped.values():
		if current.instance_id == item.instance_id: return "Item já equipado"
	if slot == "weapon" and item.definition.hands == 2 and equipped.has("shield"): return "Arma de duas mãos exige mão secundária livre"
	if slot == "shield" and equipped.has("weapon") and equipped["weapon"].definition.hands == 2: return "Mão secundária ocupada pela arma"
	return ""

func equip_item(item: AethelItemInstance, target_slot: String = "") -> Dictionary:
	var problem := equipment_problem(item,target_slot)
	if not problem.is_empty(): return {"ok":false,"reason":problem}
	var slot: String = target_slot if not target_slot.is_empty() else slot_for(item)
	var replaced: AethelItemInstance = equipped.get(slot)
	equipped[slot] = item
	recalculate_stats()
	equipment_changed.emit()
	return {"ok": true, "slot": slot, "replaced": replaced}

func unequip_slot(slot: String) -> AethelItemInstance:
	var item: AethelItemInstance = equipped.get(slot)
	if item == null: return null
	equipped.erase(slot)
	recalculate_stats()
	equipment_changed.emit()
	return item

func recalculate_stats() -> void:
	var vit: int = total_attribute("vitality")
	var ene: int = total_attribute("energy")
	var strength: int = total_attribute("strength")
	var dex: int = total_attribute("dexterity")
	max_hp = 55 + (character_level - 1) * 2 + vit * 4 + int(sum_stat("life"))
	max_ether = 10 + (character_level - 1) + int(float(ene) * 1.5) + int(sum_stat("mana"))
	max_stamina = 80.0 + float(vit) + sum_stat("stamina")
	var item_defense: int = 0
	for value in equipped.values():
		var item: AethelItemInstance = value
		item_defense += item.defense_value()
	defense = item_defense + dex / 4
	attack_rating = dex * 5
	move_speed_mult = 1.0 + minf(sum_stat("move_speed"), 75.0) / 100.0
	attack_speed_mult = 1.0 + minf(sum_stat("attack_speed"), 75.0) / 100.0
	magic_find = sum_stat("find_magic")
	var shield: AethelItemInstance = equipped.get("shield")
	block_chance = 0.0
	if shield != null:
		block_chance = clampf(float(shield.definition.block_chance) * float(dex - 15) / float(character_level * 2), 0.0, 75.0)
	var weapon: AethelItemInstance = equipped.get("weapon")
	var base_min: float = 1.0
	var base_max: float = 2.0
	if weapon != null:
		base_min = float(weapon.definition.damage_min)
		base_max = float(weapon.definition.damage_max)
	var added: float = sum_stat("damage_add")
	var multiplier: float = 1.0 + float(strength) / 100.0 + sum_stat("damage_pct") / 100.0
	damage_min = (base_min + added) * multiplier
	damage_max = (base_max + added) * multiplier
	hp = mini(hp, max_hp)
	ether = mini(ether, max_ether)
	stamina = minf(stamina, max_stamina)
	hp_changed.emit(float(hp), float(max_hp))
	ether_changed.emit(float(ether), float(max_ether))
	stamina_changed.emit(stamina, max_stamina)
	_sync_equipment_visuals()

func restore_full() -> void:
	hp = max_hp
	ether = max_ether
	stamina = max_stamina
	hp_changed.emit(float(hp), float(max_hp))
	ether_changed.emit(float(ether), float(max_ether))
	stamina_changed.emit(stamina, max_stamina)

func roll_damage(multiplier: float = 1.0) -> int:
	return maxi(1, roundi(rng.randf_range(damage_min, damage_max) * multiplier))

# ---------------------------------------------------------------- comandos do mouse
func command_move(point: Vector3) -> void:
	var world := get_parent()
	if world.get("regions") != null:
		if has_move_target and move_target.distance_to(point)<0.35: return
		navigation_path=world.regions.level.path(global_position,point)
		if navigation_path.is_empty():
			clear_commands()
			world._show_message("Destino fora da navegação")
			return
		navigation_index=0
	move_target = point
	has_move_target = true
	attack_target = null
	stand_attack = false

func command_attack(enemy: Node3D) -> void:
	if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.hp <= 0: return
	if attack_target == enemy: return
	_stuck_time = 0
	attack_target = enemy
	has_move_target = false
	stand_attack = false

func command_stand_attack(point: Vector3) -> void:
	var direction: Vector3 = point - global_position
	direction.y = 0.0
	if direction.length() > 0.05: stand_direction = direction.normalized()
	stand_attack = true
	has_move_target = false
	attack_target = null

func stop_stand_attack() -> void:
	stand_attack = false

func clear_commands() -> void:
	has_move_target = false
	navigation_path.clear()
	attack_target = null
	stand_attack = false

func _keyboard_direction() -> Vector3:
	if interaction_input_locked: return Vector3.ZERO
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var camera := get_viewport().get_camera_3d()
	var yaw: float = camera.global_rotation.y if camera != null else CAMERA_YAW
	return Vector3(direction.x, 0, direction.y).rotated(Vector3.UP, yaw)

# ---------------------------------------------------------------- loop principal
func _physics_process(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	attack_recovery = maxf(0, attack_recovery - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	dash_remaining = maxf(0.0, dash_remaining - delta)
	guard_remaining = maxf(0.0, guard_remaining - delta)
	for skill_id in skill_cooldowns.keys():
		skill_cooldowns[skill_id] = maxf(0.0, float(skill_cooldowns[skill_id]) - delta)
	var previous_stamina: float = stamina
	stamina = minf(max_stamina, stamina + STAMINA_REGEN_PER_SECOND * delta)
	if absf(stamina - previous_stamina) > 0.001: stamina_changed.emit(stamina, max_stamina)
	if hp > 0 and ether < max_ether and ETHER_REGEN_PER_SECOND > 0.0:
		_ether_fraction += ETHER_REGEN_PER_SECOND * delta
		if _ether_fraction >= 1.0:
			var whole: int = int(_ether_fraction)
			_ether_fraction -= float(whole)
			ether = mini(max_ether, ether + whole)
			ether_changed.emit(float(ether), float(max_ether))
	_emit_ui_state()
	if hp <= 0:
		velocity = Vector3.ZERO
		return
	manual_block = not interaction_input_locked and Input.is_action_pressed("block") and equipped.has("shield")
	var direction: Vector3 = _keyboard_direction()
	keyboard_active = direction.length() > 0.1
	if keyboard_active: clear_commands()
	elif is_instance_valid(attack_target) and attack_target.hp > 0 and not attack_target.is_queued_for_deletion():
		var offset: Vector3 = attack_target.global_position - global_position
		offset.y = 0.0
		if offset.length() <= ATTACK_REACH+0.04:
			facing = offset.normalized() if offset.length() > 0.01 else facing
			_try_attack()
		else:
			direction = path_direction(attack_target.global_position,delta) * minf(1, maxf(0, offset.length() - ATTACK_REACH) / maxf(0.001, speed * move_speed_mult * delta))
	elif attack_target != null:
		attack_target = null
	elif stand_attack:
		facing = stand_direction
		_try_attack()
	elif has_move_target:
		var offset: Vector3 = move_target - global_position
		offset.y = 0.0
		if offset.length() < 0.25: has_move_target = false
		else: direction = path_direction(move_target,delta)
	if direction.length() > 0.1 and attack_recovery <= 0: facing = direction
	if not interaction_input_locked and Input.is_action_pressed("dodge") and dash_remaining <= 0.0 and invulnerability <= 0.0 and stamina >= DASH_STAMINA_COST:
		_visual_action(&"dodge", 0.2)
		dash_remaining = 0.17
		invulnerability = 0.22
		stamina -= DASH_STAMINA_COST
		stamina_changed.emit(stamina, max_stamina)
	var move_direction: Vector3 = direction
	if dash_remaining > 0.0 and move_direction.length() < 0.1: move_direction = facing
	var current_speed: float = 15.0 if dash_remaining > 0.0 else speed * move_speed_mult
	velocity = move_direction * current_speed * (0.35 if manual_block else 1.0)
	if attack_recovery > 0: velocity = Vector3.ZERO
	velocity.y=-8.0 if is_on_floor() else -12.0
	move_and_slide()
	if global_position.y < -5 and get_parent().get("regions") != null:
		global_position=get_parent().regions.level.safe_position(Vector3.INF)
		clear_commands()
	if has_move_target:
		if get_real_velocity().length() < 0.4: _stuck_time += delta
		else: _stuck_time = 0.0
		if _stuck_time > 0.45:
			has_move_target = false
			_stuck_time = 0.0
	var visual_node: Node3D = get_node_or_null("BastiaoVisual") as Node3D
	if visual_node != null:
		visual_node.call("set_motion", velocity, facing, delta)
		var model: Node3D = visual_node.get("_model")
		if model != null and model.has_method("set_guard_active"): model.call("set_guard_active", guard_remaining > 0)

var _ether_fraction: float = 0.0

# ---------------------------------------------------------------- combate
func _try_attack() -> void:
	if not combat_allowed(): return
	if attack_cooldown > 0.0 or manual_block or hp <= 0: return
	combo_step = (combo_step + 1) % 2
	attack_cooldown = 0.55 / attack_speed_mult
	attack_recovery = 0.18
	velocity = Vector3.ZERO
	_play_attack_animation()
	combat_event.emit(global_position, "", "attack")
	perform_attack(1.0, ATTACK_RADIUS, false)

func _play_attack_animation() -> void:
	_visual_action(&"attack_1" if combo_step == 0 else &"attack_2", 0.45)

func _visual_action(state: StringName, duration: float = 0.3) -> void:
	var visual := get_node_or_null("BastiaoVisual") as AethelCharacterVisual
	if visual != null: visual.play_action(state, duration)

func _sync_equipment_visuals() -> void:
	var visual := get_node_or_null("BastiaoVisual") as AethelCharacterVisual
	if visual == null: return
	var adapter := visual.equipment_adapter()
	if adapter == null: return
	var mapping: Dictionary = {"weapon":"weapon_main", "shield":"offhand", "helm":"helmet", "armor":"chest", "gloves":"gloves", "boots":"boots", "cape":"cape"}
	for slot: String in mapping:
		var item: AethelItemInstance = equipped.get(slot)
		if item == null:
			adapter.clear_equipment(StringName(mapping[slot]))
		elif not item.definition.appearance_id.is_empty():
			adapter.apply_equipment(StringName(mapping[slot]), item.definition.appearance_id, adapter.RARITIES[clampi(item.get_quality(), 0, 4)])

func perform_attack(multiplier: float, radius: float, full_circle: bool) -> int:
	if not combat_allowed(): return 0
	var candidates: int = 0
	var targeted: int = 0
	var landed: int = 0
	for node in get_tree().get_nodes_in_group("hybrid_enemies"):
		if not is_instance_valid(node): continue
		var offset: Vector3 = node.global_position - global_position
		offset.y = 0.0
		var distance: float = offset.length()
		if distance <= radius + 1.25: candidates += 1
		var in_arc: bool = full_circle or distance < 0.01 or facing.dot(offset.normalized()) >= 0.1
		var clear_hit := true
		if get_parent().get("regions")!=null: clear_hit=get_parent().exploration.reachable(node) and absf(node.position.y-position.y)<1.4
		if distance <= radius and in_arc and clear_hit:
			targeted += 1
			if node.receive_hit(roll_damage(multiplier), attack_rating, character_level): landed += 1
	if candidates > 0 and targeted == 0:
		combat_event.emit(global_position + Vector3(0, 2.2, 0), "FORA DE ALCANCE", "miss")
	return landed

func skill_problem(skill: AethelSkillData) -> String:
	if skill == null or not String(skill.skill_id) in ["heavy_strike", "iron_guard", "echo_cleave"]: return "Habilidade indisponível"
	if hp <= 0: return "Personagem derrotado"
	if String(skill.skill_id)!="iron_guard" and not combat_allowed(): return "Zona segura: ataque indisponível"
	var skill_id := String(skill.skill_id)
	if skill_id == "iron_guard" and guard_remaining > 0: return ""
	if float(skill_cooldowns.get(skill_id, 0.0)) > 0: return "Em recarga"
	if ether < skill.ether_cost: return "Sem Éter"
	if skill_id != "iron_guard" and (attack_cooldown > 0 or manual_block): return "Em recuperação"
	return ""

func use_skill(skill: AethelSkillData) -> String:
	var problem := skill_problem(skill)
	if not problem.is_empty(): return problem
	var skill_id := String(skill.skill_id)
	if skill_id == "iron_guard" and guard_remaining > 0:
		guard_remaining = 0
		_emit_ui_state()
		combat_event.emit(global_position + Vector3(0,2.2,0), "GUARDA ENCERRADA", "buff")
		return ""
	clear_commands()
	velocity = Vector3.ZERO
	ether -= skill.ether_cost
	ether_changed.emit(float(ether), float(max_ether))
	skill_cooldowns[skill_id] = skill.cooldown
	skill_used.emit(skill_id)
	match skill_id:
		"heavy_strike":
			attack_cooldown = 0.7 / attack_speed_mult
			attack_recovery = 0.22
			_play_attack_animation()
			perform_attack(1.5, ATTACK_RADIUS, false)
		"echo_cleave":
			attack_cooldown = 0.8 / attack_speed_mult
			attack_recovery = 0.25
			_play_attack_animation()
			perform_attack(1.25, 3.4, true)
		"iron_guard":
			guard_remaining = 8
			_visual_action(&"block", 0.3)
			combat_event.emit(global_position + Vector3(0, 2.2, 0), "GUARDA DE FERRO", "buff")
	_emit_ui_state()
	return ""

func drink_potion(life: int, mana: int) -> void:
	if life > 0:
		var healed: int = mini(life, max_hp - hp)
		hp += healed
		hp_changed.emit(float(hp), float(max_hp))
		if healed > 0: combat_event.emit(global_position + Vector3(0, 2.2, 0), "+%d" % healed, "heal")
	if mana > 0:
		var restored: int = mini(mana, max_ether - ether)
		ether += restored
		ether_changed.emit(float(ether), float(max_ether))
		if restored > 0: combat_event.emit(global_position + Vector3(0, 2.6, 0), "+%d" % restored, "mana")

func receive_attack(raw_damage: int, attacker_rating: int, attacker_level: int) -> String:
	if hp <= 0 or invulnerability > 0.0: return "ignored"
	var chance: float = clampf(2.0 * float(attacker_rating) / float(attacker_rating + defense + 1) * float(attacker_level) / float(attacker_level + character_level), 0.05, 0.95)
	if rng.randf() > chance:
		combat_event.emit(global_position + Vector3(0, 2.2, 0), "ESQUIVOU", "miss")
		return "miss"
	if (manual_block and stamina >= 8) or (block_chance > 0.0 and rng.randf() * 100.0 < block_chance):
		if manual_block:
			_visual_action(&"block")
			stamina -= 8
			stamina_changed.emit(stamina, max_stamina)
		combat_event.emit(global_position + Vector3(0, 2.2, 0), "BLOQUEOU", "miss")
		return "block"
	take_damage(raw_damage)
	return "hit"

func take_damage(amount: int) -> void:
	if hp <= 0 or invulnerability > 0.0: return
	var final_damage: int = maxi(1, roundi(float(amount) * (0.6 if guard_remaining > 0.0 else 1.0) * (1.0-clampf(exploration_reduction,0,0.5))))
	hp = maxi(0, hp - final_damage)
	hp_changed.emit(float(hp), float(max_hp))
	combat_event.emit(global_position + Vector3(0, 2.2, 0), "-%d" % final_damage, "hurt")
	invulnerability = 0.35
	if hp == 0:
		_visual_action(&"death", 999)
		died.emit()
	else:
		_visual_action(&"hit", 0.2)

func _emit_ui_state() -> void:
	var signature: Array = [hp,ether,manual_block,ceili(attack_cooldown*10),ceili(guard_remaining*10)]
	for id: String in ["heavy_strike","iron_guard","echo_cleave"]:
		var ticks: int = ceili(float(skill_cooldowns.get(id,0))*10)
		signature.append(ticks)
		if int(_cooldown_display.get(id,-1)) != ticks:
			_cooldown_display[id] = ticks
			cooldown_changed.emit(id,ticks/10.0)
	var seconds: int = ceili(guard_remaining)
	if seconds != _guard_display:
		_guard_display = seconds
		effect_changed.emit("guard",guard_remaining,0.4)
	if signature != _ui_signature:
		_ui_signature = signature
		skills_changed.emit()

func combat_allowed() -> bool:
	var owner_world := get_parent()
	return owner_world.get("regions")==null or owner_world.regions.allows_combat()

func path_direction(destination: Vector3,delta: float) -> Vector3:
	var owner_world := get_parent()
	if owner_world.get("regions")==null: return (destination-global_position).normalized()
	if is_instance_valid(attack_target):
		navigation_repath-=delta
		if navigation_repath<=0:
			navigation_path=owner_world.regions.level.path(global_position,destination)
			navigation_index=0
			navigation_repath=0.3
	while navigation_index<navigation_path.size():
		var offset := navigation_path[navigation_index]-global_position
		offset.y=0
		if offset.length()>0.25: return offset.normalized()
		navigation_index+=1
	return Vector3.ZERO
