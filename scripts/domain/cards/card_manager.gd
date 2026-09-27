class_name CardManager
extends RefCounted

var game_state: GameState
var random_source: RandomSource

func _init(p_game_state: GameState, p_random_source: RandomSource) -> void:
	game_state = p_game_state
	random_source = p_random_source

func initialize_deck() -> void:
	game_state.deck_state = DeckState.new()
	var symbols := [CardState.Symbol.INFANTRY, CardState.Symbol.CAVALRY, CardState.Symbol.ARTILLERY]
	for index in range(game_state.map_data.territories.size()):
		var territory_id: String = game_state.map_data.territories.keys()[index]
		var card := CardState.new("TERRITORY_%s" % territory_id, territory_id, symbols[index % symbols.size()])
		game_state.deck_state.add_card(card)
	for index in range(2):
		game_state.deck_state.add_card(CardState.new("JOKER_%d" % (index + 1), "", CardState.Symbol.JOKER))
	for card_id: String in game_state.deck_state.cards:
		game_state.deck_state.draw_pile.append(card_id)
	random_source.shuffle(game_state.deck_state.draw_pile)

func draw_for_player(player_id: String) -> CardState:
	var player := game_state.get_player(player_id)
	if player == null or not game_state.ruleset.territory_cards_enabled or not player.has_conquered_this_turn or player.card_drawn_this_turn:
		return null
	if game_state.deck_state.draw_pile.is_empty():
		_reshuffle_discard()
	var card := game_state.deck_state.draw_card()
	if card != null:
		player.territory_card_ids.append(card.card_id)
		player.card_drawn_this_turn = true
	return card

func trade_cards(player_id: String, card_ids: Array[String]) -> Dictionary:
	var player := game_state.get_player(player_id)
	if player == null:
		return {"ok": false, "code": "INVALID_PLAYER"}
	if not is_valid_set(card_ids):
		return {"ok": false, "code": "INVALID_CARD_SET"}
	for card_id in card_ids:
		if not player.territory_card_ids.has(card_id):
			return {"ok": false, "code": "CARD_NOT_OWNED"}
	var bonus := trade_value(game_state.deck_state.trade_count)
	var owned_bonus_territory := ""
	for card_id in card_ids:
		var card := game_state.deck_state.get_card(card_id)
		if card == null:
			continue
		if not card.is_joker() and game_state.get_territory(card.territory_id).owner_player_id == player_id:
			owned_bonus_territory = card.territory_id
		player.territory_card_ids.erase(card_id)
		game_state.deck_state.discard(card_id)
	game_state.deck_state.trade_count += 1
	player.pending_trade_reinforcements += bonus
	if owned_bonus_territory != "" and game_state.ruleset.owned_territory_card_bonus > 0:
		game_state.get_territory(owned_bonus_territory).army_count += game_state.ruleset.owned_territory_card_bonus
	return {"ok": true, "code": "OK", "bonus": bonus, "owned_bonus_territory": owned_bonus_territory}

func is_valid_set(card_ids: Array[String]) -> bool:
	if card_ids.size() != 3:
		return false
	var cards: Array[CardState] = []
	for card_id in card_ids:
		var card := game_state.deck_state.get_card(card_id)
		if card == null:
			return false
		cards.append(card)
	var non_joker_symbols: Array[int] = []
	var joker_count := 0
	for card in cards:
		if card.is_joker():
			joker_count += 1
		else:
			non_joker_symbols.append(card.symbol)
	if joker_count == 0:
		return _all_same(non_joker_symbols) or _all_different(non_joker_symbols)
	if joker_count == 1:
		return _all_same(non_joker_symbols) or non_joker_symbols.size() == 2
	return true

func trade_value(trade_index: int) -> int:
	if game_state.ruleset.card_bonus_mode == Ruleset.CardBonusMode.FIXED:
		return game_state.ruleset.fixed_card_bonus
	var values := game_state.ruleset.progressive_card_values
	if trade_index < values.size():
		return values[trade_index]
	return values.back() + (trade_index - values.size() + 1) * game_state.ruleset.progressive_increment_after_sequence

func transfer_cards(from_player_id: String, to_player_id: String) -> void:
	var from_player := game_state.get_player(from_player_id)
	var to_player := game_state.get_player(to_player_id)
	if from_player == null or to_player == null:
		return
	for card_id in from_player.territory_card_ids:
		to_player.territory_card_ids.append(card_id)
	from_player.territory_card_ids.clear()

func _reshuffle_discard() -> void:
	if game_state.deck_state.discard_pile.is_empty():
		return
	for card_id in game_state.deck_state.discard_pile:
		game_state.deck_state.draw_pile.append(card_id)
	game_state.deck_state.discard_pile.clear()
	random_source.shuffle(game_state.deck_state.draw_pile)

static func _all_same(values: Array[int]) -> bool:
	if values.is_empty():
		return false
	for value in values:
		if value != values[0]:
			return false
	return true

static func _all_different(values: Array[int]) -> bool:
	var unique := {}
	for value in values:
		unique[value] = true
	return unique.size() == values.size()
