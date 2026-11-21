extends RefCounted

static func from_window(viewport: Viewport, window: Window) -> Rect2:
	return to_viewport(viewport.get_visible_rect(), Rect2(DisplayServer.get_display_safe_area()),
		Vector2(window.position), viewport.get_final_transform())

static func to_viewport(visible_rect: Rect2, display_safe_area: Rect2, window_origin: Vector2,
		viewport_to_window: Transform2D) -> Rect2:
	# The final transform includes viewport scaling and the content offset.
	var safe_in_window := Rect2(display_safe_area.position - window_origin, display_safe_area.size)
	var available := visible_rect.intersection(viewport_to_window.affine_inverse() * safe_in_window)
	return available if available.has_area() else visible_rect
