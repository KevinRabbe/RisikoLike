class_name GameStateSnapshot
extends RefCounted

var protocol_version: int = App.PROTOCOL_VERSION
var match_id: String = ""
var state_revision: int = 0
var status: int = GameState.MatchStatus.INITIALIZING
var winner_player_id: String = ""
var viewer_player_id: String = ""
var ruleset: Dictionary = {}
var players: Array[Dictionary] = []
var territories: Array[Dictionary] = []
var turn: Dictionary = {}
var deck: Dictionary = {}
var combat: Dictionary = {}
var pending_reinforcements: Dictionary = {}
var pending_conquest: Dictionary = {}
var forced_trade_player_id: String = ""
var last_action_id: String = ""

static func from_game_state(game_state: GameState, p_viewer_player_id: String = "") -> GameStateSnapshot:
	var snapshot := GameStateSnapshot.new()
	snapshot.match_id = game_state.match_id
	snapshot.state_revision = game_state.state_revision
	snapshot.status = game_state.status
	snapshot.winner_player_id = game_state.winner_player_id
	snapshot.viewer_player_id = p_viewer_player_id
	snapshot.ruleset = game_state.ruleset.to_dict()
	for player_id: String in _sorted_keys(game_state.players):
		var player := game_state.get_player(player_id)
		var cards: Array[String] = []
		if player_id == p_viewer_player_id:
			cards = player.territory_card_ids.duplicate()
		var card_count := player.territory_card_ids.size() if player_id == p_viewer_player_id or player.visible_card_count == 0 else player.visible_card_count
		snapshot.players.append({
			"player_id": player.player_id,
			"name": player.name,
			"color": player.color.to_html(false),
			"status": player.status,
			"territory_card_ids": cards,
			"territory_card_count": card_count,
			"reinforcements_remaining": player.reinforcements_remaining if player_id == p_viewer_player_id else 0,
			"has_conquered_this_turn": player.has_conquered_this_turn if player_id == p_viewer_player_id else false,
			"card_drawn_this_turn": player.card_drawn_this_turn if player_id == p_viewer_player_id else false,
			"fortification_used": player.fortification_used if player_id == p_viewer_player_id else false,
			"pending_trade_reinforcements": player.pending_trade_reinforcements if player_id == p_viewer_player_id else 0,
		})
	for territory_id: String in _sorted_keys(game_state.territories):
		var territory := game_state.get_territory(territory_id)
		snapshot.territories.append({
			"territory_id": territory.territory_id,
			"owner_player_id": territory.owner_player_id,
			"army_count": territory.army_count,
		})
	snapshot.turn = {
		"round_number": game_state.turn_state.round_number,
		"active_player_id": game_state.turn_state.active_player_id,
		"phase": game_state.turn_state.phase,
		"turn_started_at_msec": game_state.turn_state.turn_started_at_msec,
	}
	var card_definitions: Array[Dictionary] = []
	for card_id: String in _sorted_keys(game_state.deck_state.cards):
		var card := game_state.deck_state.get_card(card_id)
		card_definitions.append({
			"card_id": card.card_id,
			"territory_id": card.territory_id,
			"symbol": card.symbol,
		})
	snapshot.deck = {
		"cards": card_definitions,
		"draw_pile_count": game_state.deck_state.draw_pile.size(),
		"discard_pile": game_state.deck_state.discard_pile.duplicate(),
		"trade_count": game_state.deck_state.trade_count,
	}
	snapshot.combat = {
		"attacker_player_id": game_state.combat_state.attacker_player_id,
		"attacker_territory_id": game_state.combat_state.attacker_territory_id,
		"defender_territory_id": game_state.combat_state.defender_territory_id,
		"attacker_dice": game_state.combat_state.attacker_dice.duplicate(),
		"defender_dice": game_state.combat_state.defender_dice.duplicate(),
		"attacker_losses": game_state.combat_state.attacker_losses,
		"defender_losses": game_state.combat_state.defender_losses,
		"active": game_state.combat_state.active,
	}
	snapshot.pending_reinforcements = game_state.pending_reinforcements.duplicate(true)
	snapshot.pending_conquest = game_state.pending_conquest.duplicate(true)
	snapshot.forced_trade_player_id = game_state.forced_trade_player_id
	snapshot.last_action_id = game_state.last_action_id
	return snapshot

