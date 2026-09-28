class_name NetworkMessage
extends RefCounted

const JOIN_REQUEST := "JOIN_REQUEST"
const JOIN_ACCEPTED := "JOIN_ACCEPTED"
const JOIN_REJECTED := "JOIN_REJECTED"
const COMMAND_REQUEST := "COMMAND_REQUEST"
const COMMAND_RESULT := "COMMAND_RESULT"
const GAME_EVENT := "GAME_EVENT"
const SNAPSHOT_REQUEST := "SNAPSHOT_REQUEST"
const STATE_SNAPSHOT := "STATE_SNAPSHOT"
const LOBBY_SNAPSHOT := "LOBBY_SNAPSHOT"
const READY_CHANGED := "READY_CHANGED"
const LEAVE_LOBBY := "LEAVE_LOBBY"
const MATCH_STARTED := "MATCH_STARTED"
const PEER_LEFT := "PEER_LEFT"
const ERROR := "ERROR"
const RULESET_REQUEST := "RULESET_REQUEST"
const RECONNECT_CREDENTIAL := "RECONNECT_CREDENTIAL"
const SPECTATOR_REQUEST := "SPECTATOR_REQUEST"

static var _known_types: Dictionary = {
	JOIN_REQUEST: true,
	JOIN_ACCEPTED: true,
	JOIN_REJECTED: true,
	COMMAND_REQUEST: true,
	COMMAND_RESULT: true,
	GAME_EVENT: true,
	SNAPSHOT_REQUEST: true,
	STATE_SNAPSHOT: true,
	LOBBY_SNAPSHOT: true,
	READY_CHANGED: true,
	LEAVE_LOBBY: true,
	MATCH_STARTED: true,
	PEER_LEFT: true,
	ERROR: true,
	RULESET_REQUEST: true,
	RECONNECT_CREDENTIAL: true,
	SPECTATOR_REQUEST: true,
}

var message_type: String
var protocol_version: int
var match_id: String
var payload: Dictionary

func _init(p_message_type: String, p_payload: Dictionary = {}, p_match_id: String = "", p_protocol_version: int = 1) -> void:
	message_type = p_message_type
	payload = p_payload.duplicate(true)
	match_id = p_match_id
	protocol_version = p_protocol_version

func is_known_type() -> bool:
	return _known_types.has(message_type)

func to_dict() -> Dictionary:
	return {
		"protocol_version": protocol_version,
		"message_type": message_type,
		"match_id": match_id,
		"payload": payload.duplicate(true),
	}

static func from_dict(raw: Variant) -> NetworkMessage:
	if not raw is Dictionary:
		return null
	var values: Dictionary = raw
	var message_type_value := str(values.get("message_type", ""))
	if message_type_value.is_empty() or not _known_types.has(message_type_value):
		return null
	var payload_value: Variant = values.get("payload", {})
	if not payload_value is Dictionary:
		return null
	return NetworkMessage.new(
		message_type_value,
		payload_value,
		str(values.get("match_id", "")),
		int(values.get("protocol_version", 0))
	)
