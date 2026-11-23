extends RefCounted
## Test-only audio teardown. Godot 4.7.2 frees a stopped playback only after
## the next audio mix and main-loop update, so quitting right after a test
## leaves it alive and reports "ObjectDB instances leaked" / "resources still
## in use". Weak references let the audio server own the playback lifetime.
const TIMEOUT_MS := 2000
var _managers: Array[WeakRef] = []
var _playbacks := {}

## Call first in a suite's run(). Watches every audio manager added afterwards.
func attach(tree: SceneTree) -> void:
	tree.node_added.connect(func(node: Node) -> void:
		if node.has_signal("event_played"):
			_managers.append(weakref(node))
			node.event_played.connect(func(_id) -> void:
				for player in node.players.values() + node.fade_players.values():
					observe(player)))

func observe(player: AudioStreamPlayer) -> void:
	if player.has_stream_playback():
		var playback := player.get_stream_playback()
		_playbacks[playback.get_instance_id()] = weakref(playback)

## Processes frames until every observed playback has retired. Returns false
## if the deadline passes first. Returns at once when none remain.
func drain(tree: SceneTree, timeout_ms: int = TIMEOUT_MS) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while true:
		for id in _playbacks.keys():
			if _playbacks[id].get_ref() == null:
				_playbacks.erase(id)
		if _playbacks.is_empty():
			return true
		if Time.get_ticks_msec() >= deadline:
			return false
		await tree.process_frame
	return false

## Replaces a suite's final quit(): stops watched audio, drains, then quits.
func finish(tree: SceneTree, exit_code: int) -> void:
	for manager in _managers:
		if manager.get_ref() != null:
			manager.get_ref().stop_all()
	if not await drain(tree):
		push_error("Audio teardown timed out with %d playback(s) still alive" % _playbacks.size())
		exit_code = 1
	tree.quit(exit_code)
