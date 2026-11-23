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
	var failures := 0
	var miss := Vector2(2, 200)
	var base: float = audio.events["user.tap_miss"].volume_db
	for attenuation in [0, 0, 0, 0, -6, -12, -18, -24, -30, -30]:
		audio.tick(0.2)
		game._handle_player_touch(miss)
		if not is_equal_approx(audio.players.contact.volume_db, base + attenuation):
			failures += 1
	audio.tick(0.44)
	game._handle_player_touch(miss)
	if not is_equal_approx(audio.players.contact.volume_db, base - 30):
		failures += 1
	audio.tick(0.45)
	game._handle_player_touch(miss)
	if not is_equal_approx(audio.players.contact.volume_db, base):
		failures += 1
	for i in range(3):
		audio.tick(0.2)
		game._handle_player_touch(miss)
	audio.tick(0.2)
	if not game.touch_at(game.body_position + Vector2(0, -70)) or audio.reaction_attenuation_db != -6:
		failures += 1
	game.begin_reaction(game.Reaction.BOX, game.body_position)
	game.advance(1.1)
	audio.trace.clear()
	var streak: int = audio.click_streak
	game._handle_player_touch(game._box_position() + Vector2(0, -60))
	if not audio.trace.is_empty() or streak != audio.click_streak:
		failures += 1
	audio.muted = true
	game.queue_free()
	await process_frame
	await process_frame
	print("Click attenuation failures: ", failures)
	await audio_cleanup.finish(self, 1 if failures else 0)
