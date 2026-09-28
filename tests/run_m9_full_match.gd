extends SceneTree

## Real two-process M9 acceptance harness.
## The host creates one deterministic setup state before the first snapshot.
## Every subsequent mutation is a normal CommandEnvelope through the WebRTC
## NetworkTransport and the host CommandProcessor.

const WAIT_LIMIT := 4000
const SECRET_P1_CARD := "TERRITORY_NA_04"

var role := ""
var signal_dir := ""
var backend_url := "http://127.0.0.1:8000"
var network_manager: Variant
var backend_client: Variant
var last_network_result_code := ""
var last_network_result_action := ""

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
	var host_result: Dictionary = network_manager.host_online_lobby("M9 Host", 2, Ruleset.new())
	if not bool(host_result.get("ok", false)):
		_fail("host_create:" + str(host_result.get("code", "ERROR")))
		return
	if not await _wait_until(func() -> bool: return network_manager.lobby_state != null and not network_manager.lobby_state.invite_code.is_empty()):
		_fail("host_lobby_timeout")
		return
	_write_signal("invite", network_manager.lobby_state.invite_code)
	if not await _wait_until(func() -> bool: return network_manager.lobby_state.players.size() == 2 and network_manager.lobby_state.get_player("P2") != null and network_manager.lobby_state.get_player("P2").is_ready):
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
	if not await _wait_until(func() -> bool: return network_manager.game_state != null and network_manager.transport != null and not network_manager.transport.peer_ids().is_empty()):
		_fail("host_data_channel_timeout")
		return

	_setup_controlled_state()
	var peer_ids: Array[int] = network_manager.transport.peer_ids()
	network_manager._send_snapshot_to_peer(peer_ids[0], "P2", NetworkMessage.STATE_SNAPSHOT)
	_record_step("host", "initial")
	if not await _wait_for_file("client-initial"):
		_fail("client_initial_timeout")
		return

	# P2: card trade -> reinforcement -> attack -> conquest -> fortification -> end turn.
	if not await _wait_for_client_action("m9-p2-trade", "trade"): return
	if not await _wait_for_client_action("m9-p2-card-phase", "p2_card_phase"): return
	if not await _wait_for_client_action("m9-p2-reinforcement", "reinforcement"): return
	if not await _wait_for_client_action("m9-p2-confirm", "p2_confirm"): return
	if not await _wait_for_client_action("m9-p2-attack", "attack"): return
	if not await _wait_for_client_action("m9-p2-conquest", "conquest_move"): return
	if not await _wait_for_client_action("m9-p2-end-attack", "p2_end_attack"): return
	if not await _wait_for_client_action("m9-p2-fortify", "fortification"): return
	if not await _wait_for_client_action("m9-p2-end-fortification", "p2_end_fortification"): return
	if not await _wait_for_client_action("m9-p2-end-turn", "end_turn"): return
	var host_drawn_player: PlayerState = network_manager.game_state.get_player("P2")
	if host_drawn_player == null or not host_drawn_player.card_drawn_this_turn or host_drawn_player.territory_card_ids.size() != 1:
		_fail("host_authoritative_card_draw_missing")
		return

	# P1 is the host. These commands are still validated by the same host
	# CommandProcessor and their authoritative snapshots travel over WebRTC.
	if not await _host_command("m9-p1-card-phase", "p1_card_phase", "end_phase", {}): return
	if not await _host_command("m9-p1-reinforcement", "p1_reinforcement", "place_reinforcement", {"territory_id": "NA_03", "amount": 3}): return
	if not await _host_command("m9-p1-confirm", "p1_confirm", "confirm_reinforcements", {}): return
	if not await _host_command("m9-p1-attack", "p1_attack", "attack", {"source_id": "NA_03", "target_id": "NA_04", "attacker_dice": 1, "defender_dice": 1}): return
	if not await _host_command("m9-p1-end-attack", "p1_end_attack", "end_phase", {}): return
	if not await _host_command("m9-p1-end-fortification", "p1_end_fortification", "end_phase", {}): return
	if not await _host_command("m9-p1-end-turn", "p1_end_turn", "end_turn", {}): return

	# P2's final turn: two combat actions, elimination, conquest move and victory.
	if not await _wait_for_client_action("m9-p2-final-card-phase", "p2_final_card_phase"): return
	if not await _wait_for_client_action("m9-p2-final-reinforcement", "p2_final_reinforcement"): return
	if not await _wait_for_client_action("m9-p2-final-confirm", "p2_final_confirm"): return
	if not await _wait_for_client_action("m9-p2-final-attack-1", "p2_final_attack_1"): return
	if not await _wait_for_client_action("m9-p2-final-attack-2", "p2_final_attack_2"): return
	if not await _wait_for_client_action("m9-p2-final-conquest", "p2_final_conquest"): return

	if network_manager.game_state.status != GameState.MatchStatus.FINISHED or network_manager.game_state.winner_player_id != "P2":
		_fail("host_final_state_invalid")
		return
	_record_step("host", "final")
	if not await _wait_for_file("client-final"):
		_fail("client_final_timeout")
		return
	if not _verify_step_match("final"):
		_fail("final_fingerprint_mismatch")
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
	var join_result: Dictionary = network_manager.join_online_lobby("M9 Client", invite)
	if not bool(join_result.get("ok", false)):
		_fail("client_resolve:" + str(join_result.get("code", "ERROR")))
		return
	if not await _wait_until(func() -> bool: return not network_manager.local_player_id.is_empty()):
		_fail("client_join_timeout")
		return
	var ready_result: Dictionary = network_manager.set_ready_state(true)
	if not bool(ready_result.get("ok", false)):
		_fail("client_ready:" + str(ready_result.get("code", "ERROR")))
		return
	if not await _wait_until(func() -> bool: return _is_controlled_state()):
		_fail("client_initial_snapshot_timeout")
		return
	if not _assert_private_opponent_hand("initial"):
		return
	_record_step("client", "initial")

	# P2 client commands use the real WebRTC DataChannel.
	if not await _client_command("trade", "m9-p2-trade", "trade_cards", {"card_ids": ["TERRITORY_NA_01", "TERRITORY_NA_02", "TERRITORY_NA_03"]}): return
	if not await _client_command("p2_card_phase", "m9-p2-card-phase", "end_phase", {}): return
	var first_reinforcement_amount: int = network_manager.game_state.get_player("P2").reinforcements_remaining
	if not await _client_command("reinforcement", "m9-p2-reinforcement", "place_reinforcement", {"territory_id": "NA_01", "amount": first_reinforcement_amount}): return
	if not await _client_command("p2_confirm", "m9-p2-confirm", "confirm_reinforcements", {}): return
	if not await _client_command("attack", "m9-p2-attack", "attack", {"source_id": "NA_01", "target_id": "NA_02", "attacker_dice": 3, "defender_dice": 1}): return
	if not await _client_command("conquest_move", "m9-p2-conquest", "conquest_move", {"amount": 3}): return
	if not await _client_command("p2_end_attack", "m9-p2-end-attack", "end_phase", {}): return
	if not await _client_command("fortification", "m9-p2-fortify", "fortify", {"source_id": "NA_01", "target_id": "NA_02", "amount": 1}): return
	if not await _client_command("p2_end_fortification", "m9-p2-end-fortification", "end_phase", {}): return
	if not await _client_command("end_turn", "m9-p2-end-turn", "end_turn", {}): return
	if not await _wait_until(func() -> bool: return network_manager.game_state != null and network_manager.game_state.turn_state.active_player_id == "P1"): return

	# Wait for the host's complete P1 turn and record every replicated step.
	if not await _wait_for_host_action("p1_card_phase", "m9-p1-card-phase"): return
	if not await _wait_for_host_action("p1_reinforcement", "m9-p1-reinforcement"): return
	if not await _wait_for_host_action("p1_confirm", "m9-p1-confirm"): return
	if not await _wait_for_host_action("p1_attack", "m9-p1-attack"): return
	if not await _wait_for_host_action("p1_end_attack", "m9-p1-end-attack"): return
	if not await _wait_for_host_action("p1_end_fortification", "m9-p1-end-fortification"): return
	if not await _wait_for_host_action("p1_end_turn", "m9-p1-end-turn"): return
	if not _assert_private_opponent_hand("after-draw"):
		return
	var drawn_player: PlayerState = network_manager.game_state.get_player("P2")
	if drawn_player == null or drawn_player.territory_card_ids.size() != 1:
		_fail("authoritative_card_hand_missing_after_turn_start")
		return

	if not await _client_command("p2_final_card_phase", "m9-p2-final-card-phase", "end_phase", {}): return
	var final_reinforcement_amount: int = network_manager.game_state.get_player("P2").reinforcements_remaining
	if not await _client_command("p2_final_reinforcement", "m9-p2-final-reinforcement", "place_reinforcement", {"territory_id": "NA_02", "amount": final_reinforcement_amount}): return
	if not await _client_command("p2_final_confirm", "m9-p2-final-confirm", "confirm_reinforcements", {}): return
	if not await _client_command("p2_final_attack_1", "m9-p2-final-attack-1", "attack", {"source_id": "NA_02", "target_id": "NA_03", "attacker_dice": 3, "defender_dice": 2}): return
	if not await _client_command("p2_final_attack_2", "m9-p2-final-attack-2", "attack", {"source_id": "NA_02", "target_id": "NA_03", "attacker_dice": 3, "defender_dice": 1}): return
	if not await _client_command("p2_final_conquest", "m9-p2-final-conquest", "conquest_move", {"amount": 3}): return
	if network_manager.game_state.status != GameState.MatchStatus.FINISHED or network_manager.game_state.winner_player_id != "P2":
		_fail("client_final_state_invalid")
		return
	var final_player: PlayerState = network_manager.game_state.get_player("P2")
	if final_player == null or not final_player.territory_card_ids.has(SECRET_P1_CARD):
		_fail("elimination_card_transfer_missing")
		return
	_record_step("client", "final")
	_write_signal("client-done", "ok")
	network_manager.shutdown()
	quit(0)

