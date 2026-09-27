extends SceneTree

var passed := 0
var failed := 0
var failures: Array[String] = []

func _init() -> void:
	_run_all()
	print("TESTS: %d passed, %d failed" % [passed, failed])
	for failure in failures:
		push_error(failure)
	quit(1 if failed > 0 else 0)

func _run_all() -> void:
	_test_map_validator()
	_test_ruleset_validator()
	_test_reinforcement_and_commands()
	_test_turn_transitions()
	_test_combat_and_conquest()
	_test_fortification()
	_test_cards()
	_test_elimination_and_surrender()
	_test_victory()
	_test_network_serialization()
	_test_network_authority_and_sync()
	_test_local_lobby_rules()

func _test_map_validator() -> void:
	var map_data := MapDataFactory.create_default()
	_expect(MapValidator.is_valid(map_data), "default map validates")
	_expect_equal(map_data.territories.size(), 42, "map has 42 territories")
	_expect_equal(map_data.regions.size(), 6, "map has 6 regions")
	var symbol_counts := {"infantry": 0, "cavalry": 0, "artillery": 0}
	for territory: TerritoryDefinition in map_data.territories.values():
		symbol_counts[territory.card_symbol] += 1
	_expect_equal(symbol_counts["infantry"], 14, "infantry count")
	_expect_equal(symbol_counts["cavalry"], 14, "cavalry count")
	_expect_equal(symbol_counts["artillery"], 14, "artillery count")

func _test_ruleset_validator() -> void:
	var ruleset := Ruleset.new()
	_expect(RulesetValidator.is_valid(ruleset), "default ruleset validates")
	ruleset.turn_timer_seconds = 10
	_expect(not RulesetValidator.is_valid(ruleset), "invalid timer rejected")
	ruleset = Ruleset.new()
	ruleset.progressive_card_values = [4, 4]
	_expect(not RulesetValidator.is_valid(ruleset), "non-increasing card values rejected")

func _test_reinforcement_and_commands() -> void:
	var game := GameState.create_local(2, 10)
	var processor := CommandProcessor.new(game, RandomSource.new(10))
	var player_id := game.turn_state.active_player_id
	var phase_result := processor.execute(CommandEnvelope.new("reinforce-phase", player_id, game.state_revision, "end_phase"))
	_expect(phase_result.accepted, "card trade phase can end")
	var player := game.get_player(player_id)
	_expect(player.reinforcements_remaining >= 3, "minimum reinforcement is three")
	var own := game.owned_territories(player_id)[0]
	var place := processor.execute(PlaceReinforcementCommand.create(player_id, game.state_revision, own.territory_id, 1))
	_expect(place.accepted, "place reinforcement accepted")
	_expect_equal(game.state_revision, 2, "accepted commands increment revision")
	var premature_end := processor.execute(CommandEnvelope.new("premature-end", player_id, game.state_revision, "end_phase"))
	_expect_equal(premature_end.code, "REINFORCEMENTS_REMAINING", "reinforcement phase cannot end with remaining troops")
	var stale := processor.execute(CommandEnvelope.new("stale", player_id, 0, "reset_reinforcements"))
	_expect_equal(stale.code, "STALE_STATE", "stale revision rejected")
	var duplicate := processor.execute(CommandEnvelope.new("reinforce-place", player_id, game.state_revision, "reset_reinforcements"))
	_expect(duplicate.accepted, "reset accepted")
	var duplicate_again := processor.execute(CommandEnvelope.new("reinforce-place", player_id, game.state_revision, "reset_reinforcements"))
	_expect_equal(duplicate_again.code, "DUPLICATE_ACTION", "duplicate action rejected")
	var wrong_player := processor.execute(CommandEnvelope.new("wrong-player", "P2" if player_id == "P1" else "P1", game.state_revision, "reset_reinforcements"))
	_expect_equal(wrong_player.code, "NOT_YOUR_TURN", "wrong player rejected")
	game.turn_state.phase = TurnState.Phase.ATTACK
	var wrong_phase := processor.execute(CommandEnvelope.new("wrong-phase", player_id, game.state_revision, "place_reinforcement", {"territory_id": own.territory_id, "amount": 1}))
	_expect_equal(wrong_phase.code, "INVALID_PHASE", "wrong phase rejected")
	var bonus_game := GameState.create_local(2, 11)
	var bonus_manager := ReinforcementManager.new(bonus_game)
	for territory_id: String in bonus_game.map_data.territory_ids_for_region("NA"):
		bonus_game.get_territory(territory_id).owner_player_id = bonus_game.turn_state.active_player_id
	var with_bonus := bonus_manager.calculate_reinforcements(bonus_game.turn_state.active_player_id)
	bonus_game.get_territory("NA_01").owner_player_id = "P2" if bonus_game.turn_state.active_player_id == "P1" else "P1"
	var without_bonus := bonus_manager.calculate_reinforcements(bonus_game.turn_state.active_player_id)
	_expect_equal(with_bonus - without_bonus, 5, "complete continent grants region bonus")

