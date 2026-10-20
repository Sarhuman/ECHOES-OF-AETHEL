class_name AethelProgressionManager
extends Node
signal leveled_up(new_level: int)
signal xp_changed(current_xp: int, required_xp: int)
signal points_changed(points: int)
const MAX_LEVEL: int = 99
var current_level: int = 1
var current_xp: int = 0
var skill_points: int = 0

func required_xp(level: int) -> int:
 return maxi(1, roundi(100.0 * pow(float(maxi(1,level)), 1.5)))

func gain_xp(amount: int) -> void:
 if amount <= 0 or current_level >= MAX_LEVEL: return
 current_xp += amount
 while current_level < MAX_LEVEL and current_xp >= required_xp(current_level):
  current_xp -= required_xp(current_level)
  current_level += 1
  skill_points += 1
  leveled_up.emit(current_level)
  points_changed.emit(skill_points)
 if current_level == MAX_LEVEL: current_xp = 0
 xp_changed.emit(current_xp, required_xp(current_level))

func spend_point() -> bool:
 if skill_points < 1: return false
 skill_points -= 1
 points_changed.emit(skill_points)
 return true

func serialize() -> Dictionary:
 return {"level":current_level,"xp":current_xp,"points":skill_points}

func restore(data: Dictionary) -> void:
 current_level = clampi(int(data.get("level",1)),1,MAX_LEVEL)
 current_xp = clampi(int(data.get("xp",0)),0,required_xp(current_level)-1)
 skill_points = clampi(int(data.get("points",0)),0,MAX_LEVEL)
 xp_changed.emit(current_xp,required_xp(current_level))
 points_changed.emit(skill_points)
