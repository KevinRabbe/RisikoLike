class_name WebRTCNetworkTransport
extends NetworkTransport

## WebRTC transport for the existing reliable, ordered NetworkTransport boundary.
## Signaling is handled by the autoload BackendClient; gameplay never uses that socket.

const HOST_PEER_ID := 2
const CLIENT_PEER_ID := 1
const DATA_CHANNEL_OPEN := 1

var backend_client: Node
var lobby_id := ""
var session_token := ""
var signaling_url := ""
var ice_servers: Array = []
var relay_only := false

var _is_host := false
var _signaling_connected := false
var _remote_peer_id := 0
var _peer_connection: Variant
var _data_channel: Variant
var _ready_emitted := false

func configure(
	p_backend_client: Node,
	p_lobby_id: String,
	p_session_token: String,
	p_signaling_url: String,
	p_ice_servers: Array = [],
	p_relay_only: bool = false
) -> void:
	backend_client = p_backend_client
	lobby_id = p_lobby_id
	session_token = p_session_token
	signaling_url = p_signaling_url
	ice_servers = p_ice_servers.duplicate(true)
	relay_only = p_relay_only
	if backend_client != null:
		if not backend_client.signaling_message_received.is_connected(_on_signaling_message):
			backend_client.signaling_message_received.connect(_on_signaling_message)
		if not backend_client.signaling_connected.is_connected(_on_signaling_connected):
			backend_client.signaling_connected.connect(_on_signaling_connected)
		if not backend_client.signaling_disconnected.is_connected(_on_signaling_disconnected):
			backend_client.signaling_disconnected.connect(_on_signaling_disconnected)

func start_host(_port: int) -> bool:
	if not _can_start():
		transport_error.emit("BACKEND_NOT_CONFIGURED")
		return false
	close()
	_is_host = true
	var result: Dictionary = backend_client.connect_signaling_as_host(lobby_id, session_token, signaling_url)
	if not bool(result.get("ok", false)):
		transport_error.emit(str(result.get("code", "SIGNALING_UNAVAILABLE")))
		return false
	return true

func connect_to_host(_address: String, _port: int) -> bool:
	if not _can_start():
		transport_error.emit("BACKEND_NOT_CONFIGURED")
		return false
	close()
	_is_host = false
	var result: Dictionary = backend_client.connect_signaling_as_joiner(lobby_id, session_token, signaling_url)
	if not bool(result.get("ok", false)):
		transport_error.emit(str(result.get("code", "SIGNALING_UNAVAILABLE")))
		return false
	return true

func send(peer_id: int, serialized_message: String) -> bool:
	if _data_channel == null or not _ready_emitted:
		return false
	var expected_peer_id := HOST_PEER_ID if _is_host else CLIENT_PEER_ID
	if peer_id != expected_peer_id:
		return false
	return _data_channel.put_packet(serialized_message.to_utf8_buffer()) == OK

func poll() -> void:
	if _peer_connection != null:
		_peer_connection.poll()
		_check_data_channel()
	if _data_channel != null and _data_channel.get_ready_state() == DATA_CHANNEL_OPEN:
		while _data_channel.get_available_packet_count() > 0:
			var packet: PackedByteArray = _data_channel.get_packet()
			packet_received.emit(HOST_PEER_ID if _is_host else CLIENT_PEER_ID, packet.get_string_from_utf8())

func close() -> void:
	_ready_emitted = false
	_remote_peer_id = 0
	_signaling_connected = false
	_data_channel = null
	if _peer_connection != null:
		_peer_connection.close()
	_peer_connection = null
	if backend_client != null:
		backend_client.disconnect_signaling()

func peer_ids() -> Array[int]:
	if _ready_emitted:
		return [HOST_PEER_ID if _is_host else CLIENT_PEER_ID]
	return []

func _can_start() -> bool:
	return backend_client != null and not lobby_id.is_empty() and not session_token.is_empty() and not signaling_url.is_empty()

func _on_signaling_connected() -> void:
	_signaling_connected = true