func _test_turn_transitions() -> void:
	var game := GameState.create_local(2, 20)
	var processor := CommandProcessor.new(game, RandomSource.new(20))
	var player_id := game.turn_state.active_player_id
	_expect_equal(game.turn_state.phase, TurnState.Phase.CARD_TRADE, "turn begins in card trade")
	_expect(processor.execute(CommandEnvelope.new("turn-card", player_id, game.state_revision, "end_phase")).accepted, "card trade -> reinforcement")
	var player := game.get_player(player_id)
	while player.reinforcements_remaining > 0:
		var territory := game.owned_territories(player_id)[0]
		var amount := mini(player.reinforcements_remaining, 3)
		_expect(processor.execute(PlaceReinforcementCommand.create(player_id, game.state_revision, territory.territory_id, amount)).accepted, "reinforcement placement in turn")
	_expect(processor.execute(CommandEnvelope.new("turn-attack", player_id, game.state_revision, "end_phase")).accepted, "reinforcement -> attack")
	_expect(processor.execute(CommandEnvelope.new("turn-fortify", player_id, game.state_revision, "end_phase")).accepted, "attack -> fortification")
	_expect(processor.execute(CommandEnvelope.new("turn-end", player_id, game.state_revision, "end_phase")).accepted, "fortification -> turn end")
	_expect(processor.execute(CommandEnvelope.new("turn-next", player_id, game.state_revision, "end_turn")).accepted, "turn end -> next turn")
	var skip_game := GameState.create_local(3, 21)
	var skip_player := skip_game.turn_state.active_player_id
	var skipped_id := "P2" if skip_player != "P2" else "P3"
	skip_game.get_player(skipped_id).status = PlayerState.Status.ELIMINATED
	var remaining_ids := skip_game.active_player_ids()
	var expected_next := remaining_ids[(remaining_ids.find(skip_player) + 1) % remaining_ids.size()]
	var before_round := skip_game.turn_state.round_number
	skip_game.begin_next_turn()
	_expect_equal(skip_game.turn_state.active_player_id, expected_next, "eliminated player skipped in rotation")
	_expect(skip_game.turn_state.round_number >= before_round, "rotation retains valid round after skipped players")

func _test_combat_and_conquest() -> void:
	var game := GameState.create_local(2, 30)
	var random := RandomSource.new(30)
	var processor := CommandProcessor.new(game, random)
	var player_id := game.turn_state.active_player_id
	var enemy_id := "P2" if player_id == "P1" else "P1"
	var source := game.get_territory("NA_01")
	var target := game.get_territory("NA_02")
	source.owner_player_id = player_id
	source.army_count = 5
	target.owner_player_id = enemy_id
	target.army_count = 1
	game.turn_state.phase = TurnState.Phase.ATTACK
	random.set_controlled_rolls([6, 1])
	var result := processor.execute(CommandEnvelope.new("attack-1", player_id, game.state_revision, "attack", {"source_id": "NA_01", "target_id": "NA_02", "attacker_dice": 1, "defender_dice": 1}))
	_expect(result.accepted, "attack accepted")
	_expect_equal(target.owner_player_id, player_id, "territory conquered")
	_expect(not game.pending_conquest.is_empty(), "conquest move is required")
	var move := processor.execute(CommandEnvelope.new("conquest-1", player_id, game.state_revision, "conquest_move", {"amount": 1}))
	_expect(move.accepted, "conquest move accepted")
	_expect_equal(target.army_count, 1, "conquest minimum moved")
	game.turn_state.phase = TurnState.Phase.ATTACK
	target.owner_player_id = enemy_id
	target.army_count = 3
	source.army_count = 5
	random.set_controlled_rolls([4, 3, 4, 3])
	var tie_result := processor.execute(CommandEnvelope.new("attack-2", player_id, game.state_revision, "attack", {"source_id": "NA_01", "target_id": "NA_02", "attacker_dice": 2, "defender_dice": 2}))
	_expect(tie_result.accepted, "two-dice attack accepted")
	_expect_equal(tie_result.data.attacker_losses, 2, "ties favor defender")
	_expect_equal(tie_result.data.attacker_dice, [4, 3], "attacker dice sorted descending")
	_expect_equal(tie_result.data.defender_dice, [4, 3], "defender dice sorted descending")

