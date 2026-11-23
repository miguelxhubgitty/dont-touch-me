extends SceneTree
## Physical movement finishes and settles under touches, in both renderers.
## See plans/movement-continuity.md.
var audio_cleanup = preload("res://tests/audio_test_cleanup.gd").new()
const Game = preload("res://main.tscn")
const Blob = preload("res://scripts/blob.gd")
const STEP := 1.0 / 60.0
const EXPRESSION := [Blob.Reaction.BLINK, Blob.Reaction.SIDE_EYE, Blob.Reaction.SQUISH, Blob.Reaction.IRRITATED,
	Blob.Reaction.DONT, Blob.Reaction.SERIOUSLY, Blob.Reaction.SHAKE, Blob.Reaction.FLATTEN, Blob.Reaction.TURN,
	Blob.Reaction.STOP, Blob.Reaction.SIGN, Blob.Reaction.PUFFER_HUFF]
const WIDTHS := [300, 360, 720, 1280]
var checks := 0
var failures := 0
var accepted_locked_hits := 0
var maximum_step := 0.0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		if failures < 30: printerr("FAIL: " + message)

func make(viewport: SubViewport, native: bool, free_jump: bool):
	var game = Game.instantiate()
	game.use_adobe_idle = native
	game.free_jump_enabled = free_jump
	viewport.add_child(game)
	game.set_process(false)
	game.audio_manager.muted = false # Playback is needed to count real landings.
	game.audio_manager.set_focused(true)
	game.audio_manager.trace_enabled = true
	game._resize()
	return game

func reset(game, x: float) -> void:
	game.reaction = Blob.Reaction.NONE
	game.last_reaction = Blob.Reaction.NONE
	game.jump_returning = false
	game.asleep = false
	game.elapsed = 0
	game.clock = 0.65
	game.idle_time = 0
	game._reset_special_idle()
	game.annoyance = 0
	game.successful_poke_streak = 0
	game.blink_timer = 2.5
	game.gaze_timer = 1
	game.blink_remaining = 0
	game.rng.seed = 9
	game.idle_rng.seed = 9
	game.anchor = Vector2(x, game.last_size.y * .58)
	game.origin = game.anchor
	game.destination = game.anchor
	game.audio_manager.cancel_reaction()
	game.audio_manager.trace.clear()
	game._update_pose()

func poke(viewport: SubViewport, point: Vector2, touch: bool) -> void:
	var event: InputEvent
	if touch:
		var finger := InputEventScreenTouch.new()
		finger.position = point
		finger.pressed = true
		event = finger
	else:
		var mouse := InputEventMouseButton.new()
		mouse.position = point
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = true
		event = mouse
	viewport.push_input(event, true)

func shown_scale(game) -> Vector2:
	return game.breathing.scale if game.uses_authored_visual() else game.body_scale

func settled(game) -> bool:
	return game.reaction == Blob.Reaction.NONE and not game.jump_returning

func run() -> void:
	audio_cleanup.attach(self)
	var viewport := SubViewport.new()
	viewport.handle_input_locally = true
	root.add_child(viewport)
	# The untouched twin lives in its own viewport, so pushed input never reaches it.
	var quiet := SubViewport.new()
	quiet.handle_input_locally = true
	root.add_child(quiet)
	for width in WIDTHS:
		viewport.size = Vector2i(width, 1280)
		quiet.size = viewport.size
		await process_frame
		for native in [false, true]:
			for variant in ["slide", "free_jump", "jump", "recoil", "wake"]:
				await movement_case(viewport, quiet, width, native, variant)
			await expression_case(viewport, width, native)
			await destination_case(viewport, width, native)
	await rapid_and_resize(viewport)
	viewport.free()
	quiet.free()
	await process_frame
	var result := {"checks": checks, "failures": failures, "accepted_locked_hits": accepted_locked_hits,
		"maximum_position_step_on_restart": maximum_step, "widths": WIDTHS}
	print("MOVEMENT_CONTINUITY ", JSON.stringify(result))
	await audio_cleanup.finish(self, 0 if failures == 0 else 1)

