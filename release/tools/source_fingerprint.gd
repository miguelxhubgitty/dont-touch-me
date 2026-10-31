extends RefCounted
## New manifests normalize source-text line endings; binary assets stay byte exact.
## Historical manifests used raw LF or CRLF hashes. Accept either representation
## of the same text, without updating old manifests or claiming fresh captures.
const MODE := "text-lf-binary-raw-v1"
const TEXT_EXTENSIONS := ["gd", "tres", "tscn", "godot", "cfg"]

static func digest(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	if path.get_extension() in TEXT_EXTENSIONS:
		return FileAccess.get_file_as_string(path).replace("\r\n", "\n").sha256_text()
	return FileAccess.get_sha256(path)

static func matches(path: String, expected: String, mode := "") -> bool:
	if expected.is_empty() or not FileAccess.file_exists(path):
		return false
	if mode == MODE:
		return digest(path) == expected
	if not mode.is_empty():
		return false
	if FileAccess.get_sha256(path) == expected:
		return true
	if path.get_extension() in TEXT_EXTENSIONS:
		var text := FileAccess.get_file_as_string(path).replace("\r\n", "\n")
		return text.sha256_text() == expected or text.replace("\n", "\r\n").sha256_text() == expected
	return false
