extends SceneTree
const Original = preload("res://scripts/blob.gd")
const Simple = preload("res://scripts/blob_animationplayer.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func run() -> void:
	root.size = Vector2i(720,1280)
	var original = Original.new()
	var simple = Simple.new()
	simple.free_jump_enabled = false
	for actor in [original,simple]:
		root.add_child(actor)
		actor.set_process(false)
		actor.audio_manager.muted = true
		actor.rng.seed = 41837
	var animation: Animation = simple.player.get_animation("breathe")
	check(animation.get_track_count() == 2, "only two native scale tracks")
	for track in range(2):
		check(animation.track_get_type(track) == Animation.TYPE_BEZIER, "native Bezier easing")
		check(animation.track_get_key_count(track) == 8, "eight keys, five poses")
	check(animation.length == 3 and animation.loop_mode == Animation.LOOP_LINEAR, "three second native loop")
	check(is_equal_approx(animation.step,1.0/30), "30 FPS authoring reference")
	for track in range(2):
		for key in range(8):
			var author_frame := animation.track_get_key_time(track,key)*30
			check(absf(author_frame-roundf(author_frame)) < .0001,"whole 30 FPS authoring frames")
	var between_ticks := animation.bezier_track_interpolate(1,.45)
	check(absf(between_ticks-animation.bezier_track_interpolate(1,13.0/30)) > .00001,"continuous motion between authoring frames")
	var sprite: Sprite2D = simple.visual.get_node("Breathing/Body")
	check(sprite.texture.get_size() == Vector2(576,448), "one reused body texture")
	check(FileAccess.get_sha256("res://assets/blob/body.png") == "87e014bffb797f0f3d333c14892e42ce7d439d390e540d6ca82683dc0835a20c", "unchanged native Adobe resting artwork")
	check(sprite.scale == Vector2(.5,.5) and sprite.position == Vector2(-144,-208), "fixed foot registration at 2x resolution")
	for time in [0,.04,.1,.16]:
		simple.player.seek(time,true)
		check(simple.visual.get_node("Breathing").scale.is_equal_approx(Vector2.ONE), "rest hold")
	for time in [1,1.05,1.1,1.16]:
		simple.player.seek(time,true)
		check(simple.visual.get_node("Breathing").scale.is_equal_approx(Vector2(.991,1.018)), "crest hold")
	var max_hit_outline_difference := 0.0
	var resting_outline: PackedVector2Array = original._silhouette()
	for frame in range(72):
		simple.player.seek(frame/24.0,true)
		var scale_value: Vector2 = simple.visual.get_node("Breathing").scale
		original.clock = frame/24.0
		original._update_pose()
		var collision_outline: PackedVector2Array = original._silhouette()
		for vertex in range(resting_outline.size()):
			max_hit_outline_difference = maxf(max_hit_outline_difference,(collision_outline[vertex]*original.body_scale-resting_outline[vertex]*scale_value).length())
		check(scale_value.x >= .9909 and scale_value.x <= 1.0031 and scale_value.y >= .9969 and scale_value.y <= 1.0181, "subtle scale range without doubled breathing")
	# Standalone blink track is independent of the breathing player.
	var blink: AnimationPlayer = simple.visual.get_node("BlinkPlayer")
	blink.play("blink")
	blink.seek(1.86,true)
	check(is_equal_approx(simple.eyes.scale.y,2.0/21), "native independent blink closes eyes")
	blink.stop()
	simple.clock = 0
	simple._update_pose()
	simple.blink_remaining = .1
	simple.idle_gaze = Vector2(5,-2)
	simple._update_pose()
	check(simple.eyes.position == Vector2(5,-115), "game gaze remains independent")
	check(is_equal_approx(simple.eyes.scale.y,2.0/21), "game blink preserved")
	simple.blink_remaining = original.blink_remaining
	simple.idle_gaze = original.idle_gaze
	original.clock = simple.clock
	for reaction in Original.DURATIONS:
		for actor in [original,simple]:
			actor.reaction = 0
			actor._update_pose()
			actor.begin_reaction(reaction,actor.body_position+Vector2(-20,-70))
		check(not simple.uses_authored_idle() and simple.visual.visible == Simple.AUTHORED_REACTIONS.has(reaction), "all approved reactions use native rendering")
		for tick in range(120):
			for actor in [original,simple]:
				actor.advance(float(Original.DURATIONS[reaction])/120)
			compare_state(original,simple)
	for tick in range(2400):
		if tick < 300 and tick % 13 == 0 or tick == 2200:
			var point: Vector2 = original.body_position+Vector2(0,-70)
			check(original.touch_at(point) == simple.touch_at(point), "unchanged hit acceptance")
		for actor in [original,simple]:
			actor.advance(1.0/60)
		compare_state(original,simple)
		if tick == 2100:
			check(simple.asleep and not simple.visual.visible, "sleep fallback")
		if tick == 2200:
			check(simple.reaction == Original.Reaction.WAKE,"unchanged wake reaction")
	var report := FileAccess.open("res://test-output/simple-tests.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures,"max_procedural_outline_difference":max_hit_outline_difference},"\t"))
	for actor in [original,simple]:
		actor.free()
	await process_frame
	quit(1 if failures else 0)

func compare_state(original,simple) -> void:
	for property in ["annoyance","reaction","asleep","idle_time","elapsed","clock","body_position","body_scale","body_angle","eye_open","gaze","bubble","box_amount","sign_amount","blink_remaining","blink_timer","gaze_timer","anchor","destination"]:
		check(original.get(property) == simple.get(property),"unchanged simulation: "+property)
	check(original.rng.state == simple.rng.state,"same RNG")
