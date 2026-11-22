extends CanvasLayer

const HudSafeArea := preload("res://scripts/hud_safe_area.gd")
const MARGIN := 20.0
const PANEL_GAP := 8.0
const MIN_DESKTOP_HEIGHT := 540

@onready var sound: Button = $SoundButton
@onready var volume: Button = $VolumeButton

func _ready() -> void:
	if OS.has_feature("android"):
		_connect_layout.call_deferred()
	elif OS.has_feature("pc") and get_viewport() is Window:
		var window := get_window()
		window.min_size.y = maxi(window.min_size.y, MIN_DESKTOP_HEIGHT)

func _connect_layout() -> void:
	get_viewport().size_changed.connect(_refresh)
	volume.panel.visibility_changed.connect(_refresh)
	volume.panel.resized.connect(_refresh)
	_refresh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and is_node_ready() and OS.has_feature("android"):
		_refresh()

func _refresh() -> void:
	_place(HudSafeArea.from_window(get_viewport(), get_window()))

func _place(safe_rect: Rect2) -> void:
	var top := safe_rect.position.y + MARGIN
	var side_margin := clampf((safe_rect.size.x - volume.size.x - sound.size.x) * 0.5, 0.0, MARGIN)
	volume.position = Vector2(safe_rect.position.x + side_margin, top)
	sound.position = Vector2(safe_rect.end.x - side_margin - sound.size.x, top)
	var panel: PanelContainer = volume.panel
	if not panel.visible:
		return
	var panel_size := panel.size.max(panel.get_combined_minimum_size())
	var left := clampf(volume.position.x, safe_rect.position.x,
		maxf(safe_rect.position.x, safe_rect.end.x - panel_size.x))
	var below := volume.position.y + volume.size.y + PANEL_GAP
	var above := volume.position.y - panel_size.y - PANEL_GAP
	var panel_top := above if below + panel_size.y > safe_rect.end.y and above >= safe_rect.position.y else below
	panel.position = Vector2(left, panel_top) - volume.position
