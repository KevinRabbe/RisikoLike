extends SceneTree

var backend: Variant
var event_type := ""
var event_data: Dictionary = {}
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	backend = get_root().get_node_or_null("BackendClient")
	if backend == null:
		_fail("backend_autoload_missing")
		_finish()
		return
	backend.configure(_argument("backend-url", "http://127.0.0.1:8000"))
	backend.lobby_created.connect(_on_lobby_created)
	backend.lobby_resolved.connect(_on_lobby_resolved)
	backend.heartbeat_succeeded.connect(_on_heartbeat)
	backend.lobby_closed.connect(_on_lobby_closed)
	backend.backend_request_failed.connect(_on_request_failed)
	backend.create_lobby(2)
	await _wait_for("created")
	var created := event_data.duplicate(true)
	_expect(not str(created.get("host_session_token", "")).is_empty(), "create returns host token")
	_expect(str(created.get("signaling_url", "")).contains("/v1/signaling"), "create returns signaling URL")
	backend.resolve_invite_code(str(created.get("invite_code", "")))
	await _wait_for("resolved")
	_expect(str(event_data.get("join_token", "")).length() > 20, "resolve returns short-lived join token")
	backend.heartbeat()
	await _wait_for("heartbeat")
	_expect(not str(event_data.get("expires_at", "")).is_empty(), "heartbeat extends expiry")
	backend.close_lobby()
	await _wait_for("closed")
	_expect_equal(str(event_data.get("status", "")), "CLOSED", "close invalidates lobby")
	backend.resolve_invite_code(str(created.get("invite_code", "")))
	await _wait_for("failed")
	_expect_equal(str(event_data.get("code", "")), "LOBBY_CLOSED", "closed lobby returns mapped error")
	backend.clear_session()
	print("BACKEND_CLIENT_TESTS: %d passed, %d failed" % [passed, failed])
	_finish()

func _wait_for(expected: String) -> void:
	event_type = ""
	event_data = {}
	for _index in range(1000):
		if event_type == expected:
			return
		await create_timer(0.01).timeout
	_fail("event_timeout:" + expected)

func _on_lobby_created(data: Dictionary) -> void:
	event_type = "created"
	event_data = data

func _on_lobby_resolved(data: Dictionary) -> void:
	event_type = "resolved"
	event_data = data

func _on_heartbeat(data: Dictionary) -> void:
	event_type = "heartbeat"
	event_data = data

func _on_lobby_closed(data: Dictionary) -> void:
	event_type = "closed"
	event_data = data

func _on_request_failed(_operation: String, code: String) -> void:
	event_type = "failed"
	event_data = {"code": code}

func _expect(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		_fail(label)

func _expect_equal(actual: String, expected: String, label: String) -> void:
	_expect(actual == expected, "%s (got %s, expected %s)" % [label, actual, expected])

func _fail(label: String) -> void:
	failed += 1
	push_error("FAIL: " + label)

func _finish() -> void:
	quit(1 if failed > 0 else 0)

func _argument(name: String, default_value: String) -> String:
	var prefix := "--%s=" % name
	for argument in OS.get_cmdline_args():
		if str(argument).begins_with(prefix):
			return str(argument).trim_prefix(prefix)
	return default_value
