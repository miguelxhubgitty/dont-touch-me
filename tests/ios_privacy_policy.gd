extends SceneTree

const Game := preload("res://main.tscn")

class IPhoneButton extends "res://scripts/ios_privacy_policy_button.gd":
	var requests := 0

	func _is_ios() -> bool:
		return true

	func _open_policy() -> void:
		requests += 1

var failures := 0
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func touch(viewport: Viewport, point: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = down
	viewport.push_input(event, true)

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	root.add_child(viewport)
	var game = Game.instantiate()
	viewport.add_child(game)
	if not OS.has_feature("ios"):
		check(not game.get_node("PrivacyHUD/PrivacyPolicy").is_visible_in_tree(),
			"normal non-iOS game keeps the HUD hidden")
	game.free()
	game = Game.instantiate()
	var button: Button = game.get_node("PrivacyHUD/PrivacyPolicy")
	button.set_script(IPhoneButton)
	viewport.add_child(game)
	game.set_process(false)
	check(button.is_visible_in_tree() and button.flat and button.text == "Privacy Policy",
		"iOS shows a flat privacy policy link")
	check(button.POLICY_URL == "https://miguelxhubgitty.github.io/dont-touch-me/privacy.html",
		"the button opens the published policy")
	var viewport_rect := Rect2(0, 0, 720, 1280)
	var scaled := Transform2D(0.0, Vector2(1.5, 1.5), 0.0, Vector2(30, 45))
	button._place(viewport_rect, Rect2(180, 170, 990, 1740), Vector2(120, 80), scaled)
	check(button.get_global_rect().is_equal_approx(Rect2(456, 1108, 200, 58)),
		"scaled and offset safe rectangle keeps the button clear of insets")
	var point := button.get_global_rect().get_center()
	game.annoyance = 9.0
	game.idle_time = 1.8
	touch(viewport, point, true)
	check(viewport.is_input_handled() and button.requests == 1, "native press is consumed and opens once")
	for down in [true, false]:
		var mirrored := InputEventMouseButton.new()
		mirrored.position = point
		mirrored.button_index = MOUSE_BUTTON_LEFT
		mirrored.pressed = down
		mirrored.device = InputEvent.DEVICE_ID_EMULATION
		viewport.push_input(mirrored, true)
	touch(viewport, point, false)
	check(button.requests == 1, "mirrored mouse and release do not open a second time")
	check(game.annoyance == 9.0 and game.idle_time == 1.8 and game.reaction == 0,
		"privacy gesture leaves gameplay state alone")
	var blob_point: Vector2 = game.body_position + Vector2(0, -60)
	check(game.contains_touch(blob_point), "gameplay probe is inside the frozen hit silhouette")
	touch(viewport, blob_point, true)
	touch(viewport, blob_point, false)
	check(game.reaction != 0 and game.idle_time == 0.0 and button.requests == 1,
		"tap on the original blob still reaches gameplay")
	viewport.free()
	print("iOS privacy checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
