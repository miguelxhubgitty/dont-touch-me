extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var audio = game.audio_manager
	audio.muted = false
	audio.focused = true
	audio.audio_rng.seed = 42
	var gameplay_rng: int = game.rng.state
	var pitches := {}
	var passed := true
	for i in range(16):
		audio.tick(0.2)
		passed = audio.play_event("blink.contact") and passed
		var player: AudioStreamPlayer = audio.players.contact
		pitches[player.pitch_scale] = true
		passed = passed and absf(player.pitch_scale - 1.0) <= 0.03001
		passed = passed and absf(player.volume_db - float(audio.events["blink.contact"].volume_db)) <= 0.60001
	audio.tick(0.2)
	audio.play_event("user.tap_miss")
	passed = passed and audio.players.contact.pitch_scale == 1.0
	audio.play_event("wake.voice")
	passed = passed and audio.players.voice.pitch_scale == 1.0
	passed = passed and pitches.size() > 1 and game.rng.state == gameplay_rng
	audio.muted = true
	game.queue_free()
	await create_timer(0.3).timeout
	print("Audio variation checks passed: ", passed)
	quit(0 if passed else 1)