## Touches during the whole movement keep it identical to an untouched twin.
func movement_case(viewport: SubViewport, quiet: SubViewport, width: int, native: bool, variant: String) -> void:
	var free_jump := variant == "free_jump"
	var which: int = {"slide": Blob.Reaction.SLIDE, "free_jump": Blob.Reaction.JUMP, "jump": Blob.Reaction.JUMP,
		"recoil": Blob.Reaction.RECOIL, "wake": Blob.Reaction.WAKE}[variant]
	var label := "%s %s w%d" % [variant, "authored" if native else "procedural", width]
	var touched = make(viewport, native, free_jump)
	var twin = make(quiet, native, free_jump)
	for game in [touched, twin]:
		reset(game, width * .5)
		game.begin_reaction(which, game.body_position + Vector2(-20, -70))
	var lands := [0] # Lambdas capture locals by value; share a counter.
	touched.audio_manager.event_played.connect(func(id): if id == "jump.land": lands[0] += 1)
	var frame := 0
	var hits := 0
	while not settled(twin) and frame < 2000:
		frame += 1
		if frame % 5 == 0:
			var before: float = touched.annoyance
			var point: Vector2 = touched.body_position + Vector2(0, -70)
			var visible: bool = touched.contains_touch(point)
			poke(viewport, point, frame % 10 == 0)
			if visible:
				hits += 1
				check(touched.annoyance > before or touched.successful_poke_streak >= 9, label + " locked hit still scores")
				check(touched.idle_time == 0.0 and touched.touch_flash == 1.0, label + " locked hit resets idle and flashes")
			check(touched.reaction == twin.reaction and touched.elapsed == twin.elapsed and touched.jump_returning == twin.jump_returning,
				label + " touch keeps the reaction and its clock")
		for game in [touched, twin]:
			game.advance(STEP)
		check(touched.body_position.distance_to(twin.body_position) < .0001, label + " path unchanged by touches")
		check(shown_scale(touched).distance_to(shown_scale(twin)) < .0001, label + " squash and recovery unchanged by touches")
	accepted_locked_hits += hits
	check(hits >= 3, label + " visible body accepted touches during the movement")
	check(settled(touched) and settled(twin), label + " movement settles")
	check(touched.body_position.distance_to(twin.body_position) < .0001 and touched.body_position.y == touched.anchor.y, label + " settles on the floor at the same place")
	if free_jump:
		check(lands[0] == 1, label + " lands exactly once (%d)" % lands[0])
	# The first touch after settling interrupts normally, exactly where the body is.
	var rest: Vector2 = touched.body_position
	poke(viewport, rest + Vector2(0, -70), true)
	check(touched.reaction != Blob.Reaction.NONE and touched.elapsed == 0.0, label + " next touch starts a reaction")
	check(touched.origin == Vector2(rest.x, touched.anchor.y), label + " next reaction starts at the rest position")
	var step: float = touched.body_position.distance_to(rest)
	maximum_step = maxf(maximum_step, step)
	check(step < .001, label + " no teleport when the next reaction starts")
	touched.free()
	twin.free()
	await process_frame

## Expression-only reactions stay interruptible.
func expression_case(viewport: SubViewport, width: int, native: bool) -> void:
	var game = make(viewport, native, true)
	for which in EXPRESSION:
		reset(game, width * .5)
		game.begin_reaction(which, game.body_position + Vector2(-20, -70))
		game.advance(float(Blob.DURATIONS[which]) * .5)
		check(not game.reaction_locked(), "expression reaction is not locked")
		var point: Vector2 = game.body_position + Vector2(0, -70)
		if not game.contains_touch(point):
			continue
		var before: Vector2 = game.body_position
		poke(viewport, point, false)
		check(game.reaction != which and game.elapsed == 0.0, "expression reaction %d interrupts at width %d" % [which, width])
		check(game.origin == Vector2(before.x, game.anchor.y), "interrupted expression keeps its x")
	game.free()
	await process_frame

## Destinations stay on stage at every width, and reactions start at the body.
func destination_case(viewport: SubViewport, width: int, native: bool) -> void:
	var game = make(viewport, native, false)
	var margin := minf(190.0, width * .5)
	for x in [30.0, width * .25, width * .5, width * .75, width - 30.0]:
		for side in [-1.0, 1.0]:
			for which in [Blob.Reaction.SLIDE, Blob.Reaction.JUMP]:
				reset(game, x)
				game.begin_reaction(which, game.body_position + Vector2(side * 20, -70))
				check(game.origin.x == x and game.body_position.x == x, "reaction starts at the body (w%d x%.0f)" % [width, x])
				check(game.destination.x >= margin and game.destination.x <= width - margin, "destination inside the stage band (w%d x%.0f)" % [width, x])
				if game.destination.x != x:
					check(signf(game.destination.x - x) == game.direction, "facing follows the travel (w%d x%.0f)" % [width, x])
				game.advance(float(Blob.DURATIONS[which]))
				check(game.body_position.x == game.destination.x and settled(game), "ends at its destination (w%d x%.0f)" % [width, x])
	game.free()
	await process_frame

## Frantic tapping during a locked jump, and resize during a lock.
func rapid_and_resize(viewport: SubViewport) -> void:
	viewport.size = Vector2i(720, 1280)
	await process_frame
	for native in [false, true]:
		var game = make(viewport, native, true)
		reset(game, 360)
		game.begin_reaction(Blob.Reaction.JUMP, game.body_position + Vector2(-20, -70))
		var lands := [0] # Lambdas capture locals by value; share a counter.
		game.audio_manager.event_played.connect(func(id): if id == "jump.land": lands[0] += 1)
		for tap in range(30):
			poke(viewport, game.body_position + Vector2(0, -70), tap % 2 == 0)
			check(game.reaction == Blob.Reaction.JUMP and game.last_reaction == Blob.Reaction.JUMP, "rapid taps never start another reaction")
			game.advance(1.0 / 120.0)
		check(game.successful_poke_streak == 9, "rapid taps still build the poke streak")
		check(game.audio_manager.trace.count("jump.contact") <= 3, "contact cooldown prevents a burst")
		game.advance(1.05)
		check(lands[0] == 1 and settled(game), "rapid taps still land once")
		# Resize still cancels a lock, without a landing.
		reset(game, 360)
		lands[0] = 0
		game.begin_reaction(Blob.Reaction.JUMP, game.body_position + Vector2(-20, -70))
		game.advance(.4)
		viewport.size = Vector2i(800, 1280)
		await process_frame
		game._resize()
		check(settled(game) and not game.reaction_locked(), "resize cancels a lock")
		game.advance(1.0)
		check(lands[0] == 0, "cancelled jump never lands")
		viewport.size = Vector2i(720, 1280)
		await process_frame
		game.free()
		await process_frame
