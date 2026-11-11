extends SceneTree
## Historical legacy-region comparison; not the corrected active reaction hit region.
const Native = preload("res://scripts/blob_animationplayer.gd")

func _initialize() -> void:
	run.call_deferred()

func directed_gap(a: PackedVector2Array,b: PackedVector2Array) -> float:
	var maximum := 0.0
	for point in a:
		var distance := INF
		for i in range(b.size()):
			distance = minf(distance,point.distance_to(Geometry2D.get_closest_point_to_segment(point,b[i],b[(i+1)%b.size()])))
		maximum = maxf(maximum,distance)
	return maximum

func run() -> void:
	root.size = Vector2i(720,1280)
	var actor = Native.new()
	root.add_child(actor)
	actor.set_process(false)
	actor.audio_manager.muted = true
	var results: Dictionary = {}
	for which in Native.AUTHORED_REACTIONS:
		var result := {"duration":Native.DURATIONS[which],"samples":0,"maximum_boundary_gap":0.0,"maximum_corresponding_vertex_distance":0.0,"largest_entry_gap":0.0,"worst_case":{},"comparison_region":"historical procedural region, NOT the active native reaction hit region"}
		for entry_time in [0,.65,1.7]:
			for side in [-1,1]:
				actor.reaction = 0
				actor.clock = entry_time
				actor.asleep = false
				actor._update_pose()
				actor.begin_reaction(which,actor.body_position+Vector2(side*20,-70))
				var count := int(ceil(float(Native.DURATIONS[which])*60))
				for sample in range(count+1):
					var elapsed: float = minf(sample/60.0,float(Native.DURATIONS[which])-.000001)
					actor.elapsed = elapsed
					actor.clock = entry_time+elapsed
					actor._update_pose()
					var visible: PackedVector2Array = actor.breathing.get_global_transform_with_canvas()*actor.idle_outline
					var hit: PackedVector2Array = Transform2D(actor.body_angle,actor.body_scale,0,actor.body_position)*actor._silhouette()
					var gap := maxf(directed_gap(visible,hit),directed_gap(hit,visible))
					if sample == 0: result.largest_entry_gap = maxf(result.largest_entry_gap,gap)
					if gap > result.maximum_boundary_gap:
						result.maximum_boundary_gap = gap
						result.worst_case = {"entry_clock":entry_time,"direction":actor.direction,"elapsed":elapsed,"native_scale":str(actor.breathing.scale),"legacy_scale":str(actor.body_scale)}
					for i in range(80): result.maximum_corresponding_vertex_distance = maxf(result.maximum_corresponding_vertex_distance,visible[i].distance_to(hit[i]))
					result.samples += 1
		results[Native.AUTHORED_REACTIONS[which]] = result
	results["method"] = "Historical comparison only: six entry-clock/direction cases, 60 Hz plus near-endpoint. Native reaction hits now use the displayed fixed outline; use adobe_reaction_hits and adobe_reaction_render_edges for remaining active-hit discrepancies."
	var file := FileAccess.open("res://test-output/reaction-legacy-geometry.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"))
	print("REACTION_GEOMETRY ",JSON.stringify(results))
	actor.free()
	await process_frame
	quit()
