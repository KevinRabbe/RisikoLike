extends Node

signal connection_changed(state: String)
signal network_error(code: String)
signal lobby_changed(snapshot: LobbySnapshot)
signal command_result_received(result: CommandResult)
signal state_snapshot_changed(snapshot: GameStateSnapshot)
signal match_started(game_state: GameState)
signal peer_changed(player_id: String, connected: bool)

enum Role { NONE, HOST, CLIENT }

const DEFAULT_LOCAL_PORT := 43100

var role: Role = Role.NONE
var connection_state := "offline"
var local_player_id := ""
var lobby_id := ""
var match_id := ""
var local_port := DEFAULT_LOCAL_PORT
var game_state: GameState
var lobby_state: LobbyState
var command_processor: CommandProcessor
var transport: NetworkTransport
var backend_mode := false
var _backend_pending_role := ""
var _backend_pending_name := ""
var _backend_pending_max_players := 2
var _backend_pending_ruleset: Ruleset
var _backend_heartbeat_elapsed := 0.0
var _reconnect_elapsed := 0.0
var _reconnect_attempts := 0
var _reconnect_request_pending := false
var _reconnect_transport_pending := false
var _host_disconnect_pending := false
var _host_disconnect_elapsed := 0.0
var _pending_peer_identities: Dictionary = {}
var _issued_reconnect_generations: Dictionary = {}

var _pending_join_name := ""
var _peer_to_player: Dictionary = {}
var _next_player_number := 1

func _ready() -> void:
	set_process(true)
	var backend := get_node_or_null("/root/BackendClient")
	if backend != null:
		backend.lobby_created.connect(_on_backend_lobby_created)
		backend.lobby_resolved.connect(_on_backend_lobby_resolved)
		backend.lobby_started.connect(_on_backend_lobby_started)
		backend.reconnect_credential_received.connect(_on_backend_reconnect_credential)
		backend.reconnect_authorized.connect(_on_backend_reconnect_authorized)
		backend.backend_request_failed.connect(_on_backend_request_failed)

func _process(delta: float) -> void:
	if transport != null:
		transport.poll()
	if role == Role.CLIENT and _host_disconnect_pending and game_state != null:
		_host_disconnect_elapsed += delta
		# Let already-buffered reliable data channels deliver the final command
		# result/snapshot before presenting the terminal host-loss state.
		if _host_disconnect_elapsed >= 0.25 and game_state.status == GameState.MatchStatus.PLAYING:
			_host_disconnect_pending = false
			game_state.status = GameState.MatchStatus.TERMINATED
			game_state.last_action_id = "host-disconnect"
			game_state.last_result = {"code": "HOST_UNAVAILABLE"}
			network_error.emit("HOST_UNAVAILABLE")
	if role == Role.HOST and game_state != null and command_processor != null and game_state.status == GameState.MatchStatus.PLAYING:
		var lifecycle := command_processor.advance_time(game_state.clock.now_msec())
		if bool(lifecycle.get("changed", false)):
			_broadcast_game_state(NetworkMessage.STATE_SNAPSHOT, game_state.last_action_id)
			var host_snapshot := snapshot_for_player(local_player_id)
			if host_snapshot != null:
				state_snapshot_changed.emit(host_snapshot)
	if backend_mode and role == Role.HOST:
		_backend_heartbeat_elapsed += delta
		if _backend_heartbeat_elapsed >= 15.0:
			_backend_heartbeat_elapsed = 0.0
			var backend := get_node_or_null("/root/BackendClient")
			if backend != null:
				backend.heartbeat()
	if role == Role.CLIENT and game_state != null and connection_state in ["disconnected", "reconnecting"]:
		_reconnect_elapsed += delta
		if _reconnect_elapsed >= float(game_state.ruleset.reconnect_timeout_seconds):
			if connection_state != "failed":
				set_connection_state("failed")
				network_error.emit("RECONNECT_WINDOW_EXPIRED")
		elif not _reconnect_request_pending and not _reconnect_transport_pending and _reconnect_elapsed >= _next_reconnect_delay():
			_attempt_reconnect()

func set_connection_state(next_state: String) -> void:
	if connection_state == next_state:
		return
	connection_state = next_state
	if is_inside_tree():
		var session := get_node_or_null("/root/SessionManager")
		if session != null:
			match next_state:
				"in_game", "joined", "hosting":
					session.connection_state = session.ConnectionState.CONNECTED
				"disconnected":
					session.connection_state = session.ConnectionState.DISCONNECTED
				"reconnecting":
					session.connection_state = session.ConnectionState.RECONNECTING
				"failed":
					session.connection_state = session.ConnectionState.FAILED
				_:
					session.connection_state = session.ConnectionState.OFFLINE
	connection_changed.emit(connection_state)

func host_local_lobby(player_name: String, max_players: int, p_ruleset: Ruleset = null, port: int = DEFAULT_LOCAL_PORT) -> Dictionary:
	backend_mode = false
	return _host_lobby(player_name, max_players, p_ruleset, port, LocalNetworkTransport.new())

func host_lobby_on_transport(player_name: String, max_players: int, p_ruleset: Ruleset, p_transport: NetworkTransport, port: int = DEFAULT_LOCAL_PORT) -> Dictionary:
	return _host_lobby(player_name, max_players, p_ruleset, port, p_transport)

