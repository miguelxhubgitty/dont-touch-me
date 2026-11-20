extends SceneTree

const Game = preload("res://main.tscn")
const IdleFixture = preload("res://tests/idle_fixture.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func make_actor(authored: bool):
	var actor = Game.instantiate()
	actor.use_adobe_idle = authored
	root.add_child(actor)
	actor.set_process(false)
	actor.audio_manager.muted = false
	actor.audio_manager.set_focused(true)
	actor.audio_manager.trace_enabled = true
	actor.audio_manager.stop_all()
	actor.rng.seed = 918
	actor.idle_rng.seed = 81
	return actor

func poke(actor, screen_touch: bool) -> void:
	var point: Vector2 = actor.body_position + Vector2(-14, -70)
	if screen_touch:
		var finger := InputEventScreenTouch.new()
		finger.pressed = true
		finger.position = point
		actor._unhandled_input(finger)
	else:
		var mouse := InputEventMouseButton.new()
		mouse.pressed = true
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.position = point
		actor._unhandled_input(mouse)

func mark(actor, time: float) -> void:
	actor.advance(time - actor.elapsed)
	# Sample the exact fractional boundary for visual assertions.
	actor.elapsed = time
	actor._update_pose()

func examine(authored: bool) -> void:
	var actor = make_actor(authored)
	var baseline = make_actor(authored)
	for subject in [actor, baseline]:
		IdleFixture.arm(subject, subject.SpecialIdle.YAWN, 10.8)
		subject.advance(11.0)
		subject.advance(.75)
		subject.audio_manager.trace.clear()
		check(subject.active_idle == subject.SpecialIdle.YAWN, "start at live Yawn")
	var outgoing: PackedVector2Array = actor.yawn_mouth.duplicate()
	var eye_before: float = actor._displayed_yawn_aperture()
	baseline.active_idle = baseline.SpecialIdle.NONE
	poke(actor, authored)
	poke(baseline, authored)
	check(actor.elapsed == 0.0 and actor.idle_time == 0.0 and actor.reaction == baseline.reaction, "poke starts the reaction immediately")
	check(actor.audio_manager.trace == baseline.audio_manager.trace and not actor.audio_manager.trace.is_empty(), "no delay or change to reaction audio")
	check(actor.yawn_mouth == outgoing and is_equal_approx(actor._startled_aperture(0.8), eye_before), "initial face uses the outgoing pose")
	for time in [.018,.036,.054,.072,.126,.18,.19]:
		mark(actor, time)
		mark(baseline, time)
		check(actor.reaction == baseline.reaction and actor.annoyance == baseline.annoyance, "gameplay state matches baseline")
		check(actor.body_position.is_equal_approx(baseline.body_position) and actor.body_scale.is_equal_approx(baseline.body_scale) and is_equal_approx(actor.body_angle, baseline.body_angle), "face overlay does not modify body")
		if authored:
			check(actor.breathing.transform.is_equal_approx(baseline.breathing.transform), "authored silhouette transform matches")
		for x in range(-135,136,15):
			var point: Vector2 = actor.body_position + Vector2(x,-92)
			check(actor.contains_touch(point) == baseline.contains_touch(point), "overlay never affects hit detection")
		if time < .036:
			check(not actor.yawn_mouth.is_empty() and absf(actor.yawn_mouth[24].y + 66.0) < absf(outgoing[24].y + 66.0), "mouth closure interpolates")
		else:
			check(actor.yawn_mouth.is_empty(), "mouth hidden from 36 ms onward")
		if time == .036:
			check(is_equal_approx(actor._startled_aperture(0.8), 1.35), "wide at 36 ms")
		if time == .072:
			check(actor._startled_aperture(0.8) == 0.0, "both eyes close fully at 72 ms")
			if authored:
				check(not actor.left_eye.visible and not actor.right_eye.visible, "closed authored eyes are hidden")
		if time == .126:
			check(is_equal_approx(actor._startled_aperture(0.8), 0.4), "slow return interpolates toward live reaction")
		if time >= .18:
			check(not actor._startled_active() and actor.startled_mouth.is_empty(), "overlay clears by 180 ms")
			if authored:
				check(actor.eyes.scale == baseline.eyes.scale and actor.left_eye.visible == baseline.left_eye.visible, "normal authored face restored")
	check(actor.audio_manager.trace == baseline.audio_manager.trace, "audio trace matches through overlay")

	actor.reaction = actor.Reaction.NONE
	actor.idle_time = 0.0
	actor._reset_special_idle()
	IdleFixture.arm(actor, actor.SpecialIdle.YAWN, 10.8)
	actor.advance(11.0)
	actor.advance(.65)
	poke(actor, authored)
	mark(actor, .018)
	actor._handle_player_touch(Vector2(2, 2))
	check(actor._startled_active() and actor.elapsed == .018, "miss leaves the overlay running")
	poke(actor, authored)
	check(not actor._startled_active() and actor.startled_mouth.is_empty(), "a second accepted poke clears the old overlay")

	actor.reaction = actor.Reaction.NONE
	actor.idle_time = 0.0
	actor._reset_special_idle()
	IdleFixture.arm(actor, actor.SpecialIdle.YAWN, 10.8)
	actor.advance(11.0)
	actor.advance(.65)
	poke(actor, authored)
	check(actor._startled_active(), "new Yawn gets its own overlay")
	actor.last_size = Vector2.ZERO
	actor._resize()
	check(not actor._startled_active() and actor.yawn_mouth.is_empty(), "resize clears the current overlay")

	actor.begin_reaction(actor.Reaction.WAKE, actor.body_position)
	check(not actor._startled_active() and is_equal_approx(actor.eye_open, 1.35), "WAKE keeps immediate surprise")
	actor.free()
	baseline.free()

func run() -> void:
	examine(true)
	examine(false)
	print("Stage 3 polish checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
