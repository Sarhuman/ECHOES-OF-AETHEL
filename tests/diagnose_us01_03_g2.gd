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
func run() -> void:
 print("G2_RUN")
 folder=OS.get_environment("AETHEL_G2_EVIDENCE")
 if folder.is_empty() or OS.get_environment("AETHEL_TEST_SAVE_DIR").is_empty(): quit(2);return
 DirAccess.make_dir_recursive_absolute(folder)
 await fresh();await at_anchor("vigilia_anchor")
 snap("01_new_game_before_E");await press(KEY_E);snap("01_new_game_after_E");await shot("01-one-anchor")
 await discover_pair()
 snap("02_peaceful_pair_open");await shot("02-peaceful-menu")
 await click(world.exploration.travel_panel.get_child(0).get_child(1).get_global_rect().get_center())
 snap("02_after_first_destination_click")
 await discover_pair();world.exploration.close_travel()
 var actor=world._spawn_enemy(world.player.position+Vector3(-4,0,0),1,0)
 actor.set_physics_process(false);actor.ai_state=&"patrol"
 await press(KEY_E);snap("03_controlled_patrol_open")
 await click(world.exploration.travel_panel.get_child(0).get_child(1).get_global_rect().get_center())
 snap("03_controlled_patrol_after_click")
 await discover_pair();world.exploration.close_travel()
 actor=world._spawn_enemy(world.player.position+Vector3(-4,0,0),1,0)
 actor.set_physics_process(false);actor.ai_state=&"chase"
 await press(KEY_E);snap("04_controlled_chase_E");await shot("04-controlled-chase")
 # Change only fixture state to probe the render/physics ordering of the gate.
 actor.ai_state=&"patrol";await press(KEY_E);snap("05_before_threat")
 actor.ai_state=&"chase";snap("05_same_frame_after_threat")
 await frames(1);snap("05_one_frame_after_threat");await shot("05-after-threat")
 # Actual actor physics must acquire the player after a peaceful opening.
 await discover_pair();world.exploration.close_travel()
 actor=world._spawn_enemy(world.player.position+Vector3(-4,0,0),1,0)
 actor.set_physics_process(false);actor.ai_state=&"patrol"
 await press(KEY_E);snap("05_live_before_threat")
 actor.set_physics_process(true)
 await frames(1);snap("05_live_after_one_frame")
 await frames(2);snap("05_live_after_three_frames");await shot("05-live-after-threat")
 # Live authored encounter, no frozen enemies or replaced target/states.
 await fresh("map_02");await at_anchor("district_anchor")
 await frames(60);snap("06_authored_encounter_before_E")
 await press(KEY_E);snap("06_authored_encounter_after_E");await shot("06-authored-anchor")
 # UI approach from outside reach, including the ray and actual click.
 await fresh("map_02",true)
 world.player.position=world.exploration.objects.district_anchor.position+Vector3(0,0,4)
 world.player.clear_commands();root.get_camera_3d().snap_to_target();await frames()
 var screen:Vector2=root.get_camera_3d().unproject_position(world.exploration.objects.district_anchor.global_position+Vector3(0,0.7,0))
 print("G2_WORLD_PICK ",world.exploration.pick(screen)," at ",screen)
 snap("07_before_world_click");await click(screen);await frames(180);snap("07_after_world_click_approach")
 # Classifier matrix: reference identity persists even in non-hostile states.
 actor=world._spawn_enemy(world.player.position+Vector3(-4,0,0),1,0)
 actor.set_physics_process(false)
 for state:StringName in [&"patrol",&"return",&"chase",&"search",&"attack",&"hit"]:
  actor.ai_state=state;actor.search_remaining=2
  snap("08_matrix_"+String(state))
 actor.search_remaining=0;snap("08_hit_without_memory")
 actor.ai_state=&"chase";actor.target=null;snap("08_chase_without_target")
 actor.target=world.player;actor.hide();snap("08_hidden_chase_with_target")
 # Non-combat travel guards: preserve their real return and feedback.
 await discover_pair()
 var result:bool=world.exploration.travel("district_anchor","archive_anchor")
 snap("09_undiscovered_destination");rows[-1]["travel_return"]=result
 result=world.exploration.travel("vigilia_anchor","district_anchor")
 snap("09_invisible_source");rows[-1]["travel_return"]=result
 world.player.position=world.exploration.objects.district_anchor.position+Vector3(0,0,3)
 world.player.clear_commands();await frames()
 await click(world.exploration.travel_panel.get_child(0).get_child(1).get_global_rect().get_center())
 snap("09_out_of_reach_destination_click")
 await at_anchor("district_anchor")
 world.exploration.close_travel();await press(KEY_E)
 await click(world.exploration.travel_panel.get_child(0).get_child(1).get_global_rect().get_center())
 world.quest_started=false;await press(KEY_E)
 await click(world.exploration.travel_panel.get_child(0).get_child(1).get_global_rect().get_center())
 snap("09_progression_destination_click")
 await discover_pair();world.exploration.close_travel()
 var wall:=StaticBody3D.new()
 var collision:=CollisionShape3D.new()
 var shape:=BoxShape3D.new();shape.size=Vector3(2,3,0.2)
 collision.shape=shape;wall.add_child(collision);world.add_child(wall)
 wall.position=world.exploration.objects.district_anchor.position+Vector3(0,1,0.5)
 await frames();await press(KEY_E);snap("09_occluded_source_E")
 var file:=FileAccess.open(folder.path_join("trace.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify({"engine":Engine.get_version_info(),"display":DisplayServer.get_name(),"executable":OS.get_executable_path(),"rows":rows},"\t"));file.close()
 world.queue_free();await frames()
 print("G2_DIAGNOSTIC_COMPLETE: ",rows.size()," snapshots; no production changes")
 quit(0)
