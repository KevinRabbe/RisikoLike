# ATLAS // FRONT

ATLAS // FRONT is a desktop-first, host-authoritative private strategy match for Windows. V1 private lobbies are player-hosted and connect directly over reliable TCP; no central service is required. The release candidate contains the playable 42-territory world map, self-contained invites, reconnect/spectator lifecycle, cards, combat, timer policy, and the dark command-table UI.

## Requirements

- Windows 10/11 for the packaged build
- Godot 4.7.2 only for source development/export
- Python 3.12+ only when running the optional central-service prototype

## Run from source

```powershell
godot --path .
```

Create a normal V1 private lobby directly from the client. The host opens the
configured TCP port (default `43100`) and shows a self-contained `AF1.…`
invite. The invite contains the endpoint, session identity, join capability,
protocol version, and checksum. A second client can paste it without a
backend, Python process, account, or lobby lookup.

For the optional legacy WebRTC/signaling prototype, start the backend from `backend/`:

```powershell
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

The central backend is opt-in through the existing development APIs and is not
used by the normal Create Lobby / Join flow. `RISIKOLIKE_BACKEND_URL` is only
for that optional mode.

## Controls / How to play

- Create a direct lobby or paste an `AF1.…` invite to join one.
- For LAN or manual port forwarding, the host may advertise a local IP,
  hostname, or public endpoint in the Create Lobby screen.
- In the lobby, the host selects the ruleset and starts when players are ready.
- Click a territory during Reinforcement to select it, then place the chosen amount.
- During Attack or Fortification, select source and target territories in that order.
- Use the phase controls in the bottom action bar to confirm, end a phase, end a turn, trade cards, or surrender.
- Mouse wheel zooms the map; middle mouse pans it; the map buttons reset or change zoom.
- A disconnected client is read-only while reconnecting. If the reconnect window expires, the match ends according to the authoritative host policy.

## Tests

```powershell
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . --script res://tests/run_m13_tests.gd
godot --headless --path . --script res://tests/run_m14_tests.gd
godot --headless --path . --script res://tests/run_m15_hardening.gd
godot --headless --path . --script res://tests/run_direct_tests.gd
godot --headless --path . --script res://tests/run_direct_two_process_peer.gd
python -m pytest -q backend
```

The existing M9–M16, TCP, optional WebRTC, and backend harnesses remain part
of the release checklist. Direct-host acceptance harnesses cover no-backend
Create/Join, reconnect, host loss, malformed invites, port conflicts, and a
three-player lobby. See `docs/RELEASE_CHECKLIST.md` for the external-network
gates.

## Windows export

With Godot 4.7.2 export templates installed:

```powershell
godot --headless --path . --export-release "ATLAS FRONT // Windows" builds/windows/ATLAS_FRONT.exe
```

The preset embeds the PCK and targets x86_64. The packaged client uses the
direct-host default and does not require a development backend.

## Optional central-service configuration

The retained backend is a future/optional central-service prototype. If it is
deployed for an explicit WebRTC or service mode, copy `backend/.env.example`
into that deployment environment and set:

- `BACKEND_PUBLIC_BASE_URL=https://your-domain.example`
- `ICE_SERVERS_JSON` with production STUN/TURN entries
- `TURN_URL` and `TURN_SHARED_SECRET` for short-lived coturn credentials

Never commit real TURN secrets or session tokens. The backend stores rendezvous metadata only; the host remains authoritative for game state.

## Licensing

WebRTC native dependency notices are in `third_party/webrtc_native/`. Audio fallback tones and UI code are project-owned. The asset policy and future audio attribution requirements are recorded in `docs/AUDIO_LICENSES.md`.
