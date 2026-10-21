extends CharacterBody3D
## Rasura: monstro com nível, rank (normal/campeão/único), defesa, recuo ao ser atingido e golpe com aviso.
signal presentation_changed
var _ward_display := -1
signal defeated(enemy: CharacterBody3D)
signal damaged(enemy: CharacterBody3D)
signal combat_event(position: Vector3, message: String, kind: String)

const RANK_HP: Array = [1.0, 2.6, 5.0]
const RANK_DAMAGE: Array = [1.0, 1.3, 1.7]
const RANK_XP: Array = [1.0, 4.0, 12.0]
const RANK_STAGGER: Array = [0.34, 0.22, 0.12]
const RANK_COLORS: Array = [Color("d0d0d0"), Color("6969ff"), Color("c7b377")]
const RANK_SCALE: Array = [1.0, 1.2, 1.45]

var target: CharacterBody3D
var monster_name: String = "Rasura"
var level: int = 1
var rank: int = 0
var max_hp: int = 38
var hp: int = 38
var damage_min: int = 4
var damage_max: int = 7
var defense: int = 16
var attack_rating: int = 42
var move_speed: float = 2.65
var xp_value: int = 12
var attack_cooldown: float = 0.0
var stagger: float = 0.0
var windup: float = 0.0
var windup_active: bool = false
var navigation_agent: NavigationAgent3D
var repath_time: float = 0.0
var ai_state: StringName = &"patrol"
var home_position := Vector3.ZERO
var _home_initialized := false
var _patrol_clock := 0.0
var modifiers: Array[String] = []
var modifier_rules: Dictionary = {}
var modifier_clock := 0.0
var guardian_clock := 0.0
var ward_remaining := 0.0
var visual: Node3D

func setup(new_level: int, new_rank: int, new_name: String = "Rasura") -> void:
	level = maxi(1, new_level)
	rank = clampi(new_rank, 0, 2)
	monster_name = new_name
	max_hp = roundi(float(38 + 14 * (level - 1)) * float(RANK_HP[rank]))
	hp = max_hp
	damage_min = roundi(float(4 + 2 * (level - 1)) * float(RANK_DAMAGE[rank]))
	damage_max = roundi(float(7 + 3 * (level - 1)) * float(RANK_DAMAGE[rank]))
	defense = 10 + 6 * level
	attack_rating = 30 + 12 * level
	xp_value = roundi(float(12 + 4 * (level - 1)) * float(RANK_XP[rank]))
	move_speed = 2.65 * [1.0, 1.1, 1.15][rank]

func display_name() -> String:
	return monster_name if rank == 0 else "%s %s" % [monster_name, ["", "Campeã", "Elite"][rank]]

func _ready() -> void:
	add_to_group("hybrid_enemies")
	collision_layer = 4
	collision_mask = 1 | 2 | 4 | 8
	navigation_agent = NavigationAgent3D.new()
	navigation_agent.path_desired_distance = 0.45
	navigation_agent.target_desired_distance = 1.4
	add_child(navigation_agent)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	var presentation := AethelActorPresentationContract.install(self,"enemy",rank)
	capsule.radius = presentation.radius
	capsule.height = presentation.height
	collision.shape = capsule
	collision.position.y = capsule.height * 0.5
	add_child(collision)
	# Selection volume follows the visible head/cloak, not a fixed screen-pixel radius.
	var pick := Area3D.new()
	pick.name = "EnemyPickArea"
	pick.collision_layer = 16
	pick.collision_mask = 0
	var pick_shape := CollisionShape3D.new()
	var pick_capsule := CapsuleShape3D.new()
	pick_capsule.radius = 0.55 * float(RANK_SCALE[rank])
	pick_capsule.height = 1.85 * float(RANK_SCALE[rank])
	pick_shape.shape = pick_capsule
	pick_shape.position.y = pick_capsule.height * 0.5
	pick.add_child(pick_shape)
	add_child(pick)
	visual = Node3D.new()
	visual.name = "RasuraVisual"
	visual.set_script(preload("res://scripts/procedural_rasura.gd"))
	visual.set("presentation_rank",rank)
	visual.scale = Vector3.ONE * float(RANK_SCALE[rank])
	add_child(visual)
	if rank >= 0:
		var glow := OmniLight3D.new()
		glow.light_color = RANK_COLORS[rank]
		glow.light_energy = 1.1 if rank>0 else 0.0
		glow.omni_range = 3.4
		glow.position.y = 1.2
		add_child(glow)
		var name_label := Label3D.new()
		name_label.text = display_name()
		name_label.modulate = RANK_COLORS[rank]
		name_label.position = presentation.label
		name_label.font_size = 24
		name_label.pixel_size = 0.008
		name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(name_label)