func to_dict() -> Dictionary:
	return {
		"protocol_version": protocol_version,
		"match_id": match_id,
		"state_revision": state_revision,
		"status": status,
		"winner_player_id": winner_player_id,
		"viewer_player_id": viewer_player_id,
		"ruleset": ruleset.duplicate(true),
		"players": players.duplicate(true),
		"territories": territories.duplicate(true),
		"turn": turn.duplicate(true),
		"deck": deck.duplicate(true),
		"combat": combat.duplicate(true),
		"pending_reinforcements": pending_reinforcements.duplicate(true),
		"pending_conquest": pending_conquest.duplicate(true),
		"forced_trade_player_id": forced_trade_player_id,
		"last_action_id": last_action_id,
	}

static func from_dict(raw: Variant) -> GameStateSnapshot:
	if not raw is Dictionary:
		return null
	var values: Dictionary = raw
	var snapshot := GameStateSnapshot.new()
	snapshot.protocol_version = int(values.get("protocol_version", 0))
	snapshot.match_id = str(values.get("match_id", ""))
	snapshot.state_revision = int(values.get("state_revision", -1))
	snapshot.status = int(values.get("status", GameState.MatchStatus.INITIALIZING))
	snapshot.winner_player_id = str(values.get("winner_player_id", ""))
	snapshot.viewer_player_id = str(values.get("viewer_player_id", ""))
	var ruleset_value: Variant = values.get("ruleset", {})
	if ruleset_value is Dictionary:
		snapshot.ruleset = ruleset_value.duplicate(true)
	for key in ["players", "territories"]:
		var list_value: Variant = values.get(key, [])
		if not list_value is Array:
			return null
		if key == "players":
			for item in list_value:
				if not item is Dictionary:
					return null
				snapshot.players.append(item.duplicate(true))
		else:
			for item in list_value:
				if not item is Dictionary:
					return null
				snapshot.territories.append(item.duplicate(true))
	for key in ["turn", "deck", "combat", "pending_reinforcements", "pending_conquest"]:
		var dictionary_value: Variant = values.get(key, {})
		if not dictionary_value is Dictionary:
			return null
		if key == "turn":
			snapshot.turn = dictionary_value.duplicate(true)
		elif key == "deck":
			snapshot.deck = dictionary_value.duplicate(true)
		elif key == "combat":
			snapshot.combat = dictionary_value.duplicate(true)
		elif key == "pending_reinforcements":
			snapshot.pending_reinforcements = dictionary_value.duplicate(true)
		else:
			snapshot.pending_conquest = dictionary_value.duplicate(true)
	snapshot.forced_trade_player_id = str(values.get("forced_trade_player_id", ""))
	snapshot.last_action_id = str(values.get("last_action_id", ""))
	return snapshot

func fingerprint() -> String:
	return str(NetworkSerializer.canonical_json(to_dict()).hash())

