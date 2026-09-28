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
	match command.command_type:
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

## Advances host-owned lifecycle state. This is deliberately separate from
## execute(): clients never decide when a timer or reconnect window expires.
func advance_time(now_msec: int = -1) -> Dictionary:
	var now: int = game_state.clock.now_msec() if now_msec < 0 else now_msec
	var changed := false
	var warning := false
	var timeout_reason := ""
	var expired_players := _expire_disconnect_windows(now)
	if not expired_players.is_empty():
		changed = true
	if game_state.status == GameState.MatchStatus.PLAYING and game_state.is_turn_timer_expired(now):
		var timeout := _expire_turn()
		if bool(timeout.get("changed", false)):
			changed = true
			timeout_reason = str(timeout.get("reason", "TURN_TIMER"))
			game_state.last_timeout_reason = timeout_reason
	elif game_state.status == GameState.MatchStatus.PLAYING and game_state.is_turn_timer_warning(now) and not game_state.turn_state.timer_warning_emitted:
		game_state.turn_state.timer_warning_emitted = true
		changed = true
		warning = true
	if changed:
		var action_id := "lifecycle-%d-%d" % [game_state.turn_state.round_number, now]
		game_state.increment_revision(action_id, {
			"code": "TURN_TIMER_EXPIRED" if timeout_reason != "" else "TURN_TIMER_WARNING" if warning else "RECONNECT_WINDOW_EXPIRED",
			"expired_player_ids": expired_players,
			"reason": game_state.last_timeout_reason,
		})
	return {"changed": changed, "warning": warning, "expired_player_ids": expired_players, "reason": game_state.last_timeout_reason}

func mark_disconnected(player_id: String, now_msec: int = -1) -> Dictionary:
	var player := game_state.get_player(player_id)
	if player == null:
		return {"ok": false, "code": "INVALID_PLAYER"}
	if not player.is_turn_eligible():
		return {"ok": false, "code": "PLAYER_NOT_ACTIVE"}
	var now: int = game_state.clock.now_msec() if now_msec < 0 else now_msec
	player.status = PlayerState.Status.DISCONNECTED
	player.disconnected_at_msec = now
	player.reconnect_deadline_msec = 0 if game_state.ruleset.reconnect_timeout_seconds <= 0 else now + game_state.ruleset.reconnect_timeout_seconds * 1000
	return {"ok": true, "code": "DISCONNECTED", "reconnect_deadline_msec": player.reconnect_deadline_msec}

func mark_reconnected(player_id: String, now_msec: int = -1) -> Dictionary:
	var player := game_state.get_player(player_id)
	if player == null:
		return {"ok": false, "code": "INVALID_PLAYER"}
	var now: int = game_state.clock.now_msec() if now_msec < 0 else now_msec
	if player.status == PlayerState.Status.LEFT:
		return {"ok": false, "code": "RECONNECT_WINDOW_EXPIRED"}
	if player.status == PlayerState.Status.ELIMINATED or player.status == PlayerState.Status.SURRENDERED or player.spectator_mode:
		return {"ok": false, "code": "PLAYER_NOT_ACTIVE"}
	if player.status != PlayerState.Status.DISCONNECTED:
		return {"ok": false, "code": "PLAYER_ALREADY_CONNECTED"}
	if player.reconnect_deadline_msec > 0 and now >= player.reconnect_deadline_msec:
		_expire_disconnect_player(player, now)
		return {"ok": false, "code": "RECONNECT_WINDOW_EXPIRED"}
	player.status = PlayerState.Status.ACTIVE
	player.disconnected_at_msec = 0
	player.reconnect_deadline_msec = 0
	return {"ok": true, "code": "RECONNECTED"}

func enter_spectator(player_id: String) -> Dictionary:
	var player := game_state.get_player(player_id)
	if player == null:
		return {"ok": false, "code": "INVALID_PLAYER"}
	if not game_state.ruleset.spectating_allowed:
		return {"ok": false, "code": "SPECTATOR_DISABLED"}
	if player.status != PlayerState.Status.SURRENDERED and player.status != PlayerState.Status.ELIMINATED and player.status != PlayerState.Status.LEFT:
		return {"ok": false, "code": "PLAYER_NOT_SPECTATOR_ELIGIBLE"}
	player.spectator_source_status = player.status
	player.spectator_mode = true
	return {"ok": true, "code": "SPECTATOR"}

