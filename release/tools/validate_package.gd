extends SceneTree
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	var listing = JSON.parse_string(FileAccess.get_file_as_string("res://release/listing.json"))
	var limits := {"name": 30, "google_play_short": 80, "google_play_full": 4000, "apple_subtitle": 30, "apple_promotional": 170, "apple_description": 4000, "apple_keywords": 100}
	for field in limits:
		check(listing[field].length() > 0 and listing[field].length() <= limits[field], "metadata character limit: " + field)
	check(listing.apple_keywords.to_utf8_buffer().size() <= 100, "Apple keyword byte limit")
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://release/assets/manifest.json"))
	check(manifest.source_script_sha256 == FileAccess.get_sha256("res://scripts/blob.gd"), "screenshots match current gameplay source")
	check(manifest.assets.size() == 39, "complete 39-PNG graphics package")
	var image_preview := Image.create(864, 2400, false, Image.FORMAT_RGB8)
	image_preview.fill(Color("dfd8ca"))
	var columns := ["google-play", "iphone-medium-reference", "iphone-large-reference", "ipad-reference"]
	for asset in manifest.assets:
		var path: String = "res://release/assets/" + asset.file
		check(FileAccess.file_exists(path), "asset exists: " + asset.file)
		var image := Image.load_from_file(path)
		check(image != null and not image.is_empty(), "valid PNG: " + asset.file)
		if image == null or image.is_empty(): continue
		check(image.get_width() == int(asset.width) and image.get_height() == int(asset.height), "pixel dimensions: " + asset.file)
		if asset.opaque:
			check(image.get_format() == Image.FORMAT_RGB8, "opaque RGB PNG: " + asset.file)
		if asset.kind == "play_icon":
			check(image.get_format() == Image.FORMAT_RGBA8, "32-bit Play icon")
			check(FileAccess.get_file_as_bytes(path).size() <= 1024 * 1024, "Play icon below 1 MB")
		if asset.kind == "actual_gameplay_render":
			var parts: PackedStringArray = asset.file.split("/")
			var col := columns.find(parts[1])
			var row := int(parts[2].substr(0, 2)) - 1
			var height := roundi(216.0 * image.get_height() / image.get_width())
			image.resize(216, height, Image.INTERPOLATE_LANCZOS)
			image_preview.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(col * 216, row * 480))
	DirAccess.make_dir_recursive_absolute("res://test-output")
	check(image_preview.save_png("res://test-output/store-capture-contact-sheet.png") == OK, "QA contact sheet saved")
	var gameplay := FileAccess.get_file_as_string("res://scripts/blob.gd")
	for forbidden in ["HTTPRequest", "HTTPClient", "WebSocket", "ENet", "FileAccess", "DirAccess", "OS.execute", "https://", "http://"]:
		check(not gameplay.contains(forbidden), "offline/no-persistence source check: " + forbidden)
	var presets := ConfigFile.new()
	check(presets.load("res://export_presets.cfg") == OK, "export presets load")
	for index in range(3):
		var section := "preset.%d" % index
		check(str(presets.get_value(section, "exclude_filter")).contains("release/*"), "release material excluded from game")
		check(str(presets.get_value(section, "include_filter")).contains("THIRD_PARTY_NOTICES.txt"), "license notices included")
	check(not presets.get_value("preset.2.options", "package/signed"), "AAB preparation cannot claim a production signature")
	check(presets.get_value("preset.2.options", "gradle_build/target_sdk") == "36", "AAB target SDK 36")
	for file in ["PRIVACY_POLICY.md", "STORE_LISTING.md", "DATA_SAFETY.md", "APP_STORE_PRIVACY.md", "CONTENT_RATING.md", "IOS_EXPORT.md", "PUBLISH_PRIVACY.md", "RELEASE_CHECKLIST.md"]:
		check(FileAccess.file_exists("res://release/" + file), "release document: " + file)
	print("Release package checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
