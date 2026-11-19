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
			var actor = load("res://main.tscn").instantiate()
			actor.use_adobe_idle = native
			viewport.add_child(actor)
			actor.set_process(false)
			actor.audio_manager.muted = true
			actor.begin_reaction(actor.Reaction.PUFFER_HUFF, actor.body_position)
			actor.advance(0.09)
			if actor.spike_extension != 0 or actor.eye_open >= 1.0: failures += 1
			actor.advance(0.09)
			var scale_value: Vector2 = actor.breathing.scale if native else actor.body_scale
			if not scale_value.is_equal_approx(Vector2(0.81, 0.81)) or actor.spike_extension != 0.0: failures += 1
			actor.advance(0.045)
			if actor.spike_extension <= 0.0 or actor.spike_extension >= 1.0: failures += 1
			actor.advance(0.045)
			scale_value = actor.breathing.scale if native else actor.body_scale
			if not scale_value.is_equal_approx(Vector2(1.35, 1.35)): failures += 1
			actor.advance(0.45)
			if not is_equal_approx(actor.spike_extension, 1.0): failures += 1
			var outline: PackedVector2Array = actor.idle_outline if native else actor._silhouette()
			var pose := Transform2D(0.0, actor.body_scale, 0.0, actor.body_position)
			if native:
				pose = actor.breathing.get_global_transform_with_canvas()
			var spike: PackedVector2Array = actor._puffer_spike(outline, 0)
			var inside := outline[0].lerp(Vector2(0, -81), 0.09)
			if not actor.contains_touch(pose * inside): failures += 1
			if actor.contains_touch(pose * spike[1]): failures += 1
			actor._handle_player_touch(pose * spike[1])
			if actor.reaction != actor.Reaction.PUFFER_HUFF: failures += 1
			if not actor.touch_at(pose * inside) or actor.spike_extension != 0.0: failures += 1
			actor.begin_reaction(actor.Reaction.PUFFER_HUFF, actor.body_position)
			actor.advance(1.125)
			if actor.spike_extension <= 0.0 or actor.spike_extension >= 1.0: failures += 1
			actor.advance(0.226)
			if actor.spike_extension != 0.0: failures += 1
			if actor.reaction != actor.Reaction.NONE: failures += 1
			actor.free()
		viewport.free()
	print("Puffer-huff failures: ", failures)
	quit(0 if failures == 0 else 1)