func _host_lobby(player_name: String, max_players: int, p_ruleset: Ruleset, port: int, p_transport: NetworkTransport) -> Dictionary:
	if max_players < Ruleset.MIN_PLAYERS or max_players > Ruleset.MAX_PLAYERS:
		return {"ok": false, "code": "INVALID_PLAYER_COUNT"}
	var ruleset := p_ruleset.duplicate_ruleset() if p_ruleset != null else Ruleset.new()
	var ruleset_errors := RulesetValidator.validate(ruleset)
	if not ruleset_errors.is_empty():
		return {"ok": false, "code": "INVALID_RULESET", "errors": ruleset_errors}
	if not _replace_transport(p_transport):
		return {"ok": false, "code": "TRANSPORT_UNAVAILABLE"}
	if not transport.start_host(port):
		return {"ok": false, "code": "PORT_UNAVAILABLE"}
	role = Role.HOST
	local_port = port
	local_player_id = "P1"
	lobby_id = _new_id("lobby")
	match_id = ""
	_pending_join_name = ""
	_peer_to_player.clear()
	_next_player_number = 2
	lobby_state = LobbyState.new()
	lobby_state.lobby_id = lobby_id
	lobby_state.invite_code = "DEV-%d" % port
	lobby_state.max_players = max_players
	lobby_state.ruleset = ruleset
	var add_result := lobby_state.add_player(local_player_id, player_name, 1, true)
	if not bool(add_result.get("ok", false)):
		shutdown()
		return add_result
	set_connection_state("hosting")
	_sync_session()
	_emit_lobby_changed()
	print("[LOBBY] host lobby=%s code=%s player=%s port=%d" % [lobby_id, lobby_state.invite_code, local_player_id, port])
	return {"ok": true, "code": "OK", "lobby_id": lobby_id, "invite_code": lobby_state.invite_code, "player_id": local_player_id}

func join_local_lobby(player_name: String, address: String = "127.0.0.1", port: int = DEFAULT_LOCAL_PORT) -> Dictionary:
	backend_mode = false
	return _join_lobby(player_name, address, port, LocalNetworkTransport.new())

func host_online_lobby(player_name: String, max_players: int, p_ruleset: Ruleset = null) -> Dictionary:
	if player_name.strip_edges().length() < 2 or player_name.strip_edges().length() > 20:
		return {"ok": false, "code": "NAME_INVALID"}
	if max_players < Ruleset.MIN_PLAYERS or max_players > Ruleset.MAX_PLAYERS:
		return {"ok": false, "code": "INVALID_PLAYER_COUNT"}
	var backend := get_node_or_null("/root/BackendClient")
	if backend == null or not backend.is_configured():
		return {"ok": false, "code": "BACKEND_NOT_CONFIGURED"}
	_backend_pending_role = "host"
	_backend_pending_name = player_name.strip_edges()
	_backend_pending_max_players = max_players
	_backend_pending_ruleset = p_ruleset.duplicate_ruleset() if p_ruleset != null else Ruleset.new()
	backend_mode = true
	return backend.create_lobby(max_players)

func join_online_lobby(player_name: String, invite_code: String) -> Dictionary:
	if player_name.strip_edges().length() < 2 or player_name.strip_edges().length() > 20:
		return {"ok": false, "code": "NAME_INVALID"}
	var backend := get_node_or_null("/root/BackendClient")
	if backend == null or not backend.is_configured():
		return {"ok": false, "code": "BACKEND_NOT_CONFIGURED"}
	_backend_pending_role = "client"
	_backend_pending_name = player_name.strip_edges()
	_backend_pending_max_players = 2
	_backend_pending_ruleset = null
	backend_mode = true
	return backend.resolve_invite_code(invite_code)

func _on_backend_lobby_created(data: Dictionary) -> void:
	if _backend_pending_role != "host":
		return
	var ruleset := _backend_pending_ruleset.duplicate_ruleset() if _backend_pending_ruleset != null else Ruleset.new()
	var transport_instance := WebRTCNetworkTransport.new()
	var backend := get_node_or_null("/root/BackendClient")
	transport_instance.configure(backend, str(data.get("lobby_id", "")), str(data.get("host_session_token", "")), str(data.get("signaling_url", "")), data.get("ice_servers", []), false)
	var result := _host_lobby_with_backend_identity(_backend_pending_name, _backend_pending_max_players, ruleset, transport_instance, data)
	if not bool(result.get("ok", false)):
		network_error.emit(str(result.get("code", "BACKEND_LOBBY_FAILED")))
	_backend_pending_role = ""

func _on_backend_lobby_resolved(data: Dictionary) -> void:
	if _backend_pending_role != "client":
		return
	var backend := get_node_or_null("/root/BackendClient")
	var transport_instance := WebRTCNetworkTransport.new()
	transport_instance.configure(backend, str(data.get("lobby_id", "")), str(data.get("join_token", "")), str(data.get("signaling_url", "")), data.get("ice_servers", []), false)
	_replace_transport(transport_instance)
	role = Role.CLIENT
	local_player_id = ""
	lobby_id = str(data.get("lobby_id", ""))
	match_id = ""
	_pending_join_name = _backend_pending_name
	_peer_to_player.clear()
	local_port = 0
	set_connection_state("connecting")
	_sync_session()
	if not transport.connect_to_host("backend", 0):
		shutdown()
		network_error.emit("SIGNALING_UNAVAILABLE")
	_backend_pending_role = ""

func _on_backend_lobby_started(_data: Dictionary) -> void:
	if role != Role.HOST or not backend_mode or lobby_state == null:
		return
	var backend := get_node_or_null("/root/BackendClient")
	if backend == null:
		return
	for player_id: String in _sorted_player_ids(lobby_state.players):
		if player_id != local_player_id:
			backend.request_reconnect_credential(player_id)

