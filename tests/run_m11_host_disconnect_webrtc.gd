extends SceneTree

## M11 host-loss acceptance: the client must enter TERMINATED/HOST_UNAVAILABLE,
## and must not reconnect or submit further gameplay commands.

const WAIT_LIMIT := 5000
var role := ""
var signal_dir := ""
var backend_url := "http://127.0.0.1:8000"
var network_manager: Variant
var backend_client: Variant

func _init() -> void:
	role = _argument("role", "")
	signal_dir = _argument("signal-dir", "")
	backend_url = _argument("backend-url", backend_url)
	if role.is_empty() or signal_dir.is_empty():
		quit(2)
		return
	call_deferred("_run")

func _run() -> void:
	network_manager = get_root().get_node_or_null("NetworkManager")
	backend_client = get_root().get_node_or_null("BackendClient")
	if network_manager == null or backend_client == null:
		_fail("autoload_missing")
		return
	backend_client.configure(backend_url)
	if role == "host":
		await _host()
	else:
		await _client()

func _host() -> void:
	var created: Dictionary = network_manager.host_online_lobby("M11 Host Loss", 2, Ruleset.new())
	if not bool(created.get("ok", false)):
		_fail("host_create")
		return
	if not await _wait_until(func() -> bool: return network_manager.lobby_state != null and not network_manager.lobby_state.invite_code.is_empty()):
		_fail("invite_timeout")
		return
	_write("invite", network_manager.lobby_state.invite_code)
	if not await _wait_until(func() -> bool: return network_manager.lobby_state.get_player("P2") != null and network_manager.lobby_state.get_player("P2").is_ready):
		_fail("ready_timeout")
		return
	var started: Dictionary = network_manager.start_match(401)
	if not bool(started.get("ok", false)):
		_fail("start_failed")
		return
	_write("host-started", "ok")
	if not await _wait_for_file("client-snapshot-ready"):
		_fail("client_snapshot_ready_timeout")
		return
	network_manager.shutdown()
	quit(0)

func _client() -> void:
	var invite := ""
	for _index in range(WAIT_LIMIT):
		invite = _read("invite")
		if not invite.is_empty():
			break
		await create_timer(0.01).timeout
	if invite.is_empty():
		_fail("invite_timeout")
		return
	var joined: Dictionary = network_manager.join_online_lobby("M11 Host Loss Client", invite)
	if not bool(joined.get("ok", false)):
		_fail("join_failed")
		return
	if not await _wait_until(func() -> bool: return not network_manager.local_player_id.is_empty()):
		_fail("join_timeout")
		return
	var ready: Dictionary = network_manager.set_ready_state(true)
	if not bool(ready.get("ok", false)):
		_fail("ready_failed")
		return
	if not await _wait_for_file("host-started"):
		_fail("start_signal_timeout")
		return
	if not await _wait_until(func() -> bool: return network_manager.game_state != null):
		_fail("snapshot_timeout")
		return
	_write("client-snapshot-ready", "ok")
	if not await _wait_until(func() -> bool: return network_manager.game_state.status == GameState.MatchStatus.TERMINATED and network_manager.connection_state == "failed"):
		_fail("host_disconnect_not_terminated")
		return
	var rejected: Dictionary = network_manager.submit_command(CommandEnvelope.new("m11-after-host-loss", "P2", network_manager.game_state.state_revision, "end_phase"))
	if bool(rejected.get("ok", false)) or str(rejected.get("code", "")) != "MATCH_NOT_PLAYING":
		_fail("command_not_rejected_after_host_loss")
		return
	_write("client-result", "%d|%s|%s" % [network_manager.game_state.status, network_manager.game_state.last_action_id, str(rejected.get("code", ""))])
	quit(0)

func _wait_until(predicate: Callable) -> bool:
	for _index in range(WAIT_LIMIT):
		if bool(predicate.call()):
			return true
		await create_timer(0.01).timeout
	return false

func _wait_for_file(name: String) -> bool:
	return await _wait_until(func() -> bool: return FileAccess.file_exists(_path(name)))

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

func _read(name: String) -> String:
	var path := _path(name)
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text().strip_edges() if file != null else ""
