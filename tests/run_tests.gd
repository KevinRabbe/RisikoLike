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
	var source := game.get_territory("NA_01")
	var middle := game.get_territory("NA_02")
	var target := game.get_territory("NA_03")
	for territory: TerritoryState in game.territories.values():
		territory.owner_player_id = player_id
		territory.army_count = 1
	source.army_count = 5
	middle.owner_player_id = "P2" if player_id == "P1" else "P1"
	target.army_count = 1
	game.turn_state.phase = TurnState.Phase.FORTIFICATION
	var manager := FortificationManager.new(game)
	_expect(not manager.can_reach(player_id, "NA_01", "NA_03"), "enemy territory blocks connected path")
	middle.owner_player_id = player_id
	_expect(manager.can_reach(player_id, "NA_01", "NA_03"), "connected path reaches own target")
	var result := manager.fortify(player_id, "NA_01", "NA_03", 2)
	_expect(result.accepted, "fortification accepted")
	_expect_equal(source.army_count, 3, "one fortification leaves one minimum")
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
	var reshuffle_game := GameState.create_local(2, 52)
	var reshuffle_processor := CommandProcessor.new(reshuffle_game, RandomSource.new(52))
	var reshuffle_player_id := reshuffle_game.turn_state.active_player_id
	var reshuffle_card_id: String = reshuffle_game.deck_state.cards.keys()[0]
	reshuffle_game.deck_state.draw_pile.clear()
	reshuffle_game.deck_state.discard_pile = [reshuffle_card_id]
	var drawn := reshuffle_processor.card_manager.draw_for_player(reshuffle_player_id)
	_expect(drawn != null, "discard pile reshuffled when draw pile is empty")
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

func _expect(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		failures.append("FAIL: %s" % label)

func _expect_equal(actual, expected, label: String) -> void:
	_expect(actual == expected, "%s (got %s, expected %s)" % [label, str(actual), str(expected)])
