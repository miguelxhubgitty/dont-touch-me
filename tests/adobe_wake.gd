extends "res://tests/adobe_reactions.gd"

func route_poke(viewport: SubViewport, point: Vector2, touch: bool) -> void:
	if touch:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = true
		viewport.push_input(event, true)
	else:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		viewport.push_input(event, true)

func run() -> void:
	var views: Array[SubViewport] = [SubViewport.new(),SubViewport.new()]
	var native = Native.new()
	var source = Original.new()
	var actors := [native,source]
	for i in range(views.size()):
		root.add_child(views[i])
		views[i].add_child(actors[i])
		actors[i].set_process(false)
		actors[i].audio_manager.muted = true
	var times := [1.0/30,4.0/30,.3,.35,.4125,.6,.8,.825,26.0/30,.9075,31.0/30,1.2,1.3]
	var scales := [Vector2(1.045,.945),Vector2(.90,1.20),Vector2(.925,1.15),Vector2(.925,1.15),
		Vector2(.925,1.15),Vector2(.96,1.085),Vector2(.965,1.075),Vector2(.965,1.075),
		Vector2(1.09,.91),Vector2(.99,1.02),Vector2(1.015,.99),Vector2(1.015,.99),Vector2(1.015,.99)]
	for width in [360,720]:
		for view in views:
			view.size = Vector2i(width,720)
		await process_frame
		for actor in actors:
			actor._resize()
		for side in [-1,1]:
			var use_touch: bool = (width == 360) == (side < 0)
			for interrupt_at in [-1.0,.18,.65,1.2]:
				for i in range(actors.size()):
					var actor = actors[i]
					reset(actor)
					actor.advance(24.0)
					check(actor.asleep,"controller enters sleep after inactivity")
					route_poke(views[i],Vector2(10,10),use_touch)
					check(actor.asleep and actor.reaction == Original.Reaction.NONE,"background miss does not wake")
				check(not native.uses_authored_visual(),"procedural sleeper remains visible")
				var sleeping_scale: Vector2 = native.body_scale
				for i in range(actors.size()):
					route_poke(views[i],actors[i].body_position+Vector2(side*20,-70),use_touch)
				compare(native,source)
				check(native.reaction == Original.Reaction.WAKE and not native.asleep,"routed sleeping hit starts WAKE")
				check(native.uses_authored_reaction() and native.breathing.scale.is_equal_approx(sleeping_scale),"matches displayed sleeper at entry")
				check(is_equal_approx(native.eyes.scale.y,1.35) and native.audio_manager.fired.has("wake.voice"),"immediate surprise and start voice marker")
				if interrupt_at >= 0:
					for i in range(actors.size()):
						var actor = actors[i]
						actor.advance(interrupt_at)
						route_poke(views[i],actor.body_position+Vector2(side*20,-70),use_touch)
					compare(native,source)
					check(native.reaction != Original.Reaction.WAKE and not native.asleep,"body poke interrupts WAKE at each phase")
					check(native.audio_manager.active_reaction != "wake" and native.bubble != "I was DREAMING.","interruption clears old audio schedule and bubble")
					continue
				for i in range(times.size()):
					var at: float = times[i]
					# Set the exact absolute time so one-step rounding cannot obscure marker boundaries.
					for actor in actors:
						actor.advance(at-actor.elapsed)
					compare(native,source)
					check(native.breathing.scale.distance_to(scales[i]) < .0003,"approved body key or hold at %.4f" % at)
					check(is_zero_approx(native.breathing.rotation),"upright WAKE")
					check(native.bubble == "I was DREAMING." and native.bubble_alpha == source.bubble_alpha,"original bubble and fade")
					check(is_equal_approx(native.eyes.scale.y,source.eye_open),"exact controller eye expression")
					check(absf(native.anchor.y-native.body_position.y-sin(PI*minf(at*2/1.65,1))*100) < .001,"original hop")
					check(native.contains_touch(native.body_position+Vector2(0,-70)) and not native.contains_touch(Vector2(10,10)),"moving center hits and background misses")
				check(native.audio_manager.events["wake.contact"].enabled and native.audio_manager.events["wake.voice"].enabled,"existing audible cues remain enabled")
				check(not native.audio_manager.events["wake.land"].enabled and not native.audio_manager.events["wake.grumble"].enabled,"later markers remain silent")
				for actor in actors:
					actor.advance(1.65-actor.elapsed)
				check(native.uses_authored_idle() and native.bubble == "","exact completion hands off to idle")
	native.use_adobe_reactions = false
	reset(native)
	native.advance(24.0)
	check(native.touch_at(native.body_position+Vector2(0,-70)),"fallback sleeper accepts poke")
	check(native.reaction == Original.Reaction.WAKE and not native.uses_authored_visual(),"procedural WAKE fallback")
	for view in views:
		view.free()
	print("WAKE_TESTS ",JSON.stringify({"checks":checks,"failures":failures,"widths":[360,720]}))
	quit(0 if failures == 0 else 1)
