extends SceneTree

const Game = preload("res://main.tscn")
const IdleFixture = preload("res://tests/idle_fixture.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", what)

func reset(actor) -> void:
	actor.asleep = false
	actor.reaction = actor.Reaction.NONE
	actor.jump_returning = false
	actor.idle_time = 0.0
	actor._reset_special_idle()
	actor.next_idle_at = INF
	actor.audio_manager.stop_all()
	actor.audio_manager.trace.clear()

func check_decay(actor) -> void:
	for time in [3.0, 9.0, 12.0, 18.0]:
		var results: Array[float] = []
		for steps in [1, 90, 137]:
			reset(actor)
			actor.annoyance = 100.0
			for step in range(steps):
				actor.advance(time / steps)
			results.append(actor.annoyance)
		var grace: float = time - 3.0
		var expected := maxf(0.0, 100.0 - 0.45 * grace * grace)
		for result in results:
			check(is_equal_approx(result, expected), "decay at %ss is partition independent" % time)
	reset(actor)
	actor.annoyance = 10.0
	actor.advance(3.1)
	check(is_equal_approx(actor.annoyance, 9.9955), "exact integral across the grace period")
	var before := actor.annoyance as float
	actor._handle_player_touch(Vector2(2, 2))
	var after_miss := actor.annoyance as float
	check(before - after_miss >= 0.9 and before - after_miss <= 1.8, "Stage 1 miss still reduces points")
	actor.advance(0.4)
	check(is_equal_approx(actor.annoyance, after_miss - 0.108), "next interval subtracts only its own decay")
	check(actor.touch_at(actor.body_position + Vector2(0, -76)) and actor.idle_time == 0.0, "poke restores grace")
	var after_poke := actor.annoyance as float
	actor.advance(2.99)
	check(actor.annoyance == after_poke, "no carried-over decay after a successful poke")

func check_scheduler(actor) -> void:
	var expected := [[100,0,0,0,0,0,0], [20,40,40,0,0,0,0], [25,15,15,25,20,0,0],
		[20,0,15,20,20,25,0], [80,0,0,0,0,0,20]]
	reset(actor)
	for stage in range(expected.size()):
		var counts := [0,0,0,0,0,0,0]
		for roll in range(100):
			counts[actor._idle_choice(stage, roll)] += 1
		check(counts == expected[stage], "stage eligibility and weights %d" % stage)
	actor.last_special_idle = actor.SpecialIdle.HUMMING
	check(actor._idle_choice(actor.IdleStage.FALLING_ASLEEP, 20) == actor.SpecialIdle.NONE, "repeat weight goes to base")
	actor.last_special_idle = actor.SpecialIdle.SLEEP_TWITCH
	check(actor._idle_choice(actor.IdleStage.ASLEEP, 99) == actor.SpecialIdle.SLEEP_TWITCH, "Twitch can recur after its cooldown")

	for threshold in [3.0,9.0,12.0,18.0]:
		reset(actor)
		actor.advance(threshold - 0.001)
		var before: int = actor.idle_stage
		actor.advance(0.002)
		check(actor.idle_stage == before + 1, "base advances at %ss" % threshold)
	for start in [8.1, 10.8, 16.2]:
		reset(actor)
		IdleFixture.arm(actor, actor.SpecialIdle.HUMMING, start)
		actor.advance(start)
		var stage: int = actor.idle_stage
		var rng_state: int = actor.idle_rng.state
		actor.advance(2.69)
		check(actor.active_idle == actor.SpecialIdle.HUMMING and actor.idle_stage == stage and not actor.asleep, "Humming crosses a stage boundary")
		check(actor.idle_rng.state == rng_state, "active clip does not consume rolls")
		actor.advance(0.02)
		check(actor.active_idle == actor.SpecialIdle.NONE and actor.idle_stage == actor._stage_for(actor.idle_time), "handoff uses latest threshold")
		var delay: float = actor.next_idle_at - actor.idle_time
		check(delay >= (3.6 if actor.asleep else 0.9) and delay <= (5.4 if actor.asleep else 1.8), "completion uses the correct cooldown")
	reset(actor)
	IdleFixture.arm(actor, actor.SpecialIdle.STRETCH, 11.1)
	actor.advance(11.1)
	actor.advance(1.0)
	check(actor.active_idle == actor.SpecialIdle.STRETCH and actor.idle_stage == actor.IdleStage.SLEEPY, "Stretch finishes across 12s")
	actor.advance(8.0)
	check(actor.active_idle == actor.SpecialIdle.NONE and actor.asleep and actor.next_idle_at > actor.idle_time, "large step reaches sleep with no catch-up rolls")
	reset(actor)
	actor.idle_time = 17.9
	actor.jump_returning = true
	actor.jump_return_target = actor.anchor + Vector2(400.0, 0.0)
	actor.advance(0.2)
	check(not actor.asleep and actor.jump_returning, "JUMP return defers sleep")
	actor.advance(2.0)
	check(actor.asleep, "sleep starts when return ends")

