class_name BackendErrorMapper
extends RefCounted

static func to_game_code(raw_code: String) -> String:
	var code := raw_code
	if code.contains(":"):
		code = code.get_slice(":", 1)
	match code:
		"INVALID_INVITE_CODE", "LOBBY_NOT_FOUND", "LOBBY_EXPIRED", "LOBBY_CLOSED", "LOBBY_FULL", "MATCH_ALREADY_STARTED", "INVALID_TOKEN", "TOKEN_EXPIRED", "TOKEN_ALREADY_USED", "VERSION_MISMATCH", "PROTOCOL_MISMATCH", "RATE_LIMITED", "SIGNALING_UNAVAILABLE", "TURN_UNAVAILABLE":
			return code
		"BACKEND_UNAVAILABLE", "INVALID_BACKEND_RESPONSE", "INTERNAL_ERROR":
			return "SIGNALING_UNAVAILABLE"
		"UNAUTHENTICATED", "AUTH_ERROR":
			return "INVALID_TOKEN"
		_:
			return "INTERNAL_ERROR"
