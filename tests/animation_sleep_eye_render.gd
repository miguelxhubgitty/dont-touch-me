extends SceneTree
const Game = preload("res://main.tscn")
const IdleFixture = preload("res://tests/idle_fixture.gd")
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for authored in [true, false]:
		for width in [288, 360, 720]:
			await sample(authored, width)
	quit(1 if failures else 0)

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func sample(authored: bool, width: int) -> void:
	var view := SubViewport.new()
	view.size = Vector2i(width, roundi(width * 1280.0 / 720.0))
	view.size_2d_override = Vector2i(720, 1280)
	view.size_2d_override_stretch = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var actor = Game.instantiate()
	actor.use_adobe_idle = authored
	view.add_child(actor)
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	actor.get_node("SoundHUD").hide()
	actor.intro_alpha = 0
	actor.audio_manager.muted = true
	actor.next_idle_at = INF
	actor.advance(18.0)
	IdleFixture.arm(actor, actor.SpecialIdle.SLEEP_TWITCH, 23.4)
	actor.advance(5.38)
	var twitch_frames := 0
	var poses := {}
	var softened_frames := 0
	for n in range(42):
		actor.advance(1.0 / 60)
		await RenderingServer.frame_post_draw
		check(actor.asleep and not actor.uses_authored_visual() and actor.gaze.is_zero_approx(), "steady sleeping pose")
		var scale_value: Vector2 = actor._fallback_body_scale()
		check(actor.contains_touch(actor.body_position + (Vector2(0,-75) * scale_value).rotated(actor.body_angle)), "visible sleeper remains touchable")
		var eye: Vector2 = (actor.body_position + (Vector2(-37,-113) * scale_value).rotated(actor.body_angle)) * (width / 720.0)
		var image := view.get_texture().get_image()
		var count := 0
		var has_fringe := false
		for x in range(roundi(eye.x) - 17, roundi(eye.x) + 18):
			for y in range(roundi(eye.y)-5, roundi(eye.y)+6):
				var color := image.get_pixel(x,y)
				if color.r > 0.5 and color.g > 0.5:
					count += 1
				if color.r > 0.2 and color.r < 0.88:
					has_fringe = true
		check(count > 0, "sleep eye remains visible")
		if has_fringe:
			softened_frames += 1
		if actor.active_idle == actor.SpecialIdle.SLEEP_TWITCH:
			twitch_frames += 1
			poses[actor.body_angle] = true
	check(twitch_frames >= 31 and poses.size() >= 14, "Sleep Twitch animates through its full duration")
	check(softened_frames >= 35, "sleeping eye coverage has a softened edge")
	print("Sleep Twitch samples: ", width, " px, authored setting=", authored, ", softened frames=", softened_frames)
	view.free()
