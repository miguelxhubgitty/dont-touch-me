extends "res://scripts/blob.gd"
## Experiment adapter only. Native scene/AnimationPlayer own visual transforms.
const VisualScene = preload("res://scenes/blob/blob.tscn")
const AUTHORED_REACTIONS := {Reaction.BLINK:"reaction_blink",Reaction.SIDE_EYE:"reaction_side_eye",Reaction.SQUISH:"reaction_squish",Reaction.IRRITATED:"reaction_irritated",Reaction.DONT:"reaction_dont",Reaction.SERIOUSLY:"reaction_seriously",Reaction.SLIDE:"reaction_slide",Reaction.JUMP:"reaction_jump",Reaction.SHAKE:"reaction_shake",Reaction.FLATTEN:"reaction_flatten",Reaction.TURN:"reaction_turn",Reaction.STOP:"reaction_stop",Reaction.SIGN:"reaction_sign",Reaction.BOX:"reaction_box",Reaction.RUN:"reaction_run",Reaction.WAKE:"reaction_wake"}
const MODEL_EYE_REACTIONS := [Reaction.FLATTEN, Reaction.TURN, Reaction.STOP, Reaction.SIGN, Reaction.BOX, Reaction.RUN, Reaction.WAKE]
const BubbleDrawer = preload("res://scripts/bubble_foreground.gd")

class Props extends Node2D:
	var actor

	func _draw() -> void:
		if actor.sign_amount > 0:
			actor._draw_sign(self)
		if actor.box_amount > 0:
			actor._draw_box(self)

class TurnDetails extends Node2D:
	var actor

	func _draw() -> void:
		var amount: float = actor.turn_amount
		if amount > .1:
			draw_arc(Vector2(0,-105),21,.35,1.5,20,Color(.30,.30,.31,amount*.45),2,true)
		var flash: float = actor.touch_flash
		if flash > 0:
			for side in [-1.0,1.0]:
				draw_line(Vector2(side*136,-143),Vector2(side*(136+13*flash),-151),Color(actor.MUTED,flash),3,true)
var use_adobe_idle := true
var use_adobe_reactions := true
var visual: Node2D
var player: AnimationPlayer
var eyes: Node2D
var idle_outline := PackedVector2Array()
var outline_bounds := Rect2()
var breathing: Node2D
var visual_reaction := Reaction.NONE
var reaction_templates: Dictionary = {}
var pending_entry: Dictionary = {}
var bubble_drawer: Node2D
var left_eye: Node2D
var right_eye: Node2D
var turn_details: TurnDetails
var props: Props

func _ready() -> void:
	visual = VisualScene.instantiate()
	idle_outline = visual.get_meta("resting_body_outline",PackedVector2Array())
	if not idle_outline.is_empty():
		outline_bounds = Rect2(idle_outline[0],Vector2.ZERO)
		for point in idle_outline: outline_bounds = outline_bounds.expand(point)
	add_child(visual)
	breathing = visual.get_node("Breathing")
	player = visual.get_node("BreathingPlayer")
	# Native resources are editable/shared on disk, but entry/exit keys are local.
	var library := player.get_animation_library("").duplicate(true) as AnimationLibrary
	player.remove_animation_library("")
	player.add_animation_library("",library)
	for name in AUTHORED_REACTIONS.values():
		var animation := player.get_animation(name)
		var tracks: Array = []
		for track in range(animation.get_track_count()):
			var values: Array = []
			for key in range(animation.track_get_key_count(track)):
				values.append(animation.bezier_track_get_key_value(track,key))
			tracks.append(values)
		reaction_templates[name] = tracks
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	player.play("breathe")
	var blink: AnimationPlayer = visual.get_node("BlinkPlayer")
	blink.stop()
	blink.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	eyes = visual.get_node("Breathing/Eyes")
	left_eye = eyes.get_node("Left")
	right_eye = eyes.get_node("Right")
	turn_details = TurnDetails.new()
	turn_details.actor = self
	breathing.add_child(turn_details)
	props = Props.new()
	props.actor = self
	add_child(props)
	bubble_drawer = BubbleDrawer.new()
	add_child(bubble_drawer) # After the native body: same foreground order as source.
	super._ready()

func uses_authored_idle() -> bool:
	return use_adobe_idle and not asleep and reaction == Reaction.NONE

func uses_authored_reaction() -> bool:
	return use_adobe_idle and use_adobe_reactions and not asleep and AUTHORED_REACTIONS.has(reaction)

