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
