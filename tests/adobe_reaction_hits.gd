extends "res://tests/adobe_idle_hits.gd"
## Reuse existing independent geometry, input and state-parity test helpers.
var metrics: Dictionary = {}
var boundary_samples := 0

func reset(actor,t: float = .9) -> void:
	super.reset(actor,t)
	actor.anchor = Vector2(actor.last_size.x*.5,actor.last_size.y*.58)
	actor.origin = actor.anchor
	actor.destination = actor.anchor
	actor.blink_remaining = 0
	actor.blink_timer = 2.5
	actor.gaze_timer = 1
	actor.idle_gaze = Vector2.ZERO
	actor._update_pose()

func measured_boundary_error(actor) -> float:
	var polygon: PackedVector2Array = actor.breathing.get_global_transform_with_canvas()*actor.idle_outline
	var maximum := 0.0
	for i in range(0,80,8):
		var tangent := polygon[(i+1)%80]-polygon[(i+79)%80]
		var normal := Vector2(tangent.y,-tangent.x).normalized()
		var results: Array[float] = []
		for active in [false,true]:
			var lo := -2.0
			var hi := 2.0
			for iteration in range(12):
				var middle := (lo+hi)*.5
				var point: Vector2 = polygon[i]+normal*middle
				var inside: bool = actor.contains_touch(point) if active else independent_inside(point,polygon)
				if inside: lo = middle
				else: hi = middle
			results.append((lo+hi)*.5)
		maximum = maxf(maximum,absf(results[0]-results[1]))
		boundary_samples += 1
	return maximum

func largest_scale(transform: Transform2D) -> float:
	var squared := transform.x.length_squared()+transform.y.length_squared()
	var determinant := transform.determinant()
	return sqrt((squared+sqrt(maxf(0,squared*squared-4*determinant*determinant)))*.5)

func source_alpha_contour(image: Image) -> PackedVector2Array:
	var points := PackedVector2Array()
	for y in range(image.get_height()):
		for x in range(image.get_width()-1):
			var a := image.get_pixel(x,y).a
			var b := image.get_pixel(x+1,y).a
			if (a >= .5) != (b >= .5):
				var t := (.5-a)/(b-a)
				points.append(Vector2(-144,-208)+Vector2(x+.5+t,y+.5)*.5)
	for x in range(image.get_width()):
		for y in range(image.get_height()-1):
			var a := image.get_pixel(x,y).a
			var b := image.get_pixel(x,y+1).a
			if (a >= .5) != (b >= .5):
				var t := (.5-a)/(b-a)
				points.append(Vector2(-144,-208)+Vector2(x+.5,y+.5+t)*.5)
	return points

