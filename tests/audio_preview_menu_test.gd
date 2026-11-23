extends SceneTree
var audio_cleanup = preload("res://tests/audio_test_cleanup.gd").new()

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var menu = load("res://tests/audio_preview_menu.tscn").instantiate()
	root.add_child(menu)
	var passed: bool = menu.rows.get_child_count() == menu.manager.events.size()
	var disabled_id := ""
	for id in menu.manager.events:
		if not menu.manager.events[id].enabled:
			disabled_id = id
			break
	menu.preview(disabled_id)
	audio_cleanup.observe(menu.player)
	passed = passed and menu.player.playing and not menu.manager.events[disabled_id].enabled
	menu.preview("user.tap_miss")
	audio_cleanup.observe(menu.player)
	passed = passed and menu.player.playing and menu.player.stream == menu.manager.streams[menu.manager.events["user.tap_miss"].stream]
	menu.get_child(2).pressed.emit()
	passed = passed and not menu.player.playing
	var presets := ConfigFile.new()
	passed = presets.load("res://export_presets.cfg") == OK and passed
	for section in presets.get_sections():
		if presets.has_section_key(section, "export_filter"):
			passed = "tests/*" in str(presets.get_value(section, "exclude_filter")).split(",") and passed
	menu.queue_free()
	print("Development preview checks passed: ", passed)
	await audio_cleanup.finish(self, 0 if passed else 1)
