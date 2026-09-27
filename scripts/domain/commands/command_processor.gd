class_name CommandProcessor
extends RefCounted

var game_state: GameState
var random_source: RandomSource
var reinforcement_manager: ReinforcementManager
var card_manager: CardManager
var combat_manager: CombatManager
var fortification_manager: FortificationManager
var seen_action_ids := {}

func _init(p_game_state: GameState, p_random_source: RandomSource = null) -> void:
	game_state = p_game_state
	random_source = p_random_source if p_random_source != null else RandomSource.new()
	reinforcement_manager = ReinforcementManager.new(game_state)
	card_manager = CardManager.new(game_state, random_source)
	combat_manager = CombatManager.new(game_state, random_source, card_manager)
	fortification_manager = FortificationManager.new(game_state)
	if game_state.deck_state.cards.is_empty() and game_state.ruleset.territory_cards_enabled:
		card_manager.initialize_deck()
	if game_state.turn_state.phase == TurnState.Phase.REINFORCEMENT:
		reinforcement_manager.begin_phase(game_state.turn_state.active_player_id)

func execute(command: CommandEnvelope) -> CommandResult:
	var envelope_error := _validate_envelope(command)
	if envelope_error != "":
		return _reject(envelope_error)
	var result: Dictionary
	switch command.command_type:
		"place_reinforcement":
			result = reinforcement_manager.place(command.player_id, str(command.payload.get("territory_id", "")), int(command.payload.get("amount", 0)))
		"reset_reinforcements":
			result = reinforcement_manager.reset(command.player_id)
		"confirm_reinforcements":
			result = reinforcement_manager.confirm(command.player_id)
			if bool(result.get("accepted", false)):
				result = _transition_to(command.player_id, TurnState.Phase.ATTACK)
		"trade_cards":
			result = _trade_cards(command)
		"attack":
			result = combat_manager.attack(command.player_id, str(command.payload.get("source_id", "")), str(command.payload.get("target_id", "")), int(command.payload.get("attacker_dice", 0)), int(command.payload.get("defender_dice", 0)))
		"conquest_move":
			result = combat_manager.conquest_move(command.player_id, int(command.payload.get("amount", 0)))
		"fortify":
			result = fortification_manager.fortify(command.player_id, str(command.payload.get("source_id", "")), str(command.payload.get("target_id", "")), int(command.payload.get("amount", 0)))
		"end_phase":
			result = _end_phase(command.player_id)
		"end_turn":
			result = _end_turn(command.player_id)
		"surrender":
			result = _surrender(command.player_id)
		_:
			return _reject("UNKNOWN_COMMAND")
	if not bool(result.get("accepted", false)):
		return _reject(str(result.get("code", "COMMAND_REJECTED")), result)
	seen_action_ids[command.action_id] = true
	game_state.increment_revision(command.action_id, result)
	return CommandResult.new(true, "OK", game_state.state_revision, result)

func _validate_envelope(command: CommandEnvelope) -> String:
	if command == null or command.action_id.is_empty() or command.player_id.is_empty():
		return "INVALID_ENVELOPE"
	if seen_action_ids.has(command.action_id):
		return "DUPLICATE_ACTION"
	if command.expected_state_revision != game_state.state_revision:
		return "STALE_STATE"
	if game_state.status != GameState.MatchStatus.PLAYING:
		return "MATCH_NOT_PLAYING"
	if game_state.get_player(command.player_id) == null:
		return "INVALID_PLAYER"
	if not game_state.get_player(command.player_id).can_take_turn():
		return "PLAYER_NOT_ACTIVE"
	if command.command_type != "surrender" and game_state.turn_state.active_player_id != command.player_id:
		return "NOT_YOUR_TURN"
	return ""

