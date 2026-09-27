class_name InProcessTransport
extends NetworkTransport

var remote: InProcessTransport
var local_peer_id: int = 1
var remote_peer_id: int = 1
var _is_host := false

static func create_pair() -> Array[InProcessTransport]:
	var host := InProcessTransport.new()
	var client := InProcessTransport.new()
	host.remote = client
	client.remote = host
	host.local_peer_id = 1
	host.remote_peer_id = 2
	client.local_peer_id = 2
	client.remote_peer_id = 1
	return [host, client]

func start_host(_port: int) -> bool:
	_is_host = true
	return true

func connect_to_host(_address: String, _port: int) -> bool:
	_is_host = false
	if remote == null:
		transport_error.emit("CONNECT_FAILED")
		return false
	remote.peer_connected.emit(local_peer_id)
	peer_connected.emit(remote_peer_id)
	return true

func send(peer_id: int, serialized_message: String) -> bool:
	if remote == null or peer_id != remote_peer_id:
		return false
	remote.packet_received.emit(local_peer_id, serialized_message)
	return true

func close() -> void:
	if remote != null:
		remote.peer_disconnected.emit(local_peer_id)
	remote = null

func peer_ids() -> Array[int]:
	if remote == null:
		return []
	return [remote_peer_id]
