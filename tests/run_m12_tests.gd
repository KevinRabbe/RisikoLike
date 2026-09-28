extends SceneTree

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := GameState.create_local(2, 120)
	var map_controller := MapController.new()
	map_controller.size = Vector2(1200, 700)
	get_root().add_child(map_controller)
	map_controller.configure(game_state.map_data, game_state)
	map_controller.reset_view()
	await process_frame
	_test_visual_definitions(game_state)
	_test_hit_testing(map_controller)
	_test_interaction_states(map_controller, game_state)
	print("M12_TESTS: %d passed, %d failed" % [passed, failed])
	map_controller.queue_free()
	quit(1 if failed > 0 else 0)

func _test_visual_definitions(game_state: GameState) -> void:
	var visuals := MapVisualDefinition.create_default()
	_expect(MapVisualValidator.is_valid(game_state.map_data, visuals), "MAP_SPEC visual definitions validate")
	_expect_equal(visuals.size(), 42, "exactly 42 visual definitions")
	for territory_id: String in game_state.map_data.territories:
		var visual := visuals.get(territory_id) as TerritoryVisualDefinition
		_expect(visual != null, "visual exists for %s" % territory_id)
		if visual != null:
			_expect(visual.polygon.size() >= 3, "polygon renders for %s" % territory_id)
			_expect(visual.label_position != Vector2.ZERO, "label anchor renders for %s" % territory_id)
			_expect(visual.marker_position != Vector2.ZERO, "marker anchor renders for %s" % territory_id)

func _test_hit_testing(map_controller: MapController) -> void:
	var checks := ["NA_01", "EU_05", "AS_11", "OC_04"]
	for territory_id: String in checks:
		var visual := map_controller.map_surface.visuals[territory_id] as TerritoryVisualDefinition
		var screen_position := map_controller.map_surface.position + visual.marker_position * map_controller.zoom_level
		_expect_equal(map_controller.territory_at_screen_position(screen_position), territory_id, "marker hit testing %s" % territory_id)
	map_controller.zoom_in()
	var zoomed_visual := map_controller.map_surface.visuals["EU_05"] as TerritoryVisualDefinition
	var zoomed_screen_position := map_controller.map_surface.position + zoomed_visual.marker_position * map_controller.zoom_level
	_expect_equal(map_controller.territory_at_screen_position(zoomed_screen_position), "EU_05", "hit testing survives zoom")
	map_controller.pan_offset += Vector2(60, -20)
	map_controller._layout_surface()
	var panned_screen_position := map_controller.map_surface.position + zoomed_visual.marker_position * map_controller.zoom_level
	_expect_equal(map_controller.territory_at_screen_position(panned_screen_position), "EU_05", "hit testing survives pan")

func _test_interaction_states(map_controller: MapController, game_state: GameState) -> void:
	game_state.get_territory("NA_01").owner_player_id = "P1"
	game_state.get_territory("NA_02").owner_player_id = "P2"
	game_state.get_territory("NA_06").owner_player_id = "P1"
	map_controller.selected_territory_id = "NA_01"
	map_controller.set_interaction_context("NA_01", "", TurnState.Phase.ATTACK, "P1")
	_expect_equal(map_controller.map_surface._interaction_for("NA_02"), "valid", "enemy neighbor is a valid target")
	map_controller.set_interaction_context("NA_01", "NA_06", TurnState.Phase.ATTACK, "P1")
	_expect_equal(map_controller.map_surface._interaction_for("NA_06"), "invalid", "own neighbor is an invalid attack target")
	map_controller.set_interaction_context("NA_01", "NA_02", TurnState.Phase.ATTACK, "P1")
	_expect_equal(map_controller.map_surface._interaction_for("NA_02"), "target", "selected attack target is distinct")
	map_controller.set_interaction_context("NA_01", "NA_06", TurnState.Phase.FORTIFICATION, "P1")
	_expect_equal(map_controller.map_surface._interaction_for("NA_06"), "target", "own neighbor is a valid fortification target")

func _expect(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	_expect(actual == expected, "%s (got %s, expected %s)" % [label, str(actual), str(expected)])
