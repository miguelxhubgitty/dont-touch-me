extends SceneTree

const GAME := preload("res://main.tscn")
const PREFS := "user://volume_controls_regression.cfg"
const MUTE_PREFS := "user://volume_controls_mute_regression.cfg"
var passed := true

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var game = GAME.instantiate()
	var button = game.get_node("SoundHUD/VolumeButton")
	button.settings_path = PREFS
	game.get_node("SoundHUD/SoundButton").settings_path = MUTE_PREFS
	root.add_child(game)
	game.set_process(false)
	await process_frame
	var audio = game.audio_manager
	audio.muted = false
	audio.trace_enabled = true
	var before: float = game.annoyance
	var reaction: int = game.reaction
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = button.get_global_rect().get_center()
	root.push_input(touch, true)
	await process_frame
	passed = passed and button.panel.visible and button.sliders.size() == 5
	var i := 0
	for bus in button.BUSES:
		var slider: HSlider = button.sliders[bus]
		var bus_index := AudioServer.get_bus_index(bus)
		passed = passed and slider.value == 100 and AudioServer.get_bus_volume_db(bus_index) == 0
		var click := InputEventScreenTouch.new()
		click.index = i + 1
		click.pressed = true
		click.position = slider.get_global_rect().position + slider.size * Vector2(0.5, 0.5)
		root.push_input(click, true)
		click = click.duplicate()
		click.pressed = false
		root.push_input(click, true)
		passed = passed and is_equal_approx(slider.value, 50)
		slider.value = i * 20
		passed = passed and AudioServer.is_bus_mute(bus_index) == (i == 0)
		i += 1
	passed = passed and game.annoyance == before and game.reaction == reaction and audio.trace.is_empty()
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
	quit(0 if passed else 1)
