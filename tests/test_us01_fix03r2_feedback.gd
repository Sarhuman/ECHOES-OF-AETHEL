extends SceneTree
## Investigation only: external script can run against the immutable exported PCK.
var world
var rows: Array = []
var folder: String
func _initialize() -> void:
 print("G2_INITIALIZE")
 call_deferred("run")
func frames(count: int = 4) -> void:
 for i in count: await physics_frame
 await process_frame
func press(code: Key) -> void:
 for down: bool in [true,false]:
  var event := InputEventKey.new()
  event.keycode=code;event.physical_keycode=code;event.pressed=down
  Input.parse_input_event(event)
  await frames(2)
func click(point: Vector2) -> void:
 point=root.get_final_transform()*point
 for down: bool in [true,false]:
  var motion:=InputEventMouseMotion.new()
  motion.position=point;motion.global_position=point
  Input.parse_input_event(motion)
  var event:=InputEventMouseButton.new()
  event.position=point;event.global_position=point
  event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
  event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
  Input.parse_input_event(event)
  await frames(2)
func snap(label: String) -> void:
 var ex=world.exploration
 var actors: Array=[]
 for actor in world.enemies:
  if not is_instance_valid(actor): continue
  actors.append({"id":actor.get_instance_id(),"name":actor.name,"state":String(actor.ai_state),"target_id":actor.target.get_instance_id() if is_instance_valid(actor.target) else 0,"target_player":actor.target==world.player,"hp":actor.hp,"position":str(actor.position),"distance":actor.position.distance_to(world.player.position),"los":actor.has_line_of_sight(),"visible":actor.is_visible_in_tree(),"windup":actor.windup_active,"search":actor.search_remaining,"nav":String(actor.nav_status),"physics":actor.is_physics_processing()})
 var buttons:Array=[]
 if ex.travel_panel.get_child_count()>0:
  for node in ex.travel_panel.get_child(0).get_children():
   if node is Button: buttons.append({"text":node.text,"rect":str(node.get_global_rect()),"disabled":node.disabled})
 var conditions:Dictionary={}
 for id:String in ["vigilia_anchor","district_anchor","courtyard_anchor","archive_anchor"]:
  var object=ex.objects[id]
  conditions[id]={"discovered":id in ex.anchors,"visible":object.visible,"distance":world.player.position.distance_to(object.position),"reachable":ex.reachable(object),"region":ex.definition_for(id).region}
 var row={"label":label,"ticks_ms":Time.get_ticks_msec(),"physics_frame":Engine.get_physics_frames(),"region":world.region_id,"position":str(world.player.position),"hp":world.player.hp,"player_id":world.player.get_instance_id(),"quest":world.quest_started,"menu":ex.travel_panel.visible,"menu_rect":str(ex.travel_panel.get_global_rect()),"lock":world.player.interaction_input_locked,"combat":ex.travel_combat_active(),"recent_damage":ex.recent_enemy_damage_active(),"last_damage":ex.last_enemy_damage_ms,"pending":ex.pending,"feedback":world.message_label.text,"actors":actors,"buttons":buttons,"anchors":conditions}
 rows.append(row)
 print("G2_TRACE ",JSON.stringify(row))
