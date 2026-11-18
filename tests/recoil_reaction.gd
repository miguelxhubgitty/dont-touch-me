extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var failures := 0
	for width in [360, 720]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(width, 1280)
		root.add_child(viewport)
		for native in [false, true]:
			for side in [-1.0, 1.0]:
				var actor = load("res://main.tscn").instantiate()
				actor.use_adobe_idle = native
				viewport.add_child(actor)
				actor.set_process(false)
				actor.audio_manager.muted = true
				var start := Vector2(width * 0.5, 742.4)
				actor.anchor = start
				actor._update_pose()
				actor.begin_reaction(actor.Reaction.RECOIL, start - Vector2(side * 18, 70))
				actor.advance(0.09)
				if (actor.body_position.x - start.x) * side > 0.0: failures += 1
				actor.advance(0.18)
				if (actor.body_position.x - start.x) * side <= 0.0: failures += 1
				if not is_equal_approx(actor.recoil_travel, minf(45.0, width * 0.5 - 144.0)): failures += 1
				if actor.body_position.y >= start.y or actor.eye_open <= 1.0: failures += 1
				if actor.uses_authored_reaction() != native: failures += 1
				if not actor.contains_touch(actor.body_position + Vector2(0, -70)): failures += 1
				actor.advance(0.64)
				if actor.body_position != start or actor.reaction != actor.Reaction.NONE: failures += 1
				actor.free()
		viewport.free()
	print("Recoil failures: ", failures)
	quit(0 if failures == 0 else 1)
