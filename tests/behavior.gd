extends SceneTree

const Blob = preload("res://scripts/blob.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func run() -> void:
	var game := Blob.new()
	root.add_child(game)
	game.set_process(false)
	game.rng.seed = 48291
	check(game.reaction == Blob.Reaction.NONE, "starts idle")
	check(not game.touch_at(Vector2(2, 2)), "background ignores touches")
	check(game.annoyance == 0, "background does not annoy")
	for boundary in [0.0, 20.0, 20.01, 50.0, 50.01, 80.0, 80.01, 100.0]:
		game.annoyance = boundary
		var expected := 0 if boundary <= 20 else (1 if boundary <= 50 else (2 if boundary <= 80 else 3))
		check(game.tier() == expected, "tier boundary " + str(boundary))
		var seen := {}
		for i in range(250):
			var selected: int = game.choose_reaction()
			check(selected != game.last_reaction, "never repeat consecutive selections")
			check(selected in Blob.POOLS[expected], "selection belongs to tier")
			seen[selected] = true
			game.last_reaction = selected
		check(seen.size() == Blob.POOLS[expected].size(), "all reactions reachable in tier")
	for which in Blob.DURATIONS:
		game.anchor = Vector2(game.last_size.x * 0.5, game.last_size.y * 0.58)
		game.reaction = Blob.Reaction.NONE
		game._update_pose()
		game.begin_reaction(which, game.body_position + Vector2(-20, -70))
		var duration: float = Blob.DURATIONS[which]
		for i in range(100):
			game.advance(duration / 100.0)
			check(game.body_position.is_finite(), "finite position")
			check(game.body_scale.x > 0 and game.body_scale.y > 0, "nonzero scale")
			if which != Blob.Reaction.RUN:
				var polygon: PackedVector2Array = game._silhouette()
				for vertex in polygon:
					var world: Vector2 = (vertex * game.body_scale).rotated(game.body_angle) + game.body_position
					check(world.x >= 0 and world.x <= game.last_size.x, "body horizontally visible")
					check(world.y >= 0 and world.y <= game.last_size.y, "body vertically visible")
		game.advance(0.1)
		check(game.reaction == Blob.Reaction.NONE, "reaction completes " + str(which))
		check(game.contains_touch(game.body_position + Vector2(0, -70)), "hitbox follows body")
	# The widest and most tilted poses also fit at both movement limits.
	for edge in [190.0, game.last_size.x - 190.0]:
		for which in Blob.DURATIONS:
			if which == Blob.Reaction.RUN: continue
			game.asleep = false
			game.idle_time = 0
			game.anchor = Vector2(edge, game.last_size.y * 0.58)
			game.reaction = Blob.Reaction.NONE
			game._update_pose()
			game.begin_reaction(which, game.body_position + Vector2(-10, -60))
			for frame in range(30):
				game.advance(float(Blob.DURATIONS[which]) / 30.0)
				for vertex in game._silhouette():
					var world: Vector2 = (vertex * game.body_scale).rotated(game.body_angle) + game.body_position
					check(world.x >= 0 and world.x <= game.last_size.x, "edge pose stays visible")
	# Repeated input should never restart an escape and prevent its return.
	for which in [Blob.Reaction.RUN, Blob.Reaction.BOX]:
		game.asleep = false
		game.idle_time = 0.0
		game.begin_reaction(which, game.body_position)
		for i in range(600):
			if game.reaction != which: break
			game.touch_at(game.body_position + Vector2(0, -60))
			game.advance(0.016)
		check(game.reaction == Blob.Reaction.NONE, "escape survives tap spam")
	for i in range(1000):
		game.touch_at(game.body_position + Vector2(0, -60))
		game.advance(0.016)
		check(game.annoyance >= 0 and game.annoyance <= 100, "annoyance bounded")
	game.reaction = Blob.Reaction.NONE
	game.idle_time = 0
	for i in range(400): game.advance(0.1)
	check(game.asleep, "sleeps after inactivity")
	check(game.annoyance == 0, "relaxes fully")
	check(game.touch_at(game.body_position + Vector2(0, -60)), "sleeping body touchable")
	check(not game.asleep and game.reaction == Blob.Reaction.WAKE, "special wake reaction")
	# Exercise the real mouse and touchscreen input paths without emulation.
	game.reaction = Blob.Reaction.NONE
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = game.body_position + Vector2(0, -60)
	var before: float = game.annoyance
	game._unhandled_input(mouse)
	check(game.annoyance > before, "mouse path")
	game.reaction = Blob.Reaction.NONE
	game._update_pose()
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = game.body_position + Vector2(0, -60)
	before = game.annoyance
	game._unhandled_input(touch)
	check(game.annoyance > before, "touch path")
	mouse.pressed = false
	before = game.annoyance
	game._unhandled_input(mouse)
	check(game.annoyance == before, "release ignored")
	# Resizing during an escape must recover a visible, touchable state.
	for size in [Vector2i(720, 1280), Vector2i(1080, 2400), Vector2i(768, 1024)]:
		root.size = size
		await process_frame
		game._resize()
		game.begin_reaction(Blob.Reaction.RUN, game.body_position)
		game.advance(0.7)
		game.last_size = Vector2.ZERO
		game._resize()
		check(game.reaction == Blob.Reaction.NONE, "resize clears escape")
		check(game.contains_touch(game.body_position + Vector2(0, -60)), "resize restores hitbox")
	print("Behavior checks: %d; failures: %d" % [checks, failures])
	game.queue_free()
	quit(1 if failures else 0)