func apply_to_game_state(target: GameState) -> bool:
	if target == null or match_id.is_empty() or state_revision < 0:
		return false
	target.match_id = match_id
	# Static map data is local configuration, not part of the wire snapshot.
	# Recreate it when a client installs its first authoritative snapshot so
	# the normal Game/Map UI can render the replicated state.
	target.map_data = MapDataFactory.create_default()
	target.state_revision = state_revision
	target.status = status as GameState.MatchStatus
	target.winner_player_id = winner_player_id
	target.ruleset = Ruleset.from_dict(ruleset)
	target.players.clear()
	for raw_player in players:
		if not raw_player is Dictionary:
			return false
		var values: Dictionary = raw_player
		var player_id := str(values.get("player_id", ""))
		if player_id.is_empty():
			return false
		var player := PlayerState.new(player_id, str(values.get("name", "Spieler")), Color(str(values.get("color", "ffffff"))))
		player.status = int(values.get("status", PlayerState.Status.ACTIVE)) as PlayerState.Status
		player.reinforcements_remaining = int(values.get("reinforcements_remaining", 0))
		player.has_conquered_this_turn = bool(values.get("has_conquered_this_turn", false))
		player.card_drawn_this_turn = bool(values.get("card_drawn_this_turn", false))
		player.fortification_used = bool(values.get("fortification_used", false))
		player.pending_trade_reinforcements = int(values.get("pending_trade_reinforcements", 0))
		var card_ids: Variant = values.get("territory_card_ids", [])
		if card_ids is Array:
			for card_id in card_ids:
				player.territory_card_ids.append(str(card_id))
		player.visible_card_count = int(values.get("territory_card_count", player.territory_card_ids.size()))
		target.players[player_id] = player
	target.territories.clear()
	for raw_territory in territories:
		if not raw_territory is Dictionary:
			return false
		var territory_values: Dictionary = raw_territory
		var territory_id := str(territory_values.get("territory_id", ""))
		if territory_id.is_empty():
			return false
		target.territories[territory_id] = TerritoryState.new(territory_id, str(territory_values.get("owner_player_id", "")), int(territory_values.get("army_count", 0)))
	target.turn_state = TurnState.new()
	target.turn_state.round_number = int(turn.get("round_number", 1))
	target.turn_state.active_player_id = str(turn.get("active_player_id", ""))
	target.turn_state.phase = int(turn.get("phase", TurnState.Phase.TURN_START))
	target.turn_state.turn_started_at_msec = int(turn.get("turn_started_at_msec", 0))
	target.deck_state = DeckState.new()
	var card_values: Variant = deck.get("cards", [])
	if card_values is Array:
		for raw_card in card_values:
			if raw_card is Dictionary:
				var card_dictionary: Dictionary = raw_card
				var card := CardState.new(str(card_dictionary.get("card_id", "")), str(card_dictionary.get("territory_id", "")), int(card_dictionary.get("symbol", CardState.Symbol.JOKER)))
				target.deck_state.add_card(card)
	target.deck_state.discard_pile = []
	var discard_value: Variant = deck.get("discard_pile", [])
	if discard_value is Array:
		for card_id in discard_value:
			target.deck_state.discard_pile.append(str(card_id))
	target.deck_state.trade_count = int(deck.get("trade_count", 0))
	var draw_pile_count := int(deck.get("draw_pile_count", 0))
	for index in range(draw_pile_count):
		target.deck_state.draw_pile.append("__HIDDEN_DRAW_PILE_%d" % index)
	target.combat_state = CombatState.new()
	target.combat_state.attacker_player_id = str(combat.get("attacker_player_id", ""))
	target.combat_state.attacker_territory_id = str(combat.get("attacker_territory_id", ""))
	target.combat_state.defender_territory_id = str(combat.get("defender_territory_id", ""))
	target.combat_state.attacker_dice = _int_array(combat.get("attacker_dice", []))
	target.combat_state.defender_dice = _int_array(combat.get("defender_dice", []))
	target.combat_state.attacker_losses = int(combat.get("attacker_losses", 0))
	target.combat_state.defender_losses = int(combat.get("defender_losses", 0))
	target.combat_state.active = bool(combat.get("active", false))
	target.pending_reinforcements.clear()
	for territory_id in pending_reinforcements:
		target.pending_reinforcements[str(territory_id)] = int(pending_reinforcements[territory_id])
	target.pending_conquest = pending_conquest.duplicate(true)
	target.forced_trade_player_id = forced_trade_player_id
	target.last_action_id = last_action_id
	target.last_result = {}
	return true

static func _sorted_keys(values: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key in values:
		result.append(str(key))
	result.sort()
	return result

static func _int_array(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if value is Array:
		for item in value:
			result.append(int(item))
	return result
