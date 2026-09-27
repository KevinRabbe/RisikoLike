class_name CommandResult
extends RefCounted

var accepted: bool
var code: String
var state_revision: int
var data: Dictionary
var action_id: String = ""

func _init(p_accepted: bool, p_code: String, p_state_revision: int, p_data: Dictionary = {}, p_action_id: String = "") -> void:
	accepted = p_accepted
	code = p_code
	state_revision = p_state_revision
	data = p_data
	action_id = p_action_id

func to_dict() -> Dictionary:
	return {
		"action_id": action_id,
		"accepted": accepted,
		"code": code,
		"result_code": code,
		"state_revision": state_revision,
		"resulting_state_revision": state_revision,
		"data": data.duplicate(true),
	}

static func from_dict(raw: Variant) -> CommandResult:
	if not raw is Dictionary:
		return null
	var values: Dictionary = raw
	var data_value: Variant = values.get("data", {})
	if not data_value is Dictionary:
		return null
	return CommandResult.new(
		bool(values.get("accepted", false)),
		str(values.get("code", values.get("result_code", "INVALID_RESULT"))),
		int(values.get("state_revision", values.get("resulting_state_revision", -1))),
		data_value,
		str(values.get("action_id", ""))
	)
