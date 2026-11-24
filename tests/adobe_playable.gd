extends SceneTree
const Game = preload("res://main.tscn")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(720,960)
	var actor = Game.instantiate()
	root.add_child(actor)
	actor.set_process(false)
	actor.set_process_unhandled_input(false)
	actor.audio_manager.muted = true
	await process_frame
	var checks := 0
	var failures := 0 if actor.free_jump_enabled and actor.use_adobe_idle and actor.use_adobe_reactions else 1
	# Polygon2D redraws break on Web in Godot 4.7.2 (godotengine/godot#124726), so the
	# shipping scene must not contain any; the eyes keep the authored shape and colour.
	var pending: Array[Node] = [actor]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		checks += 1
		if node is Polygon2D:
			failures += 1
			printerr("FAIL: Polygon2D in shipping scene: ", node.get_path())
		pending.append_array(node.get_children())
	var authored_art: Node = preload("res://scenes/blob/blob.tscn").instantiate()
	for eye_name in ["Left", "Right"]:
		var source: Polygon2D = authored_art.get_node("Breathing/Eyes/" + eye_name)
		var eye: Node2D = actor.visual.get_node("Breathing/Eyes/" + eye_name)
		checks += 1
		if eye.polygon != source.polygon or eye.color != source.color or eye.position != source.position:
			failures += 1
			printerr("FAIL: replacement eye differs from authored art: ", eye_name)
	authored_art.free()
	for authored in [true,false]:
		actor.use_adobe_idle = authored
		for which in actor.DURATIONS:
			actor.anchor = Vector2(360,600)
			actor.idle_time = 0
			actor._update_pose()
			if which == actor.Reaction.WAKE:
				actor.advance(24)
				actor.touch_at(actor.body_position+Vector2(0,-70))
			else:
				actor.begin_reaction(which,actor.body_position+Vector2(-20,-70))
			checks += 1
			if actor.reaction != which or actor.uses_authored_reaction() != authored or not actor.free_jump_enabled:
				failures += 1
			var duration: float = actor.DURATIONS[which]
			for i in range(60):
				actor.advance(duration/60)
				await process_frame
			actor.advance(.001)
			checks += 1
			if actor.reaction != actor.Reaction.NONE or actor.uses_authored_idle() != authored:
				failures += 1
	print("Playable authored and fallback reaction checks: ",checks," failures: ",failures)
	actor.free()
	quit(0 if failures == 0 else 1)
