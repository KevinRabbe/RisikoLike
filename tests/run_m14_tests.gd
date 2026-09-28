extends SceneTree

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var audio: Node = get_root().get_node("AudioManager")
	_expect(AudioServer.get_bus_index("Master") >= 0, "Master bus exists")
	_expect(AudioServer.get_bus_index("Music") >= 0, "Music bus exists")
	_expect(AudioServer.get_bus_index("SFX") >= 0, "SFX bus exists")
	_expect(audio.EFFECTS.size() >= 10, "named feedback event catalog exists")
	for event_name in ["ui_click", "error", "turn_start", "dice_roll", "conquest", "card_trade", "victory"]:
		_expect(audio.EFFECTS.has(event_name), "feedback event: %s" % event_name)
	audio.apply_settings()
	audio.play_ui_click()
	audio.play_event("victory")
	_expect(FileAccess.file_exists("res://docs/AUDIO_LICENSES.md"), "audio license record exists")
	print("M14_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _expect(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)
