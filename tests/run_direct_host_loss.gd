extends SceneTree

var role := ""
var port := 43630
var signal_dir := ""
var network_manager: Variant

func _init() -> void:
	role = _argument("role", "")
	port = int(_argument("port", "43630"))
	signal_dir = _argument("signal-dir", "")
	if role.is_empty() or signal_dir.is_empty():
		quit(2)
		return
	call_deferred("_run")

func _run() -> void:
	network_manager = get_root().get_node_or_null("NetworkManager")
	if network_manager == null:
		_fail("network_manager_missing")
		return
	if role == "host":
		await _host()
	else:
		await _client()

func _host() -> void:
	var result: Dictionary = network_manager.host_direct_lobby("Host Loss Host", 2, Ruleset.new(), port, "127.0.0.1")
	if not bool(result.get("ok", false)):
		_fail("host_start")
		return
	_write("invite", str(result.get("invite_code", "")))
	if not await _wait_until(func() -> bool: return network_manager.lobby_state.players.size() == 2 and network_manager.lobby_state.get_player("P2").is_ready):
		_fail("host_ready_timeout")
		return
	var start: Dictionary = network_manager.start_match(_seed_for_p2())
	if not bool(start.get("ok", false)):
		_fail("host_start_match")
		return
	_write("host-running", "1")
	# Give the just-broadcast MATCH_STARTED frame time to leave the socket before
	# simulating the hard host loss. The process still exits without shutdown.
	await create_timer(0.5).timeout
	# Deliberately terminate the process without a graceful network shutdown.
	quit(0)

func _client() -> void:
	var invite := await _wait_text("invite")
	if invite.is_empty():
		_fail("invite_timeout")
		return
	var join: Dictionary = network_manager.join_direct_lobby("Host Loss Client", invite)
	if not bool(join.get("ok", false)):
		_fail("join_failed")
		return
	if not await _wait_until(func() -> bool: return network_manager.lobby_state != null and not network_manager.local_player_id.is_empty()):
		_fail("join_timeout")
		return
	if not bool(network_manager.set_ready_state(true).get("ok", false)):
		_fail("ready_failed")
		return
	if not await _wait_until(func() -> bool: return network_manager.game_state != null and network_manager.connection_state == "in_game"):
		_fail("match_timeout")
		return
	if not await _wait_until(func() -> bool: return FileAccess.file_exists(_path("host-running")), 5.0):
		_fail("host_running_signal_timeout")
		return
	if not await _wait_until(func() -> bool: return network_manager.game_state.status == GameState.MatchStatus.TERMINATED and network_manager.connection_state == "failed", 8.0):
		_fail("host_loss_not_terminated")
		return
	_write("client-result", "%s|%s" % [network_manager.connection_state, network_manager.game_state.last_result.get("code", "")])
	network_manager.shutdown()
	quit(0)

func _seed_for_p2() -> int:
	for candidate in range(1, 100):
		var preview := GameState.create_local_for_player_ids(["P1", "P2"], candidate, Ruleset.new())
		if preview.turn_state.active_player_id == "P2":
			return candidate
	return 1

func _wait_until(predicate: Callable, timeout_seconds: float = 12.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if bool(predicate.call()):
			return true
		await create_timer(0.01).timeout
	return bool(predicate.call())

func _wait_text(name: String) -> String:
	if not await _wait_until(func() -> bool: return FileAccess.file_exists(_path(name)), 15.0):
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
