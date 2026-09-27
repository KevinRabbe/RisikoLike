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
	var stale := processor.execute(CommandEnvelope.new("stale", player_id, 0, "reset_reinforcements"))
	_expect_equal(stale.code, "STALE_STATE", "stale revision rejected")
	var duplicate := processor.execute(CommandEnvelope.new("reinforce-place", player_id, game.state_revision, "reset_reinforcements"))
	_expect(duplicate.accepted, "reset accepted")
	var duplicate_again := processor.execute(CommandEnvelope.new("reinforce-place", player_id, game.state_revision, "reset_reinforcements"))
	_expect_equal(duplicate_again.code, "DUPLICATE_ACTION", "duplicate action rejected")

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
	_expect_equal(processor.card_manager.trade_value(6), 20, "progressive card value after six trades")

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
	for territory: TerritoryState in game.territories.values():
		territory.owner_player_id = player_id
	var result := game.check_victory()
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
