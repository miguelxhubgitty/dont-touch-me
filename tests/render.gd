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
	var ignore := FileAccess.open("res://test-output/.gdignore", FileAccess.WRITE)
	if ignore != null:
		ignore.close()
	var error := sheet.save_png("res://test-output/reactions.png")
	print("Rendered 18 states. Screenshot save: ", error)
	if error != OK:
		quit(error)
		return
	# Render the same longest dialogue at independent phone/tablet aspect ratios.
	var aspects := Image.create(720, 480, false, Image.FORMAT_RGBA8)
	aspects.fill(Color("e6dfd2"))
	var sizes := [Vector2i(720, 1280), Vector2i(720, 1600), Vector2i(960, 1280), Vector2i(720, 1920)]
	for index in range(sizes.size()):
		var viewport := SubViewport.new()
		viewport.size = sizes[index]
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var subject := Blob.new()
		viewport.add_child(subject)
		subject.set_process(false)
		subject.intro_alpha = 0
		subject.begin_reaction(Blob.Reaction.WAKE, subject.body_position)
		subject.elapsed = 0.65
		subject._update_pose()
		subject.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := viewport.get_texture().get_image()
		picture.resize(180, roundi(180.0 * sizes[index].y / sizes[index].x), Image.INTERPOLATE_LANCZOS)
		aspects.blit_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), Vector2i(index * 180, 0))
		viewport.queue_free()
	var aspect_error := aspects.save_png("res://test-output/aspects.png")
	print("Rendered 4 mobile aspect ratios. Screenshot save: ", aspect_error)
	game.queue_free()
	quit(aspect_error)
