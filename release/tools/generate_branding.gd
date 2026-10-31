extends SceneTree
## Release-only 315:250 cover using the actual game renderer and approved fonts.
const Blob = preload("res://scripts/blob.gd")
const Typography = preload("res://scripts/typography.gd")

class Cover extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 630, 500), Color("f6f2e9"))
		Typography.draw_text(self, "Don't Touch Me", Vector2(36, 89), 52, Color("202124"), true)
		Typography.draw_text(self, "a little personal space, please.", Vector2(39, 131), 24, Color("7f786c"))

func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--finalize-release"):
		printerr("Branding authoring is release-only; pass -- --finalize-release.")
		quit(1)
		return
	call_deferred("run")

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(630, 500)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.add_child(Cover.new())
	var game := Blob.new()
	viewport.add_child(game)
	game.set_process(false)
	game.intro_alpha = 0
	game.anchor = Vector2(315, 409)
	game.clock = 0.8
	game._update_pose()
	game.gaze = Vector2(-8, 0)
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	DirAccess.make_dir_recursive_absolute("res://release/catalog/branding")
	var error := image.save_png("res://release/catalog/branding/itch-cover-630x500.png")
	print("Actual-renderer 630x500 cover: ", error)
	viewport.queue_free()
	quit(error)
