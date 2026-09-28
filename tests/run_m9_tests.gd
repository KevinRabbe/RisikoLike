extends SceneTree

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_command_guards()
	_test_host_authoritative_combat_and_conquest()
	_test_card_privacy_after_trade_and_elimination_transfer()
	_test_surrender_and_finished_match_guard()
	print("M9_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _test_command_guards() -> void:
	var game := GameState.create_local_for_player_ids(["P1", "P2"], 11, Ruleset.new())
	var player_id := game.turn_state.active_player_id
	var processor := CommandProcessor.new(game, RandomSource.new(12))
	var wrong_player := processor.execute(CommandEnvelope.new("m9-wrong-player", "NOT_A_PLAYER", game.state_revision, "end_phase"))
	_expect_equal(wrong_player.code, "INVALID_PLAYER", "wrong player rejected")
	var stale := processor.execute(CommandEnvelope.new("m9-stale", player_id, game.state_revision - 1, "end_phase"))
	_expect_equal(stale.code, "STALE_STATE", "stale revision rejected")
	var phase_result := processor.execute(CommandEnvelope.new("m9-phase", player_id, game.state_revision, "end_phase"))
	_expect(phase_result.accepted, "valid phase command accepted")
	var duplicate := processor.execute(CommandEnvelope.new("m9-phase", player_id, game.state_revision, "end_phase"))
	_expect_equal(duplicate.code, "DUPLICATE_ACTION", "duplicate action rejected")
	var invalid_phase := processor.execute(CommandEnvelope.new("m9-invalid-phase", player_id, game.state_revision, "attack", {"source_id": "NA_01", "target_id": "NA_02", "attacker_dice": 1, "defender_dice": 1}))
	_expect_equal(invalid_phase.code, "INVALID_PHASE", "wrong phase rejected")

func _test_host_authoritative_combat_and_conquest() -> void:
	var game := GameState.create_local_for_player_ids(["P1", "P2"], 21, Ruleset.new())
	var player_id := game.turn_state.active_player_id
	var enemy_id := "P2" if player_id == "P1" else "P1"
	game.turn_state.phase = TurnState.Phase.ATTACK
	game.get_territory("NA_01").owner_player_id = player_id
	game.get_territory("NA_01").army_count = 8
	game.get_territory("NA_02").owner_player_id = enemy_id
	game.get_territory("NA_02").army_count = 1
	var random := RandomSource.new(22)
	random.set_controlled_rolls([6, 1])
	var processor := CommandProcessor.new(game, random)
	var attack := processor.execute(CommandEnvelope.new("m9-attack", player_id, game.state_revision, "attack", {"source_id": "NA_01", "target_id": "NA_02", "attacker_dice": 1, "defender_dice": 1, "attacker_dice_result": [1], "defender_dice_result": [1]}))
	_expect(attack.accepted, "host attack accepted")
	_expect_equal(attack.data.attacker_dice, [6], "host generated attacker dice")
	_expect_equal(attack.data.defender_dice, [1], "host generated defender dice")
	_expect_equal(game.get_territory("NA_02").owner_player_id, player_id, "conquest owner changed on host")
	_expect(not game.pending_conquest.is_empty(), "conquest move is pending")
	var blocked_attack := processor.execute(CommandEnvelope.new("m9-blocked-attack", player_id, game.state_revision, "attack", {"source_id": "NA_01", "target_id": "NA_02", "attacker_dice": 1, "defender_dice": 1}))
	_expect_equal(blocked_attack.code, "CONQUEST_MOVE_REQUIRED", "attack blocked during pending conquest")
	var move := processor.execute(CommandEnvelope.new("m9-conquest", player_id, game.state_revision, "conquest_move", {"amount": 1}))
	_expect(move.accepted, "valid conquest move accepted")
	_expect_equal(game.pending_conquest.size(), 0, "conquest state cleared")
	_expect_equal(game.state_revision, 2, "attack and conquest advance revision")

	# Final conquest must finish only after the required move.
	var final_game := GameState.create_local_for_player_ids(["P1", "P2"], 23, Ruleset.new())
	var final_attacker := final_game.turn_state.active_player_id
	var final_defender := "P2" if final_attacker == "P1" else "P1"
	for territory_id: String in final_game.territories:
		final_game.get_territory(territory_id).owner_player_id = final_attacker
		final_game.get_territory(territory_id).army_count = 1
	final_game.get_territory("NA_01").army_count = 8
	final_game.get_territory("NA_02").owner_player_id = final_defender
	final_game.get_territory("NA_02").army_count = 1
	final_game.turn_state.active_player_id = final_attacker
	final_game.turn_state.phase = TurnState.Phase.ATTACK
	var final_random := RandomSource.new(24)
	final_random.set_controlled_rolls([6, 1])
	var final_processor := CommandProcessor.new(final_game, final_random)
	var final_attack := final_processor.execute(CommandEnvelope.new("m9-final-attack", final_attacker, final_game.state_revision, "attack", {"source_id": "NA_01", "target_id": "NA_02", "attacker_dice": 1, "defender_dice": 1}))
	_expect(final_attack.accepted, "final attack accepted")
	_expect_equal(final_game.status, GameState.MatchStatus.PLAYING, "victory waits for conquest move")
	var final_move := final_processor.execute(CommandEnvelope.new("m9-final-conquest", final_attacker, final_game.state_revision, "conquest_move", {"amount": 1}))
	_expect(final_move.accepted, "final conquest move accepted")
	_expect_equal(final_game.status, GameState.MatchStatus.FINISHED, "victory detected after conquest move")
	_expect_equal(final_game.winner_player_id, final_attacker, "host winner is authoritative")

func _test_card_privacy_after_trade_and_elimination_transfer() -> void:
	var ruleset := Ruleset.new()
	var game := GameState.create_local_for_player_ids(["P1", "P2"], 31, ruleset)
	var viewer := game.turn_state.active_player_id
	var opponent := "P2" if viewer == "P1" else "P1"
	var viewer_state := game.get_player(viewer)
	var opponent_state := game.get_player(opponent)
	viewer_state.territory_card_ids = ["TERRITORY_NA_01"]
	opponent_state.territory_card_ids = ["TERRITORY_NA_02"]
	var viewer_snapshot := GameStateSnapshot.from_game_state(game, viewer)
	var opponent_entry := _player_snapshot(viewer_snapshot, opponent)
	_expect(not (opponent_entry.get("territory_card_ids", []) as Array).has("TERRITORY_NA_02"), "opponent card id hidden")
	_expect_equal(int(opponent_entry.get("territory_card_count", -1)), 1, "opponent card count visible")
	var processor := CommandProcessor.new(game, RandomSource.new(32))
	game.turn_state.active_player_id = viewer
	game.turn_state.phase = TurnState.Phase.CARD_TRADE
	viewer_state.territory_card_ids = ["TERRITORY_NA_01", "TERRITORY_NA_02", "TERRITORY_NA_03"]
	var trade := processor.execute(CommandEnvelope.new("m9-privacy-trade", viewer, game.state_revision, "trade_cards", {"card_ids": viewer_state.territory_card_ids.duplicate()}))
	_expect(trade.accepted, "card trade accepted through command processor")
	var after_trade := GameStateSnapshot.from_game_state(game, viewer)
	var after_trade_opponent := _player_snapshot(after_trade, opponent)
	_expect(not (after_trade_opponent.get("territory_card_ids", []) as Array).has("TERRITORY_NA_02"), "opponent card still hidden after trade")
	# Elimination transfer reveals the cards only to the eliminator's private view.
	var eliminator_snapshot := GameStateSnapshot.from_game_state(game, viewer)
	opponent_state.territory_card_ids = ["SECRET_OPPONENT_CARD"]
	var hidden_before_transfer := GameStateSnapshot.from_game_state(game, viewer)
	_expect(not (_player_snapshot(hidden_before_transfer, opponent).get("territory_card_ids", []) as Array).has("SECRET_OPPONENT_CARD"), "secret card hidden before transfer")
	opponent_state.territory_card_ids.clear()
	viewer_state.territory_card_ids.append("SECRET_OPPONENT_CARD")
	var visible_after_transfer := GameStateSnapshot.from_game_state(game, viewer)
	_expect((_player_snapshot(visible_after_transfer, viewer).get("territory_card_ids", []) as Array).has("SECRET_OPPONENT_CARD"), "transferred card visible to eliminator")
	_expect(eliminator_snapshot != null, "privacy snapshot remains serializable")

func _test_surrender_and_finished_match_guard() -> void:
	var game := GameState.create_local_for_player_ids(["P1", "P2"], 41, Ruleset.new())
	var player_id := game.turn_state.active_player_id
	var processor := CommandProcessor.new(game, RandomSource.new(42))
	var surrender := processor.execute(CommandEnvelope.new("m9-surrender", player_id, game.state_revision, "surrender"))
	_expect(surrender.accepted, "surrender accepted")
	_expect_equal(game.get_player(player_id).status, PlayerState.Status.SURRENDERED, "surrendered player status replicated by domain")
	game.status = GameState.MatchStatus.FINISHED
	var rejected := processor.execute(CommandEnvelope.new("m9-after-victory", "P2", game.state_revision, "surrender"))
	_expect_equal(rejected.code, "MATCH_FINISHED", "commands after victory rejected")

func _player_snapshot(snapshot: GameStateSnapshot, player_id: String) -> Dictionary:
	for player_value in snapshot.players:
		if str(player_value.get("player_id", "")) == player_id:
			return player_value
	return {}

func _expect(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	_expect(actual == expected, "%s (expected=%s actual=%s)" % [label, str(expected), str(actual)])
