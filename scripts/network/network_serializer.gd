class_name NetworkSerializer
extends RefCounted

static func encode_message(message: NetworkMessage) -> String:
	return JSON.stringify(message.to_dict())

static func decode_message(serialized: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(serialized)
	if raw == null:
		return {"ok": false, "code": "INVALID_MESSAGE"}
	var message := NetworkMessage.from_dict(raw)
	if message == null:
		var values: Dictionary = raw if raw is Dictionary else {}
		if str(values.get("message_type", "")).is_empty():
			return {"ok": false, "code": "INVALID_MESSAGE"}
		return {"ok": false, "code": "UNKNOWN_MESSAGE_TYPE"}
	if message.protocol_version != App.PROTOCOL_VERSION:
		return {"ok": false, "code": "PROTOCOL_MISMATCH", "message": message}
	return {"ok": true, "code": "OK", "message": message}

static func encode_command(command: CommandEnvelope) -> Dictionary:
	return command.to_dict()

static func decode_command(raw: Variant) -> CommandEnvelope:
	return CommandEnvelope.from_dict(raw)

static func encode_result(result: CommandResult) -> Dictionary:
	return result.to_dict()

static func decode_result(raw: Variant) -> CommandResult:
	return CommandResult.from_dict(raw)

static func canonical_json(value: Variant) -> String:
	return JSON.stringify(_canonicalize(value))

static func _canonicalize(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value:
			result[key] = _canonicalize(value[key])
		return result
	if value is Array:
		var result_array: Array = []
		for item in value:
			result_array.append(_canonicalize(item))
		return result_array
	if value is float:
		var numeric := float(value)
		if is_equal_approx(numeric, round(numeric)):
			return int(round(numeric))
	return value
