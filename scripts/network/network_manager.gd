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

var _pending_join_name := ""
var _peer_to_player: Dictionary = {}
var _next_player_number := 1

func _ready() -> void:
	set_process(true)

func _process(_delta: float) -> void:
	if transport != null:
		transport.poll()

func set_connection_state(next_state: String) -> void:
	if connection_state == next_state:
		return
	connection_state = next_state
	connection_changed.emit(connection_state)

func host_local_lobby(player_name: String, max_players: int, p_ruleset: Ruleset = null, port: int = DEFAULT_LOCAL_PORT) -> Dictionary:
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
	return _join_lobby(player_name, address, port, LocalNetworkTransport.new())

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
		return {"ok": _send_message(1, NetworkMessage.new(NetworkMessage.COMMAND_REQUEST, {"command": command.to_dict()}, match_id)), "code": "QUEUED"}
	return {"ok": false, "code": "NOT_CONNECTED"}

func set_ready_state(ready: bool) -> Dictionary:
	if role != Role.CLIENT or local_player_id.is_empty():
		return {"ok": false, "code": "NOT_CLIENT"}
	return {"ok": _send_message(1, NetworkMessage.new(NetworkMessage.READY_CHANGED, {"player_id": local_player_id, "ready": ready}, lobby_id)), "code": "QUEUED"}

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
	set_connection_state("in_game")
	_sync_session()
	_broadcast_lobby()
	_broadcast_game_state(NetworkMessage.MATCH_STARTED)
	match_started.emit(game_state)
	print("[GAME] match started lobby=%s revision=%d" % [lobby_id, game_state.state_revision])
	return {"ok": true, "code": "OK", "match_id": match_id}

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
	return GameStateSnapshot.from_game_state(game_state, player_id if not player_id.is_empty() else local_player_id)

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
	_sync_session()
	connection_changed.emit(connection_state)

func _replace_transport(next_transport: NetworkTransport) -> bool:
	if next_transport == null:
		return false
	if transport != null:
		transport.close()
	transport = next_transport
	transport.packet_received.connect(_on_packet_received)
	transport.peer_connected.connect(_on_peer_connected)
	transport.peer_disconnected.connect(_on_peer_disconnected)
	transport.transport_error.connect(_on_transport_error)
	return true

func _on_peer_connected(peer_id: int) -> void:
	print("[NETWORK] peer connected peer=%d role=%s" % [peer_id, Role.keys()[role]])
	if role == Role.CLIENT and peer_id == 1:
		_send_message(1, NetworkMessage.new(NetworkMessage.JOIN_REQUEST, {
			"player_name": _pending_join_name,
			"protocol_version": App.PROTOCOL_VERSION,
			"game_version": App.GAME_VERSION,
		}, lobby_id))

func _on_peer_disconnected(peer_id: int) -> void:
	var player_id := str(_peer_to_player.get(peer_id, ""))
	if not player_id.is_empty() and lobby_state != null and role == Role.HOST:
		lobby_state.remove_player(player_id)
		_peer_to_player.erase(peer_id)
		_broadcast_lobby()
		peer_changed.emit(player_id, false)
	if role == Role.CLIENT and connection_state != "offline":
		set_connection_state("disconnected")
		network_error.emit("PEER_DISCONNECTED")

func _on_transport_error(code: String) -> void:
	network_error.emit(code)

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
	set_connection_state("in_game")
	_sync_session()
	state_snapshot_changed.emit(snapshot)
	if message.message_type == NetworkMessage.MATCH_STARTED:
		match_started.emit(game_state)

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
	var snapshot := GameStateSnapshot.from_game_state(game_state, player_id)
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

func _new_id(prefix: String) -> String:
	return "%s-%d" % [prefix, Time.get_ticks_usec()]

static func _sorted_player_ids(values: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for player_id in values:
		result.append(str(player_id))
	result.sort()
	return result
