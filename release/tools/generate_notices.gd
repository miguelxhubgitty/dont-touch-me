extends SceneTree

func _initialize() -> void:
	var text := "Don't Touch Me — Engine and Third-Party Notices\n\n"
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
	var license_names := licenses.keys()
	license_names.sort()
	for name in license_names:
		text += "\n" + str(name) + "\n" + str(licenses[name]) + "\n"
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://release/audio-manifest.json"))
	if not manifest is Dictionary or not manifest.get("streams") is Dictionary:
		push_error("Invalid release audio manifest.")
		quit(1)
		return
	var audio_notices := {}
	for stream in manifest.streams.values():
		if stream.has("notice"):
			audio_notices[stream.notice] = true
	var notice_paths := audio_notices.keys()
	notice_paths.sort()
	if not notice_paths.is_empty():
		text += "\nAUDIO LICENSES\n==============\n"
	for path in notice_paths:
		var notice := FileAccess.get_file_as_string("res://" + path).strip_edges()
		if notice.is_empty():
			push_error("Missing required audio notice: " + path)
			quit(1)
			return
		text += "\n" + notice + "\n"
	text = text.strip_edges().replace("\r\n", "\n") + "\n"
	const OUTPUT := "res://THIRD_PARTY_NOTICES.txt"
	if "--check" in OS.get_cmdline_user_args():
		if FileAccess.get_file_as_string(OUTPUT).replace("\r\n", "\n") != text:
			push_error("Third-party notices are stale. Run generate_notices.gd.")
			quit(1)
			return
		print("Third-party notices match the generated text.")
		quit()
		return
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(text)
	file.close()
	print("Generated engine and audio notices: ", text.length(), " characters")
	quit()