func _on_backend_reconnect_credential(data: Dictionary) -> void:
	if role != Role.HOST or game_state == null:
		return
	var player_id := str(data.get("player_id", ""))
	var reconnect_token := str(data.get("reconnect_token", ""))
	if player_id.is_empty() or reconnect_token.is_empty() or player_id == local_player_id:
		return
	var peer_id := 0
	for candidate_peer_id in _peer_to_player:
		if str(_peer_to_player[candidate_peer_id]) == player_id:
			peer_id = int(candidate_peer_id)
			break
	if peer_id == 0:
		return
	_issued_reconnect_generations[player_id] = int(data.get("generation", 1))
	_send_message(peer_id, NetworkMessage.new(NetworkMessage.RECONNECT_CREDENTIAL, {
		"match_id": str(data.get("match_id", match_id)),
		"player_id": player_id,
		"reconnect_token": reconnect_token,
		"expires_at": str(data.get("expires_at", "")),
		"connection_generation": int(data.get("generation", 1)),
	}, match_id))

func _on_backend_reconnect_authorized(data: Dictionary) -> void:
	if role != Role.CLIENT or game_state == null:
		return
	var player_id := str(data.get("player_id", ""))
	var generation := int(data.get("generation", 0))
	var ticket := str(data.get("reconnect_ticket", ""))
	if player_id != local_player_id or ticket.is_empty() or generation <= 0:
		_reconnect_request_pending = false
		set_connection_state("failed")
		network_error.emit("RECONNECT_FAILED")
		return
	var session := get_node_or_null("/root/SessionManager")
	var rotated_token := str(data.get("reconnect_token", ""))
	if session != null:
		session.set_reconnect_credentials(match_id, local_player_id, rotated_token, str(data.get("expires_at", "")), generation)
	var backend := get_node_or_null("/root/BackendClient")
	var next_transport := WebRTCNetworkTransport.new()
	next_transport.configure(backend, match_id, ticket, str(data.get("signaling_url", "")), data.get("ice_servers", []), false)
	if not _replace_transport(next_transport):
		_reconnect_request_pending = false
		set_connection_state("failed")
		network_error.emit("RECONNECT_FAILED")
		return
	_reconnect_request_pending = false
	_reconnect_transport_pending = true
	set_connection_state("reconnecting")
	if not next_transport.connect_for_reconnect(local_player_id, generation):
		_reconnect_transport_pending = false
		_reconnect_attempts += 1
		set_connection_state("disconnected")
		network_error.emit("RECONNECT_FAILED")

func _on_backend_request_failed(operation: String, code: String) -> void:
	if operation == "authorize_reconnect":
		_reconnect_request_pending = false
		_reconnect_attempts += 1
		if _reconnect_elapsed >= float(game_state.ruleset.reconnect_timeout_seconds):
			set_connection_state("failed")
		else:
			set_connection_state("disconnected")
		network_error.emit(BackendErrorMapper.to_game_code(code))
		return
	if _backend_pending_role.is_empty():
		return
	network_error.emit(BackendErrorMapper.to_game_code("%s:%s" % [operation, code]))
	_backend_pending_role = ""
	backend_mode = false

func _host_lobby_with_backend_identity(player_name: String, max_players: int, p_ruleset: Ruleset, p_transport: NetworkTransport, data: Dictionary) -> Dictionary:
	if p_ruleset == null:
		p_ruleset = Ruleset.new()
	var ruleset_errors := RulesetValidator.validate(p_ruleset)
	if not ruleset_errors.is_empty():
		return {"ok": false, "code": "INVALID_RULESET", "errors": ruleset_errors}
	if not _replace_transport(p_transport):
		return {"ok": false, "code": "TRANSPORT_UNAVAILABLE"}
	if not transport.start_host(0):
		return {"ok": false, "code": "SIGNALING_UNAVAILABLE"}
	role = Role.HOST
	backend_mode = true
	local_port = 0
	local_player_id = "P1"
	lobby_id = str(data.get("lobby_id", ""))
	match_id = ""
	_pending_join_name = ""
	_peer_to_player.clear()
	_next_player_number = 2
	lobby_state = LobbyState.new()
	lobby_state.lobby_id = lobby_id
	lobby_state.invite_code = str(data.get("invite_code", ""))
	lobby_state.max_players = max_players
	lobby_state.ruleset = p_ruleset
	var add_result := lobby_state.add_player(local_player_id, player_name, 1, true)
	if not bool(add_result.get("ok", false)):
		shutdown()
		return add_result
	set_connection_state("hosting")
	_sync_session()
	_emit_lobby_changed()
	print("[LOBBY] online host lobby=%s code=%s player=%s" % [lobby_id, lobby_state.invite_code, local_player_id])
	return {"ok": true, "code": "OK", "lobby_id": lobby_id, "invite_code": lobby_state.invite_code, "player_id": local_player_id}

func join_lobby_on_transport(player_name: String, p_transport: NetworkTransport, address: String = "in-process", port: int = DEFAULT_LOCAL_PORT) -> Dictionary:
	return _join_lobby(player_name, address, port, p_transport)

func _join_lobby(player_name: String, address: String, port: int, p_transport: NetworkTransport) -> Dictionary:
	if player_name.strip_edges().length() < 2 or player_name.strip_edges().length() > 20:
		return {"ok": false, "code": "NAME_INVALID"}
	if address.strip_edges().is_empty() or port < 1 or port > 65535:
		return {"ok": false, "code": "INVALID_REQUEST"}
	if not _replace_transport(p_transport):
		return {"ok": false, "code": "TRANSPORT_UNAVAILABLE"}
	role = Role.CLIENT
	local_player_id = ""
	lobby_id = ""
	match_id = ""
	_pending_join_name = player_name.strip_edges()
	_peer_to_player.clear()
	local_port = port
	set_connection_state("connecting")
	_sync_session()
	if not transport.connect_to_host(address.strip_edges(), port):
		shutdown()
		return {"ok": false, "code": "CONNECT_FAILED"}
	return {"ok": true, "code": "CONNECTING"}

