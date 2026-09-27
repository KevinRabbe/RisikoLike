class_name LobbyState
extends RefCounted

enum Status { CREATING, OPEN, STARTING, IN_GAME, CLOSED }

var lobby_id: String = ""
var invite_code: String = ""
var host_player_id: String = ""
var status: Status = Status.CREATING
var max_players: int = Ruleset.MAX_PLAYERS
var players: Dictionary = {}
var ruleset: Ruleset = Ruleset.new()
var protocol_version: int = App.PROTOCOL_VERSION
var game_version: String = App.GAME_VERSION
var ruleset_locked: bool = false

func status_name() -> String:
	return Status.keys()[status]

func add_player(player_id: String, player_name: String, peer_id: int, is_host: bool = false) -> Dictionary:
	if status != Status.CREATING and status != Status.OPEN:
		return {"ok": false, "code": "MATCH_ALREADY_STARTED"}
	if players.size() >= max_players:
		return {"ok": false, "code": "LOBBY_FULL"}
	var cleaned_name := player_name.strip_edges()
	if cleaned_name.length() < 2 or cleaned_name.length() > 20:
		return {"ok": false, "code": "NAME_INVALID"}
	if player_id.is_empty() or players.has(player_id):
		return {"ok": false, "code": "INVALID_PLAYER"}
	var entry := LobbyPlayerEntry.new(player_id, cleaned_name, is_host)
	entry.network_peer_id = peer_id
	entry.color = _color_for_slot(players.size())
	entry.is_ready = is_host
	players[player_id] = entry
	if is_host:
		host_player_id = player_id
	status = Status.OPEN
	return {"ok": true, "code": "OK", "player": entry}

func remove_player(player_id: String) -> Dictionary:
	if not players.has(player_id):
		return {"ok": false, "code": "INVALID_PLAYER"}
	if player_id == host_player_id:
		status = Status.CLOSED
		return {"ok": true, "code": "HOST_CLOSED"}
	players.erase(player_id)
	return {"ok": true, "code": "OK"}

func set_ready(player_id: String, ready: bool) -> Dictionary:
	if status != Status.OPEN:
		return {"ok": false, "code": "MATCH_ALREADY_STARTED"}
	var player := get_player(player_id)
	if player == null:
		return {"ok": false, "code": "INVALID_PLAYER"}
	if player.is_host:
		return {"ok": false, "code": "NOT_HOST"}
	player.is_ready = ready
	return {"ok": true, "code": "OK"}

func set_ruleset(next_ruleset: Ruleset) -> Dictionary:
	if ruleset_locked or status != Status.OPEN:
		return {"ok": false, "code": "MATCH_ALREADY_STARTED"}
	var errors := RulesetValidator.validate(next_ruleset)
	if not errors.is_empty():
		return {"ok": false, "code": "INVALID_RULESET", "errors": errors}
	ruleset = next_ruleset.duplicate_ruleset()
	return {"ok": true, "code": "OK"}

func can_start() -> Dictionary:
	if status != Status.OPEN:
		return {"ok": false, "code": "MATCH_ALREADY_STARTED"}
	if players.size() < Ruleset.MIN_PLAYERS:
		return {"ok": false, "code": "NOT_ENOUGH_PLAYERS"}
	if players.size() > max_players:
		return {"ok": false, "code": "LOBBY_FULL"}
	if host_player_id.is_empty() or not players.has(host_player_id):
		return {"ok": false, "code": "INVALID_HOST"}
	for player_id: String in players:
		var player := get_player(player_id)
		if not player.is_host and not player.is_ready:
			return {"ok": false, "code": "PLAYER_NOT_READY"}
	var errors := RulesetValidator.validate(ruleset)
	if not errors.is_empty():
		return {"ok": false, "code": "INVALID_RULESET", "errors": errors}
	return {"ok": true, "code": "OK"}

func get_player(player_id: String) -> LobbyPlayerEntry:
	return players.get(player_id) as LobbyPlayerEntry

func player_id_for_peer(peer_id: int) -> String:
	for player_id: String in players:
		var player := get_player(player_id)
		if player.network_peer_id == peer_id:
			return player_id
	return ""

func to_dict() -> Dictionary:
	var player_values: Array[Dictionary] = []
	for player_id: String in _sorted_player_ids():
		player_values.append(get_player(player_id).to_dict())
	return {
		"lobby_id": lobby_id,
		"invite_code": invite_code,
		"host_player_id": host_player_id,
		"status": status,
		"max_players": max_players,
		"players": player_values,
		"ruleset": ruleset.to_dict(),
		"protocol_version": protocol_version,
		"game_version": game_version,
		"ruleset_locked": ruleset_locked,
	}

static func from_dict(raw: Variant) -> LobbyState:
	if not raw is Dictionary:
		return null
	var values: Dictionary = raw
	var lobby := LobbyState.new()
	lobby.lobby_id = str(values.get("lobby_id", ""))
	lobby.invite_code = str(values.get("invite_code", ""))
	lobby.host_player_id = str(values.get("host_player_id", ""))
	lobby.status = int(values.get("status", Status.CREATING)) as Status
	lobby.max_players = int(values.get("max_players", Ruleset.MAX_PLAYERS))
	lobby.protocol_version = int(values.get("protocol_version", App.PROTOCOL_VERSION))
	lobby.game_version = str(values.get("game_version", App.GAME_VERSION))
	lobby.ruleset_locked = bool(values.get("ruleset_locked", false))
	var ruleset_value: Variant = values.get("ruleset", {})
	if ruleset_value is Dictionary:
		lobby.ruleset = Ruleset.from_dict(ruleset_value)
	var players_value: Variant = values.get("players", [])
	if players_value is Array:
		for raw_player in players_value:
			var player := LobbyPlayerEntry.from_dict(raw_player)
			if player != null and not player.player_id.is_empty():
				lobby.players[player.player_id] = player
	return lobby

func _sorted_player_ids() -> Array[String]:
	var result: Array[String] = []
	for player_id: String in players:
		result.append(player_id)
	result.sort()
	return result

static func _color_for_slot(slot: int) -> Color:
	var colors := [Color("e45756"), Color("4f86c6"), Color("5cb85c"), Color("f0ad4e"), Color("9b59b6")]
	return colors[mini(slot, colors.size() - 1)]
