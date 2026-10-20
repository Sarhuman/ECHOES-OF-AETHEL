class_name AethelSkillTree
extends Node
signal skills_updated
var progression: AethelProgressionManager
var unlocked: Dictionary = {}
var catalog: Dictionary = {}

func configure(manager: AethelProgressionManager) -> void:
 progression = manager
 _add(&"heavy_strike", "Golpe Pesado", "Ataque com dano ampliado.", 1, 10, 1.0, [])
 _add(&"iron_guard", "Guarda de Ferro", "Reduz dano recebido por 8 segundos.", 2, 12, 12.0, [&"heavy_strike"])
 _add(&"echo_cleave", "Corte do Eco", "Golpe amplo que ecoa no espaço.", 4, 18, 4.0, [&"heavy_strike"])

func _add(id: StringName, title: String, description: String, level: int, cost: int, cd: float, dependencies: Array[StringName]) -> void:
 var skill := AethelSkillData.new()
 skill.skill_id = id
 skill.display_name = title
 skill.description = description
 skill.required_level = level
 skill.ether_cost = cost
 skill.cooldown = cd
 skill.prerequisites = dependencies
 catalog[str(id)] = skill

func unlock(id: String) -> bool:
 if progression == null or not catalog.has(id) or unlocked.has(id): return false
 var skill: AethelSkillData = catalog[id]
 if progression.current_level < skill.required_level: return false
 for req in skill.prerequisites:
  if not unlocked.has(str(req)): return false
 if not progression.spend_point(): return false
 unlocked[id] = true
 skills_updated.emit()
 return true

func serialize() -> Array:
 return unlocked.keys().duplicate()

func restore(ids: Array) -> void:
 unlocked.clear()
 for raw_id in ids:
  var id: String = str(raw_id)
  if catalog.has(id): unlocked[id] = true
 skills_updated.emit()
