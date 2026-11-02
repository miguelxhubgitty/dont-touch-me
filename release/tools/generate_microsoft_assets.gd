extends SceneTree
## Offline authoring only. Run inside an isolated, byte-verified Alpha checkout.
## No installed fonts, fallback main, image resizing, network or gameplay edits.
const Blob = preload("res://scripts/blob.gd")
const Typography = preload("res://scripts/typography.gd")
var output := ""
var receipt: Array[Dictionary] = []

class KeyArt extends Node2D:
	var pixels := Vector2.ZERO
	var title_size := 96
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, pixels), Color("f6f2e9"))
		var text := "Don't Touch Me"
		var width := Typography.width(text, title_size, true)
		Typography.draw_text(self, text, Vector2((pixels.x - width) * 0.5, pixels.y * 0.18), title_size, Color("202124"), true)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.has("--visual-review-only") or not args.has("--output"):
		printerr("Use -- --visual-review-only --output ABSOLUTE_DIRECTORY; no approval or upload is performed.")
		quit(1)
		return
	output = args[args.find("--output") + 1]
	if not output.is_absolute_path():
		quit(1)
		return
	call_deferred("run")

func save_capture(viewport: SubViewport, filename: String, kind: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := viewport.get_texture().get_image()
	picture.convert(Image.FORMAT_RGB8)
	if picture.save_png(output.path_join(filename)) != OK:
		push_error("Cannot save " + filename)
		quit(1)
		return
	receipt.append({"filename": filename, "dimensions": [picture.get_width(), picture.get_height()], "kind": kind, "post_capture_resize": false})
	viewport.free()

func screenshot(situation: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(2160, 3840)
	viewport.size_2d_override = Vector2i(720, 1280)
	viewport.size_2d_override_stretch = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var blob := Blob.new()
	viewport.add_child(blob)
	blob.set_process(false)
	blob.rng.seed = 472
	blob.clock = 1.1
	blob.intro_alpha = 1.0 if situation == "01-calm" else 0.0
	match situation:
		"02-annoyed":
			blob.annoyance = 42
			blob.begin_reaction(Blob.Reaction.SERIOUSLY, blob.body_position + Vector2(-20, -70))
			blob.elapsed = 0.65
		"03-angry":
			blob.annoyance = 75
			blob.begin_reaction(Blob.Reaction.STOP, blob.body_position + Vector2(-20, -70))
			blob.elapsed = 0.6
		"04-hiding":
			blob.annoyance = 95
			blob.begin_reaction(Blob.Reaction.BOX, blob.body_position + Vector2(-20, -70))
			blob.elapsed = 1.2
		"05-sleeping":
			for frame in range(300):
				blob.advance(0.1)
	blob._update_pose()
	blob.queue_redraw()
	await save_capture(viewport, situation + "-2160x3840.png", "screenshot")

func key_art(filename: String, pixels: Vector2i, title_size: int, blob_scale: float, anchor_ratio: float) -> void:
	var viewport := SubViewport.new()
	viewport.size = pixels
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	if title_size > 0:
		var art := KeyArt.new()
		art.pixels = Vector2(pixels)
		art.title_size = title_size
		viewport.add_child(art)
	var blob := Blob.new()
	viewport.add_child(blob)
	blob.set_process(false)
	blob.intro_alpha = 0
	blob.clock = 0.8
	blob.scale = Vector2.ONE * blob_scale
	blob.anchor = Vector2(float(pixels.x) * 0.5 / blob_scale, float(pixels.y) * anchor_ratio / blob_scale)
	blob._update_pose()
	blob.gaze = Vector2(-8, 0)
	blob.queue_redraw()
	await save_capture(viewport, filename, "key_art")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	if not Typography.TITLE_FONT.get_font_name().begins_with("Space Grotesk") or Typography.Phrases.BASE_SIZE != 160.0:
		push_error("Approved Alpha typography required")
		quit(1)
		return
	for situation in ["01-calm", "02-annoyed", "03-angry", "04-hiding", "05-sleeping"]:
		await screenshot(situation)
	await key_art("poster-1440x2160.png", Vector2i(1440, 2160), 112, 4.1, 0.64)
	await key_art("box-2160x2160.png", Vector2i(2160, 2160), 144, 5.0, 0.65)
	# Microsoft hero specification forbids title, dialogue and any other text.
	await key_art("hero-3840x2160.png", Vector2i(3840, 2160), 0, 7.0, 0.72)
	# Rasterize original vector directly at final pixels, never shrink a small PNG.
	var svg := Image.new()
	var error := svg.load_svg_from_string(FileAccess.get_file_as_string("res://icon.svg"), 300.0 / 512.0)
	if error != OK:
		quit(error)
		return
	var tile := Image.create(300, 300, false, Image.FORMAT_RGBA8)
	tile.fill(Color("f6f2e9"))
	svg.convert(Image.FORMAT_RGBA8)
	tile.blend_rect(svg, Rect2i(0, 0, 300, 300), Vector2i.ZERO)
	tile.convert(Image.FORMAT_RGB8)
	error = tile.save_png(output.path_join("tile-300x300.png"))
	if error != OK:
		quit(error)
		return
	receipt.append({"filename": "tile-300x300.png", "dimensions": [300, 300], "kind": "vector_icon", "post_capture_resize": false})
	var file := FileAccess.open(output.path_join("render-receipt.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine": Engine.get_version_info().string, "assets": receipt, "human_approval": false}, "\t"))
	file.close()
	print("Rendered 9 Microsoft candidates directly at target pixels. Human approval PENDING; no upload.")
	quit()
