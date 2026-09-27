class_name LobbySnapshot
extends LobbyState

static func from_lobby_state(source: LobbyState) -> LobbySnapshot:
	var snapshot := LobbySnapshot.new()
	var copy := LobbyState.from_dict(source.to_dict())
	snapshot.lobby_id = copy.lobby_id
	snapshot.invite_code = copy.invite_code
	snapshot.host_player_id = copy.host_player_id
	snapshot.status = copy.status
	snapshot.max_players = copy.max_players
	snapshot.players = copy.players
	snapshot.ruleset = copy.ruleset
	snapshot.protocol_version = copy.protocol_version
	snapshot.game_version = copy.game_version
	snapshot.ruleset_locked = copy.ruleset_locked
	return snapshot

static func from_dict(raw: Variant) -> LobbySnapshot:
	var base := LobbyState.from_dict(raw)
	if base == null:
		return null
	return from_lobby_state(base)
