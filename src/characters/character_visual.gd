class_name AethelCharacterVisual
extends Node3D
## Presentation-only adapter: never owns combat, physics, AI or stats.

signal animation_requested(state: StringName)

@export var model_scene: PackedScene
@export var animation_player_path: NodePath = NodePath("Model/AnimationPlayer")
@export var fallback_idle: StringName = &"idle"

var _model: Node3D
var _player: AnimationPlayer
var _state: StringName = &"idle"
var _action_time := 0.0

func _ready() -> void:
    if model_scene == null:
        push_warning("CharacterVisual: model_scene is not assigned")
        return
    var instance := model_scene.instantiate()
    if not instance is Node3D:
        push_error("CharacterVisual: model root must be Node3D")
        instance.queue_free()
        return
    _model = instance as Node3D
    _model.name = "Model"
    add_child(_model)
    _player = get_node_or_null(animation_player_path) as AnimationPlayer
    request_state(fallback_idle)

func request_state(next_state: StringName) -> void:
    if next_state == _state and _player != null and _player.is_playing():
        return
    _state = next_state
    animation_requested.emit(next_state)
    if _player == null:
        return
    if _player.has_animation(next_state):
        _player.play(next_state, 0.12)
    elif _player.has_animation(fallback_idle):
        _player.play(fallback_idle, 0.12)

func face_direction(direction: Vector3) -> void:
    var flat := Vector3(direction.x, 0.0, direction.z)
    if flat.length_squared() > 0.0001:
        rotation.y = atan2(-flat.x, -flat.z)

func update_locomotion(velocity: Vector3, sprinting: bool = false) -> void:
    if _action_time > 0: return
    if Vector2(velocity.x, velocity.z).length_squared() < 0.01:
        request_state(&"idle")
    elif sprinting:
        request_state(&"run")
    else:
        request_state(&"walk")

func set_motion(world_velocity: Vector3, direction: Vector3, delta: float) -> void:
    _action_time = maxf(0, _action_time - delta)
    update_locomotion(world_velocity, world_velocity.length() > 9)
    if _model != null and _model.has_method("set_motion"):
        _model.call("set_motion", world_velocity, direction, delta)
    else:
        face_direction(direction)

func play_action(state: StringName, duration: float = 0.3) -> void:
    _action_time = duration
    request_state(state)
    if _model != null and _model.has_method("play_state"):
        _model.call("play_state", state)

func play_attack() -> void:
    play_action(&"attack_1", 0.45)

func equipment_adapter() -> AethelEquipmentVisual:
    if _model == null: return null
    return _model.get_node_or_null("EquipmentAdapter") as AethelEquipmentVisual
