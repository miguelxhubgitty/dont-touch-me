extends SceneTree
## Regression coverage for tests/audio_test_cleanup.gd (adapted from PR #10).
## Run with `-- --finish-timeout` to see finish() report a retained playback and exit 1.
const Cleanup := preload("res://tests/audio_test_cleanup.gd")
const Blob := preload("res://scripts/blob.gd")
const Sound := preload("res://audio/candidate_sfx/user/game_start.wav")
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)

func started_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = Sound
	root.add_child(player)
	player.play()
	return player

func run() -> void:
	var cleanup := Cleanup.new()
	cleanup.attach(self)
	# Nothing played: no frame is spent.
	var frame := Engine.get_process_frames()
	check(await cleanup.drain(self, 0) and Engine.get_process_frames() == frame, "empty teardown finishes in the same frame")

	# The tree hook watches a real game's audio manager without per-suite wiring.
	var game := Blob.new()
	root.add_child(game)
	game.set_process(false)
	game.audio_manager.muted = false
	game.audio_manager.play_event("user.tap_miss")
	check(cleanup._playbacks.size() > 0, "game playback observed through the tree hook")
	await process_frame
	game.free()
	check(await cleanup.drain(self), "freed game playback retires before the deadline")

	# A just-stopped real player drains.
	var player := started_player()
	cleanup.observe(player)
	await process_frame
	await process_frame
	player.stop()
	player.free()
	check(await cleanup.drain(self), "stopped player playback retires before the deadline")

	# Deliberate timeout: a retained playback must keep drain() from passing.
	player = started_player()
	cleanup.observe(player)
	var retained := player.get_stream_playback()
	player.stop()
	player.free()
	check(not await cleanup.drain(self, 100), "retained playback makes drain() time out")
	check(cleanup._playbacks.size() == 1, "timeout leaves exactly the retained playback pending")
	if "--finish-timeout" in OS.get_cmdline_user_args():
		await cleanup.finish(self, 0) # Expected: error and exit 1.
		return
	retained = null
	check(await cleanup.drain(self), "released playback then retires")

	print("Audio shutdown checks: %s" % ("passed" if failures == 0 else "%d failures" % failures))
	await cleanup.finish(self, 1 if failures else 0)