func shot(label: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(folder.path_join(label+".png"))
func fresh(region_id: String="map_01",clear_actors: bool=false) -> void:
 if is_instance_valid(world): world.queue_free();await frames()
 print("G2_FRESH ",region_id)
 Engine.set_meta("aethel_new_game",true)
 world=load("res://scenes/main.tscn").instantiate()
 root.add_child(world)
 await frames()
 if region_id!="map_01":
  world.quest_started=true;world.region_id=region_id;world._update_region()
 if clear_actors:
  for actor in world.enemies: actor.queue_free()
  world.enemies.clear()
 await frames()
func at_anchor(id: String) -> void:
 world.player.position=world.exploration.objects[id].position+Vector3(0,0,1)
 world.player.clear_commands()
 root.get_camera_3d().snap_to_target()
 await frames()
func discover_pair() -> void:
 # Authored discovery logic, not prefilled anchors. Teleports are test setup only.
 await fresh("map_02",true)
 world.region_id="map_01";world._update_region()
 await at_anchor("vigilia_anchor");await press(KEY_E)
 world.exploration.close_travel()
 world.region_id="map_02";world._update_region()
 for actor in world.enemies: actor.queue_free()
 world.enemies.clear()
 await at_anchor("district_anchor");await press(KEY_E)
func select(text: String) -> void:
 var ex=world.exploration
 for node in ex.travel_panel.get_child(0).get_children():
  if node is Button and node.text==text:
   await click(node.get_global_rect().get_center());return
 print("G2_NO_DESTINATION ",text)
var checks := 0
var failures:Array[String]=[]
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok: failures.append(label)
func run() -> void:
 if OS.get_environment("AETHEL_TEST_SAVE_DIR").is_empty(): quit(2);return
 await fresh();await at_anchor("vigilia_anchor");await press(KEY_E)
 var ex=world.exploration
 var text:=""
 for node in ex.travel_panel.get_child(0).get_children():
  if node is Label: text+=node.text
 check(ex.travel_panel.visible and "Nenhum outro destino" in text,"single discovered anchor explains empty menu")
 check(ex.anchors.size()==1 and not paused,"discovery through E and active world")
 await discover_pair();ex=world.exploration
 check(ex.anchors.size()==2 and ex.travel_panel.visible,"E discovers both anchors through real activation")
 var button:Button=ex.travel_panel.get_child(0).get_child(1)
 await click(button.get_global_rect().get_center())
 check(world.region_id=="map_01" and not ex.travel_panel.visible and not world.player.interaction_input_locked,"mouse selects discovered destination and releases controls")
 await press(KEY_E)
 button=ex.travel_panel.get_child(0).get_child(1);button.grab_focus();await press(KEY_ENTER)
 check(world.region_id=="map_02" and not ex.travel_panel.visible,"keyboard focus and Enter travel to discovered destination")
 # Arrival rebuilds the authored encounter; isolate non-combat refusal guards.
 for actor in world.enemies: actor.queue_free()
 world.enemies.clear();await frames()
 await press(KEY_E)
 var hp:int=world.player.hp
 check(not ex.travel("district_anchor","archive_anchor") and "Descubra" in world.message_label.text,"undiscovered destination explains refusal")
 check(not ex.travel("vigilia_anchor","district_anchor") and "nesta região" in world.message_label.text,"invisible source explains refusal")
 world.player.position=ex.objects.district_anchor.position+Vector3(0,0,3);world.player.clear_commands();await frames()
 await click(ex.travel_panel.get_child(0).get_child(1).get_global_rect().get_center())
 check(world.region_id=="map_02" and "Aproxime-se" in world.message_label.text,"out of range native destination click explains refusal")
 check(ex.travel_panel.visible and world.player.hp==hp,"feedback does not change HP or modal rule")
 await at_anchor("district_anchor");ex.close_travel();await press(KEY_E)
 world.regions.transitioning=true
 check(not ex.travel("district_anchor","vigilia_anchor") and "Aguarde" in world.message_label.text,"transition rejection explains wait")
 world.regions.transitioning=false
 await click(ex.travel_panel.get_child(0).get_child(1).get_global_rect().get_center())
 world.quest_started=false;await press(KEY_E)
 await click(ex.travel_panel.get_child(0).get_child(1).get_global_rect().get_center())
 check(world.region_id=="map_01" and "Maera" in world.message_label.text,"progression refusal replaces stale success feedback")
 await discover_pair();ex=world.exploration;ex.close_travel()
 var wall:=StaticBody3D.new();var collision:=CollisionShape3D.new()
 var shape:=BoxShape3D.new();shape.size=Vector3(2,3,0.2);collision.shape=shape
 wall.add_child(collision);world.add_child(wall)
 wall.position=ex.objects.district_anchor.position+Vector3(0,1,0.5)
 await frames();await press(KEY_E)
 check(not ex.travel_panel.visible and "obstruído" in world.message_label.text,"E explains obstructed anchor")
 check(not ex.travel("district_anchor","vigilia_anchor") and "obstruído" in world.message_label.text,"direct travel explains obstructed anchor")
 world.queue_free();await frames()
 for failure in failures: printerr("FALHA: ",failure)
 print("FIX03R2 FEEDBACK: %d checks, %d failures"%[checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
