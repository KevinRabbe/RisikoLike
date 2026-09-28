extends Node

signal backend_error(code: String)
signal lobby_created(data: Dictionary)
signal lobby_resolved(data: Dictionary)
signal heartbeat_succeeded(data: Dictionary)
signal lobby_closed(data: Dictionary)
signal lobby_started(data: Dictionary)
signal reconnect_credential_received(data: Dictionary)
signal reconnect_authorized(data: Dictionary)
signal turn_credentials_received(data: Dictionary)
signal backend_request_failed(operation: String, code: String)
signal signaling_connected
signal signaling_disconnected
signal signaling_message_received(message: Dictionary)

const API_VERSION := "v1"
const DEFAULT_BASE_URL := "http://127.0.0.1:8000"
var base_url := DEFAULT_BASE_URL
var host_session_token := ""
var join_token := ""
var current_lobby_id := ""
var current_signaling_url := ""
var current_ice_servers: Array = []
var _signaling_socket: WebSocketPeer
var _signaling_auth_message: Dictionary = {}
var _signaling_auth_sent := false

func _ready() -> void:
	set_process(true)
	var configured_url := OS.get_environment("RISIKOLIKE_BACKEND_URL").strip_edges()
	if not configured_url.is_empty():
		configure(configured_url)

func _process(_delta: float) -> void:
	if _signaling_socket == null:
		return
	_signaling_socket.poll()
	var state := _signaling_socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN and not _signaling_auth_sent:
		_signaling_socket.send_text(JSON.stringify(_signaling_auth_message))
		_signaling_auth_sent = true
		signaling_connected.emit()
	while _signaling_socket.get_available_packet_count() > 0:
		var packet := _signaling_socket.get_packet()
		var parsed: Variant = JSON.parse_string(packet.get_string_from_utf8())
		if parsed is Dictionary:
			signaling_message_received.emit(parsed)
	if state == WebSocketPeer.STATE_CLOSED:
		_signaling_socket = null
		_signaling_auth_sent = false
		signaling_disconnected.emit()

func configure(url: String) -> void:
	base_url = url.trim_suffix("/")

func is_configured() -> bool:
	return not base_url.is_empty()

func create_lobby(max_players: int) -> Dictionary:
	return _request("create_lobby", "/%s/lobbies" % API_VERSION, {
		"game_version": App.GAME_VERSION,
		"protocol_version": App.PROTOCOL_VERSION,
		"max_players": max_players,
	}, "")

func resolve_invite_code(invite_code: String) -> Dictionary:
	return _request("resolve_lobby", "/%s/lobbies/resolve" % API_VERSION, {
		"invite_code": invite_code,
		"game_version": App.GAME_VERSION,
		"protocol_version": App.PROTOCOL_VERSION,
	}, "")

func heartbeat() -> Dictionary:
	if current_lobby_id.is_empty() or host_session_token.is_empty():
		return {"ok": false, "code": "NOT_HOST_SESSION"}
	return _request("heartbeat", "/%s/lobbies/%s/heartbeat" % [API_VERSION, current_lobby_id], {}, host_session_token)

func close_lobby() -> Dictionary:
	if current_lobby_id.is_empty() or host_session_token.is_empty():
		return {"ok": false, "code": "NOT_HOST_SESSION"}
	return _request("close_lobby", "/%s/lobbies/%s/close" % [API_VERSION, current_lobby_id], {}, host_session_token)

func mark_lobby_started() -> Dictionary:
	if current_lobby_id.is_empty() or host_session_token.is_empty():
		return {"ok": false, "code": "NOT_HOST_SESSION"}
	return _request("started_lobby", "/%s/lobbies/%s/started" % [API_VERSION, current_lobby_id], {}, host_session_token)

func request_reconnect_credential(player_id: String) -> Dictionary:
	if current_lobby_id.is_empty() or host_session_token.is_empty() or player_id.is_empty():
		return {"ok": false, "code": "NOT_HOST_SESSION"}
	return _request(
		"reconnect_credential",
		"/%s/lobbies/%s/reconnect-credentials" % [API_VERSION, current_lobby_id],
		{"player_id": player_id},
		host_session_token,
	)

func authorize_reconnect(match_id: String, player_id: String, reconnect_token: String) -> Dictionary:
	if match_id.is_empty() or player_id.is_empty() or reconnect_token.is_empty():
		return {"ok": false, "code": "RECONNECT_TOKEN_INVALID"}
	return _request(
		"authorize_reconnect",
		"/%s/matches/reconnect" % API_VERSION,
		{
			"match_id": match_id,
			"player_id": player_id,
			"reconnect_token": reconnect_token,
			"protocol_version": App.PROTOCOL_VERSION,
			"game_version": App.GAME_VERSION,
		},
		"",
	)

func request_turn_credentials() -> Dictionary:
	if current_lobby_id.is_empty() or host_session_token.is_empty():
		return {"ok": false, "code": "NOT_HOST_SESSION"}
	return _request("turn_credentials", "/%s/lobbies/%s/turn-credentials" % [API_VERSION, current_lobby_id], {}, host_session_token)