func _setup_controlled_state() -> void:
	var state: GameState = network_manager.game_state
	for territory_id: String in state.territories:
		var territory := state.get_territory(territory_id)
		territory.owner_player_id = "P2"
		territory.army_count = 1
	state.get_territory("NA_01").army_count = 5
	state.get_territory("NA_02").owner_player_id = "P1"
	state.get_territory("NA_02").army_count = 1
	state.get_territory("NA_03").owner_player_id = "P1"
	state.get_territory("NA_03").army_count = 1
	state.get_territory("NA_04").army_count = 10
	var p1 := state.get_player("P1")
	var p2 := state.get_player("P2")
	p1.territory_card_ids.clear()
	p2.territory_card_ids.clear()
	p1.territory_card_ids.append(SECRET_P1_CARD)
	p2.territory_card_ids.append("TERRITORY_NA_01")
	p2.territory_card_ids.append("TERRITORY_NA_02")
	p2.territory_card_ids.append("TERRITORY_NA_03")
	for card_id in [SECRET_P1_CARD, "TERRITORY_NA_01", "TERRITORY_NA_02", "TERRITORY_NA_03"]:
		state.deck_state.draw_pile.erase(card_id)
	state.status = GameState.MatchStatus.PLAYING
	state.state_revision = 0
	state.last_action_id = ""
	state.last_result = {}
	state.winner_player_id = ""
	state.pending_reinforcements.clear()
	state.pending_conquest.clear()
	state.forced_trade_player_id = ""
	state.combat_state.clear()
	state.turn_state.round_number = 1
	state.turn_state.active_player_id = "P2"
	state.turn_state.phase = TurnState.Phase.CARD_TRADE
	p1.reinforcements_remaining = 0
	p1.has_conquered_this_turn = false
	p1.card_drawn_this_turn = false
	p1.fortification_used = false
	p1.pending_trade_reinforcements = 0
	p2.reinforcements_remaining = 0
	p2.has_conquered_this_turn = false
	p2.card_drawn_this_turn = false
	p2.fortification_used = false
	p2.pending_trade_reinforcements = 0
	network_manager.command_processor.seen_action_ids.clear()
	var controlled_rolls: Array[int] = [
		6, 6, 6, 1, # P2 first attack: conquest.
		1, 6, # P1 attack: attacker loses, no conquest.
		6, 6, 6, 1, 1, # P2 final attack 1: two defender losses.
		6, 6, 6, 1, # P2 final attack 2: final defender loss.
	]
	network_manager.command_processor.random_source.set_controlled_rolls(controlled_rolls)

