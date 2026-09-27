class_name GameState
extends RefCounted

enum MatchStatus { INITIALIZING, STARTING_SETUP, PLAYING, PAUSED_HOST_DISCONNECTED, FINISHED, TERMINATED }

var match_id: String = "local-match"
var state_revision: int = 0
var status: MatchStatus = MatchStatus.INITIALIZING
var ruleset: Ruleset
var map_data: MapData
var players: Dictionary = {}
var territories: Dictionary = {}
var turn_state := TurnState.new()
var deck_state := DeckState.new()
var combat_state := CombatState.new()
var pending_conquest: Dictionary = {}
var forced_trade_player_id: String = ""
var last_action_id: String = ""
var winner_player_id: String = ""
var last_result: Dictionary = {}

static func create_local(player_count: int, seed_value: int = 12345, p_ruleset: Ruleset = null) -> GameState:
	var game := GameState.new()
	game.ruleset = p_ruleset.duplicate_ruleset() if p_ruleset != null else Ruleset.new()
	game.map_data = MapDataFactory.create_default()
	game.status = MatchStatus.STARTING_SETUP
	var random := RandomSource.new(seed_value)
	var colors := [Color("#e45756"), Color("#4f86c6"), Color("#5cb85c"), Color("#f0ad4e"), Color("#9b59b6")]
	for index in range(player_count):
		var player_id := "P%d" % (index + 1)
		game.players[player_id] = PlayerState.new(player_id, "Spieler %d" % (index + 1), colors[index])
	for territory_id: String in game.map_data.territories:
		game.territories[territory_id] = TerritoryState.new(territory_id)
	var territory_ids: Array[String] = []
	for territory_id: String in game.map_data.territories:
		territory_ids.append(territory_id)
	random.shuffle(territory_ids)
	for index in range(territory_ids.size()):
		var player_id := "P%d" % ((index % player_count) + 1)
		game.territories[territory_ids[index]].owner_player_id = player_id
		game.territories[territory_ids[index]].army_count = 1
	var remaining_by_player := {}
	for player_id: String in game.players:
		var player := game.get_player(player_id)
		remaining_by_player[player_id] = int(game.ruleset.starting_armies_by_player_count.get(player_count, 25)) - player.territory_count(game)
	while _has_remaining(remaining_by_player):
		for player_id: String in game.players:
			if int(remaining_by_player[player_id]) <= 0:
				continue
			var owned := game.owned_territories(player_id)
			if owned.is_empty():
				continue
			var target: TerritoryState = owned[0]
			target.army_count += 1
			remaining_by_player[player_id] -= 1
	game._choose_starting_player(random)
	game.status = MatchStatus.PLAYING
	game._begin_turn_internal()
	var card_manager := CardManager.new(game, random)
	card_manager.initialize_deck()
	return game

func get_player(player_id: String) -> PlayerState:
	return players.get(player_id) as PlayerState

func get_territory(territory_id: String) -> TerritoryState:
	return territories.get(territory_id) as TerritoryState

func owned_territories(player_id: String) -> Array[TerritoryState]:
	var result: Array[TerritoryState] = []
	for territory: TerritoryState in territories.values():
		if territory.owner_player_id == player_id:
			result.append(territory)
	return result

func active_player_ids() -> Array[String]:
	var result: Array[String] = []
	for player_id: String in players:
		if get_player(player_id).can_take_turn():
			result.append(player_id)
	return result

func begin_next_turn() -> bool:
	var active_ids := active_player_ids()
	if active_ids.size() < 1:
		return false
	var current_index := active_ids.find(turn_state.active_player_id)
	var next_index := 0 if current_index < 0 else (current_index + 1) % active_ids.size()
	if current_index >= 0 and next_index == 0:
		turn_state.round_number += 1
	turn_state.active_player_id = active_ids[next_index]
	_begin_turn_internal()
	return true

func check_victory() -> MatchResult:
	if status == MatchStatus.FINISHED:
		return MatchResult.new("VICTORY", winner_player_id, "already_finished")
	for player_id: String in players:
		if get_player(player_id).territory_count(self) == territories.size() and get_player(player_id).is_active():
			winner_player_id = player_id
			status = MatchStatus.FINISHED
			return MatchResult.new("VICTORY", player_id, "WORLD_CONQUEST")
	return MatchResult.new("IN_PROGRESS")

func eliminate_empty_players() -> Array[String]:
	var eliminated: Array[String] = []
	for player_id: String in players:
		var player := get_player(player_id)
		if player.status == PlayerState.Status.ACTIVE and player.territory_count(self) == 0:
			player.status = PlayerState.Status.ELIMINATED
			eliminated.append(player_id)
	return eliminated

func increment_revision(action_id: String, result: Dictionary = {}) -> void:
	state_revision += 1
	last_action_id = action_id
	last_result = result

func _choose_starting_player(random: RandomSource) -> void:
	var ids: Array[String] = []
	if ruleset.starting_player_rule == Ruleset.StartingPlayerRule.RANDOM:
		ids = active_player_ids()
	else:
		var lowest := 999999
		for player_id: String in players:
			var total := get_player(player_id).army_count(self)
			if total < lowest:
				lowest = total
				ids.clear()
			if total == lowest:
				ids.append(player_id)
	turn_state.active_player_id = ids[random.next_int(0, ids.size() - 1)]

func _begin_turn_internal() -> void:
	turn_state.phase = TurnState.Phase.TURN_START
	var player := get_player(turn_state.active_player_id)
	player.has_conquered_this_turn = false
	player.fortification_used = false
	player.pending_trade_reinforcements = 0
	pending_conquest.clear()
	combat_state.clear()
	if ruleset.territory_cards_enabled:
		turn_state.phase = TurnState.Phase.CARD_TRADE
	else:
		turn_state.phase = TurnState.Phase.REINFORCEMENT
	player.reinforcements_remaining = 0

static func _has_remaining(values: Dictionary) -> bool:
	for value in values.values():
		if int(value) > 0:
			return true
	return false