func submit_command(command: CommandEnvelope) -> Dictionary:
	if command == null:
		return {"ok": false, "code": "INVALID_REQUEST"}
	if game_state == null:
		return {"ok": false, "code": "MATCH_NOT_STARTED"}
	if role == Role.HOST:
		if command.player_id != local_player_id:
			return {"ok": false, "code": "INVALID_PLAYER"}
		var result := _execute_host_command(1, command)
		return {"ok": result != null and result.accepted, "code": result.code if result != null else "COMMAND_REJECTED"}
	if role == Role.CLIENT:
		if command.player_id != local_player_id:
			return {"ok": false, "code": "INVALID_PLAYER"}
		if game_state.status != GameState.MatchStatus.PLAYING:
			return {"ok": false, "code": "MATCH_FINISHED" if game_state.status == GameState.MatchStatus.FINISHED else "MATCH_NOT_PLAYING"}
		var local_player := game_state.get_player(local_player_id)
		if local_player == null or not local_player.can_take_turn():
			return {"ok": false, "code": "PLAYER_NOT_ACTIVE"}
		return {"ok": _send_message(1, NetworkMessage.new(NetworkMessage.COMMAND_REQUEST, {"command": command.to_dict()}, match_id)), "code": "QUEUED"}
	return {"ok": false, "code": "NOT_CONNECTED"}

func set_ready_state(ready: bool) -> Dictionary:
	if role != Role.CLIENT or local_player_id.is_empty():
		return {"ok": false, "code": "NOT_CLIENT"}
	return {"ok": _send_message(1, NetworkMessage.new(NetworkMessage.READY_CHANGED, {"player_id": local_player_id, "ready": ready}, lobby_id)), "code": "QUEUED"}

func enter_spectator() -> Dictionary:
	if game_state == null or local_player_id.is_empty():
		return {"ok": false, "code": "MATCH_NOT_STARTED"}
	if role == Role.HOST:
		var host_result := command_processor.enter_spectator(local_player_id)
		if bool(host_result.get("ok", false)):
			_broadcast_lobby()
			_broadcast_game_state(NetworkMessage.STATE_SNAPSHOT)
		return host_result
	if role != Role.CLIENT:
		return {"ok": false, "code": "NOT_CONNECTED"}
	return {"ok": _send_message(1, NetworkMessage.new(NetworkMessage.SPECTATOR_REQUEST, {"player_id": local_player_id}, match_id)), "code": "QUEUED"}

func configure_ruleset(next_ruleset: Ruleset) -> Dictionary:
	if role != Role.HOST or lobby_state == null:
		return {"ok": false, "code": "NOT_HOST"}
	var result := lobby_state.set_ruleset(next_ruleset)
	if bool(result.get("ok", false)):
		_broadcast_lobby()
	return result

func request_ruleset_change(_next_ruleset: Ruleset) -> Dictionary:
	return {"ok": false, "code": "NOT_HOST"}

func start_match(seed_value: int = 424242) -> Dictionary:
	if role != Role.HOST or lobby_state == null:
		return {"ok": false, "code": "NOT_HOST"}
	var can_start := lobby_state.can_start()
	if not bool(can_start.get("ok", false)):
		return can_start
	lobby_state.status = LobbyState.Status.STARTING
	lobby_state.ruleset_locked = true
	var player_ids: Array[String] = []
	for player_id: String in _sorted_player_ids(lobby_state.players):
		player_ids.append(player_id)
	game_state = GameState.create_local_for_player_ids(player_ids, seed_value, lobby_state.ruleset)
	game_state.match_id = lobby_state.lobby_id
	for player_id: String in player_ids:
		var lobby_player := lobby_state.get_player(player_id)
		var player := game_state.get_player(player_id)
		player.name = lobby_player.name
		player.color = lobby_player.color
	command_processor = CommandProcessor.new(game_state, RandomSource.new(seed_value))
	match_id = game_state.match_id
	lobby_state.status = LobbyState.Status.IN_GAME
	if backend_mode:
		var backend := get_node_or_null("/root/BackendClient")
		if backend != null:
			backend.mark_lobby_started()
	set_connection_state("in_game")
	_sync_session()
	_broadcast_lobby()
	_broadcast_game_state(NetworkMessage.MATCH_STARTED)
	match_started.emit(game_state)
	print("[GAME] match started lobby=%s revision=%d" % [lobby_id, game_state.state_revision])
	return {"ok": true, "code": "OK", "match_id": match_id}

func begin_manual_reconnect() -> Dictionary:
	if role != Role.CLIENT or game_state == null:
		return {"ok": false, "code": "NOT_CLIENT"}
	_reconnect_elapsed = 0.0
	_reconnect_attempts = 0
	_reconnect_request_pending = false
	_reconnect_transport_pending = false
	set_connection_state("disconnected")
	return {"ok": true, "code": "RECONNECTING"}

func request_snapshot() -> Dictionary:
	if role != Role.CLIENT:
		return {"ok": false, "code": "NOT_CLIENT"}
	return {"ok": _send_message(1, NetworkMessage.new(NetworkMessage.SNAPSHOT_REQUEST, {"player_id": local_player_id}, match_id)), "code": "QUEUED"}

func leave_lobby() -> Dictionary:
	if role == Role.CLIENT and not lobby_id.is_empty():
		_send_message(1, NetworkMessage.new(NetworkMessage.LEAVE_LOBBY, {"player_id": local_player_id}, lobby_id))
		shutdown()
		return {"ok": true, "code": "OK"}
	if role == Role.HOST:
		close_lobby()
		return {"ok": true, "code": "OK"}
	return {"ok": false, "code": "NOT_CONNECTED"}

