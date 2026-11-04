extends RefCounted
## Test-only observation. Weak references let the mixer own playback lifetime.
const TIMEOUT_MS := 2000
var _playbacks: Dictionary = {}

func watch(manager: Node) -> void:
	manager.event_played.connect(func(_event_name):
		for player in manager.players.values():
			observe(player)
	)

func observe(player: AudioStreamPlayer) -> void:
	if player.has_stream_playback():
		var playback := player.get_stream_playback()
		_playbacks[playback.get_instance_id()] = weakref(playback)

func wait_for_retirement(tree: SceneTree, timeout_ms: int = TIMEOUT_MS) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while true:
		for id in _playbacks.keys():
			if _playbacks[id].get_ref() == null:
				_playbacks.erase(id)
		if _playbacks.is_empty():
			return true
		if Time.get_ticks_msec() >= deadline:
			push_error("Audio teardown timed out with %d playback reference(s) still alive" % _playbacks.size())
			return false
		await tree.process_frame
	return false
