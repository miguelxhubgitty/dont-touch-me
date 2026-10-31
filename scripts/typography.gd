extends RefCounted
## Consistent runtime/marketing typography. Ink Free is supplied as complete
## phrase images, not an embedded font, glyph atlas, or operating-system lookup.
const TITLE_FONT: Font = preload("res://assets/fonts/title.tres")
const BODY_FONT: Font = preload("res://assets/fonts/SpaceGrotesk.ttf")
const Phrases = preload("res://assets/typography/phrases.gd")

static func width(text: String, size: int, title := false) -> float:
	if not title and Phrases.PHRASES.has(text):
		return float(Phrases.PHRASES[text].advance) * size / Phrases.BASE_SIZE
	return (TITLE_FONT if title else BODY_FONT).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

static func draw_text(canvas: CanvasItem, text: String, baseline: Vector2, size: int, color: Color, title := false) -> void:
	if not title and Phrases.PHRASES.has(text):
		var phrase: Dictionary = Phrases.PHRASES[text]
		var texture: Texture2D = phrase.texture
		var scale := float(size) / Phrases.BASE_SIZE
		var offset := Vector2(Phrases.PADDING, float(phrase.ascent) + Phrases.PADDING) * scale
		canvas.draw_texture_rect(texture, Rect2(baseline - offset, Vector2(texture.get_size()) * scale), false, color)
		return
	canvas.draw_string(TITLE_FONT if title else BODY_FONT, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
