extends SceneTree
const Native = preload("res://scripts/blob_animationplayer.gd")
var results: Array = []
var failures := 0
var probes := 0

func _initialize() -> void:
	run.call_deferred()

func shake_peak(half_cycle: int) -> float:
	# Exact extrema of sin(22*PI*u)*sin(PI*u), not just a frame sample.
	var lo := half_cycle/22.0
	var hi := (half_cycle+1)/22.0
	for iteration in range(40):
		var mid := (lo+hi)*.5
		var a := 22*cos(22*PI*lo)*sin(PI*lo)+sin(22*PI*lo)*cos(PI*lo)
		var b := 22*cos(22*PI*mid)*sin(PI*mid)+sin(22*PI*mid)*cos(PI*mid)
		if a*b > 0: lo = mid
		else: hi = mid
	return (lo+hi)*.5

func distance_to_outline(point: Vector2,polygon: PackedVector2Array) -> float:
	var distance := INF
	for i in range(polygon.size()):
		distance = minf(distance,point.distance_to(Geometry2D.get_closest_point_to_segment(point,polygon[i],polygon[(i+1)%polygon.size()])))
	return distance

class FrozenActor extends Native:
	# The test advances elapsed explicitly, including after OS focus changes.
	func _process(_delta: float) -> void:
		pass

