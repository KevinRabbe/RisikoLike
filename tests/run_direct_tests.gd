extends SceneTree

const DirectInviteCodec = preload("res://scripts/network/direct_invite.gd")
const DirectTransport = preload("res://scripts/network/direct_network_transport.gd")

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var backend := get_root().get_node_or_null("BackendClient")
	_expect(backend != null and not backend.is_configured(), "central backend is disabled by default")
	var invite := DirectInviteCodec.encode("127.0.0.1", 43620, "session-test-1", "a".repeat(64))
	_expect(invite.begins_with("AF1."), "invite uses AF1 prefix")
	var decoded := DirectInviteCodec.decode(invite)
	_expect(bool(decoded.get("ok", false)), "invite decodes")
	var values: Dictionary = decoded.get("invite", {})
	_expect_equal(str(values.get("host_address", "")), "127.0.0.1", "address round trips")
	_expect_equal(int(values.get("port", 0)), 43620, "port round trips")
	_expect_equal(str(values.get("session_id", "")), "session-test-1", "session id round trips")
	_expect_equal(str(values.get("join_secret", "")), "a".repeat(64), "join secret round trips")
	_expect_equal(str(DirectInviteCodec.decode("").get("code", "")), "INVITE_INVALID", "empty invite rejected")
	_expect_equal(str(DirectInviteCodec.decode("ABC-123").get("code", "")), "INVITE_FORMAT_INVALID", "wrong prefix rejected")
	var corrupt := invite.substr(0, invite.length() - 1) + ("0" if invite.ends_with("1") else "1")
	_expect_equal(str(DirectInviteCodec.decode(corrupt).get("code", "")), "INVITE_CHECKSUM_INVALID", "checksum corruption rejected")
	var bad_version := invite.replace("AF1.", "AF2.")
	_expect_equal(str(DirectInviteCodec.decode(bad_version).get("code", "")), "INVITE_FORMAT_INVALID", "unsupported prefix rejected")
	var malformed_payload := "AF1.e30.%s" % DirectInviteCodec._checksum("e30")
	_expect_equal(str(DirectInviteCodec.decode(malformed_payload).get("code", "")), "INVITE_VERSION_UNSUPPORTED", "malformed payload rejected")
	var host := DirectTransport.new("127.0.0.1")
	var port_error := not host.start_host(43621)
	_expect(not port_error, "direct transport binds configured port")
	var occupied := DirectTransport.new("127.0.0.1")
	_expect(not occupied.start_host(43621), "port in use is rejected")
	occupied.close()
	host.close()
	var recycled := DirectTransport.new("127.0.0.1")
	_expect(recycled.start_host(43621), "closed lobby releases its port")
	recycled.close()
	print("DIRECT_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _expect(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	_expect(actual == expected, "%s (got %s, expected %s)" % [label, str(actual), str(expected)])
