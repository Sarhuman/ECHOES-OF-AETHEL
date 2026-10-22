extends SceneTree
var checks := 0
var failures: Array[String] = []
var world: Node3D
func check(ok: bool, text: String) -> void:
 checks += 1
 if not ok: failures.append(text)
func frames(count: int = 4) -> void:
 for i in count: await physics_frame
 await process_frame
func key(code: Key) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.physical_keycode = code
 event.pressed = true
 Input.parse_input_event(event)
 await frames(2)
 event = event.duplicate()
 event.pressed = false
 Input.parse_input_event(event)
 await frames(2)
func capture(label: String) -> void:
 if DisplayServer.get_name() == "headless": return
 var folder := OS.get_environment("AETHEL_CAPTURE_DIR")
 if folder.is_empty(): return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(folder.path_join(label + ".png"))
func _initialize() -> void: call_deferred("run")
func run() -> void:
 if OS.get_environment("AETHEL_TEST_SAVE_DIR").is_empty():
  quit(2)
  return
 Engine.set_meta("aethel_new_game", true)
 world = load("res://scenes/main.tscn").instantiate()
 root.add_child(world)
 await frames()
 world.region_id = "map_03"
 world._update_region()
 # Disable fixture actors only: no enemy implementation or balance changes.
 for enemy in world.enemies: enemy.set_physics_process(false)
 var actor: CharacterBody3D = world.player
 var visual: AethelCharacterVisual = actor.get_node("BastiaoVisual")
 var model: Node3D = visual._model
 actor.position = world.regions.level.safe_position(Vector3.ZERO)
 actor.command_stand_attack(actor.position + Vector3(0,0,-2))
 await frames(2)
 check(actor.attack_cooldown > 0, "living actor enters combat")
 actor.clear_commands()
 actor.hp = actor.max_hp - 10
 var bag_before: Dictionary = world.inventory.serialize()
 var equipment_before: Dictionary = {}
 for slot in actor.equipped: equipment_before[slot] = actor.equipped[slot].serialize()
 await key(KEY_F5)
 var saved: Dictionary = world._read_save_payload(world.SAVE_PATH)
 check(not saved.is_empty() and saved.hp > 0, "positive HP snapshot saved via F5")
 var saved_position := Vector3(saved.position[0], saved.position[1], saved.position[2])
 actor.invulnerability = 0
 actor.take_damage(actor.max_hp * 2)
 await frames(30)
 check(actor.hp == 0 and world.game_over, "actual damage produces death and overlay")
 check(model._visual_state == &"death" and model.torso.rotation.z > 1, "procedural model actually fallen")
 await capture("fix01-dead")
 # Poison only nonpersisted state to expose blocked controls after restoration.
 actor.interaction_input_locked = true
 actor.attack_recovery = 99
 actor.attack_cooldown = 99
 actor.dash_remaining = 99
 actor.invulnerability = 99
 actor.skill_cooldowns["heavy_strike"] = 99
 await key(KEY_F9)
 check(actor.hp == int(saved.hp) and not world.game_over, "F9 after death loads living snapshot")
 # Continue diagnostic even when the input path failed, to isolate visual failure.
 if world.game_over: check(world._load_state(), "direct load succeeds")
 check(actor.hp == int(saved.hp), "HP restored")
 check(actor.position.distance_to(saved_position) < 0.25, "position restored")
 check(not actor.interaction_input_locked and actor.attack_recovery == 0 and actor.dash_remaining == 0 and actor.invulnerability == 0, "transient control locks cleared")
 check(not visual._state == &"death" and visual._action_time == 0, "presentation death action cleared")
 check(model._visual_state != &"death", "model internal death state cleared")
 check(absf(model.torso.rotation.z) < 0.05, "model torso upright immediately")
 await frames(30)
 check(absf(model.torso.rotation.z) < 0.05, "death tween cannot reapply fallen pose")
 check(actor.skill_cooldowns.is_empty(), "stale skill recovery cleared on load")
 await capture("fix01-restored")
 check(not world.death_overlay.visible, "death overlay removed")
 check(world.inventory.serialize() == bag_before, "inventory preserved")
 var equipment: Dictionary = {}
 for slot in actor.equipped: equipment[slot] = actor.equipped[slot].serialize()
 check(equipment == equipment_before, "equipment preserved")
 check(world.narrative.serialize() == saved.narrative and world.slain == int(saved.slain), "mission and narrative preserved")
 var start: Vector3 = actor.position
 Input.action_press("move_right")
 await frames(15)
 Input.action_release("move_right")
 check(actor.position.distance_to(start) > 0.2, "keyboard movement works after reload")
 await capture("fix01-moving")
 check(model.is_moving, "model locomotion works after reload")
 actor.command_stand_attack(actor.position + Vector3(0,0,-2))
 await frames(2)
 check(actor.attack_cooldown > 0 and visual._state in [&"attack_1", &"attack_2"], "basic attack command and visual work")
 actor.clear_commands()
 await frames(60)
 actor.ether = actor.max_ether
 var before_ether: int = actor.ether
 world._activate_skill("heavy_strike")
 check(actor.ether < before_ether and float(actor.skill_cooldowns.get("heavy_strike", 0)) > 0, "world skill input route works after reload")
 # Reload while the death tween is still running, not only after completion.
 actor.invulnerability = 0
 actor.take_damage(actor.max_hp * 2)
 check(world._load_state(), "load during death tween")
 await frames(30)
 check(model._visual_state != &"death" and absf(model.torso.rotation.z) < 0.05, "in-flight death tween cancelled")
 # A snapshot saved dead must stay dead, including when loaded from living state.
 actor.invulnerability = 0
 actor.take_damage(actor.max_hp * 2)
 world._save_state()
 actor.hp = actor.max_hp
 world.game_over = false
 visual.reset_after_load()
 check(world._load_state(), "zero HP snapshot accepted")
 check(model._visual_state == &"death", "zero HP snapshot has death visual state")
 check(actor.hp == 0 and world.game_over and world.death_overlay.visible, "zero HP snapshot never resurrects")
 var dead_position: Vector3 = actor.position
 Input.action_press("move_right")
 await frames(15)
 Input.action_release("move_right")
 check(actor.position.distance_to(dead_position) < 0.05, "dead snapshot cannot move")
 check(not actor.use_skill(world.skill_tree.catalog.heavy_strike).is_empty(), "dead snapshot cannot use skill")
 for failure in failures: printerr("FALHA: ", failure)
 print("FIX01 REGRESSION: %d checks, %d failures" % [checks, failures.size()])
 world.queue_free()
 await frames()
 quit(0 if failures.is_empty() else 1)
