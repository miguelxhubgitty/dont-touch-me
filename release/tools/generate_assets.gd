extends SceneTree
## Run with a real renderer: godot --path . --script release/tools/generate_assets.gd
## Screenshots come from the existing Blob renderer, with no image compositing.
const Blob = preload("res://scripts/blob.gd")
const Fingerprint = preload("res://release/tools/source_fingerprint.gd")
const Typography = preload("res://scripts/typography.gd")
const OUT := "res://release/assets/"
const PAPER := Color("f6f2e9")
var records: Array[Dictionary] = []
var failed := false

class FeatureGraphic extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1024, 500), Color("f6f2e9"))
		Typography.draw_text(self, "Don't Touch Me", Vector2(72, 219), 65, Color("202124"), true)
		Typography.draw_text(self, "a little personal space, please.", Vector2(75, 269), 24, Color("7f786c"))
		Typography.draw_text(self, "A tiny interactive comedy.", Vector2(75, 412), 19, Color("7f786c"))

func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--finalize-release"):
		printerr("Store captures are release-only. See BRANCH_WORKFLOW.md; pass -- --finalize-release after gameplay/text freeze.")
		quit(1)
		return
	call_deferred("run")

func save_image(image: Image, relative: String, kind: String, opaque := true) -> void:
	var path := OUT + relative
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	image.convert(Image.FORMAT_RGB8 if opaque else Image.FORMAT_RGBA8)
	var error := image.save_png(path)
	if error != OK:
		failed = true
		printerr("Image save failed: ", path, " ", error)
	records.append({"file": relative, "width": image.get_width(), "height": image.get_height(), "kind": kind, "opaque": opaque})

func svg_image(path: String, pixels: int, square_background := false) -> Image:
	var svg := FileAccess.get_file_as_string(path)
	if square_background:
		svg = svg.replace(' rx="112"', '')
	var image := Image.new()
	var error := image.load_svg_from_string(svg, float(pixels) / 512.0)
	if error != OK:
		failed = true
		printerr("SVG rasterization failed: ", path)
	return image

func write_text(path: String, content: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failed = true
		return
	file.store_string(content)

func run() -> void:
	root.size = Vector2i(432, 768)
	save_image(svg_image("res://icon.svg", 1024, true), "icons/master-1024.png", "master_icon")
	save_image(svg_image("res://icon.svg", 512, true), "icons/google-play-512.png", "play_icon", false)
	save_image(svg_image("res://icon.svg", 1024, true), "icons/ios/AppIcon.appiconset/AppIcon-1024.png", "ios_icon")
	write_text(OUT + "icons/ios/AppIcon.appiconset/Contents.json", JSON.stringify({"images": [{"filename": "AppIcon-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}], "info": {"author": "xcode", "version": 1}}, "\t"))
	var densities := {"mdpi": [48, 108], "hdpi": [72, 162], "xhdpi": [96, 216], "xxhdpi": [144, 324], "xxxhdpi": [192, 432]}
	for density in densities:
		save_image(svg_image("res://icon.svg", densities[density][0], true), "android/res/mipmap-%s/ic_launcher.png" % density, "android_launcher", false)
		save_image(svg_image("res://assets/icon_foreground.svg", densities[density][1]), "android/res/mipmap-%s/ic_launcher_foreground.png" % density, "android_adaptive_foreground", false)
		save_image(svg_image("res://assets/icon_monochrome.svg", densities[density][1]), "android/res/mipmap-%s/ic_launcher_monochrome.png" % density, "android_monochrome", false)
	write_text(OUT + "android/res/mipmap-anydpi-v26/ic_launcher.xml", '<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/icon_background"/><foreground android:drawable="@mipmap/ic_launcher_foreground"/></adaptive-icon>\n')
	write_text(OUT + "android/res/mipmap-anydpi-v33/ic_launcher.xml", '<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@color/icon_background"/><foreground android:drawable="@mipmap/ic_launcher_foreground"/><monochrome android:drawable="@mipmap/ic_launcher_monochrome"/></adaptive-icon>\n')
	write_text(OUT + "android/res/values/colors.xml", '<?xml version="1.0" encoding="utf-8"?>\n<resources><color name="icon_background">#f6f2e9</color></resources>\n')
	await feature_graphic()
	var targets := {
		"google-play": Vector2i(1080, 1920),
		"iphone-medium-reference": Vector2i(1179, 2556),
		"iphone-large-reference": Vector2i(1320, 2868),
		"ipad-reference": Vector2i(2064, 2752),
	}
	for target in targets:
		for situation in ["01-calm", "02-annoyed", "03-angry", "04-hiding", "05-sleeping"]:
			await capture(target, targets[target], situation)
	var typography_sources := {}
	for source in ["scripts/typography.gd", "assets/typography/phrases.gd", "assets/fonts/SpaceGrotesk.ttf", "assets/fonts/title.tres"]:
		typography_sources[source] = Fingerprint.digest("res://" + source)
	for phrase in Typography.Phrases.PHRASES.values():
		var source: String = phrase.texture.resource_path.trim_prefix("res://")
		typography_sources[source] = Fingerprint.digest("res://" + source)
	write_text(OUT + "manifest.json", JSON.stringify({
		"generated_by": "release/tools/generate_assets.gd",
		"engine": Engine.get_version_info().string,
		"source_script_sha256": Fingerprint.digest("res://scripts/blob.gd"),
		"source_hash_mode": Fingerprint.MODE,
		"typography_sources_sha256": typography_sources,
		"screenshot_provenance": "Actual Blob Node2D rendering in Godot SubViewports on Windows. Deterministic reachable reaction poses; no compositing, captions, fake OS frames, or post-capture resizing. Apple files are dimension-ready reference renders, not verified iOS device captures.",
		"assets": records,
	}, "\t"))
	print("Release assets generated: %d PNGs; failures: %s" % [records.size(), failed])
	quit(1 if failed else 0)

func feature_graphic() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1024, 500)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var graphic := FeatureGraphic.new()
	viewport.add_child(graphic)
	var blob := Blob.new()
	viewport.add_child(blob)
	blob.set_process(false)
	blob.intro_alpha = 0
	blob.anchor = Vector2(801, 343)
	blob.clock = 0.8
	blob._update_pose()
	blob.gaze = Vector2(-11, 0)
	blob.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	save_image(viewport.get_texture().get_image(), "google-play-feature-1024x500.png", "feature_graphic")
	viewport.queue_free()

func capture(target: String, pixels: Vector2i, situation: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = pixels
	# Reproduce the game's expanding reference canvas in the renderer itself.
	var factor := minf(float(pixels.x) / 720.0, float(pixels.y) / 1280.0)
	viewport.size_2d_override = Vector2i(roundi(pixels.x / factor), roundi(pixels.y / factor))
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
	await process_frame
	await RenderingServer.frame_post_draw
	save_image(viewport.get_texture().get_image(), "screenshots/%s/%s.png" % [target, situation], "actual_gameplay_render")
	viewport.queue_free()
