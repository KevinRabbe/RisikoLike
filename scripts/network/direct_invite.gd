class_name DirectInvite
extends RefCounted

## Versioned, self-contained invite for the V1 player-hosted TCP flow.
## The join secret is intentionally carried inside the invite: it is the
## capability that authorizes the initial join. Reconnect credentials are
## issued separately by the host after a player has joined.

const PREFIX := "AF1"
const FORMAT_VERSION := 1
const CHECKSUM_LENGTH := 8
const MAX_LENGTH := 512

static func encode(host_address: String, port: int, session_id: String, join_secret: String) -> String:
	var payload := {
		"v": FORMAT_VERSION,
		"g": App.GAME_VERSION,
		"p": App.PROTOCOL_VERSION,
		"a": host_address.strip_edges(),
		"o": port,
		"s": session_id,
		"j": join_secret,
	}
	var raw := JSON.stringify(payload).to_utf8_buffer()
	var encoded := _base64url_encode(raw)
	return "%s.%s.%s" % [PREFIX, encoded, _checksum(encoded)]

static func decode(code: String) -> Dictionary:
	var normalized := code.strip_edges().replace(" ", "")
	if normalized.length() == 0 or normalized.length() > MAX_LENGTH:
		return {"ok": false, "code": "INVITE_INVALID"}
	var parts := normalized.split(".")
	if parts.size() != 3 or parts[0] != PREFIX:
		return {"ok": false, "code": "INVITE_FORMAT_INVALID"}
	var encoded := str(parts[1])
	var checksum := str(parts[2]).to_upper()
	if checksum.length() != CHECKSUM_LENGTH or checksum != _checksum(encoded):
		return {"ok": false, "code": "INVITE_CHECKSUM_INVALID"}
	var raw := _base64url_decode(encoded)
	if raw.is_empty():
		return {"ok": false, "code": "INVITE_PAYLOAD_INVALID"}
	var parsed: Variant = JSON.parse_string(raw.get_string_from_utf8())
	if not parsed is Dictionary:
		return {"ok": false, "code": "INVITE_PAYLOAD_INVALID"}
	var payload: Dictionary = parsed
	if int(payload.get("v", -1)) != FORMAT_VERSION:
		return {"ok": false, "code": "INVITE_VERSION_UNSUPPORTED"}
	if int(payload.get("p", -1)) != App.PROTOCOL_VERSION:
		return {"ok": false, "code": "INVITE_PROTOCOL_MISMATCH"}
	if str(payload.get("g", "")) != App.GAME_VERSION:
		return {"ok": false, "code": "INVITE_GAME_VERSION_MISMATCH"}
	var address := str(payload.get("a", "")).strip_edges()
	var port := int(payload.get("o", 0))
	var session_id := str(payload.get("s", ""))
	var secret := str(payload.get("j", ""))
	if address.is_empty() or session_id.is_empty() or secret.length() < 32 or port < 1 or port > 65535:
		return {"ok": false, "code": "INVITE_FIELDS_INVALID"}
	return {"ok": true, "code": "OK", "invite": {
		"format_version": FORMAT_VERSION,
		"game_version": str(payload.get("g", "")),
		"protocol_version": int(payload.get("p", 0)),
		"host_address": address,
		"port": port,
		"session_id": session_id,
		"join_secret": secret,
	}}

static func normalize(value: String) -> String:
	return value.strip_edges().replace(" ", "")

static func redacted(code: String) -> String:
	var normalized := code.strip_edges()
	return normalized.substr(0, mini(7, normalized.length())) + "…" if not normalized.is_empty() else "<empty>"

static func local_host_address() -> String:
	var addresses := IP.get_local_addresses()
	for address in addresses:
		var candidate := str(address)
		if candidate.contains(":"):
			continue
		if candidate.begins_with("127.") or candidate == "0.0.0.0":
			continue
		return candidate
	return "127.0.0.1"

static func _checksum(encoded: String) -> String:
	return encoded.sha256_text().substr(0, CHECKSUM_LENGTH).to_upper()

static func _base64url_encode(raw: PackedByteArray) -> String:
	return Marshalls.raw_to_base64(raw).replace("+", "-").replace("/", "_").trim_suffix("=").trim_suffix("=")

static func _base64url_decode(value: String) -> PackedByteArray:
	var restored := value.replace("-", "+").replace("_", "/")
	while restored.length() % 4 != 0:
		restored += "="
	return Marshalls.base64_to_raw(restored)
