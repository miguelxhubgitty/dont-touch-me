extends "res://tests/adobe_reactions.gd"

func run() -> void:
	var viewport := SubViewport.new()
	root.add_child(viewport)
	var native = Native.new()
	var original = Original.new()
	for actor in [native,original]:
		viewport.add_child(actor)
		actor.set_process(false)
		actor.audio_manager.muted = true
	var expression: float = native.audio_manager.marker_position("expression")
	var poses := {
		Original.Reaction.FLATTEN: [[2.0/30,.98,1.025],[4.0/30,1.34,.43],[1.65/7,1.45,.22],[1.65*6/7,1.45,.22],[1.5,.98,1.045],[1.6,1.006,.994]],
		Original.Reaction.TURN: [[2.0/30,1.015,.99],[1.8/14,.78,1.025],[.2,.92,1.012],[1.8/7,1,1],[1.8*6/7,1,1],[1.8*13/14,.78,1.025],[52.0/30,1.025,.985]],
		Original.Reaction.STOP: [[2.0/30,1.025,.975],[1.25*expression,1.13,1.15],[.2,1.14,1.16],[.3,1.12,1.14],[1.25*6/7,1.12,1.14],[35.0/30,1.005,.99]],
	}
	for width in [360,720]:
		viewport.size = Vector2i(width,720)
		await process_frame
		for actor in [native,original]: actor._resize()
		for which in poses:
			for side in [-1,1]:
				for actor in [native,original]:
					reset(actor)
					actor.idle_gaze = Vector2(4,-1)
					actor.begin_reaction(which,actor.body_position+Vector2(side*20,-70))
				for pose in poses[which]:
					native.elapsed = pose[0]
					native._update_pose()
					check(native.breathing.scale.distance_to(Vector2(pose[1],pose[2])) < .00001,"approved exact key pose")
				native.elapsed = 0
				native._update_pose()
				for tick in range(int(Original.DURATIONS[which]*120)):
					for actor in [native,original]: actor.advance(1.0/120)
					compare(native,original)
					check(native.bubble == original.bubble and native.bubble_alpha == original.bubble_alpha,"source bubble text and envelope")
					check(native.eyes.position == Vector2(original.gaze.x,-113+original.gaze.y),"source gaze")
					check(is_equal_approx(native.eyes.scale.y,maxf(2.0/21,original.eye_open)),"source eyelids")
					check(native.visual.position == original.body_position,"model body position applied once")
					var amount: float = original.turn_amount
					check(is_equal_approx(native.left_eye.scale.x,1-.8*amount) and native.left_eye.scale.x == native.right_eye.scale.x,"per-eye foreshortening")
					check(native.eyes.visible == (amount < .97) and is_equal_approx(native.eyes.modulate.a,1-amount),"face visibility and fade")
					check(native.turn_details.visible == (original.reaction == Original.Reaction.TURN),"TURN details scoped to active reaction")
					if amount >= .97:
						var body_point: Vector2 = native.breathing.get_global_transform_with_canvas()*Vector2(0,-70)
						check(native.contains_touch(body_point),"hidden face leaves the body pokeable")
				reset(native)
				native.begin_reaction(Original.Reaction.TURN,native.body_position)
				native.advance(.6)
				native.begin_reaction(which if which != Original.Reaction.TURN else Original.Reaction.BLINK,native.body_position)
				check(native.eyes.visible and native.eyes.modulate.a == 1 and native.left_eye.scale.x == 1 and not native.turn_details.visible,"interruption resets TURN appearance")
	var report := {"checks":checks,"failures":failures,"widths":[360,720],"scope":"Exact approved scale keys, both directions, 120Hz source state/audio parity, model gaze/blink, bubbles, TURN fade/width/cutoff and interruption reset"}
	FileAccess.open("res://test-output/flatten-turn-stop-tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	viewport.free()
	await process_frame
	print("FLATTEN_TURN_STOP_TESTS ",JSON.stringify(report))
	quit(0 if failures == 0 else 1)
