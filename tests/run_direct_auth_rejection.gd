extends SceneTree

const DirectInviteCodec = preload("res://scripts/network/direct_invite.gd")

var role := ""
var port := 43650
var signal_dir := ""
var network_manager: Variant
var error_code := ""

func _init() -> void:
	role = _argument("role", "")
	port = int(_argument("port", "43650"))
	signal_dir = _argument("signal-dir", "")
	if role.is_empty() or signal_dir.is_empty():
		quit(2)
		return
	call_deferred("_run")

func _run() -> void:
	network_manager = get_root().get_node_or_null("NetworkManager")
	if network_manager == null:
		quit(2)
		return
	network_manager.network_error.connect(_on_network_error)
	if role == "host":
		await _host()
	else:
		await _client()

func _host() -> void:
	var created: Dictionary = network_manager.host_direct_lobby("Auth Host", 2, Ruleset.new(), port, "127.0.0.1")
	if not bool(created.get("ok", false)):
		_fail("host_start")
		return
	_write("invite", str(created.get("invite_code", "")))
	await _wait_until(func() -> bool: return FileAccess.file_exists(_path("client-result")), 8.0)
	network_manager.shutdown()
	quit(0)

func _client() -> void:
	var invite := await _wait_text("invite")
	var decoded := DirectInviteCodec.decode(invite)
	if not bool(decoded.get("ok", false)):
		_fail("invite_decode")
		return
	var values: Dictionary = decoded.get("invite", {})
	var wrong_invite := DirectInviteCodec.encode(str(values.get("host_address", "")), int(values.get("port", 0)), str(values.get("session_id", "")), "b".repeat(64))
	var joined: Dictionary = network_manager.join_direct_lobby("Wrong Secret", wrong_invite)
	if not bool(joined.get("ok", false)):
		_fail("connect_start")
		return
	if not await _wait_until(func() -> bool: return error_code == "JOIN_SECRET_INVALID", 6.0):
		_fail("wrong_secret_not_rejected")
		return
	_write("client-result", error_code)
	network_manager.shutdown()
	quit(0)

func _on_network_error(code: String) -> void:
	error_code = code

func _wait_until(predicate: Callable, timeout_seconds: float = 8.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if bool(predicate.call()):
			return true
		await create_timer(0.01).timeout
	return bool(predicate.call())

func _wait_text(name: String) -> String:
	if not await _wait_until(func() -> bool: return FileAccess.file_exists(_path(name)), 10.0):
		return ""
	var file := FileAccess.open(_path(name), FileAccess.READ)
	return file.get_as_text().strip_edges() if file != null else ""

func _fail(reason: String) -> void:
	_write("failure-%s" % role, reason)
	if network_manager != null:
		network_manager.shutdown()
	quit(1)

func _argument(name: String, default_value: String) -> String:
	var prefix := "--%s=" % name
	for argument in OS.get_cmdline_args():
		if str(argument).begins_with(prefix):
			return str(argument).trim_prefix(prefix)
	return default_value

func _path(name: String) -> String:
	return signal_dir.path_join(name + ".txt")

func _write(name: String, value: String) -> void:
	var file := FileAccess.open(_path(name), FileAccess.WRITE)
	if file != null:
		file.store_string(value)
