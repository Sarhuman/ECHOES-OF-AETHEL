extends SceneTree
var world: Node3D
var checks := 0
var failures: Array[String] = []
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok: failures.append(label)
func frames(count: int = 4) -> void:
 for i in count: await physics_frame
 await process_frame
func key(code: Key) -> void:
 var event:=InputEventKey.new()
 event.keycode=code;event.physical_keycode=code;event.pressed=true
 Input.parse_input_event(event)
 await frames(2)
 event=event.duplicate();event.pressed=false;Input.parse_input_event(event)
 await frames(2)
func setup() -> void:
 if is_instance_valid(world): world.queue_free();await frames()
 Engine.set_meta("aethel_new_game",true)
 world=load("res://scenes/main.tscn").instantiate()
 root.add_child(world)
 await frames()
 world.quest_started=true;world.region_id="map_02";world._update_region()
 for actor in world.enemies: actor.queue_free()
 world.enemies.clear()
 await frames()
 world.player.position=world.exploration.objects.district_anchor.position+Vector3(0,0,1)
 world.exploration.anchors.assign(["district_anchor","vigilia_anchor","courtyard_anchor"])
 await frames()
func spawn(active: bool = false) -> CharacterBody3D:
 var actor: CharacterBody3D=world._spawn_enemy(world.player.position+Vector3(-4,0,0),1,1)
 actor.set_physics_process(active)
 return actor
func _initialize() -> void: call_deferred("run")
func run() -> void:
 if OS.get_environment("AETHEL_TEST_SAVE_DIR").is_empty(): quit(2);return
 await setup()
 var ex: AethelExploration=world.exploration
 var actor:=spawn()
 actor.ai_state=&"patrol"
 var player=world.player
 ex.open_travel("district_anchor")
 player.invulnerability=0
 var hp_before:int=player.hp
 player.take_damage(2)
 check(player.hp<hp_before and not ex.recent_enemy_damage_active() and ex.travel_panel.visible,"environment damage does not arm window or close menu")
 player.block_chance=0
 player.invulnerability=0
 player.rng.seed=1
 player.manual_block=true;player.stamina=player.max_stamina
 var outcome:String=player.receive_attack(3,99999,99,actor)
 check(outcome=="block" and not ex.recent_enemy_damage_active(),"blocked enemy melee does not arm window")
 player.manual_block=false
 player.rng.seed=1
 player.invulnerability=1
 player.take_damage(2,actor)
 check(not ex.recent_enemy_damage_active(),"ignored enemy damage does not arm window")
 player.invulnerability=0
 player.guard_remaining=0
 player.exploration_reduction=0
 hp_before=player.hp
 player.take_damage(3,actor)
 var stamp:int=ex.last_enemy_damage_ms
 check(player.hp==hp_before-3 and ex.recent_enemy_damage_active(),"actual enemy damage arms monotonic window without changing damage")
 check(not ex.travel_panel.visible and not player.interaction_input_locked,"damage closes menu immediately and releases modal lock")
 ex.open_travel("district_anchor")
 check(not ex.travel_panel.visible,"recent enemy damage denies opening despite peaceful actor")
 var region_before:String=world.region_id
 var position_before:Vector3=player.position
 check(not ex.travel("district_anchor","vigilia_anchor") and world.region_id==region_before and player.position==position_before,"direct travel cannot bypass damage window")
 player.invulnerability=0
 player.take_damage(1)
 check(ex.last_enemy_damage_ms==stamp,"environment damage does not refresh active window")
 player.invulnerability=1
 player.receive_attack(3,99999,99,actor)
 check(ex.last_enemy_damage_ms==stamp,"invulnerable melee does not refresh window")
 OS.delay_msec(20)
 player.invulnerability=0
 player.take_damage(1,actor)
 check(ex.last_enemy_damage_ms>stamp,"additional actual enemy damage refreshes window")
 stamp=ex.last_enemy_damage_ms
 for state:StringName in [&"chase",&"search",&"attack"]:
  actor.ai_state=state
  check(ex.travel_combat_active() and not ex.travel("district_anchor","vigilia_anchor"),"damage window coexists with "+String(state))
 actor.ai_state=&"patrol"
 actor.queue_free();world.enemies.clear()
 check(ex.recent_enemy_damage_active(),"removing attacker does not erase window")
 while Time.get_ticks_msec()-stamp<ex.ENEMY_DAMAGE_TRAVEL_LOCK_MS+20:
  OS.delay_msec(10)
  await process_frame
 check(not ex.recent_enemy_damage_active(),"window expires after five real monotonic seconds")
 actor=spawn();actor.ai_state=&"patrol"
 ex.open_travel("district_anchor")
 check(ex.travel_panel.visible,"peaceful nearby enemy permits opening after expiry")
 ex.close_travel()
 for state:StringName in [&"chase",&"search",&"attack"]:
  actor.ai_state=state
  check(ex.travel_combat_active() and not ex.travel("district_anchor","vigilia_anchor"),"active "+String(state)+" still blocks after timer expiry")
 actor.ai_state=&"hit";actor.search_remaining=2
 ex.open_travel("district_anchor")
 check(not ex.travel_panel.visible and not ex.travel("district_anchor","vigilia_anchor"),"hit with active threat blocks opening and direct travel")
 actor.search_remaining=0
 ex.open_travel("district_anchor")
 check(ex.travel_panel.visible,"hit without active threat memory does not block peaceful actor")
 ex.close_travel();actor.ai_state=&"patrol"
 check(ex.travel("district_anchor","vigilia_anchor"),"peaceful travel succeeds after expiry")
 await setup();ex=world.exploration;player=world.player
 actor=spawn();actor.ai_state=&"patrol"
 player.block_chance=0;player.rng.seed=1;player.invulnerability=0
 hp_before=player.hp
 outcome=player.receive_attack(3,99999,99,actor)
 check(outcome=="hit" and player.hp<hp_before and ex.recent_enemy_damage_active(),"enemy melee source reaches damage registration")
 await setup();ex=world.exploration;player=world.player
 actor=spawn();actor.position=player.position+Vector3(0,0,1)
 actor.modifiers.assign(["corrupted"])
 actor.modifier_rules={"corrupted":{"interval":2.0,"radius":5.0,"dot_damage":2,"name":"test"}}
 player.invulnerability=0;hp_before=player.hp
 actor._tick_modifiers(2.1)
 check(player.hp<hp_before and ex.recent_enemy_damage_active(),"real corrupted enemy DOT registers enemy source")
 world.queue_free();await frames()
 for failure in failures: printerr("FALHA: ",failure)
 print("FIX03 DAMAGE: %d checks, %d failures"%[checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
