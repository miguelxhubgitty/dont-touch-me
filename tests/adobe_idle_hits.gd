extends SceneTree
const Original = preload("res://scripts/blob.gd")
const Native = preload("res://scripts/blob_animationplayer.gd")
var checks := 0
var failures := 0
var edge_checks := 0
var pixel_checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		if failures < 20: printerr("FAIL: "+message)

func reset(actor,t: float = .9) -> void:
	if actor is Native: actor.free_jump_enabled = false
	actor.reaction = 0
	actor.asleep = false
	actor.clock = t
	actor.idle_time = 0
	actor.annoyance = 0
	actor.last_reaction = 0
	actor.elapsed = 0
	actor.origin = actor.anchor
	actor.destination = actor.anchor
	actor.rng.seed = 833
	actor.audio_manager.cancel_reaction()
	actor._update_pose()

func probe_edges(actor) -> void:
	var transform: Transform2D = actor.breathing.get_global_transform_with_canvas()
	var polygon: PackedVector2Array = transform*actor.idle_outline
	for i in range(80):
		var tangent := polygon[(i+1)%80]-polygon[(i+79)%80]
		var normal := Vector2(tangent.y,-tangent.x).normalized()
		for offset in [-.25,.25,-.75,.75,-2,2]:
			var point: Vector2 = polygon[i]+normal*float(offset)
			var reference := independent_inside(point,polygon)
			if reference != Geometry2D.is_point_in_polygon(point,polygon):
				print("WORLD_ORACLE_PRECISION case t=",actor.clock," vertex=",i," offset=",offset," reference=",reference," active=",actor.contains_touch(point)," distance=",pixel_distance(point,polygon))
			check(actor.contains_touch(point) == reference,"active edge t=%.5f vertex=%d offset=%.2f scale=%s canvas=%s point=%s" % [actor.clock,i,float(offset),actor.scale,actor.get_viewport().canvas_transform,point])
			edge_checks += 1

func independent_inside(point: Vector2,polygon: PackedVector2Array) -> bool:
	# Double-precision scalar crossing oracle, independent of Geometry2D's ray.
	var inside := false
	var px := float(point.x)
	var py := float(point.y)
	var previous := polygon.size()-1
	for i in range(polygon.size()):
		var ax := float(polygon[i].x)
		var ay := float(polygon[i].y)
		var bx := float(polygon[previous].x)
		var by := float(polygon[previous].y)
		if (ay > py) != (by > py) and px < (bx-ax)*(py-ay)/(by-ay)+ax:
			inside = not inside
		previous = i
	return inside

func pixel_distance(point: Vector2,polygon: PackedVector2Array) -> float:
	var closest := INF
	for i in range(polygon.size()):
		closest = minf(closest,point.distance_to(Geometry2D.get_closest_point_to_segment(point,polygon[i],polygon[(i+1)%polygon.size()])))
	return closest

func same_state(a,b) -> void:
	for property in ["reaction","annoyance","elapsed","idle_time","asleep","clock","body_position","body_scale","body_angle","gaze","eye_open","last_reaction","direction"]:
		check(a.get(property) == b.get(property),"same accepted-input simulation: "+property)
	check(a.rng.state == b.rng.state,"unchanged RNG consumption")
	for property in ["active_reaction","progress","fired"]:
		check(a.audio_manager.get(property) == b.audio_manager.get(property),"unchanged audio hook: "+property)

func changed_edge(actor,baseline,want_hit: bool) -> Vector2:
	var polygon: PackedVector2Array = actor.breathing.get_global_transform_with_canvas()*actor.idle_outline
	for i in range(80):
		var tangent := polygon[(i+1)%80]-polygon[(i+79)%80]
		var normal := Vector2(tangent.y,-tangent.x).normalized()
		for offset in [-.75,.75]:
			var point: Vector2 = polygon[i]+normal*float(offset)
			if actor.contains_touch(point) == want_hit and baseline.contains_touch(point) != want_hit:
				return point
	return Vector2.INF

