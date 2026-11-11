extends SceneTree
const Native = preload("res://scripts/blob_animationplayer.gd")
const Original = preload("res://scripts/blob.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		if failures < 20: printerr("FAIL: "+message)

func reset(actor,t: float = .5) -> void:
	if actor is Native: actor.free_jump_enabled = false
	actor.reaction = 0
	actor.asleep = false
	actor.clock = t
	actor.elapsed = 0
	actor.idle_time = 0
	actor.annoyance = 0
	actor.last_reaction = 0
	# Moving reactions change anchor/destination; reset those test fixtures too.
	actor.anchor = Vector2(actor.last_size.x*.5,actor.last_size.y*.58)
	actor.origin = actor.anchor
	actor.destination = actor.anchor
	actor.blink_remaining = 0
	actor.blink_timer = 2.5
	actor.gaze_timer = 1
	actor.idle_gaze = Vector2.ZERO
	actor.rng.seed = 8127
	actor.audio_manager.cancel_reaction()
	actor._update_pose()

func compare(a,b) -> void:
	for property in ["clock","elapsed","reaction","asleep","idle_time","annoyance","body_position","body_scale","body_angle","gaze","eye_open","direction","last_reaction","origin","destination","blink_remaining","blink_timer","idle_gaze"]:
		check(a.get(property) == b.get(property),"same gameplay: "+property)
	check(a.rng.state == b.rng.state,"same RNG")
	for property in ["active_reaction","progress","fired"]:
		check(a.audio_manager.get(property) == b.audio_manager.get(property),"same audio hook: "+property)

func run() -> void:
	root.size = Vector2i(720,1280)
	var a = Native.new()
	var b = Original.new()
	var other = Native.new()
	for actor in [a,b,other]:
		root.add_child(actor)
		actor.set_process(false)
		actor.audio_manager.muted = true
	check(Native.AUTHORED_REACTIONS.size() == 16,"sixteen approved native reactions")
	var shared_scene: Node2D = Native.VisualScene.instantiate()
	var authored_player: AnimationPlayer = shared_scene.get_node("BreathingPlayer")
	for which in Native.AUTHORED_REACTIONS:
		var name: String = Native.AUTHORED_REACTIONS[which]
		var animation: Animation = a.player.get_animation(name)
		check(animation.length == Original.DURATIONS[which],"exact duration")
		check(is_equal_approx(animation.step,1.0/30),"30 FPS reference")
		check(animation.loop_mode == Animation.LOOP_NONE,"reaction does not loop")
		for track in range(animation.get_track_count()):
			check(animation.track_get_type(track) == Animation.TYPE_BEZIER,"native visual-only Bezier tracks; no audio/method tracks")
			check(is_equal_approx(animation.track_get_key_time(track,animation.track_get_key_count(track)-1),Original.DURATIONS[which]),"fractional-frame exact endpoint")
		check(animation != other.player.get_animation(name),"per-actor resource isolation")
		for side in [-1,1]:
			for actor in [a,b]: reset(actor)
			var entry_scale: Vector2 = a.breathing.scale
			var entry_eye: float = a.eyes.scale.y
			for actor in [a,b]: actor.begin_reaction(which,actor.body_position+Vector2(side*20,-70))
			check(a.uses_authored_reaction() and a.visual.visible,"native reaction selected")
			var expected_eye := maxf(2.0/21,b.eye_open) if which in Native.MODEL_EYE_REACTIONS else entry_eye
			check(a.breathing.scale.is_equal_approx(entry_scale) and is_equal_approx(a.eyes.scale.y,expected_eye),"entry body and source expression")
			compare(a,b)
			var duration: float = Original.DURATIONS[which]
			for tick in range(90):
				for actor in [a,b]: actor.advance(duration/90)
				compare(a,b)
				for x in [-125,-70,0,70,125]:
					var point: Vector2 = b.body_position+Vector2(x,-80)
					if a.reaction != 0 and a.reaction != Original.Reaction.BOX:
						var displayed: Transform2D = a.breathing.get_global_transform_with_canvas()
						check(a.contains_touch(point) == Geometry2D.is_point_in_polygon(displayed.affine_inverse()*point,a.idle_outline),"approved reaction hit follows visible transform")
			for actor in [a,b]: actor.advance(.001)
			check(a.reaction == 0 and a.uses_authored_idle(),"exact completion returns to idle")
			check(is_zero_approx(a.breathing.rotation),"no stale roll after exit")
			check(a.breathing.scale.is_equal_approx(Vector2(a.player.get_animation("breathe").bezier_track_interpolate(0,fposmod(a.clock,3)),a.player.get_animation("breathe").bezier_track_interpolate(1,fposmod(a.clock,3)))),"phase-correct idle on completion")
			# Seek immediately before completion and compare to the authored exit.
			reset(a)
			a.begin_reaction(which,a.body_position+Vector2(side*20,-70))
			a.advance(duration-.00001)
			var before: Vector2 = a.breathing.scale
			a.advance(.00002)
			check(a.breathing.scale.distance_to(before) < .0001,"body exit has no final-frame pop")
	# Native holds and mirrored direction are authored, not old procedural curves.
	reset(a)
	a.begin_reaction(Original.Reaction.BLINK,a.body_position)
	a.advance(.17)
	check(is_equal_approx(a.eyes.scale.y,2.0/21),"BLINK holds minimum eye height")
	a.advance(.04)
	check(is_equal_approx(a.eyes.scale.y,2.0/21),"BLINK hold stays still")
	for side in [-1,1]:
		reset(a)
		a.begin_reaction(Original.Reaction.SIDE_EYE,a.body_position+Vector2(side*20,-70))
		a.advance(.4)
		check(is_equal_approx(a.eyes.position.x,-18*a.direction),"side eye mirrors once")
		check(is_equal_approx(a.breathing.rotation,-.06*a.direction),"side eye roll mirrors once")
		a.advance(.3)
		check(is_equal_approx(a.eyes.position.x,-18*a.direction),"skeptical hold stays still")
	reset(a)
	a.begin_reaction(Original.Reaction.SQUISH,a.body_position)
	a.advance(a.audio_manager.marker_position("squish_rebound")*.85)
	check(a.breathing.scale.distance_to(Vector2(1.217,.758)) < .0001,"squish peak matches existing rebound cue")
	a.advance(.3-a.elapsed)
	check(a.breathing.scale.distance_to(Vector2(.96,1.05)) < .0001,"squish expressive rebound")
	check(not a.audio_manager.events["squish.rebound"].enabled and not a.audio_manager.events["side_eye.voice"].enabled,"disabled sounds stay disabled")
	# Interrupt all pairs, including repeat of the same reaction.
	for first in Native.AUTHORED_REACTIONS:
		for second in Native.AUTHORED_REACTIONS:
			reset(a)
			a.begin_reaction(first,a.body_position+Vector2(-20,-70))
			a.advance(.2)
			var old_scale: Vector2 = a.breathing.scale
			var old_roll: float = a.breathing.rotation
			a.begin_reaction(second,a.body_position+Vector2(20,-70))
			check(a.breathing.scale.is_equal_approx(old_scale) and is_equal_approx(a.breathing.rotation,old_roll),"interrupted pose captured including signed roll")
			check(a.elapsed == 0 and a.visual_reaction == second,"no stale reaction progress")
	for which in Original.DURATIONS:
		reset(a)
		a.begin_reaction(which,a.body_position)
		check(a.visual.visible == Native.AUTHORED_REACTIONS.has(which),"remaining reactions use procedural rendering")
		for fallback in [false,true]:
			a.use_adobe_idle = fallback
			a._update_pose()
			check(a.visual.visible == (fallback and Native.AUTHORED_REACTIONS.has(which)),"master procedural fallback works")
	a.use_adobe_idle = true
	# Random selection/interruptions/sleep/wake remain source-controlled.
	for actor in [a,b]: reset(actor)
	for tick in range(2400):
		if tick < 300 and tick%7 == 0 or tick == 2200:
			var point: Vector2 = b.body_position+Vector2(-20,-70)
			check(a.touch_at(point) == b.touch_at(point),"same center-input acceptance")
		for actor in [a,b]: actor.advance(1.0/60)
		compare(a,b)
	# Original scene resources must still contain neutral first/last keys.
	check(authored_player.get_animation("reaction_side_eye").bezier_track_get_key_value(2,0) == 0,"shared scene template not mutated")
	var result := {"checks":checks,"failures":failures,"native_reactions":Native.AUTHORED_REACTIONS.size(),"texture_count":1}
	var report := FileAccess.open("res://test-output/reaction-tests.json",FileAccess.WRITE)
	report.store_string(JSON.stringify(result,"\t"))
	shared_scene.free()
	for actor in [a,b,other]: actor.free()
	await process_frame
	print("REACTION_TESTS ",JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures == 0 else 1)
