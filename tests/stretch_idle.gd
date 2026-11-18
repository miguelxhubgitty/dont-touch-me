extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var failures := 0
	for authored in [false, true]:
		var actor = load("res://main.tscn").instantiate()
		actor.use_adobe_idle = authored
		root.add_child(actor)
		actor.set_process(false)
		actor.audio_manager.muted = true
		actor.next_idle = actor.SpecialIdle.STRETCH
		actor.next_idle_at = 4.5
		actor.advance(4.49)
		if actor.active_idle != actor.SpecialIdle.NONE: failures += 1
		actor.advance(0.02)
		var start: float = actor.special_idle_started
		actor.advance(0.81)
		var scale_value: Vector2 = actor.breathing.scale if authored else actor.body_scale
		if not scale_value.is_equal_approx(actor.STRETCH_SCALE): failures += 1
		if actor.eye_open > actor.STRETCH_EYES: failures += 1
		var anchor: Vector2 = actor.anchor
		if actor.body_position != anchor: failures += 1
		actor._handle_player_touch(Vector2(2, 2))
		if actor.active_idle != actor.SpecialIdle.STRETCH or actor.special_idle_started != start or actor.reaction != actor.Reaction.NONE: failures += 1
		if not actor.touch_at(anchor + Vector2(0, -225)) or actor.active_idle != actor.SpecialIdle.NONE:
			failures += 1
		actor.advance(2.0)
		actor.next_idle = actor.SpecialIdle.STRETCH
		actor.next_idle_at = 4.5
		actor.advance(2.6)
		actor.advance(1.81)
		if actor.active_idle != actor.SpecialIdle.NONE or actor.idle_time < 6.4: failures += 1
		actor.advance(18.0 - actor.idle_time)
		if not actor.asleep: failures += 1
		actor.free()
	print("Stretch idle failures: ", failures)
	quit(0 if failures == 0 else 1)
