extends SceneTree

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_snapshot_restoration()
	_test_forced_trade_restoration_path()
	_test_duplicate_and_finished_guards()
	_test_reconnect_credential_state()
	print("M10_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _test_snapshot_restoration() -> void:
	var game := GameState.create_local_for_player_ids(["P1", "P2"], 101, Ruleset.new())
	var viewer_id := game.turn_state.active_player_id
	var opponent_id := "P2" if viewer_id == "P1" else "P1"
	var viewer := game.get_player(viewer_id)
	var opponent := game.get_player(opponent_id)
	game.match_id = "m10-snapshot"
	game.state_revision = 7
	game.last_action_id = "m10-fortify"
	game.turn_state.phase = TurnState.Phase.ATTACK
	viewer.fortification_used = true
	viewer.pending_trade_reinforcements = 4
	viewer.territory_card_ids = ["TERRITORY_NA_01", "TERRITORY_NA_02"]
	opponent.territory_card_ids = ["SECRET_OPPONENT_CARD"]
	game.pending_reinforcements = {"NA_01": 2}
	game.pending_conquest = {"source_id": "NA_01", "target_id": "NA_02", "minimum": 3}
	game.forced_trade_player_id = viewer_id

	var snapshot := GameStateSnapshot.from_game_state(game, viewer_id)
	var opponent_entry := _player_snapshot(snapshot, opponent_id)
	_expect_equal(snapshot.state_revision, 7, "snapshot keeps authoritative revision")
	_expect_equal(snapshot.pending_reinforcements.get("NA_01", 0), 2, "partial reinforcement is snapshotted")
	_expect_equal(snapshot.pending_conquest.get("minimum", 0), 3, "pending conquest is snapshotted")
	_expect_equal(snapshot.forced_trade_player_id, viewer_id, "forced trade owner is snapshotted")
	_expect(not (opponent_entry.get("territory_card_ids", []) as Array).has("SECRET_OPPONENT_CARD"), "opponent hand stays private")
	_expect_equal(int(opponent_entry.get("territory_card_count", 0)), 1, "opponent card count remains visible")

	var restored := GameState.new()
	_expect(snapshot.apply_to_game_state(restored), "player-scoped snapshot applies")
	var restored_snapshot := GameStateSnapshot.from_game_state(restored, viewer_id)
	_expect_equal(restored_snapshot.fingerprint(), snapshot.fingerprint(), "restored snapshot fingerprint matches")
	_expect_equal(restored.state_revision, game.state_revision, "restored revision matches host")
	_expect_equal(restored.pending_conquest.get("target_id", ""), "NA_02", "restored pending conquest target")
	_expect_equal(restored.get_player(viewer_id).fortification_used, true, "restored fortification flag")
	_expect_equal(restored.get_player(viewer_id).pending_trade_reinforcements, 4, "restored immediate trade pool")
	_expect_equal(restored.forced_trade_player_id, viewer_id, "restored forced trade owner")

func _test_forced_trade_restoration_path() -> void:
	var game := GameState.create_local_for_player_ids(["P1", "P2"], 102, Ruleset.new())
	var player_id := game.turn_state.active_player_id
	var player := game.get_player(player_id)
	var trade_cards: Array[String] = []
	var extra_cards: Array[String] = []
	for card: CardState in game.deck_state.cards.values():
		if card.symbol == CardState.Symbol.INFANTRY and trade_cards.size() < 3:
			trade_cards.append(card.card_id)
		elif extra_cards.size() < 2:
			extra_cards.append(card.card_id)
	player.territory_card_ids = trade_cards + extra_cards
	game.turn_state.phase = TurnState.Phase.ATTACK
	game.forced_trade_player_id = player_id
	var processor := CommandProcessor.new(game, RandomSource.new(103))
	var snapshot := GameStateSnapshot.from_game_state(game, player_id)
	var restored := GameState.new()
	_expect(snapshot.apply_to_game_state(restored), "forced trade snapshot applies")
	var restored_processor := CommandProcessor.new(restored, RandomSource.new(104))
	var trade := restored_processor.execute(CommandEnvelope.new("m10-forced-trade", player_id, restored.state_revision, "trade_cards", {"card_ids": trade_cards}))
	_expect(trade.accepted, "forced trade remains actionable after restore")
	_expect_equal(restored.forced_trade_player_id, "", "forced trade marker clears after valid trade")
	_expect_equal(restored.get_player(player_id).pending_trade_reinforcements, 4, "forced trade bonus survives restore")

func _test_duplicate_and_finished_guards() -> void:
	var game := GameState.create_local_for_player_ids(["P1", "P2"], 105, Ruleset.new())
	var player_id := game.turn_state.active_player_id
	var processor := CommandProcessor.new(game, RandomSource.new(106))
	var surrender := processor.execute(CommandEnvelope.new("m10-inflight", player_id, game.state_revision, "surrender"))
	_expect(surrender.accepted, "in-flight command is accepted once")
	var duplicate := processor.execute(CommandEnvelope.new("m10-inflight", player_id, game.state_revision, "surrender"))
	_expect_equal(duplicate.code, "DUPLICATE_ACTION", "in-flight retry cannot double-apply")
	game.status = GameState.MatchStatus.FINISHED
	var finished := processor.execute(CommandEnvelope.new("m10-after-finished", "P2", game.state_revision, "surrender"))
	_expect_equal(finished.code, "MATCH_FINISHED", "finished match rejects commands")

func _test_reconnect_credential_state() -> void:
	var session: Variant = load("res://scripts/app/session_manager.gd").new()
	session.set_reconnect_credentials("m10-session", "P2", "token-generation-1", "2099-01-01T00:00:00+00:00", 1)
	_expect_equal(session.match_id, "m10-session", "session binds reconnect match")
	_expect_equal(session.player_id, "P2", "session binds reconnect player")
	_expect_equal(session.connection_generation, 1, "session stores initial generation")
	session.set_reconnect_credentials("m10-session", "P2", "token-generation-2", "2099-01-01T00:03:00+00:00", 2)
	_expect_equal(session.reconnect_token, "token-generation-2", "session rotates reconnect token")
	_expect_equal(session.connection_generation, 2, "session rotates connection generation")
	session.clear_reconnect_credentials()
	_expect(session.reconnect_token.is_empty(), "session clears reconnect secret")
	_expect_equal(session.connection_generation, 0, "session clears reconnect generation")
	session.free()

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