func _validate_envelope(command: CommandEnvelope) -> String:
	if command == null or command.action_id.is_empty() or command.player_id.is_empty():
		return "INVALID_ENVELOPE"
	if seen_action_ids.has(command.action_id):
		return "DUPLICATE_ACTION"
	if command.expected_state_revision != game_state.state_revision:
		return "STALE_STATE"
	if game_state.status == GameState.MatchStatus.FINISHED:
		return "MATCH_FINISHED"
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
			if game_state.get_player(player_id).pending_trade_reinforcements > 0:
				return {"accepted": false, "code": "TRADE_REINFORCEMENTS_REMAINING"}
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
	if player == null or not player.can_take_turn():
		return {"accepted": false, "code": "PLAYER_NOT_ACTIVE"}
	player.status = PlayerState.Status.SURRENDERED
	player.disconnected_at_msec = 0
	player.reconnect_deadline_msec = 0
	if game_state.turn_state.active_player_id == player_id:
		_advance_to_next_turn()
	return {"accepted": true, "code": "OK"}

func _expire_disconnect_windows(now_msec: int) -> Array[String]:
	var expired: Array[String] = []
	for player_id: String in game_state.players:
		var player := game_state.get_player(player_id)
		if player.status != PlayerState.Status.DISCONNECTED or player.reconnect_deadline_msec <= 0:
			continue
		if now_msec >= player.reconnect_deadline_msec:
			_expire_disconnect_player(player, now_msec)
			expired.append(player_id)
	if not expired.is_empty() and game_state.status == GameState.MatchStatus.PLAYING and not game_state.turn_rotation_player_ids().has(game_state.turn_state.active_player_id):
		_advance_to_next_turn()
	return expired

func _expire_disconnect_player(player: PlayerState, now_msec: int) -> void:
	player.status = PlayerState.Status.LEFT
	player.permanently_left_at_msec = now_msec
	player.disconnected_at_msec = 0
	player.reconnect_deadline_msec = 0

func _expire_turn() -> Dictionary:
	var player_id := game_state.turn_state.active_player_id
	var player := game_state.get_player(player_id)
	if player == null or not player.is_turn_eligible():
		return {"changed": false}
	match game_state.turn_state.phase:
		TurnState.Phase.CARD_TRADE:
			if game_state.forced_trade_player_id == player_id:
				_force_deterministic_trade(player_id)
		TurnState.Phase.REINFORCEMENT:
			# Confirmed placements are already on the map. Unallocated armies are
			# intentionally discarded; timeout must never invent attacks.
			player.reinforcements_remaining = 0
			game_state.pending_reinforcements.clear()
		TurnState.Phase.ATTACK:
			if not game_state.pending_conquest.is_empty():
				_safe_conquest_move(player_id)
			if game_state.forced_trade_player_id == player_id:
				_force_deterministic_trade(player_id)
		TurnState.Phase.FORTIFICATION, TurnState.Phase.TURN_END:
			pass
	if game_state.status == GameState.MatchStatus.FINISHED:
		return {"changed": true, "reason": "VICTORY"}
	return {"changed": _advance_to_next_turn(), "reason": "TURN_TIMER"}

func _force_deterministic_trade(player_id: String) -> void:
	var player := game_state.get_player(player_id)
	if player == null:
		return
	var sorted_cards := player.territory_card_ids.duplicate()
	sorted_cards.sort()
	var candidate := _find_first_valid_card_set(sorted_cards)
	if not candidate.is_empty():
		card_manager.trade_cards(player_id, candidate)
	# A malformed/non-tradable hand must never strand the match in forced trade.
	game_state.forced_trade_player_id = ""

func _find_first_valid_card_set(card_ids: Array) -> Array[String]:
	for first in range(card_ids.size()):
		for second in range(first + 1, card_ids.size()):
			for third in range(second + 1, card_ids.size()):
				var candidate: Array[String] = [str(card_ids[first]), str(card_ids[second]), str(card_ids[third])]
				if card_manager.is_valid_set(candidate):
					return candidate
	return []

func _safe_conquest_move(player_id: String) -> void:
	if game_state.pending_conquest.is_empty():
		return
	var source := game_state.get_territory(str(game_state.pending_conquest.get("source_id", "")))
	var minimum := int(game_state.pending_conquest.get("minimum", 0))
	if source != null and source.army_count - 1 >= minimum:
		combat_manager.conquest_move(player_id, minimum)
	else:
		game_state.pending_conquest.clear()
		game_state.combat_state.clear()
		game_state.check_victory()

func _advance_to_next_turn() -> bool:
	if not game_state.begin_next_turn():
		return false
	if game_state.status != GameState.MatchStatus.FINISHED and game_state.turn_state.phase != TurnState.Phase.CARD_TRADE:
		_enter_reinforcement(game_state.turn_state.active_player_id)
	return true

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
