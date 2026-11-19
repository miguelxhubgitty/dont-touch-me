extends SceneTree

const Game = preload("res://main.tscn")
var failures := 0
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func fixture(authored: bool):
	var game = Game.instantiate()
	game.use_adobe_idle = authored
	root.add_child(game)
	game.set_process(false)
	game.rng.seed = 918
	game.idle_rng.seed = 81
	game.audio_manager.trace_enabled = true
	game.audio_manager.set_focused(true)
	return game

func poke(game) -> bool:
	return game.touch_at(game.body_position + Vector2(0, -70))

func pointer(game, point: Vector2, mouse: bool) -> void:
	if mouse:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		event.position = point
		game.get_viewport().push_input(event, true)
	else:
		var event := InputEventScreenTouch.new()
		event.pressed = true
		event.position = point
		game.get_viewport().push_input(event, true)

func check_window(game) -> void:
	var audio = game.audio_manager
	for multiplier in [1.0, 1.0, 1.0, 1.0, 0.8, 0.6, 0.4, 0.2, 0.0, 0.0]:
		var roll := RandomNumberGenerator.new()
		roll.state = game.rng.state
		var expected: float = roll.randf_range(1.8, 3.6) * multiplier
		var before: float = game.annoyance
		var previous: int = game.reaction
		check(poke(game), "successful poke")
		check(is_equal_approx(game.annoyance - before, expected), "seeded gain at multiplier %s" % multiplier)
		check(game.reaction != previous and game.reaction != game.Reaction.NONE, "successful poke selects a new reaction even at zero gain")
		game.advance(0.09)
	game.advance(0.45)
	check(audio.click_attenuation_db() == 0.0, "audio streak expires before gameplay window")
	var before: float = game.annoyance
	check(poke(game) and game.annoyance == before and audio.click_streak == 1, "gameplay stays on plateau across audio reset")
	for at in [1.53, 1.71, 1.79, 1.8]:
		game.advance(at - game.clock)
		before = game.annoyance
		check(poke(game), "continuous poke at %s" % at)
		check((game.annoyance > before) == (at == 1.8), "full gain only at exact window boundary")
	check(game.successful_poke_streak == 1 and is_equal_approx(game.poke_streak_started_at, 1.8), "window restarts on boundary poke")
	check(audio.click_attenuation_db() < 0.0, "gameplay reset preserves active audio attenuation")
	game.advance(1.79)
	check(poke(game) and game.successful_poke_streak == 2, "gap just under expiry keeps the streak")
	game.advance(1.8)
	check(poke(game) and game.successful_poke_streak == 1, "1.8-second gap starts a streak")
	game.advance(2.7)
	check(poke(game) and game.successful_poke_streak == 1, "long gap starts one fresh streak")

func check_rejected_and_protected(game) -> void:
	var audio = game.audio_manager
	game.annoyance = 18.0
	check(poke(game), "open a gameplay streak")
	game.begin_reaction(game.Reaction.BOX, game.body_position)
	game.advance(0.9)
	audio.tick(0.45)
	audio.trace.clear()
	var idle_before: float = game.idle_time
	var start_before: float = game.poke_streak_started_at
	var elapsed_before: float = game.elapsed
	var streak_before: int = game.successful_poke_streak
	var annoyance_before: float = game.annoyance
	pointer(game, game.body_position + Vector2(0, -60), false)
	var loss: float = annoyance_before - game.annoyance
	check(loss >= 1.8 and loss <= 3.6 and audio.trace.is_empty(), "cardboard calms without audio")
	annoyance_before = game.annoyance
	pointer(game, Vector2(2, 2), true)
	loss = annoyance_before - game.annoyance
	check(loss >= 0.9 and loss <= 1.8 and audio.trace.count("user.tap_miss") == 1, "background calms and plays miss audio")
	check(game.reaction == game.Reaction.BOX and game.elapsed == elapsed_before, "rejected touches leave protected BOX in progress")
	check(game.idle_time == idle_before and game.poke_streak_started_at == start_before and game.successful_poke_streak == streak_before, "rejected touches leave gameplay streak clocks and count alone")
	game.annoyance = 0.1
	pointer(game, Vector2(2, 2), false)
	check(game.annoyance == 0.0, "miss clamps to zero")
	check(game.touch_at(game._box_position() + Vector2(28, -148)) and game.reaction == game.Reaction.BOX and game.elapsed == elapsed_before, "peek eyes are touchable with BOX protected")
	game.begin_reaction(game.Reaction.RUN, game.body_position)
	game.advance(0.09)
	game.annoyance = 99.9
	elapsed_before = game.elapsed
	check(poke(game) and game.reaction == game.Reaction.RUN and game.elapsed == elapsed_before, "RUN accepts a visible poke without restart")
	check(game.annoyance == 100.0, "successful gain clamps to 100")

func check_tier_access(game) -> void:
	var reached := {}
	for i in range(180):
		# Present an exposed, stationary body for every input. Protected
		# reactions and moving hit tests have separate end-to-end coverage.
		game.reaction = game.Reaction.NONE
		game._update_pose()
		check(poke(game), "tier progression poke accepted")
		reached[game.tier()] = true
		game.advance(0.18)
	check(reached.size() == 4 and game.annoyance == 100.0, "continuous accepted pokes reach all tiers")

func run() -> void:
	var games: Array = []
	for authored in [true, false]:
		var game = fixture(authored)
		game.audio_manager.muted = not authored
		check_window(game)
		games.append(game)
		game = fixture(authored)
		game.audio_manager.muted = false
		check_rejected_and_protected(game)
		games.append(game)
		game = fixture(authored)
		game.audio_manager.muted = true
		check_tier_access(game)
		games.append(game)
	for game in games:
		game.audio_manager.stop_all()
		game.queue_free()
	await process_frame
	print("Annoyance Stage 1 checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
