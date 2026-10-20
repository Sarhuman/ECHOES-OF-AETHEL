class_name AethelSkillData
extends Resource
@export var skill_id: StringName
@export var display_name: String = ""
@export var description: String = ""
@export_range(1,60) var required_level: int = 1
@export_range(0,500) var ether_cost: int = 0
@export_range(0.0,20.0) var cooldown: float = 0.0
@export var prerequisites: Array[StringName] = []
