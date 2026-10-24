extends Camera3D
## Orthographic camera. Zoom and follow bounds stay independent of input coordinates.
const MIN_ZOOM := 10.0
const MAX_ZOOM := 18.0
var target: Node3D
var follow_offset := Vector3(12.25, 12.25, 12.25)
var zoom_target := 12.0
var follow_min := Vector2(-13, -13)
var follow_max := Vector2(13, 13)

func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	zoom_target = clampf(AethelSettings.camera_zoom, MIN_ZOOM, MAX_ZOOM)
	size = zoom_target

func set_zoom(value: float, persist: bool = true) -> void:
	if not is_finite(value): return
	zoom_target = clampf(value, MIN_ZOOM, MAX_ZOOM)
	AethelSettings.camera_zoom = zoom_target
	if persist and AethelSettings.remember_zoom: AethelSettings.save_settings()

func _follow_point() -> Vector3:
	return Vector3(clampf(target.global_position.x, follow_min.x, follow_max.x), target.global_position.y,
		clampf(target.global_position.z, follow_min.y, follow_max.y)) + follow_offset

func snap_to_target() -> void:
	if is_instance_valid(target): global_position = _follow_point()

func _physics_process(delta: float) -> void:
	size = lerpf(size, zoom_target, 1 - exp(-12 * delta))
	if not is_instance_valid(target): return
	var desired := _follow_point()
	if global_position.distance_to(desired) > 8:
		global_position = desired
	else:
		global_position = global_position.lerp(desired, 1 - exp(-10 * delta))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		set_zoom(zoom_target - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("zoom_out"):
		set_zoom(zoom_target + 1)
		get_viewport().set_input_as_handled()