func connect_signaling_as_host(lobby_id: String, token: String, signaling_url: String) -> Dictionary:
	return _connect_signaling(lobby_id, token, signaling_url, true)

func connect_signaling_as_joiner(lobby_id: String, token: String, signaling_url: String) -> Dictionary:
	return _connect_signaling(lobby_id, token, signaling_url, false)

func connect_signaling_as_reconnect(lobby_id: String, ticket: String, signaling_url: String, player_id: String, generation: int) -> Dictionary:
	return _connect_signaling(lobby_id, ticket, signaling_url, false, true, player_id, generation)

func send_signaling_message(message: Dictionary) -> bool:
	if _signaling_socket == null or _signaling_socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return false
	return _signaling_socket.send_text(JSON.stringify(message)) == OK

func disconnect_signaling() -> void:
	if _signaling_socket != null:
		_signaling_socket.close()
	_signaling_socket = null
	_signaling_auth_sent = false

func clear_session() -> void:
	disconnect_signaling()
	host_session_token = ""
	join_token = ""
	current_lobby_id = ""
	current_signaling_url = ""
	current_ice_servers.clear()

func _connect_signaling(
	lobby_id: String,
	token: String,
	signaling_url: String,
	is_host: bool,
	is_reconnect: bool = false,
	player_id: String = "",
	generation: int = 0,
) -> Dictionary:
	disconnect_signaling()
	_signaling_socket = WebSocketPeer.new()
	_signaling_auth_sent = false
	_signaling_auth_message = {
		"type": "AUTH_HOST" if is_host else "AUTH_RECONNECT" if is_reconnect else "AUTH_JOIN",
		"lobby_id": lobby_id,
		"host_session_token": token if is_host else null,
		"join_token": token if not is_host and not is_reconnect else null,
		"reconnect_ticket": token if is_reconnect else null,
		"player_id": player_id if is_reconnect else null,
		"connection_generation": generation if is_reconnect else null,
		"protocol_version": App.PROTOCOL_VERSION,
		"game_version": App.GAME_VERSION,
	}
	var error := _signaling_socket.connect_to_url(signaling_url)
	if error != OK:
		_signaling_socket = null
		return {"ok": false, "code": "SIGNALING_UNAVAILABLE"}
	return {"ok": true, "code": "CONNECTING"}

func _request(operation: String, path: String, payload: Dictionary, token: String) -> Dictionary:
	if not is_configured():
		return {"ok": false, "code": "BACKEND_NOT_CONFIGURED"}
	var request := HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_request_completed.bind(operation, request))
	var headers := PackedStringArray(["Content-Type: application/json"])
	if not token.is_empty():
		headers.append("Authorization: Bearer %s" % token)
	var error := request.request(base_url + path, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		request.queue_free()
		backend_error.emit("BACKEND_UNAVAILABLE")
		backend_request_failed.emit(operation, "BACKEND_UNAVAILABLE")
		return {"ok": false, "code": "BACKEND_UNAVAILABLE"}
	return {"ok": true, "code": "PENDING"}

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, operation: String, request: HTTPRequest) -> void:
	request.queue_free()
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300 or not parsed is Dictionary:
		var code := "BACKEND_UNAVAILABLE" if result != HTTPRequest.RESULT_SUCCESS else "INVALID_BACKEND_RESPONSE"
		if parsed is Dictionary:
			var error_value: Variant = parsed.get("error", {})
			if error_value is Dictionary:
				code = str(error_value.get("code", code))
		backend_error.emit(code)
		backend_request_failed.emit(operation, code)
		return
	var data: Dictionary = parsed
	if operation == "create_lobby":
		host_session_token = str(data.get("host_session_token", ""))
		current_lobby_id = str(data.get("lobby_id", ""))
		current_signaling_url = str(data.get("signaling_url", ""))
		var servers: Variant = data.get("ice_servers", [])
		current_ice_servers = servers.duplicate(true) if servers is Array else []
		lobby_created.emit(data)
	elif operation == "resolve_lobby":
		join_token = str(data.get("join_token", ""))
		current_lobby_id = str(data.get("lobby_id", ""))
		current_signaling_url = str(data.get("signaling_url", ""))
		var servers: Variant = data.get("ice_servers", [])
		current_ice_servers = servers.duplicate(true) if servers is Array else []
		lobby_resolved.emit(data)
	elif operation == "heartbeat":
		heartbeat_succeeded.emit(data)
	elif operation == "close_lobby":
		lobby_closed.emit(data)
	elif operation == "started_lobby":
		lobby_started.emit(data)
	elif operation == "reconnect_credential":
		reconnect_credential_received.emit(data)
	elif operation == "authorize_reconnect":
		current_lobby_id = str(data.get("match_id", current_lobby_id))
		current_signaling_url = str(data.get("signaling_url", current_signaling_url))
		var reconnect_servers: Variant = data.get("ice_servers", [])
		current_ice_servers = reconnect_servers.duplicate(true) if reconnect_servers is Array else []
		reconnect_authorized.emit(data)
	elif operation == "turn_credentials":
		var turn_servers: Variant = data.get("ice_servers", [])
		if turn_servers is Array:
			current_ice_servers = turn_servers.duplicate(true)
		turn_credentials_received.emit(data)
