extends "res://tests/adobe_reactions.gd"
var movement_samples := 0
var edge_samples := 0
var maximum_position_error := 0.0
var pose_cases := 0

func at(actor,which: int,time: float,side: int = -1) -> void:
	reset(actor)
	actor.begin_reaction(which,actor.body_position+Vector2(side*20,-70))
	actor.advance(time)

func run() -> void:
	var viewport := SubViewport.new()
	root.add_child(viewport)
	var a = Native.new()
	var b = Original.new()
	for actor in [a,b]:
		viewport.add_child(actor)
		actor.set_process(false)
		actor.audio_manager.muted = true
	viewport.size = Vector2i(960,960)
	await process_frame
	# Renderer discovered a Godot ray-test false positive ~399px outside SHAKE.
	at(a,Original.Reaction.SHAKE,.315)
	var stray := Vector2(176.5,80.5)
	var stray_local: Vector2 = a.breathing.get_global_transform_with_canvas().affine_inverse()*stray
	check(not a.outline_bounds.has_point(stray_local) and not a.contains_touch(stray),"far outside shake ray-test regression")
	for which in Native.AUTHORED_REACTIONS:
		at(a,which,float(Original.DURATIONS[which])*.3)
		for x in [-400,400]:
			for y in [-500,200]:
				var outside: Vector2 = a.breathing.get_global_transform_with_canvas()*Vector2(x,y)
				check(not a.contains_touch(outside),"exact bounds reject impossible native hits")
	for row in [
		[Original.Reaction.SLIDE,1.0/30,Vector2(1.04,.96),-.02,.85],
		[Original.Reaction.SLIDE,.1,Vector2(1.14,.9),.035,.75],
		[Original.Reaction.SLIDE,7.0/30,Vector2(1.18,.88),.045,.7],
		[Original.Reaction.SLIDE,.6,Vector2(1.06,.96),-.025,.65],
		[Original.Reaction.JUMP,1.0/30,Vector2(1.05,.95),-.02,.85],
		[Original.Reaction.JUMP,7.0/30,Vector2(.9,1.17),.17,1.08],
		[Original.Reaction.JUMP,14.0/30,Vector2(.94,1.08),.18,1.05],
		[Original.Reaction.SHAKE,4.0/30,Vector2(1.025,.98),.1,.3],
		[Original.Reaction.SHAKE,7.0/30,Vector2(1.025,.98),-.1,.3],
		[Original.Reaction.SHAKE,13.0/30,Vector2(1.02,.985),-.075,.3],
		[Original.Reaction.SHAKE,19.0/30,Vector2(1.01,.99),-.045,.3]]:
		for side in [-1,1]:
			at(a,row[0],row[1],side)
			var mirror: float = a.direction if row[0] != Original.Reaction.SHAKE else 1
			check(a.breathing.scale.distance_to(row[2]) < .00001,"approved moving scale key")
			check(absf(a.breathing.rotation-row[3]*mirror) < .00001,"approved roll, mirrored only where intended")
			check(absf(a.eyes.scale.y-row[4]) < .00001,"approved eye key")
			pose_cases += 1
	for row in [[Original.Reaction.SLIDE,20.0/30,22.0/30],[Original.Reaction.JUMP,11.0/30,14.0/30],[Original.Reaction.SHAKE,25.0/30,28.0/30]]:
		at(a,row[0],row[1])
		var scale: Vector2 = a.breathing.scale
		var roll: float = a.breathing.rotation
		var eye: float = a.eyes.scale.y
		for tick in range(1,21):
			a.advance((row[2]-row[1])/20)
			check(a.breathing.scale.distance_to(scale) < .00001 and absf(a.breathing.rotation-roll) < .00001 and absf(a.eyes.scale.y-eye) < .00001,"approved local hold")
	for width in [320,380,640,960]:
		viewport.size = Vector2i(width,960)
		await process_frame
		for actor in [a,b]: actor._resize()
		for which in [Original.Reaction.SLIDE,Original.Reaction.JUMP,Original.Reaction.SHAKE]:
			for start_x in [190.0,width*.5,width-190.0]:
				for side in [-1,1]:
					for actor in [a,b]:
						reset(actor)
						actor.anchor.x = start_x
						actor._update_pose()
						actor.begin_reaction(which,actor.body_position+Vector2(side*20,-70))
					var duration: float = Original.DURATIONS[which]
					var animation: Animation = a.player.get_animation(Native.AUTHORED_REACTIONS[which])
					for track in range(animation.get_track_count()):
						check(not str(animation.track_get_path(track)).begins_with("Breathing:position"),"no native body position tracks")
					for tick in range(int(round(duration*120))+1):
						if tick > 0:
							for actor in [a,b]: actor.advance(1.0/120)
						compare(a,b)
						var expected_position: Vector2 = b.body_position
						maximum_position_error = maxf(maximum_position_error,a.body_position.distance_to(expected_position))
						check(a.visual.position == a.body_position,"model movement applied once")
						if a.uses_authored_visual():
							var transform: Transform2D = a.breathing.get_global_transform_with_canvas()
							for vertex in range(0,80,8):
								var p: Vector2 = a.idle_outline[vertex]
								var normal := Vector2(p.x,p.y+90).normalized()
								for offset in [-.75,.75]:
									var local: Vector2 = p+normal*offset
									check(a.contains_touch(transform*local) == Geometry2D.is_point_in_polygon(local,a.idle_outline),"moving-body edge follows actual transform")
									edge_samples += 1
						movement_samples += 1
					for actor in [a,b]: actor.advance(.00001)
					check(a.reaction == Original.Reaction.NONE and b.reaction == Original.Reaction.NONE,"exact completion")
	# Blink accent is multiplied once, with original minimum, and exit clears it.
	for actor in [a,b]: actor._resize()
	at(a,Original.Reaction.JUMP,7.0/30)
	a.blink_remaining = .1
	a._update_pose()
	check(is_equal_approx(a.eyes.scale.y,2.0/21),"jump keeps natural closed eye minimum")
	a.blink_remaining = 0
	a._update_pose()
	check(is_equal_approx(a.eyes.scale.y,1.08),"jump accent returns after blink")
	reset(a)
	a.blink_remaining = .1
	a._update_pose()
	var closed: float = a.eyes.scale.y
	a.begin_reaction(Original.Reaction.JUMP,a.body_position)
	check(is_equal_approx(a.eyes.scale.y,closed),"jump entry blink is not multiplied twice")
	check(not a.audio_manager.events["jump.voice"].enabled and a.audio_manager.events["jump.land"].enabled and a.audio_manager.events["shake.voice"].enabled,"existing audio enabled states preserved")
	at(a,Original.Reaction.JUMP,.4)
	check(not a.audio_manager.fired.has("jump.land"),"no early landing cue")
	a.begin_reaction(Original.Reaction.BLINK,a.body_position)
	a.advance(1.05)
	check(not a.audio_manager.fired.has("jump.land"),"interrupted jump never lands later")
	at(a,Original.Reaction.JUMP,1.05)
	check(a.audio_manager.fired.has("jump.land"),"landing marker consumed at exact completion")
	var consumed: int = a.audio_manager.fired.size()
	a.advance(.1)
	check(a.audio_manager.fired.size() == consumed,"idle does not replay landing marker")
	var report := {"checks":checks,"failures":failures,"pose_cases":pose_cases,"movement_samples":movement_samples,"moving_edge_probes":edge_samples,"maximum_model_position_difference":maximum_position_error,"widths":[320,380,640,960],"scope":"Both sides, center/edge starting positions, boundary reversal/narrow-width behavior, 120Hz complete movement traces, audio/RNG/state parity, exact keys and local holds, blink composition. No physical touch claim."}
	FileAccess.open("res://test-output/moving-reaction-tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	viewport.free()
	await process_frame
	print("MOVING_REACTION_TESTS ",JSON.stringify(report))
	quit(0 if failures == 0 else 1)
