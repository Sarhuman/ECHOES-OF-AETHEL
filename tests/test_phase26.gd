extends SceneTree
var checks := 0
var failures: Array[String] = []
var world: Node3D
var skill_events := 0
var cooldown_events := 0
func check(ok: bool,text: String) -> void:
 checks += 1
 if not ok: failures.append(text)
func _initialize() -> void: call_deferred("run")
func frames(count: int = 3) -> void:
 for i in count: await physics_frame
 await process_frame
func run() -> void:
 root.size=Vector2i(1280,720)
 Engine.set_meta("aethel_new_game",true)
 world=load("res://scenes/main.tscn").instantiate()
 root.add_child(world)
 await frames(8)
 var hud: AethelHUDManager=world.hud
 var actor: CharacterBody3D=world.player
 check(hud.hp_bar != null and hud.ether_bar != null,"compact resources reuse reactive HUD")
 actor.hp_changed.emit(45,100)
 actor.ether_changed.emit(12,40)
 actor.stamina_changed.emit(6,100)
 check(hud.hp_bar.value==45 and hud.ether_bar.value==12 and hud.stamina_bar.value==6,"three resource events")
 check("45%" in hud.hp_text.text and "30%" in hud.ether_text.text,"resource percentages visible")
 check("BAIXO" in hud.stamina_text.text,"insufficient stamina text")
 hud._on_hp_changed(10,0,true)
 check(hud.hp_bar.value==0,"zero maximum safe")
 var globe:=AethelGlobe.new()
 root.add_child(globe)
 globe.hide()
 globe.set_shader_enabled(false)
 check(not globe.surface.visible and globe.progress.visible,"reusable globe fallback remains available independently")
 globe.queue_free()
 actor.restore_full()
 await frames(3)
 hud.setup_player_listeners(actor)
 hud.setup_player_listeners(actor)
 check(actor.hp_changed.get_connections().size()==1,"resource listeners not duplicated")
 hud.bind_world(world)
 hud.bind_world(world)
 check(world.target_changed.get_connections().size()==1,"target listener not duplicated")
 var updates: int=hud.presentation_updates
 await frames(30)
 check(hud.presentation_updates==updates,"stable HUD avoids skill/style rebuilds")
 # Offensive presentation is now exercised in a hostile region, not the safe hub.
 world.region_id="map_03"
 world._update_region()
 actor.position=Vector3.ZERO
 actor.skill_used.connect(func(_id: String) -> void: skill_events+=1)
 actor.cooldown_changed.connect(func(_id: String,_remaining: float) -> void: cooldown_events+=1)
 actor.ether=actor.max_ether
 actor.attack_cooldown=0
 world._activate_skill("heavy_strike")
 check(skill_events==1 and actor.skill_cooldowns.has("heavy_strike"),"one skill-used event")
 check("Recarga" in hud.skill_buttons[0].text,"cooldown label")
 world._activate_skill("heavy_strike")
 check(skill_events==1,"rejected cast emits no duplicate event")
 await frames(70)
 check(not "Recarga" in hud.skill_buttons[0].text and cooldown_events>0,"cooldown completion event")
 actor.ether=actor.max_ether
 actor.attack_cooldown=0
 world._activate_skill("iron_guard")
 check(hud.effect_badges.has("guard"),"real Guard effect badge")
 actor.guard_remaining=0
 actor._emit_ui_state()
 check(not hud.effect_badges.has("guard"),"effect removal")
 world.exploration.buffs={"remaining":30.0,"reduction":0.2,"source":"district_altar"}
 world.exploration.apply_buffs()
 check(hud.effect_badges.has("altar") and "20%" in hud.effect_badges.altar.tooltip_text,"altar intensity and tooltip")
 world.exploration.tick(31)
 check(not hud.effect_badges.has("altar"),"altar expires through owner event")
 var enemy: CharacterBody3D=world._spawn_enemy(Vector3(2,0,0),1,2)
 enemy.set_physics_process(false)
 enemy.set_meta("category","boss")
 enemy.monster_name="Chefe de teste — não canônico"
 world.target_changed.emit(enemy)
 check(hud.boss_box.visible and not hud.target_box.visible,"dedicated boss bar")
 var hp: int=enemy.hp
 enemy.take_damage(10)
 check(hud.boss_bar.value==hp-10,"boss damage signal updates bar")
 enemy.set_meta("category","champion")
 enemy.presentation_changed.emit()
 check(not hud.boss_box.visible and hud.target_box.visible and "Campeão" in hud.target_name.text,"category presentation")
 enemy.take_damage(100000)
 await frames()
 check(not hud.target_box.visible and not hud.boss_box.visible,"removed target signals disconnected")
 var xp: int=world.progression.current_xp
 world.progression.gain_xp(7)
 check(hud.xp_bar.value==world.progression.current_xp and ("Nv %d"%world.progression.current_level) in hud.status_header.text,"real XP event")
 world.progression.gain_xp(world.progression.required_xp(world.progression.current_level))
 check(("Nv %d"%world.progression.current_level) in hud.status_header.text,"level update")
 for bus: String in ["Master","Music","SFX","UI","Ambience"]: check(AudioServer.get_bus_index(bus)>=0,"audio bus "+bus)
 var count: int=AudioServer.bus_count
 AethelAudioManager.ensure_buses()
 check(AudioServer.bus_count==count,"no duplicate audio buses")
 var before: int=int(world.audio.played_cues.get("inventory",0))
 world.audio.play_cue("inventory",true)
 world.audio.play_cue("inventory",true)
 check(int(world.audio.played_cues.get("inventory",0))<=before+1,"audio cue rate limit")
 check(world.audio.active_voices<=8,"bounded audio voices")
 AethelSettings.channel_volumes.UI=0.25
 AethelSettings.hud_scale=1.1
 AethelSettings.shader_globes=false
 AethelSettings.save_settings()
 AethelSettings.channel_volumes.UI=1
 AethelSettings.hud_scale=0.85
 AethelSettings.shader_globes=true
 AethelSettings.load_settings()
 check(AethelSettings.channel_volumes.UI==0.25 and AethelSettings.hud_scale==1.1 and not AethelSettings.shader_globes,"preferences persisted separately")
 check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("UI"))-linear_to_db(0.25))<0.01,"bus gain applied")
 hud.apply_settings()
 check(hud.resource_panel.scale==Vector2.ONE*1.1,"HUD settings applied")
 for row: Dictionary in world.inventory.entries(): world.inventory.remove_item(row.instance.instance_id)
 var potion:=AethelItemInstance.new(world.item_catalog.hp_small,"discard-stack")
 potion.quantity=7
 check(world.inventory.add_item(potion),"discard fixture uses real bag")
 var gold: int=world.gold
 world._on_discard_requested(potion.instance_id)
 check(world.inventory.find_item(potion.instance_id)==null and world.gold==gold,"discard removes bag stack without currency")
 var dropped: AethelDroppedItem
 for drop: AethelDroppedItem in world.dropped_items:
  if drop.item != null and drop.item.instance_id==potion.instance_id: dropped=drop
 check(dropped!=null and dropped.item.quantity==7,"same stack exists on ground")
 var count_drops: int=world.dropped_items.size()
 world._on_discard_requested(potion.instance_id)
 check(world.dropped_items.size()==count_drops,"stale discard cannot duplicate")
 world._save_state()
 check(world._load_state(),"discard state uses existing save v6")
 var matches:=0
 for drop: AethelDroppedItem in world.dropped_items:
  if drop.item != null and drop.item.instance_id==potion.instance_id: matches+=1; dropped=drop
 check(matches==1,"discarded stack persisted once")
 for i in 4: world.belt[i]={"kind":"hp_small","count":4}
 check(world._collect_drop(dropped) and world.inventory.find_item(potion.instance_id).quantity==7,"discard can be recovered intact")
 var quest:=AethelItemInstance.new(world.item_catalog.quest_seal,"protected-discard")
 world.inventory.add_item(quest)
 world._on_discard_requested(quest.instance_id)
 check(world.inventory.find_item(quest.instance_id)!=null,"quest item discard blocked")
 var tooltip: AethelItemTooltip=world.shop_tooltip
 var shield:=AethelItemInstance.new(world.item_catalog.wood_shield)
 var glass: AethelItemInstance=world.loot_generator.roll_item(8,2,0,2)
 glass.custom_name="Eco de Vidro"
 for item: AethelItemInstance in [shield,glass]:
  tooltip.show_item_at(item,Rect2(30,430,300,45))
  tooltip.append_comparison(item,actor.equipped.get("shield"))
  await frames(4)
  var rect: Rect2=tooltip.get_global_rect()
  for i in 40:
   await process_frame
   check(tooltip.get_global_rect()==rect,"stable tooltip "+item.display_name())
  check(root.get_visible_rect().encloses(rect),"tooltip remains in viewport")
 check(tooltip._text.get_v_scroll_bar().mouse_filter==Control.MOUSE_FILTER_IGNORE,"scrollbar cannot steal item hover")
 tooltip.hide_item()
 for i in 50: world._on_combat_event(actor.position,"12","damage")
 check(world.active_popups.size()<=32,"floating text cap")
 world.quest_started=true
 world.map_02_cleared=true
 world._check_mission_change()
 check("retornar" in world.quest_text.text,"journal consumes real quest flags")
 world.pause_menu.open()
 check(paused and world.pause_menu.overlay.visible,"pause menu")
 world.pause_menu.resume()
 check(not paused,"resume")
 actor.restore_full()
 world._save_state()
 actor.invulnerability=0
 actor.take_damage(100000)
 check(world.game_over and world.death_overlay.visible,"death overlay")
 var bag_before: int=world.inventory.entries().size()
 world._on_discard_requested(quest.instance_id)
 check(world.inventory.entries().size()==bag_before,"death blocks inventory actions")
 check(world._load_state() and not world.game_over and not world.death_overlay.visible,"load resumes after death without corpse loss")
 world.queue_free()
 await frames()
 for text in failures: print("FALHA: "+text)
 print("PHASE26: %d checks, %d failures" % [checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