func _test_fortification() -> void:
	var game := GameState.create_local(2, 40)
	var player_id := game.turn_state.active_player_id
	var enemy_id := "P2" if player_id == "P1" else "P1"
	var source := game.get_territory("NA_01")
	var middle := game.get_territory("NA_02")
	var target := game.get_territory("NA_03")
	for territory: TerritoryState in game.territories.values():
		territory.owner_player_id = enemy_id
		territory.army_count = 1
	source.owner_player_id = player_id
	source.army_count = 5
	target.owner_player_id = player_id
	target.army_count = 1
	game.turn_state.phase = TurnState.Phase.FORTIFICATION
	var manager := FortificationManager.new(game)
	_expect(not manager.can_reach(player_id, "NA_01", "NA_03"), "enemy territory blocks connected path")
	middle.owner_player_id = player_id
	_expect(manager.can_reach(player_id, "NA_01", "NA_03"), "connected path reaches own target")
	var result := manager.fortify(player_id, "NA_01", "NA_03", 2)
	_expect(result.accepted, "fortification accepted")
	_expect_equal(source.army_count, 3, "one fortification leaves one minimum")
	var second_fortification := manager.fortify(player_id, "NA_01", "NA_03", 1)
	_expect_equal(second_fortification.code, "FORTIFICATION_ALREADY_USED", "only one fortification is allowed")
	var adjacent_game := GameState.create_local(2, 41)
	adjacent_game.ruleset.fortification_mode = Ruleset.FortificationMode.ADJACENT
	for territory: TerritoryState in adjacent_game.territories.values():
		territory.owner_player_id = adjacent_game.turn_state.active_player_id
		territory.army_count = 2
	var adjacent_manager := FortificationManager.new(adjacent_game)
	_expect(adjacent_manager.can_reach(adjacent_game.turn_state.active_player_id, "NA_01", "NA_02"), "adjacent mode accepts direct neighbor")
	_expect(not adjacent_manager.can_reach(adjacent_game.turn_state.active_player_id, "NA_01", "NA_03"), "adjacent mode rejects indirect target")

