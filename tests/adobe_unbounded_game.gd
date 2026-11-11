extends "res://tests/adobe_reaction_hits.gd"
const Playable = preload("res://main.tscn")
var routed_pokes := 0
var return_samples := 0

func reset(actor,t: float = .9) -> void:
	super.reset(actor,t)
	actor.free_jump_enabled = true
	actor.jump_returning = false

func run() -> void:
	var viewport := SubViewport.new()
	viewport.handle_input_locally = true
	root.add_child(viewport)
	var game = Playable.instantiate()
	viewport.add_child(game)
	game.set_process(false)
	game.audio_manager.muted = true
	check(game.get_node_or_null("SoundHUD/SoundButton") != null,"actual inherited game includes Sound HUD")
	var probe := RandomNumberGenerator.new()
	var jump_seed := 0
	for candidate in range(100):
		probe.seed = candidate
		probe.randf_range(7,10)
		if probe.randi_range(0,5) == 0:
			jump_seed = candidate
			break
	for width in [360,960]:
		viewport.size = Vector2i(width,720)
		await process_frame
		game._resize()
		for side in [-1,1]:
			reset(game)
			var start_x: float = width*.5 if width == 360 else (770.0 if side < 0 else 190.0)
			game.anchor.x = start_x
			game._update_pose()
			game.annoyance = 60
			game.rng.seed = jump_seed
			var kind := "mouse" if side < 0 else "touch"
			var poke_point: Vector2 = game.body_position+Vector2(side*20,-70)
			pointer(viewport,kind,poke_point,true)
			pointer(viewport,kind,poke_point,false)
			check(game.reaction == Original.Reaction.JUMP and game.direction == -side and game.destination.x == start_x-side*230,"routed game input preserves offscreen direction and distance")
			routed_pokes += 1
			var target: Vector2 = game.destination
			for tick in range(1,63):
				game.advance(1.0/60)
				var u := minf(tick/60.0/.85,1)
				check(game.visual.position == game.body_position and absf(game.body_position.x-(start_x-side*230*u)) < .0001,"native visual follows controller once")
				if tick%3 == 0: probe_edges(game)
			check(game.body_position.is_equal_approx(target) and not game.jump_returning,"finish offscreen recovery before return")
			game.advance(1.05-game.elapsed)
			check(game.jump_returning and game.uses_authored_idle(),"return uses ordinary native idle rendering")
			check(not game.contains_touch(Vector2(start_x,target.y-70)),"no hit at obsolete pre-jump position")
			while game.jump_returning and return_samples < 1000:
				game.advance(1.0/60)
				if return_samples%4 == 0: probe_edges(game)
				return_samples += 1
			check(not game.jump_returning and absf(game.body_position.x-width*.5) < .0001,"uninterrupted auto-return restores on-screen center")
			var reentry: Vector2 = game.body_position+Vector2(0,-70)
			pointer(viewport,kind,reentry,true)
			pointer(viewport,kind,reentry,false)
			check(game.reaction != Original.Reaction.NONE,"routed input works after automatic return")
			routed_pokes += 1
	# Disable authored reactions: the source procedural path still works.
	reset(game)
	game.use_adobe_reactions = false
	game.free_jump_enabled = true
	game.begin_reaction(Original.Reaction.JUMP,game.body_position+Vector2(-20,-70))
	game.advance(.3)
	check(not game.visual.visible and absf(game.body_position.y-(game.origin.y-700*(.3/.85)*(1-.3/.85))) < .0001,"procedural fallback retains approved ballistic motion")
	var report := {"checks":checks,"failures":failures,"edge_queries":edge_checks,"routed_pokes":routed_pokes,"return_samples":return_samples,"widths":[360,960],"scene":"res://main.tscn","scope":"Actual game scene inheritance, native flight/landing/return outlines, both directions, routed synthetic mouse/touch selection and re-entry, preserved procedural fallback"}
	FileAccess.open("res://test-output/jump-unbounded-native.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	viewport.free()
	await process_frame
	print("UNBOUNDED_NATIVE ",JSON.stringify(report))
	quit(0 if failures == 0 else 1)
