extends SceneTree

## Two-process acceptance harness for M10. It uses the real WebRTC transport,
## drops the guest transport twice, and verifies full player-scoped recovery.

const WAIT_LIMIT := 9000
const SECRET_OPPONENT_CARD := "TERRITORY_NA_03"

var role := ""
var signal_dir := ""
var backend_url := "http://127.0.0.1:8000"
var network_manager: Variant
var backend_client: Variant
var last_result_action := ""
var last_result_code := ""
var last_result_accepted := false

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
	network_manager.command_result_received.connect(_on_command_result)
	if role == "host":
		await _run_host()
	else:
		await _run_client()

func _run_host() -> void:
	var host_result: Dictionary = network_manager.host_online_lobby("M10 Host", 2, Ruleset.new())
	if not bool(host_result.get("ok", false)):
		_fail("host_create:%s" % str(host_result.get("code", "ERROR")))
		return
	if not await _wait_until(func() -> bool: return network_manager.lobby_state != null and not network_manager.lobby_state.invite_code.is_empty()):
		_fail("host_invite_timeout")
		return
	_write_signal("invite", network_manager.lobby_state.invite_code)
	if not await _wait_until(func() -> bool: return network_manager.lobby_state.players.size() == 2 and network_manager.lobby_state.get_player("P2") != null and network_manager.lobby_state.get_player("P2").is_ready):
		_fail("host_ready_timeout")
		return
	var seed_value := 1
	for candidate in range(1, 100):
		var preview := GameState.create_local_for_player_ids(["P1", "P2"], candidate, Ruleset.new())
		if preview.turn_state.active_player_id == "P2":
			seed_value = candidate
			break
	var start_result: Dictionary = network_manager.start_match(seed_value)
	if not bool(start_result.get("ok", false)):
		_fail("host_start:%s" % str(start_result.get("code", "ERROR")))
		return
	_setup_controlled_state()
	var peers: Array[int] = network_manager.transport.peer_ids()
	if peers.is_empty():
		_fail("host_data_channel_missing")
		return
	network_manager._send_snapshot_to_peer(peers[0], "P2", NetworkMessage.STATE_SNAPSHOT)
	_record_step("host", "initial")
	if not await _wait_for_file("client-initial"):
		_fail("client_initial_timeout")
		return
	if not _verify_step_match("initial"):
		_fail("initial_fingerprint_mismatch")
		return
	if not await _wait_for_file("client-credential"):
		_fail("credential_delivery_timeout")
		return

	if not await _wait_for_client_action("m10-reinforcement-1", "reinforcement-1"): return
	if not await _wait_for_client_action("m10-reinforcement-2", "reinforcement-2"): return
	if not await _wait_for_client_action("m10-confirm", "confirm"): return
	if not await _wait_for_client_action("m10-attack", "attack"): return
	if network_manager.game_state.pending_conquest.is_empty():
		_fail("host_pending_conquest_missing")
		return
	if not await _wait_for_file("client-drop-1"): return
	if not await _wait_until(func() -> bool: return _player_connection_state("P2") == "DISCONNECTED"):
		_fail("host_disconnect_not_detected")
		return
	_record_step("host", "disconnected-1")
	if not await _wait_for_file("client-reconnected-1"): return
	if not await _wait_until(func() -> bool: return _player_connection_state("P2") == "CONNECTED"): 
		_fail("host_reconnect_state_timeout")
		return
	_record_step("host", "reconnected-1")
	if not _verify_step_match("reconnected-1"):
		_fail("reconnect_1_fingerprint_mismatch")
		return

	if not await _wait_for_file("client-invalid-conquest"): return
	if not await _wait_for_client_action("m10-conquest", "conquest"): return
	if not await _wait_for_client_action("m10-end-attack", "end-attack"): return
	if not await _wait_for_client_action("m10-fortify", "fortify"): return
	if not await _wait_for_file("client-drop-2"): return
	if not await _wait_until(func() -> bool: return _player_connection_state("P2") == "DISCONNECTED"):
		_fail("host_second_disconnect_not_detected")
		return
	_record_step("host", "disconnected-2")
	if not await _wait_for_file("client-reconnected-2"): return
	if not await _wait_until(func() -> bool: return _player_connection_state("P2") == "CONNECTED"): 
		_fail("host_second_reconnect_state_timeout")
		return
	_record_step("host", "reconnected-2")
	if not _verify_step_match("reconnected-2"):
		_fail("reconnect_2_fingerprint_mismatch")
		return
	_write_signal("host-done", "ok")
	network_manager.shutdown()
	quit(0)

