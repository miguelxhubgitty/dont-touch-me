extends SceneTree
## Run with a real renderer, never --headless. Outputs a visual contact sheet.
const Blob = preload("res://scripts/blob.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(432, 768)
	var game := Blob.new()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	var sheet := Image.create(216 * 4, 384 * 5, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("f6f2e9"))
	for index in range(18):
		game.asleep = index == 17
		game.intro_alpha = 1.0 if index == 0 else 0.0
		game.anchor = Vector2(game.last_size.x * 0.5, game.last_size.y * 0.58)
		game.reaction = Blob.Reaction.NONE
		game._update_pose()
		if index > 0 and index < 17:
			game.begin_reaction(index, game.body_position + Vector2(-20, -70))
			game.elapsed = float(Blob.DURATIONS[index]) * (0.64 if index == Blob.Reaction.RUN else 0.42)
		game._update_pose()
		game.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		picture.resize(216, 384, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(picture, Rect2i(0, 0, 216, 384), Vector2i((index % 4) * 216, (index / 4) * 384))
	DirAccess.make_dir_recursive_absolute("res://test-output")
	var error := sheet.save_png("res://test-output/reactions.png")
	print("Rendered 18 states. Screenshot save: ", error)
	game.queue_free()
	quit(error)
