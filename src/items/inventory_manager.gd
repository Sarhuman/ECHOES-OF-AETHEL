class_name AethelInventoryManager
extends Node
signal inventory_updated
@export_range(1, 20, 1) var grid_width: int = 10
@export_range(1, 10, 1) var grid_height: int = 4
var _cells: Dictionary = {} # Vector2i -> instance_id
var _items: Dictionary = {} # String -> {instance, origin}
var _absorbed_ids: Dictionary = {}

func can_place_item(item: AethelItemData, origin: Vector2i) -> bool:
 if item == null or item.width <= 0 or item.height <= 0: return false
 if origin.x < 0 or origin.y < 0 or origin.x + item.width > grid_width or origin.y + item.height > grid_height: return false
 for y in range(origin.y, origin.y + item.height):
  for x in range(origin.x, origin.x + item.width):
   if _cells.has(Vector2i(x, y)): return false
 return true

func add_item(item: AethelItemInstance) -> bool:
 if item == null or item.definition == null or _items.has(item.instance_id): return false
 if _absorbed_ids.has(item.instance_id): return false
 if item.quantity < 1 or item.quantity > item.definition.max_stack: return false
 var remaining := item.quantity
 var merges: Array = []
 for entry in _items.values():
  var existing: AethelItemInstance = entry["instance"]
  if existing.stacks_with(item):
   var amount := mini(remaining,existing.definition.max_stack - existing.quantity)
   if amount > 0: merges.append([existing,amount])
   remaining -= amount
 var destination := Vector2i(-1,-1)
 if remaining > 0:
  for y in range(grid_height):
   for x in range(grid_width):
    if destination.x < 0 and can_place_item(item.definition,Vector2i(x,y)): destination = Vector2i(x,y)
  if destination.x < 0: return false
 for pair in merges: pair[0].quantity += pair[1]
 if remaining > 0:
  item.quantity = remaining
  _items[item.instance_id] = {"instance":item,"origin":destination}
 else: _absorbed_ids[item.instance_id] = true
 _rebuild()
 inventory_updated.emit()
 return true

func place_item(item: AethelItemInstance, origin: Vector2i) -> bool:
 if item == null or item.definition == null or _items.has(item.instance_id): return false
 if _absorbed_ids.has(item.instance_id): return false
 if item.quantity < 1 or item.quantity > item.definition.max_stack: return false
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
 return {"version":3,"grid_width":grid_width,"grid_height":grid_height,"items":rows}

func restore(payload: Dictionary, catalog: Dictionary) -> void:
 _cells.clear()
 _items.clear()
 _absorbed_ids.clear()
 var width: Variant = payload.get("grid_width",grid_width)
 var height: Variant = payload.get("grid_height",grid_height)
 if (width is int or width is float) and (height is int or height is float) and is_finite(float(width)) and is_finite(float(height)):
  grid_width = clampi(int(width),1,20)
  grid_height = clampi(int(height),1,10)
 var seen: Dictionary = {}
 var incoming: Variant = payload.get("items",[])
 if not incoming is Array:
  inventory_updated.emit()
  return
 for entry in incoming:
  if not entry is Dictionary: continue
  var instance: AethelItemInstance = AethelItemInstance.from_dict(entry, catalog)
  if instance == null or seen.has(instance.instance_id): continue
  seen[instance.instance_id] = true
  if not place_item(instance, Vector2i(int(entry.get("x", -1)), int(entry.get("y", -1)))):
   add_item(instance) # posição inválida/ocupada: recoloca no primeiro espaço livre
 inventory_updated.emit()

func find_item(instance_id: String) -> AethelItemInstance:
 if not _items.has(instance_id): return null
 return _items[instance_id]["instance"]

func _rebuild() -> void:
 _cells.clear()
 for id in _items:
  var entry: Dictionary = _items[id]
  var data: AethelItemData = entry["instance"].definition
  for y in range(data.height):
   for x in range(data.width): _cells[entry["origin"] + Vector2i(x,y)] = id

func _valid_layout(rows: Dictionary) -> bool:
 var occupied: Dictionary = {}
 for id in rows:
  var entry: Dictionary = rows[id]
  var data: AethelItemData = entry["instance"].definition
  var pos: Vector2i = entry["origin"]
  if pos.x < 0 or pos.y < 0 or pos.x+data.width > grid_width or pos.y+data.height > grid_height: return false
  for y in range(data.height):
   for x in range(data.width):
    var cell := pos+Vector2i(x,y)
    if occupied.has(cell): return false
    occupied[cell] = id
 return true

func _commit(rows: Dictionary) -> void:
 _items = rows
 _rebuild()
 inventory_updated.emit()

func item_at(cell: Vector2i) -> String:
 return str(_cells.get(cell,""))

func take_one(uid: String) -> bool:
 var item := find_item(uid)
 if item == null: return false
 if item.quantity == 1: return remove_item(uid)
 item.quantity -= 1
 inventory_updated.emit()
 return true

func move_item(uid: String, destination: Vector2i) -> bool:
 if not _items.has(uid): return false
 var rows := _items.duplicate(true)
 var old: Vector2i = rows[uid]["origin"]
 var target := item_at(destination)
 if target == uid and old == destination: return true
 if not target.is_empty() and target != uid:
  var incoming := find_item(uid)
  var outgoing := find_item(target)
  if outgoing.stacks_with(incoming) and outgoing.quantity+incoming.quantity <= outgoing.definition.max_stack:
   outgoing.quantity += incoming.quantity
   _absorbed_ids[uid] = true
   rows.erase(uid)
   _commit(rows)
   return true
  rows[target]["origin"] = old
 rows[uid]["origin"] = destination
 if not _valid_layout(rows): return false
 _commit(rows)
 return true

func exchange(uid: String, outgoing: AethelItemInstance) -> bool:
 # Plan the replacement before changing anything, including quantities.
 if not _items.has(uid): return false
 var rows := _items.duplicate(true)
 var origin: Vector2i = rows[uid]["origin"]
 rows.erase(uid)
 if outgoing != null:
  if rows.has(outgoing.instance_id): return false
  rows[outgoing.instance_id] = {"instance":outgoing,"origin":origin}
  if not _valid_layout(rows):
   var found := false
   for y in range(grid_height):
    for x in range(grid_width):
     rows[outgoing.instance_id]["origin"] = Vector2i(x,y)
     if not found and _valid_layout(rows):
      origin = Vector2i(x,y)
      found = true
   if not found: return false
   rows[outgoing.instance_id]["origin"] = origin
 _commit(rows)
 return true

func auto_sort() -> bool:
 var ordered := entries()
 ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
  var x: AethelItemInstance = a["instance"]
  var y: AethelItemInstance = b["instance"]
  var area_x := x.definition.width*x.definition.height
  var area_y := y.definition.width*y.definition.height
  return area_x > area_y if area_x != area_y else x.instance_id < y.instance_id)
 var rows: Dictionary = {}
 for entry in ordered:
  var id: String = entry["instance"].instance_id
  var found := false
  for y in range(grid_height):
   for x in range(grid_width):
    if found: continue
    rows[id] = {"instance":entry["instance"],"origin":Vector2i(x,y)}
    if _valid_layout(rows): found = true
  if not found: return false
 _commit(rows)
 return true
