# ATLAS // FRONT

ATLAS // FRONT is a desktop-first, host-authoritative private strategy match for Windows. The current release candidate contains the playable 42-territory world map, invite-code lobbies, WebRTC peer sessions, reconnect/spectator lifecycle, cards, combat, timer policy, and the dark command-table UI.

## Requirements

- Windows 10/11 for the packaged build
- Godot 4.7.2 only for source development/export
- Python 3.12+ for the rendezvous backend

## Run from source

```powershell
godot --path .
```

For a local online-signaling session, start the backend from `backend/`:

```powershell
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

The client defaults to `http://127.0.0.1:8000`. Set `RISIKOLIKE_BACKEND_URL` to an HTTPS backend for a deployed environment. The backend's public signaling URL is derived from `BACKEND_PUBLIC_BASE_URL`.

## Controls / How to play

- Create a lobby or enter an invite code to join one.
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
python -m pytest -q backend
```

The existing M9–M11 and TCP/WebRTC harnesses remain part of the release checklist. See `docs/RELEASE_CHECKLIST.md` for the external-network gates.

## Windows export

With Godot 4.7.2 export templates installed:

```powershell
godot --headless --path . --export-release "ATLAS FRONT // Windows" builds/windows/ATLAS_FRONT.exe
```

The preset embeds the PCK and targets x86_64. Do not run an exported build with development backend defaults for public play.

## Backend production configuration

Copy `backend/.env.example` into the deployment environment and set:

- `BACKEND_PUBLIC_BASE_URL=https://your-domain.example`
- `ICE_SERVERS_JSON` with production STUN/TURN entries
- `TURN_URL` and `TURN_SHARED_SECRET` for short-lived coturn credentials

Never commit real TURN secrets or session tokens. The backend stores rendezvous metadata only; the host remains authoritative for game state.

## Licensing

WebRTC native dependency notices are in `third_party/webrtc_native/`. Audio fallback tones and UI code are project-owned. The asset policy and future audio attribution requirements are recorded in `docs/AUDIO_LICENSES.md`.