func close_lobby() -> void:
	if role == Role.HOST and lobby_state != null:
		if backend_mode:
			var backend := get_node_or_null("/root/BackendClient")
			if backend != null:
				backend.close_lobby()
		lobby_state.status = LobbyState.Status.CLOSED
		_broadcast(NetworkMessage.new(NetworkMessage.ERROR, {"code": "LOBBY_CLOSED"}, lobby_id))
	shutdown()

func get_local_player() -> PlayerState:
	return game_state.get_player(local_player_id) if game_state != null else null

func has_active_match() -> bool:
	return game_state != null and not match_id.is_empty()

func snapshot_for_player(player_id: String = "") -> GameStateSnapshot:
	if game_state == null:
		return null
	var viewer := player_id if not player_id.is_empty() else local_player_id
	var viewer_state := game_state.get_player(viewer)
	if viewer_state != null and viewer_state.is_spectating():
		viewer = ""
	return GameStateSnapshot.from_game_state(game_state, viewer)

func state_fingerprint(player_id: String = "") -> String:
	var snapshot := snapshot_for_player(player_id)
	return snapshot.fingerprint() if snapshot != null else ""

func find_valid_card_set(card_ids: Array[String]) -> Array[String]:
	if game_state == null:
		return []
	var manager := CardManager.new(game_state, RandomSource.new(1))
	for first in range(card_ids.size()):
		for second in range(first + 1, card_ids.size()):
			for third in range(second + 1, card_ids.size()):
				var candidate: Array[String] = [card_ids[first], card_ids[second], card_ids[third]]
				if manager.is_valid_set(candidate):
					return candidate
	return []

func shutdown() -> void:
	if transport != null:
		transport.close()
	transport = null
	if backend_mode:
		var backend := get_node_or_null("/root/BackendClient")
		if backend != null:
			backend.clear_session()
	role = Role.NONE
	connection_state = "offline"
	local_player_id = ""
	lobby_id = ""
	match_id = ""
	game_state = null
	lobby_state = null
	command_processor = null
	_peer_to_player.clear()
	_pending_join_name = ""
	_backend_pending_role = ""
	_backend_pending_name = ""
	_backend_pending_ruleset = null
	_backend_heartbeat_elapsed = 0.0
	_reconnect_elapsed = 0.0
	_reconnect_attempts = 0
	_reconnect_request_pending = false
	_reconnect_transport_pending = false
	_pending_peer_identities.clear()
	_issued_reconnect_generations.clear()
	backend_mode = false
	_sync_session()
	connection_changed.emit(connection_state)

func _replace_transport(next_transport: NetworkTransport) -> bool:
	if next_transport == null:
		return false
	if transport != null:
		if transport.packet_received.is_connected(_on_packet_received):
			transport.packet_received.disconnect(_on_packet_received)
		if transport.peer_connected.is_connected(_on_peer_connected):
			transport.peer_connected.disconnect(_on_peer_connected)
		if transport.peer_disconnected.is_connected(_on_peer_disconnected):
			transport.peer_disconnected.disconnect(_on_peer_disconnected)
		if transport.peer_identity_received.is_connected(_on_peer_identity_received):
			transport.peer_identity_received.disconnect(_on_peer_identity_received)
		if transport.transport_error.is_connected(_on_transport_error):
			transport.transport_error.disconnect(_on_transport_error)
		if transport is WebRTCNetworkTransport:
			(transport as WebRTCNetworkTransport).detach_backend_signals()
		transport.close()
	transport = next_transport
	transport.packet_received.connect(_on_packet_received)
	transport.peer_connected.connect(_on_peer_connected)
	transport.peer_disconnected.connect(_on_peer_disconnected)
	transport.peer_identity_received.connect(_on_peer_identity_received)
	transport.transport_error.connect(_on_transport_error)
	return true

func _on_peer_connected(peer_id: int) -> void:
	print("[NETWORK] peer connected peer=%d role=%s" % [peer_id, Role.keys()[role]])
	if role == Role.HOST and _pending_peer_identities.has(peer_id):
		var identity: Dictionary = _pending_peer_identities[peer_id]
		var player_id := str(identity.get("player_id", ""))
		var generation := int(identity.get("generation", 0))
		var lobby_player := lobby_state.get_player(player_id) if lobby_state != null else null
		var expected_generation := int(_issued_reconnect_generations.get(player_id, 0))
		if lobby_player == null or lobby_player.connection_state != "DISCONNECTED" or generation != expected_generation + 1:
			if transport is WebRTCNetworkTransport:
				(transport as WebRTCNetworkTransport).reject_reconnect(peer_id, "RECONNECT_FAILED")
			_pending_peer_identities.erase(peer_id)
			return
		_peer_to_player[peer_id] = player_id
		_pending_peer_identities.erase(peer_id)
		_issued_reconnect_generations[player_id] = generation
		if command_processor != null:
			var reconnect_result := command_processor.mark_reconnected(player_id)
			if not bool(reconnect_result.get("ok", false)):
				if transport is WebRTCNetworkTransport:
					(transport as WebRTCNetworkTransport).reject_reconnect(peer_id, str(reconnect_result.get("code", "RECONNECT_FAILED")))
				_pending_peer_identities.erase(peer_id)
				return
		lobby_player.network_peer_id = peer_id
		lobby_player.connection_state = "CONNECTED"
		_broadcast_lobby()
		_send_snapshot_to_peer(peer_id, player_id, NetworkMessage.STATE_SNAPSHOT)
		peer_changed.emit(player_id, true)
		return
	if role == Role.CLIENT and peer_id == 1 and not _reconnect_transport_pending:
		_send_message(1, NetworkMessage.new(NetworkMessage.JOIN_REQUEST, {
			"player_name": _pending_join_name,
			"protocol_version": App.PROTOCOL_VERSION,
			"game_version": App.GAME_VERSION,
		}, lobby_id))

