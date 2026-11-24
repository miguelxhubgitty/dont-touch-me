extends SceneTree
## Windows-only authoring step. Render complete phrases, never a glyph atlas.
## The installed Ink Free font is used locally and is NOT copied into the game.
const BASE_SIZE := 160
const PADDING := 16
const PHRASES := [
	"a little personal space, please.", "(especially the little one)",
	"A tiny interactive comedy.", "Don't.", "Seriously?", "Can't touch this.",
	"STOP.", "I was DREAMING.", "NO", "definitely empty",
]
## Phrases whose largest display size needs more than BASE_SIZE to reach the
## 4x release density (BRANCH_WORKFLOW.md). "STOP." is shown at 43 px: 180/43 = 4.19x.
const PHRASE_BASE_SIZES := {"STOP.": 180}

class PhraseCanvas extends Node2D:
	var face: Font
	var text := ""
	var baseline := Vector2.ZERO
	var size := BASE_SIZE
	func _draw() -> void:
		# A two-pixel authoring outline is 0.29px at the 23px caption size,
		# keeping fine handwritten strokes readable after downsampling.
		draw_string_outline(face, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 2, Color.WHITE)
		draw_string(face, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color.WHITE)

## `-- --phrases=A|B` re-renders only those phrases and keeps every other
## cached image and its metrics unchanged. Without it, every phrase renders.
func _selected_phrases() -> Array:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phrases="):
			return arg.trim_prefix("--phrases=").split("|", false)
	return []

func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--finalize-release"):
		printerr("Typography authoring is release-only. See BRANCH_WORKFLOW.md; pass -- --finalize-release after text freeze.")
		quit(1)
		return
	call_deferred("run")

func run() -> void:
	if not OS.get_system_fonts().has("Ink Free"):
		printerr("Install/licence Ink Free on this Windows authoring machine first. No fallback is allowed.")
		quit(1)
		return
	var face := SystemFont.new()
	face.font_names = PackedStringArray(["Ink Free"])
	face.allow_system_fallback = false
	if face.get_font_name() != "Ink Free":
		printerr("Wrong resolved font: ", face.get_font_name())
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://assets/typography")
	var selected := _selected_phrases()
	var cached: Dictionary = {}
	if not selected.is_empty():
		for phrase in selected:
			if phrase not in PHRASES:
				printerr("Unknown phrase: ", phrase)
				quit(1)
				return
		cached = load("res://assets/typography/phrases.gd").PHRASES
	var code := "extends RefCounted\n## Generated complete-phrase graphics. No Ink Free font/glyph atlas is distributed.\nconst BASE_SIZE := %d.0\nconst PADDING := %d.0\nconst PHRASES := {\n" % [BASE_SIZE, PADDING]
	var rendered := 0
	for index in range(PHRASES.size()):
		var phrase: String = PHRASES[index]
		var filename := "phrase-%02d.png" % index
		var base: int = PHRASE_BASE_SIZES.get(phrase, BASE_SIZE)
		var advance: float
		var ascent: float
		if not selected.is_empty() and phrase not in selected:
			# Keep the existing image and metrics exactly.
			var entry: Dictionary = cached[phrase]
			advance = float(entry.advance)
			ascent = float(entry.ascent)
			base = int(entry.get("base", BASE_SIZE))
		else:
			advance = face.get_string_size(phrase, HORIZONTAL_ALIGNMENT_LEFT, -1, base).x
			ascent = face.get_ascent(base)
			var descent := face.get_descent(base)
			var viewport := SubViewport.new()
			viewport.size = Vector2i(ceili(advance) + PADDING * 2, ceili(ascent + descent) + PADDING * 2)
			viewport.transparent_bg = true
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			root.add_child(viewport)
			var label := PhraseCanvas.new()
			label.face = face
			label.text = phrase
			label.size = base
			label.baseline = Vector2(PADDING, PADDING + ascent)
			viewport.add_child(label)
			await process_frame
			await RenderingServer.frame_post_draw
			var error := viewport.get_texture().get_image().save_png("res://assets/typography/" + filename)
			if error != OK:
				printerr("Phrase save failed: ", filename)
				quit(1)
				return
			viewport.queue_free()
			rendered += 1
		var base_field := "" if base == BASE_SIZE else ", \"base\": %d.0" % base
		code += "\t%s: {\"texture\": preload(\"res://assets/typography/%s\"), \"advance\": %.4f, \"ascent\": %.4f%s},\n" % [JSON.stringify(phrase), filename, advance, ascent, base_field]
	code += "}\n"
	var file := FileAccess.open("res://assets/typography/phrases.gd", FileAccess.WRITE)
	file.store_string(code)
	print("Rendered %d of %d complete Ink Free phrases. No font file or individual-glyph atlas included." % [rendered, PHRASES.size()])
	quit()