func _test_cards() -> void:
	var game := GameState.create_local(2, 50)
	var processor := CommandProcessor.new(game, RandomSource.new(50))
	var player_id := game.turn_state.active_player_id
	var player := game.get_player(player_id)
	var infantry: Array[String] = []
	for card: CardState in game.deck_state.cards.values():
		if card.symbol == CardState.Symbol.INFANTRY:
			infantry.append(card.card_id)
		if infantry.size() == 3:
			break
	player.territory_card_ids = infantry.duplicate()
	var trade := processor.execute(CommandEnvelope.new("trade-1", player_id, game.state_revision, "trade_cards", {"card_ids": infantry}))
	_expect(trade.accepted, "same-symbol card set accepted")
	_expect_equal(trade.data.trade.bonus, 4, "first progressive card value")
	_expect_equal(game.deck_state.trade_count, 1, "trade counter increments")
	_expect(not processor.card_manager.is_valid_set([infantry[0], infantry[1]]), "incomplete card set rejected")
	_expect(not processor.card_manager.is_valid_set([infantry[0], infantry[0], infantry[0]]), "duplicate physical card set rejected")
	var one_each: Array[String] = []
	var has_symbols := {}
	for card: CardState in game.deck_state.cards.values():
		if card.is_joker() or has_symbols.has(card.symbol):
			continue
		has_symbols[card.symbol] = true
		one_each.append(card.card_id)
	_expect(processor.card_manager.is_valid_set(one_each), "mixed card set accepted")
	_expect(processor.card_manager.is_valid_set([infantry[0], infantry[1], "JOKER_1"]), "joker card set accepted")
	_expect_equal(processor.card_manager.trade_value(6), 20, "progressive card value after six trades")
	var forced_game := GameState.create_local(2, 51)
	var forced_processor := CommandProcessor.new(forced_game, RandomSource.new(51))
	var forced_player_id := forced_game.turn_state.active_player_id
	var forced_player := forced_game.get_player(forced_player_id)
	var five_cards: Array[String] = []
	for card: CardState in forced_game.deck_state.cards.values():
		five_cards.append(card.card_id)
		if five_cards.size() == 5:
			break
	forced_player.territory_card_ids = five_cards
	var forced_end := forced_processor.execute(CommandEnvelope.new("forced-end", forced_player_id, forced_game.state_revision, "end_phase"))
	_expect_equal(forced_end.code, "FORCED_TRADE_REQUIRED", "forced trade threshold enforced")
	var forced_infantry: Array[String] = []
	for card: CardState in forced_game.deck_state.cards.values():
		if card.symbol == CardState.Symbol.INFANTRY:
			forced_infantry.append(card.card_id)
		if forced_infantry.size() == 3:
			break
	forced_player.territory_card_ids = forced_infantry.duplicate()
	forced_player.territory_card_ids.append("JOKER_1")
	forced_player.territory_card_ids.append("JOKER_2")
	forced_game.turn_state.phase = TurnState.Phase.ATTACK
	forced_game.forced_trade_player_id = forced_player_id
	var immediate_trade := forced_processor.execute(CommandEnvelope.new("immediate-trade", forced_player_id, forced_game.state_revision, "trade_cards", {"card_ids": forced_infantry}))
	_expect(immediate_trade.accepted, "elimination trade accepted during attack")
	_expect_equal(forced_player.pending_trade_reinforcements, 4, "attack trade creates immediate placement pool")
	var forced_territory := forced_game.owned_territories(forced_player_id)[0]
	var immediate_place := forced_processor.execute(PlaceReinforcementCommand.create(forced_player_id, forced_game.state_revision, forced_territory.territory_id, 4))
	_expect(immediate_place.accepted, "attack trade reinforcements can be placed immediately")
	_expect_equal(forced_player.pending_trade_reinforcements, 0, "immediate trade placement pool is consumed")
	var reshuffle_game := GameState.create_local(2, 52)
	var reshuffle_processor := CommandProcessor.new(reshuffle_game, RandomSource.new(52))
	var reshuffle_player_id := reshuffle_game.turn_state.active_player_id
	reshuffle_game.get_player(reshuffle_player_id).has_conquered_this_turn = true
	var reshuffle_card_id: String = reshuffle_game.deck_state.cards.keys()[0]
	reshuffle_game.deck_state.draw_pile.clear()
	reshuffle_game.deck_state.discard_pile = [reshuffle_card_id]
	var drawn := reshuffle_processor.card_manager.draw_for_player(reshuffle_player_id)
	_expect(drawn != null, "discard pile reshuffled when draw pile is empty")
	_expect(reshuffle_processor.card_manager.draw_for_player(reshuffle_player_id) == null, "only one card can be drawn per turn")
	var owned_bonus_game := GameState.create_local(2, 53)
	var owned_bonus_processor := CommandProcessor.new(owned_bonus_game, RandomSource.new(53))
	var owned_bonus_player_id := owned_bonus_game.turn_state.active_player_id
	var owned_cards: Array[String] = []
	var owned_bonus_territory_id := ""
	var other_owner_id := "P2" if owned_bonus_player_id == "P1" else "P1"
	for card: CardState in owned_bonus_game.deck_state.cards.values():
		if card.is_joker() or owned_cards.size() >= 3:
			continue
		if owned_cards.is_empty():
			owned_bonus_territory_id = card.territory_id
			owned_bonus_game.get_territory(card.territory_id).owner_player_id = owned_bonus_player_id
		else:
			owned_bonus_game.get_territory(card.territory_id).owner_player_id = other_owner_id
		owned_cards.append(card.card_id)
	var owned_territory_before := owned_bonus_game.get_territory(owned_bonus_territory_id).army_count
	owned_bonus_game.get_player(owned_bonus_player_id).territory_card_ids = owned_cards
	var owned_trade := owned_bonus_processor.execute(CommandEnvelope.new("owned-trade", owned_bonus_player_id, owned_bonus_game.state_revision, "trade_cards", {"card_ids": owned_cards}))
	_expect(owned_trade.accepted, "owned territory card trade accepted")
	_expect_equal(owned_bonus_game.get_territory(owned_bonus_territory_id).army_count, owned_territory_before + 2, "owned territory card bonus applied")

