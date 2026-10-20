class_name AethelDroppedItem
extends Area3D
## Item, poção ou pilha de ouro no chão. Rótulo colorido pela qualidade (branco/azul/amarelo/dourado).

const COLORS: Array = [Color("e8e8e8"), Color("8c8cff"), Color("ffff64"), Color("b885ec"), Color("c7b377")]
const GOLD_COLOR: Color = Color("ffd24a")

var item: AethelItemInstance
var gold_amount: int = 0
var mesh: MeshInstance3D
var label: Label3D
var time_alive: float = 0.0

func is_gold() -> bool:
	return gold_amount > 0

func accent_color() -> Color:
	if is_gold(): return GOLD_COLOR
	if item == null or item.definition == null: return Color.WHITE
	if item.definition.is_potion():
		return Color("e04848") if item.definition.heal_life > 0 else Color("4a7be0")
	return COLORS[clampi(item.get_quality(), 0, COLORS.size() - 1)]

func display_text() -> String:
	if is_gold(): return "%d Ouro" % gold_amount
	return item.display_name() if item != null else "Desconhecido"

func default_label_visible() -> bool:
	## Itens mágicos ou melhores e ouro aparecem sempre; os comuns aparecem com Alt ou ao passar o mouse.
	if is_gold(): return true
	return item != null and item.get_quality() >= AethelItemData.Rarity.MAGIC

func set_label_visible(value: bool) -> void:
	if label != null: label.visible = value

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	mesh = MeshInstance3D.new()
	if is_gold():
		var coin := CylinderMesh.new()
		coin.top_radius = 0.22
		coin.bottom_radius = 0.22
		coin.height = 0.08
		mesh.mesh = coin
	else:
		var box := BoxMesh.new()
		box.size = Vector3(0.35, 0.2, 0.35)
		mesh.mesh = box
	mesh.position.y = 0.35
	add_child(mesh)
	var material := StandardMaterial3D.new()
	material.albedo_color = accent_color()
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 0.6
	mesh.material_override = material
	label = Label3D.new()
	label.text = display_text()
	label.position.y = 1.0
	label.font_size = 34
	label.pixel_size = 0.009
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = accent_color()
	label.visible = default_label_visible()
	add_child(label)

func _process(delta: float) -> void:
	time_alive += delta
	if mesh != null: mesh.position.y = 0.35 + sin(time_alive * 2.4) * 0.09

func collect(manager: AethelInventoryManager) -> bool:
	if item == null or not manager.add_item(item): return false
	queue_free()
	return true
