class_name AethelMinimap
extends Control
var manager: AethelRegionManager
var expanded := false
var enabled := true

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true
	apply_layout()

func apply_layout() -> void:
	anchor_left=0.328 if expanded else 0.84
	anchor_right=anchor_left
	anchor_top=0.195 if expanded else 0.02
	anchor_bottom=anchor_top
	offset_left=0;offset_top=0
	offset_right=440 if expanded else 176
	offset_bottom=340 if expanded else 144

func toggle() -> void:
	if not enabled: enabled=true; expanded=false
	elif not expanded: expanded=true
	else: enabled=false; expanded=false
	apply_layout()
	queue_redraw()

func project(at: Vector3) -> Vector2:
	var origin: Vector3=Vector3.ZERO if expanded else manager.world.player.position
	return size/2+Vector2(0,7)+Vector2(at.x-origin.x,at.z-origin.z)*(7.5 if expanded else 8.5)

func _draw() -> void:
	if not enabled or manager==null or not is_instance_valid(manager.level): return
	draw_style_box(AethelUI.panel(),Rect2(Vector2.ZERO,size))
	var world: Node3D=manager.world
	var scale_value := 7.5 if expanded else 8.5
	var knowledge: Dictionary=manager.revealed.get(manager.floor_key(world.region_id,manager.active_floor),{})
	for cell: Vector2i in manager.level.cells:
		if not knowledge.has(manager.cell_key(cell)): continue
		var at := Vector3(cell.x+0.5,manager.level.cells[cell],cell.y+0.5)
		if manager.floor_id(at)!=manager.active_floor or not Rect2(7,24,size.x-14,size.y-30).has_point(project(at)): continue
		var color := Color("655d4b") if at.distance_to(world.player.position)>4 else Color("a29471")
		draw_rect(Rect2(project(at)-Vector2.ONE*scale_value/2,Vector2.ONE*(scale_value-0.5)),color)
	for id: String in manager.connectors:
		var at: Vector3=manager.connectors[id].position
		if manager.floor_id(at)==manager.active_floor and manager.discovered(at): draw_rect(Rect2(project(at)-Vector2(3,3),Vector2(6,6)),Color("e6ca85"))
	for id: String in world.exploration.anchors:
		var row: Dictionary=world.exploration.definition_for(id)
		if row.region!=world.region_id: continue
		var at: Vector3=manager.point(row.position)
		if manager.floor_id(at)==manager.active_floor and manager.discovered(at): draw_circle(project(at),4,Color("858ef0"))
	for row: Dictionary in manager.definitions[world.region_id].pois:
		if manager.floor_id(manager.point(row.position))==manager.active_floor and manager.known_pois.has(str(row.id)) and manager.discovered(manager.point(row.position)):
			draw_circle(project(manager.point(row.position)),3,Color("b8a058"))
	draw_circle(project(world.player.position),4,Color("a3e6be"))
	var short_name: String={"map_01":"Vigília","map_02":"Bairro","map_03":"Pátio","map_04":"Arquivo"}.get(world.region_id,"Mapa")
	draw_string(ThemeDB.fallback_font,Vector2(9,17),(str(manager.definitions[world.region_id].name) if expanded else short_name)+" · P%d"%manager.active_floor,HORIZONTAL_ALIGNMENT_LEFT,size.x-18,12,Color("d3c3a3"))

	if expanded: draw_string(ThemeDB.fallback_font,Vector2(7,size.y-6),"● Você  □ Saída  ● Âncora  • Vestígio",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("d3c3a3"))
