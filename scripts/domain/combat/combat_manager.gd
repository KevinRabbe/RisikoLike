class_name CombatManager
extends RefCounted

var game_state: GameState
var random_source: RandomSource
var card_manager: CardManager

func _init(p_game_state: GameState, p_random_source: RandomSource, p_card_manager: CardManager) -> void:
	game_state = p_game_state
	random_source = p_random_source
	card_manager = p_card_manager

func attack(player_id: String, source_id: String, target_id: String, attacker_dice_count: int, defender_dice_count: int) -> Dictionary:
	if game_state.turn_state.phase != TurnState.Phase.ATTACK:
		return {"accepted": false, "code": "INVALID_PHASE"}
	if game_state.turn_state.active_player_id != player_id:
		return {"accepted": false, "code": "NOT_YOUR_TURN"}
	if not game_state.pending_conquest.is_empty():
		return {"accepted": false, "code": "CONQUEST_MOVE_REQUIRED"}
	var source := game_state.get_territory(source_id)
	var target := game_state.get_territory(target_id)
	if source == null or target == null:
		return {"accepted": false, "code": "INVALID_TERRITORY"}
	if source.owner_player_id != player_id:
		return {"accepted": false, "code": "NOT_OWNER"}
	if target.owner_player_id == player_id:
		return {"accepted": false, "code": "TARGET_NOT_ENEMY"}
	if not game_state.map_data.are_neighbors(source_id, target_id):
		return {"accepted": false, "code": "NOT_ADJACENT"}
	if source.army_count < 2:
		return {"accepted": false, "code": "INSUFFICIENT_TROOPS"}
	if attacker_dice_count < 1 or attacker_dice_count > 3 or attacker_dice_count > source.army_count - 1:
		return {"accepted": false, "code": "INVALID_ATTACK_DICE"}
	if defender_dice_count < 1 or defender_dice_count > 2 or defender_dice_count > target.army_count:
		return {"accepted": false, "code": "INVALID_DEFENSE_DICE"}
	var attacker_dice: Array[int] = []
	var defender_dice: Array[int] = []
	for _index in range(attacker_dice_count):
		attacker_dice.append(random_source.roll_d6())
	for _index in range(defender_dice_count):
		defender_dice.append(random_source.roll_d6())
	attacker_dice.sort()
	defender_dice.sort()
	attacker_dice.reverse()
	defender_dice.reverse()
	var attacker_losses := 0
	var defender_losses := 0
	for index in range(mini(attacker_dice.size(), defender_dice.size())):
		if attacker_dice[index] > defender_dice[index]:
			defender_losses += 1
		else:
			attacker_losses += 1
	source.army_count -= attacker_losses
	target.army_count -= defender_losses
	game_state.combat_state.attacker_player_id = player_id
	game_state.combat_state.attacker_territory_id = source_id
	game_state.combat_state.defender_territory_id = target_id
	game_state.combat_state.attacker_dice = attacker_dice
	game_state.combat_state.defender_dice = defender_dice
	game_state.combat_state.attacker_losses = attacker_losses
	game_state.combat_state.defender_losses = defender_losses
	game_state.combat_state.active = true
	var conquered := target.army_count <= 0
	var eliminated_player_id := ""
	if conquered:
		var old_owner := target.owner_player_id
		target.owner_player_id = player_id
		target.army_count = 0
		var attacker := game_state.get_player(player_id)
		attacker.has_conquered_this_turn = true
		game_state.pending_conquest = {"source_id": source_id, "target_id": target_id, "minimum": attacker_dice_count}
		var eliminated := game_state.eliminate_empty_players()
		if eliminated.has(old_owner):
			eliminated_player_id = old_owner
			card_manager.transfer_cards(old_owner, player_id)
			if game_state.get_player(player_id).territory_card_ids.size() >= game_state.ruleset.forced_trade_threshold:
				game_state.forced_trade_player_id = player_id
	var victory := game_state.check_victory()
	return {
		"accepted": true,
		"code": "OK",
		"attacker_dice": attacker_dice,
		"defender_dice": defender_dice,
		"attacker_losses": attacker_losses,
		"defender_losses": defender_losses,
		"conquered": conquered,
		"eliminated_player_id": eliminated_player_id,
		"victory": victory.status == "VICTORY",
	}

func conquest_move(player_id: String, amount: int) -> Dictionary:
	if game_state.turn_state.active_player_id != player_id or game_state.turn_state.phase != TurnState.Phase.ATTACK:
		return {"accepted": false, "code": "INVALID_PHASE"}
	if game_state.pending_conquest.is_empty():
		return {"accepted": false, "code": "NO_CONQUEST_PENDING"}
	var source := game_state.get_territory(str(game_state.pending_conquest["source_id"]))
	var target := game_state.get_territory(str(game_state.pending_conquest["target_id"]))
	var minimum := int(game_state.pending_conquest["minimum"])
	var maximum := source.army_count - 1
	if amount < minimum or amount > maximum:
		return {"accepted": false, "code": "INVALID_CONQUEST_AMOUNT", "minimum": minimum, "maximum": maximum}
	source.army_count -= amount
	target.army_count += amount
	game_state.pending_conquest.clear()
	game_state.combat_state.clear()
	return {"accepted": true, "code": "OK", "amount": amount}
