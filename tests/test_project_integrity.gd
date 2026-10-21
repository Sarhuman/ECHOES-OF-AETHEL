extends SceneTree
var failures: Array[String] = []
var classes: Dictionary = {}
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func scan(folder: String) -> void:
	for filename in DirAccess.get_files_at(folder):
		var path := folder.path_join(filename)
		if filename.ends_with(".gd"):
			var pattern := RegEx.new()
			pattern.compile("(?m)^class_name\\s+(\\w+)")
			var result := pattern.search(FileAccess.get_file_as_string(path))
			if result:
				var id := result.get_string(1)
				check(not classes.has(id), "duplicate class_name: " + id)
				classes[id] = path
		if filename.ends_with(".tscn") or filename.ends_with(".tres"):
			check(ResourceLoader.load(path) != null, "scene/resource dependencies: " + path)
	for directory in DirAccess.get_directories_at(folder): scan(folder.path_join(directory))

func _initialize() -> void:
	for folder in ["res://src", "res://scripts", "res://scenes", "res://assets", "res://data"]: scan(folder)
	var main_scene: String = ProjectSettings.get_setting("application/run/main_scene", "")
	check(main_scene == "res://scenes/main_menu.tscn" and ResourceLoader.exists(main_scene), "main menu scene")
	check(ProjectSettings.get_setting("application/config/version", "") == "0.25.0", "artifact version")
	print("PROJECT INTEGRITY: %d checks, %d failures" % [checks, failures.size()])
	for failure in failures: printerr("FALHA: ",failure)
	quit(0 if failures.is_empty() else 1)
