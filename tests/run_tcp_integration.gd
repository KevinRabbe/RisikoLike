extends SceneTree

const NetworkManagerScript = preload("res://scripts/network/network_manager.gd")

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var host = NetworkManagerScript.new()
	var client = NetworkManagerScript.new()
	var port := 43210 + (Time.get_ticks_msec() % 500)
	var host_result: Dictionary = host.host_local_lobby("TCP Host", 2, Ruleset.new(), port)
	_expect(bool(host_result.get("ok", false)), "TCP host starts")
	var client_result: Dictionary = client.join_local_lobby("TCP Client", "127.0.0.1", port)
	_expect(bool(client_result.get("ok", false)), "TCP client starts")
	await _pump(host, client, 180)
	_expect_equal(client.local_player_id, "P2", "TCP client receives player id")
	if client.local_player_id.is_empty():
		host.shutdown()
		client.shutdown()
		host.free()
		client.free()
		print("TCP_TESTS: %d passed, %d failed" % [passed, failed])
		quit(1)
		return
	client.set_ready_state(true)
	await _pump(host, client, 60)
	_expect(host.lobby_state != null and host.lobby_state.get_player("P2").is_ready, "TCP ready state reaches host")
	var seed_value := 1
	for candidate in range(1, 100):
		var preview := GameState.create_local_for_player_ids(["P1", "P2"], candidate, Ruleset.new())
		if preview.turn_state.active_player_id == "P2":
			seed_value = candidate
			break
	var start_result: Dictionary = host.start_match(seed_value)
	_expect(bool(start_result.get("ok", false)), "TCP host starts match")
	await _pump(host, client, 120)
	_expect(client.game_state != null, "TCP client receives snapshot")
	if client.game_state != null:
		host.game_state.turn_state.phase = TurnState.Phase.REINFORCEMENT
		ReinforcementManager.new(host.game_state).begin_phase("P2")
		var host_peer_ids: Array[int] = host.transport.peer_ids()
		if not host_peer_ids.is_empty():
			host._send_snapshot_to_peer(host_peer_ids[0], "P2", NetworkMessage.STATE_SNAPSHOT)
		await _pump(host, client, 30)
		var owned: Array[TerritoryState] = host.game_state.owned_territories("P2")
		var command := CommandEnvelope.new("tcp-reinforcement", "P2", client.game_state.state_revision, "place_reinforcement", {"territory_id": owned[0].territory_id, "amount": 1})
		var queued: Dictionary = client.submit_command(command)
		_expect(bool(queued.get("ok", false)), "TCP client queues command")
		await _pump(host, client, 60)
		_expect_equal(host.game_state.last_action_id, "tcp-reinforcement", "TCP host processes command")
		_expect_equal(client.state_fingerprint("P2"), host.state_fingerprint("P2"), "TCP host/client fingerprints match")
	host.shutdown()
	client.shutdown()
	host.free()
	client.free()
	print("TCP_TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _pump(host, client, frames: int) -> void:
	for _index in range(frames):
		host._process(0.016)
		client._process(0.016)
		await process_frame
		await create_timer(0.005).timeout

func _expect(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: %s" % label)

func _expect_equal(actual, expected, label: String) -> void:
	_expect(actual == expected, "%s (got %s, expected %s)" % [label, str(actual), str(expected)])
