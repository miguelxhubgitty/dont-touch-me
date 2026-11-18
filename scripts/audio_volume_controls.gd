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

func initialize() -> void:
	settings.load(settings_path)
	pressed.connect(_toggle_panel)
	gui_input.connect(_volume_button_input)
	panel = PanelContainer.new()
	panel.position = Vector2(0, size.y + 8)
	panel.hide()
	add_child(panel)
	panel.gui_input.connect(_consume_touch.bind(panel))

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

func _toggle_panel() -> void:
	panel.visible = not panel.visible

func _volume_button_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		accept_event()
		if event.pressed:
			_toggle_panel()

func _consume_touch(event: InputEvent, control: Control) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		control.accept_event()

func _slider_touch(event: InputEvent, slider: HSlider) -> void:
	if event is InputEventScreenTouch:
		slider.accept_event()
		if event.pressed:
			slider.value = 100.0 * clampf(event.position.x / slider.size.x, 0.0, 1.0)
	elif event is InputEventScreenDrag:
		slider.accept_event()

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
	if not dragging:
		_save()

func _save() -> void:
	var result := settings.save(settings_path)
	if result != OK:
		push_warning("Could not save audio volume preferences: " + error_string(result))
