from __future__ import annotations

from typing import Any

from fastapi.testclient import TestClient

from app.main import LobbyRegistry, create_app


class FakeClock:
    def __init__(self, value: float = 1_000.0) -> None:
        self.value = value

    def __call__(self) -> float:
        return self.value

    def advance(self, seconds: float) -> None:
        self.value += seconds


def _create(client: TestClient) -> dict[str, Any]:
    response = client.post(
        "/v1/lobbies",
        json={"game_version": "0.1.0", "protocol_version": 1, "max_players": 2},
    )
    assert response.status_code == 200
    return response.json()


def _start(client: TestClient, created: dict[str, Any]) -> None:
    response = client.post(
        f"/v1/lobbies/{created['lobby_id']}/started",
        headers={"Authorization": f"Bearer {created['host_session_token']}"},
    )
    assert response.status_code == 200


def _credential(client: TestClient, created: dict[str, Any]) -> dict[str, Any]:
    response = client.post(
        f"/v1/lobbies/{created['lobby_id']}/reconnect-credentials",
        json={"player_id": "P2"},
        headers={"Authorization": f"Bearer {created['host_session_token']}"},
    )
    assert response.status_code == 200, response.text
    return response.json()


def test_reconnect_token_binding_rotation_and_replay() -> None:
    clock = FakeClock()
    registry = LobbyRegistry(clock=clock)
    client = TestClient(create_app(registry))
    created = _create(client)
    _start(client, created)
    issued = _credential(client, created)
    assert issued["match_id"] == created["lobby_id"]
    assert issued["player_id"] == "P2"
    assert len(issued["reconnect_token"]) >= 40
    assert "P2" not in issued["reconnect_token"]

    authorized = client.post(
        "/v1/matches/reconnect",
        json={
            "match_id": created["lobby_id"],
            "player_id": "P2",
            "reconnect_token": issued["reconnect_token"],
            "protocol_version": 1,
            "game_version": "0.1.0",
        },
    )
    assert authorized.status_code == 200, authorized.text
    rotated = authorized.json()
    assert rotated["generation"] == 2
    assert rotated["reconnect_token"] != issued["reconnect_token"]

    replay = client.post(
        "/v1/matches/reconnect",
        json={
            "match_id": created["lobby_id"],
            "player_id": "P2",
            "reconnect_token": issued["reconnect_token"],
            "protocol_version": 1,
            "game_version": "0.1.0",
        },
    )
    assert replay.status_code == 401
    assert replay.json()["error"]["code"] == "RECONNECT_TOKEN_REUSED"

    wrong_player = client.post(
        "/v1/matches/reconnect",
        json={
            "match_id": created["lobby_id"],
            "player_id": "P3",
            "reconnect_token": rotated["reconnect_token"],
            "protocol_version": 1,
            "game_version": "0.1.0",
        },
    )
    assert wrong_player.status_code == 401
    assert wrong_player.json()["error"]["code"] == "RECONNECT_TOKEN_INVALID"

    wrong_match = client.post(
        "/v1/matches/reconnect",
        json={
            "match_id": "other-match",
            "player_id": "P2",
            "reconnect_token": rotated["reconnect_token"],
            "protocol_version": 1,
            "game_version": "0.1.0",
        },
    )
    assert wrong_match.status_code == 404
    assert wrong_match.json()["error"]["code"] == "MATCH_NOT_FOUND"


