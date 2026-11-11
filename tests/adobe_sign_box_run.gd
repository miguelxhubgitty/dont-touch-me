extends "res://tests/adobe_reactions.gd"

class OriginalProps extends Original:
	func _draw() -> void:
		if sign_amount > 0: _draw_sign()
		if box_amount > 0: _draw_box()

class NativeProps extends Native:
	func _draw() -> void:
		pass

func seek_pose(actor, time: float) -> void:
	actor.elapsed = time
	actor._update_pose()
	actor.queue_redraw()

func poke(viewport: SubViewport, point: Vector2, touch: bool) -> void:
	if touch:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = true
		viewport.push_input(event,true)
	else:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		viewport.push_input(event,true)

func run() -> void:
	var views: Array[SubViewport] = []
	var original = OriginalProps.new()
	var native = NativeProps.new()
	for actor in [original,native]:
		var view := SubViewport.new()
		view.transparent_bg = true
		view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		view.handle_input_locally = true
		root.add_child(view)
		view.add_child(actor)
		actor.set_process(false)
		actor.audio_manager.muted = true
		views.append(view)
	var rendered := DisplayServer.get_name() != "headless"
	var prop_cases := 0
	var peek: float = 2.7*native.audio_manager.marker_position("expression")
	var accents := {
		Original.Reaction.SIGN: [[5.0/30,.985,1.055],[2.0/7,1.01,1.02],[12.0/7,1.01,1.02]],
		Original.Reaction.BOX: [[peek,1.025,.73],[2.7/7,1,.70],[2.7*6/7,1,.70],[76.0/30,.985,1.035]],
		Original.Reaction.RUN: [[2.0/30,1.07,.92],[.8,1.22,.83],[2.132,1,1],[2.6,1.035,.965],[2.87,.98,1.035]],
	}
	for width in [360,720]:
		for view in views: view.size = Vector2i(width,720)
		await process_frame
		for actor in [original,native]: actor._resize()
		for side in [-1,1]:
			for which in [Original.Reaction.SIGN,Original.Reaction.BOX,Original.Reaction.RUN]:
				for actor in [original,native]:
					reset(actor)
					actor.anchor.x = width*(.35 if side < 0 else .65)
					actor._update_pose()
					actor.begin_reaction(which,actor.body_position+Vector2(side*20,-70))
				for accent in accents[which]:
					seek_pose(native,accent[0])
					check(native.breathing.scale.distance_to(Vector2(accent[1],accent[2])) < .00001,"approved accent or hold pose")
				if which == Original.Reaction.RUN:
					seek_pose(native,.8)
					check(is_equal_approx(native.breathing.rotation,.2*native.direction),"RUN leans in the controller's escape direction")
				seek_pose(native,0)
				var duration: float = Original.DURATIONS[which]
				for tick in range(roundi(duration*120)):
					for actor in [original,native]: actor.advance(1.0/120)
					compare(native,original)
					check(native.visual.position == original.body_position,"controller path applied once")
					check(native.sign_amount == original.sign_amount and native.box_amount == original.box_amount,"prop phase parity")
					check(native.eyes.position == Vector2(original.gaze.x,-113+original.gaze.y),"source gaze")
					check(is_equal_approx(native.eyes.scale.y,maxf(2.0/21,original.eye_open)),"source eyelids")
				for actor in [original,native]: actor.advance(.0001)
				check(native.reaction == 0 and not native.props.visible,"completion clears props")
		for which in [Original.Reaction.SIGN,Original.Reaction.BOX]:
			for mirrored in [false,true]:
				for actor in [original,native]:
					reset(actor)
					actor.scale = Vector2(-.8,1) if mirrored else Vector2.ONE
					actor.position.x = width if mirrored else 0
					actor.begin_reaction(which,actor.body_position)
				var times := [.08,.285714,1.2,1.9] if which == Original.Reaction.SIGN else [.08,peek-.001,peek+.001,1.2,2.7-peek-.001,2.7-peek+.001,2.6]
				for time in times:
					for actor in [original,native]: seek_pose(actor,time)
					if which == Original.Reaction.BOX:
						var box_pos: Vector2 = original.body_position+Vector2(0,190*(1-original.box_amount))
						var transform: Transform2D = native.get_global_transform_with_canvas()
						check(not native.contains_touch(transform*(box_pos+Vector2(0,-60))),"cardboard panel rejects hits")
						check(not native.contains_touch(transform*(box_pos+Vector2(-112,-141))),"cardboard flap rejects hits")
						if original.box_amount > .85:
							for x in [-28,28]: check(native.contains_touch(transform*(box_pos+Vector2(x,-148))),"peek eye wins before cardboard")
						else:
							check(not native.contains_touch(transform*(box_pos+Vector2(-28,-148))),"hidden peek eye has no priority")
						if time == .08:
							check(native.contains_touch(transform*(native.body_position+Vector2(0,-100))),"exposed body remains pokeable")
					if rendered:
						native.breathing.hide()
						await RenderingServer.frame_post_draw
						check(views[0].get_texture().get_image().get_data() == views[1].get_texture().get_image().get_data(),"prop layers match source pixels")
						prop_cases += 1
						native.breathing.show()
				for actor in [original,native]:
					actor.scale = Vector2.ONE
					actor.position = Vector2.ZERO
	for which in [Original.Reaction.BOX,Original.Reaction.RUN]:
		for touch in [false,true]:
			reset(native)
			native.begin_reaction(which,native.body_position)
			seek_pose(native,1.2 if which == Original.Reaction.BOX else 2.87)
			var point: Vector2 = native.body_position+Vector2(28,-148) if which == Original.Reaction.BOX else native.body_position+Vector2(0,-73)
			var elapsed_before: float = native.elapsed
			poke(views[1],point,touch)
			check(native.annoyance > 0 and native.reaction == which and native.elapsed == elapsed_before,"routed poke applies without restarting BOX or RUN")
	reset(native)
	native.begin_reaction(Original.Reaction.SIGN,native.body_position)
	seek_pose(native,.5)
	native.begin_reaction(Original.Reaction.BLINK,native.body_position)
	check(not native.props.visible,"interruption clears SIGN foreground")
	native.use_adobe_reactions = false
	native.begin_reaction(Original.Reaction.BOX,native.body_position)
	seek_pose(native,1.2)
	check(not native.visual.visible and not native.props.visible and native.contains_touch(native.body_position+Vector2(28,-148)),"fallback keeps original prop hit behavior")
	var report := {"checks":checks,"failures":failures,"exact_rendered_prop_cases":prop_cases,"widths":[360,720]}
	var path := "res://test-output/sign-box-run-render.json" if rendered else "res://test-output/sign-box-run-tests.json"
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	for view in views: view.free()
	await process_frame
	print("SIGN_BOX_RUN_TESTS ",JSON.stringify(report))
	quit(0 if failures == 0 else 1)
