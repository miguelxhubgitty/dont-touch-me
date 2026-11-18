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
		actor.next_idle = actor.SpecialIdle.HUMMING
		actor.next_idle_at = 9.0
		actor.advance(8.99)
		if actor.active_idle != actor.SpecialIdle.NONE: failures += 1
		actor.advance(0.02)
		if actor.active_idle != actor.SpecialIdle.HUMMING: failures += 1
		var anchor: Vector2 = actor.anchor
		for beat in range(3):
			actor.advance(0.45)
			if actor.body_position.y >= anchor.y or actor.body_position.x != anchor.x: failures += 1
			if actor.eye_open >= 1.0 or actor.body_angle * (-1 if beat == 1 else 1) <= 0.0: failures += 1
			if authored and not is_equal_approx(actor.breathing.rotation, actor.body_angle): failures += 1
			if not actor.contains_touch(actor.body_position + Vector2(0, -70)): failures += 1
			actor.advance(0.45)
			if not actor.body_position.is_equal_approx(anchor): failures += 1
		actor.advance(0.01)
		if actor.active_idle != actor.SpecialIdle.NONE or actor.next_idle != actor.SpecialIdle.NONE: failures += 1
		actor.advance(18.0 - actor.idle_time)
		if not actor.asleep: failures += 1
		actor.asleep = false
		actor.idle_time = 0.0
		actor.next_idle = actor.SpecialIdle.HUMMING
		actor.next_idle_at = 9.0
		actor.advance(9.0)
		actor.advance(0.9)
		actor._handle_player_touch(Vector2(2, 2))
		if actor.active_idle != actor.SpecialIdle.HUMMING: failures += 1
		if not actor.touch_at(actor.body_position + Vector2(0, -70)) or actor.active_idle != actor.SpecialIdle.NONE:
			failures += 1
		actor.free()
	print("Humming idle failures: ", failures)
	quit(0 if failures == 0 else 1)
