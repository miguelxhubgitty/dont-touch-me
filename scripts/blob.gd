extends Node2D
## One clock owns every pose. No asynchronous reactions or overlapping tweens.
const AudioManager = preload("res://scripts/audio_manager.gd")

enum Reaction { NONE, BLINK, SIDE_EYE, SQUISH, IRRITATED, DONT, SERIOUSLY,
	SLIDE, JUMP, SHAKE, FLATTEN, TURN, STOP, SIGN, BOX, RUN, WAKE, RECOIL, PUFFER_HUFF }

const INK := Color("202124")
const WHITE := Color("fffdf8")
const MUTED := Color("aaa395")
const PAPER := Color("f6f2e9")
const DURATIONS := {
	Reaction.BLINK: 0.65, Reaction.SIDE_EYE: 1.15, Reaction.SQUISH: 0.85,
	Reaction.IRRITATED: 1.2, Reaction.DONT: 1.25, Reaction.SERIOUSLY: 1.5,
	Reaction.SLIDE: 0.9, Reaction.JUMP: 1.05, Reaction.SHAKE: 1.05,
	Reaction.FLATTEN: 1.65, Reaction.TURN: 1.8, Reaction.STOP: 1.25,
	Reaction.SIGN: 2.0, Reaction.BOX: 2.7, Reaction.RUN: 4.1, Reaction.WAKE: 1.65, Reaction.RECOIL: 0.9,
	Reaction.PUFFER_HUFF: 1.35,
}
# Body deformation in these lasts to the final frame, so touches never cut them short.
const PHYSICAL_MOVEMENT := [Reaction.SLIDE, Reaction.JUMP, Reaction.RECOIL, Reaction.WAKE]
const STAGE_MARGIN := 190.0
const POOLS := [
	[Reaction.BLINK, Reaction.SIDE_EYE, Reaction.SQUISH, Reaction.RECOIL],
	[Reaction.IRRITATED, Reaction.DONT, Reaction.SERIOUSLY, Reaction.SLIDE, Reaction.PUFFER_HUFF],
	[Reaction.JUMP, Reaction.SHAKE, Reaction.FLATTEN, Reaction.TURN, Reaction.STOP, Reaction.SIGN],
	[Reaction.STOP, Reaction.SIGN, Reaction.BOX, Reaction.RUN],
]
const SLEEP_AFTER := 18.0
const POKE_STREAK_SECONDS := 1.8
const POKE_STREAK_MULTIPLIERS := [1.0, 1.0, 1.0, 1.0, 0.8, 0.6, 0.4, 0.2, 0.0]
const STRETCH_DURATION := 1.8
const STRETCH_SCALE := Vector2(0.72, 1.45)
const HUMMING_BEAT := 0.9
const HUMMING_DURATION := 3.0 * HUMMING_BEAT
const HUMMING_SQUINT_EXIT := 0.09

enum SpecialIdle { NONE, STRETCH, HUMMING, YAWN, MICROSLEEP, FIGHTING_SLEEP, SLEEP_TWITCH }
enum IdleStage { SETTLING, AWAKE, SLEEPY, FALLING_ASLEEP, ASLEEP }
const IDLE_DURATIONS := {
	SpecialIdle.STRETCH: STRETCH_DURATION, SpecialIdle.HUMMING: HUMMING_DURATION,
	SpecialIdle.YAWN: 1.98, SpecialIdle.MICROSLEEP: 1.35,
	SpecialIdle.FIGHTING_SLEEP: 2.43, SpecialIdle.SLEEP_TWITCH: 0.54,
}
# Columns follow SpecialIdle, with NONE continuing the base pose.
const IDLE_WEIGHTS := [
	[100, 0, 0, 0, 0, 0, 0],
	[20, 40, 40, 0, 0, 0, 0],
	[25, 15, 15, 25, 20, 0, 0],
	[20, 0, 15, 20, 20, 25, 0],
	[80, 0, 0, 0, 0, 0, 20],
]
const IDLE_HANDOFF_SECONDS := 0.27
const YAWN_PINK := Color("D98E9A")
const STARTLED_OPEN := 0.036
const STARTLED_SHUT := 0.072
const STARTLED_END := 0.18
const STARTLED_WIDE := 1.35
const IDLE_VOICE_CUES := {SpecialIdle.STRETCH: "idle.stretch", SpecialIdle.HUMMING: "idle.humming"}
const FREE_JUMP_FLIGHT := .85
const FREE_JUMP_TRAVEL := 230.0
const JUMP_RETURN_SPEED := FREE_JUMP_TRAVEL / FREE_JUMP_FLIGHT
@export var free_jump_enabled := false
var recoil_travel := 0.0
var jump_returning := false
var jump_return_target := Vector2.ZERO

