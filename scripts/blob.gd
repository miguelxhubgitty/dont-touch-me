extends Node2D
## One clock owns every pose. No asynchronous reactions or overlapping tweens.

enum Reaction { NONE, BLINK, SIDE_EYE, SQUISH, IRRITATED, DONT, SERIOUSLY,
	SLIDE, JUMP, SHAKE, FLATTEN, TURN, STOP, SIGN, BOX, RUN, WAKE }

const INK := Color("202124")
const WHITE := Color("fffdf8")
const MUTED := Color("aaa395")
const PAPER := Color("f6f2e9")
const DURATIONS := {
	Reaction.BLINK: 0.65, Reaction.SIDE_EYE: 1.15, Reaction.SQUISH: 0.85,
	Reaction.IRRITATED: 1.2, Reaction.DONT: 1.25, Reaction.SERIOUSLY: 1.5,
	Reaction.SLIDE: 0.9, Reaction.JUMP: 1.05, Reaction.SHAKE: 1.05,
	Reaction.FLATTEN: 1.65, Reaction.TURN: 1.8, Reaction.STOP: 1.25,
	Reaction.SIGN: 2.0, Reaction.BOX: 2.7, Reaction.RUN: 4.1, Reaction.WAKE: 1.65,
}
const POOLS := [
	[Reaction.BLINK, Reaction.SIDE_EYE, Reaction.SQUISH],
	[Reaction.IRRITATED, Reaction.DONT, Reaction.SERIOUSLY, Reaction.SLIDE],
	[Reaction.JUMP, Reaction.SHAKE, Reaction.FLATTEN, Reaction.TURN, Reaction.STOP, Reaction.SIGN],
	[Reaction.STOP, Reaction.SIGN, Reaction.BOX, Reaction.RUN],
]
const SLEEP_AFTER := 24.0

var rng := RandomNumberGenerator.new()
var annoyance := 0.0
var idle_time := 0.0
var asleep := false
var reaction: int = Reaction.NONE
var last_reaction: int = Reaction.NONE
var elapsed := 0.0
var clock := 0.0
var anchor := Vector2.ZERO
var origin := Vector2.ZERO
var destination := Vector2.ZERO
var body_position := Vector2.ZERO
var body_scale := Vector2.ONE
var body_angle := 0.0
var eye_open := 1.0
var gaze := Vector2.ZERO
var idle_gaze := Vector2.ZERO
var gaze_timer := 1.0
var blink_timer := 2.5
var blink_remaining := 0.0
var turn_amount := 0.0
var box_amount := 0.0
var sign_amount := 0.0
var direction := 1.0
var bubble := ""
var bubble_alpha := 0.0
var touch_flash := 0.0
var intro_alpha := 1.0
var last_size := Vector2.ZERO
var font: Font

func _ready() -> void:
	rng.randomize()
	font = ThemeDB.fallback_font
	_resize()

