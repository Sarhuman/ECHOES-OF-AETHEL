extends SceneTree
## Read-only production investigation. Writes only to isolated evidence/save paths.
var world: Node3D
var enemy: CharacterBody3D
var samples: Array[Dictionary] = []
var errors: Array[String] = []
func frames(count: int = 4) -> void:
 for i in count: await physics_frame
 await process_frame
func record(label: String) -> void:
 var row := {"case":label,"hp":world.player.hp,"position":[world.player.position.x,world.player.position.y,world.player.position.z],"region":world.region_id,"menu":world.exploration.travel_panel.visible,"input_locked":world.player.interaction_input_locked,"paused":paused,"invulnerability":world.player.invulnerability,"transitioning":world.regions.transitioning,"veil_visible":world.regions.veil.visible,"ether":world.player.ether,"attack_recovery":world.player.attack_recovery,"skill_cooldowns":world.player.skill_cooldowns.duplicate(),"enemy_count":world.enemies.size()}
 if is_instance_valid(enemy):
  row["enemy"]={"state":String(enemy.ai_state),"windup":enemy.windup_active,"queued":enemy.is_queued_for_deletion(),"position":[enemy.position.x,enemy.position.y,enemy.position.z]}
 samples.append(row)
 print("ANCHOR OBSERVATION ",JSON.stringify(row))
func setup() -> void:
 if is_instance_valid(world):
  world.queue_free()
  await frames()
 Engine.set_meta("aethel_new_game",true)
 world=load("res://scenes/main.tscn").instantiate()
 root.add_child(world)
 await frames()
 world.quest_started=true
 world.region_id="map_02"
 world._update_region()
 for actor in world.enemies:
  actor.queue_free()
 world.enemies.clear()
 await frames()
 world.player.position=world.exploration.objects.district_anchor.position+Vector3(0,0,1)
 world.player.clear_commands()
 world.player.rng.seed=42
 world.exploration.anchors.assign(["district_anchor","vigilia_anchor","courtyard_anchor"])
 enemy=null
 await frames()
func spawn(distance: float, active: bool = true) -> void:
 enemy=world._spawn_enemy(world.player.position+Vector3(-distance,0,0),1,1)
 enemy.set_physics_process(active)
 await frames(3)
func open_menu(label: String) -> void:
 if not world.exploration.request("district_anchor"): errors.append("anchor request rejected: "+label)
 await frames(2)
 record(label)
func key(code: Key) -> void:
 var event:=InputEventKey.new()
 event.keycode=code;event.physical_keycode=code;event.pressed=true
 Input.parse_input_event(event)
 await frames(2)
 event=event.duplicate();event.pressed=false
 Input.parse_input_event(event)
 await frames(2)
func click(at: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
 at = root.get_final_transform() * at
 var motion:=InputEventMouseMotion.new()
 motion.position=at;motion.global_position=at
 Input.parse_input_event(motion)
 for pressed: bool in [true,false]:
  var event:=InputEventMouseButton.new()
  event.position=at;event.global_position=at;event.button_index=button;event.pressed=pressed
  Input.parse_input_event(event)
  await frames(2)
func movement(label: String) -> void:
 var before: Vector3=world.player.position
 Input.action_press("move_right")
 await frames(12)
 Input.action_release("move_right")
 record(label+" displacement="+str(world.player.position.distance_to(before)))
func _initialize() -> void: call_deferred("run")
func run() -> void:
 if OS.get_environment("AETHEL_TEST_SAVE_DIR").is_empty(): quit(2);return
 seed(7)
 await setup()
 await open_menu("peaceful_open")
 var before: Vector3=world.player.position
 await click(Vector2(900,500))
 record("world_click_while_menu command="+str(world.player.has_move_target))
 await movement("movement_while_open")
 await click(Vector2(900,500),MOUSE_BUTTON_RIGHT)
 record("M2_while_open")
 world.player.attack_cooldown=0;world.player.attack_recovery=0
 world.player.skill_cooldowns.clear();world.player.ether=world.player.max_ether
 await key(KEY_J)
 record("J_while_open")
 world.player.attack_cooldown=0;world.player.attack_recovery=0
 await key(KEY_F1)
 record("F1_while_open")
 await key(KEY_ESCAPE)
 record("escape_closed")
 await movement("movement_after_escape")
 await setup()
 await spawn(2,false)
 await open_menu("nearby_passive_fixture")
 await frames(60)
 record("passive_after_1s")
 # Close via the actual Control button's mouse input, not calling hide directly.
 var column: VBoxContainer=world.exploration.travel_panel.get_child(0)
 var close_button: Button=column.get_child(column.get_child_count()-1)
 await click(close_button.get_global_rect().get_center())
 record("close_button_clicked")
 await movement("movement_after_button")
 await setup()
 await spawn(4)
 for i in 30:
  if enemy.ai_state == &"chase": break
  await frames(1)
 if enemy.ai_state != &"chase": errors.append("active chase not established")
 record("chase_before_open")
 await open_menu("chase_open")
 # Actual destination button travels while the source enemy is chasing.
 column=world.exploration.travel_panel.get_child(0)
 var destination_button: Button=column.get_child(1) # discovered Vigilia destination
 await click(destination_button.get_global_rect().get_center())
 record("chase_travel_button_to_hub")
 await frames(30)
 record("chase_travel_after_half_second")
 await setup()
 await spawn(1.4)
 for i in 20:
  if enemy.windup_active: break
  await frames(1)
 if not enemy.windup_active: errors.append("travel windup not established")
 await open_menu("windup_travel_open")
 var accepted_windup: bool=world.exploration.travel("district_anchor","vigilia_anchor")
 record("windup_travel_return="+str(accepted_windup))
 await frames(30)
 record("windup_travel_after_half_second")
 await setup()
 await spawn(1.4)
 for i in 20:
  if enemy.windup_active: break
  await frames(1)
 if not enemy.windup_active: errors.append("windup not established")
 record("windup_before_open")
 await open_menu("windup_open")
 await frames(180)
 record("windup_menu_after_3s")
 # Reopen/ensure source still reachable, then measure synchronous transition during active threat.
 record("combat_travel_before")
 var accepted: bool=world.exploration.travel("district_anchor","courtyard_anchor")
 record("combat_travel_return="+str(accepted))
 await frames(3)
 record("combat_travel_after_frames")
 # Probe exposure during the visual veil using a controlled destination encounter.
 for actor in world.enemies: actor.set_physics_process(false)
 await spawn(1.4)
 await frames(180)
 record("destination_threat_after_3s")
 await setup()
 world._save_state()
 await open_menu("load_menu_before")
 await key(KEY_F9)
 record("load_menu_after")
 await movement("movement_after_load")
 await setup()
 await spawn(1.4)
 world.player.hp=1
 world.player.invulnerability=0
 await open_menu("lethal_menu_open")
 for i in 300:
  if world.game_over: break
  await frames(1)
 record("death_while_menu_open game_over="+str(world.game_over))
 var out:=OS.get_environment("AETHEL_TEST_SAVE_DIR").path_join("anchor-observations.json")
 var file:=FileAccess.open(out,FileAccess.WRITE)
 file.store_string(JSON.stringify({"observations":samples,"fixture_errors":errors},"  "));file.close()
 for error in errors: printerr("FIXTURE ERROR: ",error)
 print("ANCHOR DIAGNOSIS: %d observations, %d fixture errors"%[samples.size(),errors.size()])
 world.queue_free()
 await frames()
 quit(0 if errors.is_empty() else 1)
