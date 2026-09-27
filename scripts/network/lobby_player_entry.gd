class_name LobbyPlayerEntry
extends RefCounted

var player_id: String
var network_peer_id: int = 0
var name: String
var color: Color = Color.WHITE
var is_host: bool = false
var is_ready: bool = false
var connection_state: String = "CONNECTED"
var spectator: bool = false

func _init(p_player_id: String = "", p_name: String = "Spieler", p_is_host: bool = false) -> void:
	player_id = p_player_id
	name = p_name
	is_host = p_is_host

func to_dict() -> Dictionary:
	return {
		"player_id": player_id,
		"network_peer_id": network_peer_id,
		"name": name,
		"color": color.to_html(false),
		"is_host": is_host,
		"is_ready": is_ready,
		"connection_state": connection_state,
		"spectator": spectator,
	}

static func from_dict(raw: Variant) -> LobbyPlayerEntry:
	if not raw is Dictionary:
		return null
	var values: Dictionary = raw
	var entry := LobbyPlayerEntry.new(str(values.get("player_id", "")), str(values.get("name", "Spieler")), bool(values.get("is_host", false)))
	entry.network_peer_id = int(values.get("network_peer_id", 0))
	entry.color = Color(str(values.get("color", "ffffff")))
	entry.is_ready = bool(values.get("is_ready", false))
	entry.connection_state = str(values.get("connection_state", "CONNECTED"))
	entry.spectator = bool(values.get("spectator", false))
	return entry