func alpha_edges(image: Image) -> PackedVector2Array:
	var points := PackedVector2Array()
	for y in range(image.get_height()):
		for x in range(image.get_width()-1):
			var a := image.get_pixel(x,y).a
			var b := image.get_pixel(x+1,y).a
			if (a >= .5) != (b >= .5): points.append(Vector2(x+.5+(.5-a)/(b-a),y+.5))
	for x in range(image.get_width()):
		for y in range(image.get_height()-1):
			var a := image.get_pixel(x,y).a
			var b := image.get_pixel(x,y+1).a
			if (a >= .5) != (b >= .5): points.append(Vector2(x+.5,y+.5+(.5-a)/(b-a)))
	return points

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960,960) # Keep the full airborne body inside the audit.
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var actor = FrozenActor.new()
	viewport.add_child(actor)
	actor.set_process(false)
	actor.free_jump_enabled = true
	actor.audio_manager.muted = true
	actor.intro_alpha = 0
	await process_frame
	for which in Native.AUTHORED_REACTIONS:
		if "--jump-only" in OS.get_cmdline_user_args() and which != Native.Reaction.JUMP: continue
		var new_pose: bool = which in [Native.Reaction.FLATTEN,Native.Reaction.TURN,Native.Reaction.STOP]
		var waking: bool = which == Native.Reaction.WAKE
		if "--wake-only" in OS.get_cmdline_user_args() and not waking: continue
		var prop_batch: bool = which in [Native.Reaction.SIGN,Native.Reaction.BOX,Native.Reaction.RUN]
		if "--sign-box-run-only" in OS.get_cmdline_user_args() and not prop_batch: continue
		if "--flatten-turn-stop-only" in OS.get_cmdline_user_args() and not new_pose: continue
		var moving: bool = which in [Native.Reaction.SLIDE,Native.Reaction.JUMP,Native.Reaction.SHAKE]
		for sample in range(19 if which == Native.Reaction.JUMP else (17 if which == Native.Reaction.SHAKE else (15 if moving or new_pose or prop_batch or waking else 7))):
			var size := Vector2i(360,640) if (new_pose or prop_batch or waking) and sample >= 12 else Vector2i(960,960)
			if viewport.size != size:
				viewport.size = size
				await process_frame
				actor._resize()
			var edge_jump: bool = which == Native.Reaction.JUMP and sample >= 15
			actor.scale = Vector2(-.8,1.1) if sample == 4 else Vector2.ONE
			actor.rotation = .12 if sample == 4 else 0
			actor.position = Vector2(680,-30) if sample == 4 else Vector2.ZERO
			actor.reaction = 0
			actor.asleep = false
			actor.clock = .65
			actor.anchor = Vector2(viewport.size.x*.5,viewport.size.y*.58)
			if which == Native.Reaction.RUN: actor.anchor.x = viewport.size.x*(.35 if sample%2 == 0 else .65)
			if edge_jump: actor.anchor.x = 770 if sample%2 == 0 else 190
			actor.origin = actor.anchor
			actor.destination = actor.anchor
			actor._update_pose()
			actor.begin_reaction(which,actor.body_position+Vector2(-20 if sample%2 == 0 else 20,-70))
			var fraction := .3 if sample < 2 else .8
			if which == Native.Reaction.SQUISH: fraction = atan(PI)/(1.5*PI) if sample < 2 else .3/.85
			if sample == 5: fraction = actor.audio_manager.marker_position("expression")
			if sample == 6:
				var accent_time: float = {Native.Reaction.BLINK:4.0/30,Native.Reaction.SIDE_EYE:.2,Native.Reaction.SQUISH:atan(PI)/(1.5*PI)*.85,Native.Reaction.IRRITATED:7.0/30,Native.Reaction.DONT:.2,Native.Reaction.SERIOUSLY:7.0/30,Native.Reaction.SLIDE:7.0/30,Native.Reaction.JUMP:7.0/30,Native.Reaction.SHAKE:7.0/30,Native.Reaction.FLATTEN:1.65/7,Native.Reaction.TURN:1.8/14,Native.Reaction.STOP:.2,Native.Reaction.SIGN:2.0/7,Native.Reaction.BOX:2.7/7,Native.Reaction.RUN:2.6,Native.Reaction.WAKE:.4125}[which]
				fraction = accent_time/float(Native.DURATIONS[which])
			if sample >= 7 and sample < 15: fraction = [0,.05,.1,.4,.5,2.0/3,.9,.99][sample-7]
			if new_pose and sample >= 12: fraction = [1.0/14,.5,13.0/14][sample-12]
			if which == Native.Reaction.SHAKE and sample >= 15: fraction = shake_peak(10+sample-15)
			if which == Native.Reaction.JUMP and sample >= 7 and sample < 15:
				# Contact, peak squash, recovery and constant-speed flight samples.
				fraction = [0,.1,.425,.7,.84,.85,26.5/30,28.0/30][sample-7]/1.05
			if waking and sample >= 7:
				fraction = [0,1.0/30,.60,.825,26.0/30,.9075,1.3,1.649][sample-7]/1.65
			actor.elapsed = float(Native.DURATIONS[which])*fraction
			actor.clock = .65+actor.elapsed
			actor._update_pose()
			if edge_jump:
				actor.elapsed = 0
				actor.advance(.85 if sample == 15 else (26.5/30 if sample == 16 else 1.35))
			# Body-only contour audit; adobe_bubble_render.gd checks bubbles.
			actor.bubble = ""
			actor.bubble_drawer.hide()
			actor.props.hide()
			actor.box_amount = 0
			actor.queue_redraw()
			await RenderingServer.frame_post_draw
			var image := viewport.get_texture().get_image()
			var polygon: PackedVector2Array = actor.breathing.get_global_transform_with_canvas()*actor.idle_outline
			var maximum := 0.0
			var contour := alpha_edges(image)
			for point in contour: maximum = maxf(maximum,distance_to_outline(point,polygon))
			for y in range(0,image.get_height(),8):
				for x in range(0,image.get_width(),8):
					var point := Vector2(x+.5,y+.5)
					if distance_to_outline(point,polygon) <= 1: continue
					if actor.contains_touch(point) != (image.get_pixel(x,y).a >= .5):
						failures += 1
						printerr("RENDER_PIXEL_MISMATCH reaction=",which," sample=",sample," point=",point," distance=",distance_to_outline(point,polygon)," alpha=",image.get_pixel(x,y).a," hit=",actor.contains_touch(point))
					probes += 1
			var on_screen := false
			for point in polygon:
				if Rect2(Vector2.ZERO, Vector2(viewport.size)).has_point(point):
					on_screen = true
					break
			if (contour.is_empty() and on_screen) or maximum > 1: failures += 1
			results.append({"reaction":Native.AUTHORED_REACTIONS[which],"sample":sample,"elapsed":actor.elapsed,"viewport_width":viewport.size.x,"mirrored_parent":sample == 4,"edge_jump":edge_jump,"returning":actor.jump_returning,"body_x":actor.body_position.x,"alpha50_crossings":contour.size(),"maximum_rendered_alpha50_boundary_distance":maximum})
	var result := {"failures":failures,"pixel_probes_outside_one_pixel_edge_band":probes,"cases":results,"method":"Real transparent SubViewports, rendered alpha=.5 contour crossings versus visible vector hit outline. Includes renderer filtering and low-alpha shadow. One viewport pixel tolerance without gameplay padding."}
	var file := FileAccess.open("res://test-output/reaction-rendered-edge-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	print("RENDERED_EDGE_VALIDATION ",JSON.stringify(result))
	viewport.free()
	await process_frame
	quit(0 if failures == 0 else 1)
