class_name FortificationManager
extends RefCounted

var game_state: GameState

func _init(p_game_state: GameState) -> void:
	game_state = p_game_state

func can_reach(player_id: String, source_id: String, target_id: String) -> bool:
	if source_id == target_id:
		return false
	var source := game_state.get_territory(source_id)
	var target := game_state.get_territory(target_id)
	if source == null or target == null or source.owner_player_id != player_id or target.owner_player_id != player_id:
		return false
	if game_state.ruleset.fortification_mode == Ruleset.FortificationMode.ADJACENT:
		return game_state.map_data.are_neighbors(source_id, target_id)
	var queue: Array[String] = [source_id]
	var visited := {source_id: true}
	while not queue.is_empty():
		var current: String = queue.pop_front()
		for neighbor_id: String in game_state.map_data.get_territory(current).neighbors:
			if visited.has(neighbor_id):
				continue
			if game_state.get_territory(neighbor_id).owner_player_id != player_id:
				continue
			if neighbor_id == target_id:
				return true
			visited[neighbor_id] = true
			queue.append(neighbor_id)
	return false

func fortify(player_id: String, source_id: String, target_id: String, amount: int) -> Dictionary:
	if game_state.turn_state.phase != TurnState.Phase.FORTIFICATION:
		return {"accepted": false, "code": "INVALID_PHASE"}
	if game_state.turn_state.active_player_id != player_id:
		return {"accepted": false, "code": "NOT_YOUR_TURN"}
	var player := game_state.get_player(player_id)
	if player.fortification_used:
		return {"accepted": false, "code": "FORTIFICATION_ALREADY_USED"}
	var source := game_state.get_territory(source_id)
	var target := game_state.get_territory(target_id)
	if source == null or target == null or source.owner_player_id != player_id or target.owner_player_id != player_id:
		return {"accepted": false, "code": "NOT_OWNER"}
	if not can_reach(player_id, source_id, target_id):
		return {"accepted": false, "code": "INVALID_FORTIFICATION_PATH"}
	if amount < 1 or amount > source.army_count - 1:
		return {"accepted": false, "code": "INSUFFICIENT_TROOPS"}
	source.army_count -= amount
	target.army_count += amount
	player.fortification_used = true
	return {"accepted": true, "code": "OK", "amount": amount}
