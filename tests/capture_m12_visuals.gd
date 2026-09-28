extends SceneTree

var output_dir := "C:/Users/kevin/.codex/visualizations/2026/09/27/01a0e495-0936-7c31-89b0-c7aea6192265"

func _init() -> void:
	for argument in OS.get_cmdline_args():
		if str(argument).begins_with("--output-dir="):
			output_dir = str(argument).trim_prefix("--output-dir=")
	call_deferred("_capture_states")

func _capture_states() -> void:
	var packed_scene: PackedScene = load("res://scenes/game/Game.tscn")
	var scene: Node = packed_scene.instantiate()
	get_root().add_child(scene)
	for _index in range(12):
		await process_frame
	var controller: Variant = scene
	var map_controller: MapController = controller.map_controller
	var game_state: GameState = controller.game_state
	var edge := _find_enemy_edge(game_state)
	if edge.size() < 2:
		push_error("M12 capture could not find an enemy adjacency")
		quit(1)
		return
	var source_id: String = edge[0]
	var target_id: String = edge[1]
	var player_id := game_state.get_territory(source_id).owner_player_id
	game_state.turn_state.phase = TurnState.Phase.ATTACK

	map_controller.selected_territory_id = ""
	map_controller.set_interaction_context("", "", TurnState.Phase.ATTACK, player_id)
	await _capture("m12-hover.png")

	map_controller.hovered_territory_id = source_id
	map_controller.selected_territory_id = ""
	map_controller.set_interaction_context("", "", TurnState.Phase.ATTACK, player_id)
	await _capture("m12-hover-source.png")

	map_controller.selected_territory_id = source_id
	map_controller.set_interaction_context("", "", TurnState.Phase.ATTACK, player_id)
	await _capture("m12-selected.png")

	map_controller.set_interaction_context(source_id, "", TurnState.Phase.ATTACK, player_id)
	await _capture("m12-valid-target.png")

	map_controller.set_interaction_context(source_id, target_id, TurnState.Phase.ATTACK, player_id)
	await _capture("m12-attack-selection.png")

	for _index in range(5):
		map_controller.zoom_in()
	await _capture("m12-zoomed.png")

	print("M12_VISUAL_CAPTURE: %s source=%s target=%s" % [output_dir, source_id, target_id])
	quit(0)

func _capture(file_name: String) -> void:
	for _index in range(4):
		await process_frame
	var texture := get_root().get_viewport().get_texture()
	if texture == null:
		push_error("M12 capture viewport texture is null")
		quit(1)
		return
	var image := texture.get_image()
	var error := image.save_png(output_dir.path_join(file_name))
	if error != OK:
		push_error("M12 capture failed for %s: %s" % [file_name, str(error)])
		quit(1)

func _find_enemy_edge(game_state: GameState) -> Array[String]:
	for territory_id: String in game_state.map_data.territories:
		var definition := game_state.map_data.get_territory(territory_id)
		var state := game_state.get_territory(territory_id)
		for neighbor_id: String in definition.neighbors:
			var neighbor_state := game_state.get_territory(neighbor_id)
			if neighbor_state != null and neighbor_state.owner_player_id != state.owner_player_id:
				return [territory_id, neighbor_id]
	return []
