extends SceneTree

const Cleanup := preload("res://tests/audio_test_cleanup.gd")
const Sound := preload("res://audio/prototypes/M1.3R_baby_alligator_call_study_NONCOMMERCIAL_CC-BY-NC-3.0.wav")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var cleanup := Cleanup.new()
	var player := AudioStreamPlayer.new()
	root.add_child(player)
	player.stream = Sound
	# A configured but never-played player has nothing to drain.
	cleanup.observe(player)
	var frame := Engine.get_process_frames()
	if not await cleanup.wait_for_retirement(self, 0) or Engine.get_process_frames() != frame:
		push_error("Empty teardown must finish in the same frame")
		quit(1)
		return
	var exercise_timeout := "--timeout" in OS.get_cmdline_user_args()
	player.play()
	if not player.has_stream_playback():
		push_error("Regression probe did not create a playback")
		quit(1)
		return
	cleanup.observe(player)
	var retained: AudioStreamPlayback
	if exercise_timeout:
		retained = player.get_stream_playback()
	# Let the player submit the playback to the audio server before stopping.
	await process_frame
	await process_frame
	player.stop()
	player.free()
	var drained := await cleanup.wait_for_retirement(self, 0 if exercise_timeout else Cleanup.TIMEOUT_MS)
	if exercise_timeout:
		if retained == null:
			push_error("Timeout probe lost its retained reference")
		retained = null
		if not await cleanup.wait_for_retirement(self):
			quit(2)
			return
		quit(1 if not drained else 2)
		return
	print("Audio teardown regression: ", "passed" if drained else "failed")
	quit(0 if drained else 1)
