extends "res://scripts/blob_animationplayer.gd"
## Test-only game root for suites that advance the blob themselves. The game
## re-enables processing on window focus-in (intended behavior), so a test's
## set_process(false) cannot be relied on. Here the real-time step is a no-op.
## set_script() resets scene-assigned root properties; restore them after it.
func _process(_delta: float) -> void:
	pass
