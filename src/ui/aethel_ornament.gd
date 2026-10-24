class_name AethelOrnament
extends Control
## Original Aethel bell/portal geometry, drawn without external textures.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var c := AethelUI.UNIQUE_REFERENCE
	for x in [8.0, size.x - 8.0]:
		draw_line(Vector2(x,10),Vector2(x,26),c,1)
		draw_polyline(PackedVector2Array([Vector2(x-4,18),Vector2(x,14),Vector2(x+4,18),Vector2(x,22),Vector2(x-4,18)]),c,1)
	draw_line(Vector2(20,8),Vector2(size.x/2-10,8),AethelUI.BRASS,1)
	draw_line(Vector2(size.x/2+10,8),Vector2(size.x-20,8),AethelUI.BRASS,1)
	var center := Vector2(size.x/2,8)
	draw_polyline(PackedVector2Array([center+Vector2(-6,3),center+Vector2(-3,-2),center+Vector2(0,-4),center+Vector2(3,-2),center+Vector2(6,3)]),c,1)
