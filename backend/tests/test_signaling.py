from __future__ import annotations

from fastapi.testclient import TestClient

from app.main import MAX_WS_MESSAGE_BYTES, LobbyRegistry, create_app


class Clock:
    def __init__(self) -> None:
        self.value = 1_000.0

    def __call__(self) -> float:
        return self.value


def setup() -> tuple[TestClient, dict, dict]:
    registry = LobbyRegistry(clock=Clock())
    client = TestClient(create_app(registry))
    created = client.post(
        "/v1/lobbies", json={"game_version": "0.1.0", "protocol_version": 1, "max_players": 2}
    ).json()
    resolved = client.post(
        "/v1/lobbies/resolve",
        json={"invite_code": created["invite_code"], "game_version": "0.1.0", "protocol_version": 1},
    ).json()
    return client, created, resolved


def test_host_join_auth_and_offer_answer_ice_relay() -> None:
    client, created, resolved = setup()
    with client.websocket_connect("/v1/signaling") as host:
        host.send_json(
            {
                "type": "AUTH_HOST",
                "lobby_id": created["lobby_id"],
                "host_session_token": created["host_session_token"],
                "protocol_version": 1,
                "game_version": "0.1.0",
            }
        )
        host_auth = host.receive_json()
        assert host_auth["type"] == "AUTH_OK"
        host_peer_id = host_auth["peer_id"]
        with client.websocket_connect("/v1/signaling") as guest:
            guest.send_json(
                {
                    "type": "AUTH_JOIN",
                    "lobby_id": resolved["lobby_id"],
                    "join_token": resolved["join_token"],
                    "protocol_version": 1,
                    "game_version": "0.1.0",
                }
            )
            guest_auth = guest.receive_json()
            assert guest_auth["type"] == "AUTH_OK"
            guest_peer_id = guest_auth["peer_id"]
            assert host.receive_json() == {"type": "PEER_JOINING", "peer_id": guest_peer_id}
            guest.send_json({"type": "WEBRTC_OFFER", "target_peer_id": host_peer_id, "payload": {"sdp": "offer"}})
            offer = host.receive_json()
            assert offer["type"] == "WEBRTC_OFFER"
            assert offer["from_peer_id"] == guest_peer_id
            assert offer["payload"] == {"sdp": "offer"}
            host.send_json({"type": "WEBRTC_ANSWER", "target_peer_id": guest_peer_id, "payload": {"sdp": "answer"}})
            answer = guest.receive_json()
            assert answer["type"] == "WEBRTC_ANSWER"
            assert answer["from_peer_id"] == host_peer_id
            host.send_json({"type": "ICE_CANDIDATE", "target_peer_id": guest_peer_id, "payload": {"candidate": "candidate"}})
            candidate = guest.receive_json()
            assert candidate["type"] == "ICE_CANDIDATE"
            assert candidate["payload"] == {"candidate": "candidate"}


def test_signaling_rejects_unauthenticated_and_replayed_join_token() -> None:
    client, created, resolved = setup()
    with client.websocket_connect("/v1/signaling") as first:
        first.send_json({"type": "WEBRTC_OFFER", "payload": {"sdp": "offer"}})
        assert first.receive_json()["error"]["code"] == "UNAUTHENTICATED"
        first.send_json({"type": "AUTH_JOIN", "lobby_id": resolved["lobby_id"], "join_token": resolved["join_token"]})
        assert first.receive_json()["type"] == "AUTH_OK"
    with client.websocket_connect("/v1/signaling") as replay:
        replay.send_json({"type": "AUTH_JOIN", "lobby_id": created["lobby_id"], "join_token": resolved["join_token"]})
        assert replay.receive_json()["error"]["code"] == "TOKEN_ALREADY_USED"


def test_signaling_rejects_bad_host_token_and_protocol() -> None:
    client, created, _resolved = setup()
    with client.websocket_connect("/v1/signaling") as socket:
        socket.send_json({"type": "AUTH_HOST", "lobby_id": created["lobby_id"], "host_session_token": "bad"})
        assert socket.receive_json()["error"]["code"] == "INVALID_TOKEN"
        socket.send_json(
            {
                "type": "AUTH_HOST",
                "lobby_id": created["lobby_id"],
                "host_session_token": created["host_session_token"],
                "protocol_version": 999,
                "game_version": "0.1.0",
            }
        )
        assert socket.receive_json()["error"]["code"] == "PROTOCOL_MISMATCH"


def test_signaling_rejects_oversized_message() -> None:
    client, _created, _resolved = setup()
    with client.websocket_connect("/v1/signaling") as socket:
        socket.send_text("x" * (MAX_WS_MESSAGE_BYTES + 1))
        assert socket.receive_json()["error"]["code"] == "MESSAGE_TOO_LARGE"
