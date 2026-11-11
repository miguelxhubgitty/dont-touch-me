extends SceneTree
## Exercise the actual game scene and routed input, not a preview actor stub.
const Game = preload("res://main.tscn")
const Blob = preload("res://scripts/blob.gd")
var checks := 0
var failures := 0
var samples := 0
var returns := 0
var maximum_vx_error := 0.0
var contact_times: Array[float] = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		if failures < 20: printerr("FAIL: "+message)

func reset(game,x: float) -> void:
	game.reaction = Blob.Reaction.NONE
	game.last_reaction = Blob.Reaction.NONE
	game.jump_returning = false
	game.asleep = false
	game.elapsed = 0
	game.clock = 0
	game.idle_time = 0
	game.annoyance = 0
	game.blink_timer = 2.5
	game.gaze_timer = 1
	game.blink_remaining = 0
	game.anchor = Vector2(x,game.last_size.y*.58)
	game.origin = game.anchor
	game.destination = game.anchor
	game.audio_manager.cancel_reaction()
	game._update_pose()

func poke(viewport: SubViewport,point: Vector2,touch: bool) -> void:
	var event: InputEvent
	if touch:
		var finger := InputEventScreenTouch.new()
		finger.position = point
		finger.pressed = true
		event = finger
	else:
		var mouse := InputEventMouseButton.new()
		mouse.position = point
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = true
		event = mouse
	viewport.push_input(event,true)

