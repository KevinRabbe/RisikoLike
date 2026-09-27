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