func native_at(actor,which: int,side: int,t: float,elapsed_value: float) -> void:
	reset(actor,t)
	actor.begin_reaction(which,actor.body_position+Vector2(side*20,-70))
	actor.clock = t+elapsed_value
	actor.elapsed = elapsed_value
	actor._update_pose()

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720,1280)
	viewport.handle_input_locally = true
	root.add_child(viewport)
	var actor = Native.new()
	var baseline = Original.new()
	for value in [actor,baseline]:
		viewport.add_child(value)
		value.set_process(false)
		value.audio_manager.muted = true
	baseline.set_process_unhandled_input(false)
	var image: Image = actor.visual.get_node("Breathing/Body").texture.get_image()
	var contour := source_alpha_contour(image)
	var alpha_gap := 0.0
	for point in contour: alpha_gap = maxf(alpha_gap,pixel_distance(point,actor.idle_outline))
	for which in Native.AUTHORED_REACTIONS:
		var start_edges := edge_checks
		var maximum_scale := 0.0
		var maximum_test_parent_scale := 0.0
		var boundary_error := 0.0
		var duration: float = Original.DURATIONS[which]
		for entry_time in [0,.65,1.7]:
			for side in [-1,1]:
				reset(actor,entry_time)
				actor.begin_reaction(which,actor.body_position+Vector2(side*20,-70))
				var sample_times: Array[float] = []
				for tick in range(int(ceil(duration*60))+1): sample_times.append(minf(tick/60.0,duration-.000001))
				var animation: Animation = actor.player.get_animation(Native.AUTHORED_REACTIONS[which])
				for key in range(animation.track_get_key_count(0)):
					var key_time := minf(animation.track_get_key_time(0,key),duration-.000001)
					var found := false
					for value in sample_times:
						if absf(value-key_time) < .000001: found = true
					if not found: sample_times.append(key_time)
				sample_times.sort()
				for sample_time in sample_times:
					actor.elapsed = sample_time
					actor.clock = entry_time+actor.elapsed
					actor._update_pose()
					actor.box_amount = 0 # Audit the body outline in isolation.
					probe_edges(actor)
					boundary_error = maxf(boundary_error,measured_boundary_error(actor))
					maximum_scale = maxf(maximum_scale,largest_scale(actor.breathing.get_global_transform_with_canvas()))
		for parent_scale in [Vector2(.5,.5),Vector2(1.8,.7),Vector2(-1.2,.9)]:
			actor.scale = parent_scale
			actor.rotation = .23
			actor.position = Vector2(21,-17)
			viewport.canvas_transform = Transform2D(.08,Vector2(13,29))
			for side in [-1,1]:
				for fraction in [.0001,.137,.399,.701,.9999]:
					native_at(actor,which,side,.53,duration*fraction)
					actor.box_amount = 0
					probe_edges(actor)
					maximum_test_parent_scale = maxf(maximum_test_parent_scale,largest_scale(actor.breathing.get_global_transform_with_canvas()))
		actor.scale = Vector2.ONE
		actor.position = Vector2.ZERO
		actor.rotation = 0
		viewport.canvas_transform = Transform2D.IDENTITY
		# Alpha consistency away from the existing raster boundary band.
		native_at(actor,which,-1,.65,duration*.37)
		actor.box_amount = 0
		var transform: Transform2D = actor.breathing.get_global_transform_with_canvas()
		for y in range(0,image.get_height(),8):
			for x in range(0,image.get_width(),8):
				var local := Vector2(-144,-208)+Vector2(x+.5,y+.5)*.5
				if pixel_distance(local,actor.idle_outline) < .75: continue
				var alpha := image.get_pixel(x,y).a
				if alpha > .01 and alpha < .99: continue
				check(actor.contains_touch(transform*local) == (alpha >= .99),"reaction alpha matches outside .75px local band")
				pixel_checks += 1
		# BOX recovery brings a transformed vertex close enough to the test ray for
		# Godot's polygon check and the scalar world oracle to differ by ~.008 px.
		var numeric_tolerance := 0.01 if which == Original.Reaction.BOX else 0.003
		check(boundary_error <= numeric_tolerance, "numeric hit boundary agrees within %s px" % numeric_tolerance)
		metrics[Native.AUTHORED_REACTIONS[which]] = {"edge_checks":edge_checks-start_edges,"measured_numeric_boundary_error":boundary_error,"boundary_search_resolution":4.0/4096,"source_alpha50_max_distance":alpha_gap,"maximum_native_transform_stretch":maximum_scale,"conservative_alpha50_world_distance_bound":alpha_gap*maximum_scale,"parent_transform_alpha50_bound":alpha_gap*maximum_test_parent_scale,"added_hit_padding":0}
	# All legacy reactions and all disabled authored paths keep the exact source method.
	for which in Original.DURATIONS:
		for use_native in [false,true]:
			actor.use_adobe_reactions = use_native
			for value in [actor,baseline]:
				reset(value)
				value.begin_reaction(which,value.body_position+Vector2(-20,-70))
			for fraction in [.1,.5,.9]:
				for value in [actor,baseline]:
					value.elapsed = float(Original.DURATIONS[which])*fraction
					value._update_pose()
				if not use_native or not Native.AUTHORED_REACTIONS.has(which):
					for x in range(-160,161,20):
						for y in range(-210,21,20):
							var point: Vector2 = baseline.body_position+Vector2(x,y)
							check(actor.contains_touch(point) == baseline.contains_touch(point),"procedural fallback/other reaction hit unchanged")
	actor.use_adobe_reactions = true
	await process_frame
	# Actual routed mouse/touch at edges changed by the reaction correction.
	for which in Native.AUTHORED_REACTIONS:
		if which in [Original.Reaction.BOX,Original.Reaction.RUN]: continue # Dedicated interaction suite covers protected reactions.
		for kind in ["mouse","touch"]:
			for want_hit in [true,false]:
				native_at(actor,which,-1,.65,float(Original.DURATIONS[which])*.37)
				reset(baseline,.65)
				baseline.begin_reaction(which,baseline.body_position+Vector2(-20,-70))
				baseline.advance(actor.elapsed)
				var point := changed_edge(actor,baseline,want_hit)
				check(point.is_finite(),"changed reaction edge found")
				var initial_elapsed: float = actor.elapsed
				pointer(viewport,kind,point,true)
				if want_hit:
					check(actor.annoyance > 0 and actor.elapsed == 0,kind+" visible reaction edge interrupts normally")
				else:
					check(actor.annoyance == 0 and actor.elapsed == initial_elapsed,kind+" invisible old edge ignored")
				var annoyance: float = actor.annoyance
				pointer(viewport,kind,point,false)
				check(actor.annoyance == annoyance,"release never repeats poke")
	# Route real events through a rotated/mirrored parent as well as querying it.
	for kind in ["mouse","touch"]:
		actor.scale = Vector2(-.8,1.1)
		actor.rotation = .12
		actor.position = Vector2(680,-30)
		native_at(actor,Native.Reaction.SQUISH,-1,.65,.3)
		var point: Vector2 = actor.breathing.get_global_transform_with_canvas()*Vector2(0,-70)
		pointer(viewport,kind,point,true)
		check(actor.annoyance > 0 and actor.elapsed == 0,kind+" routes through mirrored parent")
		var annoyance: float = actor.annoyance
		pointer(viewport,kind,point,false)
		check(actor.annoyance == annoyance,"mirrored release is not a second poke")
	actor.scale = Vector2.ONE
	actor.rotation = 0
	actor.position = Vector2.ZERO
	# Repeated fast center pokes should preserve state, selection, RNG and audio markers.
	for value in [actor,baseline]: reset(value)
	for tick in range(600):
		if tick < 120 or tick%11 == 0:
			var point: Vector2 = baseline.body_position+Vector2(0,-70)
			check(actor.touch_at(point) == baseline.touch_at(point),"rapid shared hits")
		for value in [actor,baseline]: value.advance(1.0/120)
		same_state(actor,baseline)
	for first in Native.AUTHORED_REACTIONS:
		for second in Original.DURATIONS:
			native_at(actor,first,1,.8,.2)
			actor.begin_reaction(second,actor.body_position+Vector2(-20,-70))
			if Native.AUTHORED_REACTIONS.has(second):
				actor.box_amount = 0
				probe_edges(actor)
			actor.advance(float(Original.DURATIONS[second])+.001)
			check(actor.reaction == 0 and actor.uses_authored_idle(),"native/procedural interruption returns to idle")
			probe_edges(actor)
	var report := {"checks":checks,"failures":failures,"edge_checks":edge_checks,"pixel_alpha_checks":pixel_checks,"boundary_search_samples":boundary_samples,"source_alpha50_samples":contour.size(),"source_alpha50_distance":alpha_gap,"reactions":metrics,"mouse_touch":"SubViewport synthetic events; no physical-device claim","method":"Independent scalar crossing oracle at visible transformed vector edges. Numeric boundary measured with paired 12-step bisections. Alpha50 crossings measured from source texture then bounded by maximum singular stretch; excludes additional screen rasterization/filtering. No hit padding added."}
	var file := FileAccess.open("res://test-output/reaction-hit-validation.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("REACTION_HIT_VALIDATION ",JSON.stringify(report))
	viewport.free()
	await process_frame
	quit(0 if failures == 0 else 1)