func _on_peer_disconnected(peer_id: int) -> void:
	var player_id := str(_peer_to_player.get(peer_id, ""))
	if not player_id.is_empty() and lobby_state != null and role == Role.HOST:
		if game_state != null and not match_id.is_empty() and game_state.status == GameState.MatchStatus.PLAYING:
			var lobby_player := lobby_state.get_player(player_id)
			if lobby_player != null:
				lobby_player.network_peer_id = 0
				lobby_player.connection_state = "DISCONNECTED"
			_peer_to_player.erase(peer_id)
			_broadcast_lobby()
			if command_processor != null:
				command_processor.mark_disconnected(player_id)
			_broadcast_game_state(NetworkMessage.STATE_SNAPSHOT)
			peer_changed.emit(player_id, false)
			return
		if game_state != null and not match_id.is_empty():
			_peer_to_player.erase(peer_id)
			peer_changed.emit(player_id, false)
			return
		lobby_state.remove_player(player_id)
		_peer_to_player.erase(peer_id)
		_broadcast_lobby()
		peer_changed.emit(player_id, false)
	if role == Role.CLIENT and connection_state != "offline" and game_state != null:
		if peer_id == 1:
			_host_disconnect_pending = true
			_host_disconnect_elapsed = 0.0
			set_connection_state("failed")
			return
		_reconnect_elapsed = 0.0
		_reconnect_attempts = 0
		_reconnect_request_pending = false
		_reconnect_transport_pending = false
		set_connection_state("disconnected")
		network_error.emit("PEER_DISCONNECTED")

func _on_transport_error(code: String) -> void:
	if role == Role.CLIENT and connection_state == "reconnecting":
		_reconnect_transport_pending = false
		_reconnect_attempts += 1
		set_connection_state("disconnected")
	network_error.emit(code)

func _on_peer_identity_received(peer_id: int, player_id: String, generation: int) -> void:
	if role != Role.HOST or lobby_state == null or game_state == null:
		return
	var lobby_player := lobby_state.get_player(player_id)
	var expected_generation := int(_issued_reconnect_generations.get(player_id, 0))
	if lobby_player == null or lobby_player.connection_state != "DISCONNECTED" or generation != expected_generation + 1:
		if transport is WebRTCNetworkTransport:
			(transport as WebRTCNetworkTransport).reject_reconnect(peer_id, "RECONNECT_FAILED")
		return
	_pending_peer_identities[peer_id] = {"player_id": player_id, "generation": generation}

func _on_packet_received(peer_id: int, serialized_message: String) -> void:
	var decoded := NetworkSerializer.decode_message(serialized_message)
	if not bool(decoded.get("ok", false)):
		var code := str(decoded.get("code", "INVALID_MESSAGE"))
		network_error.emit(code)
		if role == Role.HOST:
			_send_message(peer_id, NetworkMessage.new(NetworkMessage.ERROR, {"code": code}, lobby_id))
		return
	var message: NetworkMessage = decoded.get("message") as NetworkMessage
	if role == Role.HOST:
		_handle_host_message(peer_id, message)
	else:
		_handle_client_message(message)

func _handle_host_message(peer_id: int, message: NetworkMessage) -> void:
	match message.message_type:
		NetworkMessage.JOIN_REQUEST:
			_handle_join_request(peer_id, message)
		NetworkMessage.READY_CHANGED:
			_handle_ready_request(peer_id, message)
		NetworkMessage.LEAVE_LOBBY:
			_handle_leave_request(peer_id, message)
		NetworkMessage.COMMAND_REQUEST:
			_handle_command_request(peer_id, message)
		NetworkMessage.SNAPSHOT_REQUEST:
			_send_snapshot_to_peer(peer_id, str(_peer_to_player.get(peer_id, "")), NetworkMessage.STATE_SNAPSHOT)
		NetworkMessage.SPECTATOR_REQUEST:
			_handle_spectator_request(peer_id, message)
		NetworkMessage.RULESET_REQUEST:
			_send_message(peer_id, NetworkMessage.new(NetworkMessage.ERROR, {"code": "NOT_HOST"}, lobby_id))
		_:
			_send_message(peer_id, NetworkMessage.new(NetworkMessage.ERROR, {"code": "UNKNOWN_MESSAGE_TYPE"}, lobby_id))

func _handle_client_message(message: NetworkMessage) -> void:
	match message.message_type:
		NetworkMessage.JOIN_ACCEPTED:
			local_player_id = str(message.payload.get("player_id", ""))
			lobby_id = str(message.payload.get("lobby_id", ""))
			set_connection_state("joined")
			_sync_session()
		NetworkMessage.JOIN_REJECTED:
			network_error.emit(str(message.payload.get("code", "JOIN_REJECTED")))
		NetworkMessage.RECONNECT_CREDENTIAL:
			var credential_player_id := str(message.payload.get("player_id", ""))
			var reconnect_token := str(message.payload.get("reconnect_token", ""))
			if credential_player_id != local_player_id or reconnect_token.is_empty() or str(message.payload.get("match_id", "")) != match_id:
				network_error.emit("RECONNECT_TOKEN_INVALID")
				return
			var session := get_node_or_null("/root/SessionManager")
			if session != null:
				session.set_reconnect_credentials(match_id, local_player_id, reconnect_token, str(message.payload.get("expires_at", "")), int(message.payload.get("connection_generation", 1)))
		NetworkMessage.LOBBY_SNAPSHOT:
			var snapshot := LobbySnapshot.from_dict(message.payload.get("lobby", {}))
			if snapshot != null:
				lobby_state = snapshot
				lobby_id = snapshot.lobby_id
				_emit_lobby_changed()
		NetworkMessage.MATCH_STARTED, NetworkMessage.STATE_SNAPSHOT:
			_apply_snapshot_message(message)
		NetworkMessage.COMMAND_RESULT:
			_handle_command_result(message)
		NetworkMessage.PEER_LEFT:
			peer_changed.emit(str(message.payload.get("player_id", "")), false)
		NetworkMessage.ERROR:
			var error_code := str(message.payload.get("code", "NETWORK_ERROR"))
			network_error.emit(error_code)
			if error_code == "LOBBY_CLOSED":
				shutdown()
			elif error_code == "MATCH_LEFT":
				shutdown()
		_:
			network_error.emit("UNKNOWN_MESSAGE_TYPE")