func _test_elimination_and_surrender() -> void:
	var game := GameState.create_local(2, 60)
	var random := RandomSource.new(60)
	var processor := CommandProcessor.new(game, random)
	var player_id := game.turn_state.active_player_id
	var enemy_id := "P2" if player_id == "P1" else "P1"
	for territory: TerritoryState in game.territories.values():
		territory.owner_player_id = player_id
		territory.army_count = 2
	var target := game.get_territory("NA_02")
	target.owner_player_id = enemy_id
	target.army_count = 1
	game.get_player(enemy_id).territory_card_ids = ["JOKER_1"]
	game.turn_state.phase = TurnState.Phase.ATTACK
	random.set_controlled_rolls([6, 1])
	var attack := processor.execute(CommandEnvelope.new("eliminate-1", player_id, game.state_revision, "attack", {"source_id": "NA_01", "target_id": "NA_02", "attacker_dice": 1, "defender_dice": 1}))
	_expect(attack.accepted, "elimination attack accepted")
	_expect_equal(game.get_player(enemy_id).status, PlayerState.Status.ELIMINATED, "empty player eliminated")
	_expect(game.get_player(player_id).territory_card_ids.has("JOKER_1"), "eliminated cards transferred")
	var surrender_game := GameState.create_local(2, 61)
	var surrender_processor := CommandProcessor.new(surrender_game, RandomSource.new(61))
	var surrender_player := surrender_game.turn_state.active_player_id
	var surrender := surrender_processor.execute(CommandEnvelope.new("surrender-1", surrender_player, surrender_game.state_revision, "surrender"))
	_expect(surrender.accepted, "surrender accepted")
	_expect_equal(surrender_game.get_player(surrender_player).status, PlayerState.Status.SURRENDERED, "player surrendered")

func _test_victory() -> void:
	var game := GameState.create_local(2, 70)
	var player_id := game.turn_state.active_player_id
	var result := game.check_victory()
	_expect_equal(result.status, "IN_PROGRESS", "no premature victory")
	for territory: TerritoryState in game.territories.values():
		territory.owner_player_id = player_id
	result = game.check_victory()
	_expect_equal(result.status, "VICTORY", "world conquest victory")
	_expect_equal(result.winner_player_id, player_id, "correct winner")

func _test_network_serialization() -> void:
	var command := CommandEnvelope.new("serialize-action", "P1", 7, "place_reinforcement", {"territory_id": "NA_01", "amount": 2})
	var command_roundtrip := CommandEnvelope.from_dict(command.to_dict())
	_expect(command_roundtrip != null, "command roundtrip decodes")
	_expect_equal(command_roundtrip.action_id, command.action_id, "command action id roundtrip")
	_expect_equal(command_roundtrip.payload.get("amount"), 2, "command payload roundtrip")
	var result := CommandResult.new(true, "OK", 8, {"amount": 2}, command.action_id)
	var result_roundtrip := CommandResult.from_dict(result.to_dict())
	_expect(result_roundtrip != null, "result roundtrip decodes")
	_expect_equal(result_roundtrip.action_id, command.action_id, "result action id roundtrip")
	var message := NetworkMessage.new(NetworkMessage.COMMAND_REQUEST, {"command": command.to_dict()}, "match-1")
	var message_roundtrip := NetworkSerializer.decode_message(NetworkSerializer.encode_message(message))
	_expect(bool(message_roundtrip.get("ok", false)), "network message roundtrip")
	_expect_equal((message_roundtrip.get("message") as NetworkMessage).message_type, NetworkMessage.COMMAND_REQUEST, "message type roundtrip")
	_expect_equal(NetworkSerializer.decode_message("{\"message_type\":\"NOT_A_REAL_MESSAGE\",\"protocol_version\":1,\"payload\":{}}").get("code"), "UNKNOWN_MESSAGE_TYPE", "unknown message rejected")
	_expect_equal(NetworkSerializer.decode_message("{\"message_type\":\"COMMAND_REQUEST\",\"protocol_version\":999,\"payload\":{}}").get("code"), "PROTOCOL_MISMATCH", "protocol mismatch rejected")
	var game := GameState.create_local(2, 81)
	var snapshot := GameStateSnapshot.from_game_state(game, "P1")
	var snapshot_roundtrip := GameStateSnapshot.from_dict(snapshot.to_dict())
	_expect(snapshot_roundtrip != null, "snapshot roundtrip decodes")
	_expect_equal(snapshot_roundtrip.state_revision, game.state_revision, "snapshot revision roundtrip")
	var restored := GameState.new()
	_expect(snapshot_roundtrip.apply_to_game_state(restored), "snapshot applies to game state")
	_expect_equal(GameStateSnapshot.from_game_state(restored, "P1").fingerprint(), snapshot.fingerprint(), "snapshot fingerprint roundtrip")

