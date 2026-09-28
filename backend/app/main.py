from __future__ import annotations

import base64
import hashlib
import hmac
import json
import logging
import os
import re
import secrets
import time
import uuid
from collections import defaultdict, deque
from dataclasses import dataclass, field
from typing import Any, Callable, Deque, Dict, Iterable, Optional

from fastapi import FastAPI, Request, WebSocket, WebSocketDisconnect
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field


LOGGER = logging.getLogger("risikolike.backend")
INVITE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
INVITE_LENGTH = 6
JOIN_TOKEN_TTL_SECONDS = 60
LOBBY_TTL_SECONDS = 45
TURN_CREDENTIAL_TTL_SECONDS = 600
RECONNECT_WINDOW_SECONDS = 180
RECONNECT_AUTH_TTL_SECONDS = 30
MAX_WS_MESSAGE_BYTES = 64 * 1024
MAX_SDP_BYTES = 64 * 1024
MAX_ICE_CANDIDATE_BYTES = 16 * 1024
MAX_PENDING_JOINS = 4
MAX_PLAYERS = 5
SUPPORTED_PROTOCOL_VERSION = 1
SUPPORTED_GAME_VERSION = "0.1.0-dev"

ERROR_MESSAGES = {
    "INVALID_REQUEST": "The request is invalid.",
    "INVALID_INVITE_CODE": "The invite code is invalid.",
    "LOBBY_NOT_FOUND": "The lobby was not found.",
    "LOBBY_EXPIRED": "The lobby has expired.",
    "LOBBY_CLOSED": "The lobby is closed.",
    "LOBBY_FULL": "The lobby is full.",
    "MATCH_ALREADY_STARTED": "The match has already started.",
    "INVALID_TOKEN": "The token is invalid.",
    "TOKEN_EXPIRED": "The token has expired.",
    "TOKEN_ALREADY_USED": "The token has already been used.",
    "VERSION_MISMATCH": "The game version is incompatible.",
    "PROTOCOL_MISMATCH": "The protocol version is incompatible.",
    "RATE_LIMITED": "Too many requests.",
    "SIGNALING_UNAVAILABLE": "Signaling is unavailable.",
    "TURN_UNAVAILABLE": "TURN credentials are unavailable.",
    "RECONNECT_TOKEN_INVALID": "The reconnect credential is invalid.",
    "RECONNECT_TOKEN_EXPIRED": "The reconnect credential has expired.",
    "RECONNECT_TOKEN_REUSED": "The reconnect credential was already rotated.",
    "RECONNECT_WINDOW_EXPIRED": "The reconnect window has expired.",
    "PLAYER_ALREADY_CONNECTED": "The player is already connected.",
    "MATCH_NOT_FOUND": "The match was not found.",
    "MATCH_FINISHED": "The match has finished.",
    "HOST_UNAVAILABLE": "The host is unavailable.",
    "RECONNECT_FAILED": "Reconnect authorization failed.",
    "UNAUTHENTICATED": "Signaling authentication is required.",
    "MESSAGE_TOO_LARGE": "The signaling message is too large.",
    "INTERNAL_ERROR": "An internal error occurred.",
}


class BackendError(Exception):
    def __init__(self, code: str, status_code: int = 400) -> None:
        self.code = code
        self.status_code = status_code
        super().__init__(ERROR_MESSAGES.get(code, code))


def error_payload(code: str) -> Dict[str, Dict[str, str]]:
    return {"error": {"code": code, "message": ERROR_MESSAGES.get(code, code)}}


def normalize_invite_code(value: str) -> str:
    if not isinstance(value, str):
        raise BackendError("INVALID_INVITE_CODE")
    compact = re.sub(r"[\s-]", "", value).upper()
    if len(compact) != INVITE_LENGTH or any(char not in INVITE_ALPHABET for char in compact):
        raise BackendError("INVALID_INVITE_CODE")
    return f"{compact[:3]}-{compact[3:]}"


