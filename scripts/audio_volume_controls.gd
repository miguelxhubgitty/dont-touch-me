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
var menu_touch_button: Button
var menu_touch_index := -1
var touch_start_value := 0.0
const ORIENTATIONS := {
	"Auto": DisplayServer.SCREEN_SENSOR,
	"Portrait": DisplayServer.SCREEN_PORTRAIT,
	"Landscape": DisplayServer.SCREEN_LANDSCAPE,
}

var settings_menu: VBoxContainer
var volume_menu: VBoxContainer
var orientation_menu: VBoxContainer
var orientation_options := ButtonGroup.new()

func initialize() -> void:
	settings.load(settings_path)
	pressed.connect(_toggle_panel)
	gui_input.connect(_menu_input.bind(self, _toggle_panel))
	panel = PanelContainer.new()
	panel.position = Vector2(0, size.y + 8)
	panel.hide()
	add_child(panel)
	panel.gui_input.connect(_consume_touch.bind(panel))
	panel.visibility_changed.connect(_panel_visibility_changed)

	settings_menu = VBoxContainer.new()
	# Every screen matches the slider width, so the card keeps one size between screens.
	settings_menu.custom_minimum_size.x = 292
	panel.add_child(settings_menu)
	volume_menu = VBoxContainer.new()
	# Each label sits on its own slider; the theme's label margin separates the groups.
	volume_menu.add_theme_constant_override("separation", -6)
	panel.add_child(volume_menu)
	volume_menu.hide()
	_add_menu_button(settings_menu, "Volume", _show_menu.bind(volume_menu))
	for bus in BUSES:
		var label := Label.new()
		label.text = BUSES[bus]
		volume_menu.add_child(label)
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
		volume_menu.add_child(slider)
		sliders[bus] = slider
	var back_gap := Control.new()
	back_gap.custom_minimum_size.y = 18
	back_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	volume_menu.add_child(back_gap)
	_add_menu_button(volume_menu, "Back", _show_menu.bind(settings_menu))
	if _supports_manual_orientation():
		orientation_menu = VBoxContainer.new()
		orientation_menu.custom_minimum_size.x = 292
		panel.add_child(orientation_menu)
		orientation_menu.hide()
		_add_menu_button(settings_menu, "Orientation", _show_menu.bind(orientation_menu))
		var saved: Variant = settings.get_value("display", "orientation", "Auto")
		if not ORIENTATIONS.has(saved):
			saved = "Auto"
		for choice in ORIENTATIONS:
			var option := _add_menu_button(orientation_menu, choice, _select_orientation.bind(choice))
			option.toggle_mode = true
			option.button_group = orientation_options
			option.set_pressed_no_signal(choice == saved)
		_add_menu_button(orientation_menu, "Back", _show_menu.bind(settings_menu))
		_request_orientation.call_deferred(ORIENTATIONS[saved])

func _add_menu_button(menu: VBoxContainer, title: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 45
	button.pressed.connect(action)
	button.gui_input.connect(_menu_input.bind(button, action))
	menu.add_child(button)
	return button

func _show_menu(menu: VBoxContainer) -> void:
	_finish_touch()
	for child in panel.get_children():
		child.visible = child == menu
	panel.reset_size()
	panel.reset_size.call_deferred()

func _supports_manual_orientation() -> bool:
	return OS.has_feature("android") or (OS.has_feature("ios") and OS.has_feature("manual_ios_orientation"))

func _select_orientation(choice: String) -> void:
	for option in orientation_options.get_buttons():
		option.set_pressed_no_signal(option.text == choice)
	settings.set_value("display", "orientation", choice)
	_save()
	_request_orientation(ORIENTATIONS[choice])

func _request_orientation(orientation: DisplayServer.ScreenOrientation) -> void:
	DisplayServer.screen_set_orientation(orientation)

func _toggle_panel() -> void:
	if not panel.visible:
		_show_menu(settings_menu)
	panel.visible = not panel.visible

func _menu_input(event: InputEvent, button: Button, action: Callable) -> void:
	_consume_touch(event, button)
	if not event is InputEventScreenTouch or event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event.pressed and not event.canceled and menu_touch_button == null:
		menu_touch_button = button
		menu_touch_index = event.index
	elif event.index == menu_touch_index and (event.canceled or not event.pressed):
		var activate: bool = menu_touch_button == button and not event.canceled and Rect2(Vector2.ZERO, button.size).has_point(event.position)
		menu_touch_button = null
		menu_touch_index = -1
		if activate:
			action.call_deferred()

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
		menu_touch_button = null
		menu_touch_index = -1
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
		push_warning("Could not save game settings: " + error_string(result))