func uses_authored_visual() -> bool:
	return uses_authored_idle() or uses_authored_reaction()

func _entry_pose() -> Dictionary:
	if visual != null and visual.visible:
		return {"sx":breathing.scale.x,"sy":breathing.scale.y,"roll":breathing.rotation,"eye":eyes.scale.y,"left":eyes.scale.y*left_eye.scale.y,"right":eyes.scale.y*right_eye.scale.y,"gx":eyes.position.x,"gy":eyes.position.y}
	return {"sx":body_scale.x,"sy":body_scale.y,"roll":body_angle,"eye":maxf(2.0/21,eye_open),"left":maxf(2.0/21,eye_open*(.5 if reaction == Reaction.SERIOUSLY else 1)),"right":maxf(2.0/21,eye_open),"gx":gaze.x,"gy":-113+gaze.y}

func begin_reaction(which: int,touch: Vector2) -> void:
	pending_entry = _entry_pose()
	visual_reaction = Reaction.NONE
	super.begin_reaction(which,touch)
	pending_entry = {}

func _start_reaction_visual() -> void:
	var name: String = AUTHORED_REACTIONS[reaction]
	var animation := player.get_animation(name)
	var entry := pending_entry if not pending_entry.is_empty() else _entry_pose()
	var exit_phase := fposmod(clock-elapsed+float(DURATIONS[reaction]),3)
	var idle := player.get_animation("breathe")
	for track in range(animation.get_track_count()):
		var path := str(animation.track_get_path(track))
		var values: Array = reaction_templates[name][track]
		for key in range(values.size()):
			var value: float = values[key]
			if (path == "Breathing:rotation" and reaction in [Reaction.SIDE_EYE,Reaction.SLIDE,Reaction.JUMP,Reaction.RUN]) or (path == "Breathing/Eyes:position:x" and reaction in [Reaction.SIDE_EYE,Reaction.SLIDE]): value *= direction
			animation.bezier_track_set_key_value(track,key,value)
		var first: float = values[0]
		var last: float = values[-1]
		match path:
			"Breathing:scale:x":
				first = entry.sx
				last = idle.bezier_track_interpolate(0,exit_phase)
			"Breathing:scale:y":
				first = entry.sy
				last = idle.bezier_track_interpolate(1,exit_phase)
			"Breathing:rotation": first = entry.roll
			"Breathing/Eyes:scale:y": first = entry.eye/(.08 if reaction == Reaction.JUMP and blink_remaining > 0 else 1.0)
			"Breathing/Eyes/Left:scale:y": first = entry.left/(.08 if blink_remaining > 0 else 1.0)
			"Breathing/Eyes/Right:scale:y": first = entry.right/(.08 if blink_remaining > 0 else 1.0)
			"Breathing/Eyes:position:x": first = entry.gx
			"Breathing/Eyes:position:y": first = entry.gy
		animation.bezier_track_set_key_value(track,0,first)
		animation.bezier_track_set_key_value(track,values.size()-1,last)
	visual_reaction = reaction
	player.play(name)

func _set_exit_eye_targets() -> void:
	var animation := player.get_animation(AUTHORED_REACTIONS[reaction])
	for track in range(animation.get_track_count()):
		var path := str(animation.track_get_path(track))
		var last := animation.track_get_key_count(track)-1
		match path:
			"Breathing/Eyes:scale:y": animation.bezier_track_set_key_value(track,last,1.0 if reaction == Reaction.JUMP else (2.0/21 if blink_remaining > 0 else 1.0))
			"Breathing/Eyes:position:x": animation.bezier_track_set_key_value(track,last,idle_gaze.x)
			"Breathing/Eyes:position:y": animation.bezier_track_set_key_value(track,last,-113+idle_gaze.y)
			"Breathing/Eyes/Left:scale:y", "Breathing/Eyes/Right:scale:y": animation.bezier_track_set_key_value(track,last,1.0)

