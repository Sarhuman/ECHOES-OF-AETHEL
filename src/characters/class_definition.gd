class_name AethelClassDefinition
extends Resource

@export var class_id: StringName
@export var display_name: String
@export var role: String
@export var playable := false
@export var visual: AethelCharacterVisualDefinition

static func definitions() -> Array[AethelClassDefinition]:
	var result: Array[AethelClassDefinition] = []
	for entry: Array in [
		["bastion", "Bastião do Crepúsculo", "Machado, escudo e resistência"],
		["weaver", "Tecelã do Éter", "Magia ofensiva e controle"],
		["sentinel", "Sentinela das Cinzas", "Arco e mobilidade"],
		["summoner", "Invocadora dos Véus", "Invocações e enfraquecimentos"],
		["inquisitor", "Inquisidor da Aurora", "Combate híbrido e proteção"]]:
		var data := AethelClassDefinition.new()
		data.class_id = StringName(entry[0])
		data.display_name = entry[1]
		data.role = entry[2]
		data.playable = data.class_id == &"bastion"
		result.append(data)
	return result
