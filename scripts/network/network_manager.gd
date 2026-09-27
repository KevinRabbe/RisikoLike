extends Node

signal connection_changed(state: String)
signal network_error(code: String)

var connection_state := "offline"

func set_connection_state(next_state: String) -> void:
	if connection_state == next_state:
		return
	connection_state = next_state
	connection_changed.emit(connection_state)

func shutdown() -> void:
	multiplayer.multiplayer_peer = null
	set_connection_state("offline")
