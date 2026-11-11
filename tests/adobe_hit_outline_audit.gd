extends SceneTree
## Historical baseline versus the now-approved active idle correction.
const Native = preload("res://scripts/blob_animationplayer.gd")
const Original = preload("res://scripts/blob.gd")
var max_actual_gap := 0.0
var max_scale_only_gap := 0.0
var max_wobble_only_gap := 0.0
var false_hits := 0
var missed_hits := 0
var candidate_mismatches := 0
var probes := 0
var active_mismatches := 0

func _initialize() -> void:
	run.call_deferred()

func boundary_gap(a: PackedVector2Array,b: PackedVector2Array) -> float:
	var maximum := 0.0
	for point in a:
		var closest := INF
		for i in range(b.size()):
			closest = minf(closest,point.distance_to(Geometry2D.get_closest_point_to_segment(point,b[i],b[(i+1)%b.size()])))
		maximum = maxf(maximum,closest)
	return maximum

func symmetric_gap(a: PackedVector2Array,b: PackedVector2Array) -> float:
	return maxf(boundary_gap(a,b),boundary_gap(b,a))

func run() -> void:
	root.size = Vector2i(720,1280)
	var actor = Native.new()
	root.add_child(actor)
	actor.set_process(false)
	actor.audio_manager.muted = true
	actor.clock = 0
	actor._update_pose()
	var baseline = Original.new()
	root.add_child(baseline)
	baseline.set_process(false)
	baseline.audio_manager.muted = true
	var resting: PackedVector2Array = actor._silhouette()
	var body: Node2D = actor.visual.get_node("Breathing")
	for phase in range(180):
		actor.clock = phase/60.0
		actor._update_pose()
		baseline.clock = actor.clock
		baseline._update_pose()
		var visual_transform := body.get_global_transform_with_canvas()
		var old_transform := Transform2D(actor.body_angle,actor.body_scale,0,actor.body_position)
		var visible_polygon: PackedVector2Array = visual_transform*resting
		var old_polygon: PackedVector2Array = old_transform*actor._silhouette()
		max_actual_gap = maxf(max_actual_gap,symmetric_gap(visible_polygon,old_polygon))
		max_scale_only_gap = maxf(max_scale_only_gap,symmetric_gap(visible_polygon,old_transform*resting))
		max_wobble_only_gap = maxf(max_wobble_only_gap,symmetric_gap(visible_polygon,visual_transform*actor._silhouette()))
		for i in range(visible_polygon.size()):
			var tangent := visible_polygon[(i+1)%80]-visible_polygon[(i+79)%80]
			var normal := Vector2(tangent.y,-tangent.x).normalized()
			for offset in [-.75,.75]:
				var point: Vector2 = visible_polygon[i]+normal*float(offset)
				var expected := Geometry2D.is_point_in_polygon(point,visible_polygon)
				var existing: bool = baseline.contains_touch(point)
				if actor.contains_touch(point) != expected: active_mismatches += 1
				var candidate := Geometry2D.is_point_in_polygon(visual_transform.affine_inverse()*point,resting)
				if existing and not expected: false_hits += 1
				if expected and not existing: missed_hits += 1
				if candidate != expected: candidate_mismatches += 1
				probes += 1
	var result := {"phases_at_60hz":180,"edge_probes":probes,"probe_offset_logical_pixels":.75,"baseline_false_hits":false_hits,"baseline_missed_hits":missed_hits,"matching_outline_mismatches":candidate_mismatches,"active_idle_hit_mismatches":active_mismatches,"maximum_baseline_symmetric_vertex_to_segment_distance":max_actual_gap,"scale_timing_only_distance":max_scale_only_gap,"contour_wobble_only_distance":max_wobble_only_gap,"correction_activated_in_experiment_only":true,"note":"Edge-focused diagnostic counts are not player error rates or pixel-area percentages. Boundary distance is sampled at polygon vertices; texture antialiasing is excluded."}
	var report := FileAccess.open("res://test-output/hit-outline-audit.json",FileAccess.WRITE)
	report.store_string(JSON.stringify(result,"\t"))
	print("HIT_OUTLINE_AUDIT ",JSON.stringify(result))
	actor.free()
	baseline.free()
	await process_frame
	quit(0 if candidate_mismatches == 0 and active_mismatches == 0 else 1)
