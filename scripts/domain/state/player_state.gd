class_name PlayerState
extends RefCounted

enum Status { ACTIVE, DISCONNECTED, SURRENDERED, ELIMINATED, SPECTATOR, LEFT }

var player_id: String
var name: String
var color: Color
var status: Status = Status.ACTIVE
var territory_card_ids: Array[String] = []
var reinforcements_remaining: int = 0
var has_conquered_this_turn: bool = false
var card_drawn_this_turn: bool = false
var fortification_used: bool = false
var pending_trade_reinforcements: int = 0

func _init(p_player_id: String = "", p_name: String = "Spieler", p_color: Color = Color.WHITE) -> void:
	player_id = p_player_id
	name = p_name
	color = p_color

func is_active() -> bool:
	return status == Status.ACTIVE

func can_take_turn() -> bool:
	return status == Status.ACTIVE

func territory_count(game_state: GameState) -> int:
	var count := 0
	for territory: TerritoryState in game_state.territories.values():
		if territory.owner_player_id == player_id:
			count += 1
	return count

func army_count(game_state: GameState) -> int:
	var count := 0
	for territory: TerritoryState in game_state.territories.values():
		if territory.owner_player_id == player_id:
			count += territory.army_count
	return count
