from __future__ import annotations

from typing import Any

import pytest
from fastapi.testclient import TestClient

from app.main import INVITE_ALPHABET, MAX_WS_MESSAGE_BYTES, LobbyRegistry, create_app, normalize_invite_code


class FakeClock:
    def __init__(self, value: float = 1_000.0) -> None:
        self.value = value

    def __call__(self) -> float:
        return self.value

    def advance(self, seconds: float) -> None:
        self.value += seconds


@pytest.fixture()
def fixture() -> tuple[FakeClock, LobbyRegistry, TestClient]:
    clock = FakeClock()
    registry = LobbyRegistry(clock=clock)
    return clock, registry, TestClient(create_app(registry))


def create(client: TestClient, max_players: int = 2) -> dict[str, Any]:
    response = client.post(
        "/v1/lobbies",
        json={"game_version": "0.1.0-dev", "protocol_version": 1, "max_players": max_players},
    )
    assert response.status_code == 200, response.text
    return response.json()


def test_invite_code_format_and_normalization() -> None:
    assert normalize_invite_code(" abc-234 ") == "ABC-234"
    assert normalize_invite_code("abc234") == "ABC-234"
    assert set("ABC234") <= set(INVITE_ALPHABET)
    with pytest.raises(Exception):
        normalize_invite_code("ABC-120")


def test_create_resolve_and_versions(fixture: tuple[FakeClock, LobbyRegistry, TestClient]) -> None:
    _clock, _registry, client = fixture
    created = create(client)
    assert len(created["invite_code"]) == 7
    resolved = client.post(
        "/v1/lobbies/resolve",
        json={"invite_code": created["invite_code"].lower(), "game_version": "0.1.0-dev", "protocol_version": 1},
    )
    assert resolved.status_code == 200
    assert resolved.json()["lobby_id"] == created["lobby_id"]
    assert resolved.json()["ice_servers"] == []
    assert client.post(
        "/v1/lobbies/resolve",
        json={"invite_code": created["invite_code"], "game_version": "wrong", "protocol_version": 1},
    ).json()["error"]["code"] == "VERSION_MISMATCH"
    assert client.post(
        "/v1/lobbies/resolve",
        json={"invite_code": created["invite_code"], "game_version": "0.1.0-dev", "protocol_version": 9},
    ).json()["error"]["code"] == "PROTOCOL_MISMATCH"


def test_lobby_lifecycle_heartbeat_close_and_wrong_token(fixture: tuple[FakeClock, LobbyRegistry, TestClient]) -> None:
    clock, _registry, client = fixture
    created = create(client)
    wrong = client.post(f"/v1/lobbies/{created['lobby_id']}/heartbeat", headers={"Authorization": "Bearer wrong"})
    assert wrong.status_code == 401
    heartbeat = client.post(
        f"/v1/lobbies/{created['lobby_id']}/heartbeat",
        headers={"Authorization": f"Bearer {created['host_session_token']}"},
    )
    assert heartbeat.status_code == 200
    clock.advance(44)
    assert client.post(
        "/v1/lobbies/resolve",
        json={"invite_code": created["invite_code"], "game_version": "0.1.0-dev", "protocol_version": 1},
    ).status_code == 200
    close = client.post(
        f"/v1/lobbies/{created['lobby_id']}/close",
        headers={"X-Host-Session-Token": created["host_session_token"]},
    )
    assert close.status_code == 200
    resolved = client.post(
        "/v1/lobbies/resolve",
        json={"invite_code": created["invite_code"], "game_version": "0.1.0-dev", "protocol_version": 1},
    )
    assert resolved.json()["error"]["code"] == "LOBBY_CLOSED"