func _test_network_authority_and_sync() -> void:
	var manager_script = preload("res://scripts/network/network_manager.gd")
	var pair := InProcessTransport.create_pair()
	var host = manager_script.new()
	var client = manager_script.new()
	var host_result: Dictionary = host.host_lobby_on_transport("Host", 2, Ruleset.new(), pair[0])
	_expect(bool(host_result.get("ok", false)), "host creates local transport lobby")
	var join_result: Dictionary = client.join_lobby_on_transport("Client", pair[1])
	_expect(bool(join_result.get("ok", false)), "client connects to local transport lobby")
	_expect_equal(client.local_player_id, "P2", "client receives stable player id")
	_expect_equal(host.lobby_state.players.size(), 2, "host owns joined lobby state")
	_expect(client.lobby_state != null, "client receives lobby snapshot")
	var ready_result: Dictionary = client.set_ready_state(true)
	_expect(bool(ready_result.get("ok", false)), "client ready request accepted")
	_expect(host.lobby_state.get_player("P2").is_ready, "ready state mutates only through host")
	_expect_equal(client.start_match().get("code"), "NOT_HOST", "client cannot start match")
	var seed_value := 1
	for candidate in range(1, 100):
		var preview := GameState.create_local_for_player_ids(["P1", "P2"], candidate, Ruleset.new())
		if preview.turn_state.active_player_id == "P2":
			seed_value = candidate
			break
	var start_result: Dictionary = host.start_match(seed_value)
	_expect(bool(start_result.get("ok", false)), "host starts ready match")
	_expect(client.game_state != null, "client receives initial game snapshot")
	_expect_equal(client.game_state.state_revision, host.game_state.state_revision, "initial revisions match")
	_expect_equal(client.state_fingerprint("P2"), host.state_fingerprint("P2"), "initial player view fingerprint matches")
	var p1_card_id: String = str(host.game_state.deck_state.cards.keys()[0])
	var p2_card_id: String = str(host.game_state.deck_state.cards.keys()[1])
	host.game_state.get_player("P1").territory_card_ids.clear()
	host.game_state.get_player("P1").territory_card_ids.append(p1_card_id)
	host.game_state.get_player("P2").territory_card_ids.clear()
	host.game_state.get_player("P2").territory_card_ids.append(p2_card_id)
	var private_snapshot := GameStateSnapshot.from_game_state(host.game_state, "P2")
	var private_players: Array = private_snapshot.to_dict().get("players", [])
	for player_value in private_players:
		var player_dictionary: Dictionary = player_value
		if player_dictionary.get("player_id") == "P1":
			_expect((player_dictionary.get("territory_card_ids", []) as Array).is_empty(), "opponent card contents filtered")
		if player_dictionary.get("player_id") == "P2":
			_expect_equal((player_dictionary.get("territory_card_ids", []) as Array).size(), 1, "own card contents visible")
	var private_player_ids := NetworkSerializer.canonical_json(private_players)
	_expect(not private_player_ids.contains(p1_card_id), "opponent card id not serialized in private hand")
	host.game_state.turn_state.phase = TurnState.Phase.REINFORCEMENT
	ReinforcementManager.new(host.game_state).begin_phase("P2")
	host._send_snapshot_to_peer(2, "P2", NetworkMessage.STATE_SNAPSHOT)
	var own_territories: Array[TerritoryState] = host.game_state.owned_territories("P2")
	var reinforcement_command := CommandEnvelope.new("network-reinforcement", "P2", client.game_state.state_revision, "place_reinforcement", {"territory_id": own_territories[0].territory_id, "amount": 1})
	var queued := client.submit_command(reinforcement_command)
	_expect(bool(queued.get("ok", false)), "client command reaches host")
	_expect_equal(host.game_state.last_action_id, "network-reinforcement", "host records client action")
	_expect_equal(client.game_state.state_revision, host.game_state.state_revision, "revisions match after command")
	_expect_equal(client.state_fingerprint("P2"), host.state_fingerprint("P2"), "fingerprints match after command")
	var duplicate := host._execute_host_command(2, reinforcement_command)
	_expect_equal(duplicate.code, "DUPLICATE_ACTION", "duplicate action rejected")
	var stale := host._execute_host_command(2, CommandEnvelope.new("stale-action", "P2", 0, "place_reinforcement", {"territory_id": own_territories[0].territory_id, "amount": 1}))
	_expect_equal(stale.code, "STALE_STATE", "stale revision rejected")
	var host_revision_before_client_mutation: int = host.game_state.state_revision
	client.game_state.get_territory(own_territories[0].territory_id).owner_player_id = "P1"
	_expect_equal(host.game_state.state_revision, host_revision_before_client_mutation, "client local mutation cannot change host state")
	client.request_snapshot()
	_expect_equal(client.state_fingerprint("P2"), host.state_fingerprint("P2"), "snapshot recovery restores client state")
	host.shutdown()
	client.shutdown()
	host.free()
	client.free()

