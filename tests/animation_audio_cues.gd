extends SceneTree

const Game = preload("res://main.tscn")
const IdleFixture = preload("res://tests/idle_fixture.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func reset(game) -> void:
	game.audio_manager.cancel_reaction()
	game.audio_manager.tick(1.0)
	game.audio_manager.muted = false
	game.audio_manager.set_focused(true)
	game.audio_manager.trace.clear()
	game.active_idle = game.SpecialIdle.NONE
	game._reset_special_idle()
	game.next_idle_at = INF
	game.idle_time = 0.0
	game.asleep = false
	game.jump_returning = false
	game.reaction = game.Reaction.NONE
	game.elapsed = 0.0
	game.annoyance = 0.0
	game._update_pose()

func schedule_idle(game, which: int) -> void:
	game.idle_time = maxf(game.idle_time, 4.5)
	game.idle_stage = game._stage_for(game.idle_time)
	IdleFixture.arm(game, which, game.idle_time + 0.09)

func check_idles(game) -> void:
	var audio = game.audio_manager
	for idle in game.IDLE_VOICE_CUES:
		reset(game)
		var event: String = game.IDLE_VOICE_CUES[idle]
		schedule_idle(game, idle)
		game.advance(0.08)
		check(not audio.trace.has(event), "selection alone is silent " + event)
		game.advance(0.011)
		check(game.active_idle == idle and audio.trace.count(event) == 1, "cue starts with visual idle " + event)
		check(audio.players.voice.bus == &"CharacterVoice" and audio.players.voice.pitch_scale == 1.0, "idle bus and original pitch")
		var voice: AudioStreamPlayer = audio.players.voice
		game.advance(0.09)
		game._handle_player_touch(Vector2(2, 2))
		check(audio.trace.count(event) == 1 and audio.slots.voice.id == event and voice.playing, "miss leaves active idle voice alone")
		check(audio.trace.has("user.tap_miss"), "miss still supplies existing feedback")
		check(game.touch_at(game.body_position + Vector2(0, -81)), "accepted poke interrupts the idle")
		check(audio.fade_players.voice == voice and audio.fades.has("voice"), "accepted poke uses existing voice fade")
		game.advance(0.034)
		check(voice.playing, "35 ms fade continues before its boundary")
		game.advance(0.002)
		check(not voice.playing and not audio.fades.has("voice"), "voice fade ends without replay")

	reset(game)
	check(audio.play_event("dont.voice"), "existing voice starts")
	var old_voice: AudioStreamPlayer = audio.players.voice
	schedule_idle(game, game.SpecialIdle.HUMMING)
	game.advance(0.09)
	check(game.active_idle == game.SpecialIdle.HUMMING and not audio.trace.has("idle.humming"), "busy voice yields a silent idle")
	check(audio.slots.voice.id == "dont.voice" and old_voice.playing, "idle never evicts existing voice")
	game.jump_returning = true
	game._update_special_idle()
	check(audio.slots.voice.id == "dont.voice" and not audio.fades.has("voice"), "idle cleanup never fades another cue")
	game.advance(0.54)
	check(not audio.trace.has("idle.humming"), "skipped busy-slot cue is not replayed")

	reset(game)
	schedule_idle(game, game.SpecialIdle.STRETCH)
	game.advance(0.09)
	game.jump_returning = true
	game._update_special_idle()
	check(audio.fades.has("voice") and not audio.slots.has("voice"), "other idle interruption fades its owned slot")
	game.advance(0.036)
	check(not audio.fade_players.voice.playing, "event-scoped fade stops playback")

	reset(game)
	game.idle_time = 16.5
	schedule_idle(game, game.SpecialIdle.HUMMING)
	game.advance(0.09)
	check(game.active_idle == game.SpecialIdle.HUMMING and audio.trace.count("idle.humming") == 1, "late Humming starts with its cue")
	game.advance(1.5)
	check(not game.asleep and audio.slots.voice.id == "idle.humming", "18-second threshold leaves Humming audio untouched")
	game.advance(1.21)
	check(game.asleep and game.active_idle == game.SpecialIdle.NONE and audio.trace.count("sleep.enter") == 1, "sleep cue fires once at the actual handoff")

func check_reactions(game) -> void:
	var audio = game.audio_manager
	var poke := Vector2(330, 680)
	reset(game)
	for click in range(6):
		audio.register_click()
	game.begin_reaction(game.Reaction.RECOIL, poke)
	check(audio.trace.count("recoil.voice") == 1, "Recoil starts once at activation")
	check(audio.players.voice.bus == &"CharacterVoice" and audio.players.voice.pitch_scale == 1.0, "Recoil bus and original pitch")
	check(is_equal_approx(audio.players.voice.volume_db, -12.0), "Recoil uses the six-click attenuation")
	game.advance(0.299)
	game.begin_reaction(game.Reaction.RECOIL, poke)
	game.advance(0.001)
	check(audio.trace.count("recoil.voice") == 1, "voice cooldown suppresses and consumes a rapid restart")
	game.advance(0.001)
	game.begin_reaction(game.Reaction.RECOIL, poke)
	check(audio.trace.count("recoil.voice") == 2, "fresh activation is permitted after the cooldown")

	reset(game)
	for click in range(6):
		audio.register_click()
	game.begin_reaction(game.Reaction.PUFFER_HUFF, poke)
	check(audio.trace.count("puffer_huff.action") == 1 and game.elapsed == 0.0, "Puffer WAV starts with the contraction")
	check(audio.players.action.bus == &"CharacterSFX" and audio.players.action.pitch_scale == 1.0, "Puffer bus and original pitch")
	check(is_equal_approx(audio.players.action.volume_db, -15.0), "Puffer uses cue gain and click attenuation")
	var stream: AudioStreamWAV = audio.players.action.stream
	var pcm_matches := stream.mix_rate == 48000 and stream.format == AudioStreamWAV.FORMAT_16_BITS and not stream.stereo and stream.data.size() >= 26880
	check(pcm_matches, "Puffer PCM retains timing format")
	if not pcm_matches:
		return
	var samples := stream.data
	var quiet := true
	for frame in range(12096, 12960):
		quiet = quiet and samples.decode_s16(frame * 2) == 0
	var spike_peak := 0
	for frame in range(12960, 13440):
		spike_peak = maxi(spike_peak, absi(samples.decode_s16(frame * 2)))
	check(quiet and spike_peak > 100, "embedded puff begins at 0.270 s after the silent gap")
	game.advance(0.269)
	check(game.spike_extension < 1.0, "visual inflation is still finishing before the embedded puff")
	game.advance(0.0011)
	check(is_equal_approx(game.spike_extension, 1.0) and audio.trace.count("puffer_huff.action") == 1, "inflation reaches the snap without a duplicate cue")
	for repeat in range(9):
		game.begin_reaction(game.Reaction.PUFFER_HUFF, poke)
		check(audio.fades.size() == 1 and audio.slots.action.id == "puffer_huff.action", "rapid puffs keep one current cue and one fade")
	game.advance(0.036)
	check(audio.fades.is_empty(), "rapid restart fade is bounded")
	game.advance(1.35)
	check(not audio.slots.has("action") and not audio.players.action.playing, "Puffer cue ends with its animation")

func check_suppression(game) -> void:
	var audio = game.audio_manager
	for guard in ["mute", "focus", "pause"]:
		reset(game)
		match guard:
			"mute": audio.muted = true
			"focus": audio.set_focused(false)
			"pause": paused = true
		schedule_idle(game, game.SpecialIdle.HUMMING)
		game.advance(0.09)
		check(audio.trace.is_empty(), "idle activation is suppressed by " + guard)
		game.begin_reaction(game.Reaction.PUFFER_HUFF, Vector2(330, 680))
		audio.muted = false
		audio.set_focused(true)
		paused = false
		game.advance(0.30)
		check(audio.trace.is_empty(), "suppressed cues never replay after " + guard)

	reset(game)
	schedule_idle(game, game.SpecialIdle.HUMMING)
	game.advance(0.09)
	audio.muted = true
	check(audio.slots.is_empty() and audio.fades.is_empty(), "mute stops live and fading cues")
	audio.muted = false
	game.advance(0.09)
	check(audio.trace.count("idle.humming") == 1 and not audio.players.voice.playing, "unmute does not restart an active idle's cue")
	reset(game)
	schedule_idle(game, game.SpecialIdle.STRETCH)
	game.advance(0.09)
	game.last_size = Vector2.ZERO
	game._resize()
	check(audio.slots.is_empty() and audio.fades.is_empty(), "resize stops audio through existing path")

func run() -> void:
	for authored in [true, false]:
		var game = Game.instantiate()
		game.use_adobe_idle = authored
		root.add_child(game)
		game.set_process(false)
		game.audio_manager.trace_enabled = true
		check_idles(game)
		check_reactions(game)
		check_suppression(game)
		game.audio_manager.muted = true
		game.queue_free()
		await process_frame
	print("Animation audio cue checks: %d; failures: %d" % [checks, failures])
	quit(0 if failures == 0 else 1)