func _client_command(step: String, action_id: String, command_type: String, payload: Dictionary) -> bool:
	var command := CommandEnvelope.new(action_id, "P2", network_manager.game_state.state_revision, command_type, payload)
	var queued: Dictionary = network_manager.submit_command(command)
	if not bool(queued.get("ok", false)):
		_fail("client_command_%s:%s" % [step, str(queued.get("code", "ERROR"))])
		return false
	if not await _wait_until(func() -> bool: return network_manager.game_state != null and network_manager.game_state.last_action_id == action_id):
		push_error("M9 client result timeout step=%s phase=%s remaining=%d revision=%d result=%s/%s" % [step, TurnState.Phase.keys()[network_manager.game_state.turn_state.phase] if network_manager.game_state != null else "none", network_manager.game_state.get_player("P2").reinforcements_remaining if network_manager.game_state != null else -1, network_manager.game_state.state_revision if network_manager.game_state != null else -1, last_network_result_action, last_network_result_code])
		_fail("client_result_%s_timeout" % step)
		return false
	_record_step("client", step)
	return true

func _host_command(step: String, action_id: String, command_type: String, payload: Dictionary) -> bool:
	var command := CommandEnvelope.new(action_id, "P1", network_manager.game_state.state_revision, command_type, payload)
	var result: Dictionary = network_manager.submit_command(command)
	if not bool(result.get("ok", false)):
		_fail("host_command_%s:%s" % [step, str(result.get("code", "ERROR"))])
		return false
	if network_manager.game_state.last_action_id != action_id:
		_fail("host_result_%s_missing" % step)
		return false
	_record_step("host", step)
	if not await _wait_for_file("client-%s" % step):
		_fail("client_%s_timeout" % step)
		return false
	if not _verify_step_match(step):
		_fail("fingerprint_mismatch_%s" % step)
		return false
	return true

