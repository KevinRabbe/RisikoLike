class_name LocalNetworkTransport
extends NetworkTransport

const DEFAULT_BIND_ADDRESS := "127.0.0.1"

var _server: TCPServer
var _peers: Dictionary = {}
var _buffers: Dictionary = {}
var _next_peer_id: int = 2
var _client_peer: StreamPeerTCP
var _client_connected_emitted := false
var _is_host := false

func start_host(port: int) -> bool:
	close()
	_server = TCPServer.new()
	var error := _server.listen(port, DEFAULT_BIND_ADDRESS)
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
	_peers[1] = _client_peer
	_buffers[1] = ""
	return true

func send(peer_id: int, serialized_message: String) -> bool:
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
		while _server.is_connection_available():
			var peer := _server.take_connection()
			if peer == null:
				break
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
			continue
		var buffer := str(_buffers.get(peer_id, "")) + (data_result[1] as PackedByteArray).get_string_from_utf8()
		var lines: PackedStringArray = buffer.split("\n")
		var remainder := ""
		if not lines.is_empty():
			remainder = lines[lines.size() - 1]
		_buffers[peer_id] = remainder
		for line_index in range(maxi(0, lines.size() - 1)):
			var line: String = lines[line_index]
			if not line.strip_edges().is_empty():
				packet_received.emit(int(peer_id), line.strip_edges())
	for peer_id in disconnected:
		_peers.erase(peer_id)
		_buffers.erase(peer_id)
		peer_disconnected.emit(peer_id)