func _handle_join_request(peer_id: int, message: NetworkMessage) -> void:
	if lobby_state == null or lobby_state.status != LobbyState.Status.OPEN:
		_send_message(peer_id, NetworkMessage.new(NetworkMessage.JOIN_REJECTED, {"code": "LOBBY_CLOSED"}, lobby_id))
		return
	if int(message.payload.get("protocol_version", -1)) != App.PROTOCOL_VERSION:
		_send_message(peer_id, NetworkMessage.new(NetworkMessage.JOIN_REJECTED, {"code": "PROTOCOL_MISMATCH"}, lobby_id))
		return
	if str(message.payload.get("game_version", "")) != App.GAME_VERSION:
		_send_message(peer_id, NetworkMessage.new(NetworkMessage.JOIN_REJECTED, {"code": "VERSION_MISMATCH"}, lobby_id))
		return
	if _peer_to_player.has(peer_id):
		_send_message(peer_id, NetworkMessage.new(NetworkMessage.JOIN_REJECTED, {"code": "DUPLICATE_ACTION"}, lobby_id))
		return
	var player_id := "P%d" % _next_player_number
	_next_player_number += 1
	var result := lobby_state.add_player(player_id, str(message.payload.get("player_name", "")), peer_id, false)
	if not bool(result.get("ok", false)):
		_send_message(peer_id, NetworkMessage.new(NetworkMessage.JOIN_REJECTED, {"code": result.get("code", "INVALID_REQUEST")}, lobby_id))
		return
	_peer_to_player[peer_id] = player_id
	_send_message(peer_id, NetworkMessage.new(NetworkMessage.JOIN_ACCEPTED, {"player_id": player_id, "lobby_id": lobby_id}, lobby_id))
	_broadcast_lobby()
	peer_changed.emit(player_id, true)
	print("[LOBBY] player joined player=%s peer=%d" % [player_id, peer_id])

func _handle_spectator_request(peer_id: int, message: NetworkMessage) -> void:
	var player_id := str(_peer_to_player.get(peer_id, ""))
	if player_id.is_empty() or player_id != str(message.payload.get("player_id", "")):
		_send_message(peer_id, NetworkMessage.new(NetworkMessage.ERROR, {"code": "INVALID_PLAYER"}, match_id))
		return
	if command_processor == null:
		_send_message(peer_id, NetworkMessage.new(NetworkMessage.ERROR, {"code": "MATCH_NOT_STARTED"}, match_id))
		return
	var result := command_processor.enter_spectator(player_id)
	if not bool(result.get("ok", false)):
		_send_message(peer_id, NetworkMessage.new(NetworkMessage.ERROR, {"code": str(result.get("code", "SPECTATOR_REJECTED"))}, match_id))
		if str(result.get("code", "")) == "SPECTATOR_DISABLED":
			_send_message(peer_id, NetworkMessage.new(NetworkMessage.ERROR, {"code": "MATCH_LEFT"}, match_id))
		return
	var lobby_player := lobby_state.get_player(player_id) if lobby_state != null else null
	if lobby_player != null:
		lobby_player.spectator = true
	_broadcast_lobby()
	_broadcast_game_state(NetworkMessage.STATE_SNAPSHOT)

func _handle_ready_request(peer_id: int, message: NetworkMessage) -> void:
	var player_id := str(_peer_to_player.get(peer_id, ""))
	if player_id.is_empty() or player_id != str(message.payload.get("player_id", "")):
		_send_message(peer_id, NetworkMessage.new(NetworkMessage.ERROR, {"code": "INVALID_PLAYER"}, lobby_id))
		return
	var result := lobby_state.set_ready(player_id, bool(message.payload.get("ready", false)))
	if not bool(result.get("ok", false)):
		_send_message(peer_id, NetworkMessage.new(NetworkMessage.ERROR, {"code": result.get("code", "INVALID_REQUEST")}, lobby_id))
		return
	_broadcast_lobby()

func _handle_leave_request(peer_id: int, _message: NetworkMessage) -> void:
	var player_id := str(_peer_to_player.get(peer_id, ""))
	if player_id.is_empty():
		return
	lobby_state.remove_player(player_id)
	_peer_to_player.erase(peer_id)
	_broadcast(NetworkMessage.new(NetworkMessage.PEER_LEFT, {"player_id": player_id}, lobby_id))
	_broadcast_lobby()

func _handle_command_request(peer_id: int, message: NetworkMessage) -> void:
	var command := CommandEnvelope.from_dict(message.payload.get("command", {}))
	if command == null:
		_send_message(peer_id, NetworkMessage.new(NetworkMessage.COMMAND_RESULT, {"result": CommandResult.new(false, "INVALID_REQUEST", game_state.state_revision).to_dict()}, match_id))
		return
	_execute_host_command(peer_id, command)

