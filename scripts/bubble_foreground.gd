extends Node2D

func _draw() -> void:
	var actor = get_parent()
	if actor.uses_authored_visual() and actor.font != null and actor.bubble != "" and actor.bubble_alpha > 0:
		actor._draw_bubble(self)
