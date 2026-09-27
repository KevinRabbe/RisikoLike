class_name ReinforcementManager
extends RefCounted

var game_state: GameState

func _init(p_game_state: GameState) -> void:
	game_state = p_game_state

func calculate_reinforcements(player_id: String) -> int:
	var player := game_state.get_player(player_id)
	if player == null:
		return 0
	var amount := maxi(3, floori(player.territory_count(game_state) / 3.0))
	if game_state.ruleset.continent_bonus_enabled:
		for region_id: String in game_state.map_data.regions:
			var territory_ids := game_state.map_data.territory_ids_for_region(region_id)
			var controls_region := true
			for territory_id: String in territory_ids:
				if game_state.get_territory(territory_id).owner_player_id != player_id:
					controls_region = false
					break
			if controls_region:
				amount += game_state.map_data.get_region(region_id).bonus
	return amount

func begin_phase(player_id: String) -> int:
	var player := game_state.get_player(player_id)
	if player == null:
		return 0
	game_state.pending_reinforcements.clear()
	var amount := calculate_reinforcements(player_id) + player.pending_trade_reinforcements
	player.pending_trade_reinforcements = 0
	player.reinforcements_remaining = amount
	return amount

func place(player_id: String, territory_id: String, amount: int) -> Dictionary:
	if game_state.turn_state.phase != TurnState.Phase.REINFORCEMENT:
		return {"accepted": false, "code": "INVALID_PHASE"}
	if game_state.turn_state.active_player_id != player_id:
		return {"accepted": false, "code": "NOT_YOUR_TURN"}
	var territory := game_state.get_territory(territory_id)
	if territory == null:
		return {"accepted": false, "code": "INVALID_TERRITORY"}
	if territory.owner_player_id != player_id:
		return {"accepted": false, "code": "NOT_OWNER"}
	if amount <= 0 or amount > game_state.get_player(player_id).reinforcements_remaining:
		return {"accepted": false, "code": "INVALID_REINFORCEMENT_AMOUNT"}
	territory.army_count += amount
	game_state.get_player(player_id).reinforcements_remaining -= amount
	game_state.pending_reinforcements[territory_id] = int(game_state.pending_reinforcements.get(territory_id, 0)) + amount
	return {"accepted": true, "code": "OK", "territory_id": territory_id, "amount": amount}

func reset(player_id: String) -> Dictionary:
	if game_state.turn_state.active_player_id != player_id or game_state.turn_state.phase != TurnState.Phase.REINFORCEMENT:
		return {"accepted": false, "code": "INVALID_PHASE"}
	for territory_id: String in game_state.pending_reinforcements:
		var territory := game_state.get_territory(territory_id)
		var amount := int(game_state.pending_reinforcements[territory_id])
		territory.army_count -= amount
		game_state.get_player(player_id).reinforcements_remaining += amount
	game_state.pending_reinforcements.clear()
	return {"accepted": true, "code": "OK"}

func confirm(player_id: String) -> Dictionary:
	if game_state.turn_state.active_player_id != player_id or game_state.turn_state.phase != TurnState.Phase.REINFORCEMENT:
		return {"accepted": false, "code": "INVALID_PHASE"}
	if game_state.get_player(player_id).reinforcements_remaining != 0:
		return {"accepted": false, "code": "REINFORCEMENTS_REMAINING"}
	return {"accepted": true, "code": "OK"}
