extends Node

enum Role { NONE, HOST, CLIENT }

var role: Role = Role.NONE
var player_id := ""
var lobby_id := ""
var match_id := ""
var reconnect_token := ""

func clear() -> void:
	role = Role.NONE
	player_id = ""
	lobby_id = ""
	match_id = ""
	reconnect_token = ""
