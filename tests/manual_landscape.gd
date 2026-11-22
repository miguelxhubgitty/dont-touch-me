extends SceneTree

const Game := preload("res://main.tscn")

class PreviewVolume extends "res://scripts/audio_volume_controls.gd":
	var requests: Array[int] = []

	func _supports_manual_orientation() -> bool:
		return true

	func _request_orientation(orientation: DisplayServer.ScreenOrientation) -> void:
		requests.append(orientation)

var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + description)

func tap(viewport: Viewport, point: Vector2, emulate_mouse := false) -> void:
	for down in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.position = point
		touch.pressed = down
		viewport.push_input(touch, true)
		if emulate_mouse:
			var mouse := InputEventMouseButton.new()
			mouse.position = point
			mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.pressed = down
			mouse.device = InputEvent.DEVICE_ID_EMULATION
			viewport.push_input(mouse, true)

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	root.add_child(viewport)
	var game = Game.instantiate()
	viewport.add_child(game)
	if OS.has_feature("pc"):
		check(game.get_node("SoundHUD/VolumeButton").orientation_button == null, "desktop menu stays unchanged")
	game.free()
	game = Game.instantiate()
	var volume = game.get_node("SoundHUD/VolumeButton")
	volume.set_script(PreviewVolume)
	viewport.add_child(game)
	game.set_process(false)
	game.annoyance = 9.0
	game.idle_time = 1.8
	check(volume.requests.is_empty(), "opening the game issues no orientation request")
	tap(viewport, volume.get_global_rect().get_center())
	await process_frame
	await process_frame
	var selector: Button = volume.orientation_button
	check(volume.panel.visible and selector.text == "Orientation: Portrait", "selector starts at Portrait")
	tap(viewport, selector.get_global_rect().get_center(), true)
	check(volume.requests == [DisplayServer.SCREEN_LANDSCAPE] and selector.text == "Orientation: Landscape",
		"native tap requests fixed landscape once despite mirrored mouse")
	viewport.size = Vector2i(2275, 1280)
	await process_frame
	game._resize()
	var safe_area := Rect2(72, 27, 2100, 1217)
	game.get_node("SoundHUD")._place(safe_area)
	check(safe_area.encloses(selector.get_global_rect()), "selector fits the landscape safe area")
	tap(viewport, selector.get_global_rect().get_center(), true)
	check(volume.requests == [DisplayServer.SCREEN_LANDSCAPE, DisplayServer.SCREEN_PORTRAIT],
		"the same menu selects fixed portrait after resizing")
	check(game.annoyance == 9.0 and game.idle_time == 1.8 and game.reaction == 0
		and game.audio_manager.click_streak == 0, "menu and resize preserve established gameplay input isolation")
	viewport.free()
	print("Manual landscape checks: %d failures" % failures)
	quit(1 if failures else 0)