func _on_signaling_disconnected() -> void:
	_signaling_connected = false
	if _ready_emitted:
		_ready_emitted = false
		peer_disconnected.emit(HOST_PEER_ID if _is_host else CLIENT_PEER_ID)

func _on_signaling_message(message: Dictionary) -> void:
	var message_type := str(message.get("type", ""))
	match message_type:
		"AUTH_OK":
			if not _is_host:
				_ensure_peer_connection()
				_create_client_data_channel()
				_peer_connection.create_offer()
		"PEER_JOINING":
			if _is_host:
				_ensure_peer_connection()
		"WEBRTC_OFFER":
			_ensure_peer_connection()
			var offer_payload: Dictionary = message.get("payload", {})
			if _peer_connection != null:
				_peer_connection.set_remote_description(str(offer_payload.get("type", "offer")), str(offer_payload.get("sdp", "")))
		"WEBRTC_ANSWER":
			var answer_payload: Dictionary = message.get("payload", {})
			if _peer_connection != null:
				_peer_connection.set_remote_description(str(answer_payload.get("type", "answer")), str(answer_payload.get("sdp", "")))
		"ICE_CANDIDATE":
			var candidate_payload: Dictionary = message.get("payload", {})
			if _peer_connection != null:
				_peer_connection.add_ice_candidate(str(candidate_payload.get("media", "0")), int(candidate_payload.get("index", 0)), str(candidate_payload.get("candidate", "")))
		"PEER_LEFT":
			if _ready_emitted:
				_ready_emitted = false
				peer_disconnected.emit(HOST_PEER_ID if _is_host else CLIENT_PEER_ID)
		"AUTH_ERROR", "ERROR":
			transport_error.emit(BackendErrorMapper.to_game_code(str((message.get("error", {}) as Dictionary).get("code", "SIGNALING_ERROR"))))

func _ensure_peer_connection() -> void:
	if _peer_connection != null:
		return
	if not ClassDB.class_exists("WebRTCPeerConnection"):
		transport_error.emit("WEBRTC_DEPENDENCY_MISSING")
		return
	_peer_connection = ClassDB.instantiate("WebRTCPeerConnection")
	if _peer_connection == null:
		transport_error.emit("WEBRTC_INIT_FAILED")
		return
	_peer_connection.session_description_created.connect(_on_session_description_created)
	_peer_connection.ice_candidate_created.connect(_on_ice_candidate_created)
	_peer_connection.data_channel_received.connect(_on_data_channel_received)
	var configuration := {"iceServers": ice_servers}
	if relay_only:
		configuration["iceTransportPolicy"] = "relay"
	var result: int = _peer_connection.initialize(configuration)
	if result != OK:
		_peer_connection = null
		transport_error.emit("WEBRTC_INIT_FAILED")

func _create_client_data_channel() -> void:
	if _data_channel != null or _peer_connection == null:
		return
	_data_channel = _peer_connection.create_data_channel("reliable", {"ordered": true})
	if _data_channel == null:
		transport_error.emit("DATA_CHANNEL_FAILED")

func _on_data_channel_received(channel: Variant) -> void:
	_data_channel = channel
	_check_data_channel()

func _check_data_channel() -> void:
	if _data_channel == null or _ready_emitted:
		return
	if _data_channel.get_ready_state() == DATA_CHANNEL_OPEN:
		_ready_emitted = true
		peer_connected.emit(HOST_PEER_ID if _is_host else CLIENT_PEER_ID)

func _on_session_description_created(description_type: String, sdp: String) -> void:
	_send_signaling("WEBRTC_OFFER" if description_type == "offer" else "WEBRTC_ANSWER", {
		"type": description_type,
		"sdp": sdp,
	})

func _on_ice_candidate_created(media: String, index: int, candidate: String) -> void:
	_send_signaling("ICE_CANDIDATE", {
		"media": media,
		"index": index,
		"candidate": candidate,
	})

func _send_signaling(message_type: String, payload: Dictionary) -> void:
	if backend_client == null or not _signaling_connected:
		return
	var message := {"type": message_type, "payload": payload}
	backend_client.send_signaling_message(message)
