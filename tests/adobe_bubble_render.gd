extends SceneTree
const Original = preload("res://scripts/blob.gd")
const Native = preload("res://scripts/blob_animationplayer.gd")
class OriginalBubble extends Original:
	func _draw() -> void:
		if bubble != "" and bubble_alpha > 0: _draw_bubble()
class NativeBubble extends Native:
	func _draw() -> void:
		pass
var failures := 0
var cases := 0
var pixels := 0
var foreground_pixels := 0
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var viewports: Array[SubViewport] = []
	var actors: Array = []
	for i in range(3):
		var viewport := SubViewport.new()
		viewport.transparent_bg = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var actor = OriginalBubble.new() if i == 0 else (NativeBubble.new() if i == 1 else Native.new())
		viewport.add_child(actor)
		actor.set_process(false)
		actor.audio_manager.muted = true
		actor.intro_alpha = 0
		viewports.append(viewport)
		actors.append(actor)
	for size in [Vector2i(480,720),Vector2i(640,360),Vector2i(480,300)]:
		for viewport in viewports: viewport.size = size
		await process_frame
		for which in [Original.Reaction.DONT,Original.Reaction.SERIOUSLY,Original.Reaction.FLATTEN,Original.Reaction.STOP,Original.Reaction.WAKE]:
			for fraction in [.07,.5,.95]:
				for x in [40,size.x*.5,size.x-40]:
					for actor in actors:
						actor.reaction = Original.Reaction.NONE
						actor.asleep = false
						actor.clock = .5
						actor.blink_remaining = 0
						actor._update_pose()
						actor.begin_reaction(which,actor.body_position)
						actor.elapsed = Original.DURATIONS[which]*fraction
						actor.clock += actor.elapsed
						actor._update_pose()
						actor.body_position.x = x
						if actor is Native: actor.visual.position = actor.body_position
						actor.queue_redraw()
						if actor is Native: actor.bubble_drawer.queue_redraw()
					actors[1].breathing.hide()
					await RenderingServer.frame_post_draw
					var source := viewports[0].get_texture().get_image()
					var native := viewports[1].get_texture().get_image()
					var full := viewports[2].get_texture().get_image()
					if source.get_data() != native.get_data():
						failures += 1
						printerr("Bubble pixels differ: ",size," reaction=",which," fraction=",fraction," x=",x)
					pixels += size.x*size.y
					if fraction == .5:
						for y in range(size.y):
							for px in range(size.x):
								var expected := source.get_pixel(px,y)
								if expected.a < .999: continue
								foreground_pixels += 1
								if expected != full.get_pixel(px,y): failures += 1
					cases += 1
	# Replacement/dismissal clears both paths immediately, without extra timers.
	for actor in actors:
		actor.begin_reaction(Original.Reaction.BLINK,actor.body_position)
		actor.queue_redraw()
		if actor is Native: actor.bubble_drawer.queue_redraw()
	actors[1].breathing.hide()
	await RenderingServer.frame_post_draw
	if viewports[0].get_texture().get_image().get_data() != viewports[1].get_texture().get_image().get_data(): failures += 1
	var report := {"failures":failures,"cases":cases,"exact_bubble_pixel_comparisons":pixels,"opaque_foreground_pixels":foreground_pixels,"method":"Real transparent viewports; original bubble-only drawing versus native foreground drawer byte-for-byte; opaque bubble pixels compared with full body present, including short overlap and horizontal clamping. Interruption dismissal checked."}
	FileAccess.open("res://test-output/next-bubble-render.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("BUBBLE_RENDER ",JSON.stringify(report))
	for viewport in viewports: viewport.free()
	await process_frame
	quit(0 if failures == 0 else 1)