def test_ttl_and_valid_heartbeat(fixture: tuple[FakeClock, LobbyRegistry, TestClient]) -> None:
    clock, _registry, client = fixture
    created = create(client)
    clock.advance(46)
    expired = client.post(
        "/v1/lobbies/resolve",
        json={"invite_code": created["invite_code"], "game_version": "0.1.0-dev", "protocol_version": 1},
    )
    assert expired.json()["error"]["code"] == "LOBBY_EXPIRED"
    created = create(client)
    clock.advance(40)
    assert client.post(
        f"/v1/lobbies/{created['lobby_id']}/heartbeat",
        headers={"Authorization": f"Bearer {created['host_session_token']}"},
    ).status_code == 200
    clock.advance(40)
    assert client.post(
        "/v1/lobbies/resolve",
        json={"invite_code": created["invite_code"], "game_version": "0.1.0-dev", "protocol_version": 1},
    ).status_code == 200


def test_join_token_is_lobby_bound_expiring_and_single_use(fixture: tuple[FakeClock, LobbyRegistry, TestClient]) -> None:
    clock, registry, client = fixture
    created = create(client)
    resolved = client.post(
        "/v1/lobbies/resolve",
        json={"invite_code": created["invite_code"], "game_version": "0.1.0-dev", "protocol_version": 1},
    ).json()
    registry.consume_join_token(created["lobby_id"], resolved["join_token"])
    with pytest.raises(Exception) as replay:
        registry.consume_join_token(created["lobby_id"], resolved["join_token"])
    assert replay.value.code == "TOKEN_ALREADY_USED"
    other = create(client)
    with pytest.raises(Exception) as wrong_lobby:
        registry.consume_join_token(other["lobby_id"], resolved["join_token"])
    assert wrong_lobby.value.code == "INVALID_TOKEN"
    expiring = client.post(
        "/v1/lobbies/resolve",
        json={"invite_code": other["invite_code"], "game_version": "0.1.0-dev", "protocol_version": 1},
    ).json()
    clock.advance(40)
    assert client.post(
        f"/v1/lobbies/{other['lobby_id']}/heartbeat",
        headers={"Authorization": f"Bearer {other['host_session_token']}"},
    ).status_code == 200
    clock.advance(21)
    with pytest.raises(Exception) as expired:
        registry.consume_join_token(other["lobby_id"], expiring["join_token"])
    assert expired.value.code == "TOKEN_EXPIRED"


def test_max_players_and_started_lobby(fixture: tuple[FakeClock, LobbyRegistry, TestClient]) -> None:
    _clock, _registry, client = fixture
    invalid = client.post("/v1/lobbies", json={"game_version": "0.1.0-dev", "protocol_version": 1, "max_players": 1})
    assert invalid.json()["error"]["code"] == "INVALID_REQUEST"
    created = create(client)
    assert client.post(
        f"/v1/lobbies/{created['lobby_id']}/started",
        headers={"Authorization": f"Bearer {created['host_session_token']}"},
    ).status_code == 200
    response = client.post(
        "/v1/lobbies/resolve",
        json={"invite_code": created["invite_code"], "game_version": "0.1.0-dev", "protocol_version": 1},
    )
    assert response.json()["error"]["code"] == "MATCH_ALREADY_STARTED"


def test_secrets_are_not_in_logs_or_health_response(fixture: tuple[FakeClock, LobbyRegistry, TestClient], caplog) -> None:
    _clock, _registry, client = fixture
    caplog.set_level("INFO")
    created = create(client)
    assert created["host_session_token"] not in caplog.text
    assert client.get("/healthz").json() == {"status": "ok"}


def test_invalid_invite_and_rate_limit(fixture: tuple[FakeClock, LobbyRegistry, TestClient]) -> None:
    _clock, registry, client = fixture
    malformed = client.post(
        "/v1/lobbies/resolve",
        json={"invite_code": "0O1-111", "game_version": "0.1.0-dev", "protocol_version": 1},
    )
    assert malformed.json()["error"]["code"] == "INVALID_INVITE_CODE"
    create(client)
    registry.endpoint_limiters["create"].limit = 1
    limited = client.post(
        "/v1/lobbies",
        json={"game_version": "0.1.0-dev", "protocol_version": 1, "max_players": 2},
    )
    assert limited.status_code == 429
