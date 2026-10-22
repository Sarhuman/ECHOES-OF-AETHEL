extends SceneTree
class DummyPlayer extends CharacterBody3D:
 var hp := 1000
 var hits := 0
 func receive_attack(_damage: int, _rating: int, _level: int) -> String:
  hits += 1
  return "hit"
 func take_damage(_amount: int) -> void: hits += 1
var failures: Array[String] = []
var checks := 0
var fixture: Node3D
var player: DummyPlayer
var enemy: CharacterBody3D
var region: NavigationRegion3D
var nav_map: RID
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok: failures.append(label)
func frames(count: int) -> void:
 for i in count: await physics_frame
 await process_frame
func box(at: Vector3, size: Vector3) -> StaticBody3D:
 var body := StaticBody3D.new()
 var collision := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = size
 collision.shape = shape
 body.add_child(collision)
 fixture.add_child(body)
 body.position = at
 return body
func spawn(at: Vector3) -> CharacterBody3D:
 var actor := CharacterBody3D.new()
 actor.set_script(load("res://scripts/hybrid_enemy.gd"))
 actor.target = player
 fixture.add_child(actor)
 actor.position = at
 actor.navigation_agent.set_navigation_map(nav_map)
 return actor
func setup(blocks: Array[Rect2] = [], navigation: bool = true, nav_blocks: Array[Rect2] = []) -> void:
 if fixture != null:
  fixture.queue_free()
  await frames(3)
  NavigationServer3D.free_rid(nav_map)
 fixture = Node3D.new()
 root.add_child(fixture)
 nav_map = NavigationServer3D.map_create()
 if navigation: NavigationServer3D.map_set_active(nav_map, true)
 box(Vector3(0,-0.3,0), Vector3(30,0.6,30))
 for rect in blocks: box(Vector3(rect.get_center().x,1.5,rect.get_center().y),Vector3(rect.size.x,3,rect.size.y))
 region = NavigationRegion3D.new()
 region.set_navigation_map(nav_map)
 var mesh := NavigationMesh.new()
 var vertices := PackedVector3Array()
 var ids: Dictionary = {}
 for x in range(-12,12):
  for z in range(-12,12):
   var blocked := false
   for rect in blocks + nav_blocks:
    if rect.grow(0.6).has_point(Vector2(x+0.5,z+0.5)): blocked = true
   if blocked: continue
   var polygon := PackedInt32Array()
   for corner in [Vector2i(x,z),Vector2i(x,z+1),Vector2i(x+1,z+1),Vector2i(x+1,z)]:
    if not ids.has(corner): ids[corner] = vertices.size(); vertices.append(Vector3(corner.x,0,corner.y))
    polygon.append(ids[corner])
   mesh.add_polygon(polygon)
 mesh.set_vertices(vertices)
 region.navigation_mesh = mesh
 if navigation: fixture.add_child(region)
 player = DummyPlayer.new()
 fixture.add_child(player)
 player.position = Vector3(5,0,0)
 enemy = spawn(Vector3(-5,0,0))
 if navigation: NavigationServer3D.map_force_update(nav_map)
 await frames(5)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 await setup()
 var initial: Vector3 = enemy.position
 await frames(30)
 check(enemy.ai_state == &"chase" and enemy.position.distance_to(initial) > 0.5,"open area detects and physically chases")
 await setup([Rect2(-1,-3,2,6)])
 await frames(50)
 check(enemy.ai_state != &"chase", "wall prevents proximity acquisition")
 # Observe first, then move behind a pillar; the remembered point must not track hidden motion.
 player.position = Vector3(-4,0,-5)
 await frames(2)
 check(enemy.ai_state == &"chase", "visible player acquired before hiding")
 var last_seen: Vector3 = player.position
 player.position = Vector3(5,0,0)
 await frames(2)
 check(enemy.ai_state == &"search", "loss of sight enters search")
 check(enemy.get("last_known_position") is Vector3 and enemy.get("last_known_position").distance_to(last_seen) < 0.2,"search uses observed position only")
 # Search at last seen point is bounded even when no route becomes available.
 await frames(400)
 check(enemy.ai_state in [&"return", &"patrol"], "lost player search expires")
 player.position = enemy.position + Vector3(-4 if enemy.position.x < 0 else 4,0,0)
 var reacquired := false
 for i in 200:
  await frames(1)
  if enemy.ai_state == &"chase": reacquired = true
 check(reacquired, "reappearing player reacquired")
 # A remembered reachable point on the far side requires a genuine detour.
 await setup([Rect2(-1,-2,2,4)])
 if enemy.get("last_known_position") is Vector3:
  enemy.last_known_position = player.position
  enemy.search_remaining = 10.0
  enemy.ai_state = &"search"
 var max_z := 0.0
 for i in 230:
  await frames(1)
  max_z = maxf(max_z, absf(enemy.position.z))
 check(enemy.position.x > 1.5 and max_z > 2.3, "agent physically routes around pillar")
 # Disconnected cells with a clear sightline: synchronized map, unreachable goal.
 await setup([],true,[Rect2(-1,-12,2,24)])
 initial = enemy.position
 await frames(30)
 check(enemy.get("nav_status") == &"unavailable","navigation failure has explicit status")
 await frames(70)
 check(enemy.position.distance_to(initial) < 0.4,"unavailable navigation has no direct-motion fallback")
 await frames(300)
 check(enemy.position.x < -3,"disconnected agent never walks toward target through the gap")
 # Stale walkable polygons cannot justify endlessly pushing a physical wall.
 await setup()
 box(Vector3(0,1.5,0),Vector3(2,3,26))
 var blocked_seen := false
 for i in 360:
  await frames(1)
  if enemy.get("nav_status") == &"blocked": blocked_seen = true
 check(blocked_seen,"physical wall produces blocked navigation status")
 check(enemy.ai_state in [&"patrol", &"return"] and enemy.position.x < -3,"blocked search ends and returns instead of pushing wall")
 # First synchronization: there is a map RID but no navigation iteration yet.
 await setup([],false)
 initial = enemy.position
 await frames(15)
 check(enemy.position.distance_to(initial) < 0.1 and enemy.get("nav_status") == &"waiting","unsynchronized navigation waits")
 fixture.add_child(region)
 NavigationServer3D.map_set_active(nav_map, true)
 NavigationServer3D.map_force_update(nav_map)
 await frames(35)
 check(enemy.position.distance_to(initial) > 0.3,"agent resumes after map synchronizes")
 # Attack initiation and delayed resolution must both respect solid obstruction.
 await setup([Rect2(-0.2,-3,0.4,6)])
 enemy.position = Vector3(-0.7,0,0)
 player.position = Vector3(0.7,0,0)
 await frames(60)
 check(player.hits == 0 and not enemy.windup_active,"wall prevents melee initiation and damage")
 await setup()
 enemy.position = Vector3(-0.7,0,0)
 player.position = Vector3(0.7,0,0)
 await frames(2)
 check(enemy.windup_active,"clear melee begins telegraph")
 box(Vector3(0,1.5,0),Vector3(0.2,3,5))
 await frames(30)
 check(player.hits == 0,"new wall during windup blocks attack resolution")
 enemy.configure_modifiers(["corrupted"],{"corrupted":{"name":"fixture","interval":0.1,"radius":4.0,"dot_damage":1}})
 await frames(30)
 check(player.hits == 0,"corrupted damage also respects solid obstruction")
 # Local separation uses physical actors and navigation, not vector-only assertions.
 await setup()
 var actors: Array[CharacterBody3D] = [enemy,spawn(Vector3(-5,0,1.2)),spawn(Vector3(-5,0,-1.2))]
 await frames(100)
 check(actors.all(func(actor: CharacterBody3D) -> bool: return actor.position.x > -3),"multiple enemies make physical progress")
 player.hp = 0
 await frames(5)
 check(actors.all(func(actor: CharacterBody3D) -> bool: return not actor.windup_active),"dead player cancels pursuit attack")
 player.hp = 1000
 player.position = Vector3(4,0,4)
 await frames(10)
 check(actors.any(func(actor: CharacterBody3D) -> bool: return actor.ai_state == &"chase"),"respawn can be perceived again")
 enemy.take_damage(99999)
 await frames(3)
 check(not is_instance_valid(enemy),"enemy death still removes actor")
 fixture.queue_free()
 await frames(3)
 NavigationServer3D.free_rid(nav_map)
 for failure in failures: printerr("FALHA: ",failure)
 print("FIX02 AI: %d checks, %d failures" % [checks,failures.size()])
 quit(0 if failures.is_empty() else 1)
