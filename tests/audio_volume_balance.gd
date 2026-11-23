extends SceneTree
var audio_cleanup = preload("res://tests/audio_test_cleanup.gd").new()

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	audio_cleanup.attach(self)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var audio = game.audio_manager
	audio.muted = false
	audio.focused = true
	var expected := {"irritated.voice": -14.0, "shake.voice": -10.0, "stop.voice": -9.0}
	var passed := true
	for id in expected:
		audio.tick(1.0)
		passed = audio.play_event(id) and passed
		passed = is_equal_approx(audio.players.voice.volume_db, expected[id]) and passed
		audio.stop_all()
	audio.muted = true
	game.queue_free()
	print("Volume balance checks passed: ", passed)
	await audio_cleanup.finish(self, 0 if passed else 1)
