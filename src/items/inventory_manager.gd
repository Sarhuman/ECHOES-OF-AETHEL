class_name AethelInventoryManager
extends Node
signal inventory_updated
@export_range(1, 20, 1) var grid_width: int = 10
@export_range(1, 10, 1) var grid_height: int = 4
var _cells: Dictionary = {} # Vector2i -> instance_id
var _items: Dictionary = {} # String -> {instance, origin}

func can_place_item(item: AethelItemData, origin: Vector2i) -> bool:
 if item == null or item.width <= 0 or item.height <= 0: return false
 if origin.x < 0 or origin.y < 0 or origin.x + item.width > grid_width or origin.y + item.height > grid_height: return false
 for y in range(origin.y, origin.y + item.height):
  for x in range(origin.x, origin.x + item.width):
   if _cells.has(Vector2i(x, y)): return false
 return true

func add_item(item: AethelItemInstance) -> bool:
 if item == null or item.definition == null or _items.has(item.instance_id): return false
 for y in range(grid_height):
  for x in range(grid_width):
   if place_item(item, Vector2i(x, y)): return true
 return false

func place_item(item: AethelItemInstance, origin: Vector2i) -> bool:
 if item == null or item.definition == null or _items.has(item.instance_id): return false
 if not can_place_item(item.definition, origin): return false
 for y in range(origin.y, origin.y + item.definition.height):
  for x in range(origin.x, origin.x + item.definition.width):
   _cells[Vector2i(x,y)] = item.instance_id
 _items[item.instance_id] = {"instance": item, "origin": origin}
 inventory_updated.emit()
 return true

func remove_item(instance_id: String) -> bool:
 if not _items.has(instance_id): return false
 var positions: Array = _cells.keys()
 for pos in positions:
  if _cells[pos] == instance_id: _cells.erase(pos)
 _items.erase(instance_id)
 inventory_updated.emit()
 return true

func entries() -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 for entry in _items.values(): result.append(entry)
 return result

func occupied_count() -> int: return _cells.size()

func serialize() -> Dictionary:
 var rows: Array[Dictionary] = []
 for entry in entries():
  var obj: AethelItemInstance = entry["instance"]
  var origin: Vector2i = entry["origin"]
  var row: Dictionary = obj.serialize()
  row["x"] = origin.x
  row["y"] = origin.y
  rows.append(row)
 return {"version":2,"grid_width":grid_width,"grid_height":grid_height,"items":rows}

func restore(payload: Dictionary, catalog: Dictionary) -> void:
 _cells.clear()
 _items.clear()
 for entry in payload.get("items", []):
  if not entry is Dictionary: continue
  var instance: AethelItemInstance = AethelItemInstance.from_dict(entry, catalog)
  if instance == null: continue
  if not place_item(instance, Vector2i(int(entry.get("x", -1)), int(entry.get("y", -1)))):
   add_item(instance) # posição inválida/ocupada: recoloca no primeiro espaço livre
 inventory_updated.emit()

func find_item(instance_id: String) -> AethelItemInstance:
 if not _items.has(instance_id): return null
 return _items[instance_id]["instance"]
