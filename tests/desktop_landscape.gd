extends SceneTree

const Game := preload("res://main.tscn")
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func run() -> void:
	var game = Game.instantiate()
	root.add_child(game)
	game.set_process(false)
	var volume = game.get_node("SoundHUD/VolumeButton")
	var sound: Button = game.get_node("SoundHUD/SoundButton")
	volume.panel.show()
	root.size = Vector2i(540, 810)
	await process_frame
	await process_frame
	game._resize()
	for requested in [Vector2i(432, 768), Vector2i(960, 540), Vector2i(1260, 540), Vector2i(810, 108)]:
		game.begin_reaction(game.Reaction.JUMP, game.body_position)
		root.size = requested
		await process_frame
		await process_frame
		game._resize()
		var expected := Vector2i(requested.x, maxi(requested.y, 540))
		check(root.size == expected, "desktop height floor and width at %s" % requested)
		var scale := root.get_final_transform().get_scale()
		check(absf(scale.x - scale.y) < 0.001, "uniform viewport scale at %s" % requested)
		var bounds := root.get_visible_rect()
		check(bounds.encloses(volume.panel.get_global_rect()) and bounds.encloses(sound.get_global_rect()),
			"open panel and Sound stay in bounds at %s" % requested)
		check(not volume.panel.get_global_rect().intersects(sound.get_global_rect()), "HUD controls do not overlap")
		check(game.reaction == game.Reaction.NONE and game.contains_touch(game.body_position + Vector2(0, -60)),
			"resize still resets motion and restores the hitbox at %s" % requested)
	print("Desktop landscape checks: 20; failures: %d" % failures)
	quit(1 if failures else 0)
