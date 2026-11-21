extends Button

const POLICY_URL := "https://miguelxhubgitty.github.io/dont-touch-me/privacy.html"
const MARGIN := Vector2(24, 24)

var active_touch := -1

func _ready() -> void:
	set_process_input(false)
	if not _is_ios():
		return
	pressed.connect(_open_policy)
	get_viewport().size_changed.connect(_refresh_position)
	_refresh_position()
	(get_parent() as CanvasLayer).show()

func _is_ios() -> bool:
	return OS.has_feature("ios")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_clear_touch()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN and is_node_ready() and is_visible_in_tree():
		_refresh_position()

func _refresh_position() -> void:
	var viewport := get_viewport()
	_place(viewport.get_visible_rect(), Rect2(DisplayServer.get_display_safe_area()),
		Vector2(get_window().position), viewport.get_final_transform())

func _place(visible_rect: Rect2, display_safe_area: Rect2, window_origin: Vector2,
		viewport_to_window: Transform2D) -> void:
	var safe_in_window := Rect2(display_safe_area.position - window_origin, display_safe_area.size)
	var available := visible_rect.intersection(viewport_to_window.affine_inverse() * safe_in_window)
	if not available.has_area():
		available = visible_rect
	position = (available.end - MARGIN - size).max(available.position)

func _input(event: InputEvent) -> void:
	# A mirrored touch may end GUI capture before the real release arrives.
	if event is InputEventScreenTouch and event.index == active_touch and event.device != InputEvent.DEVICE_ID_EMULATION:
		if not event.pressed or event.canceled:
			_clear_touch()

func _clear_touch() -> void:
	active_touch = -1
	set_process_input(false)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		accept_event()
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if event.pressed and not event.canceled and active_touch == -1:
			active_touch = event.index
			set_process_input(true)
			_open_policy()
	elif event is InputEventScreenDrag or (event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION):
		accept_event()

func _open_policy() -> void:
	var error := OS.shell_open(POLICY_URL)
	if error != OK:
		push_warning("Could not open the privacy policy: " + error_string(error))
