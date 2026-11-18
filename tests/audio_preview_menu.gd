extends VBoxContainer

const AudioManager = preload("res://scripts/audio_manager.gd")

var manager: Node
var player: AudioStreamPlayer
var rows: VBoxContainer

func _ready() -> void:
	if not OS.has_feature("editor"):
		return
	manager = AudioManager.new()
	add_child(manager)
	player = AudioStreamPlayer.new()
	add_child(player)
	var stop := Button.new()
	stop.text = "Stop playback"
	stop.pressed.connect(player.stop)
	add_child(stop)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	var ids: Array = manager.events.keys()
	ids.sort()
	for id in ids:
		var cue: Dictionary = manager.events[id]
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s  |  %s  |  %+.1f dB\n%s" % [
			id, "Enabled" if cue.enabled else "Disabled", cue.volume_db, str(cue.stream).get_file()
		]
		button.disabled = manager.streams.get(cue.stream) == null
		button.pressed.connect(preview.bind(id))
		rows.add_child(button)

func preview(id: String) -> void:
	if manager == null or not manager.events.has(id):
		return
	var cue: Dictionary = manager.events[id]
	var stream: AudioStream = manager.streams.get(cue.stream)
	if stream == null:
		return
	player.stop()
	player.stream = stream
	player.volume_db = cue.volume_db
	player.play()
