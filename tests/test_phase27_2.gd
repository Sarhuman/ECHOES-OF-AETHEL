extends SceneTree
var checks:=0
var failures: Array[String]=[]
var world: Node3D
var skill_count:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures.append(message)
func frames(count:=3) -> void:
	for i in count: await physics_frame
	await process_frame
func run() -> void:
	Engine.set_meta("aethel_new_game",true)
	world=load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await frames(8)
	var actor: CharacterBody3D=world.player
	var visual: AethelCharacterVisual=actor.get_node("BastiaoVisual")
	check(visual.mode=="PLACEHOLDER" and visual._model.has_method("set_motion"),"original placeholder is still the production default")
	check(not visual.select_mode("IMPORTED_MODEL") and visual.mode=="PLACEHOLDER","missing real model falls back")
	var original: AethelCharacterVisualDefinition=visual.definition
	var definition: AethelCharacterVisualDefinition=load("res://data/characters/bastion_fixture_visual.tres")
	visual.definition=definition
	var before:=JSON.stringify({"hp":actor.hp,"ether":actor.ether,"stamina":actor.stamina,"equipment":actor.equipped.keys(),"stats":actor.stats.serialize()})
	var at: Transform3D=actor.transform
	var collision: Shape3D=actor.find_children("*","CollisionShape3D",false,false)[0].shape
	check(visual.select_mode("IMPORTED_MODEL"),"real imported GLB fixture passes validation")
	await frames()
	check(visual.mode=="IMPORTED_MODEL" and visual.last_validation.valid,"imported selection recorded")
	check(visual.last_validation.triangles==80 and visual.last_validation.bones==4 and visual.last_validation.materials==1,"GLB geometry skin and material metrics")
	check(actor.find_children("*","CollisionShape3D",false,false)[0].shape==collision,"same collision resource")
	check(actor.transform.origin.distance_to(at.origin)<0.02,"same actor position")
	check(JSON.stringify({"hp":actor.hp,"ether":actor.ether,"stamina":actor.stamina,"equipment":actor.equipped.keys(),"stats":actor.stats.serialize()})==before,"resources stats and equipment preserved")
	for socket: String in definition.socket_names: check(visual._model.find_child(socket,true,false)!=null,"socket "+socket)
	var adapter:=visual.equipment_adapter()
	for pair: Array in [["helmet","helmet"],["chest","chest"],["gloves","gloves"],["boots","boots"],["cape","cape"],["weapon_main","sword"],["offhand","shield"]]:
		check(adapter.apply_equipment(StringName(pair[0]),StringName(pair[1]),&"common"),"existing adapter slot "+str(pair[0]))
	check(AethelVisualAssetValidator.inspect(visual._model,definition).materials==1,"equipped authored materials stay shared")
	var equipment:=adapter.snapshot()
	actor.attack_cooldown=0.5
	actor.skill_cooldowns["heavy_strike"]=1.25
	var inventory_before: Dictionary=world.inventory.serialize()
	check(visual.select_mode("PLACEHOLDER"),"reversible placeholder selection")
	check(actor.attack_cooldown==0.5 and actor.skill_cooldowns.heavy_strike==1.25 and world.inventory.serialize()==inventory_before,"active combat timers and inventory survive visual swap")
	check(visual.equipment_adapter().snapshot()==equipment,"equipment restored on fallback")
	check(visual.select_mode("IMPORTED_MODEL") and visual.equipment_adapter().snapshot()==equipment,"equipment restored on import")
	for state: String in definition.animation_map:
		visual.play_action(StringName(state),0.2)
		visual._player.advance(0.1)
		check(visual._player.current_animation==str(definition.animation_map[state]),"animation map "+state)
		check(actor.hp==int(JSON.parse_string(before).hp),"animation does not apply damage "+state)
	var hand:=visual._model.find_child("SocketMain",true,false) as BoneAttachment3D
	var skeleton:=hand.get_parent() as Skeleton3D
	visual.play_action(&"attack_1",0.45)
	visual._player.advance(0.2)
	check(not skeleton.get_bone_pose_rotation(skeleton.find_bone("hand_r")).is_equal_approx(Quaternion.IDENTITY),"imported skeletal rotation changes hand pose")
	# Check rejection with actual modified candidates, rather than merely inspecting constants.
	var candidate:=definition.imported_scene.instantiate() as Node3D
	root.add_child(candidate)
	var strict:=definition.duplicate() as AethelCharacterVisualDefinition
	strict.max_triangles=1
	check(not AethelVisualAssetValidator.inspect(candidate,strict).valid,"over-budget triangles rejected")
	strict=definition.duplicate();strict.max_deforming_bones=1
	check(not AethelVisualAssetValidator.inspect(candidate,strict).valid,"over-budget bones rejected")
	strict=definition.duplicate();strict.max_materials=0
	check(not AethelVisualAssetValidator.inspect(candidate,strict).valid,"over-budget actual materials rejected")
	strict=definition.duplicate();strict.max_influences=0
	check(not AethelVisualAssetValidator.inspect(candidate,strict).valid,"skin influence budget rejected")
	var fixture_mesh:=candidate.find_child("Body",true,false) as MeshInstance3D
	var oversized_material:=StandardMaterial3D.new()
	oversized_material.albedo_texture=ImageTexture.create_from_image(Image.create(2048,1,false,Image.FORMAT_RGBA8))
	fixture_mesh.material_override=oversized_material
	check(not AethelVisualAssetValidator.inspect(candidate,definition).valid,"oversized texture rejected")
	fixture_mesh.material_override=null
	var missing_socket:=candidate.find_child("SocketMain",true,false)
	missing_socket.name="MissingMain"
	check(not AethelVisualAssetValidator.inspect(candidate,definition).valid,"missing hand socket rejected")
	missing_socket.name="SocketMain"
	strict=definition.duplicate();strict.provenance_status="PENDING"
	check(not AethelVisualAssetValidator.inspect(candidate,strict).valid,"undocumented provenance rejected")
	candidate.scale=Vector3.ONE*2
	check(not AethelVisualAssetValidator.inspect(candidate,definition).valid,"unapplied scale rejected")
	candidate.scale=Vector3.ONE
	candidate.find_child("Forward",true,false).position=Vector3.BACK
	check(not AethelVisualAssetValidator.inspect(candidate,definition).valid,"wrong facing rejected")
	candidate.find_child("Forward",true,false).position=Vector3.FORWARD
	var authority:=StaticBody3D.new()
	candidate.add_child(authority)
	check(not AethelVisualAssetValidator.inspect(candidate,definition).valid,"physics authority inside model rejected")
	authority.free()
	var player:=candidate.find_child("AnimationPlayer",true,false) as AnimationPlayer
	var unsafe_clip:=Animation.new()
	unsafe_clip.add_track(Animation.TYPE_METHOD)
	player.get_animation_library("").add_animation("unsafe",unsafe_clip)
	check(not AethelVisualAssetValidator.inspect(candidate,definition).valid,"method animation tracks rejected")
	player.get_animation_library("").remove_animation("unsafe")
	var outside:=Animation.new()
	outside.add_track(Animation.TYPE_POSITION_3D)
	outside.track_set_path(0,NodePath("../.."))
	player.get_animation_library("").add_animation("outside",outside)
	check(not AethelVisualAssetValidator.inspect(candidate,definition).valid,"animation cannot target nodes outside model")
	player.get_animation_library("").remove_animation("outside")
	var root_motion:=Animation.new()
	root_motion.add_track(Animation.TYPE_POSITION_3D)
	root_motion.track_set_path(0,NodePath(str(player.get_animation("idle").track_get_path(0)).get_slice(":",0)+":"+skeleton.get_bone_name(0)))
	player.get_animation_library("").add_animation("root_motion",root_motion)
	check(not AethelVisualAssetValidator.inspect(candidate,definition).valid,"root bone translation rejected")
	player.get_animation_library("").remove_animation("root_motion")
	check(AethelVisualAssetValidator.inspect(candidate,definition).valid,"clean candidate accepted again")
	candidate.queue_free()
	visual.definition=strict
	check(not visual.select_mode("IMPORTED_MODEL") and visual.mode=="PLACEHOLDER","invalid import automatically falls back")
	visual.definition=definition
	check(visual.select_mode("IMPORTED_MODEL"),"recover from invalid candidate")
	# Actual combat authority remains live; a newly spawned enemy can deal and receive damage.
	world.quest_started=true;world.region_id="map_03";world._update_region()
	actor.position=Vector3.ZERO
	await frames()
	var enemy: CharacterBody3D=world._spawn_enemy(Vector3(0,0,-1.4),1,0)
	enemy.hp=10000;enemy.max_hp=10000;enemy.defense=0
	actor.facing=Vector3.FORWARD
	actor.skill_used.connect(func(_id: String) -> void: skill_count+=1)
	for id: String in ["heavy_strike","echo_cleave","iron_guard"]:
		actor.attack_cooldown=0;actor.attack_recovery=0;actor.skill_cooldowns.clear();actor.ether=actor.max_ether
		var hp_before: int=enemy.hp
		var ether_before: int=actor.ether
		for candidate_seed in 100:
			seed(candidate_seed)
			if randf()<0.5: seed(candidate_seed);break
		check(actor.use_skill(world.skill_tree.catalog[id]).is_empty(),"real skill success "+id)
		check(actor.ether==ether_before-world.skill_tree.catalog[id].ether_cost,"one authoritative resource cost "+id)
		check(visual._player.current_animation==str(definition.animation_map[id]),"real skill maps to imported clip "+id)
		if id!="iron_guard": check(enemy.hp<hp_before,"real damage "+id)
		var hp_after: int=enemy.hp
		visual._player.advance(0.15)
		check(enemy.hp==hp_after,"animation advancement cannot duplicate damage "+id)
	check(skill_count==3,"one skill event per successful action")
	actor.invulnerability=0
	var old_hp: int=actor.hp
	actor.take_damage(5)
	check(actor.hp<old_hp,"actual damage received with imported visual")
	world._save_state()
	var saved_position: Vector3=actor.position
	actor.position=Vector3(0,0,8)
	world._load_state()
	check(world.region_id=="map_03" and actor.position.distance_to(saved_position)<0.3,"same save/load and region")
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(world.SAVE_PATH))
	check(not saved.has("visual_mode") and int(saved.version)==6,"no save schema migration for visual mode")
	actor.invulnerability=0
	actor.take_damage(99999)
	check(actor.hp==0 and visual._player.current_animation=="death","real death selects imported death without moving actor")
	visual.definition=original
	visual.select_mode("PLACEHOLDER")
	world.queue_free()
	await frames()
	# Existing restart creates a fresh actor, not a visual-owned respawn system.
	Engine.set_meta("aethel_new_game",true)
	world=load("res://scenes/main.tscn").instantiate();root.add_child(world)
	await frames(4)
	check(world.player.hp>0 and world.player.get_node("BastiaoVisual").mode=="PLACEHOLDER","new game after defeat retains healthy fallback")
	world.queue_free()
	await frames()
	for failure in failures: print("FALHA: "+failure)
	print("PHASE27.2: %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
