extends Button

var settings_path := "user://audio_settings.cfg"
var manager: Node
var touch_index := -1

func initialize(audio_manager: Node) -> void:
	manager = audio_manager
	var settings := ConfigFile.new()
	var saved: Variant = true
	if settings.load(settings_path) == OK:
		saved = settings.get_value("audio", "muted", true)
	manager.muted = saved if saved is bool else true
	_update_label()
	pressed.connect(_toggle_sound)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		accept_event()
		if event.pressed and touch_index == -1:
			touch_index = event.index
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			if not event.canceled and Rect2(Vector2.ZERO, size).has_point(event.position):
				_toggle_sound()
	elif event is InputEventScreenDrag:
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_VISIBILITY_CHANGED:
		touch_index = -1

func _toggle_sound() -> void:
	if manager == null:
		return
	manager.muted = not manager.muted
	_update_label()
	var settings := ConfigFile.new()
	settings.set_value("audio", "muted", manager.muted)
	var result := settings.save(settings_path)
	if result != OK:
		push_warning("Could not save sound preference: " + error_string(result))

func _update_label() -> void:
	text = "Sound Off" if manager.muted else "Sound On"
