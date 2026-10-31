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

class PhraseCanvas extends Node2D:
	var face: Font
	var text := ""
	var baseline := Vector2.ZERO
	func _draw() -> void:
		# A two-pixel authoring outline is 0.29px at the 23px caption size,
		# keeping fine handwritten strokes readable after downsampling.
		draw_string_outline(face, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, BASE_SIZE, 2, Color.WHITE)
		draw_string(face, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, BASE_SIZE, Color.WHITE)

func _initialize() -> void:
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
	var code := "extends RefCounted\n## Generated complete-phrase graphics. No Ink Free font/glyph atlas is distributed.\nconst BASE_SIZE := %d.0\nconst PADDING := %d.0\nconst PHRASES := {\n" % [BASE_SIZE, PADDING]
	for index in range(PHRASES.size()):
		var phrase: String = PHRASES[index]
		var advance := face.get_string_size(phrase, HORIZONTAL_ALIGNMENT_LEFT, -1, BASE_SIZE).x
		var ascent := face.get_ascent(BASE_SIZE)
		var descent := face.get_descent(BASE_SIZE)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(ceili(advance) + PADDING * 2, ceili(ascent + descent) + PADDING * 2)
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var label := PhraseCanvas.new()
		label.face = face
		label.text = phrase
		label.baseline = Vector2(PADDING, PADDING + ascent)
		viewport.add_child(label)
		await process_frame
		await RenderingServer.frame_post_draw
		var filename := "phrase-%02d.png" % index
		var error := viewport.get_texture().get_image().save_png("res://assets/typography/" + filename)
		if error != OK:
			printerr("Phrase save failed: ", filename)
			quit(1)
			return
		code += "\t%s: {\"texture\": preload(\"res://assets/typography/%s\"), \"advance\": %.4f, \"ascent\": %.4f},\n" % [JSON.stringify(phrase), filename, advance, ascent]
		viewport.queue_free()
	code += "}\n"
	var file := FileAccess.open("res://assets/typography/phrases.gd", FileAccess.WRITE)
	file.store_string(code)
	print("Rendered 10 complete Ink Free phrases. No font file or individual-glyph atlas included.")
	quit()