func pointer(viewport,kind: String,point: Vector2,down: bool) -> void:
	var event: InputEvent
	if kind == "mouse":
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.position = point
		mouse.pressed = down
		event = mouse
	else:
		var touch := InputEventScreenTouch.new()
		touch.position = point
		touch.pressed = down
		event = touch
	viewport.push_input(event,true)

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720,1280)
	viewport.handle_input_locally = true
	root.add_child(viewport)
	var actor = Native.new()
	viewport.add_child(actor)
	actor.set_process(false)
	actor.audio_manager.muted = true
	var baseline = Original.new()
	viewport.add_child(baseline)
	baseline.set_process(false)
	baseline.set_process_unhandled_input(false)
	baseline.audio_manager.muted = true
	check(actor.idle_outline.size() == 80,"cached fixed source outline")
	check(actor.idle_outline == actor.visual.get_meta("resting_body_outline"),"native scene owns fixed outline")
	for frame in range(180):
		reset(actor,frame/60.0)
		probe_edges(actor)
	for scale_value in [Vector2(.5,.5),Vector2(2,1.5),Vector2(-.85,1.15)]:
		actor.scale = scale_value
		actor.position = Vector2(25,-17)
		actor.rotation = .21
		viewport.canvas_transform = Transform2D(.07,Vector2(21,34))
		for t in [.0001,.471,1.085,2.312,2.999]:
			reset(actor,t)
			probe_edges(actor)
	actor.scale = Vector2.ONE
	actor.position = Vector2.ZERO
	actor.rotation = 0
	viewport.canvas_transform = Transform2D.IDENTITY
	reset(actor)
	actor.breathing.scale = Vector2.ZERO
	check(not actor.contains_touch(actor.breathing.get_global_transform_with_canvas().origin),"collapsed body cannot be hit")
	actor._update_pose()
	# Compare with source PNG alpha away from raster/antialias boundaries.
	var image: Image = actor.visual.get_node("Breathing/Body").texture.get_image()
	for y in range(0,image.get_height(),8):
		for x in range(0,image.get_width(),8):
			var local := Vector2(-144,-208)+Vector2(x+.5,y+.5)*.5
			if pixel_distance(local,actor.idle_outline) < .75: continue
			var alpha := image.get_pixel(x,y).a
			if alpha > .01 and alpha < .99: continue
			for t in [.1,.78,1.04,2.58]:
				reset(actor,t)
				var point: Vector2 = actor.breathing.get_global_transform_with_canvas()*local
				check(actor.contains_touch(point) == (alpha >= .99),"texture alpha agrees outside .75px edge tolerance")
				pixel_checks += 1
	# Preserve reaction/sleep/fallback queries against the actual original class.
	for which in Original.DURATIONS:
		for actor_value in [actor,baseline]:
			reset(actor_value)
			actor_value.begin_reaction(which,actor_value.body_position+Vector2(-20,-70))
		for phase in [.0,.1,.35,.7,.999]:
			for actor_value in [actor,baseline]:
				actor_value.elapsed = float(Original.DURATIONS[which])*float(phase)
				actor_value._update_pose()
			check(not actor.uses_authored_idle() and actor.visual.visible == Native.AUTHORED_REACTIONS.has(which),"reaction selects correct visual without using idle hits")
			for x in range(-180,181,30):
				for y in range(-220,21,30):
					var point: Vector2 = baseline.body_position+Vector2(x,y)
					var expected: bool = baseline.contains_touch(point)
					if Native.AUTHORED_REACTIONS.has(which):
						expected = independent_inside(point,actor.breathing.get_global_transform_with_canvas()*actor.idle_outline)
						var prop_hit: int = baseline._box_hit(point)
						if prop_hit != Original.BoxHit.EXPOSED:
							expected = prop_hit == Original.BoxHit.PEEK
					check(actor.contains_touch(point) == expected,"native hit alignment or unchanged procedural reaction hit")
		for actor_value in [actor,baseline]:
			actor_value.elapsed = float(Original.DURATIONS[which])-.001
			actor_value.advance(.002)
		check(actor.visual.visible and actor.uses_authored_idle(),"reaction completion restores authored idle")
		probe_edges(actor)
	for state in ["sleep","disabled","hidden","missing_outline"]:
		for actor_value in [actor,baseline]: reset(actor_value)
		if state == "sleep":
			for actor_value in [actor,baseline]:
				actor_value.asleep = true
				actor_value._update_pose()
		if state == "disabled": actor.use_adobe_idle = false
		if state == "hidden": actor.visual.hide()
		var saved: PackedVector2Array = actor.idle_outline
		if state == "missing_outline": actor.idle_outline = PackedVector2Array()
		for x in range(-150,151,15):
			for y in range(-210,21,15):
				var point: Vector2 = baseline.body_position+Vector2(x,y)
				check(actor.contains_touch(point) == baseline.contains_touch(point),"unchanged "+state+" hit test")
		actor.idle_outline = saved
		actor.use_adobe_idle = true
	# Input routing uses native mouse/touch events, including down/release behavior.
	await process_frame
	for kind in ["mouse","touch"]:
		reset(actor)
		reset(baseline)
		var inside := changed_edge(actor,baseline,true)
		check(inside.is_finite(),"visible-only edge exists for "+kind+" routing")
		for down in [true,false]:
			pointer(viewport,kind,inside,down)
			if down:
				check(actor.annoyance > 0 and actor.reaction != 0,kind+" routed to poke")
				check(not actor.uses_authored_idle() and actor.reaction != 0,kind+" poke transitions out of authored idle")
			else:
				check(actor.annoyance <= 10,kind+" release does not poke twice")
		reset(actor)
		reset(baseline)
		var miss := changed_edge(actor,baseline,false)
		check(miss.is_finite(),"old-only invisible edge exists for "+kind+" routing")
		pointer(viewport,kind,miss,true)
		pointer(viewport,kind,miss,false)
		check(actor.annoyance == 0 and actor.reaction == 0,"invisible old-only edge is ignored by "+kind)
	# Identical accepted input must preserve selection, timing, audio cues and RNG.
	for actor_value in [actor,baseline]: reset(actor_value)
	for tick in range(1800):
		if tick < 180 and tick%11 == 0 or tick == 1740:
			# At 22% height a poke 70px above the feet is outside FLATTEN.
			# Use a shared interior point to compare the resulting gameplay state.
			var local_y := -15 if baseline.reaction == Original.Reaction.FLATTEN else -70
			var point: Vector2 = baseline.body_position+Vector2(-20,local_y)
			check(actor.touch_at(point) == baseline.touch_at(point),"same center touch acceptance")
		for actor_value in [actor,baseline]: actor_value.advance(1.0/60)
		same_state(actor,baseline)
		if tick == 1700:
			check(actor.asleep and not actor.visual.visible,"sleep transition retains fallback")
		if tick == 1740:
			check(actor.reaction == Original.Reaction.WAKE,"sleep touch retains WAKE")
	viewport.size = Vector2i(1280,720)
	actor._resize()
	check(actor.reaction == 0 and actor.visual.visible,"resize cancels reaction to authored idle")
	probe_edges(actor)
	var result := {"checks":checks,"failures":failures,"edge_checks":edge_checks,"pixel_alpha_checks":pixel_checks,"raster_edge_exclusion_logical_pixels":.75,"mouse_touch":"SubViewport synthetic events; physical touchscreen untested"}
	var report := FileAccess.open("res://test-output/idle-hit-validation.json",FileAccess.WRITE)
	report.store_string(JSON.stringify(result,"\t"))
	print("IDLE_HIT_VALIDATION ",JSON.stringify(result))
	viewport.free()
	await process_frame
	quit(0 if failures == 0 else 1)
