extends Node

enum Role { NONE, HOST, CLIENT }
enum ConnectionState { OFFLINE, CONNECTED, DISCONNECTED, RECONNECTING, FAILED }

var role: Role = Role.NONE
var player_id := ""
var lobby_id := ""
var match_id := ""
var reconnect_token := ""
var reconnect_expires_at := ""
var connection_generation := 0
var connection_state: ConnectionState = ConnectionState.OFFLINE

func set_reconnect_credentials(p_match_id: String, p_player_id: String, p_token: String, p_expires_at: String, p_generation: int) -> void:
	match_id = p_match_id
	player_id = p_player_id
	reconnect_token = p_token
	reconnect_expires_at = p_expires_at
	connection_generation = p_generation

func clear_reconnect_credentials() -> void:
	reconnect_token = ""
	reconnect_expires_at = ""
	connection_generation = 0

func clear() -> void:
	role = Role.NONE
	player_id = ""
	lobby_id = ""
	match_id = ""
	clear_reconnect_credentials()
	connection_state = ConnectionState.OFFLINE
