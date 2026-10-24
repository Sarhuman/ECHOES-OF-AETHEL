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
 check(ex.request("district_anchor") and ex.travel_panel.visible,"peaceful anchor opens")
 check(not paused and world.player.interaction_input_locked,"world active and modal locked")
 var before_ether: int=world.player.ether
 for code: Key in [KEY_J,KEY_F1,KEY_F2,KEY_F3]: await key(code)
 world._cast_right_skill(Vector2(900,500))
 world._activate_skill("heavy_strike")
 check(world.player.ether==before_ether and world.player.attack_cooldown==0 and world.player.skill_cooldowns.is_empty(),"J/F1-F3/M2/HUD blocked without resource changes")
 var start: Vector3=world.player.position
 Input.action_press("move_right");Input.action_press("dodge")
 await frames(12)
 Input.action_release("move_right");Input.action_release("dodge")
 check(world.player.position.distance_to(start)<0.05,"movement/dodge blocked in modal")
 await key(KEY_ESCAPE)
 check(not ex.travel_panel.visible and not world.player.interaction_input_locked and not paused,"Escape closes without pause or stale lock")
 Input.action_press("move_right");await frames(12);Input.action_release("move_right")
 check(world.player.position.distance_to(start)>0.2,"movement restored after Escape")
 world.player.position=start
 ex.open_travel("district_anchor")
 var column: VBoxContainer=ex.travel_panel.get_child(0)
 (column.get_child(column.get_child_count()-1) as Button).pressed.emit()
 check(not ex.travel_panel.visible and not world.player.interaction_input_locked,"button closes and unlocks immediately")
 ex.open_travel("district_anchor");world.shop_panel.show();ex.close_travel()
 check(world.player.interaction_input_locked,"shop lock preserved when closing travel")
 world.shop_panel.hide();world.narrative.view.show();ex.close_travel()
 check(world.player.interaction_input_locked,"dialogue lock preserved when closing travel")
 world.narrative.close()
 var actor:=spawn()
 for state: StringName in [&"chase",&"search",&"attack"]:
  actor.ai_state=state
  ex.open_travel("district_anchor")
  check(not ex.travel_panel.visible,"deny opening during "+String(state))
  var region_before: String=world.region_id
  var hp_before: int=world.player.hp
  check(not ex.travel("district_anchor","vigilia_anchor") and world.region_id==region_before and world.player.hp==hp_before,"direct travel rejects "+String(state)+" without mutation")
 actor.ai_state=&"patrol";actor.windup_active=true
 check(not ex.travel("district_anchor","vigilia_anchor"),"windup rejected before state transition")
 actor.windup_active=false
 ex.open_travel("district_anchor")
 check(ex.travel_panel.visible,"nonaggressive nearby actor permits opening")
 actor.ai_state=&"chase"
 check(not ex.travel("district_anchor","vigilia_anchor") and not ex.travel_panel.visible,"revalidate threat after menu opened")
 actor.ai_state=&"patrol";ex.open_travel("district_anchor");actor.ai_state=&"search"
 await frames()
 check(not ex.travel_panel.visible and not world.player.interaction_input_locked,"new threat auto closes and unlocks")
 check(not paused,"threat closure never pauses world")
 actor.ai_state=&"patrol";ex.open_travel("district_anchor")
 check(not ex.travel("district_anchor","archive_anchor"),"undiscovered destination still rejected")
 ex.close_travel();ex.anchors.erase("district_anchor")
 check(not ex.travel("district_anchor","vigilia_anchor"),"undiscovered source still rejected")
 ex.anchors.append("district_anchor")
 check(ex.travel("district_anchor","vigilia_anchor"),"peaceful travel succeeds")
 await frames()
 check(world.region_id=="map_01" and not ex.travel_panel.visible and not world.player.interaction_input_locked,"arrival region menu and controls consistent")
 await setup();ex=world.exploration
 world._save_state();ex.open_travel("district_anchor")
 await key(KEY_F9)
 check(not ex.travel_panel.visible and not world.player.interaction_input_locked,"load clears menu and lock")
 ex.open_travel("district_anchor");world.player.invulnerability=0;world.player.take_damage(9999)
 check(world.game_over and not ex.travel_panel.visible and not world.player.interaction_input_locked,"death clears menu and lock")
 await key(KEY_F9)
 check(not world.game_over and world.player.hp>0,"Fix01 F9 after death preserved")
 await setup();ex=world.exploration
 ex.open_travel("district_anchor")
 actor=spawn(true)
 await frames(12)
 check(actor.ai_state in [&"chase",&"attack"] and not ex.travel_panel.visible,"real AI pursuit closes open menu")
 world.queue_free();await frames()
 for failure in failures: printerr("FALHA: ",failure)
 print("FIX03 ANCHORS: %d checks, %d failures"%[checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
