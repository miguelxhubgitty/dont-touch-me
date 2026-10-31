extends SceneTree
const Fingerprint = preload("res://release/tools/source_fingerprint.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://test-output")
	var path := "res://test-output/fingerprint-probe.gd"
	var original := "extends Node\nconst VALUE := 1\n"
	for ending in ["\n", "\r\n"]:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(original.replace("\n", ending))
		file.close()
		check(Fingerprint.digest(path) == original.sha256_text(), "Canonical digest ignores checkout line endings")
		for legacy in [original, original.replace("\n", "\r\n")]:
			check(Fingerprint.matches(path, legacy.sha256_text()), "Historical text fingerprints are portable")
		check(Fingerprint.matches(path, original.sha256_text(), Fingerprint.MODE), "Declared normalized fingerprint matches")
		check(not Fingerprint.matches(path, original.replace("1", "2").sha256_text()), "Actual source changes are rejected")
		check(not Fingerprint.matches(path, original.sha256_text(), "unknown-mode"), "Unknown modes are rejected")
	check(not Fingerprint.matches(path, ""), "Missing fingerprint is rejected")
	check(not Fingerprint.matches(path + ".missing", original.sha256_text()), "Missing source is rejected")
	var binary := "res://test-output/fingerprint-probe.bin"
	var file := FileAccess.open(binary, FileAccess.WRITE)
	file.store_buffer(PackedByteArray([0, 10, 13, 10, 255]))
	file.close()
	var expected := FileAccess.get_sha256(binary)
	check(Fingerprint.digest(binary) == expected, "Binary fingerprints remain byte exact")
	check(Fingerprint.matches(binary, expected, Fingerprint.MODE), "Binary source matches")
	file = FileAccess.open(binary, FileAccess.WRITE)
	file.store_buffer(PackedByteArray([0, 10, 10, 255]))
	file.close()
	check(not Fingerprint.matches(binary, expected), "Binary line-ending-like changes are rejected")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(binary)
	print("Source fingerprints: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
