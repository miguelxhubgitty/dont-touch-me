extends SceneTree
var audio_cleanup = preload("res://tests/audio_test_cleanup.gd").new()

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	audio_cleanup.attach(self)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var audio = game.audio_manager
	audio.muted = false
	audio.focused = true
	audio.begin_reaction(game.Reaction.SLIDE)
	audio.advance_reaction(0.1)
	var outgoing: AudioStreamPlayer = audio.players.action
	var level := outgoing.volume_db
	audio.begin_reaction(game.Reaction.BLINK)
	var passed: bool = outgoing.playing and audio.fade_players.action == outgoing
	audio.tick(0.0175)
	passed = passed and outgoing.playing and outgoing.volume_db < level
	audio.tick(0.018)
	passed = passed and not outgoing.playing and audio.fades.is_empty()
	for i in range(12):
		audio.begin_reaction(game.Reaction.SLIDE)
		audio.advance_reaction(0.1)
		passed = passed and audio.fades.size() <= 1
	audio.muted = true
	passed = passed and audio.fades.is_empty() and audio.slots.is_empty()
	for player in audio.fade_players.values():
		passed = passed and not player.playing
	game.queue_free()
	print("Interruption fade checks passed: ", passed)
	await audio_cleanup.finish(self, 0 if passed else 1)