func check_motion(actor, authored: bool) -> void:
	for clip in [actor.SpecialIdle.YAWN, actor.SpecialIdle.MICROSLEEP, actor.SpecialIdle.FIGHTING_SLEEP, actor.SpecialIdle.SLEEP_TWITCH]:
		reset(actor)
		var start := 12.3 if clip == actor.SpecialIdle.FIGHTING_SLEEP else 9.9
		if clip == actor.SpecialIdle.SLEEP_TWITCH:
			actor.advance(18.0)
			start = 22.5
		IdleFixture.arm(actor, clip, start)
		actor.advance(start - actor.idle_time)
		check(actor.active_idle == clip, "new clip starts via scheduler")
		actor.advance(0.74 if clip == actor.SpecialIdle.YAWN else 0.54 if clip != actor.SpecialIdle.SLEEP_TWITCH else 0.09)
		check(actor.contains_touch(actor.body_position + Vector2(0,-70)), "moving body remains touchable")
		if clip == actor.SpecialIdle.YAWN:
			check(actor.yawn_mouth.size() == 96 and actor.body_angle != 0.0, "Yawn has a filled mouth and peak shudder")
			check(is_equal_approx(actor.yawn_mouth[0].x, 29.0 * 0.85 * 0.9), "approved Yawn mouth width")
			check(is_equal_approx(actor.yawn_mouth[24].y - actor.yawn_mouth[72].y, 2.0 * 36.5 * 0.85 * 0.9), "approved Yawn mouth height at peak")
			if authored:
				check(actor.mouth.visible and actor.mouth.get_parent() == actor.breathing, "authored mouth shares body transform")
		if clip == actor.SpecialIdle.SLEEP_TWITCH:
			check(actor.asleep and is_equal_approx(actor.eye_open, 0.07), "Twitch keeps its closed eyes")
		var was_asleep: bool = actor.asleep
		var time: float = actor.idle_time
		actor._handle_player_touch(Vector2(2,2))
		check(actor.active_idle == clip and actor.idle_time == time, "miss leaves the current idle alone")
		check(actor.touch_at(actor.body_position + Vector2(0,-70)), "accepted poke interrupts")
		check(actor.active_idle == actor.SpecialIdle.NONE and actor.yawn_mouth.is_empty(), "interruption clears pose")
		check((actor.reaction == actor.Reaction.WAKE) == was_asleep, "only true sleep enters WAKE")
	reset(actor)
	IdleFixture.arm(actor, actor.SpecialIdle.FIGHTING_SLEEP, 16.2)
	actor.advance(16.2)
	actor.advance(1.81)
	check(not actor.asleep and actor.active_idle == actor.SpecialIdle.FIGHTING_SLEEP, "Fighting Sleep crosses threshold")
	actor.advance(0.63)
	check(actor.asleep and actor.active_idle == actor.SpecialIdle.NONE, "Fighting Sleep hands off to real sleep")

func run() -> void:
	for authored in [false, true]:
		var actor = Game.instantiate()
		actor.use_adobe_idle = authored
		root.add_child(actor)
		actor.set_process(false)
		actor.audio_manager.muted = true
		check_decay(actor)
		check_scheduler(actor)
		check_motion(actor, authored)
		actor.free()
	print("Stage 2 idle checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