var rng := RandomNumberGenerator.new()
var idle_rng := RandomNumberGenerator.new()
var next_idle_at := 0.0
var active_idle := SpecialIdle.NONE
var last_special_idle := SpecialIdle.NONE
var idle_stage := IdleStage.SETTLING
var special_idle_started := 0.0
var idle_handoff_started := -1.0
var idle_handoff: Dictionary = {}
var idle_scale_offset := Vector2.ZERO
var idle_scale_factor := Vector2.ONE
var yawn_mouth := PackedVector2Array()
var startled_mouth := PackedVector2Array()
var startled_entry_eye := 0.0
var annoyance := 0.0
var successful_poke_streak := 0
var poke_streak_started_at := 0.0
var idle_time := 0.0
var asleep := false
var reaction: int = Reaction.NONE
var last_reaction: int = Reaction.NONE
var elapsed := 0.0
var clock := 0.0
var anchor := Vector2.ZERO
var origin := Vector2.ZERO
var destination := Vector2.ZERO
var body_position := Vector2.ZERO
var body_scale := Vector2.ONE
var body_angle := 0.0
var eye_open := 1.0
var humming_squint := 0.0
var gaze := Vector2.ZERO
var idle_gaze := Vector2.ZERO
var gaze_timer := 1.0
var blink_timer := 2.5
var blink_remaining := 0.0
var spike_extension := 0.0
var turn_amount := 0.0
var box_amount := 0.0
var sign_amount := 0.0
var direction := 1.0
var bubble := ""
var bubble_alpha := 0.0
var touch_flash := 0.0
var intro_alpha := 1.0
var last_size := Vector2.ZERO
var font: Font
var audio_manager: Node

func _ready() -> void:
	free_jump_enabled = free_jump_enabled or "--free-jump" in OS.get_cmdline_user_args()
	rng.randomize()
	font = ThemeDB.fallback_font
	_resize()
	audio_manager = AudioManager.new()
	audio_manager.name = "BlobAudio"
	add_child(audio_manager)
	_reset_special_idle()
	var sound_button := get_node_or_null("SoundHUD/SoundButton")
	if sound_button != null:
		sound_button.initialize(audio_manager)
	var volume_button := get_node_or_null("SoundHUD/VolumeButton")
	if volume_button != null:
		volume_button.initialize()
	# On the initial launch only; respected by the saved mute preference.
	audio_manager.play_event("user.game_start")

