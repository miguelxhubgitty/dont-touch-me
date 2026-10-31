extends SceneTree
const Typography = preload("res://scripts/typography.gd")
var failures := 0
var checks := 0

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
	check(Typography.Phrases.PHRASES.size() == 10, "All 10 fixed handwritten phrases are supplied")
	for phrase in Typography.Phrases.PHRASES:
		var entry: Dictionary = Typography.Phrases.PHRASES[phrase]
		var image: Image = entry.texture.get_image()
		check(image != null and not image.is_empty(), "Phrase image loads: " + phrase)
		check(float(entry.advance) > 0 and float(entry.ascent) > 0, "Positive phrase metrics: " + phrase)
		check(image.get_width() > entry.advance and image.get_height() > entry.ascent, "Phrase padding prevents clipping: " + phrase)
		check(image.detect_alpha() != Image.ALPHA_NONE, "Transparent phrase background: " + phrase)
		for size in [19, 23, 24, 31, 34, 43]:
			check(is_equal_approx(Typography.width(phrase, size), float(entry.advance) * size / Typography.Phrases.BASE_SIZE), "Runtime width matches rendered phrase")
	for width in [720, 960]:
		check(Typography.width("Don't Touch Me", 40, true) + 36 < width, "Title fits reference phone/tablet")
		check(Typography.width("a little personal space, please.", 23) + 36 < width, "Handwritten intro fits reference phone/tablet")
	check(not FileAccess.file_exists("res://assets/fonts/Inkfree.ttf"), "No proprietary font file is bundled")
	print("Typography: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
