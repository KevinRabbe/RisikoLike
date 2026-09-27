# RisikoLike Backend

Der Backend-Prozess ist ein kurzlebiger Rendezvous- und WebRTC-Signaling-Service. Er speichert keinen Game State, keine Territorien, keine Truppen und keine Kartenhände. Die eigentliche Partie bleibt beim Godot-Host autoritativ.

## Voraussetzungen

- Python 3.12 oder neuer
- optional Docker für einen späteren lokalen coturn-Test

## Setup und Start

```powershell
py -3.12 -m venv .venv
.\\.venv\\Scripts\\Activate.ps1
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Die lokale API ist unter `http://127.0.0.1:8000` erreichbar. Für Godot wird die Signaling-Adresse als `ws://127.0.0.1:8000/v1/signaling` zurückgegeben. In einer TLS-Umgebung wird aus `BACKEND_PUBLIC_BASE_URL=https://...` automatisch eine `wss://...`-Adresse.

## Tests

```powershell
python -m pytest -q
```

Die Tests verwenden eine kontrollierte Uhr und warten nicht 45 Sekunden auf Lobby-TTLs. WebSocket-Tests laufen gegen FastAPI `TestClient`.

## Environment

Siehe [.env.example](.env.example). `.env` und echte TURN-Secrets gehören nicht ins Repository. `ICE_SERVERS_JSON` ist eine JSON-Liste von ICE-Server-Konfigurationen. TURN-Credentials werden nur ausgegeben, wenn `TURN_URL` und `TURN_SHARED_SECRET` gesetzt sind; der Client erhält kurzlebige coturn-kompatible Credentials.

## API

- `POST /v1/lobbies`
- `POST /v1/lobbies/resolve`
- `POST /v1/lobbies/{lobby_id}/heartbeat`
- `POST /v1/lobbies/{lobby_id}/close`
- `POST /v1/lobbies/{lobby_id}/started`
- `POST /v1/lobbies/{lobby_id}/turn-credentials`
- `WS /v1/signaling`

Secrets werden nur in den dafür vorgesehenen Create-/Resolve-Antworten ausgegeben. Logs enthalten Lobby-ID, Ereignistyp und Peer-Lifecycle, aber keine Tokens, TURN-Passwörter oder SDP-Inhalte.

