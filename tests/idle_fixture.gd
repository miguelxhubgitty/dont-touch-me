extends RefCounted

static func arm(actor, clip: int, at: float) -> void:
	var probe := RandomNumberGenerator.new()
	for seed in range(1000):
		probe.seed = seed
		var roll := probe.randi_range(0, 99)
		if actor._idle_choice(actor._stage_for(at), roll) == clip:
			actor.idle_rng.seed = seed
			actor.next_idle_at = at
			return
	assert(false, "No test seed found for eligible idle")
