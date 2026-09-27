class_name MatchResult
extends RefCounted

var status: String = ""
var winner_player_id: String = ""
var reason: String = ""

func _init(p_status: String = "", p_winner_player_id: String = "", p_reason: String = "") -> void:
	status = p_status
	winner_player_id = p_winner_player_id
	reason = p_reason
