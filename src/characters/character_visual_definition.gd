class_name AethelCharacterVisualDefinition
extends Resource
## Data for heroes, NPCs and enemies. Does not affect gameplay.

@export var character_id: StringName
@export var display_name: String
@export var model_scene: PackedScene
@export var scale_multiplier: float = 1.0
@export var idle_animation: StringName = &"idle"
@export var walk_animation: StringName = &"walk"
@export var run_animation: StringName = &"run"
@export var attack_animation: StringName = &"attack"
@export var hit_animation: StringName = &"hit"
@export var dodge_animation: StringName = &"dodge"
@export var death_animation: StringName = &"death"
@export var attack_2_animation: StringName = &"attack_2"
@export var block_animation: StringName = &"block"

# Authored integration configuration, never read from a save or loot payload.
@export var imported_scene: PackedScene
@export var animation_map: Dictionary = {"idle":"idle","walk":"walk","run":"run","attack_1":"attack_basic","attack_2":"attack_heavy","heavy_strike":"skill_f1","iron_guard":"skill_f2","echo_cleave":"skill_f3","hit":"hit_reaction","death":"death","interact":"interact","block":"block","dodge":"dodge"}
@export var required_animations: PackedStringArray = ["idle","walk","run","attack_basic","attack_heavy","skill_f1","skill_f2","skill_f3","hit_reaction","death","interact","block","dodge"]
@export var socket_names: PackedStringArray = ["SocketMain","SocketOffhand","SocketName","SocketHealth","SocketFX"]
@export var max_triangles := 20000
@export var max_deforming_bones := 65
@export var max_materials := 4
@export var max_texture_size := 1024
@export var max_influences := 4
@export var min_height := 1.6
@export var max_height := 2.2
@export var max_width := 2.2
@export var provenance_path := ""
@export_enum("PENDING","DOCUMENTED","DOCUMENTED_TEST_ONLY") var provenance_status := "PENDING"