func run() -> void:
	var viewport := SubViewport.new()
	viewport.handle_input_locally = true
	root.add_child(viewport)
	var game = Game.instantiate()
	game.free_jump_enabled = true
	viewport.add_child(game)
	game.set_process(false)
	game.audio_manager.muted = true
	for width in [320,360,640,960]:
		viewport.size = Vector2i(width,720)
		await process_frame
		game._resize()
		for x in [30.0,width*.5,width-30.0]:
			for side in [-1,1]:
				reset(game,x)
				game.begin_reaction(Blob.Reaction.JUMP,game.body_position+Vector2(side*20,-70))
				var landing := Vector2(x-side*230,game.anchor.y)
				check(game.origin.x == x and game.destination == landing and game.direction == -side,"unclamped origin, displacement and poke direction")
				var previous_x: float = game.body_position.x
				for tick in range(1,126):
					game.advance(1.0/120)
					var u := minf(tick/120.0/.85,1)
					var expected := Vector2(x-side*230*u,landing.y-700*u*(1-u))
					check(game.body_position.distance_to(expected) < .0001,"ballistic flight or fixed landing")
					if tick <= 102:
						var error := absf((game.body_position.x-previous_x)*120+side*230/.85)
						maximum_vx_error = maxf(maximum_vx_error,error)
						# A 120Hz difference of float32 positions beyond x=1024
						# can quantize velocity by up to 0.01465 px/s.
						check(error < .02,"constant vx through impact")
					previous_x = game.body_position.x
					check(not game.jump_returning,"return waits for landing recovery")
					samples += 1
				game.advance(1.05-game.elapsed)
				check(game.reaction == Blob.Reaction.NONE and game.body_position.distance_to(landing) < .0001,"exact 1.05s endpoint")
				var offscreen: bool = landing.x < 0 or landing.x > width
				check(game.jump_returning == offscreen,"only offscreen landings trigger return")
				if offscreen:
					returns += 1
					for step in range(400):
						if not game.jump_returning: break
						var before: float = game.body_position.x
						game.advance(1.0/120)
						check(absf(game.body_position.x-move_toward(before,width*.5,230/.85/120)) < .0001 and game.body_position.y == landing.y,"smooth grounded return")
					check(not game.jump_returning and game.body_position.x == width*.5,"return restores exact reachable center")
	# Drive actual mouse/touch selection into JUMP from the live scene.
	viewport.size = Vector2i(360,720)
	await process_frame
	game._resize()
	var seed_value := 0
	var probe := RandomNumberGenerator.new()
	for candidate in range(100):
		probe.seed = candidate
		probe.randf_range(7,10)
		if probe.randi_range(0,5) == 0:
			seed_value = candidate
			break
	for touch in [false,true]:
		reset(game,180)
		game.rng.seed = seed_value
		game.annoyance = 60
		poke(viewport,game.body_position+Vector2(-20 if touch else 20,-70),touch)
		check(game.reaction == Blob.Reaction.JUMP,"routed game input selects JUMP")
		game.advance(1.05)
		check(game.jump_returning,"actual game input reaches offscreen return")
		game.advance(.4)
		poke(viewport,game.body_position+Vector2(0,-70),touch)
		check(not game.jump_returning and game.reaction != Blob.Reaction.NONE,"visible returning body can be interrupted")
		game.advance(.01)
		check(not game.jump_returning,"old return never resumes after poke")
	reset(game,180)
	game.begin_reaction(Blob.Reaction.JUMP,game.body_position+Vector2(-20,-70))
	game.advance(1.25)
	check(game.jump_returning and absf(game.body_position.x-(410-.2*230/.85)) < .0001,"large step returns only for post-recovery remainder")
	viewport.size = Vector2i(640,720)
	await process_frame
	game._resize()
	check(not game.jump_returning and game.body_position.x == 320,"resize cancels return/recenters")
	# Actual landing audio signal in the real controller, including suppression.
	game.audio_manager.muted = false
	game.audio_manager.set_focused(true) # The test owns focus during its synchronous cue checks.
	game.audio_manager.event_played.connect(func(id):
		if id == "jump.land": contact_times.append(game.elapsed))
	reset(game,320)
	game.begin_reaction(Blob.Reaction.JUMP,game.body_position)
	game.advance(.84)
	check(contact_times.is_empty(),"no pre-contact cue")
	game.advance(.01)
	check(contact_times.size() == 1 and absf(contact_times[0]-.85) < .000001,"actual cue at .85s contact")
	game.advance(.2)
	check(contact_times.size() == 1,"no end replay")
	reset(game,320)
	game.begin_reaction(Blob.Reaction.JUMP,game.body_position)
	game.advance(.4)
	game.begin_reaction(Blob.Reaction.SLIDE,game.body_position)
	game.advance(.7)
	check(contact_times.size() == 1 and not game.jump_returning,"interrupted jump cannot land or return")
	game.audio_manager.muted = true
	reset(game,320)
	game.begin_reaction(Blob.Reaction.JUMP,game.body_position)
	game.advance(.85)
	check(game.audio_manager.fired.has("jump.land") and contact_times.size() == 1,"muted contact consumed without playback")
	game.audio_manager.muted = false
	game.audio_manager.set_focused(false)
	reset(game,320)
	game.begin_reaction(Blob.Reaction.JUMP,game.body_position)
	game.advance(.85)
	check(game.audio_manager.fired.has("jump.land") and contact_times.size() == 1,"unfocused contact consumed without playback")
	game.audio_manager.set_focused(true)
	game.advance(.2)
	check(contact_times.size() == 1,"focus restoration does not replay contact")
	game.free_jump_enabled = false
	reset(game,320)
	game.begin_reaction(Blob.Reaction.JUMP,game.body_position+Vector2(-20,-70))
	game.advance(.3)
	check(absf(game.body_position.y-(game.origin.y-175*sin(PI*.3/1.05))) < .0001 and game.destination.x == 450,"disabled mode keeps original bounded sine jump")
	var result := {"checks":checks,"failures":failures,"trajectory_samples":samples,"offscreen_returns":returns,"maximum_finite_frame_vx_error":maximum_vx_error,"contact_times":contact_times,"widths":[320,360,640,960],"scope":"Actual main.tscn with opt-in controller; both directions, routed synthetic mouse/touch, unbounded flight, recovery, return, resize/interruption and audio"}
	DirAccess.make_dir_recursive_absolute("res://test-output")
	FileAccess.open("res://test-output/jump-unbounded-controller.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	viewport.free()
	await process_frame
	print("UNBOUNDED_CONTROLLER ",JSON.stringify(result))
	quit(0 if failures == 0 else 1)
