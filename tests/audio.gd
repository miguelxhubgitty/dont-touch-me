extends SceneTree
const Blob = preload("res://scripts/blob.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func reset(game) -> void:
	game.asleep = false
	game.idle_time = 0
	game.reaction = 0
	game.anchor = Vector2(360, 742.4)
	game._update_pose()
	game.audio_manager.cancel_reaction()
	game.audio_manager.tick(1.0)
	game.audio_manager.trace.clear()
	game.audio_manager.set_focused(true)
	game.audio_manager.muted = false

func run() -> void:
	root.size = Vector2i(720, 1280)
	var game = Blob.new()
	root.add_child(game)
	game.set_process(false)
	var audio = game.audio_manager
	audio.trace_enabled = true
	check(audio.players.size() == 3, "exactly three bounded players")
	check(audio.streams.size() == 1, "one shared placeholder loaded")
	check(audio.streams.values()[0] is AudioStreamWAV, "actual WAV decoded")
	check(absf(audio.streams.values()[0].get_length() - 1.99) < .01, "correct unchanged study loaded")
	var covered := {}
	# Exercise all configured cues, including optional ones, through real reactions.
	for pass_index in range(2):
		var defaults: Dictionary = {}
		for id in audio.events:
			defaults[id] = audio.events[id].enabled
			if pass_index == 1: audio.events[id].enabled = true
		for which in Blob.DURATIONS:
			reset(game)
			game.begin_reaction(which, Vector2(330, 680))
			check(not audio.trace.any(func(id): return id.ends_with(".contact")), "helper start is not contact")
			audio.contact(which)
			var prefix: String = audio.REACTIONS[which] + "."
			for frame in range(600):
				if game.reaction == 0: break
				game.advance(.01)
			check(game.reaction == 0, "reaction completes " + prefix)
			for id in audio.events:
				if not id.begins_with(prefix): continue
				var count: int = audio.trace.count(id)
				check(count == (1 if audio.events[id].enabled else 0), "cue exactly once or silent: " + id)
				if count > 0: covered[id] = true
			check(audio.slots.size() <= 3, "bounded overlap")
			game.advance(1)
			check(audio.slots.is_empty(), "all snippet caps stop playback")
		for id in defaults: audio.events[id].enabled = defaults[id]
	# Exact marker crossing checks, including duration independence and no repeats.
	for id in audio.events:
		var cue: Dictionary = audio.events[id]
		if cue.marker in ["contact", "sleep", "start"]: continue
		var which: int = audio.REACTIONS.find(id.get_slice(".", 0))
		reset(game)
		var enabled: bool = cue.enabled
		cue.enabled = true
		game.begin_reaction(which, Vector2(330, 680))
		var at: float = audio.marker_position(cue.marker)
		audio.tick(1) # Isolate marker accuracy from deliberately shared vocal cooldown.
		audio.advance_reaction(maxf(0, at - .0000001))
		check(not audio.trace.has(id), "not early: " + id)
		audio.advance_reaction(at)
		check(audio.trace.count(id) == 1, "at marker: " + id)
		audio.advance_reaction(at)
		check(audio.trace.count(id) == 1, "stationary time cannot repeat: " + id)
		cue.enabled = enabled
	# Misses and blocked cardboard produce no contact or disturbance.
	reset(game)
	check(not game.touch_at(Vector2(2, 2)), "miss rejected")
	check(audio.trace.is_empty(), "miss silent")
	game.begin_reaction(Blob.Reaction.BOX, Vector2(330, 680))
	game.advance(.8)
	audio.trace.clear()
	check(not game.touch_at(game.body_position + Vector2(0, -60)), "cardboard blocked")
	check(audio.trace.is_empty(), "cardboard silent")
	# Protected actions retain progress under accepted contact spam.
	for which in [Blob.Reaction.BOX, Blob.Reaction.RUN]:
		reset(game)
		game.begin_reaction(which, Vector2(330, 680))
		game.advance(.5)
		var before: float = game.elapsed
		var active: String = audio.active_reaction
		var point: Vector2 = game.body_position + (Vector2(28, -148) if which == Blob.Reaction.BOX else Vector2(0, -60))
		for tap in range(30): check(game.touch_at(point), "protected exposed hit accepted")
		check(game.elapsed == before and audio.active_reaction == active, "protected action not restarted")
		check(audio.trace.count(active + ".contact") == 1, "same-frame contacts throttled")
	# Interrupted/resized jumps never land later and stop existing sound immediately.
	for resize in [false, true]:
		reset(game)
		game.begin_reaction(Blob.Reaction.JUMP, Vector2(330, 680))
		audio.contact(Blob.Reaction.JUMP)
		game.advance(.3)
		if resize:
			game.last_size = Vector2.ZERO
			game._resize()
		else: game.begin_reaction(Blob.Reaction.BLINK, Vector2(330, 680))
		check(audio.slots.is_empty(), "interruption cancels playing clips")
		game.advance(2)
		check(not audio.trace.has("jump.land"), "no phantom landing")
	reset(game)
	game.advance(24)
	check(audio.trace.count("sleep.enter") == 1, "sleep entry once")
	game.advance(4)
	check(audio.trace.count("sleep.enter") == 1, "sleep idle silent")
	check(game.touch_at(game.body_position + Vector2(0, -60)), "wake hit accepted")
	check(audio.trace.has("wake.voice") and audio.trace.has("wake.contact"), "wake voice and own contact")
	# Actual player controls, caps, focus, mute and tree pause.
	reset(game)
	check(audio.play_event("blink.contact"), "play valid event")
	check(audio.players.contact.playing, "AudioStreamPlayer actually starts")
	check(not audio.play_event("blink.contact"), "contact spacing")
	audio.tick(.1)
	check(audio.play_event("side_eye.contact"), "next contact allowed at interval")
	check(audio.play_event("dont.voice"), "voice starts")
	check(not audio.play_event("stop.voice"), "vocal spacing")
	audio.muted = true
	check(audio.slots.is_empty() and not audio.players.voice.playing, "mute stops players")
	check(not audio.play_event("blink.contact"), "mute suppresses")
	audio.muted = false
	audio.tick(1)
	game.begin_reaction(Blob.Reaction.DONT, Vector2(330, 680))
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	game.advance(.5)
	check(audio.slots.is_empty(), "focus loss suppresses cues")
	game._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	game.set_process(false)
	game.advance(.01)
	check(audio.slots.is_empty(), "focus return does not replay consumed cues")
	audio.tick(1)
	audio.play_event("blink.contact")
	paused = true
	check(audio.slots.is_empty(), "tree pause stops sound")
	check(not audio.play_event("dont.voice"), "paused cue suppressed")
	paused = false
	check(audio.slots.is_empty(), "tree resume silent")
	# A large time jump keeps current cues, not an accumulated audio burst.
	reset(game)
	game.begin_reaction(Blob.Reaction.BOX, Vector2(330, 680))
	game.advance(2.6)
	check(not audio.trace.has("box.raise") and audio.trace.count("box.lower") == 1, "no stale raise on skipped phases")
	# Compare against the exact saved pre-audio source, not a reimplementation.
	var baseline_path := "res://builds/audio-playback-baseline/blob.gd"
	if FileAccess.file_exists(baseline_path):
		var baseline_script = load(baseline_path)
		var baseline = baseline_script.new()
		root.add_child(baseline)
		baseline.set_process(false)
		var revised = Blob.new()
		root.add_child(revised)
		revised.set_process(false)
		baseline.rng.seed = 8712
		revised.rng.seed = 8712
		for frame in range(3600):
			if frame % 13 == 0:
				var point: Vector2 = baseline.body_position + Vector2(0, -60)
				check(baseline.touch_at(point) == revised.touch_at(point), "identical hit acceptance")
			baseline.advance(.016)
			revised.advance(.016)
			for property in ["annoyance", "reaction", "asleep", "idle_time", "elapsed", "body_position", "body_scale", "eye_open", "gaze", "rng"]:
				if property == "rng": check(baseline.rng.state == revised.rng.state, "identical RNG")
				else: check(baseline.get(property) == revised.get(property), "identical gameplay: " + property)
		baseline.queue_free()
		revised.queue_free()
	else:
		print("Baseline comparison skipped: optional local pre-change snapshot is absent")
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.3).timeout # Let the mixer retire stopped playback handles.
	print("Audio checks: %d; failures: %d; mapped events exercised: %d" % [checks, failures, covered.size()])
	quit(1 if failures else 0)
