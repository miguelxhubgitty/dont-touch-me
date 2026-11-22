extends Button

const BUSES := {
	"UserSFX": "User sound effects",
	"CharacterVoice": "Character voices",
	"CharacterSFX": "Character sound effects",
	"Environment": "Environment",
	"Music": "Music",
}

var settings_path := "user://audio_volumes.cfg"
var settings := ConfigFile.new()
var panel: PanelContainer
var sliders: Dictionary = {}
var dragging := false
var touch_slider: HSlider
var touch_index := -1
var touch_start_value := 0.0
var orientation_button: Button
var landscape_selected := false

func initialize() -> void:
	settings.load(settings_path)
	pressed.connect(_toggle_panel)
	gui_input.connect(_volume_button_input)
	panel = PanelContainer.new()
	panel.position = Vector2(0, size.y + 8)
	panel.hide()
	add_child(panel)
	panel.gui_input.connect(_consume_touch.bind(panel))
	panel.visibility_changed.connect(_panel_visibility_changed)

	var options := VBoxContainer.new()
	panel.add_child(options)
	for bus in BUSES:
		var label := Label.new()
		label.text = BUSES[bus]
		options.add_child(label)
		var slider := HSlider.new()
		slider.custom_minimum_size = Vector2(292, 42)
		slider.max_value = 100
		slider.step = 1
		var stored: Variant = settings.get_value("volumes", bus, 100)
		if (stored is float or stored is int) and is_finite(float(stored)):
			slider.value = clampf(float(stored), 0, 100)
		else:
			slider.value = 100
		_apply_volume(slider.value, bus)
		slider.value_changed.connect(_apply_volume.bind(bus))
		slider.drag_started.connect(_begin_drag)
		slider.drag_ended.connect(_save_after_drag)
		slider.value_changed.connect(_save_when_not_dragging)
		slider.gui_input.connect(_slider_touch.bind(slider))
		options.add_child(slider)
		sliders[bus] = slider
	if _supports_manual_orientation():
		orientation_button = Button.new()
		orientation_button.text = "Orientation: Portrait"
		orientation_button.custom_minimum_size.y = 48
		orientation_button.pressed.connect(_toggle_orientation)
		orientation_button.gui_input.connect(_orientation_input)
		options.add_child(orientation_button)
		if OS.has_feature("ios"):
			_request_orientation.call_deferred(DisplayServer.SCREEN_PORTRAIT)

func _supports_manual_orientation() -> bool:
	return OS.has_feature("android") or (OS.has_feature("ios") and OS.has_feature("manual_ios_orientation"))

func _orientation_input(event: InputEvent) -> void:
	_consume_touch(event, orientation_button)
	if event is InputEventScreenTouch and event.pressed and not event.canceled and event.device != InputEvent.DEVICE_ID_EMULATION:
		_toggle_orientation()

func _toggle_orientation() -> void:
	landscape_selected = not landscape_selected
	orientation_button.text = "Orientation: Landscape" if landscape_selected else "Orientation: Portrait"
	_request_orientation(DisplayServer.SCREEN_LANDSCAPE if landscape_selected else DisplayServer.SCREEN_PORTRAIT)

func _request_orientation(orientation: DisplayServer.ScreenOrientation) -> void:
	DisplayServer.screen_set_orientation(orientation)

func _toggle_panel() -> void:
	panel.visible = not panel.visible

func _volume_button_input(event: InputEvent) -> void:
	_consume_touch(event, self)
	if event is InputEventScreenTouch and event.pressed and not event.canceled and event.device != InputEvent.DEVICE_ID_EMULATION:
		_toggle_panel()

func _consume_touch(event: InputEvent, control: Control) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag or (event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION):
		control.accept_event()

func _slider_touch(event: InputEvent, slider: HSlider) -> void:
	_consume_touch(event, slider)
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled and touch_slider == null and not dragging:
			touch_slider = slider
			touch_index = event.index
			touch_start_value = slider.value
			_set_touch_value(slider, event.position.x)
		elif (event.canceled or not event.pressed) and slider == touch_slider and event.index == touch_index:
			_finish_touch()
	elif event is InputEventScreenDrag and slider == touch_slider and event.index == touch_index:
		_set_touch_value(slider, event.position.x)

func _set_touch_value(slider: HSlider, x: float) -> void:
	slider.value = slider.max_value * clampf(x / slider.size.x, 0.0, 1.0)

func _finish_touch() -> void:
	if touch_slider == null:
		return
	var changed := touch_slider.value != touch_start_value
	touch_slider = null
	touch_index = -1
	if changed:
		_save()

func _panel_visibility_changed() -> void:
	if not panel.is_visible_in_tree():
		_finish_touch()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_finish_touch()

func _apply_volume(value: float, bus: String) -> void:
	var index := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_mute(index, value == 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001, value / 100.0)))
	settings.set_value("volumes", bus, value)

func _begin_drag() -> void:
	dragging = true

func _save_after_drag(changed: bool) -> void:
	dragging = false
	if changed:
		_save()

func _save_when_not_dragging(_value: float) -> void:
	if not dragging and touch_slider == null:
		_save()

func _save() -> void:
	var result := settings.save(settings_path)
	if result != OK:
		push_warning("Could not save audio volume preferences: " + error_string(result))
