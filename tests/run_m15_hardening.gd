extends SceneTree

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_malformed_serialization()
	_test_command_guards()
	_test_reconnect_rapid_cycle()
	_test_timer_and_ruleset_boundaries()
	_test_five_player_snapshot()
	print("M15_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _test_malformed_serialization() -> void:
	_expect(NetworkMessage.from_dict(null) == null, "null network message rejected")
	_expect(NetworkMessage.from_dict({"message_type": "UNKNOWN", "payload": {}}) == null, "unknown network message rejected")
	_expect(NetworkMessage.from_dict({"message_type": NetworkMessage.COMMAND_REQUEST, "payload": []}) == null, "non-dictionary message payload rejected")
	_expect(CommandEnvelope.from_dict(null) == null, "null command envelope rejected")
	_expect(CommandEnvelope.from_dict({"action_id": "x", "player_id": "P1"}) == null, "incomplete command envelope rejected")
	var message := NetworkMessage.new(NetworkMessage.ERROR, {"code": "M15"}, "match", 1)
	var restored := NetworkMessage.from_dict(message.to_dict())
	_expect(restored != null and restored.payload.get("code", "") == "M15", "network message roundtrip remains bounded")

func _test_command_guards() -> void:
	var game := GameState.create_local_for_player_ids(["P1", "P2"], 150, Ruleset.new())
	var player_id := game.turn_state.active_player_id
	var processor := CommandProcessor.new(game, RandomSource.new(151))
	var invalid := processor.execute(null)
	_expect_equal(invalid.code, "INVALID_ENVELOPE", "null command cannot mutate state")
	var unknown := processor.execute(CommandEnvelope.new("m15-unknown", player_id, game.state_revision, "unknown_command"))
	_expect_equal(unknown.code, "UNKNOWN_COMMAND", "unknown command rejected")
	var stale := processor.execute(CommandEnvelope.new("m15-stale", player_id, game.state_revision - 1, "surrender"))
	_expect_equal(stale.code, "STALE_STATE", "stale revision rejected before mutation")
	var valid := processor.execute(CommandEnvelope.new("m15-once", player_id, game.state_revision, "surrender"))
	_expect(valid.accepted, "valid command still accepted")
	var duplicate := processor.execute(CommandEnvelope.new("m15-once", player_id, game.state_revision, "surrender"))
	_expect_equal(duplicate.code, "DUPLICATE_ACTION", "duplicate action rejected")
	_expect_equal(game.state_revision, 1, "duplicate did not increment revision")

func _test_reconnect_rapid_cycle() -> void:
	var game := GameState.create_local_for_player_ids(["P1", "P2"], 152, Ruleset.new())
	var player_id := "P2" if game.turn_state.active_player_id == "P1" else "P1"
	var processor := CommandProcessor.new(game, RandomSource.new(153))
	var first_drop := processor.mark_disconnected(player_id, 1000)
	_expect(bool(first_drop.get("ok", false)), "first disconnect accepted")
	var first_restore := processor.mark_reconnected(player_id, 1001)
	_expect(bool(first_restore.get("ok", false)), "first reconnect accepted")
	var second_drop := processor.mark_disconnected(player_id, 1002)
	_expect(bool(second_drop.get("ok", false)), "second disconnect accepted")
	var second_restore := processor.mark_reconnected(player_id, 1003)
	_expect(bool(second_restore.get("ok", false)), "second reconnect accepted")
	var already_active := processor.mark_reconnected(player_id, 1004)
	_expect_equal(already_active.get("code", ""), "PLAYER_ALREADY_CONNECTED", "third reconnect without drop rejected")

func _test_timer_and_ruleset_boundaries() -> void:
	var invalid_rules := Ruleset.new()
	invalid_rules.turn_timer_seconds = 29
	_expect(not RulesetValidator.validate(invalid_rules).is_empty(), "sub-threshold turn timer rejected")
	invalid_rules = Ruleset.new()
	invalid_rules.reconnect_timeout_seconds = 29
	_expect(not RulesetValidator.validate(invalid_rules).is_empty(), "sub-threshold reconnect window rejected")
	var game := GameState.create_local_for_player_ids(["P1", "P2"], 154, Ruleset.new())
	var processor := CommandProcessor.new(game, RandomSource.new(155))
	var warning := processor.advance_time(game.turn_state.turn_deadline_msec - 30000)
	_expect(bool(warning.get("warning", false)), "timer warning is emitted once")
	var repeated := processor.advance_time(game.turn_state.turn_deadline_msec - 29999)
	_expect(not bool(repeated.get("warning", false)), "timer warning is not spammed")

func _test_five_player_snapshot() -> void:
	var game := GameState.create_local(5, 156, Ruleset.new())
	var viewer_id := game.turn_state.active_player_id
	var snapshot := GameStateSnapshot.from_game_state(game, viewer_id)
	_expect_equal(snapshot.players.size(), 5, "five-player snapshot contains every player")
	var restored := GameState.new()
	_expect(snapshot.apply_to_game_state(restored), "five-player snapshot restores")
	_expect_equal(GameStateSnapshot.from_game_state(restored, viewer_id).fingerprint(), snapshot.fingerprint(), "five-player fingerprint remains identical")

func _expect(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	_expect(actual == expected, "%s (got %s, expected %s)" % [label, str(actual), str(expected)])
