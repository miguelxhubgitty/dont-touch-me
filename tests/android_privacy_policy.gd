extends SceneTree

const Game := preload("res://main.tscn")
const HudSafeArea := preload("res://scripts/hud_safe_area.gd")

class AndroidButton extends "res://scripts/privacy_policy_button.gd":
	var requests := 0

	func _is_android() -> bool:
		return true

	func _open_policy() -> void:
		requests += 1

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func add_game(viewport: SubViewport, simulate_android: bool) -> Node:
	var game := Game.instantiate()
	if simulate_android:
		game.get_node("PrivacyHUD/PrivacyPolicy").set_script(AndroidButton)
	game.get_node("SoundHUD/SoundButton").settings_path = "user://privacy-test-mute.cfg"
	game.get_node("SoundHUD/VolumeButton").settings_path = "user://privacy-test-volume.cfg"
	viewport.add_child(game)
	game.set_process(false)
	return game

func touch(viewport: Viewport, point: Vector2, down: bool, device := 0, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = down
	event.canceled = canceled
	event.device = device
	viewport.push_input(event, true)

func click(viewport: Viewport, point: Vector2, device := 0) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = down
		event.device = device
		viewport.push_input(event, true)

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	root.add_child(viewport)
	var game := add_game(viewport, false)
	var hidden_button: Button = game.get_node("PrivacyHUD/PrivacyPolicy")
	check(not hidden_button.is_visible_in_tree() and hidden_button.pressed.get_connections().is_empty(),
		"desktop leaves the HUD hidden and activation disconnected")
	game.free()
	game = add_game(viewport, true)
	var button: AndroidButton = game.get_node("PrivacyHUD/PrivacyPolicy")
	check(button.is_visible_in_tree() and button.flat and button.text == "Privacy Policy", "Android uses the original flat label")
	var portrait := Rect2(0, 0, 720, 1280)
	button._place(HudSafeArea.to_viewport(portrait, Rect2(), Vector2.ZERO, Transform2D.IDENTITY))
	check(button.get_global_rect().is_equal_approx(Rect2(496, 1198, 200, 58)), "original portrait footprint and margins")

	var point := button.get_global_rect().get_center()
	var manager: Node = game.audio_manager
	manager.trace_enabled = true
	game.annoyance = 9.0
	game.idle_time = 1.8
	touch(viewport, point, true)
	check(button.requests == 1, "native touch opens on press")
	var drag := InputEventScreenDrag.new()
	drag.position = point + Vector2(9, 9)
	viewport.push_input(drag, true)
	check(viewport.is_input_handled() and button.requests == 1, "drag is consumed without another launch")
	click(viewport, point, InputEvent.DEVICE_ID_EMULATION)
	touch(viewport, point, false)
	check(button.requests == 1, "paired synthetic mouse and touch release cannot reopen")
	touch(viewport, point, true, InputEvent.DEVICE_ID_EMULATION)
	touch(viewport, point, false, InputEvent.DEVICE_ID_EMULATION)
	touch(viewport, point, true, 0, true)
	touch(viewport, point, false)
	check(button.requests == 1, "emulated and canceled touches do not open the browser")
	click(viewport, point)
	check(button.requests == 2, "normal Button activation opens once")
	check(game.annoyance == 9.0 and game.idle_time == 1.8 and game.reaction == 0,
		"privacy gestures do not touch gameplay")
	check(manager.click_streak == 0 and manager.trace.is_empty(), "privacy gestures do not trigger click tracking or audio")
	touch(viewport, point + Vector2(101, 0), true)
	touch(viewport, point + Vector2(101, 0), false)
	check(game.annoyance < 9.0 and button.requests == 2, "a background touch immediately outside still counts as a miss")

	var volume: Button = game.get_node("SoundHUD/VolumeButton")
	click(viewport, volume.get_global_rect().get_center())
	check(volume.panel.visible, "volume panel opens")
	click(viewport, volume.get_global_rect().get_center())
	check(not volume.panel.visible, "volume panel closes")

	# Insets and origin are in physical pixels. Neither offset is in HUD units.
	var scaled_portrait := Transform2D(0.0, Vector2(1.5, 1.5), 0.0, Vector2(30, 45))
	button._place(HudSafeArea.to_viewport(portrait, Rect2(180, 170, 990, 1740), Vector2(120, 80), scaled_portrait))
	check(button.get_global_rect().is_equal_approx(Rect2(456, 1108, 200, 58)),
		"portrait safe area converts viewport scaling and both offsets")
	viewport.size = Vector2i(1280, 720)
	await process_frame
	var landscape := Rect2(0, 0, 1280, 720)
	var scaled_landscape := Transform2D(0.0, Vector2(0.75, 0.75), 0.0, Vector2(12, 36))
	button._place(HudSafeArea.to_viewport(landscape, Rect2(165, 129, 858, 468), Vector2(96, 54), scaled_landscape))
	check(button.get_global_rect().is_equal_approx(Rect2(996, 594, 200, 58)),
		"landscape asymmetric physical safe area maps to original HUD margins")
	viewport.size = Vector2i(360, 800)
	await process_frame
	button._place(HudSafeArea.to_viewport(Rect2(0, 0, 360, 800), Rect2(900, 900, 1, 1), Vector2.ZERO, Transform2D.IDENTITY))
	check(button.get_global_rect().is_equal_approx(Rect2(136, 718, 200, 58)),
		"an unavailable safe area falls back to the visible narrow viewport")
	viewport.free()
	print("Android privacy checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