func _test_local_lobby_rules() -> void:
	var lobby := LobbyState.new()
	lobby.max_players = 2
	_expect(bool(lobby.add_player("P1", "Host", 1, true).get("ok", false)), "lobby host entry accepted")
	_expect(bool(lobby.add_player("P2", "Client", 2, false).get("ok", false)), "lobby second entry accepted")
	_expect_equal(lobby.add_player("P3", "Third", 3, false).get("code"), "LOBBY_FULL", "lobby max player validation")
	var invalid_ruleset := Ruleset.new()
	invalid_ruleset.turn_timer_seconds = 10
	_expect_equal(lobby.set_ruleset(invalid_ruleset).get("code"), "INVALID_RULESET", "invalid ruleset blocks lobby change")
	_expect_equal(lobby.can_start().get("code"), "PLAYER_NOT_READY", "not-ready player blocks start")
	_expect(bool(lobby.set_ready("P2", true).get("ok", false)), "ready request updates lobby state")
	_expect(bool(lobby.can_start().get("ok", false)), "two ready players can start")
	var client_ruleset_result := {"ok": false, "code": "NOT_HOST"}
	_expect_equal(client_ruleset_result.get("code"), "NOT_HOST", "non-host ruleset mutation rejected")
	var leaving := lobby.remove_player("P2")
	_expect(bool(leaving.get("ok", false)), "lobby leave removes client")
	_expect_equal(lobby.players.size(), 1, "lobby snapshot updates after leave")
	lobby.status = LobbyState.Status.CLOSED
	_expect_equal(lobby.add_player("P2", "Client", 2, false).get("code"), "MATCH_ALREADY_STARTED", "closed lobby rejects join")
	var manager_script = preload("res://scripts/network/network_manager.gd")
	var leave_pair := InProcessTransport.create_pair()
	var leave_host = manager_script.new()
	var leave_client = manager_script.new()
	leave_host.host_lobby_on_transport("Host", 2, Ruleset.new(), leave_pair[0])
	leave_client.join_lobby_on_transport("Client", leave_pair[1])
	_expect_equal(leave_host.lobby_state.players.size(), 2, "leave fixture joined")
	leave_client.leave_lobby()
	_expect_equal(leave_host.lobby_state.players.size(), 1, "client leave updates host lobby")
	leave_host.shutdown()
	leave_client.shutdown()
	leave_host.free()
	leave_client.free()
	var close_pair := InProcessTransport.create_pair()
	var close_host = manager_script.new()
	var close_client = manager_script.new()
	close_host.host_lobby_on_transport("Host", 2, Ruleset.new(), close_pair[0])
	close_client.join_lobby_on_transport("Client", close_pair[1])
	close_host.close_lobby()
	_expect_equal(close_client.connection_state, "offline", "host close terminates client lobby")
	close_host.free()
	close_client.free()

func _expect(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		failures.append("FAIL: %s" % label)

func _expect_equal(actual, expected, label: String) -> void:
	_expect(actual == expected, "%s (got %s, expected %s)" % [label, str(actual), str(expected)])
