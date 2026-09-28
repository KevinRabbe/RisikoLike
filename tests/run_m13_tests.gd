extends SceneTree

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for scene_path in [
		"res://scenes/menu/MainMenu.tscn",
		"res://scenes/menu/CreateLobby.tscn",
		"res://scenes/menu/JoinLobby.tscn",
		"res://scenes/menu/Lobby.tscn",
		"res://scenes/menu/Settings.tscn",
		"res://scenes/game/Game.tscn"
	]:
		var packed: PackedScene = load(scene_path)
		_expect(packed != null, "scene loads: %s" % scene_path)
		if packed == null:
			continue
		var instance := packed.instantiate()
		get_root().add_child(instance)
		await process_frame
		_expect(instance.theme != null, "ATLAS theme installed: %s" % scene_path)
		instance.queue_free()
		await process_frame
	var controller := MapController.new()
	controller.size = Vector2(1200, 700)
	get_root().add_child(controller)
	var state := GameState.create_local(2, 130)
	controller.configure(state.map_data, state)
	await process_frame
	_expect(controller.map_surface != null, "map surface is present")
	_expect_equal(controller.map_surface.visuals.size(), 42, "M13 preserves 42 territory visuals")
	controller.queue_free()
	print("M13_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _expect(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	_expect(actual == expected, "%s (got %s, expected %s)" % [label, str(actual), str(expected)])