func _run_client() -> void:
	var invite := ""
	for _index in range(WAIT_LIMIT):
		invite = _read_signal("invite")
		if not invite.is_empty():
			break
		await create_timer(0.01).timeout
	if invite.is_empty():
		_fail("client_invite_timeout")
		return
	var join_result: Dictionary = network_manager.join_online_lobby("M10 Client", invite)
	if not bool(join_result.get("ok", false)):
		_fail("client_join:%s" % str(join_result.get("code", "ERROR")))
		return
	if not await _wait_until(func() -> bool: return not network_manager.local_player_id.is_empty()):
		_fail("client_join_timeout")
		return
	var ready_result: Dictionary = network_manager.set_ready_state(true)
	if not bool(ready_result.get("ok", false)):
		_fail("client_ready:%s" % str(ready_result.get("code", "ERROR")))
		return
	if not await _wait_until(func() -> bool: return _is_controlled_state()):
		_fail("client_initial_snapshot_timeout")
		return
	if not _assert_private_opponent_hand("initial"):
		return
	_record_step("client", "initial")
	if not await _wait_until(func() -> bool:
		var session := get_root().get_node_or_null("SessionManager")
		return session != null and not session.reconnect_token.is_empty()
	):
		_fail("reconnect_credential_timeout")
		return
	_write_signal("client-credential", "received")

	if not await _client_command("reinforcement-1", "m10-reinforcement-1", "place_reinforcement", {"territory_id": "NA_01", "amount": 2}): return
	if not await _client_command("reinforcement-2", "m10-reinforcement-2", "place_reinforcement", {"territory_id": "NA_01", "amount": 2}): return
	if not await _client_command("confirm", "m10-confirm", "confirm_reinforcements", {}): return
	if not await _client_command("attack", "m10-attack", "attack", {"source_id": "NA_01", "target_id": "NA_02", "attacker_dice": 3, "defender_dice": 1}): return
	if network_manager.game_state.pending_conquest.get("source_id", "") != "NA_01" or network_manager.game_state.pending_conquest.get("target_id", "") != "NA_02":
		_fail("client_pending_conquest_missing")
		return
	_record_step("client", "before-drop-1")
	network_manager.transport.close()
	_write_signal("client-drop-1", "requested")
	network_manager.begin_manual_reconnect()
	if not await _wait_until(func() -> bool: return network_manager.connection_state == "in_game" and _has_pending_conquest() and _session_generation() == 2):
		_fail("client_reconnect_1_timeout")
		return
	if network_manager.local_player_id != "P2" or not _assert_private_opponent_hand("reconnected-1"):
		return
	_record_step("client", "reconnected-1")

	if not await _client_rejected_command("invalid-conquest", "m10-invalid-conquest", "conquest_move", {"amount": 1}, "INVALID_CONQUEST_AMOUNT"): return
	if not await _client_command("conquest", "m10-conquest", "conquest_move", {"amount": 3}): return
	if not await _client_command("end-attack", "m10-end-attack", "end_phase", {}): return
	if not await _client_command("fortify", "m10-fortify", "fortify", {"source_id": "NA_01", "target_id": "NA_02", "amount": 1}): return
	if not network_manager.game_state.get_player("P2").fortification_used:
		_fail("fortification_flag_missing")
		return
	_record_step("client", "before-drop-2")
	network_manager.transport.close()
	_write_signal("client-drop-2", "requested")
	network_manager.begin_manual_reconnect()
	if not await _wait_until(func() -> bool: return network_manager.connection_state == "in_game" and network_manager.game_state.get_player("P2").fortification_used and _session_generation() == 3):
		_fail("client_reconnect_2_timeout")
		return
	if not _assert_private_opponent_hand("reconnected-2"):
		return
	_record_step("client", "reconnected-2")
	_write_signal("client-done", "ok")
	if not await _wait_for_file("host-done"):
		_fail("host_done_timeout")
		return
	network_manager.shutdown()
	quit(0)

func _setup_controlled_state() -> void:
	var state: GameState = network_manager.game_state
	state.status = GameState.MatchStatus.PLAYING
	state.state_revision = 0
	state.last_action_id = ""
	state.last_result = {}
	state.winner_player_id = ""
	state.turn_state.active_player_id = "P2"
	state.turn_state.phase = TurnState.Phase.REINFORCEMENT
	state.turn_state.round_number = 1
	state.pending_reinforcements.clear()
	state.pending_conquest.clear()
	state.combat_state.clear()
	for territory_id: String in state.territories:
		var territory := state.get_territory(territory_id)
		territory.owner_player_id = "P2"
		territory.army_count = 1
	var source := state.get_territory("NA_01")
	source.owner_player_id = "P2"
	source.army_count = 5
	state.get_territory("NA_02").owner_player_id = "P1"
	state.get_territory("NA_02").army_count = 1
	state.get_territory("NA_03").owner_player_id = "P1"
	state.get_territory("NA_03").army_count = 1
	var p1 := state.get_player("P1")
	var p2 := state.get_player("P2")
	p1.status = PlayerState.Status.ACTIVE
	p2.status = PlayerState.Status.ACTIVE
	p1.territory_card_ids = [SECRET_OPPONENT_CARD]
	p2.territory_card_ids = []
	p1.visible_card_count = 1
	p2.visible_card_count = 0
	p1.reinforcements_remaining = 0
	p2.reinforcements_remaining = 4
	p2.has_conquered_this_turn = false
	p2.fortification_used = false
	network_manager.command_processor.seen_action_ids.clear()
	var controlled_rolls: Array[int] = [6, 6, 6, 1]
	network_manager.command_processor.random_source.set_controlled_rolls(controlled_rolls)

