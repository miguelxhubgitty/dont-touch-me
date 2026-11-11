extends "res://tests/adobe_reactions.gd"
## Additional approved-pose, eyelid, bubble and continuity coverage.
func pose(actor,which: int,time: float,side: int = 1) -> void:
	reset(actor)
	actor.begin_reaction(which,actor.body_position+Vector2(side*20,-70))
	actor.advance(time)

func run() -> void:
	root.size = Vector2i(720,1280)
	var actor = Native.new()
	var original = Original.new()
	for value in [actor,original]:
		root.add_child(value)
		value.set_process(false)
		value.audio_manager.muted = true
	var phase: float = actor.audio_manager.marker_position("expression")
	for side in [-1,1]:
		pose(actor,Original.Reaction.IRRITATED,phase*1.2,side)
		check(actor.breathing.scale.distance_to(Vector2(.985,1.025)) < .00001,"irritated expression scale")
		check(is_equal_approx(actor.breathing.rotation,.025) and is_equal_approx(actor.eyes.scale.y,.28),"irritated expression roll/eyes, fixed handedness")
		pose(actor,Original.Reaction.IRRITATED,10.0/30,side)
		check(is_equal_approx(actor.breathing.rotation,-.025),"one corrective sway")
		pose(actor,Original.Reaction.DONT,phase*1.25,side)
		check(is_equal_approx(actor.breathing.rotation,-.055) and is_equal_approx(actor.eyes.scale.y,.65),"dont statement, fixed handedness")
		pose(actor,Original.Reaction.DONT,.2,side)
		check(is_equal_approx(actor.breathing.rotation,-.06),"dont small overshoot")
		pose(actor,Original.Reaction.SERIOUSLY,phase*1.5,side)
		check(is_equal_approx(actor.breathing.rotation,.1) and is_equal_approx(actor.left_eye.scale.y,.5) and is_equal_approx(actor.right_eye.scale.y,1),"seriously fixed-left squint and roll")
		check(actor.eyes.position.distance_to(Vector2(0,-122)) < .00001,"upward question gaze")
		pose(actor,Original.Reaction.SERIOUSLY,7.0/30,side)
		check(is_equal_approx(actor.breathing.rotation,.13) and is_equal_approx(actor.left_eye.scale.y,.45) and is_equal_approx(actor.right_eye.scale.y,1.08),"questioning accent")
	for row in [[Original.Reaction.IRRITATED,13.0/30,28.0/30],[Original.Reaction.DONT,.3,1.25*6/7],[Original.Reaction.SERIOUSLY,10.0/30,1.5*6/7]]:
		pose(actor,row[0],row[1])
		var body: Vector2 = actor.breathing.scale
		var roll: float = actor.breathing.rotation
		var gaze_position: Vector2 = actor.eyes.position
		var eye: float = actor.eyes.scale.y
		var left: float = actor.left_eye.scale.y
		for tick in range(1,51):
			actor.advance((row[2]-row[1])/50)
			check(actor.breathing.scale.distance_to(body) < .00001 and absf(actor.breathing.rotation-roll) < .00001,"genuine body hold")
			check(actor.eyes.position.distance_to(gaze_position) < .0001 and absf(actor.eyes.scale.y-eye) < .00001 and absf(actor.left_eye.scale.y-left) < .00001,"genuine eye hold reaction=%s tick=%s eye=%s left=%s gaze=%s" % [row[0],tick,actor.eyes.scale.y,actor.left_eye.scale.y,actor.eyes.position])
	# Natural blinking cannot shrink the asymmetric eye below 2 logical pixels.
	pose(actor,Original.Reaction.SERIOUSLY,.5)
	actor.blink_remaining = .1
	actor._update_pose()
	check(is_equal_approx(actor.eyes.scale.y*actor.left_eye.scale.y,2.0/21) and is_equal_approx(actor.eyes.scale.y*actor.right_eye.scale.y,2.0/21),"each closed eye retains original minimum")
	actor.blink_remaining = 0
	actor._update_pose()
	check(is_equal_approx(actor.left_eye.scale.y,.5),"asymmetry restored after blink")
	# Entering the question during a blink captures the already visible minimum
	# without applying the blink factor twice.
	reset(actor)
	actor.blink_remaining = .1
	actor._update_pose()
	var closed_left: float = actor.eyes.scale.y*actor.left_eye.scale.y
	actor.begin_reaction(Original.Reaction.SERIOUSLY,actor.body_position)
	check(is_equal_approx(actor.eyes.scale.y*actor.left_eye.scale.y,closed_left),"question entry during natural blink has no eye pop")
	for next in Original.DURATIONS:
		pose(actor,Original.Reaction.SERIOUSLY,.5)
		actor.begin_reaction(next,actor.body_position)
		if next != Original.Reaction.SERIOUSLY:
			check(actor.left_eye.scale == Vector2.ONE and actor.right_eye.scale == Vector2.ONE,"no stale per-eye overrides after interruption")
	pose(actor,Original.Reaction.SERIOUSLY,.5)
	actor.use_adobe_reactions = false
	actor._update_pose()
	check(not actor.visual.visible and actor.left_eye.scale == Vector2.ONE,"procedural fallback clears overrides")
	actor.use_adobe_reactions = true
	for which in [Original.Reaction.DONT,Original.Reaction.SERIOUSLY]:
		for fraction in [.001,.07,1.0/7,.5,6.0/7,.99]:
			for value in [actor,original]: pose(value,which,float(Original.DURATIONS[which])*fraction)
			check(actor.bubble == original.bubble and actor.bubble_alpha == original.bubble_alpha,"original bubble wording and fade envelope")
			check(actor.bubble_drawer.get_index() > actor.visual.get_index(),"bubble drawn after native body")
	check(actor.audio_manager.events["irritated.voice"].enabled and actor.audio_manager.events["dont.voice"].enabled,"approved voices remain enabled")
	check(not actor.audio_manager.events["seriously.voice"].enabled,"seriously voice remains disabled")
	var report := {"checks":checks,"failures":failures,"scope":"Approved second-three poses, genuine holds, fixed handedness, eye clamps/resets, model bubble envelope and foreground order, audio enabled flags"}
	FileAccess.open("res://test-output/next-reaction-tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	for value in [actor,original]: value.free()
	await process_frame
	print("NEXT_REACTION_TESTS ",JSON.stringify(report))
	quit(0 if failures == 0 else 1)
