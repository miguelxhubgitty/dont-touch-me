extends SceneTree
var audio_cleanup = preload("res://tests/audio_test_cleanup.gd").new()

const GAME := preload("res://main.tscn")
const ManualBlob := preload("res://tests/manual_blob.gd")
const HudSafeArea := preload("res://scripts/hud_safe_area.gd")

class TrackedVolume extends "res://scripts/audio_volume_controls.gd":
	var saves := 0
	func _save() -> void:
		saves += 1
		super._save()
const PREFS := "user://volume_controls_regression.cfg"
const MUTE_PREFS := "user://volume_controls_mute_regression.cfg"
var passed := true

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		passed = false
		printerr("FAIL: " + message)

func touch(point: Vector2, index: int, down: bool, canceled := false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = down
	event.canceled = canceled
	root.push_input(event, true)

func drag(point: Vector2, index: int) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = point
	root.push_input(event, true)

func mouse(point: Vector2, device: int) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.device = device
		root.push_input(event, true)

func at(slider: HSlider, x: float) -> Vector2:
	return slider.get_global_rect().position + slider.size * Vector2(x, 0.5)

func run() -> void:
	audio_cleanup.attach(self)
	var game = GAME.instantiate()
	var free_jump: bool = game.free_jump_enabled
	game.set_script(ManualBlob)
	game.free_jump_enabled = free_jump
	var button = game.get_node("SoundHUD/VolumeButton")
	button.set_script(TrackedVolume)
	button.settings_path = PREFS
	game.get_node("SoundHUD/SoundButton").settings_path = MUTE_PREFS
	root.add_child(game)
	root.propagate_notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN) # As when the window gains focus; must not advance the blob.
	await process_frame
	var audio = game.audio_manager
	audio.muted = false
	audio.trace_enabled = true
	game.annoyance = 9.0
	game.idle_time = 1.8
	var before: float = game.annoyance
	var reaction: int = game.reaction
	var volume_center: Vector2 = button.get_global_rect().get_center()
	touch(volume_center, 0, true)
	touch(volume_center, 0, false)
	await process_frame
	mouse(button.get_global_rect().get_center(), InputEvent.DEVICE_ID_EMULATION)
	button.settings_menu.get_child(0).pressed.emit()
	await process_frame
	await process_frame
	passed = passed and button.panel.visible and button.sliders.size() == 5
	check(button.position == Vector2(20, 20) and button.panel.position == Vector2(0, 88),
		"desktop uses the original button and panel positions")
	var i := 0
	for bus in button.BUSES:
		var slider: HSlider = button.sliders[bus]
		var bus_index := AudioServer.get_bus_index(bus)
		passed = passed and slider.value == 100 and AudioServer.get_bus_volume_db(bus_index) == 0
		var saves: int = button.saves
		touch(at(slider, 0.5), i + 1, true)
		check(slider.value == 50, bus + " touch-down updates value")
		drag(at(slider, 0.9), i + 1)
		check(slider.value == 90 and is_equal_approx(AudioServer.get_bus_volume_db(bus_index), linear_to_db(0.9)),
			bus + " drag updates value and gain")
		drag(at(slider, 1.2), i + 1)
		check(slider.value == 100, bus + " captured drag clamps past right edge")
		drag(at(slider, -0.2), i + 1)
		check(slider.value == 0 and AudioServer.is_bus_mute(bus_index), bus + " captured drag clamps past left edge")
		drag(at(slider, 0.9), i + 1)
		check(button.saves == saves, bus + " does not save mid-gesture")
		touch(at(slider, 1.2), i + 1, false)
		check(button.saves == saves + 1 and slider.value == 90, bus + " release outside saves once")
		slider.value = i * 20
		passed = passed and AudioServer.is_bus_mute(bus_index) == (i == 0)
		i += 1
	var first: HSlider = button.sliders["UserSFX"]
	var second: HSlider = button.sliders["CharacterVoice"]
	var label := button.volume_menu.get_child(0) as Label
	var label_point := label.get_global_rect().get_center()
	touch(label_point, 9, true)
	touch(label_point, 9, false)
	touch(at(first, 0.5), 1, true)
	touch(at(second, 0.8), 2, true)
	drag(at(second, 0.9), 2)
	touch(at(second, 0.9), 2, false)
	check(second.value == 20 and button.touch_index == 1, "second finger cannot claim or release the panel gesture")
	var saved: int = button.saves
	touch(at(first, 0.5), 1, false, true)
	check(button.saves == saved + 1 and button.touch_slider == null, "cancellation saves last value once")
	touch(at(first, 0.6), 1, true)
	button.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(button.saves == saved + 2 and button.touch_slider == null, "focus loss saves and clears the gesture")
	touch(at(first, 0.6), 1, false)
	touch(at(first, 0.7), 1, true)
	mouse(button.get_global_rect().get_center(), 0)
	check(button.saves == saved + 3 and button.touch_slider == null and not button.panel.visible,
		"closing the panel with the desktop button saves and clears the gesture")
	touch(at(first, 0.7), 1, false)
	mouse(button.get_global_rect().get_center(), 0)
	check(button.panel.visible, "real mouse still opens the panel")
	button.settings_menu.get_child(0).pressed.emit()
	await process_frame
	await process_frame
	mouse(at(first, 0.5), 0)
	check(first.value > 0, "real mouse still adjusts a slider")
	var mouse_value := first.value
	var step := InputEventAction.new()
	step.action = &"ui_right"
	step.pressed = true
	root.push_input(step, true)
	check(first.value > mouse_value, "focused slider still responds to keyboard")
	audio.muted = true
	touch(at(first, 0.9), 1, true)
	touch(at(first, 0.9), 1, false)
	check(first.value == 90 and audio.muted, "native touch updates a slider while master mute stays on")
	audio.muted = false
	first.value = 0
	check(game.annoyance == before and game.reaction == reaction and game.idle_time == 1.8
		and audio.trace.is_empty() and audio.click_streak == 0, "HUD input leaves gameplay and cue tracking untouched")
	touch(Vector2(18, 18), 9, true)
	touch(Vector2(18, 18), 9, false)
	check(game.annoyance < before and audio.click_streak == 1, "a touch just outside the HUD still reaches gameplay")
	var hud = button.get_parent()
	var layout := Rect2(0, 0, 720, 1280)
	var scaled := Transform2D(0.0, Vector2(1.5, 1.5), 0.0, Vector2(30, 45))
	var safe := HudSafeArea.to_viewport(layout, Rect2(231, 251, 918, 1686), Vector2(120, 80), scaled)
	check(safe.is_equal_approx(Rect2(54, 84, 612, 1124)), "safe rectangle converts scaling and both offsets")
	hud._place(safe)
	check(button.position.is_equal_approx(Vector2(74, 104)) and safe.encloses(button.panel.get_global_rect()),
		"portrait audio panel fits the converted safe rectangle")
	check(safe.encloses(hud.sound.get_global_rect()), "sound button clears the right and top insets")
	var wide := Rect2(54, 45, 1124, 585)
	hud._place(wide)
	check(wide.encloses(button.panel.get_global_rect()) and wide.encloses(hud.sound.get_global_rect()),
		"landscape safe rectangle contains the open panel and sound button")
	var narrow := Rect2(18, 54, 360, 800)
	hud._place(narrow)
	check(narrow.encloses(button.panel.get_global_rect()) and narrow.encloses(hud.sound.get_global_rect())
		and not button.get_global_rect().intersects(hud.sound.get_global_rect()),
		"narrow safe rectangle keeps the panel in bounds and buttons separate")
	game.get_node("SoundHUD/SoundButton").pressed.emit()
	passed = passed and audio.muted
	game.queue_free()
	await process_frame
	game = GAME.instantiate()
	button = game.get_node("SoundHUD/VolumeButton")
	button.settings_path = PREFS
	game.get_node("SoundHUD/SoundButton").settings_path = MUTE_PREFS
	root.add_child(game)
	i = 0
	for bus in button.BUSES:
		passed = passed and button.sliders[bus].value == i * 20
		i += 1
	game.queue_free()
	await process_frame
	DirAccess.remove_absolute(PREFS)
	DirAccess.remove_absolute(MUTE_PREFS)
	print("Volume controls checks passed: ", passed)
	await audio_cleanup.finish(self, 0 if passed else 1)
