extends SceneTree

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect(ProjectSettings.get_setting("application/config/name", "") == "ATLAS // FRONT", "release app identity")
	_expect(ProjectSettings.get_setting("application/run/main_scene", "") == "res://scenes/boot/Boot.tscn", "boot main scene configured")
	_expect(FileAccess.file_exists("res://export_presets.cfg"), "Windows export preset exists")
	_expect(FileAccess.file_exists("res://README.md"), "release README exists")
	_expect(FileAccess.file_exists("res://docs/RELEASE_CHECKLIST.md"), "release checklist exists")
	_expect(FileAccess.file_exists("res://docs/AUDIO_LICENSES.md"), "audio license record exists")
	_expect(FileAccess.file_exists("res://third_party/webrtc_native/LICENSE.libdatachannel"), "WebRTC license record exists")
	_expect(FileAccess.file_exists("res://scenes/game/Game.tscn"), "game scene ships")
	print("M16_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _expect(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)
