extends SceneTree

const WAIT_LIMIT := 3000
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
	var created: Dictionary = network_manager.host_online_lobby("M9 Surrender Host", 2, Ruleset.new())
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
	var seed_value := 1
	for candidate in range(1, 100):
		var preview := GameState.create_local_for_player_ids(["P1", "P2"], candidate, Ruleset.new())
		if preview.turn_state.active_player_id == "P2":
			seed_value = candidate
			break
	var started: Dictionary = network_manager.start_match(seed_value)
	if not bool(started.get("ok", false)):
		_fail("start_failed")
		return
	if not await _wait_until(func() -> bool: return network_manager.game_state != null and network_manager.game_state.turn_state.active_player_id == "P2"): return
	if not await _wait_until(func() -> bool: return network_manager.game_state.last_action_id == "m9-surrender"): 
		_fail("surrender_timeout")
		return
	if network_manager.game_state.get_player("P2").status != PlayerState.Status.SURRENDERED:
		_fail("host_surrender_state")
		return
	_record("host-final")
	if not await _wait_until(func() -> bool: return FileAccess.file_exists(_path("client-final"))):
		_fail("client_final_timeout")
		return
	if _read("host-final") != _read("client-final"):
		_fail("surrender_fingerprint_mismatch")
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
	var joined: Dictionary = network_manager.join_online_lobby("M9 Surrender Client", invite)
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
	if not await _wait_until(func() -> bool: return network_manager.game_state != null and network_manager.game_state.turn_state.active_player_id == "P2"): return
	var command := CommandEnvelope.new("m9-surrender", "P2", network_manager.game_state.state_revision, "surrender")
	var queued: Dictionary = network_manager.submit_command(command)
	if not bool(queued.get("ok", false)):
		_fail("surrender_queued_failed")
		return
	if not await _wait_until(func() -> bool: return network_manager.game_state.last_action_id == "m9-surrender"): 
		_fail("client_surrender_timeout")
		return
	if network_manager.game_state.get_player("P2").status != PlayerState.Status.SURRENDERED:
		_fail("client_surrender_state")
		return
	_record("client-final")
	_write("client-done", "ok")
	network_manager.shutdown()
	quit(0)

func _record(name: String) -> void:
	_write(name, "%d|%s|%d|%s" % [network_manager.game_state.state_revision, network_manager.state_fingerprint("P2"), network_manager.game_state.status, network_manager.game_state.turn_state.active_player_id])

func _wait_until(predicate: Callable) -> bool:
	for _index in range(WAIT_LIMIT):
		if bool(predicate.call()):
			return true
		await create_timer(0.01).timeout
	return false

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
	if not FileAccess.file_exists(_path(name)):
		return ""
	var file := FileAccess.open(_path(name), FileAccess.READ)
	return file.get_as_text().strip_edges() if file != null else ""