func _wait_for_client_action(action_id: String, step: String) -> bool:
	if not await _wait_until(func() -> bool: return network_manager.game_state != null and network_manager.game_state.last_action_id == action_id):
		_fail("host_%s_timeout" % step)
		return false
	_record_step("host", step)
	if not await _wait_for_file("client-%s" % step):
		_fail("client_%s_timeout" % step)
		return false
	if not _verify_step_match(step):
		_fail("fingerprint_mismatch_%s" % step)
		return false
	return true

func _wait_for_host_action(action_id: String, step: String) -> bool:
	if not await _wait_until(func() -> bool: return network_manager.game_state != null and network_manager.game_state.last_action_id == action_id):
		_fail("client_%s_timeout" % step)
		return false
	_record_step("client", step)
	return true

func _is_controlled_state() -> bool:
	if network_manager.game_state == null:
		return false
	var target: TerritoryState = network_manager.game_state.get_territory("NA_02")
	var player: PlayerState = network_manager.game_state.get_player("P2")
	return network_manager.game_state.turn_state.phase == TurnState.Phase.CARD_TRADE and network_manager.game_state.turn_state.active_player_id == "P2" and target != null and target.owner_player_id == "P1" and player != null and player.territory_card_ids.size() == 3

func _assert_private_opponent_hand(label: String) -> bool:
	var snapshot: GameStateSnapshot = network_manager.snapshot_for_player("P2")
	for player_value in snapshot.players:
		if str(player_value.get("player_id", "")) == "P1" and (player_value.get("territory_card_ids", []) as Array).has(SECRET_P1_CARD):
			_fail("privacy_leak_%s" % label)
			return false
	return true

func _record_step(side: String, step: String) -> void:
	var snapshot: GameStateSnapshot = network_manager.snapshot_for_player("P2")
	var line := "%d|%s|%d|%s" % [network_manager.game_state.state_revision, snapshot.fingerprint(), network_manager.game_state.status, network_manager.game_state.winner_player_id]
	_write_signal("%s-%s" % [side, step], line)

func _verify_step_match(step: String) -> bool:
	var host_value := _read_signal("host-%s" % step)
	var client_value := _read_signal("client-%s" % step)
	if host_value == client_value:
		return true
	push_error("M9 fingerprint mismatch step=%s host=%s client=%s" % [step, host_value, client_value])
	return false

func _wait_until(predicate: Callable) -> bool:
	for _index in range(WAIT_LIMIT):
		if bool(predicate.call()):
			return true
		await create_timer(0.01).timeout
	return false

func _wait_for_file(name: String) -> bool:
	return await _wait_until(func() -> bool: return FileAccess.file_exists(_signal_path(name)))

func _on_command_result(result: CommandResult) -> void:
	last_network_result_action = result.action_id
	last_network_result_code = result.code

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
