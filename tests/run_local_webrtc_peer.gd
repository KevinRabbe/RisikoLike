extends SceneTree

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
		await _run_host()
	else:
		await _run_client()

func _run_host() -> void:
	var host_result: Dictionary = network_manager.host_online_lobby("WebRTC Host", 2, Ruleset.new())
	if not bool(host_result.get("ok", false)):
		_fail("host_create:" + str(host_result.get("code", "ERROR")))
		return
	for _index in range(1000):
		if network_manager.lobby_state != null and not network_manager.lobby_state.invite_code.is_empty():
			break
		await create_timer(0.01).timeout
	if network_manager.lobby_state == null or network_manager.lobby_state.invite_code.is_empty():
		_fail("host_lobby_timeout")
		return
	_write_signal("invite", network_manager.lobby_state.invite_code)
	for _index in range(2000):
		if network_manager.lobby_state.players.size() == 2 and network_manager.lobby_state.get_player("P2").is_ready:
			break
		await create_timer(0.01).timeout
	if network_manager.lobby_state.players.size() != 2 or not network_manager.lobby_state.get_player("P2").is_ready:
		_fail("host_wait_ready")
		return
	var seed_value := 1
	for candidate in range(1, 100):
		var preview := GameState.create_local_for_player_ids(["P1", "P2"], candidate, Ruleset.new())
		if preview.turn_state.active_player_id == "P2":
			seed_value = candidate
			break
	var start_result: Dictionary = network_manager.start_match(seed_value)
	if not bool(start_result.get("ok", false)):
		_fail("host_start_match:" + str(start_result.get("code", "ERROR")))
		return
	network_manager.game_state.turn_state.phase = TurnState.Phase.REINFORCEMENT
	ReinforcementManager.new(network_manager.game_state).begin_phase("P2")
	var peers: Array[int] = network_manager.transport.peer_ids()
	if peers.is_empty():
		_fail("host_data_channel_missing")
		return
	network_manager._send_snapshot_to_peer(peers[0], "P2", NetworkMessage.STATE_SNAPSHOT)
	for _index in range(2000):
		if network_manager.game_state.last_action_id == "webrtc-reinforcement":
			break
		await create_timer(0.01).timeout
	if network_manager.game_state.last_action_id != "webrtc-reinforcement":
		_fail("host_command_timeout")
		return
	_write_signal("host-result", "%d|%s" % [network_manager.game_state.state_revision, network_manager.state_fingerprint("P2")])
	network_manager.shutdown()
	quit(0)

func _run_client() -> void:
	var invite := ""
	for _index in range(1000):
		invite = _read_signal("invite")
		if not invite.is_empty():
			break
		await create_timer(0.01).timeout
	if invite.is_empty():
		_fail("client_invite_timeout")
		return
	var join_result: Dictionary = network_manager.join_online_lobby("WebRTC Client", invite)
	if not bool(join_result.get("ok", false)):
		_fail("client_resolve:" + str(join_result.get("code", "ERROR")))
		return
	for _index in range(2000):
		if network_manager.lobby_state != null and not network_manager.local_player_id.is_empty():
			break
		await create_timer(0.01).timeout
	if network_manager.lobby_state == null or network_manager.local_player_id.is_empty():
		_fail("client_lobby_timeout")
		return
	var ready_result: Dictionary = network_manager.set_ready_state(true)
	if not bool(ready_result.get("ok", false)):
		_fail("client_ready:" + str(ready_result.get("code", "ERROR")))
		return
	for _index in range(2500):
		if network_manager.game_state != null and network_manager.game_state.turn_state.phase == TurnState.Phase.REINFORCEMENT and network_manager.game_state.turn_state.active_player_id == "P2":
			break
		await create_timer(0.01).timeout
	if network_manager.game_state == null:
		_fail("client_snapshot_timeout")
		return
	var owned: Array[TerritoryState] = network_manager.game_state.owned_territories("P2")
	if owned.is_empty():
		_fail("client_owned_territory_missing")
		return
	var command := CommandEnvelope.new("webrtc-reinforcement", "P2", network_manager.game_state.state_revision, "place_reinforcement", {"territory_id": owned[0].territory_id, "amount": 1})
	var queued: Dictionary = network_manager.submit_command(command)
	if not bool(queued.get("ok", false)):
		_fail("client_command:" + str(queued.get("code", "ERROR")))
		return
	for _index in range(2000):
		if network_manager.game_state.last_action_id == "webrtc-reinforcement":
			break
		await create_timer(0.01).timeout
	if network_manager.game_state.last_action_id != "webrtc-reinforcement":
		_fail("client_result_timeout")
		return
	_write_signal("client-result", "%d|%s" % [network_manager.game_state.state_revision, network_manager.state_fingerprint("P2")])
	network_manager.shutdown()
	quit(0)

func _fail(reason: String) -> void:
	_write_signal("failure-%s" % role, reason)
	if network_manager != null:
		network_manager.shutdown()
	quit(1)

func _argument(name: String, default_value: String) -> String:
	var prefix := "--%s=" % name
	for argument in OS.get_cmdline_args():
		if str(argument).begins_with(prefix):
			return str(argument).trim_prefix(prefix)
	return default_value

func _signal_path(name: String) -> String:
	return signal_dir.path_join(name + ".txt")

func _write_signal(name: String, value: String) -> void:
	var file := FileAccess.open(_signal_path(name), FileAccess.WRITE)
	if file != null:
		file.store_string(value)

func _read_signal(name: String) -> String:
	var path := _signal_path(name)
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text().strip_edges() if file != null else ""