def test_active_reconnect_slot_is_not_taken_over() -> None:
    registry = LobbyRegistry(clock=FakeClock())
    client = TestClient(create_app(registry))
    created = _create(client)
    _start(client, created)
    issued = _credential(client, created)
    authorized = client.post(
        "/v1/matches/reconnect",
        json={
            "match_id": created["lobby_id"],
            "player_id": "P2",
            "reconnect_token": issued["reconnect_token"],
            "protocol_version": 1,
            "game_version": "0.1.0",
        },
    ).json()
    with client.websocket_connect("/v1/signaling") as host:
        host.send_json({
            "type": "AUTH_HOST",
            "lobby_id": created["lobby_id"],
            "host_session_token": created["host_session_token"],
            "protocol_version": 1,
            "game_version": "0.1.0",
        })
        assert host.receive_json()["type"] == "AUTH_OK"
        with client.websocket_connect("/v1/signaling") as reconnect:
            reconnect.send_json({
                "type": "AUTH_RECONNECT",
                "lobby_id": created["lobby_id"],
                "reconnect_ticket": authorized["reconnect_ticket"],
                "player_id": "P2",
                "connection_generation": authorized["generation"],
                "protocol_version": 1,
                "game_version": "0.1.0",
            })
            assert reconnect.receive_json()["type"] == "AUTH_OK"
            assert host.receive_json()["type"] == "PEER_RECONNECTING"
            takeover = client.post(
                "/v1/matches/reconnect",
                json={
                    "match_id": created["lobby_id"],
                    "player_id": "P2",
                    "reconnect_token": authorized["reconnect_token"],
                    "protocol_version": 1,
                    "game_version": "0.1.0",
                },
            )
            assert takeover.status_code == 409
            assert takeover.json()["error"]["code"] == "PLAYER_ALREADY_CONNECTED"


def test_reconnect_window_expiry_and_secret_safe_logging(caplog) -> None:
    clock = FakeClock()
    registry = LobbyRegistry(clock=clock)
    client = TestClient(create_app(registry))
    caplog.set_level("INFO")
    created = _create(client)
    _start(client, created)
    issued = _credential(client, created)
    clock.advance(181)
    expired = client.post(
        "/v1/matches/reconnect",
        json={
            "match_id": created["lobby_id"],
            "player_id": "P2",
            "reconnect_token": issued["reconnect_token"],
            "protocol_version": 1,
            "game_version": "0.1.0",
        },
    )
    assert expired.status_code == 410
    assert expired.json()["error"]["code"] == "RECONNECT_WINDOW_EXPIRED"
    assert issued["reconnect_token"] not in caplog.text


def test_reconnect_signaling_rejects_unavailable_host() -> None:
    registry = LobbyRegistry(clock=FakeClock())
    client = TestClient(create_app(registry))
    created = _create(client)
    _start(client, created)
    issued = _credential(client, created)
    authorized = client.post(
        "/v1/matches/reconnect",
        json={
            "match_id": created["lobby_id"],
            "player_id": "P2",
            "reconnect_token": issued["reconnect_token"],
            "protocol_version": 1,
            "game_version": "0.1.0",
        },
    ).json()
    with client.websocket_connect("/v1/signaling") as reconnect:
        reconnect.send_json({
            "type": "AUTH_RECONNECT",
            "lobby_id": created["lobby_id"],
            "reconnect_ticket": authorized["reconnect_ticket"],
            "player_id": "P2",
            "connection_generation": authorized["generation"],
            "protocol_version": 1,
            "game_version": "0.1.0",
        })
        error = reconnect.receive_json()
        assert error["type"] == "AUTH_ERROR"
        assert error["error"]["code"] == "HOST_UNAVAILABLE"


def test_match_heartbeat_does_not_shorten_reconnect_window() -> None:
    clock = FakeClock()
    registry = LobbyRegistry(clock=clock)
    client = TestClient(create_app(registry))
    created = _create(client)
    _start(client, created)
    issued = _credential(client, created)
    clock.advance(46)
    heartbeat = client.post(
        f"/v1/lobbies/{created['lobby_id']}/heartbeat",
        headers={"Authorization": f"Bearer {created['host_session_token']}"},
    )
    assert heartbeat.status_code == 200
    authorized = client.post(
        "/v1/matches/reconnect",
        json={
            "match_id": created["lobby_id"],
            "player_id": "P2",
            "reconnect_token": issued["reconnect_token"],
            "protocol_version": 1,
            "game_version": "0.1.0",
        },
    )
    assert authorized.status_code == 200, authorized.text
