extends SceneTree

var output_dir := "user://m13-captures"

func _init() -> void:
	for argument in OS.get_cmdline_args():
		if str(argument).begins_with("--output-dir="):
			output_dir = str(argument).trim_prefix("--output-dir=")
	call_deferred("_capture_all")

func _capture_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var scenes := {
		"main-menu": "res://scenes/menu/MainMenu.tscn",
		"create-lobby": "res://scenes/menu/CreateLobby.tscn",
		"join-lobby": "res://scenes/menu/JoinLobby.tscn",
		"lobby": "res://scenes/menu/Lobby.tscn",
		"settings": "res://scenes/menu/Settings.tscn",
		"game": "res://scenes/game/Game.tscn"
	}
	for capture_name: String in scenes:
		var packed: PackedScene = load(scenes[capture_name])
		var scene := packed.instantiate()
		get_root().add_child(scene)
		for _index in range(8):
			await process_frame
		await _capture(capture_name + ".png")
		scene.queue_free()
		await process_frame
	await _capture_game_states()
	print("M13_VISUAL_CAPTURE: %s" % output_dir)
	quit(0)

func _capture_game_states() -> void:
	var packed: PackedScene = load("res://scenes/game/Game.tscn")
	var scene := packed.instantiate()
	get_root().add_child(scene)
	for _index in range(8):
		await process_frame
	var controller: Variant = scene
	var game_state: GameState = controller.game_state
	await _capture("full-world.png")
	game_state.turn_state.phase = TurnState.Phase.REINFORCEMENT
	controller._refresh_ui()
	await _capture("reinforcement.png")
	game_state.turn_state.phase = TurnState.Phase.ATTACK
	controller._refresh_ui()
	await _capture("attack.png")
	game_state.get_player("P1").territory_card_ids = ["NA_01", "EU_01"]
	controller._refresh_ui()
	await _capture("cards.png")
	game_state.turn_state.phase = TurnState.Phase.FORTIFICATION
	controller._refresh_ui()
	await _capture("fortification.png")
	game_state.turn_state.turn_deadline_msec = game_state.clock.now_msec() + 25000
	controller._refresh_ui()
	await _capture("timer-warning.png")
	controller._on_network_connection_changed("reconnecting")
	await _capture("reconnecting.png")
	controller._on_network_connection_changed("in_game")
	game_state.get_player("P1").spectator_mode = true
	game_state.get_player("P1").spectator_source_status = PlayerState.Status.SURRENDERED
	controller._refresh_ui()
	await _capture("spectator.png")
	game_state.status = GameState.MatchStatus.FINISHED
	game_state.winner_player_id = "P1"
	controller._refresh_ui()
	await _capture("victory.png")
	game_state.status = GameState.MatchStatus.TERMINATED
	controller._refresh_ui()
	await _capture("terminated.png")
	scene.queue_free()
	await process_frame

func _capture(file_name: String) -> void:
	for _index in range(3):
		await process_frame
	var texture := get_root().get_viewport().get_texture()
	if texture == null:
		push_error("M13 capture viewport texture is null")
		quit(1)
		return
	var error := texture.get_image().save_png(output_dir.path_join(file_name))
	if error != OK:
		push_error("M13 capture failed for %s: %s" % [file_name, str(error)])
		quit(1)
