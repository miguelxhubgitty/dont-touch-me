extends SceneTree

const Game := preload("res://main.tscn")
var failures := 0
var settings_path := "user://mute-test-%d.cfg" % OS.get_process_id()

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func add_game(viewport: SubViewport) -> Node:
	var game := Game.instantiate()
	game.get_node("SoundHUD/SoundButton").settings_path = settings_path
	viewport.add_child(game)
	game.set_process(false)
	return game

func touch(viewport: SubViewport, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	viewport.push_input(event, true)

func write_settings(contents: String) -> void:
	var file := FileAccess.open(settings_path, FileAccess.WRITE)
	file.store_string(contents)
	file.close()

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	root.add_child(viewport)
	var game := add_game(viewport)
	var button: Button = game.get_node("SoundHUD/SoundButton")
	var point := button.get_global_rect().get_center()
	check(game.audio_manager.muted and button.text == "Sound Off", "first launch is muted")
	check(button.get_global_rect().end.x <= viewport.size.x and button.position.x >= 0, "portrait button fits")
	viewport.size = Vector2i(1280, 720)
	await process_frame
	check(button.get_global_rect().end.x <= viewport.size.x and button.position.x >= 0, "wide button fits")
	point = button.get_global_rect().get_center()
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = down
		viewport.push_input(event, true)
	check(not game.audio_manager.muted, "mouse toggles once")
	game.free()
	game = add_game(viewport)
	button = game.get_node("SoundHUD/SoundButton")
	check(not game.audio_manager.muted, "enabled preference survives new scene")
	var manager: Node = game.audio_manager
	check(manager.play_event("blink.contact"), "test starts a real cue")
	touch(viewport, point, true)
	check(not manager.muted, "touch press waits for release")
	touch(viewport, point, false)
	check(manager.muted and manager.slots.is_empty(), "touch toggles once and stops active sound")
	for player in manager.players.values():
		check(not player.playing, "player stopped immediately")
	touch(viewport, point, true)
	touch(viewport, Vector2(5, 5), false)
	check(manager.muted, "release outside cancels")
	check(game.annoyance == 0 and game.reaction == 0 and game.idle_time == 0, "button gestures do not poke or reset idle")
	game.begin_reaction(game.Reaction.DONT, Vector2.ZERO)
	game.advance(0.2)
	check(manager.fired.has("dont.voice") and manager.slots.is_empty(), "muted cue consumed silently")
	touch(viewport, point, true)
	touch(viewport, point, false)
	game.advance(0.01)
	check(not manager.muted and manager.slots.is_empty(), "unmute does not replay")
	check(manager.play_event("wake.contact"), "future cue plays")
	game.free()
	for contents in ["invalid config", "[audio]\nother=true\n", "[audio]\nmuted=123\n", "[audio]\nmuted=true\n"]:
		write_settings(contents)
		game = add_game(viewport)
		check(game.audio_manager.muted, "invalid or muted preference defaults to off")
		game.free()
	game = add_game(viewport)
	button = game.get_node("SoundHUD/SoundButton")
	button.settings_path = "user://missing-mute-directory/audio_settings.cfg"
	button.pressed.emit()
	check(not game.audio_manager.muted, "failed save preserves current choice")
	viewport.free()
	DirAccess.remove_absolute(settings_path)
	await create_timer(0.3).timeout
	print("Mute tests: %d failures" % failures)
	quit(1 if failures else 0)