def _hash_secret(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def _secret() -> str:
    return secrets.token_urlsafe(32)


def _utc_iso(timestamp: float) -> str:
    from datetime import datetime, timezone

    return datetime.fromtimestamp(timestamp, tz=timezone.utc).isoformat().replace("+00:00", "Z")


def _parse_json_env(name: str, default: Any) -> Any:
    raw = os.getenv(name, "")
    if not raw:
        return default
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        LOGGER.warning("invalid_json_configuration name=%s", name)
        return default


class CreateLobbyRequest(BaseModel):
    game_version: str = Field(min_length=1, max_length=32)
    protocol_version: int
    max_players: int


class ResolveLobbyRequest(BaseModel):
    invite_code: str = Field(min_length=1, max_length=32)
    game_version: str = Field(min_length=1, max_length=32)
    protocol_version: int


class TokenRequest(BaseModel):
    host_session_token: Optional[str] = Field(default=None, min_length=1, max_length=256)


class ReconnectCredentialRequest(BaseModel):
    player_id: str = Field(min_length=1, max_length=32)


class ReconnectAuthorizeRequest(BaseModel):
    match_id: str = Field(min_length=1, max_length=128)
    player_id: str = Field(min_length=1, max_length=32)
    reconnect_token: str = Field(min_length=1, max_length=256)
    protocol_version: int
    game_version: str = Field(min_length=1, max_length=32)


class SignalMessage(BaseModel):
    type: str = Field(min_length=1, max_length=64)
    lobby_id: Optional[str] = Field(default=None, max_length=128)
    protocol_version: Optional[int] = None
    game_version: Optional[str] = Field(default=None, max_length=32)
    host_session_token: Optional[str] = Field(default=None, max_length=256)
    join_token: Optional[str] = Field(default=None, max_length=256)
    reconnect_ticket: Optional[str] = Field(default=None, max_length=256)
    player_id: Optional[str] = Field(default=None, max_length=32)
    connection_generation: Optional[int] = None
    target_peer_id: Optional[str] = Field(default=None, max_length=128)
    payload: Optional[Dict[str, Any]] = None


@dataclass
class PendingJoin:
    token_hash: str
    expires_at: float
    used: bool = False


@dataclass
class ReconnectTicket:
    token_hash: str
    expires_at: float
    generation: int
    used: bool = False


@dataclass
class ReconnectCredential:
    match_id: str
    player_id: str
    token_hash: str
    expires_at: float
    generation: int = 1
    active_peer_id: Optional[str] = None
    invalidated_token_hashes: set[str] = field(default_factory=set)
    tickets: Dict[str, ReconnectTicket] = field(default_factory=dict)


@dataclass
class SignalingPeer:
    peer_id: str
    role: str
    websocket: WebSocket
    lobby_id: str
    player_id: str = ""
    connection_generation: int = 0


@dataclass
class LobbyRecord:
    lobby_id: str
    invite_code: str
    host_session_token_hash: str
    status: str
    protocol_version: int
    game_version: str
    max_players: int
    created_at: float
    last_seen_at: float
    expires_at: float
    pending_join_tokens: Dict[str, PendingJoin] = field(default_factory=dict)
    peers: Dict[str, SignalingPeer] = field(default_factory=dict)
    host_peer_id: Optional[str] = None
    match_id: str = ""
    reconnect_credentials: Dict[str, ReconnectCredential] = field(default_factory=dict)

    @property
    def guest_peer_count(self) -> int:
        return sum(1 for peer in self.peers.values() if peer.role == "guest")

    def pending_join_count(self, now: float) -> int:
        return sum(1 for token in self.pending_join_tokens.values() if not token.used and token.expires_at > now)


class RateLimiter:
    def __init__(self, limit: int, window_seconds: float, clock: Callable[[], float]) -> None:
        self.limit = limit
        self.window_seconds = window_seconds
        self.clock = clock
        self._events: Dict[str, Deque[float]] = defaultdict(deque)

    def allow(self, key: str) -> bool:
        now = self.clock()
        events = self._events[key]
        while events and now - events[0] >= self.window_seconds:
            events.popleft()
        if len(events) >= self.limit:
            return False
        events.append(now)
        return True


class LobbyRegistry:
    def __init__(self, clock: Callable[[], float] = time.time) -> None:
        self.clock = clock
        self.lobbies: Dict[str, LobbyRecord] = {}
        self.codes: Dict[str, LobbyRecord] = {}
        self.retired_codes: Dict[str, str] = {}
        self.endpoint_limiters: Dict[str, RateLimiter] = {}

    def cleanup(self) -> None:
        now = self.clock()
        for lobby in list(self.lobbies.values()):
            if lobby.status in {"OPEN", "STARTING"} and lobby.expires_at <= now:
                lobby.status = "EXPIRED"
                self.lobbies.pop(lobby.lobby_id, None)
                self.codes.pop(lobby.invite_code, None)
                self.retired_codes[lobby.invite_code] = "LOBBY_EXPIRED"
                LOGGER.info("lobby_expired lobby_id=%s", lobby.lobby_id)
            elif lobby.status == "IN_GAME" and lobby.expires_at <= now:
                # Keep the small match metadata record long enough to return a
                # precise reconnect-window error without retaining gameplay state.
                lobby.status = "EXPIRED"
                self.codes.pop(lobby.invite_code, None)
                self.retired_codes[lobby.invite_code] = "LOBBY_EXPIRED"
                LOGGER.info("match_reconnect_window_expired lobby_id=%s", lobby.lobby_id)

    def _new_invite_code(self) -> str:
        for _ in range(100):
            compact = "".join(secrets.choice(INVITE_ALPHABET) for _ in range(INVITE_LENGTH))
            code = f"{compact[:3]}-{compact[3:]}"
            if code not in self.codes and code not in self.retired_codes:
                return code
        raise BackendError("INTERNAL_ERROR", 500)

    def create_lobby(self, game_version: str, protocol_version: int, max_players: int) -> tuple[LobbyRecord, str]:
        self.cleanup()
        if not 2 <= max_players <= MAX_PLAYERS:
            raise BackendError("INVALID_REQUEST")
        _validate_versions(game_version, protocol_version)
        now = self.clock()
        lobby_id = uuid.uuid4().hex
        token = _secret()
        code = self._new_invite_code()
        lobby = LobbyRecord(
            lobby_id=lobby_id,
            invite_code=code,
            host_session_token_hash=_hash_secret(token),
            status="OPEN",
            protocol_version=protocol_version,
            game_version=game_version,
            max_players=max_players,
            created_at=now,
            last_seen_at=now,
            expires_at=now + LOBBY_TTL_SECONDS,
        )
        self.lobbies[lobby_id] = lobby
        self.codes[code] = lobby
        LOGGER.info("lobby_created lobby_id=%s max_players=%d", lobby_id, max_players)
        return lobby, token

    def resolve(self, invite_code: str, game_version: str, protocol_version: int) -> tuple[LobbyRecord, str, float]:
        self.cleanup()
        code = normalize_invite_code(invite_code)
        lobby = self.codes.get(code)
        if lobby is None:
            retired_status = self.retired_codes.get(code)
            if retired_status:
                raise BackendError(retired_status, 410)
            raise BackendError("LOBBY_NOT_FOUND", 404)
        if lobby.status == "EXPIRED":
            raise BackendError("LOBBY_EXPIRED", 410)
        if lobby.status == "CLOSED":
            raise BackendError("LOBBY_CLOSED", 410)
        if lobby.status in {"STARTING", "IN_GAME"}:
            raise BackendError("MATCH_ALREADY_STARTED", 409)
        _validate_versions(game_version, protocol_version, lobby)
        if 1 + lobby.guest_peer_count + lobby.pending_join_count(self.clock()) >= lobby.max_players:
            raise BackendError("LOBBY_FULL", 409)
        now = self.clock()
        token = _secret()
        token_hash = _hash_secret(token)
        lobby.pending_join_tokens[token_hash] = PendingJoin(token_hash=token_hash, expires_at=now + JOIN_TOKEN_TTL_SECONDS)
        return lobby, token, now + JOIN_TOKEN_TTL_SECONDS

    def authenticate_host(self, lobby_id: str, token: str) -> LobbyRecord:
        self.cleanup()
        lobby = self.lobbies.get(lobby_id)
        if lobby is None:
            raise BackendError("LOBBY_NOT_FOUND", 404)
        if lobby.status == "EXPIRED":
            raise BackendError("LOBBY_EXPIRED", 410)
        if lobby.status == "CLOSED":
            raise BackendError("LOBBY_CLOSED", 410)
        if not token or not hmac.compare_digest(lobby.host_session_token_hash, _hash_secret(token)):
            raise BackendError("INVALID_TOKEN", 401)
        return lobby

    def heartbeat(self, lobby_id: str, token: str) -> LobbyRecord:
        lobby = self.authenticate_host(lobby_id, token)
        now = self.clock()
        lobby.last_seen_at = now
        lobby.expires_at = now + (RECONNECT_WINDOW_SECONDS if lobby.status == "IN_GAME" else LOBBY_TTL_SECONDS)
        LOGGER.info("lobby_heartbeat lobby_id=%s", lobby_id)
        return lobby

    def close(self, lobby_id: str, token: str) -> LobbyRecord:
        lobby = self.authenticate_host(lobby_id, token)
        lobby.status = "CLOSED"
        self.lobbies.pop(lobby_id, None)
        self.codes.pop(lobby.invite_code, None)
        self.retired_codes[lobby.invite_code] = "LOBBY_CLOSED"
        LOGGER.info("lobby_closed lobby_id=%s", lobby_id)
        return lobby

    def mark_started(self, lobby_id: str, token: str) -> LobbyRecord:
        lobby = self.authenticate_host(lobby_id, token)
        if lobby.status != "OPEN":
            raise BackendError("MATCH_ALREADY_STARTED", 409)
        lobby.status = "IN_GAME"
        lobby.match_id = lobby.lobby_id
        lobby.expires_at = self.clock() + RECONNECT_WINDOW_SECONDS
        LOGGER.info("lobby_started lobby_id=%s", lobby_id)
        return lobby

    def issue_reconnect_credential(self, lobby_id: str, token: str, player_id: str) -> tuple[LobbyRecord, str, ReconnectCredential]:
        lobby = self.authenticate_host(lobby_id, token)
        if lobby.status != "IN_GAME":
            raise BackendError("MATCH_ALREADY_STARTED", 409)
        if not player_id or player_id == "P1":
            raise BackendError("INVALID_REQUEST")
        now = self.clock()
        old = lobby.reconnect_credentials.get(player_id)
        if old is not None and old.active_peer_id is not None:
            raise BackendError("PLAYER_ALREADY_CONNECTED", 409)
        generation = old.generation + 1 if old is not None else 1
        reconnect_token = _secret()
        credential = ReconnectCredential(
            match_id=lobby.match_id or lobby.lobby_id,
            player_id=player_id,
            token_hash=_hash_secret(reconnect_token),
            expires_at=max(lobby.expires_at, now + RECONNECT_WINDOW_SECONDS),
            generation=generation,
        )
        lobby.reconnect_credentials[player_id] = credential
        lobby.expires_at = max(lobby.expires_at, credential.expires_at)
        return lobby, reconnect_token, credential

    def authorize_reconnect(
        self,
        match_id: str,
        player_id: str,
        reconnect_token: str,
        game_version: str,
        protocol_version: int,
    ) -> tuple[LobbyRecord, str, str, ReconnectCredential]:
        self.cleanup()
        lobby = self.lobbies.get(match_id)
        if lobby is None:
            raise BackendError("MATCH_NOT_FOUND", 404)
        if lobby.status != "IN_GAME":
            if lobby.status in {"CLOSED", "EXPIRED"}:
                raise BackendError("RECONNECT_WINDOW_EXPIRED", 410)
            raise BackendError("MATCH_NOT_FOUND", 404)
        _validate_versions(game_version, protocol_version, lobby)
        credential = lobby.reconnect_credentials.get(player_id)
        if credential is None:
            raise BackendError("RECONNECT_TOKEN_INVALID", 401)
        if credential.active_peer_id is not None:
            raise BackendError("PLAYER_ALREADY_CONNECTED", 409)
        if credential.expires_at <= self.clock():
            raise BackendError("RECONNECT_WINDOW_EXPIRED", 410)
        supplied_hash = _hash_secret(reconnect_token or "")
        if supplied_hash != credential.token_hash:
            if supplied_hash in credential.invalidated_token_hashes:
                raise BackendError("RECONNECT_TOKEN_REUSED", 401)
            raise BackendError("RECONNECT_TOKEN_INVALID", 401)
        credential.invalidated_token_hashes.add(credential.token_hash)
        new_token = _secret()
        credential.token_hash = _hash_secret(new_token)
        credential.generation += 1
        ticket = _secret()
        credential.tickets[_hash_secret(ticket)] = ReconnectTicket(
            token_hash=_hash_secret(ticket),
            expires_at=self.clock() + RECONNECT_AUTH_TTL_SECONDS,
            generation=credential.generation,
        )
        return lobby, ticket, new_token, credential

    def consume_reconnect_ticket(self, match_id: str, player_id: str, ticket_value: str) -> tuple[LobbyRecord, ReconnectCredential]:
        self.cleanup()
        lobby = self.lobbies.get(match_id)
        if lobby is None:
            raise BackendError("MATCH_NOT_FOUND", 404)
        credential = lobby.reconnect_credentials.get(player_id)
        if credential is None:
            raise BackendError("RECONNECT_TOKEN_INVALID", 401)
        ticket_hash = _hash_secret(ticket_value or "")
        ticket = credential.tickets.get(ticket_hash)
        if ticket is None:
            raise BackendError("RECONNECT_TOKEN_INVALID", 401)
        if ticket.used:
            raise BackendError("RECONNECT_TOKEN_REUSED", 401)
        if ticket.expires_at <= self.clock():
            raise BackendError("RECONNECT_TOKEN_EXPIRED", 401)
        if credential.active_peer_id is not None:
            raise BackendError("PLAYER_ALREADY_CONNECTED", 409)
        ticket.used = True
        return lobby, credential

    def activate_reconnect_peer(self, credential: ReconnectCredential, peer_id: str) -> None:
        credential.active_peer_id = peer_id

    def consume_join_token(self, lobby_id: str, token: str) -> LobbyRecord:
        self.cleanup()
        lobby = self.lobbies.get(lobby_id)
        if lobby is None:
            raise BackendError("LOBBY_NOT_FOUND", 404)
        token_hash = _hash_secret(token or "")
        pending = lobby.pending_join_tokens.get(token_hash)
        if pending is None:
            raise BackendError("INVALID_TOKEN", 401)
        if pending.used:
            raise BackendError("TOKEN_ALREADY_USED", 401)
        if pending.expires_at <= self.clock():
            raise BackendError("TOKEN_EXPIRED", 401)
        if lobby.status != "OPEN":
            raise BackendError("MATCH_ALREADY_STARTED" if lobby.status in {"STARTING", "IN_GAME"} else "LOBBY_CLOSED", 409)
        if 1 + lobby.guest_peer_count >= lobby.max_players:
            raise BackendError("LOBBY_FULL", 409)
        pending.used = True
        return lobby

    def add_peer(self, lobby: LobbyRecord, peer: SignalingPeer) -> None:
        lobby.peers[peer.peer_id] = peer
        if peer.role == "host":
            lobby.host_peer_id = peer.peer_id

    def remove_peer(self, lobby: LobbyRecord, peer_id: str) -> Optional[SignalingPeer]:
        peer = lobby.peers.pop(peer_id, None)
        if peer and peer_id == lobby.host_peer_id:
            lobby.host_peer_id = None
        if peer and peer.player_id:
            credential = lobby.reconnect_credentials.get(peer.player_id)
            if credential is not None and credential.active_peer_id == peer_id:
                credential.active_peer_id = None
        return peer


def _validate_versions(game_version: str, protocol_version: int, lobby: Optional[LobbyRecord] = None) -> None:
    expected_protocol = lobby.protocol_version if lobby else SUPPORTED_PROTOCOL_VERSION
    expected_game = lobby.game_version if lobby else SUPPORTED_GAME_VERSION
    if protocol_version != expected_protocol:
        raise BackendError("PROTOCOL_MISMATCH", 409)
    if game_version != expected_game:
        raise BackendError("VERSION_MISMATCH", 409)


def _token_from_request(request: Request, body: Optional[TokenRequest]) -> str:
    header = request.headers.get("authorization", "")
    if header.lower().startswith("bearer "):
        return header[7:].strip()
    header_token = request.headers.get("x-host-session-token", "").strip()
    if header_token:
        return header_token
    return (body.host_session_token if body else None) or ""


def _client_key(request: Request, suffix: str) -> str:
    host = request.client.host if request.client else "unknown"
    return f"{suffix}:{host}"


def _ensure_rate(registry: LobbyRegistry, key: str, limit: int = 60) -> None:
    endpoint, _, client = key.partition(":")
    limiter = registry.endpoint_limiters.setdefault(endpoint, RateLimiter(limit=limit, window_seconds=60, clock=registry.clock))
    if not limiter.allow(f"{endpoint}:{client}"):
        raise BackendError("RATE_LIMITED", 429)


def create_app(registry: Optional[LobbyRegistry] = None) -> FastAPI:
    registry = registry or LobbyRegistry()
    app = FastAPI(title="RisikoLike Backend", version="0.1.0", docs_url="/docs")
    app.state.registry = registry
    app.state.public_base_url = os.getenv("BACKEND_PUBLIC_BASE_URL", "").rstrip("/")
    app.state.ice_servers = _parse_json_env("ICE_SERVERS_JSON", [])

    @app.exception_handler(BackendError)
    async def backend_error_handler(_request: Request, exc: BackendError) -> JSONResponse:
        return JSONResponse(status_code=exc.status_code, content=error_payload(exc.code))

    @app.exception_handler(RequestValidationError)
    async def validation_error_handler(_request: Request, exc: RequestValidationError) -> JSONResponse:
        LOGGER.warning(
            "request_validation_failed path=%s fields=%s",
            _request.url.path,
            [
                {
                    "location": error.get("loc", []),
                    "type": error.get("type", ""),
                }
                for error in exc.errors()
            ],
        )
        return JSONResponse(status_code=422, content=error_payload("INVALID_REQUEST"))

    @app.middleware("http")
    async def body_size_limit(request: Request, call_next):
        content_length = request.headers.get("content-length")
        if content_length and int(content_length) > MAX_WS_MESSAGE_BYTES:
            return JSONResponse(status_code=413, content=error_payload("MESSAGE_TOO_LARGE"))
        return await call_next(request)

    def signaling_url(request: Request) -> str:
        base = app.state.public_base_url or str(request.base_url).rstrip("/")
        if base.startswith("https://"):
            base = "wss://" + base[len("https://") :]
        elif base.startswith("http://"):
            base = "ws://" + base[len("http://") :]
        return base + "/v1/signaling"

    @app.get("/healthz")
    async def healthz() -> Dict[str, str]:
        return {"status": "ok"}

    @app.post("/v1/lobbies")
    async def create_lobby(request: Request, payload: CreateLobbyRequest) -> Dict[str, Any]:
        _ensure_rate(registry, _client_key(request, "create"), limit=20)
        lobby, token = registry.create_lobby(payload.game_version, payload.protocol_version, payload.max_players)
        return {
            "lobby_id": lobby.lobby_id,
            "invite_code": lobby.invite_code,
            "host_session_token": token,
            "expires_at": _utc_iso(lobby.expires_at),
            "signaling_url": signaling_url(request),
            "ice_servers": app.state.ice_servers,
        }

    @app.post("/v1/lobbies/resolve")
    async def resolve_lobby(request: Request, payload: ResolveLobbyRequest) -> Dict[str, Any]:
        _ensure_rate(registry, _client_key(request, "resolve"), limit=60)
        lobby, token, expires_at = registry.resolve(payload.invite_code, payload.game_version, payload.protocol_version)
        return {
            "lobby_id": lobby.lobby_id,
            "join_token": token,
            "join_token_expires_at": _utc_iso(expires_at),
            "signaling_url": signaling_url(request),
            "ice_servers": app.state.ice_servers,
        }

    @app.post("/v1/lobbies/{lobby_id}/heartbeat")
    async def heartbeat(request: Request, lobby_id: str, body: Optional[TokenRequest] = None) -> Dict[str, Any]:
        _ensure_rate(registry, _client_key(request, "heartbeat"), limit=120)
        lobby = registry.heartbeat(lobby_id, _token_from_request(request, body))
        return {"lobby_id": lobby.lobby_id, "expires_at": _utc_iso(lobby.expires_at)}

    @app.post("/v1/lobbies/{lobby_id}/close")
    async def close_lobby(request: Request, lobby_id: str, body: Optional[TokenRequest] = None) -> Dict[str, Any]:
        _ensure_rate(registry, _client_key(request, "close"), limit=30)
        lobby = registry.close(lobby_id, _token_from_request(request, body))
        return {"lobby_id": lobby.lobby_id, "status": "CLOSED"}

    @app.post("/v1/lobbies/{lobby_id}/started")
    async def started_lobby(request: Request, lobby_id: str, body: Optional[TokenRequest] = None) -> Dict[str, Any]:
        _ensure_rate(registry, _client_key(request, "started"), limit=30)
        lobby = registry.mark_started(lobby_id, _token_from_request(request, body))
        return {"lobby_id": lobby.lobby_id, "status": lobby.status}

    @app.post("/v1/lobbies/{lobby_id}/reconnect-credentials")
    async def reconnect_credentials(
        request: Request,
        lobby_id: str,
        payload: ReconnectCredentialRequest,
    ) -> Dict[str, Any]:
        _ensure_rate(registry, _client_key(request, "reconnect_credential"), limit=60)
        lobby, reconnect_token, credential = registry.issue_reconnect_credential(
            lobby_id,
            _token_from_request(request, None),
            payload.player_id,
        )
        return {
            "match_id": lobby.match_id or lobby.lobby_id,
            "player_id": credential.player_id,
            "reconnect_token": reconnect_token,
            "generation": credential.generation,
            "expires_at": _utc_iso(credential.expires_at),
        }

    @app.post("/v1/matches/reconnect")
    async def authorize_reconnect(request: Request, payload: ReconnectAuthorizeRequest) -> Dict[str, Any]:
        _ensure_rate(registry, _client_key(request, "reconnect"), limit=60)
        lobby, ticket, rotated_token, credential = registry.authorize_reconnect(
            payload.match_id,
            payload.player_id,
            payload.reconnect_token,
            payload.game_version,
            payload.protocol_version,
        )
        return {
            "match_id": lobby.match_id or lobby.lobby_id,
            "player_id": credential.player_id,
            "reconnect_token": rotated_token,
            "reconnect_ticket": ticket,
            "generation": credential.generation,
            "expires_at": _utc_iso(credential.expires_at),
            "signaling_url": signaling_url(request),
            "ice_servers": app.state.ice_servers,
        }

    @app.post("/v1/lobbies/{lobby_id}/turn-credentials")
    async def turn_credentials(request: Request, lobby_id: str, body: Optional[TokenRequest] = None) -> Dict[str, Any]:
        _ensure_rate(registry, _client_key(request, "turn"), limit=30)
        registry.authenticate_host(lobby_id, _token_from_request(request, body))
        turn_url = os.getenv("TURN_URL", "").strip()
        shared_secret = os.getenv("TURN_SHARED_SECRET", "").strip()
        if not turn_url or not shared_secret:
            raise BackendError("TURN_UNAVAILABLE", 503)
        expires_at = int(registry.clock()) + TURN_CREDENTIAL_TTL_SECONDS
        username = f"{expires_at}:risikolike"
        password = base64.b64encode(hmac.new(shared_secret.encode(), username.encode(), hashlib.sha1).digest()).decode()
        return {"ice_servers": [{"urls": [turn_url], "username": username, "credential": password}], "expires_at": _utc_iso(expires_at)}

    @app.websocket("/v1/signaling")
    async def signaling(websocket: WebSocket) -> None:
        await websocket.accept()
        peer: Optional[SignalingPeer] = None
        lobby: Optional[LobbyRecord] = None
        try:
            while True:
                raw = await websocket.receive_text()
                if len(raw.encode("utf-8")) > MAX_WS_MESSAGE_BYTES:
                    await websocket.send_json({"type": "ERROR", **error_payload("MESSAGE_TOO_LARGE")})
                    await websocket.close(code=1009)
                    return
                client_key = f"ws:{websocket.client.host if websocket.client else 'unknown'}"
                _ensure_rate(registry, client_key, limit=180)
                try:
                    message = SignalMessage.model_validate(json.loads(raw))
                except (json.JSONDecodeError, ValueError):
                    await websocket.send_json({"type": "ERROR", **error_payload("INVALID_REQUEST")})
                    continue
                msg_type = message.type.upper()
                if peer is None:
                    if msg_type not in {"AUTH_HOST", "AUTH_JOIN", "AUTH_RECONNECT"}:
                        await websocket.send_json({"type": "AUTH_ERROR", **error_payload("UNAUTHENTICATED")})
                        continue
                    if not message.lobby_id:
                        await websocket.send_json({"type": "AUTH_ERROR", **error_payload("INVALID_REQUEST")})
                        continue
                    if message.protocol_version is not None and message.game_version is not None:
                        try:
                            _validate_versions(message.game_version, message.protocol_version)
                        except BackendError as exc:
                            await websocket.send_json({"type": "AUTH_ERROR", **error_payload(exc.code)})
                            continue
                    try:
                        if msg_type == "AUTH_HOST":
                            lobby = registry.authenticate_host(message.lobby_id, message.host_session_token or "")
                            if lobby.host_peer_id is not None:
                                raise BackendError("SIGNALING_UNAVAILABLE", 409)
                            peer = SignalingPeer(uuid.uuid4().hex, "host", websocket, lobby.lobby_id)
                        elif msg_type == "AUTH_JOIN":
                            lobby = registry.lobbies.get(message.lobby_id)
                            if lobby is None:
                                raise BackendError("LOBBY_NOT_FOUND", 404)
                            lobby = registry.consume_join_token(message.lobby_id, message.join_token or "")
                            peer = SignalingPeer(uuid.uuid4().hex, "guest", websocket, lobby.lobby_id)
                        else:
                            if not message.player_id or message.connection_generation is None:
                                raise BackendError("INVALID_REQUEST")
                            lobby, credential = registry.consume_reconnect_ticket(
                                message.lobby_id,
                                message.player_id,
                                message.reconnect_ticket or "",
                            )
                            if lobby.host_peer_id is None or lobby.host_peer_id not in lobby.peers:
                                raise BackendError("HOST_UNAVAILABLE", 503)
                            if credential.generation != int(message.connection_generation):
                                raise BackendError("RECONNECT_FAILED", 409)
                            peer = SignalingPeer(
                                uuid.uuid4().hex,
                                "reconnect",
                                websocket,
                                lobby.lobby_id,
                                credential.player_id,
                                credential.generation,
                            )
                            registry.activate_reconnect_peer(credential, peer.peer_id)
                        registry.add_peer(lobby, peer)
                    except BackendError as exc:
                        await websocket.send_json({"type": "AUTH_ERROR", **error_payload(exc.code)})
                        continue
                    auth_ok = {"type": "AUTH_OK", "peer_id": peer.peer_id, "lobby_id": lobby.lobby_id}
                    if peer.player_id:
                        auth_ok["player_id"] = peer.player_id
                        auth_ok["connection_generation"] = peer.connection_generation
                    await websocket.send_json(auth_ok)
                    if peer.role == "guest" and lobby.host_peer_id and lobby.host_peer_id in lobby.peers:
                        await _send(lobby.peers[lobby.host_peer_id].websocket, {"type": "PEER_JOINING", "peer_id": peer.peer_id})
                    elif peer.role == "reconnect" and lobby.host_peer_id and lobby.host_peer_id in lobby.peers:
                        await _send(
                            lobby.peers[lobby.host_peer_id].websocket,
                            {
                                "type": "PEER_RECONNECTING",
                                "peer_id": peer.peer_id,
                                "player_id": peer.player_id,
                                "connection_generation": peer.connection_generation,
                            },
                        )
                    continue
                if msg_type == "PING":
                    await websocket.send_json({"type": "PONG"})
                elif msg_type == "SIGNALING_CLOSE":
                    await websocket.close(code=1000)
                    return
                elif msg_type in {"WEBRTC_OFFER", "WEBRTC_ANSWER", "ICE_CANDIDATE", "RECONNECT_REJECTED"}:
                    payload = message.payload or {}
                    payload_size = len(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
                    limit = MAX_ICE_CANDIDATE_BYTES if msg_type == "ICE_CANDIDATE" else MAX_SDP_BYTES
                    if payload_size > limit:
                        await websocket.send_json({"type": "ERROR", **error_payload("MESSAGE_TOO_LARGE")})
                        continue
                    await _relay(lobby, peer, msg_type, payload, message.target_peer_id)
                else:
                    await websocket.send_json({"type": "ERROR", **error_payload("INVALID_REQUEST")})
        except WebSocketDisconnect:
            pass
        finally:
            if peer is not None and lobby is not None:
                registry.remove_peer(lobby, peer.peer_id)
                for other in list(lobby.peers.values()):
                    try:
                        await _send(other.websocket, {"type": "PEER_LEFT", "peer_id": peer.peer_id})
                    except Exception:
                        pass
                LOGGER.info("signaling_peer_left lobby_id=%s peer_id=%s role=%s", lobby.lobby_id, peer.peer_id, peer.role)

    return app


async def _send(websocket: WebSocket, message: Dict[str, Any]) -> None:
    await websocket.send_json(message)


async def _relay(
    lobby: LobbyRecord,
    sender: SignalingPeer,
    msg_type: str,
    payload: Dict[str, Any],
    target_peer_id: Optional[str],
) -> None:
    if target_peer_id:
        target = lobby.peers.get(target_peer_id)
        targets = [target] if target and target.peer_id != sender.peer_id else []
    else:
        targets = [peer for peer in lobby.peers.values() if peer.peer_id != sender.peer_id]
    envelope = {"type": msg_type, "from_peer_id": sender.peer_id, "payload": payload}
    for target in targets:
        try:
            await _send(target.websocket, envelope)
        except Exception:
            pass


app = create_app()