func _resize() -> void:
	var size := get_viewport_rect().size
	if size == last_size:
		return
	last_size = size
	if audio_manager != null:
		audio_manager.cancel_reaction()
	# A resize cancels the current motion cleanly, including offscreen escape.
	jump_returning = false
	anchor = Vector2(size.x * 0.5, size.y * 0.58)
	origin = anchor
	destination = anchor
	reaction = Reaction.NONE
	if active_idle != SpecialIdle.NONE:
		_interrupt_special_idle()
	idle_handoff.clear()
	_update_pose()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		set_process(false)
		if audio_manager != null:
			audio_manager.set_focused(false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		set_process(true)
		if audio_manager != null:
			audio_manager.set_focused(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_player_touch(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_handle_player_touch(event.position)

func _handle_player_touch(point: Vector2) -> void:
	if touch_at(point):
		return
	var box_hit := _box_hit(point)
	if box_hit == BoxHit.BLOCKED:
		annoyance = clampf(annoyance - rng.randf_range(1.8, 3.6), 0.0, 100.0)
		return
	annoyance = clampf(annoyance - rng.randf_range(0.9, 1.8), 0.0, 100.0)
	if box_hit == BoxHit.EXPOSED and audio_manager != null:
		audio_manager.register_click()
		audio_manager.play_event("user.tap_miss", audio_manager.click_attenuation_db())

func _process(delta: float) -> void:
	_resize()
	advance(minf(delta, 0.1))

func advance(delta: float) -> void:
	var free_contact := reaction == Reaction.JUMP and _free_jump_enabled() and elapsed < FREE_JUMP_FLIGHT and elapsed+delta >= FREE_JUMP_FLIGHT
	if free_contact and audio_manager != null:
		audio_manager.fired["jump.land"] = true
	var return_delta := delta if jump_returning else 0.0
	if audio_manager != null:
		audio_manager.tick(delta)
	humming_squint = move_toward(humming_squint, 0.0, delta / HUMMING_SQUINT_EXIT)
	clock += delta
	var previous_idle := idle_time
	idle_time += delta
	intro_alpha = move_toward(intro_alpha, 0.0, delta * 0.1 if idle_time > 5.0 else 0.0)
	touch_flash = maxf(0.0, touch_flash - delta * 5.0)
	annoyance = clampf(annoyance - (_decay_at(idle_time) - _decay_at(previous_idle)), 0.0, 100.0)
	if reaction != Reaction.NONE:
		elapsed += delta
		if audio_manager != null:
			audio_manager.advance_reaction(elapsed / float(DURATIONS[reaction]), absf(destination.x - origin.x) > 0.001)
		if elapsed >= float(DURATIONS[reaction]):
			if reaction == Reaction.JUMP and _free_jump_enabled() and (destination.x < 0 or destination.x > last_size.x):
				jump_returning = true
				jump_return_target = Vector2(last_size.x*.5,destination.y)
				return_delta = maxf(0,elapsed-float(DURATIONS[reaction]))
			anchor = destination
			reaction = Reaction.NONE
			elapsed = 0.0
	if jump_returning:
		anchor.x = move_toward(anchor.x,jump_return_target.x,JUMP_RETURN_SPEED*return_delta)
		destination = anchor
		if anchor.x == jump_return_target.x: jump_returning = false
	_update_special_idle()
	blink_timer -= delta
	blink_remaining = maxf(0.0, blink_remaining - delta)
	if blink_timer <= 0.0:
		blink_remaining = 0.17
		blink_timer = rng.randf_range(2.0, 5.0)
	gaze_timer -= delta
	if gaze_timer <= 0.0:
		idle_gaze = Vector2(rng.randf_range(-8, 8), rng.randf_range(-3, 3))
		gaze_timer = rng.randf_range(1.8, 4.0)
	_update_pose()
	if free_contact and audio_manager != null:
		audio_manager.play_event("jump.land", audio_manager.reaction_attenuation_db)
	queue_redraw()

func _decay_at(time: float) -> float:
	var after_grace := maxf(0.0, time - 3.0)
	return 0.45 * after_grace * after_grace

func _stage_for(time: float) -> IdleStage:
	if time >= SLEEP_AFTER: return IdleStage.ASLEEP
	if time >= 12.0: return IdleStage.FALLING_ASLEEP
	if time >= 9.0: return IdleStage.SLEEPY
	if time >= 3.0: return IdleStage.AWAKE
	return IdleStage.SETTLING

func _reset_special_idle() -> void:
	active_idle = SpecialIdle.NONE
	last_special_idle = SpecialIdle.NONE
	idle_stage = IdleStage.SETTLING
	next_idle_at = 4.5
	idle_handoff.clear()

func _schedule_next_idle(stage: IdleStage) -> void:
	var cooldown := idle_rng.randf_range(3.6, 5.4) if stage == IdleStage.ASLEEP else idle_rng.randf_range(0.9, 1.8)
	next_idle_at = idle_time + cooldown

func _interrupt_special_idle() -> void:
	if audio_manager != null and IDLE_VOICE_CUES.has(active_idle):
		audio_manager.fade_event(IDLE_VOICE_CUES[active_idle])
	active_idle = SpecialIdle.NONE
	_schedule_next_idle(idle_stage)

func _idle_choice(stage: IdleStage, roll: int) -> SpecialIdle:
	var weights: Array = IDLE_WEIGHTS[stage]
	for choice in range(weights.size()):
		roll -= int(weights[choice])
		if roll < 0:
			if stage != IdleStage.ASLEEP and choice == last_special_idle:
				return SpecialIdle.NONE
			return choice as SpecialIdle
	return SpecialIdle.NONE

func _displayed_idle_scale() -> Vector2:
	return _fallback_body_scale()

func _fallback_body_scale() -> Vector2:
	return body_scale

func _idle_handoff_weight() -> float:
	return 0.0 if idle_handoff.is_empty() else 1.0 - _ease((idle_time - idle_handoff_started) / IDLE_HANDOFF_SECONDS)

func _update_special_idle() -> void:
	if reaction != Reaction.NONE or jump_returning:
		if active_idle != SpecialIdle.NONE:
			_interrupt_special_idle()
		return
	var latest := _stage_for(idle_time)
	# A fixture or caller can restore an already sleeping pose.
	if asleep:
		latest = IdleStage.ASLEEP
	if active_idle != SpecialIdle.NONE:
		if idle_time < special_idle_started + float(IDLE_DURATIONS[active_idle]):
			return
		_update_pose() # Sample the terminal pose before the old stage is released.
		active_idle = SpecialIdle.NONE
		if latest != IdleStage.ASLEEP or idle_stage == IdleStage.ASLEEP:
			_schedule_next_idle(latest)
	elif latest != idle_stage and latest != IdleStage.AWAKE:
		_update_pose() # Sample the outgoing base pose with current head/body transforms.
	if latest != idle_stage:
		# Settling and awake share the same resting pose and breathing phase.
		if latest != IdleStage.AWAKE:
			idle_handoff = {"scale": body_scale, "display_scale": _displayed_idle_scale(), "position": body_position,
				"angle": body_angle, "eye": eye_open, "gaze": gaze}
			idle_handoff_started = idle_time
		idle_stage = latest
		if latest == IdleStage.ASLEEP:
			if not asleep and audio_manager != null:
				audio_manager.play_event("sleep.enter")
			asleep = true
			_schedule_next_idle(latest)
	if latest == IdleStage.SETTLING or idle_time < next_idle_at:
		return
	var choice := _idle_choice(latest, idle_rng.randi_range(0, 99))
	if choice == SpecialIdle.NONE:
		_schedule_next_idle(latest)
		return
	active_idle = choice
	last_special_idle = choice
	special_idle_started = idle_time
	if audio_manager != null and IDLE_VOICE_CUES.has(choice):
		audio_manager.play_idle_voice(IDLE_VOICE_CUES[choice])

func _stretch_strength() -> float:
	if active_idle != SpecialIdle.STRETCH:
		return 0.0
	var phase := idle_time - special_idle_started
	return _ease(phase / 0.72) * _ease((STRETCH_DURATION - phase) / 0.81)

func _free_jump_enabled() -> bool:
	return free_jump_enabled

func tier() -> int:
	if annoyance <= 20.0: return 0
	if annoyance <= 50.0: return 1
	if annoyance <= 80.0: return 2
	return 3

func choose_reaction() -> int:
	var choices: Array = POOLS[tier()].duplicate()
	choices.erase(last_reaction)
	return int(choices[rng.randi_range(0, choices.size() - 1)])

enum BoxHit { EXPOSED, BLOCKED, PEEK }

func _box_position() -> Vector2:
	return body_position + Vector2(0, 190 * (1.0 - box_amount))

func _box_hit(point: Vector2) -> BoxHit:
	if box_amount <= 0:
		return BoxHit.EXPOSED
	var box_pos := _box_position()
	if box_amount > 0.85:
		for side in [-1.0, 1.0]:
			var eye_local := (point - box_pos - Vector2(side * 28, -148)) / Vector2(10, 8)
			if eye_local.length_squared() <= 1.0:
				return BoxHit.PEEK
	if Rect2(box_pos + Vector2(-143, -128), Vector2(286, 139)).has_point(point):
		return BoxHit.BLOCKED
	for flap in _box_flaps(box_pos):
		if Geometry2D.is_point_in_polygon(point, flap):
			return BoxHit.BLOCKED
	return BoxHit.EXPOSED

func contains_touch(point: Vector2) -> bool:
	var prop_hit := _box_hit(point)
	if prop_hit != BoxHit.EXPOSED:
		return prop_hit == BoxHit.PEEK
	var local := (point - body_position).rotated(-body_angle) / _fallback_body_scale()
	var polygon := _silhouette()
	return Geometry2D.is_point_in_polygon(local, polygon)

func touch_at(point: Vector2) -> bool:
	if not contains_touch(point):
		return false
	if audio_manager != null:
		audio_manager.register_click()
	if successful_poke_streak == 0 or clock >= poke_streak_started_at + POKE_STREAK_SECONDS or idle_time >= POKE_STREAK_SECONDS:
		successful_poke_streak = 0
		poke_streak_started_at = clock
	successful_poke_streak = mini(successful_poke_streak + 1, POKE_STREAK_MULTIPLIERS.size())
	var multiplier: float = POKE_STREAK_MULTIPLIERS[successful_poke_streak - 1]
	intro_alpha = 0.0
	annoyance = clampf(annoyance + rng.randf_range(1.8, 3.6) * multiplier, 0.0, 100.0)
	touch_flash = 1.0
	if asleep:
		begin_reaction(Reaction.WAKE, point)
	elif not reaction_locked():
		# Escapes and physical movement finish on schedule even under frantic tapping.
		begin_reaction(choose_reaction(), point)
	idle_time = 0.0
	_reset_special_idle()
	if audio_manager != null:
		audio_manager.contact(reaction)
	return true

## Whether a touch keeps the current reaction instead of starting a new one.
func reaction_locked() -> bool:
	return jump_returning or reaction == Reaction.RUN or reaction == Reaction.BOX or reaction in PHYSICAL_MOVEMENT

## Clamps a destination into the stage band, which collapses to the centre on narrow screens.
func _stage_x(x: float) -> float:
	var margin := minf(STAGE_MARGIN, last_size.x * 0.5)
	return clampf(x, margin, last_size.x - margin)

func begin_reaction(which: int, touch: Vector2) -> void:
	startled_mouth.clear()
	if active_idle == SpecialIdle.YAWN and which != Reaction.WAKE:
		startled_mouth = yawn_mouth.duplicate()
		startled_entry_eye = _displayed_yawn_aperture()
	active_idle = SpecialIdle.NONE
	idle_handoff.clear()
	if which == Reaction.WAKE:
		asleep = false
	jump_returning = false
	# Start where the body is. Only destinations are kept on stage.
	origin = Vector2(body_position.x, anchor.y)
	anchor = origin
	destination = origin
	elapsed = 0.0
	reaction = which
	last_reaction = which
	direction = 1.0 if touch.x <= origin.x else -1.0
	if which == Reaction.RECOIL:
		var edge := last_size.x - 144.0 if direction > 0.0 else 144.0
		recoil_travel = clampf((edge - origin.x) * direction, 0.0, 45.0)
	if which == Reaction.JUMP and _free_jump_enabled():
		destination.x = origin.x+direction*FREE_JUMP_TRAVEL
	elif which == Reaction.SLIDE or which == Reaction.JUMP:
		destination.x = _stage_x(origin.x + direction * 155.0)
		if absf(destination.x - origin.x) < 35.0:
			direction *= -1.0
			destination.x = _stage_x(origin.x + direction * 155.0)
		if destination.x != origin.x:
			# From outside the band the clamp can reverse travel; face the way it goes.
			direction = signf(destination.x - origin.x)
	if which == Reaction.RUN:
		direction = -1.0 if origin.x < last_size.x * 0.5 else 1.0
		destination = Vector2(last_size.x * 0.5, anchor.y)
	_update_pose()
	if audio_manager != null:
		audio_manager.begin_reaction(which)

func _ease(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _displayed_yawn_aperture() -> float:
	return maxf(2.0 / 21.0, eye_open)

func _startled_active() -> bool:
	return reaction != Reaction.NONE and elapsed < STARTLED_END and not startled_mouth.is_empty()

func _startled_aperture(target: float) -> float:
	if elapsed < STARTLED_OPEN:
		return lerpf(startled_entry_eye, STARTLED_WIDE, _ease(elapsed / STARTLED_OPEN))
	if elapsed < STARTLED_SHUT:
		return STARTLED_WIDE * (1.0 - _ease((elapsed - STARTLED_OPEN) / (STARTLED_SHUT - STARTLED_OPEN)))
	return target * _ease((elapsed - STARTLED_SHUT) / (STARTLED_END - STARTLED_SHUT))

func _sample_idle_keys(keys: Array, time: float, rest_eye: float) -> Vector4:
	for i in range(1, keys.size()):
		if time <= float(keys[i][0]):
			var a: Array = keys[i - 1]
			var b: Array = keys[i]
			var first := Vector4(rest_eye if a[1] < 0.0 else a[1], a[2], a[3], a[4])
			var last := Vector4(rest_eye if b[1] < 0.0 else b[1], b[2], b[3], b[4])
			return first.lerp(last, _ease((time - float(a[0])) / (float(b[0]) - float(a[0]))))
	return Vector4(rest_eye, 0.0, 0.0, 0.0)

func _set_yawn_mouth(opening: float) -> void:
	const HALF_WIDTH := 29.0 * 0.85 * 0.9
	const CIRCLE_HANDLE := 0.55228475
	var height := lerpf(0.8, 36.5 * 0.85, opening) * 0.9
	var inset := HALF_WIDTH * 0.24 * (1.0 - opening)
	var tangent := height * lerpf(0.38, CIRCLE_HANDLE, opening)
	var corner := Vector2(HALF_WIDTH, 0.0)
	var peak := Vector2(0.0, height)
	var quarter := PackedVector2Array()
	for i in range(25):
		quarter.append(corner.bezier_interpolate(Vector2(HALF_WIDTH - inset, tangent),
			Vector2(HALF_WIDTH * CIRCLE_HANDLE, height), peak, i / 24.0))
	for i in range(24): yawn_mouth.append(quarter[i] + Vector2(0, -66))
	for i in range(24, 0, -1): yawn_mouth.append(quarter[i] * Vector2(-1, 1) + Vector2(0, -66))
	for i in range(24): yawn_mouth.append(-quarter[i] + Vector2(0, -66))
	for i in range(24, 0, -1): yawn_mouth.append(quarter[i] * Vector2(1, -1) + Vector2(0, -66))

func _apply_stage_idle_pose() -> void:
	if asleep:
		gaze = Vector2.ZERO
	elif idle_stage == IdleStage.SLEEPY:
		eye_open = minf(eye_open, 0.64)
		gaze *= 0.55
	elif idle_stage == IdleStage.FALLING_ASLEEP:
		eye_open = minf(eye_open, 0.42)
		gaze *= 0.25
		idle_scale_offset += Vector2(0.009, -0.018)

	if active_idle == SpecialIdle.NONE:
		return
	var duration := float(IDLE_DURATIONS[active_idle])
	var time := clampf(idle_time - special_idle_started, 0.0, duration)
	var rest_eye := 0.42 if idle_stage == IdleStage.FALLING_ASLEEP else 0.64
	var pose := Vector4(rest_eye, 0.0, 0.0, 0.0)
	match active_idle:
		SpecialIdle.YAWN:
			pose = _sample_idle_keys([[0.,-1.,0.,0.,0.],[.27,.50,.025,0.,0.],
				[.63,.10,.105,0.,1.],[1.17,.10,.105,0.,1.],[1.44,.16,.045,0.,.42],
				[1.71,.13,-.025,0.,0.],[duration,-1.,0.,0.,0.]], time, rest_eye)
			_set_yawn_mouth(pose.w)
			if time >= 0.63 and time < 1.13:
				var phase := (time - 0.63) / 0.5
				var weight := pow(sin(PI * phase), 2.0)
				var beat := sin(TAU * 5.0 * phase) * weight
				var flex := cos(TAU * 5.0 * phase) * weight
				body_position.x += 3.4 * beat
				body_angle += 0.018 * beat
				idle_scale_factor = Vector2(1.0 + 0.018 * flex, 1.0 - 0.026 * flex)
		SpecialIdle.MICROSLEEP:
			pose = _sample_idle_keys([[0.,-1.,0.,0.,0.],[.27,.26,-.025,2.,.02],
				[.54,.095,-.085,7.,.07],[.81,.095,-.085,7.,.07],[.90,1.08,.035,-4.,-.023],
				[1.08,.78,.004,0.,.01],[duration,-1.,0.,0.,0.]], time, rest_eye)
		SpecialIdle.FIGHTING_SLEEP:
			var finish := 0.095 if special_idle_started + duration >= SLEEP_AFTER else rest_eye
			pose = _sample_idle_keys([[0.,-1.,0.,0.,0.],[.45,.18,-.045,3.,-.04],
				[.72,.095,-.09,6.,-.09],[.81,.96,.023,-3.,.020],[1.08,.68,0.,0.,0.],
				[1.44,.18,-.049,4.,.043],[1.71,.095,-.09,7.,.085],[1.80,.78,.018,-2.,-.01],
				[2.07,.30,-.018,1.,0.],[duration,finish,0.,0.,0.]], time, rest_eye)
		SpecialIdle.SLEEP_TWITCH:
			pose = _sample_idle_keys([[0.,.07,0.,0.,0.],[.09,.07,.037,-2.,.031],
				[.18,.07,-.017,1.,-.016],[.27,.07,.008,0.,.008],[duration,.07,0.,0.,0.]], time, 0.07)
			body_position.x += pose.z * 0.8
		_:
			return
	eye_open = pose.x
	if active_idle != SpecialIdle.YAWN:
		body_angle += pose.w
	body_position.y += pose.z
	idle_scale_offset += Vector2(-pose.y * 0.58, pose.y)

func _update_pose() -> void:
	body_position = anchor
	var breath := sin(clock * (1.6 if asleep else 2.3))
	body_scale = Vector2(1.0 + breath * 0.018, 1.0 - breath * 0.022)
	body_angle = 0.0
	eye_open = 0.07 if asleep else (0.08 if blink_remaining > 0.0 else 1.0)
	gaze = idle_gaze
	spike_extension = 0.0
	turn_amount = 0.0
	sign_amount = 0.0
	box_amount = 0.0
	bubble = ""
	bubble_alpha = 0.0
	yawn_mouth.clear()
	if _startled_active():
		if elapsed < STARTLED_OPEN:
			var weight := 1.0 - _ease(elapsed / STARTLED_OPEN)
			for point in startled_mouth:
				yawn_mouth.append(Vector2(point.x, -66.0 + (point.y + 66.0) * weight))
	else:
		startled_mouth.clear()
	idle_scale_offset = Vector2.ZERO
	idle_scale_factor = Vector2.ONE
	if reaction == Reaction.NONE:
		if not jump_returning:
			_apply_stage_idle_pose()
		body_scale = (body_scale + idle_scale_offset) * idle_scale_factor
		var stretch := _stretch_strength()
		body_scale = body_scale.lerp(STRETCH_SCALE, stretch)
		eye_open = minf(eye_open, 1.0 - stretch)
		if active_idle == SpecialIdle.HUMMING:
			var phase := clampf(idle_time - special_idle_started, 0.0, HUMMING_DURATION)
			var beat := phase / HUMMING_BEAT
			var strength := _ease(beat) * _ease(3.0 - beat)
			var bob := sin(PI * beat)
			body_position.y -= 9.0 * strength * bob * bob
			body_angle = 0.018 * strength * bob
			humming_squint = strength
		var handoff := _idle_handoff_weight()
		if handoff > 0.0:
			body_scale = body_scale.lerp(idle_handoff.scale, handoff)
			body_position = body_position.lerp(idle_handoff.position, handoff)
			body_angle = lerpf(body_angle, idle_handoff.angle, handoff)
			eye_open = lerpf(eye_open, idle_handoff.eye, handoff)
			gaze = gaze.lerp(idle_handoff.gaze, handoff)
		return
	var t := clampf(elapsed / float(DURATIONS[reaction]), 0.0, 1.0)
	var envelope := sin(PI * t)
	var hold := _ease(t * 7.0) * _ease((1.0 - t) * 7.0)
	bubble_alpha = hold
	match reaction:
		Reaction.BLINK:
			eye_open = 1.0 - 0.96 * pow(sin(PI * t), 2.0)
			body_scale += Vector2(-0.04, 0.06) * envelope
		Reaction.SIDE_EYE:
			gaze = Vector2(-18.0 * direction, -2.0) * hold
			eye_open = 1.0 - 0.4 * hold
			body_angle = -0.06 * direction * envelope
		Reaction.SQUISH:
			var squish := sin(PI * minf(t * 1.5, 1.0)) * exp(-t * 1.5)
			body_scale += Vector2(0.34, -0.38) * squish
		Reaction.IRRITATED:
			eye_open = 1.0 - 0.78 * hold
			gaze = Vector2(0, 4)
			body_angle = sin(t * TAU) * 0.04
		Reaction.DONT:
			bubble = "Don't."
			eye_open = 0.65
			body_angle = -0.055 * envelope
		Reaction.SERIOUSLY:
			bubble = "Seriously?"
			gaze = Vector2(0, -9) * hold
			body_angle = 0.12 * envelope
		Reaction.SLIDE:
			body_position = origin.lerp(destination, _ease(t * 1.5))
			body_scale += Vector2(0.2, -0.12) * envelope
			gaze.x = -direction * 15.0
		Reaction.JUMP:
			if _free_jump_enabled():
				var flight := clampf(elapsed/FREE_JUMP_FLIGHT,0,1)
				body_position = Vector2(lerpf(origin.x,destination.x,flight),origin.y-700*flight*(1-flight))
			else:
				body_position = origin.lerp(destination, _ease(t))
				body_position.y -= sin(PI * t) * 175.0
			body_scale += Vector2(-0.14, 0.22) * envelope
			body_angle = direction * 0.18 * envelope
		Reaction.SHAKE:
			body_position.x += sin(t * TAU * 11.0) * 15.0 * envelope
			body_angle = sin(t * TAU * 9.0) * 0.09 * envelope
			eye_open = 0.3
		Reaction.FLATTEN:
			body_scale = Vector2(1.0 + hold * 0.45, 1.0 - hold * 0.78)
			eye_open = 1.0 - hold * 0.55
			bubble = "Can't touch this."
		Reaction.TURN:
			turn_amount = hold
			body_scale.x = 1.0 - sin(PI * hold) * 0.22
		Reaction.STOP:
			bubble = "STOP."
			body_scale += Vector2(0.14, 0.16) * envelope
			eye_open = 0.3 + (1.0 - hold) * 0.7
			body_position.x += sin(t * 70.0) * 4.0 * envelope
		Reaction.SIGN:
			sign_amount = hold
			eye_open = 0.45
			gaze.x = -12.0
		Reaction.BOX:
			box_amount = hold
			body_scale.y = 1.0 - hold * 0.3
			gaze = Vector2(0, -12)
		Reaction.RUN:
			var outside := Vector2(-210.0 if direction < 0 else last_size.x + 210.0, anchor.y)
			if t < 0.23:
				body_position = origin.lerp(outside, _ease(t / 0.23))
				body_scale = Vector2(1.22, 0.83)
				body_angle = direction * 0.2
			elif t < 0.52:
				body_position = outside
			elif t < 0.7:
				var peek := Vector2(45.0 if direction < 0 else last_size.x - 45.0, anchor.y)
				body_position = outside.lerp(peek, _ease((t - 0.52) / 0.18))
				gaze.x = -direction * 18.0
			else:
				var peek := Vector2(45.0 if direction < 0 else last_size.x - 45.0, anchor.y)
				body_position = peek.lerp(destination, _ease((t - 0.7) / 0.3))
				gaze.x = -direction * 12.0
			body_position.y -= absf(sin(t * 55.0)) * 9.0
		Reaction.RECOIL:
			var anticipation := _ease(elapsed / 0.09) * (1.0 - _ease((elapsed - 0.09) / 0.18))
			var hop := _ease((elapsed - 0.09) / 0.18) * (1.0 - _ease((elapsed - 0.27) / 0.36))
			var toward_room := maxf(0.0, origin.x - 144.0 if direction > 0.0 else last_size.x - 144.0 - origin.x)
			body_position.x += direction * (recoil_travel * hop - minf(9.0, toward_room) * anticipation)
			body_position.y -= 18.0 * hop
			var landing := _ease((elapsed - 0.45) / 0.18) * (1.0 - _ease((elapsed - 0.63) / 0.27))
			body_scale += Vector2(0.09, -0.09) * (anticipation + landing)
			eye_open = lerpf(eye_open, 1.18, hop)
		Reaction.PUFFER_HUFF:
			var inflation := _ease((elapsed - 0.18) / 0.09)
			var recovery := _ease((elapsed - 0.90) / 0.45)
			if elapsed < 0.18:
				body_scale = body_scale.lerp(Vector2.ONE * 0.81, _ease(elapsed / 0.18))
			else:
				body_scale = (Vector2.ONE * lerpf(0.81, 1.35, inflation)).lerp(body_scale, recovery)
			spike_extension = inflation * (1.0 - recovery)
			var tension := _ease(elapsed / 0.18) * (1.0 - recovery)
			eye_open = minf(eye_open, lerpf(1.0, 0.27, tension))
		Reaction.WAKE:
			bubble = "I was DREAMING."
			body_position.y -= sin(PI * minf(t * 2.0, 1.0)) * 100.0
			body_scale += Vector2(-0.12, 0.24) * envelope
			eye_open = 1.35 if t < 0.55 else 0.4

func _puffer_spike(outline: PackedVector2Array, index: int) -> PackedVector2Array:
	var count := outline.size()
	var root_point := outline[index]
	var outward := (root_point - Vector2(0, -81)).normalized()
	return PackedVector2Array([
		outline[posmod(index - 1, count)] - outward * 2.0,
		root_point + outward * (18.0 * spike_extension),
		outline[(index + 1) % count] - outward * 2.0,
	])

func _draw_puffer_spikes(outline: PackedVector2Array) -> void:
	for spike in range(18):
		var index := floori(float(spike * outline.size()) / 18.0)
		draw_colored_polygon(_puffer_spike(outline, index), INK)

func _silhouette() -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(80):
		var a := TAU * float(i) / 80.0
		var x := cos(a) * 117.0 * (1.0 + 0.035 * sin(a * 3.0 + clock * 1.1))
		var y := sin(a) * 119.0
		if y > 0.0:
			y *= 0.61
		points.append(Vector2(x, y - 73.0))
	return points

func _soft_squint_point(unit_point: Vector2, strength: float) -> Vector2:
	# Retain each oval's width and taper. Raise the middle into a shallow arch.
	var arch_y := -0.18 * (1.0 - unit_point.x * unit_point.x)
	return Vector2(unit_point.x, lerpf(unit_point.y, arch_y + 0.13 * unit_point.y, strength))

func _ellipse(center: Vector2, radius: Vector2, color: Color, canvas: CanvasItem = null, squint := 0.0, fringe := 0.0) -> void:
	if canvas == null:
		canvas = self
	var points := PackedVector2Array()
	for i in range(48):
		var a := TAU * float(i) / 48.0
		var point := Vector2(cos(a), sin(a))
		if squint > 0.0:
			point = _soft_squint_point(point, squint)
		points.append(center + point * radius)
	canvas.draw_colored_polygon(points, color)
	if fringe > 0.0:
		points.append(points[0])
		canvas.draw_polyline(points, color, fringe, true)

func _sleep_eye_fringe() -> float:
	var viewport_transform := get_viewport().get_stretch_transform() * get_global_transform_with_canvas()
	var body_transform := Transform2D(body_angle, _fallback_body_scale(), 0.0, body_position)
	var screen := viewport_transform * body_transform
	return 0.5 / maxf(0.01, screen.y.length())

func _text_center(text: String, center: Vector2, size: int, color: Color, canvas: CanvasItem = null) -> void:
	if canvas == null:
		canvas = self
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	canvas.draw_string(font, center - Vector2(width * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if font == null:
		return
	# Restrained editorial title fades away after the first interaction.
	if intro_alpha > 0.0:
		_text_center("a little personal space, please.", Vector2(last_size.x * 0.5, last_size.y * 0.25), 23, Color(MUTED, intro_alpha))
		_text_center("Don't Touch Me", Vector2(last_size.x * 0.5, last_size.y * 0.25 - 42), 40, Color(INK, intro_alpha))
		_text_center("(especially the little one)", Vector2(last_size.x * 0.5, last_size.y * 0.84), 19, Color(MUTED, intro_alpha * 0.8))
	var height := maxf(0.0, anchor.y - body_position.y)
	_ellipse(Vector2(body_position.x, anchor.y + 5), Vector2(111.0 - minf(height * 0.2, 45), 13), Color(0.35, 0.31, 0.24, 0.075))
	draw_set_transform(body_position, body_angle, _fallback_body_scale())
	var outline := _silhouette()
	if spike_extension > 0.0:
		_draw_puffer_spikes(outline)
	draw_colored_polygon(outline, INK)
	if not yawn_mouth.is_empty():
		draw_colored_polygon(yawn_mouth, YAWN_PINK)
	var startled := _startled_active()
	if turn_amount < 0.97 and (eye_open > 0.0 or startled):
		var face_alpha := 1.0 - turn_amount
		var fringe := _sleep_eye_fringe() if asleep else 0.0
		for side in [-1.0, 1.0]:
			var eye := Vector2(side * 37.0 + gaze.x, -113.0 + gaze.y)
			var opening := eye_open
			if reaction == Reaction.SERIOUSLY and side < 0:
				opening *= 0.5
			var minimum_height := 0.0 if active_idle == SpecialIdle.STRETCH else 2.0
			var radius_y := maxf(minimum_height, 21.0 * opening)
			if startled:
				radius_y = 21.0 * _startled_aperture(radius_y / 21.0)
				if radius_y <= 0.0:
					continue
			_ellipse(eye, Vector2(13.5 * (1.0 - turn_amount * 0.8), radius_y), Color(WHITE, face_alpha), self, humming_squint, fringe)
	if turn_amount > 0.1:
		draw_arc(Vector2(0, -105), 21, 0.35, 1.5, 20, Color(0.30, 0.30, 0.31, turn_amount * 0.45), 2.0, true)
	if touch_flash > 0.0:
		for side in [-1.0, 1.0]:
			draw_line(Vector2(side * 136, -143), Vector2(side * (136 + 13 * touch_flash), -151), Color(MUTED, touch_flash), 3.0, true)
	draw_set_transform(Vector2.ZERO)
	if sign_amount > 0.0:
		_draw_sign()
	if box_amount > 0.0:
		_draw_box()
	if bubble != "" and bubble_alpha > 0.0:
		_draw_bubble()
	if asleep:
		for i in range(3):
			var phase := fposmod(clock * 0.35 + float(i) * 0.32, 1.0)
			var pos := body_position + Vector2(76.0 + phase * 38.0, -198.0 - phase * 85.0)
			_text_center("z" if i < 2 else "Z", pos, 19 + i * 5, Color(MUTED, sin(phase * PI) * 0.7))

func _draw_sign(canvas: CanvasItem = null) -> void:
	if canvas == null:
		canvas = self
	var base := body_position + Vector2(102, -55)
	var top := base + Vector2(30, -115 * sign_amount)
	canvas.draw_line(base, top, Color("a68a62"), 7.0, true)
	canvas.draw_style_box(_panel(WHITE, 10, Color("d6cec0")), Rect2(top - Vector2(50, 53), Vector2(100, 65)))
	_text_center("NO", top - Vector2(0, 9), 34, INK, canvas)
	_ellipse(base, Vector2(18, 12), INK, canvas)

func _panel(color: Color, radius: int, border := Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(2 if border.a > 0 else 0)
	style.anti_aliasing = true
	return style

func _box_flaps(pos: Vector2) -> Array[PackedVector2Array]:
	return [
		PackedVector2Array([pos + Vector2(-143, -128), pos + Vector2(-162, -161), pos + Vector2(-10, -149), pos + Vector2(0, -128)]),
		PackedVector2Array([pos + Vector2(0, -128), pos + Vector2(16, -150), pos + Vector2(158, -158), pos + Vector2(143, -128)]),
	]

func _draw_box(canvas: CanvasItem = null) -> void:
	if canvas == null:
		canvas = self
	var pos := _box_position()
	var color := Color("c6a77e")
	canvas.draw_style_box(_panel(color, 5, Color("ae8f67")), Rect2(pos + Vector2(-143, -128), Vector2(286, 139)))
	canvas.draw_line(pos + Vector2(0, -128), pos + Vector2(0, 10), Color("dfc69f"), 32, true)
	canvas.draw_line(pos + Vector2(-143, -126), pos + Vector2(143, -126), Color("997c59"), 3, true)
	var flaps := _box_flaps(pos)
	canvas.draw_colored_polygon(flaps[0], Color("ddc49f"))
	canvas.draw_colored_polygon(flaps[1], Color("d5b98e"))
	_text_center("definitely empty", pos + Vector2(-3, -44), 19, Color("826a4c"), canvas)
	if box_amount > 0.85:
		for side in [-1.0, 1.0]:
			_ellipse(pos + Vector2(side * 28, -148), Vector2(10, 8), WHITE, canvas)

func _draw_bubble(canvas: CanvasItem = null) -> void:
	if canvas == null:
		canvas = self
	var size := 31 if reaction != Reaction.STOP else 43
	var width := font.get_string_size(bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 54.0
	var center := Vector2(clampf(body_position.x, width * 0.5 + 18, last_size.x - width * 0.5 - 18), maxf(110, body_position.y - 290))
	center.y += (1.0 - bubble_alpha) * 10.0
	var paper := Color(WHITE, bubble_alpha)
	canvas.draw_style_box(_panel(paper, 22), Rect2(center - Vector2(width * 0.5, 43), Vector2(width, 78)))
	canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-9, 31), center + Vector2(10, 31), center + Vector2(0, 48)]), paper)
	_text_center(bubble, center + Vector2(0, 7), size, Color(INK, bubble_alpha), canvas)
