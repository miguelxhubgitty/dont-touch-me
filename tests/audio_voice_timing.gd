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
	audio.trace_enabled = true
	game.begin_reaction(game.Reaction.SHAKE, game.body_position)
	game.advance(3.0 / 30.0)
	var passed: bool = not audio.trace.has("shake.voice") and game.uses_authored_reaction()
	game.advance(1.0 / 30.0 + 0.00001)
	passed = passed and audio.trace.count("shake.voice") == 1
	game.advance(1.0 / 30.0)
	passed = passed and audio.trace.count("shake.voice") == 1
	audio.muted = true
	game.queue_free()
	print("Voice timing checks passed: ", passed)
	await audio_cleanup.finish(self, 0 if passed else 1)
