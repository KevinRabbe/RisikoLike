extends SceneTree

var role := ""
var port := 43640
var signal_dir := ""
var network_manager: Variant

func _init() -> void:
	role = _argument("role", "")
	port = int(_argument("port", "43640"))
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
		await _client("Direct Client 3" if role == "client3" else "Direct Client 2")

func _host() -> void:
	var created: Dictionary = network_manager.host_direct_lobby("Direct Host 3P", 3, Ruleset.new(), port, "127.0.0.1")
	if not bool(created.get("ok", false)):
		_fail("host_start")
		return
	_write("invite", str(created.get("invite_code", "")))
	if not await _wait_until(func() -> bool:
		if network_manager.lobby_state.players.size() != 3:
			return false
		return network_manager.lobby_state.get_player("P2").is_ready and network_manager.lobby_state.get_player("P3").is_ready
	, 30.0):
		_fail("three_players_or_ready_timeout")
		return
	var started: Dictionary = network_manager.start_match(7)
	if not bool(started.get("ok", false)):
		_fail("start_match")
		return
	_write("host-result", "%d|%s|%d" % [network_manager.game_state.state_revision, network_manager.state_fingerprint("P2"), network_manager.game_state.players.size()])
	await _wait_until(func() -> bool: return FileAccess.file_exists(_path("client2-result")) and FileAccess.file_exists(_path("client3-result")), 8.0)
	network_manager.shutdown()
	quit(0)

func _client(player_name: String) -> void:
	var invite := await _wait_text("invite")
	if invite.is_empty():
		_fail("invite_timeout")
		return
	var joined: Dictionary = network_manager.join_direct_lobby(player_name, invite)
	if not bool(joined.get("ok", false)):
		_fail("join_failed")
		return
	if not await _wait_until(func() -> bool: return not network_manager.local_player_id.is_empty() and network_manager.lobby_state != null and network_manager.lobby_state.players.size() == 3 and network_manager.lobby_state.get_player(network_manager.local_player_id) != null):
		_fail("join_timeout")
		return
	await create_timer(0.5).timeout
	for _attempt in range(8):
		var ready_result: Dictionary = network_manager.set_ready_state(true)
		if not bool(ready_result.get("ok", false)):
			_fail("ready_failed")
			return
		await create_timer(0.25).timeout
	if not await _wait_until(func() -> bool: return network_manager.game_state != null and network_manager.game_state.players.size() == 3 and network_manager.connection_state == "in_game"):
		_fail("match_timeout")
		return
	_write(role + "-result", "%d|%s|%d" % [network_manager.game_state.state_revision, network_manager.state_fingerprint(network_manager.local_player_id), network_manager.game_state.players.size()])
	network_manager.shutdown()
	quit(0)

func _wait_until(predicate: Callable, timeout_seconds: float = 15.0) -> bool:
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