func _client_command(step: String, action_id: String, command_type: String, payload: Dictionary) -> bool:
	var command := CommandEnvelope.new(action_id, "P2", network_manager.game_state.state_revision, command_type, payload)
	var queued: Dictionary = network_manager.submit_command(command)
	if not bool(queued.get("ok", false)):
		_fail("client_command_%s:%s" % [step, str(queued.get("code", "ERROR"))])
		return false
	if not await _wait_until(func() -> bool: return network_manager.game_state != null and network_manager.game_state.last_action_id == action_id):
		_fail("client_result_%s_timeout" % step)
		return false
	_record_step("client", step)
	return true

func _client_rejected_command(step: String, action_id: String, command_type: String, payload: Dictionary, expected_code: String) -> bool:
	var command := CommandEnvelope.new(action_id, "P2", network_manager.game_state.state_revision, command_type, payload)
	var queued: Dictionary = network_manager.submit_command(command)
	if not bool(queued.get("ok", false)):
		_fail("client_rejected_queue_%s" % step)
		return false
	if not await _wait_until(func() -> bool: return last_result_action == action_id):
		_fail("client_rejected_result_timeout_%s" % step)
		return false
	if last_result_accepted or last_result_code != expected_code:
		_fail("client_rejected_code_%s:%s" % [step, last_result_code])
		return false
	_write_signal("client-%s" % step, last_result_code)
	return true

func _on_command_result(result: CommandResult) -> void:
	last_result_action = result.action_id
	last_result_code = result.code
	last_result_accepted = result.accepted

func _wait_for_client_action(action_id: String, step: String) -> bool:
	if not await _wait_until(func() -> bool: return network_manager.game_state != null and network_manager.game_state.last_action_id == action_id):
		_fail("host_%s_timeout" % step)
		return false
	_record_step("host", step)
	if not await _wait_for_file("client-%s" % step):
		_fail("client_%s_timeout" % step)
		return false
	return _verify_step_match(step)

func _record_step(side: String, step: String) -> void:
	var snapshot: GameStateSnapshot = network_manager.snapshot_for_player("P2")
	var line := "%d|%s|%d|%s" % [network_manager.game_state.state_revision, snapshot.fingerprint(), network_manager.game_state.status, network_manager.game_state.winner_player_id]
	_write_signal("%s-%s" % [side, step], line)

func _verify_step_match(step: String) -> bool:
	return _read_signal("host-%s" % step) == _read_signal("client-%s" % step)

func _is_controlled_state() -> bool:
	return network_manager.game_state != null and network_manager.game_state.turn_state.active_player_id == "P2" and network_manager.game_state.turn_state.phase == TurnState.Phase.REINFORCEMENT and network_manager.game_state.get_territory("NA_02").owner_player_id == "P1"

func _has_pending_conquest() -> bool:
	return network_manager.game_state != null and network_manager.game_state.pending_conquest.get("source_id", "") == "NA_01" and network_manager.game_state.pending_conquest.get("target_id", "") == "NA_02"

func _assert_private_opponent_hand(_label: String) -> bool:
	var snapshot: GameStateSnapshot = network_manager.snapshot_for_player("P2")
	for raw_player in snapshot.players:
		if str(raw_player.get("player_id", "")) == "P1" and (raw_player.get("territory_card_ids", []) as Array).has(SECRET_OPPONENT_CARD):
			_fail("privacy_leak")
			return false
	return true

func _player_connection_state(player_id: String) -> String:
	var player: LobbyPlayerEntry = network_manager.lobby_state.get_player(player_id) if network_manager.lobby_state != null else null
	return player.connection_state if player != null else ""

func _session_generation() -> int:
	var session := get_root().get_node_or_null("SessionManager")
	return int(session.connection_generation) if session != null else 0

func _wait_until(predicate: Callable) -> bool:
	for _index in range(WAIT_LIMIT):
		if bool(predicate.call()):
			return true
		await create_timer(0.01).timeout
	return false

func _wait_for_file(name: String) -> bool:
	return await _wait_until(func() -> bool: return FileAccess.file_exists(_signal_path(name)))

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
