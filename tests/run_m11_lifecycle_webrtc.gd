extends SceneTree

## M11 acceptance harness: real WebRTC timer expiry, hard drop, reconnect and
## player-scoped snapshot equality. The host pins its monotonic clock only to
## make the timer proof fast and deterministic; the transport remains real.

const WAIT_LIMIT := 9000
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
		push_error("role and signal-dir are required")
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
	var rules := Ruleset.new()
	rules.turn_timer_seconds = 30
	var created: Dictionary = network_manager.host_online_lobby("M11 Host", 2, rules)
	if not bool(created.get("ok", false)):
		_fail("host_create")
		return
	if not await _wait_until(func() -> bool: return network_manager.lobby_state != null and not network_manager.lobby_state.invite_code.is_empty()):
		_fail("invite_timeout")
		return
	_write("invite", network_manager.lobby_state.invite_code)
	if not await _wait_until(func() -> bool: return network_manager.lobby_state.players.size() == 2 and network_manager.lobby_state.get_player("P2") != null and network_manager.lobby_state.get_player("P2").is_ready):
		_fail("ready_timeout")
		return
	var started: Dictionary = network_manager.start_match(301)
	if not bool(started.get("ok", false)):
		_fail("start_failed")
		return
	if not await _wait_until(func() -> bool: return network_manager.game_state != null and network_manager.transport != null and not network_manager.transport.peer_ids().is_empty()):
		_fail("data_channel_timeout")
		return
	var state: GameState = network_manager.game_state
	state.turn_state.active_player_id = "P2"
	state.clock.set_now_msec(1000)
	state.turn_state.turn_started_at_msec = 1000
	state.turn_state.turn_deadline_msec = 31000
	state.clock.set_now_msec(0)
	state.turn_state.phase = TurnState.Phase.REINFORCEMENT
	ReinforcementManager.new(state).begin_phase(state.turn_state.active_player_id)
	var peer_id: int = network_manager.transport.peer_ids()[0]
	network_manager._send_snapshot_to_peer(peer_id, "P2", NetworkMessage.STATE_SNAPSHOT)
	_write("host-initial", _record())
	if not await _wait_for_file("client-initial") or not _same("host-initial", "client-initial"):
		_fail("initial_snapshot_mismatch")
		return
	state.clock.set_now_msec(31000)
	if not await _wait_until(func() -> bool: return state.last_action_id.begins_with("lifecycle-") and state.turn_state.active_player_id != "P2"):
		_fail("timer_expiry_timeout")
		return
	_write("host-timer-expired", _record())
	if not await _wait_for_file("client-timer-expired") or not _same("host-timer-expired", "client-timer-expired"):
		_fail("timer_snapshot_mismatch")
		return
	if not await _wait_for_file("client-drop"):
		_fail("drop_timeout")
		return
	if not await _wait_until(func() -> bool: return _connection_state("P2") == "DISCONNECTED"):
		_fail("disconnect_not_replicated")
		return
	_write("host-disconnected", _record())
	if not await _wait_for_file("client-reconnected"):
		_fail("reconnect_timeout")
		return
	if not await _wait_until(func() -> bool: return _connection_state("P2") == "CONNECTED"):
		_fail("host_reconnect_state_timeout")
		return
	_write("host-reconnected", _record())
	if not _same("host-reconnected", "client-reconnected"):
		_fail("reconnect_snapshot_mismatch")
		return
	_write("host-done", "ok")
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
	var joined: Dictionary = network_manager.join_online_lobby("M11 Client", invite)
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
	if not await _wait_until(func() -> bool: return network_manager.game_state != null):
		_fail("match_snapshot_timeout")
		return
	if not await _wait_until(func() -> bool: return network_manager.game_state != null and network_manager.game_state.turn_state.turn_deadline_msec == 31000):
		_fail("deadline_not_replicated")
		return
	_write("client-initial", _record())
	if not await _wait_for_file("host-timer-expired"):
		_fail("timer_host_timeout")
		return
	if not await _wait_until(func() -> bool: return network_manager.game_state.last_action_id.begins_with("lifecycle-") and network_manager.game_state.turn_state.active_player_id != "P2"):
		_fail("timer_client_timeout")
		return
	_write("client-timer-expired", _record())
	if not await _wait_until(func() -> bool: return _session_generation() >= 1):
		_fail("reconnect_credential_timeout")
		return
	network_manager.transport.close()
	network_manager.begin_manual_reconnect()
	network_manager.game_state.get_player("P2").status = PlayerState.Status.DISCONNECTED
	_write("client-disconnected", _record())
	_write("client-drop", "requested")
	if not await _wait_until(func() -> bool: return network_manager.connection_state == "in_game" and network_manager.game_state != null and network_manager.game_state.get_player("P2").status == PlayerState.Status.ACTIVE):
		_fail("reconnect_client_timeout")
		return
	_write("client-reconnected", _record())
	if not await _wait_for_file("host-done"):
		_fail("host_done_timeout")
		return
	network_manager.shutdown()
	quit(0)

func _record() -> String:
	var snapshot: GameStateSnapshot = network_manager.snapshot_for_player("P2")
	return "%d|%s|%d|%s|%d" % [network_manager.game_state.state_revision, snapshot.fingerprint(), network_manager.game_state.status, network_manager.game_state.turn_state.active_player_id, network_manager.game_state.turn_state.turn_deadline_msec]

func _connection_state(player_id: String) -> String:
	var entry: LobbyPlayerEntry = network_manager.lobby_state.get_player(player_id) if network_manager.lobby_state != null else null
	return entry.connection_state if entry != null else ""

func _session_generation() -> int:
	var session := get_root().get_node_or_null("SessionManager")
	return int(session.connection_generation) if session != null else 0

func _same(left: String, right: String) -> bool:
	return _read(left) == _read(right)

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
