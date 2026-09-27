class_name NetworkTransport
extends RefCounted

signal packet_received(peer_id: int, serialized_message: String)
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal transport_error(code: String)

func start_host(_port: int) -> bool:
	return false

func connect_to_host(_address: String, _port: int) -> bool:
	return false

func send(_peer_id: int, _serialized_message: String) -> bool:
	return false

func poll() -> void:
	pass

func close() -> void:
	pass

func peer_ids() -> Array[int]:
	return []
