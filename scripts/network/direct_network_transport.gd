class_name DirectNetworkTransport
extends NetworkTransport

## Reliable, ordered TCP transport used by the V1 player-hosted flow.
## This is deliberately a small framing layer around StreamPeerTCP. The
## gameplay protocol remains the existing NetworkSerializer boundary.

const DEFAULT_BIND_ADDRESS := "0.0.0.0"
const MAX_PACKET_BYTES := 256 * 1024
const CONNECT_TIMEOUT_MSEC := 8000

var bind_address := DEFAULT_BIND_ADDRESS
var _server: TCPServer
var _peers: Dictionary = {}
var _buffers: Dictionary = {}
var _next_peer_id := 2
var _client_peer: StreamPeerTCP
var _client_connected_emitted := false
var _is_host := false
var _connect_started_msec := 0

func _init(p_bind_address: String = DEFAULT_BIND_ADDRESS) -> void:
	bind_address = p_bind_address

func start_host(port: int) -> bool:
	close()
	_server = TCPServer.new()
	var error := _server.listen(port, bind_address)
	if error != OK:
		transport_error.emit("PORT_UNAVAILABLE")
		return false
	_is_host = true
	_next_peer_id = 2
	return true

func connect_to_host(address: String, port: int) -> bool:
	close()
	_client_peer = StreamPeerTCP.new()
	var error := _client_peer.connect_to_host(address, port)
	if error != OK:
		transport_error.emit("CONNECT_FAILED")
		return false
	_is_host = false
	_client_connected_emitted = false
	_connect_started_msec = Time.get_ticks_msec()
	_peers[1] = _client_peer
	_buffers[1] = ""
	return true

func send(peer_id: int, serialized_message: String) -> bool:
	if serialized_message.to_utf8_buffer().size() > MAX_PACKET_BYTES:
		transport_error.emit("MESSAGE_TOO_LARGE")
		return false
	if not _peers.has(peer_id):
		return false
	var peer: StreamPeerTCP = _peers[peer_id]
	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return false
	var error := peer.put_data((serialized_message + "\n").to_utf8_buffer())
	if error != OK:
		transport_error.emit("SEND_FAILED")
		return false
	return true

func poll() -> void:
	if _is_host and _server != null:
		# Accept one connection per frame so an incoming connection cannot starve
		# polling of already established peers during a burst of joins.
		if _server.is_connection_available():
			var peer := _server.take_connection()
			if peer != null:
				var peer_id := _next_peer_id
				_next_peer_id += 1
				_peers[peer_id] = peer
				_buffers[peer_id] = ""
				peer_connected.emit(peer_id)
	if not _is_host and _client_peer != null:
		_client_peer.poll()
		if _client_peer.get_status() == StreamPeerTCP.STATUS_CONNECTED and not _client_connected_emitted:
			_client_connected_emitted = true
			peer_connected.emit(1)
		elif _client_peer.get_status() == StreamPeerTCP.STATUS_ERROR:
			transport_error.emit("CONNECT_FAILED")
			close()
		elif _client_peer.get_status() != StreamPeerTCP.STATUS_CONNECTED and _connect_started_msec > 0 and Time.get_ticks_msec() - _connect_started_msec > CONNECT_TIMEOUT_MSEC:
			transport_error.emit("CONNECT_TIMEOUT")
			close()
	_poll_peers()

func close() -> void:
	for peer_id in _peers.keys():
		var peer: StreamPeerTCP = _peers[peer_id]
		peer.disconnect_from_host()
	_peers.clear()
	_buffers.clear()
	if _server != null:
		_server.stop()
	_server = null
	_client_peer = null
	_client_connected_emitted = false
	_connect_started_msec = 0
	_is_host = false

func peer_ids() -> Array[int]:
	var result: Array[int] = []
	for peer_id in _peers:
		result.append(int(peer_id))
	return result

func _poll_peers() -> void:
	var disconnected: Array[int] = []
	for peer_id in _peers.keys():
		var peer: StreamPeerTCP = _peers[peer_id]
		peer.poll()
		var status := peer.get_status()
		if status == StreamPeerTCP.STATUS_ERROR or status == StreamPeerTCP.STATUS_NONE:
			disconnected.append(int(peer_id))
			continue
		if status != StreamPeerTCP.STATUS_CONNECTED:
			continue
		var available := peer.get_available_bytes()
		if available <= 0:
			continue
		var data_result: Array = peer.get_data(available)
		if int(data_result[0]) != OK:
			transport_error.emit("RECEIVE_FAILED")
			disconnected.append(int(peer_id))
			continue
		var incoming := (data_result[1] as PackedByteArray).get_string_from_utf8()
		var buffer := str(_buffers.get(peer_id, "")) + incoming
		if buffer.to_utf8_buffer().size() > MAX_PACKET_BYTES:
			transport_error.emit("MESSAGE_TOO_LARGE")
			disconnected.append(int(peer_id))
			continue
		var lines: PackedStringArray = buffer.split("\n")
		var remainder := ""
		if not lines.is_empty():
			remainder = lines[lines.size() - 1]
		_buffers[peer_id] = remainder
		for line_index in range(maxi(0, lines.size() - 1)):
			var line: String = lines[line_index]
			if line.to_utf8_buffer().size() > MAX_PACKET_BYTES:
				disconnected.append(int(peer_id))
				break
			if not line.strip_edges().is_empty():
				packet_received.emit(int(peer_id), line.strip_edges())
	for peer_id in disconnected:
		if not _peers.has(peer_id):
			continue
		_peers.erase(peer_id)
		_buffers.erase(peer_id)
		peer_disconnected.emit(peer_id)
