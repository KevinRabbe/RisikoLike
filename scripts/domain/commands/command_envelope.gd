class_name CommandEnvelope
extends RefCounted

var action_id: String
var player_id: String
var expected_state_revision: int
var command_type: String
var payload: Dictionary

func _init(p_action_id: String, p_player_id: String, p_expected_state_revision: int, p_command_type: String, p_payload: Dictionary = {}) -> void:
	action_id = p_action_id
	player_id = p_player_id
	expected_state_revision = p_expected_state_revision
	command_type = p_command_type
	payload = p_payload.duplicate(true)

static func create(player_id: String, state_revision: int, command_type: String, payload: Dictionary = {}) -> CommandEnvelope:
	return CommandEnvelope.new("action_%d_%s" % [Time.get_ticks_usec(), command_type], player_id, state_revision, command_type, payload)

func to_dict() -> Dictionary:
	return {
		"action_id": action_id,
		"player_id": player_id,
		"expected_state_revision": expected_state_revision,
		"command_type": command_type,
		"payload": payload.duplicate(true),
	}

static func from_dict(raw: Variant) -> CommandEnvelope:
	if not raw is Dictionary:
		return null
	var values: Dictionary = raw
	var payload_value: Variant = values.get("payload", {})
	if not payload_value is Dictionary:
		return null
	var action_id_value := str(values.get("action_id", ""))
	var player_id_value := str(values.get("player_id", ""))
	var command_type_value := str(values.get("command_type", ""))
	if action_id_value.is_empty() or player_id_value.is_empty() or command_type_value.is_empty():
		return null
	return CommandEnvelope.new(
		action_id_value,
		player_id_value,
		int(values.get("expected_state_revision", -1)),
		command_type_value,
		payload_value
	)
