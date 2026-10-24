extends SceneTree

func _initialize() -> void:
	var result := ResourceSaver.save(AethelUI.create_theme(),"res://assets/ui/aethel_theme.tres")
	quit(0 if result == OK else 1)
