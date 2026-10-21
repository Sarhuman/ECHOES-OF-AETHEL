class_name AethelCharacterVisual
extends Node3D
## Presentation adapter. The actor remains the only gameplay authority.
signal animation_requested(state: StringName)
@export var model_scene: PackedScene
@export var definition: AethelCharacterVisualDefinition
@export var animation_player_path: NodePath=NodePath("Model/AnimationPlayer")
@export var fallback_idle: StringName=&"idle"
var mode := "PLACEHOLDER"
var last_validation: Dictionary={}
var _model: Node3D
var _player: AnimationPlayer
var _state: StringName=&"idle"
var _action_time:=0.0
var _pending_skill: StringName

func _ready() -> void:
    if get_parent().has_signal("skill_used"):
        get_parent().connect("skill_used",func(id: String) -> void: _pending_skill=StringName(id))
    if definition!=null:
        select_mode(str(ProjectSettings.get_setting("aethel/visuals/bastion_mode","PLACEHOLDER")))
    else: replace_model(model_scene)

func select_mode(requested: String) -> bool:
    if definition==null: return false
    if requested=="IMPORTED_MODEL" and definition.imported_scene!=null:
        if _replace(definition.imported_scene,true):
            mode="IMPORTED_MODEL"
            return true
    if requested=="IMPORTED_MODEL" and definition.imported_scene==null:
        last_validation={"valid":false,"errors":["No imported model assigned; using placeholder"]}
    var success:=_replace(definition.model_scene,false)
    mode="PLACEHOLDER"
    return success and requested=="PLACEHOLDER"

func replace_model(replacement: PackedScene) -> void:
    # Compatibility API used by existing tests/tools; transactional on failure.
    if _replace(replacement,false): mode="PLACEHOLDER"

func _replace(replacement: PackedScene, validate: bool) -> bool:
    if replacement==null: return false
    var instance:=replacement.instantiate()
    if not instance is Node3D:
        instance.free()
        return false
    var candidate:=instance as Node3D
    candidate.name="Candidate"
    candidate.hide()
    add_child(candidate)
    if validate:
        last_validation=AethelVisualAssetValidator.inspect(candidate,definition)
        if not last_validation.valid:
            remove_child(candidate)
            candidate.queue_free()
            return false
    var equipment: Dictionary={}
    var previous_adapter:=equipment_adapter()
    if previous_adapter!=null: equipment=previous_adapter.snapshot()
    if _model!=null:
        remove_child(_model)
        _model.queue_free()
    _model=candidate
    _model.name="Model"
    _model.show()
    model_scene=replacement
    mode="IMPORTED_MODEL" if validate else "PLACEHOLDER"
    _player=_model.find_child("AnimationPlayer",true,false) as AnimationPlayer
    var adapter:=equipment_adapter()
    if adapter!=null:
        for slot: StringName in equipment:
            adapter.apply_equipment(slot,equipment[slot].appearance_id,equipment[slot].rarity_id)
    request_state(_state)
    return true

func request_state(next_state: StringName) -> void:
    var clip: StringName=StringName(definition.animation_map.get(str(next_state),str(next_state))) if definition!=null and mode=="IMPORTED_MODEL" else next_state
    if next_state==_state and _player!=null and _player.current_animation==clip and _player.is_playing(): return
    _state=next_state
    animation_requested.emit(next_state)
    if _player==null: return
    _player.speed_scale=1.0
    if _player.has_animation(clip): _player.play(clip,0.08)
    elif _player.has_animation(fallback_idle): _player.play(fallback_idle,0.08)

func face_direction(direction: Vector3) -> void:
    var flat:=Vector3(direction.x,0,direction.z)
    if flat.length_squared()>0.0001: rotation.y=atan2(-flat.x,-flat.z)

func update_locomotion(velocity: Vector3,sprinting: bool=false) -> void:
    if _action_time>0: return
    request_state(&"idle" if Vector2(velocity.x,velocity.z).length_squared()<0.01 else &"run" if sprinting else &"walk")

func set_motion(world_velocity: Vector3,direction: Vector3,delta: float) -> void:
    _action_time=maxf(0,_action_time-delta)
    update_locomotion(world_velocity,Vector2(world_velocity.x,world_velocity.z).length()>9)
    if _model!=null and _model.has_method("set_motion"):
        _model.call("set_motion",world_velocity,direction,delta)
    else: face_direction(direction)

func play_action(state: StringName,duration: float=0.3) -> void:
    if not _pending_skill.is_empty():
        if mode=="IMPORTED_MODEL": state=_pending_skill
        _pending_skill=&""
    _action_time=duration
    if _player!=null: _player.stop()
    request_state(state)
    if _player!=null and mode=="IMPORTED_MODEL":
        var clip: StringName=StringName(definition.animation_map.get(str(state),str(state)))
        if _player.has_animation(clip):
            _player.speed_scale=1.0 if state==&"death" else _player.get_animation(clip).length/maxf(0.05,duration)
    if _model!=null and _model.has_method("play_state"): _model.call("play_state",state)

func play_attack() -> void: play_action(&"attack_1",0.45)

func equipment_adapter() -> AethelEquipmentVisual:
    if _model==null: return null
    return _model.get_node_or_null("EquipmentAdapter") as AethelEquipmentVisual

func present_interaction() -> void:
    if mode=="IMPORTED_MODEL" and _action_time<=0: play_action(&"interact",0.4)