func _physics_process(delta: float) -> void:
	if get_parent().get("regions")!=null and not get_parent().regions.allows_combat():
		velocity=Vector3.ZERO
		return
	_tick_modifiers(delta)
	if not _home_initialized:
		home_position = global_position
		_home_initialized = true
	if hp <= 0:
		ai_state = &"death"
		return
	if not is_instance_valid(target) or target.hp <= 0:
		velocity = Vector3.ZERO
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	stagger = maxf(0.0, stagger - delta)
	if stagger > 0.0:
		ai_state = &"hit"
		velocity = Vector3.ZERO
		return
	var offset: Vector3 = target.global_position - global_position
	offset.y = 0.0
	var distance: float = offset.length()
	if windup_active:
		ai_state = &"attack"
		windup -= delta
		velocity = Vector3.ZERO
		if visual != null: visual.scale = Vector3.ONE * float(RANK_SCALE[rank]) * (1.0 + 0.14 * sin(windup * 30.0))
		if windup <= 0.0:
			windup_active = false
			if visual != null: visual.scale = Vector3.ONE * float(RANK_SCALE[rank])
			if distance < 1.95:
				target.receive_attack(randi_range(damage_min, damage_max), attack_rating, level)
			attack_cooldown = [1.3, 1.15, 1.0][rank]
		return
	if distance < 1.55 and attack_cooldown <= 0.0:
		windup_active = true
		windup = 0.4
		velocity = Vector3.ZERO
		return
	if distance > 1.3 and distance < 18.0 and global_position.distance_to(home_position) < 24:
		ai_state = &"chase"
		var desired: Vector3 = offset.normalized()
		var navigation_map: RID = navigation_agent.get_navigation_map()
		if NavigationServer3D.map_get_iteration_id(navigation_map) > 0:
			repath_time -= delta
			if repath_time <= 0.0:
				navigation_agent.target_position = target.global_position
				repath_time = 0.3
			if not navigation_agent.is_navigation_finished():
				var waypoint: Vector3 = navigation_agent.get_next_path_position()
				var path_vector: Vector3 = waypoint - global_position
				path_vector.y = 0.0
				if path_vector.length_squared() > 0.001: desired = path_vector.normalized()
		desired = (desired + _separation() * 0.8).normalized()
		velocity = desired * move_speed
		velocity.y=-8 if is_on_floor() else -12
		move_and_slide()
	else:
		_patrol_clock += delta
		var away := home_position - global_position
		away.y = 0
		if away.length() > 2:
			ai_state = &"return"
			velocity = away.normalized() * move_speed
		else:
			ai_state = &"patrol"
			var patrol_target := home_position + Vector3(sin(_patrol_clock * 0.35),0,cos(_patrol_clock * 0.35))
			velocity = (patrol_target - global_position).normalized() * move_speed * 0.25
		velocity.y=-8 if is_on_floor() else -12
		move_and_slide()

func _separation() -> Vector3:
	var push := Vector3.ZERO
	for node in get_tree().get_nodes_in_group("hybrid_enemies"):
		if node == self or not is_instance_valid(node): continue
		var away: Vector3 = global_position - node.global_position
		away.y = 0.0
		var gap: float = away.length()
		if gap > 0.001 and gap < 1.0: push += away.normalized() * (1.0 - gap)
	return push

func receive_hit(damage: int, attacker_rating: int, attacker_level: int) -> bool:
	var chance: float = clampf(2.0 * float(attacker_rating) / float(attacker_rating + defense) * float(attacker_level) / float(attacker_level + level), 0.05, 0.95)
	if randf() > chance:
		combat_event.emit(global_position + Vector3(0, 2.1, 0), "ERROU", "miss")
		return false
	take_damage(damage)
	return true

func take_damage(amount: int) -> void:
	if hp <= 0: return
	hp -= maxi(1,roundi(amount * (1.0-float(modifier_rules.get("guardian",{}).get("reduction",0.2))) if ward_remaining > 0 else amount))
	combat_event.emit(global_position + Vector3(0, 2.1, 0), "-%d" % amount, "damage")
	stagger = float(RANK_STAGGER[rank])
	windup_active = false
	damaged.emit(self)
	if hp <= 0:
		ai_state = &"death"
		defeated.emit(self)
		queue_free()

func configure_modifiers(ids: Array,rules: Dictionary) -> void:
	modifier_rules = rules
	for id: String in ids:
		if not rules.has(id) or id in modifiers: continue
		modifiers.append(id)
		match id:
			"brutal":
				damage_min = roundi(damage_min*float(rules[id].damage))
				damage_max = roundi(damage_max*float(rules[id].damage))
			"resistant": defense = roundi(defense*float(rules[id].defense))
			"fast": move_speed *= float(rules[id].speed)
	var names: Array[String] = []
	for id: String in modifiers: names.append(str(rules[id].name))
	if not names.is_empty():
		var label := Label3D.new()
		label.text = " · ".join(names)
		label.visible=false # Modifier descriptions are presented once in the target HUD.
		label.font_size = 18
		label.pixel_size = 0.005
		label.position.y = 2.8 * float(RANK_SCALE[rank])
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
	for child in get_children():
		if child is Label3D and child.font_size != 18: child.text = display_name()

func _tick_modifiers(delta: float) -> void:
	ward_remaining = maxf(0,ward_remaining-delta)
	if ceili(ward_remaining) != _ward_display:
		_ward_display = ceili(ward_remaining)
		presentation_changed.emit()
	if hp <= 0: return
	if "corrupted" in modifiers and is_instance_valid(target) and target.hp > 0:
		modifier_clock += delta
		var rule: Dictionary = modifier_rules.corrupted
		if modifier_clock >= float(rule.interval):
			modifier_clock = 0
			if global_position.distance_to(target.global_position) <= float(rule.radius):
				target.take_damage(int(rule.dot_damage))
				combat_event.emit(target.global_position+Vector3(0,2.3,0),str(rule.name),"hurt")
	if "guardian" in modifiers:
		guardian_clock -= delta
		if guardian_clock <= 0:
			var rule: Dictionary = modifier_rules.guardian
			guardian_clock = float(rule.interval)
			for ally in get_tree().get_nodes_in_group("hybrid_enemies"):
				if ally == self or ally.hp <= 0: continue
				if global_position.distance_to(ally.global_position) <= float(rule.radius):
					ally.ward_remaining = maxf(ally.ward_remaining,float(rule.duration))
			combat_event.emit(global_position+Vector3(0,2.5,0),str(rule.name),"buff")
