extends SceneTree

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_ruleset_and_deadline()
	_test_warning_and_disabled_timer()
	_test_timeout_phases()
	_test_forced_trade_timeout()
	_test_disconnect_and_reconnect_window()
	_test_disconnect_timer_and_rotation()
	_test_surrender_and_spectator()
	_test_elimination_and_privacy()
	_test_snapshot_deadline_and_status()
	_test_three_player_rotation()
	print("M11_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _test_ruleset_and_deadline() -> void:
	var rules := Ruleset.new()
	_expect_equal(rules.turn_timer_seconds, 180, "default timer is 180 seconds")
	rules.turn_timer_seconds = 0
	var restored_rules := Ruleset.from_dict(rules.to_dict())
	_expect_equal(restored_rules.turn_timer_seconds, 0, "zero disables timer")
	var game := _new_game(201, 180)
	_expect(game.turn_state.turn_started_at_msec > 0, "turn start uses monotonic clock")
	_expect_equal(game.turn_state.turn_deadline_msec, 181000, "deadline is derived from turn start")
	var active := game.turn_state.active_player_id
	game.turn_state.phase = TurnState.Phase.ATTACK
	var processor := CommandProcessor.new(game, RandomSource.new(202))
	var before := game.turn_state.turn_deadline_msec
	processor.advance_time(10000)
	_expect_equal(game.turn_state.turn_deadline_msec, before, "one timer covers every phase")
	_expect_equal(game.turn_state.active_player_id, active, "timer does not rotate before expiry")

func _test_warning_and_disabled_timer() -> void:
	var warning_game := _new_game(203, 180)
	var processor := CommandProcessor.new(warning_game, RandomSource.new(204))
	var warning := processor.advance_time(151000)
	_expect(bool(warning.get("warning", false)), "warning is emitted at 30 seconds")
	_expect(warning_game.is_turn_timer_warning(151000), "warning state is visible to UI")
	var disabled := _new_game(205, 0)
	var disabled_active := disabled.turn_state.active_player_id
	var disabled_processor := CommandProcessor.new(disabled, RandomSource.new(206))
	var result := disabled_processor.advance_time(999999999)
	_expect(not bool(result.get("changed", false)), "disabled timer never expires")
	_expect_equal(disabled.turn_state.active_player_id, disabled_active, "disabled timer keeps turn")

func _test_timeout_phases() -> void:
	var phases := [TurnState.Phase.CARD_TRADE, TurnState.Phase.REINFORCEMENT, TurnState.Phase.ATTACK, TurnState.Phase.FORTIFICATION]
	for index in range(phases.size()):
		var game := _new_game(210 + index, 30)
		var current := game.turn_state.active_player_id
		game.turn_state.phase = phases[index]
		game.turn_state.turn_deadline_msec = 31000
		game.clock.set_now_msec(31000)
		var player := game.get_player(current)
		if phases[index] == TurnState.Phase.REINFORCEMENT:
			var owned := game.owned_territories(current)[0]
			owned.army_count += 2
			game.pending_reinforcements[owned.territory_id] = 2
			player.reinforcements_remaining = 1
		if phases[index] == TurnState.Phase.ATTACK:
			game.pending_conquest = {"source_id": "NA_01", "target_id": "NA_02", "minimum": 1}
			game.get_territory("NA_01").owner_player_id = current
			game.get_territory("NA_01").army_count = 3
			game.get_territory("NA_02").owner_player_id = "P2" if current == "P1" else "P1"
			game.get_territory("NA_02").army_count = 0
		var processor := CommandProcessor.new(game, RandomSource.new(220 + index))
		var result := processor.advance_time(31000)
		_expect(bool(result.get("changed", false)), "phase timeout produces authoritative transition %d" % index)
		_expect(game.turn_state.active_player_id != current, "phase timeout rotates to next player %d" % index)
		_expect(game.pending_conquest.is_empty(), "phase timeout leaves no pending conquest %d" % index)
		_expect(game.turn_state.phase == TurnState.Phase.CARD_TRADE or game.turn_state.phase == TurnState.Phase.REINFORCEMENT, "phase timeout enters legal next turn %d" % index)

func _test_forced_trade_timeout() -> void:
	var game := _new_game(230, 30)
	var player_id := game.turn_state.active_player_id
	var player := game.get_player(player_id)
	var cards: Array[String] = []
	for card: CardState in game.deck_state.cards.values():
		if cards.size() < 3:
			cards.append(card.card_id)
	player.territory_card_ids = cards
	game.turn_state.phase = TurnState.Phase.CARD_TRADE
	game.forced_trade_player_id = player_id
	game.turn_state.turn_deadline_msec = 31000
	var processor := CommandProcessor.new(game, RandomSource.new(231))
	processor.advance_time(31000)
	_expect_equal(game.forced_trade_player_id, "", "forced trade timeout clears mandatory marker")
	_expect(game.turn_state.active_player_id != player_id, "forced trade timeout advances turn")
	_expect(game.turn_state.phase != TurnState.Phase.ATTACK, "forced trade timeout never starts risky attack")

func _test_disconnect_and_reconnect_window() -> void:
	var game := _new_game(240, 30)
	game.ruleset.reconnect_timeout_seconds = 60
	var player_id := game.turn_state.active_player_id
	var processor := CommandProcessor.new(game, RandomSource.new(241))
	var disconnected := processor.mark_disconnected(player_id, 1000)
	_expect(bool(disconnected.get("ok", false)), "disconnect enters temporary state")
	_expect_equal(game.get_player(player_id).status, PlayerState.Status.DISCONNECTED, "temporary disconnect is distinct")
	_expect_equal(game.get_player(player_id).reconnect_deadline_msec, 61000, "reconnect deadline is explicit")
	var reconnected := processor.mark_reconnected(player_id, 2000)
	_expect(bool(reconnected.get("ok", false)), "reconnect before window succeeds")
	_expect_equal(game.get_player(player_id).status, PlayerState.Status.ACTIVE, "reconnect restores active status")
	processor.mark_disconnected(player_id, 3000)
	var expired := processor.advance_time(63000)
	_expect((expired.get("expired_player_ids", []) as Array).has(player_id), "reconnect window expiry is authoritative")
	_expect_equal(game.get_player(player_id).status, PlayerState.Status.LEFT, "permanent left is distinct from surrender")
	_expect(not game.turn_rotation_player_ids().has(player_id), "permanent left is skipped in rotation")
	var late := processor.mark_reconnected(player_id, 64000)
	_expect_equal(str(late.get("code", "")), "RECONNECT_WINDOW_EXPIRED", "late reconnect is rejected")

func _test_disconnect_timer_and_rotation() -> void:
	var game := _new_game(250, 30)
	var current := game.turn_state.active_player_id
	var processor := CommandProcessor.new(game, RandomSource.new(251))
	processor.mark_disconnected(current, 1000)
	game.turn_state.turn_deadline_msec = 31000
	var before := processor.advance_time(30000)
	_expect(game.turn_state.active_player_id == current, "disconnected player is not skipped before timer expiry")
	var after := processor.advance_time(31000)
	_expect(bool(after.get("changed", false)), "disconnected active turn still expires")
	_expect(game.turn_state.active_player_id != current, "expired disconnected turn rotates")
	processor.mark_disconnected(game.turn_state.active_player_id, 32000)
	game.turn_state.turn_deadline_msec = 62000
	processor.mark_reconnected(game.turn_state.active_player_id, 33000)
	_expect_equal(game.get_player(game.turn_state.active_player_id).status, PlayerState.Status.ACTIVE, "reconnect after turn move does not alter rotation")

func _test_surrender_and_spectator() -> void:
	var game := _new_game(260, 180)
	var player_id := game.turn_state.active_player_id
	var processor := CommandProcessor.new(game, RandomSource.new(261))
	var surrender := processor.execute(CommandEnvelope.new("m11-surrender", player_id, game.state_revision, "surrender"))
	_expect(surrender.accepted, "surrender is accepted")
	_expect_equal(game.get_player(player_id).status, PlayerState.Status.SURRENDERED, "surrendered status is separate")
	var duplicate := processor.execute(CommandEnvelope.new("m11-surrender-again", player_id, game.state_revision, "surrender"))
	_expect_equal(duplicate.code, "PLAYER_NOT_ACTIVE", "surrender is idempotently rejected")
	var spectator := processor.enter_spectator(player_id)
	_expect(bool(spectator.get("ok", false)), "surrendered player may enter spectator mode")
	_expect(game.get_player(player_id).spectator_mode, "spectator mode is functional state")
	var command := processor.execute(CommandEnvelope.new("m11-spectator-command", player_id, game.state_revision, "end_phase"))
	_expect_equal(command.code, "PLAYER_NOT_ACTIVE", "spectator command is rejected by host domain")

func _test_elimination_and_privacy() -> void:
	var game := _new_game(270, 180)
	var active := game.turn_state.active_player_id
	var eliminated := "P2" if active == "P1" else "P1"
	for territory: TerritoryState in game.territories.values():
		territory.owner_player_id = active
	game.get_player(eliminated).territory_card_ids = ["SECRET_ELIMINATED_CARD"]
	var eliminated_ids := game.eliminate_empty_players()
	_expect(eliminated_ids.has(eliminated), "empty player is eliminated")
	_expect_equal(game.get_player(eliminated).status, PlayerState.Status.ELIMINATED, "eliminated status is distinct")
	var processor := CommandProcessor.new(game, RandomSource.new(271))
	_expect(bool(processor.enter_spectator(eliminated).get("ok", false)), "eliminated player may spectate")
	var snapshot := GameStateSnapshot.from_game_state(game, "")
	var hidden := _player_snapshot(snapshot, active)
	_expect((hidden.get("territory_card_ids", []) as Array).is_empty(), "spectator receives no private card contents")
	_expect_equal(int(hidden.get("territory_card_count", 0)), game.get_player(active).territory_card_ids.size(), "spectator receives public card count")
	var late := processor.mark_reconnected(eliminated, 9999)
	_expect_equal(str(late.get("code", "")), "PLAYER_NOT_ACTIVE", "elimination cannot be undone by reconnect")

func _test_snapshot_deadline_and_status() -> void:
	var game := _new_game(280, 180)
	game.match_id = "m11-snapshot"
	game.state_revision = 9
	game.turn_state.turn_deadline_msec = 181000
	var disconnected := game.get_player("P2")
	disconnected.status = PlayerState.Status.DISCONNECTED
	disconnected.reconnect_deadline_msec = 999000
	var snapshot := GameStateSnapshot.from_game_state(game, "P1")
	var restored := GameState.new()
	_expect(snapshot.apply_to_game_state(restored), "deadline snapshot applies")
	_expect_equal(restored.turn_state.turn_deadline_msec, 181000, "reconnect snapshot preserves deadline")
	_expect_equal(restored.get_player("P2").status, PlayerState.Status.DISCONNECTED, "reconnect snapshot preserves connection state")
	_expect_equal(restored.get_player("P2").reconnect_deadline_msec, 999000, "reconnect window survives snapshot")
	_expect_equal(GameStateSnapshot.from_game_state(restored, "P1").fingerprint(), snapshot.fingerprint(), "lifecycle snapshot fingerprint matches")

func _test_three_player_rotation() -> void:
	var game := _new_game_with_players(290, 3, 180)
	var processor := CommandProcessor.new(game, RandomSource.new(291))
	var first := game.turn_state.active_player_id
	var surrender := processor.execute(CommandEnvelope.new("m11-three-surrender", first, game.state_revision, "surrender"))
	_expect(surrender.accepted, "three-player surrender accepted")
	var second := game.turn_state.active_player_id
	_expect(second != first and game.get_player(second).is_turn_eligible(), "three-player rotation skips surrendered player")
	var third := ""
	for player_id: String in game.players:
		if player_id != first and player_id != second:
			third = player_id
	_expect(not third.is_empty(), "three-player setup keeps third participant")
	_expect(game.turn_rotation_player_ids().has(third), "third participant remains in rotation")

func _new_game(seed_value: int, timer_seconds: int) -> GameState:
	var rules := Ruleset.new()
	rules.turn_timer_seconds = timer_seconds
	var game := GameState.create_local_for_player_ids(["P1", "P2"], seed_value, rules)
	game.clock.set_now_msec(1000)
	game.turn_state.turn_started_at_msec = 1000
	game.turn_state.turn_deadline_msec = 1000 + timer_seconds * 1000 if timer_seconds > 0 else 0
	return game

func _new_game_with_players(seed_value: int, count: int, timer_seconds: int) -> GameState:
	var ids: Array[String] = []
	for index in range(count):
		ids.append("P%d" % (index + 1))
	var rules := Ruleset.new()
	rules.turn_timer_seconds = timer_seconds
	var game := GameState.create_local_for_player_ids(ids, seed_value, rules)
	game.clock.set_now_msec(1000)
	game.turn_state.turn_started_at_msec = 1000
	game.turn_state.turn_deadline_msec = 1000 + timer_seconds * 1000
	return game

func _player_snapshot(snapshot: GameStateSnapshot, player_id: String) -> Dictionary:
	for value in snapshot.players:
		if str(value.get("player_id", "")) == player_id:
			return value
	return {}

func _expect(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	_expect(actual == expected, "%s (expected=%s actual=%s)" % [label, str(expected), str(actual)])
