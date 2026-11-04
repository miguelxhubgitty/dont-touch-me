extends Node
## Development audio only. No gameplay RNG, timers or independent animation clock.
signal event_played(event_name: String)

const REACTIONS := ["", "blink", "side_eye", "squish", "irritated", "dont", "seriously",
	"slide", "jump", "shake", "flatten", "turn", "stop", "sign", "box", "run", "wake"]
var events: Dictionary = {}
var players: Dictionary = {}
var streams: Dictionary = {}
var slots: Dictionary = {}
var fired: Dictionary = {}
var active_reaction := ""
var progress := 0.0
var time := 0.0
var last_contact := -100.0
var last_voice := -100.0
var focused := true
var muted := false:
	set(value):
		muted = value
		if value:
			stop_all()
## Opt-in bounded diagnostic trace; disabled in ordinary play.
var trace_enabled := false
var trace: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://audio/blob_events.json"))
	if not parsed is Dictionary or not parsed.get("events") is Dictionary:
		push_error("Invalid blob audio event map; audio disabled")
		return
	events = parsed.events
	for role in ["contact", "voice", "action"]:
		var player := AudioStreamPlayer.new()
		player.name = role.capitalize()
		add_child(player)
		players[role] = player
	# Validate/load once. Repeated touches must not hit disk or reimport assets.
	for id in events:
		var cue: Dictionary = events[id]
		var path := str(cue.get("stream", ""))
		if not players.has(str(cue.get("role", ""))) or float(cue.get("max_seconds", 0)) <= 0:
			push_error("Invalid audio cue: " + id)
			cue.enabled = false
			continue
		if not streams.has(path):
			var resource = load(path) if path.begins_with("res://audio/") and ResourceLoader.exists(path) else null
			streams[path] = resource if resource is AudioStream else null
			if streams[path] == null:
				push_error("Missing/invalid audio stream: " + path)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		stop_all()
	elif what == NOTIFICATION_EXIT_TREE:
		stop_all()

func set_focused(value: bool) -> void:
	focused = value
	if not value:
		stop_all()

func stop_role(role: String) -> void:
	if players.has(role):
		players[role].stop()
	slots.erase(role)

func stop_all() -> void:
	for role in players:
		stop_role(role)

func cancel_reaction() -> void:
	stop_all()
	active_reaction = ""
	fired.clear()
	progress = 0.0

func begin_reaction(which: int) -> void:
	cancel_reaction()
	if which <= 0 or which >= REACTIONS.size():
		return
	active_reaction = REACTIONS[which]
	for id in events:
		if id.begins_with(active_reaction + ".") and events[id].marker == "start":
			fired[id] = true
			play_event(id)

func contact(which: int) -> void:
	if which > 0 and which < REACTIONS.size():
		play_event(REACTIONS[which] + ".contact")

func tick(delta: float) -> void:
	time += maxf(0, delta)
	for role in slots.keys():
		var slot: Dictionary = slots[role]
		slot.remaining -= delta
		if slot.remaining <= 0:
			stop_role(role)
		elif slot.remaining < 0.025:
			# De-click the normal snippet ending; interruption uses immediate stop.
			players[role].volume_db = slot.volume_db + linear_to_db(maxf(0.001, slot.remaining / 0.025))

func marker_position(marker: String) -> float:
	match marker:
		"start": return 0.0
		"motion": return 0.000001
		"expression":
			# Invert the actual smoothstep raise envelope at 0.85.
			var lo := 0.0
			var hi := 1.0
			for i in range(24):
				var mid := (lo + hi) * 0.5
				if mid * mid * (3.0 - 2.0 * mid) < 0.85: lo = mid
				else: hi = mid
			return (lo + hi) / 14.0
		"held": return 1.0 / 7.0
		"release": return 6.0 / 7.0
		"squish_rebound": return atan(PI) / (1.5 * PI)
		"slide_stop": return 2.0 / 3.0
		"offscreen": return 0.23
		"return": return 0.7
		"wake_land": return 0.5
		"wake_narrow": return 0.55
		"end": return 1.0
	return -1.0

func advance_reaction(next_progress: float, moved_horizontally: bool = true) -> void:
	if active_reaction.is_empty(): return
	var current := clampf(next_progress, progress, 1.0)
	var candidates: Dictionary = {}
	for id in events:
		var cue: Dictionary = events[id]
		if not id.begins_with(active_reaction + ".") or fired.has(id): continue
		var at := marker_position(cue.marker)
		if at <= progress or at > current: continue
		fired[id] = true # Muted/suppressed cues are consumed, never queued.
		if not cue.enabled: continue
		if id == "slide.move" and not moved_horizontally: continue
		if cue.has("stop_marker") and current >= marker_position(cue.stop_marker): continue
		var role: String = cue.role
		# A large step keeps only the latest relevant cue per role, never a burst.
		if not candidates.has(role) or at > candidates[role].at:
			candidates[role] = {"id": id, "at": at}
	for role in slots.keys():
		var cue: Dictionary = events[slots[role].id]
		if cue.has("stop_marker") and current >= marker_position(cue.stop_marker):
			stop_role(role)
	progress = current
	for role in candidates:
		play_event(candidates[role].id)
	if current >= 1.0:
		active_reaction = "" # Let the landing snippet finish; no future reaction cues.

func play_event(id: String) -> bool:
	if not events.has(id) or muted or not focused or not is_inside_tree() or get_tree().paused:
		return false
	var cue: Dictionary = events[id]
	if not cue.enabled: return false
	var role: String = cue.role
	if role == "contact" and time - last_contact < 0.1 - 0.000001: return false
	if role == "voice" and time - last_voice < 0.3 - 0.000001: return false
	var stream = streams.get(str(cue.stream))
	if stream == null: return false
	stop_role(role)
	var player: AudioStreamPlayer = players[role]
	player.stream = stream
	player.volume_db = float(cue.volume_db)
	player.play()
	slots[role] = {"id": id, "remaining": float(cue.max_seconds), "volume_db": float(cue.volume_db)}
	if role == "contact": last_contact = time
	if role == "voice": last_voice = time
	if trace_enabled:
		trace.append(id)
		if trace.size() > 512: trace.pop_front()
	event_played.emit(id)
	return true
