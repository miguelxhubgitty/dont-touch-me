extends Button

const HudSafeArea := preload("res://scripts/hud_safe_area.gd")
const POLICY_URL := "https://miguelxhubgitty.github.io/dont-touch-me/privacy.html"
const RELEASE_FONT := "res://assets/fonts/SpaceGrotesk.ttf"
const MARGIN := Vector2(24, 24)

func _ready() -> void:
	if not _is_android():
		return
	if ResourceLoader.exists(RELEASE_FONT, "Font"):
		add_theme_font_override("font", load(RELEASE_FONT))
	pressed.connect(_open_policy)
	get_viewport().size_changed.connect(_refresh_position)
	_refresh_position()
	(get_parent() as CanvasLayer).show()

func _is_android() -> bool:
	return OS.has_feature("android")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and is_node_ready() and is_visible_in_tree():
		_refresh_position()

func _refresh_position() -> void:
	_place(HudSafeArea.from_window(get_viewport(), get_window()))

func _place(safe_rect: Rect2) -> void:
	position = (safe_rect.end - MARGIN - size).max(safe_rect.position)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		accept_event()
		if event.pressed and not event.canceled and event.device != InputEvent.DEVICE_ID_EMULATION:
			_open_policy()
	elif event is InputEventScreenDrag or (event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION):
		# The synthetic mouse event must not reach BaseButton's pressed path.
		accept_event()

func _open_policy() -> void:
	var error := OS.shell_open(POLICY_URL)
	if error != OK:
		push_warning("Could not open the privacy policy: " + error_string(error))
