extends SceneTree

## Backend-free direct-host acceptance harness. Both processes use the real
## DirectNetworkTransport and exchange only the self-contained AF1 invite.

var role := ""
var port := 43610
var signal_dir := ""
var network_manager: Variant

func _init() -> void:
	role = _argument("role", "")
	port = int(_argument("port", "43610"))
	signal_dir = _argument("signal-dir", "")
	if role.is_empty() or signal_dir.is_empty():
		push_error("role and signal-dir are required")
		quit(2)
		return
	call_deferred("_run")

func _run() -> void:
	network_manager = get_root().get_node_or_null("NetworkManager")
	if network_manager == null:
		_fail("network_manager_missing")
		return
	if role == "host":
		await _run_host()
	else:
		await _run_client()

func _run_host() -> void:
	var host_result: Dictionary = network_manager.host_direct_lobby("Direct Host", 2, Ruleset.new(), port, "127.0.0.1")
	if not bool(host_result.get("ok", false)):
		_fail("host_start:" + str(host_result.get("code", "ERROR")))
		return
	_write("invite", str(host_result.get("invite_code", "")))
	if not await _wait_until(func() -> bool: return network_manager.lobby_state != null and network_manager.lobby_state.players.size() == 2 and network_manager.lobby_state.get_player("P2").is_ready):
		_fail("host_wait_ready")
		return
	var seed_value := _seed_for_p2()
	var start_result: Dictionary = network_manager.start_match(seed_value)
	if not bool(start_result.get("ok", false)):
		_fail("host_start_match:" + str(start_result.get("code", "ERROR")))
		return
	network_manager.game_state.turn_state.phase = TurnState.Phase.REINFORCEMENT
	ReinforcementManager.new(network_manager.game_state).begin_phase("P2")
	var peer_ids: Array[int] = network_manager.transport.peer_ids()
	if peer_ids.is_empty():
		_fail("host_peer_missing")
		return
	network_manager._send_snapshot_to_peer(peer_ids[0], "P2", NetworkMessage.STATE_SNAPSHOT)
	if not await _wait_until(func() -> bool: return network_manager.game_state.last_action_id == "direct-reinforcement"):
		_fail("host_command_timeout")
		return
	_write("host-result", "%d|%s" % [network_manager.game_state.state_revision, network_manager.state_fingerprint("P2")])
	if not await _wait_until(func() -> bool: return FileAccess.file_exists(_path("client-reconnected")), 15.0):
		_fail("host_reconnect_timeout")
		return
	if not await _wait_until(func() -> bool: return network_manager.lobby_state.get_player("P2").connection_state == "CONNECTED", 3.0):
		_write("host-state", "%s|peer=%d" % [network_manager.lobby_state.get_player("P2").connection_state, network_manager.lobby_state.get_player("P2").network_peer_id])
		_fail("host_reconnect_state")
		return
	_write("host-reconnected", "%d|%s" % [network_manager.game_state.state_revision, network_manager.state_fingerprint("P2")])
	await _wait_until(func() -> bool: return FileAccess.file_exists(_path("client-result")), 10.0)
	network_manager.shutdown()
	quit(0)

func _run_client() -> void:
	var invite := await _wait_for_text("invite")
	if invite.is_empty():
		_fail("client_invite_timeout")
		return
	var join_result: Dictionary = network_manager.join_direct_lobby("Direct Client", invite)
	if not bool(join_result.get("ok", false)):
		_fail("client_join:" + str(join_result.get("code", "ERROR")))
		return
	if not await _wait_until(func() -> bool: return network_manager.lobby_state != null and not network_manager.local_player_id.is_empty()):
		_fail("client_join_timeout")
		return
	var ready_result: Dictionary = network_manager.set_ready_state(true)
	if not bool(ready_result.get("ok", false)):
		_fail("client_ready:" + str(ready_result.get("code", "ERROR")))
		return
	if not await _wait_until(func() -> bool: return network_manager.game_state != null and network_manager.game_state.turn_state.phase == TurnState.Phase.REINFORCEMENT and network_manager.game_state.turn_state.active_player_id == "P2"):
		_fail("client_snapshot_timeout")
		return
	var owned: Array[TerritoryState] = network_manager.game_state.owned_territories("P2")
	if owned.is_empty():
		_fail("client_owned_territory_missing")
		return
	var command := CommandEnvelope.new("direct-reinforcement", "P2", network_manager.game_state.state_revision, "place_reinforcement", {"territory_id": owned[0].territory_id, "amount": 1})
	var queued: Dictionary = network_manager.submit_command(command)
	if not bool(queued.get("ok", false)):
		_fail("client_command:" + str(queued.get("code", "ERROR")))
		return
	if not await _wait_until(func() -> bool: return network_manager.game_state.last_action_id == "direct-reinforcement"):
		_fail("client_result_timeout")
		return
	_write("client-before-drop", "%d|%s" % [network_manager.game_state.state_revision, network_manager.state_fingerprint("P2")])
	if network_manager.transport != null:
		network_manager.transport.close()
	network_manager.begin_manual_reconnect()
	if not await _wait_until(func() -> bool: return network_manager.connection_state == "in_game" and network_manager.local_player_id == "P2", 15.0):
		_fail("client_reconnect_timeout")
		return
	_write("client-reconnected", "%d|%s" % [network_manager.game_state.state_revision, network_manager.state_fingerprint("P2")])
	if not await _wait_until(func() -> bool: return FileAccess.file_exists(_path("host-reconnected")), 5.0):
		_fail("host_reconnect_ack_timeout")
		return
	_write("client-result", "%d|%s" % [network_manager.game_state.state_revision, network_manager.state_fingerprint("P2")])
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

func _wait_for_text(name: String) -> String:
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
