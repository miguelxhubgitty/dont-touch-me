extends SceneTree

const Game := preload("res://main.tscn")

class PreviewVolume extends "res://scripts/audio_volume_controls.gd":
	var requests: Array[int] = []

	func _init() -> void:
		settings_path = PREFS

	func _supports_manual_orientation() -> bool:
		return true

	func _request_orientation(orientation: DisplayServer.ScreenOrientation) -> void:
		requests.append(orientation)

const PREFS := "user://orientation-regression.cfg"
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
	if FileAccess.file_exists(PREFS):
		DirAccess.remove_absolute(PREFS)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	root.add_child(viewport)
	var game = Game.instantiate()
	viewport.add_child(game)
	if OS.has_feature("pc"):
		check(game.get_node("SoundHUD/VolumeButton").orientation_menu == null, "desktop menu stays unchanged")
	game.free()
	game = Game.instantiate()
	var volume = game.get_node("SoundHUD/VolumeButton")
	volume.set_script(PreviewVolume)
	viewport.add_child(game)
	game.set_process(false)
	game.annoyance = 9.0
	game.idle_time = 1.8
	await process_frame
	check(volume.requests == [DisplayServer.SCREEN_SENSOR], "Auto is the default")
	tap(viewport, volume.get_global_rect().get_center(), true)
	await process_frame
	await process_frame
	var selector: Button = volume.settings_menu.get_child(1)
	tap(viewport, selector.get_global_rect().get_center(), true)
	await process_frame
	await process_frame
	var landscape: Button = volume.orientation_menu.get_child(2)
	tap(viewport, landscape.get_global_rect().get_center(), true)
	await process_frame
	check(volume.requests == [DisplayServer.SCREEN_SENSOR, DisplayServer.SCREEN_LANDSCAPE]
		and landscape.button_pressed, "native tap requests Landscape once")
	viewport.size = Vector2i(2275, 1280)
	await process_frame
	game._resize()
	var safe_area := Rect2(72, 27, 2100, 1217)
	game.get_node("SoundHUD")._place(safe_area)
	var portrait: Button = volume.orientation_menu.get_child(1)
	check(safe_area.encloses(volume.panel.get_global_rect()), "submenu fits the landscape safe area")
	tap(viewport, portrait.get_global_rect().get_center(), true)
	await process_frame
	check(volume.requests.back() == DisplayServer.SCREEN_PORTRAIT, "Portrait requests a fixed orientation")
	var auto: Button = volume.orientation_menu.get_child(0)
	tap(viewport, auto.get_global_rect().get_center(), true)
	await process_frame
	check(volume.requests.back() == DisplayServer.SCREEN_SENSOR, "Auto restores sensor orientation")
	tap(viewport, portrait.get_global_rect().get_center(), true)
	await process_frame
	var back: Button = volume.orientation_menu.get_child(3)
	tap(viewport, back.get_global_rect().get_center(), true)
	await process_frame
	check(volume.settings_menu.visible and not volume.orientation_menu.visible, "Back returns to Settings")
	check(game.annoyance == 9.0 and game.idle_time == 1.8 and game.reaction == 0
		and game.audio_manager.click_streak == 0, "menu and resize preserve established gameplay input isolation")
	game.free()
	game = Game.instantiate()
	volume = game.get_node("SoundHUD/VolumeButton")
	volume.set_script(PreviewVolume)
	viewport.add_child(game)
	await process_frame
	check(volume.requests == [DisplayServer.SCREEN_PORTRAIT], "saved orientation is restored")
	DirAccess.remove_absolute(PREFS)
	viewport.free()
	print("Manual landscape checks: %d failures" % failures)
	quit(1 if failures else 0)