func contains_touch(point: Vector2) -> bool:
	if not uses_authored_visual() or visual == null or breathing == null or idle_outline.size() != 80 or not visual.is_visible_in_tree():
		return super.contains_touch(point)
	# InputEvent positions are viewport coordinates. Use exactly the transform
	# that displays the resting artwork, including parent/canvas transforms.
	var displayed := breathing.get_global_transform_with_canvas()
	if is_zero_approx(displayed.determinant()):
		return false
	if box_amount > 0:
		var actor_transform := get_global_transform_with_canvas()
		var prop_hit := _box_hit(actor_transform.affine_inverse()*point)
		if prop_hit != BoxHit.EXPOSED:
			return prop_hit == BoxHit.PEEK
	var local := displayed.affine_inverse()*point
	# Godot's ray test can return a false positive far outside the polygon at
	# particular rolls. Reject points outside its exact inclusive bounds first.
	if local.x < outline_bounds.position.x or local.x > outline_bounds.end.x or local.y < outline_bounds.position.y or local.y > outline_bounds.end.y:
		return false
	return Geometry2D.is_point_in_polygon(local,idle_outline)

func _update_pose() -> void:
	super._update_pose()
	if visual == null:
		return
	left_eye.scale = Vector2.ONE
	right_eye.scale = Vector2.ONE
	eyes.visible = true
	eyes.modulate = Color.WHITE
	turn_details.visible = uses_authored_reaction() and reaction == Reaction.TURN
	if turn_details.visible:
		turn_details.queue_redraw()
	visual.visible = uses_authored_visual()
	visual.position = body_position
	visual.rotation = 0
	if uses_authored_reaction():
		if visual_reaction != reaction: _start_reaction_visual()
		_set_exit_eye_targets()
		player.seek(elapsed,true)
		if reaction in MODEL_EYE_REACTIONS:
			eyes.position = Vector2(gaze.x,-113+gaze.y)
			eyes.scale.y = maxf(2.0/21,eye_open)
		if reaction == Reaction.TURN:
			left_eye.scale.x = 1.0-.8*turn_amount
			right_eye.scale.x = left_eye.scale.x
			eyes.modulate.a = 1.0-turn_amount
			eyes.visible = turn_amount < .97
		if reaction in [Reaction.BLINK,Reaction.SQUISH]: eyes.position = Vector2(gaze.x,-113+gaze.y)
		if reaction == Reaction.SQUISH: eyes.scale.y = maxf(2.0/21,eye_open)
		if reaction == Reaction.JUMP:
			eyes.scale.y = maxf(2.0/21,eyes.scale.y*(.08 if blink_remaining > 0 else 1.0))
		if reaction == Reaction.SERIOUSLY:
			# Compose natural blink once, then enforce the original 2px minimum
			# on each final eye, rather than halving an already closed parent.
			eyes.scale.y = 1
			var blink_factor := .08 if blink_remaining > 0 else 1.0
			left_eye.scale.y = maxf(2.0/21,left_eye.scale.y*blink_factor)
			right_eye.scale.y = maxf(2.0/21,right_eye.scale.y*blink_factor)
	else:
		visual_reaction = Reaction.NONE
		if player.current_animation != "breathe": player.play("breathe")
		player.seek(fposmod(clock,3),true)
		breathing.rotation = 0
		eyes.position = Vector2(gaze.x,-113+gaze.y)
		eyes.scale.y = maxf(2.0/21,eye_open)
	props.visible = uses_authored_visual() and (sign_amount > 0 or box_amount > 0)
	if props.visible:
		props.queue_redraw()
	if bubble_drawer != null:
		bubble_drawer.visible = uses_authored_visual()
		bubble_drawer.queue_redraw()

func _draw() -> void:
	if visual == null or not uses_authored_visual() or font == null:
		if visual != null:
			visual.hide()
		super._draw()
		return
	visual.show()
	if intro_alpha > 0:
		_text_center("a little personal space, please.", Vector2(last_size.x*.5,last_size.y*.25),23,Color(MUTED,intro_alpha))
		_text_center("Don't Touch Me", Vector2(last_size.x*.5,last_size.y*.25-42),40,Color(INK,intro_alpha))
		_text_center("(especially the little one)",Vector2(last_size.x*.5,last_size.y*.84),19,Color(MUTED,intro_alpha*.8))
	var height := maxf(0, anchor.y-body_position.y)
	_ellipse(Vector2(body_position.x,anchor.y+5),Vector2(111-minf(height*.2,45),13),Color(.35,.31,.24,.075))
	if touch_flash > 0 and reaction != Reaction.TURN:
		draw_set_transform(body_position,breathing.rotation,breathing.scale)
		for side in [-1.0,1.0]:
			draw_line(Vector2(side*136,-143),Vector2(side*(136+13*touch_flash),-151),Color(MUTED,touch_flash),3,true)
		draw_set_transform(Vector2.ZERO)
