extends Camera3D
## Follows physical movement without smoothing a teleport across regions.
var target: Node3D
var follow_offset := Vector3(12.25, 12.25, 12.25)

func snap_to_target() -> void:
	if is_instance_valid(target): global_position = target.global_position + follow_offset

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target): return
	var desired := target.global_position + follow_offset
	if global_position.distance_to(desired) > 8:
		global_position = desired
	else:
		global_position = global_position.lerp(desired, 1 - exp(-10 * delta))