func _trade_cards(command: CommandEnvelope) -> Dictionary:
	var phase_allowed := game_state.turn_state.phase == TurnState.Phase.CARD_TRADE
	var forced_allowed := game_state.turn_state.phase == TurnState.Phase.ATTACK and game_state.forced_trade_player_id == command.player_id
	if not phase_allowed and not forced_allowed:
		return {"accepted": false, "code": "INVALID_PHASE"}
	var ids: Array[String] = []
	for value in command.payload.get("card_ids", []):
		ids.append(str(value))
	var result := card_manager.trade_cards(command.player_id, ids)
	if bool(result.get("ok", false)) and forced_allowed:
		if game_state.get_player(command.player_id).territory_card_ids.size() < game_state.ruleset.forced_trade_threshold:
			game_state.forced_trade_player_id = ""
	return {"accepted": bool(result.get("ok", false)), "code": str(result.get("code", "INVALID_CARD_SET")), "trade": result}

func _end_phase(player_id: String) -> Dictionary:
	if game_state.turn_state.active_player_id != player_id:
		return {"accepted": false, "code": "NOT_YOUR_TURN"}
	match game_state.turn_state.phase:
		TurnState.Phase.CARD_TRADE:
			var player := game_state.get_player(player_id)
			if game_state.ruleset.forced_trade_threshold > 0 and player.territory_card_ids.size() >= game_state.ruleset.forced_trade_threshold:
				return {"accepted": false, "code": "FORCED_TRADE_REQUIRED"}
			return _enter_reinforcement(player_id)
		TurnState.Phase.REINFORCEMENT:
			if game_state.get_player(player_id).reinforcements_remaining != 0:
				return {"accepted": false, "code": "REINFORCEMENTS_REMAINING"}
			return _transition_to(player_id, TurnState.Phase.ATTACK)
		TurnState.Phase.ATTACK:
			if not game_state.pending_conquest.is_empty():
				return {"accepted": false, "code": "CONQUEST_MOVE_REQUIRED"}
			if game_state.forced_trade_player_id == player_id:
				return {"accepted": false, "code": "FORCED_TRADE_REQUIRED"}
			return _transition_to(player_id, TurnState.Phase.FORTIFICATION)
		TurnState.Phase.FORTIFICATION:
			return _transition_to(player_id, TurnState.Phase.TURN_END)
	return {"accepted": false, "code": "INVALID_PHASE"}

func _end_turn(player_id: String) -> Dictionary:
	if game_state.turn_state.active_player_id != player_id or game_state.turn_state.phase != TurnState.Phase.TURN_END:
		return {"accepted": false, "code": "INVALID_PHASE"}
	var player := game_state.get_player(player_id)
	if player.has_conquered_this_turn and game_state.ruleset.territory_cards_enabled:
		card_manager.draw_for_player(player_id)
	game_state.begin_next_turn()
	if game_state.turn_state.phase == TurnState.Phase.CARD_TRADE:
		return {"accepted": true, "code": "OK", "phase": "CARD_TRADE"}
	_enter_reinforcement(game_state.turn_state.active_player_id)
	return {"accepted": true, "code": "OK", "phase": "REINFORCEMENT"}

func _surrender(player_id: String) -> Dictionary:
	if not game_state.ruleset.surrender_allowed:
		return {"accepted": false, "code": "SURRENDER_DISABLED"}
	var player := game_state.get_player(player_id)
	player.status = PlayerState.Status.SURRENDERED
	if game_state.turn_state.active_player_id == player_id:
		game_state.begin_next_turn()
		_enter_reinforcement(game_state.turn_state.active_player_id)
	return {"accepted": true, "code": "OK"}

func _enter_reinforcement(player_id: String) -> Dictionary:
	game_state.turn_state.phase = TurnState.Phase.REINFORCEMENT
	var amount := reinforcement_manager.begin_phase(player_id)
	return {"accepted": true, "code": "OK", "phase": "REINFORCEMENT", "amount": amount}

func _transition_to(player_id: String, phase: int) -> Dictionary:
	if game_state.turn_state.active_player_id != player_id:
		return {"accepted": false, "code": "NOT_YOUR_TURN"}
	if not game_state.turn_state.transition_to(phase):
		return {"accepted": false, "code": "INVALID_PHASE"}
	return {"accepted": true, "code": "OK", "phase": game_state.turn_state.phase_name()}

func _reject(code: String, data: Dictionary = {}) -> CommandResult:
	return CommandResult.new(false, code, game_state.state_revision, data)
