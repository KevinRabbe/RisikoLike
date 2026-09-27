class_name TerritoryState
extends RefCounted

var territory_id: String
var owner_player_id: String = ""
var army_count: int = 0

func _init(p_territory_id: String = "", p_owner_player_id: String = "", p_army_count: int = 0) -> void:
	territory_id = p_territory_id
	owner_player_id = p_owner_player_id
	army_count = p_army_count
