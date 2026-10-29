extends SceneTree

func _initialize() -> void:
	var text := "Don't Touch Me 1.0 — Engine and Third-Party Notices\n\n"
	text += "The game uses Godot Engine and its bundled components, including the engine's fallback font. These notices do not grant a license to the game's original code or artwork.\n\n"
	text += "GODOT ENGINE\n=============\n" + Engine.get_license_text() + "\n\n"
	text += "BUNDLED COMPONENT COPYRIGHTS\n===========================\n"
	for component in Engine.get_copyright_info():
		text += "\n" + str(component.name) + "\n"
		for part in component.parts:
			text += "  License: " + str(part.license) + "\n"
			for copyright_line in part.copyright:
				text += "  " + str(copyright_line) + "\n"
			text += "  Files: " + ", ".join(part.files) + "\n"
	text += "\nFULL THIRD-PARTY LICENSE TEXTS\n=============================\n"
	var licenses := Engine.get_license_info()
	for name in licenses:
		text += "\n" + str(name) + "\n" + str(licenses[name]) + "\n"
	var file := FileAccess.open("res://THIRD_PARTY_NOTICES.txt", FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(text.strip_edges() + "\n")
	file.close()
	print("Generated engine notices: ", text.length(), " characters; ", licenses.size(), " license texts")
	quit()
