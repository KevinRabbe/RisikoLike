class_name CommandResult
extends RefCounted

var accepted: bool
var code: String
var state_revision: int
var data: Dictionary

func _init(p_accepted: bool, p_code: String, p_state_revision: int, p_data: Dictionary = {}) -> void:
	accepted = p_accepted
	code = p_code
	state_revision = p_state_revision
	data = p_data

func to_dict() -> Dictionary:
	return {"accepted": accepted, "code": code, "state_revision": state_revision, "data": data}
