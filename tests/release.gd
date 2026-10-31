extends SceneTree
## Additional release regressions: actual viewport input, interruption matrix,
## logical mobile aspect ratios, focus lifecycle, and long mixed-input sessions.
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

func run() -> void:
	check(ProjectSettings.get_setting("display/window/handheld/orientation") == 1, "portrait orientation configured")
	check(ProjectSettings.get_setting("display/window/stretch/mode") == "canvas_items", "responsive canvas stretch")
	check(not ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"), "no duplicate emulated mouse taps")
	check(not ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse"), "no duplicate emulated touch taps")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	root.add_child(viewport)
	var game := Blob.new()
	viewport.add_child(game)
	game.set_process(false)
	game.rng.seed = 10042
	# Dispatch events through Godot's viewport, not just the input handler.
	for size in [Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(960, 1280), Vector2i(720, 1920)]:
		viewport.size = size
		game._resize()
		check(game.last_size == Vector2(size), "test uses distinct logical viewport size")
		game.annoyance = 0
		var touch := InputEventScreenTouch.new()
		touch.position = game.body_position + Vector2(0, -70)
		touch.pressed = true
		viewport.push_input(touch, true)
		check(game.annoyance >= 7 and game.annoyance <= 10, "native touch dispatch hits silhouette")
		var before: float = game.annoyance
		touch.pressed = false
		viewport.push_input(touch, true)
		check(game.annoyance == before, "native release does not double count")
		touch.position = Vector2(1, 1)
		touch.pressed = true
		viewport.push_input(touch, true)
		check(game.annoyance == before, "background touch ignores annoyance")
		var mouse := InputEventMouseButton.new()
		mouse.position = game.body_position + Vector2(0, -70)
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = true
		viewport.push_input(mouse, true)
		check(game.annoyance > before, "mouse dispatch matches touch")
		mouse.pressed = false
		viewport.push_input(mouse, true)
		# All reactions at multiple moments, including visible bounds and text width.
		for which in Blob.DURATIONS:
			game.reaction = Blob.Reaction.NONE
			game._update_pose()
			game.begin_reaction(which, game.body_position + Vector2(-10, -70))
			for frame in range(41):
				game.elapsed = float(Blob.DURATIONS[which]) * frame / 40.0
				game._update_pose()
				check(game.body_scale.is_finite(), "finite pose at every aspect")
				if which != Blob.Reaction.RUN:
					for vertex in game._silhouette():
						var world: Vector2 = (vertex * game.body_scale).rotated(game.body_angle) + game.body_position
						check(Rect2(Vector2.ZERO, Vector2(size)).has_point(world), "full body visible at mobile aspect")
				if not game.bubble.is_empty():
					var font_size := 43 if which == Blob.Reaction.STOP else 31
					check(Blob.Typography.width(game.bubble, font_size) + 90 < size.x, "rendered dialogue fits")
			game.advance(0.1)
			check(game.reaction == Blob.Reaction.NONE, "completes across aspects")
	# Every possible short reaction can safely interrupt every current reaction.
	for current in Blob.DURATIONS:
		for next in Blob.DURATIONS:
			game.asleep = false
			game.idle_time = 0
			game.reaction = Blob.Reaction.NONE
			game._update_pose()
			game.begin_reaction(current, game.body_position)
			game.advance(float(Blob.DURATIONS[current]) * 0.4)
			game.begin_reaction(next, game.body_position)
			game.advance(float(Blob.DURATIONS[next]) + 0.01)
			check(game.reaction == Blob.Reaction.NONE, "interruption completes")
			check(game.body_position.is_equal_approx(game.destination), "interruption lands at destination")
	# A pause must keep the clock frozen; resuming must re-enable updates.
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not game.is_processing(), "focus loss pauses")
	var paused_clock: float = game.clock
	await process_frame
	check(game.clock == paused_clock, "no background clock advance")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(game.is_processing(), "focus resume restores processing")
	game.set_process(false)
	# Exact decay grace period, sleep threshold, and wake behavior.
	game.reaction = Blob.Reaction.NONE
	game.asleep = false
	game.idle_time = 0
	game.annoyance = 100
	game.advance(2.4)
	check(game.annoyance == 100, "decay grace period")
	game.advance(0.2)
	check(game.annoyance < 100 and game.annoyance > 98, "gradual decay")
	game.idle_time = Blob.SLEEP_AFTER - 0.1
	game.advance(0.05)
	check(not game.asleep, "not asleep too early")
	game.advance(0.06)
	check(game.asleep, "sleep threshold")
	check(not game.touch_at(Vector2.ONE), "background cannot wake")
	check(game.asleep, "background preserves sleep")
	game.touch_at(game.body_position + Vector2(0, -70))
	check(not game.asleep and game.reaction == Blob.Reaction.WAKE, "wake reaction via silhouette")
	# Long deterministic sessions: varied touch rates, misses, pauses, and escapes.
	for seed_value in [1, 7721, 99427]:
		game.rng.seed = seed_value
		for frame in range(6000):
			if frame % 3 == 0:
				var point: Vector2 = game.body_position + Vector2(0, -60)
				if frame % 17 == 0: point = Vector2.ONE
				if Rect2(Vector2.ZERO, Vector2(viewport.size)).has_point(point):
					var old_reaction: int = game.last_reaction
					var was_sleeping: bool = game.asleep
					var protected: bool = game.reaction in [Blob.Reaction.RUN, Blob.Reaction.BOX]
					var hit: bool = game.touch_at(point)
					if hit and not protected and not was_sleeping:
						check(game.last_reaction != old_reaction, "no repeated reaction during live input")
			game.advance(1.0 / 60.0)
			check(game.annoyance >= 0 and game.annoyance <= 100, "session annoyance bounded")
			check(game.body_position.is_finite(), "session never corrupts position")
		game.idle_time = 0
		for frame in range(400): game.advance(0.1)
		check(game.reaction == Blob.Reaction.NONE and game.asleep, "session recovers to peaceful sleep")
	print("Release checks: %d; failures: %d" % [checks, failures])
	viewport.queue_free()
	quit(1 if failures else 0)