func _resize() -> void:
	var size := get_viewport_rect().size
	if size == last_size:
		return
	last_size = size
	# A resize cancels the current motion cleanly, including offscreen escape.
	anchor = Vector2(size.x * 0.5, size.y * 0.58)
	origin = anchor
	destination = anchor
	reaction = Reaction.NONE
	_update_pose()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		set_process(false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		set_process(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			touch_at(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		touch_at(event.position)

func _process(delta: float) -> void:
	_resize()
	advance(minf(delta, 0.1))

func advance(delta: float) -> void:
	clock += delta
	idle_time += delta
	intro_alpha = move_toward(intro_alpha, 0.0, delta * 0.1 if idle_time > 5.0 else 0.0)
	touch_flash = maxf(0.0, touch_flash - delta * 5.0)
	if idle_time > 2.5:
		annoyance = maxf(0.0, annoyance - delta * 4.0)
	if reaction != Reaction.NONE:
		elapsed += delta
		if elapsed >= float(DURATIONS[reaction]):
			anchor = destination
			reaction = Reaction.NONE
			elapsed = 0.0
	if idle_time >= SLEEP_AFTER and reaction == Reaction.NONE:
		asleep = true
	blink_timer -= delta
	blink_remaining = maxf(0.0, blink_remaining - delta)
	if blink_timer <= 0.0:
		blink_remaining = 0.17
		blink_timer = rng.randf_range(2.0, 5.0)
	gaze_timer -= delta
	if gaze_timer <= 0.0:
		idle_gaze = Vector2(rng.randf_range(-8, 8), rng.randf_range(-3, 3))
		gaze_timer = rng.randf_range(1.8, 4.0)
	_update_pose()
	queue_redraw()

func tier() -> int:
	if annoyance <= 20.0: return 0
	if annoyance <= 50.0: return 1
	if annoyance <= 80.0: return 2
	return 3

func choose_reaction() -> int:
	var choices: Array = POOLS[tier()].duplicate()
	choices.erase(last_reaction)
	return int(choices[rng.randi_range(0, choices.size() - 1)])

func contains_touch(point: Vector2) -> bool:
	# Test the actual transformed silhouette, never an invisible resting hitbox.
	var local := (point - body_position).rotated(-body_angle) / body_scale
	var polygon := _silhouette()
	return Geometry2D.is_point_in_polygon(local, polygon)

func touch_at(point: Vector2) -> bool:
	if not contains_touch(point):
		return false
	idle_time = 0.0
	intro_alpha = 0.0
	annoyance = minf(100.0, annoyance + rng.randf_range(7.0, 10.0))
	touch_flash = 1.0
	if asleep:
		asleep = false
		begin_reaction(Reaction.WAKE, point)
	elif reaction != Reaction.RUN and reaction != Reaction.BOX:
		# Escapes finish on schedule even under frantic tapping.
		begin_reaction(choose_reaction(), point)
	return true

func begin_reaction(which: int, touch: Vector2) -> void:
	origin = Vector2(clampf(body_position.x, 190.0, last_size.x - 190.0), anchor.y)
	anchor = origin
	destination = origin
	elapsed = 0.0
	reaction = which
	last_reaction = which
	direction = 1.0 if touch.x <= origin.x else -1.0
	if which == Reaction.SLIDE or which == Reaction.JUMP:
		destination.x = clampf(origin.x + direction * 155.0, 190.0, last_size.x - 190.0)
		if absf(destination.x - origin.x) < 35.0:
			direction *= -1.0
			destination.x = clampf(origin.x + direction * 155.0, 190.0, last_size.x - 190.0)
	if which == Reaction.RUN:
		direction = -1.0 if origin.x < last_size.x * 0.5 else 1.0
		destination = Vector2(last_size.x * 0.5, anchor.y)
	_update_pose()

func _ease(value: float) -> float:
	var t := clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _update_pose() -> void:
	body_position = anchor
	var breath := sin(clock * (1.6 if asleep else 2.3))
	body_scale = Vector2(1.0 + breath * 0.018, 1.0 - breath * 0.022)
	body_angle = 0.0
	eye_open = 0.07 if asleep else (0.08 if blink_remaining > 0.0 else 1.0)
	gaze = idle_gaze
	turn_amount = 0.0
	sign_amount = 0.0
	box_amount = 0.0
	bubble = ""
	bubble_alpha = 0.0
	if reaction == Reaction.NONE:
		return
	var t := clampf(elapsed / float(DURATIONS[reaction]), 0.0, 1.0)
	var envelope := sin(PI * t)
	var hold := _ease(t * 7.0) * _ease((1.0 - t) * 7.0)
	bubble_alpha = hold
	match reaction:
		Reaction.BLINK:
			eye_open = 1.0 - 0.96 * pow(sin(PI * t), 2.0)
			body_scale += Vector2(-0.04, 0.06) * envelope
		Reaction.SIDE_EYE:
			gaze = Vector2(-18.0 * direction, -2.0) * hold
			eye_open = 1.0 - 0.4 * hold
			body_angle = -0.06 * direction * envelope
		Reaction.SQUISH:
			var squish := sin(PI * minf(t * 1.5, 1.0)) * exp(-t * 1.5)
			body_scale += Vector2(0.34, -0.38) * squish
		Reaction.IRRITATED:
			eye_open = 1.0 - 0.78 * hold
			gaze = Vector2(0, 4)
			body_angle = sin(t * TAU) * 0.04
		Reaction.DONT:
			bubble = "Don't."
			eye_open = 0.65
			body_angle = -0.055 * envelope
		Reaction.SERIOUSLY:
			bubble = "Seriously?"
			gaze = Vector2(0, -9) * hold
			body_angle = 0.12 * envelope
		Reaction.SLIDE:
			body_position = origin.lerp(destination, _ease(t * 1.5))
			body_scale += Vector2(0.2, -0.12) * envelope
			gaze.x = -direction * 15.0
		Reaction.JUMP:
			body_position = origin.lerp(destination, _ease(t))
			body_position.y -= sin(PI * t) * 175.0
			body_scale += Vector2(-0.14, 0.22) * envelope
			body_angle = direction * 0.18 * envelope
		Reaction.SHAKE:
			body_position.x += sin(t * TAU * 11.0) * 15.0 * envelope
			body_angle = sin(t * TAU * 9.0) * 0.09 * envelope
			eye_open = 0.3
		Reaction.FLATTEN:
			body_scale = Vector2(1.0 + hold * 0.45, 1.0 - hold * 0.78)
			eye_open = 1.0 - hold * 0.55
			bubble = "Can't touch this."
		Reaction.TURN:
			turn_amount = hold
			body_scale.x = 1.0 - sin(PI * hold) * 0.22
		Reaction.STOP:
			bubble = "STOP."
			body_scale += Vector2(0.14, 0.16) * envelope
			eye_open = 0.3 + (1.0 - hold) * 0.7
			body_position.x += sin(t * 70.0) * 4.0 * envelope
		Reaction.SIGN:
			sign_amount = hold
			eye_open = 0.45
			gaze.x = -12.0
		Reaction.BOX:
			box_amount = hold
			body_scale.y = 1.0 - hold * 0.3
			gaze = Vector2(0, -12)
		Reaction.RUN:
			var outside := Vector2(-210.0 if direction < 0 else last_size.x + 210.0, anchor.y)
			if t < 0.23:
				body_position = origin.lerp(outside, _ease(t / 0.23))
				body_scale = Vector2(1.22, 0.83)
				body_angle = direction * 0.2
			elif t < 0.52:
				body_position = outside
			elif t < 0.7:
				var peek := Vector2(45.0 if direction < 0 else last_size.x - 45.0, anchor.y)
				body_position = outside.lerp(peek, _ease((t - 0.52) / 0.18))
				gaze.x = -direction * 18.0
			else:
				var peek := Vector2(45.0 if direction < 0 else last_size.x - 45.0, anchor.y)
				body_position = peek.lerp(destination, _ease((t - 0.7) / 0.3))
				gaze.x = -direction * 12.0
			body_position.y -= absf(sin(t * 55.0)) * 9.0
		Reaction.WAKE:
			bubble = "I was DREAMING."
			body_position.y -= sin(PI * minf(t * 2.0, 1.0)) * 100.0
			body_scale += Vector2(-0.12, 0.24) * envelope
			eye_open = 1.35 if t < 0.55 else 0.4

func _silhouette() -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(80):
		var a := TAU * float(i) / 80.0
		var x := cos(a) * 117.0 * (1.0 + 0.035 * sin(a * 3.0 + clock * 1.1))
		var y := sin(a) * 119.0
		if y > 0.0:
			y *= 0.61
		points.append(Vector2(x, y - 73.0))
	return points

func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(48):
		var a := TAU * float(i) / 48.0
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(points, color)

func _text_center(text: String, center: Vector2, size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, center - Vector2(width * 0.5, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if font == null:
		return
	# Restrained editorial title fades away after the first interaction.
	if intro_alpha > 0.0:
		_text_center("a little personal space, please.", Vector2(last_size.x * 0.5, last_size.y * 0.25), 23, Color(MUTED, intro_alpha))
		_text_center("Don't Touch Me", Vector2(last_size.x * 0.5, last_size.y * 0.25 - 42), 40, Color(INK, intro_alpha))
		_text_center("(especially the little one)", Vector2(last_size.x * 0.5, last_size.y * 0.84), 19, Color(MUTED, intro_alpha * 0.8))
	var height := maxf(0.0, anchor.y - body_position.y)
	_ellipse(Vector2(body_position.x, anchor.y + 5), Vector2(111.0 - minf(height * 0.2, 45), 13), Color(0.35, 0.31, 0.24, 0.075))
	draw_set_transform(body_position, body_angle, body_scale)
	draw_colored_polygon(_silhouette(), INK)
	if turn_amount < 0.97:
		var face_alpha := 1.0 - turn_amount
		for side in [-1.0, 1.0]:
			var eye := Vector2(side * 37.0 + gaze.x, -113.0 + gaze.y)
			var opening := eye_open
			if reaction == Reaction.SERIOUSLY and side < 0:
				opening *= 0.5
			_ellipse(eye, Vector2(13.5 * (1.0 - turn_amount * 0.8), maxf(2.0, 21.0 * opening)), Color(WHITE, face_alpha))
	if turn_amount > 0.1:
		draw_arc(Vector2(0, -105), 21, 0.35, 1.5, 20, Color(0.30, 0.30, 0.31, turn_amount * 0.45), 2.0, true)
	if touch_flash > 0.0:
		for side in [-1.0, 1.0]:
			draw_line(Vector2(side * 136, -143), Vector2(side * (136 + 13 * touch_flash), -151), Color(MUTED, touch_flash), 3.0, true)
	draw_set_transform(Vector2.ZERO)
	if sign_amount > 0.0:
		_draw_sign()
	if box_amount > 0.0:
		_draw_box()
	if bubble != "" and bubble_alpha > 0.0:
		_draw_bubble()
	if asleep:
		for i in range(3):
			var phase := fposmod(clock * 0.35 + float(i) * 0.32, 1.0)
			var pos := body_position + Vector2(76.0 + phase * 38.0, -198.0 - phase * 85.0)
			_text_center("z" if i < 2 else "Z", pos, 19 + i * 5, Color(MUTED, sin(phase * PI) * 0.7))

func _draw_sign() -> void:
	var base := body_position + Vector2(102, -55)
	var top := base + Vector2(30, -115 * sign_amount)
	draw_line(base, top, Color("a68a62"), 7.0, true)
	draw_style_box(_panel(WHITE, 10, Color("d6cec0")), Rect2(top - Vector2(50, 53), Vector2(100, 65)))
	_text_center("NO", top - Vector2(0, 9), 34, INK)
	_ellipse(base, Vector2(18, 12), INK)

func _panel(color: Color, radius: int, border := Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(2 if border.a > 0 else 0)
	style.anti_aliasing = true
	return style

func _draw_box() -> void:
	var pos := body_position + Vector2(0, 190 * (1.0 - box_amount))
	var color := Color("c6a77e")
	draw_style_box(_panel(color, 5, Color("ae8f67")), Rect2(pos + Vector2(-143, -128), Vector2(286, 139)))
	draw_line(pos + Vector2(0, -128), pos + Vector2(0, 10), Color("dfc69f"), 32, true)
	draw_line(pos + Vector2(-143, -126), pos + Vector2(143, -126), Color("997c59"), 3, true)
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-143, -128), pos + Vector2(-162, -161), pos + Vector2(-10, -149), pos + Vector2(0, -128)]), Color("ddc49f"))
	draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -128), pos + Vector2(16, -150), pos + Vector2(158, -158), pos + Vector2(143, -128)]), Color("d5b98e"))
	_text_center("definitely empty", pos + Vector2(-3, -44), 19, Color("826a4c"))
	if box_amount > 0.85:
		for side in [-1.0, 1.0]:
			_ellipse(pos + Vector2(side * 28, -148), Vector2(10, 8), WHITE)

func _draw_bubble() -> void:
	var size := 31 if reaction != Reaction.STOP else 43
	var width := font.get_string_size(bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 54.0
	var center := Vector2(clampf(body_position.x, width * 0.5 + 18, last_size.x - width * 0.5 - 18), maxf(110, body_position.y - 290))
	center.y += (1.0 - bubble_alpha) * 10.0
	var paper := Color(WHITE, bubble_alpha)
	draw_style_box(_panel(paper, 22), Rect2(center - Vector2(width * 0.5, 43), Vector2(width, 78)))
	draw_colored_polygon(PackedVector2Array([center + Vector2(-9, 31), center + Vector2(10, 31), center + Vector2(0, 48)]), paper)
	_text_center(bubble, center + Vector2(0, 7), size, Color(INK, bubble_alpha))