func _execute_host_command(peer_id: int, command: CommandEnvelope) -> CommandResult:
	var expected_player_id := local_player_id if peer_id == 1 else str(_peer_to_player.get(peer_id, ""))
	var result: CommandResult
	if expected_player_id.is_empty() or command.player_id != expected_player_id:
		result = CommandResult.new(false, "INVALID_PLAYER", game_state.state_revision, {}, command.action_id)
	else:
		result = command_processor.execute(command)
		result.action_id = command.action_id
	var recipient_player_id := expected_player_id
	var payload := {"result": result.to_dict()}
	if result.accepted:
		_broadcast_game_state(NetworkMessage.COMMAND_RESULT, command.action_id, result)
	else:
		_send_message(peer_id, NetworkMessage.new(NetworkMessage.COMMAND_RESULT, payload, match_id))
		command_result_received.emit(result)
	return result

func _apply_snapshot_message(message: NetworkMessage) -> void:
	var snapshot := GameStateSnapshot.from_dict(message.payload.get("snapshot", {}))
	if snapshot == null or snapshot.protocol_version != App.PROTOCOL_VERSION:
		network_error.emit("INVALID_SNAPSHOT")
		return
	if game_state == null:
		game_state = GameState.new()
	if not snapshot.apply_to_game_state(game_state):
		network_error.emit("INVALID_SNAPSHOT")
		return
	match_id = game_state.match_id
	if lobby_state != null:
		lobby_state.status = LobbyState.Status.IN_GAME
	var was_reconnecting := _reconnect_transport_pending or connection_state == "reconnecting"
	_reconnect_transport_pending = false
	_host_disconnect_pending = false
	_host_disconnect_elapsed = 0.0
	_reconnect_request_pending = false
	_reconnect_elapsed = 0.0
	_reconnect_attempts = 0
	set_connection_state("in_game")
	_sync_session()
	state_snapshot_changed.emit(snapshot)
	if message.message_type == NetworkMessage.MATCH_STARTED:
		match_started.emit(game_state)
	if was_reconnecting and game_state.status == GameState.MatchStatus.FINISHED:
		network_error.emit("MATCH_FINISHED")

func _handle_command_result(message: NetworkMessage) -> void:
	var result := CommandResult.from_dict(message.payload.get("result", {}))
	if result == null:
		network_error.emit("INVALID_RESULT")
		return
	command_result_received.emit(result)
	var snapshot_value: Variant = message.payload.get("snapshot", {})
	if snapshot_value is Dictionary and not snapshot_value.is_empty():
		_apply_snapshot_message(NetworkMessage.new(NetworkMessage.STATE_SNAPSHOT, {"snapshot": snapshot_value}, match_id))

func _broadcast_lobby() -> void:
	_broadcast(NetworkMessage.new(NetworkMessage.LOBBY_SNAPSHOT, {"lobby": lobby_state.to_dict()}, lobby_id))
	_emit_lobby_changed()

func _broadcast_game_state(message_type: String, action_id: String = "", result: CommandResult = null) -> void:
	for peer_id in transport.peer_ids() if transport != null else []:
		var player_id := str(_peer_to_player.get(peer_id, ""))
		_send_snapshot_to_peer(int(peer_id), player_id, NetworkMessage.COMMAND_RESULT if result != null else message_type, action_id, result)
	if result != null:
		var host_snapshot := snapshot_for_player(local_player_id)
		if host_snapshot != null:
			state_snapshot_changed.emit(host_snapshot)
		command_result_received.emit(result)

func _send_snapshot_to_peer(peer_id: int, player_id: String, message_type: String, action_id: String = "", result: CommandResult = null) -> void:
	if game_state == null:
		return
	var snapshot := snapshot_for_player(player_id)
	var payload: Dictionary = {"snapshot": snapshot.to_dict()}
	if result != null:
		payload["result"] = result.to_dict()
		payload["action_id"] = action_id
	_send_message(peer_id, NetworkMessage.new(message_type, payload, match_id))

func _broadcast(message: NetworkMessage) -> void:
	if transport == null:
		return
	for peer_id in transport.peer_ids():
		_send_message(int(peer_id), message)

func _send_message(peer_id: int, message: NetworkMessage) -> bool:
	if transport == null:
		return false
	return transport.send(peer_id, NetworkSerializer.encode_message(message))

func _emit_lobby_changed() -> void:
	if lobby_state != null:
		lobby_changed.emit(LobbySnapshot.from_lobby_state(lobby_state))

func _sync_session() -> void:
	if not is_inside_tree():
		return
	var session_node := get_node_or_null("/root/SessionManager")
	if session_node == null:
		return
	session_node.role = 1 if role == Role.HOST else 2 if role == Role.CLIENT else 0
	session_node.player_id = local_player_id
	session_node.lobby_id = lobby_id
	session_node.match_id = match_id

func _next_reconnect_delay() -> float:
	match _reconnect_attempts:
		0:
			return 0.5
		1:
			return 1.5
		2:
			return 3.0
		_:
			return 8.0

func _attempt_reconnect() -> void:
	var session := get_node_or_null("/root/SessionManager")
	if session == null or session.reconnect_token.is_empty() or local_player_id.is_empty() or match_id.is_empty():
		return
	_reconnect_request_pending = true
	set_connection_state("reconnecting")
	var backend := get_node_or_null("/root/BackendClient")
	if backend == null:
		_reconnect_request_pending = false
		set_connection_state("disconnected")
		return
	var result: Dictionary = backend.authorize_reconnect(match_id, local_player_id, session.reconnect_token)
	if not bool(result.get("ok", false)):
		_reconnect_request_pending = false
		_reconnect_attempts += 1
		set_connection_state("disconnected")
		network_error.emit(str(result.get("code", "RECONNECT_FAILED")))

func _new_id(prefix: String) -> String:
	return "%s-%d" % [prefix, Time.get_ticks_usec()]

static func _sorted_player_ids(values: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for player_id in values:
		result.append(str(player_id))
	result.sort()
	return result
