extends SceneTree
const Typography = preload("res://scripts/typography.gd")
const Blob = preload("res://scripts/blob.gd")
const Authoring = preload("res://release/tools/generate_typography.gd")
var failures := 0
var checks := 0
var audio_cleanup = preload("res://tests/audio_test_cleanup.gd").new()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr(message)

func _initialize() -> void:
	# The variable source's family metadata includes "Light" at its default axis;
	# the title variation below explicitly selects weight 600.
	check(Typography.TITLE_FONT.get_font_name().begins_with("Space Grotesk"), "Actual title font resolves to Space Grotesk")
	check(Typography.TITLE_FONT.variation_opentype.get(TextServerManager.get_primary_interface().name_to_tag("wght")) == 600.0, "Title uses semibold weight")
	check(Typography.Phrases.PHRASES.size() == Authoring.PHRASES.size(), "Cached phrases match the authoring list")
	for phrase in Authoring.PHRASES:
		check(Typography.Phrases.PHRASES.has(phrase), "Authoring phrase has a cached image: " + phrase)
	# New gameplay dialogue must not silently fall back to a different typeface.
	var game := Blob.new()
	root.add_child(game)
	game.set_process(false)
	for reaction in Blob.DURATIONS:
		game.reaction = Blob.Reaction.NONE
		game.begin_reaction(reaction, game.body_position)
		if not game.bubble.is_empty():
			check(Typography.Phrases.PHRASES.has(game.bubble), "Current gameplay dialogue has handwriting: " + game.bubble)
	game.free()
	var captions := RegEx.new()
	captions.compile('_text_center\\("([^"\\n]+)"')
	for found in captions.search_all(FileAccess.get_file_as_string("res://scripts/blob.gd")):
		var caption: String = found.get_string(1)
		if caption not in ["Don't Touch Me", "z"]:
			check(Typography.Phrases.PHRASES.has(caption), "Current caption/sign has handwriting: " + caption)
	for phrase in Typography.Phrases.PHRASES:
		var entry: Dictionary = Typography.Phrases.PHRASES[phrase]
		var image: Image = entry.texture.get_image()
		check(image != null and not image.is_empty(), "Phrase image loads: " + phrase)
		check(float(entry.advance) > 0 and float(entry.ascent) > 0, "Positive phrase metrics: " + phrase)
		check(image.get_width() > entry.advance and image.get_height() > entry.ascent, "Phrase padding prevents clipping: " + phrase)
		check(image.detect_alpha() != Image.ALPHA_NONE, "Transparent phrase background: " + phrase)
		for size in [19, 23, 24, 31, 34, 43]:
			check(is_equal_approx(Typography.width(phrase, size), float(entry.advance) * size / Typography.base_size(entry)), "Runtime width matches rendered phrase")
	# Release standard: every phrase image is at least 4x its largest display size
	# (BRANCH_WORKFLOW.md). Sizes come from blob.gd and generate_assets.gd.
	var largest := {"a little personal space, please.": 24, "(especially the little one)": 19,
		"A tiny interactive comedy.": 19, "Don't.": 31, "Seriously?": 31, "Can't touch this.": 31,
		"STOP.": 43, "I was DREAMING.": 31, "NO": 34, "definitely empty": 19}
	for phrase in Typography.Phrases.PHRASES:
		check(largest.has(phrase), "Largest display size recorded for: " + phrase)
		var density := Typography.base_size(Typography.Phrases.PHRASES[phrase]) / float(largest.get(phrase, 1))
		check(density >= 4.0, "Phrase meets 4x density (%.2fx): %s" % [density, phrase])
	for width in [720, 960]:
		check(Typography.width("Don't Touch Me", 40, true) + 36 < width, "Title fits reference phone/tablet")
		check(Typography.width("a little personal space, please.", 23) + 36 < width, "Handwritten intro fits reference phone/tablet")
	check(not FileAccess.file_exists("res://assets/fonts/Inkfree.ttf"), "No proprietary font file is bundled")
	_check_hud.call_deferred()

## Release HUD text uses Space Grotesk, including the generated Settings panel.
## Deferred: the scene's _ready (which builds the panel) runs once the tree is live.
func _check_hud() -> void:
	audio_cleanup.attach(self)
	var scene: Node = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	var sound: Button = scene.get_node("SoundHUD/SoundButton")
	var settings: Button = scene.get_node("SoundHUD/VolumeButton")
	var hud: Array[Control] = [sound, settings]
	var pending: Array[Node] = [settings.panel]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is Label or node is Button or node is Range:
			hud.append(node)
		pending.append_array(node.get_children())
	check(hud.size() >= 12, "HUD controls found: %d" % hud.size())
	for control in hud:
		var resolved: Font = control.get_theme_font("font")
		check(resolved != null and resolved.get_font_name().begins_with("Space Grotesk"), "HUD text uses Space Grotesk: " + control.name)
	for text in ["Sound Off", "Sound On", "Settings"]:
		var font: Font = sound.get_theme_font("font")
		check(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 24 < sound.size.x, "HUD label fits its button: " + text)
	print("Typography: %d checks; %d failures" % [checks, failures])
	await audio_cleanup.finish(self, 1 if failures else 0)
