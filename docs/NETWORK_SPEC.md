# RisikoLike — Lobby & Network Specification

> **Status:** Pre-Production / Architektur  
> **Dokumentversion:** 0.2  
> **Bezug:** `docs/GDD.md`, `docs/MAP_SPEC.md`, `docs/BACKEND_SPEC.md`

## 1. Architekturziele

- `FIX` Private Online-Partien für 2–5 Spieler.
- `FIX` Ein Spieler ist Host und gleichzeitig autoritative Spielinstanz.
- `FIX` Clients senden nur Aktionen/Intents; der Host validiert und verändert den Game State.
- `FIX` Self-contained Invite statt zentraler Lobby-Auflösung im normalen Nutzerfluss.
- `FIX` Kein Account-Zwang für V1.
- `FIX` Kein Dedicated Game Server für V1.
- `FIX` V1 private Lobbys benötigen keinen öffentlichen Rendezvous-/Signaling-Service.
- `FIX` Ein optionaler Direct-Address-Pfad unterstützt LAN, Port Forwarding und Debugging.
- `FIX` Das Ruleset wird vor Matchstart festgelegt und danach immutable.

## 2. V1-Technologieentscheidungen

- `FIX` Godot 4.7.2 stable als initial festgeschriebene Engine-Version.
- `FIX` Windows x86_64 als primäres V1-Target.
- `FIX` GDScript für den Game Client.
- `FIX` Reliable ordered TCP als V1 Direct-Host-Transport auf Default-Port `43100`.
- `OPTIONAL` WebRTC, HTTPS/WSS, ICE/STUN und TURN für den retained central-service path.
- `CONFIG` UPnP-TCP-Portmapping als Komfortfunktion; manuelles Forwarding bleibt Fallback.
- `FIX` Host-authoritative Game Session.
- `SPÄTER` Optional ENet/LAN/Direct Connect.

Engine-Upgrades erfolgen bewusst und werden separat getestet; während einer Implementierungsphase wird nicht automatisch auf Preview-/Dev-Versionen gewechselt.

## 3. Topologie

```text
Host Godot Client
   | TCP :43100 (configurable)
   v
Guest Godot Client

Optional/future:
Host <------ WebRTC direct ------> Guest
  über retained central signaling / optional TURN
```

Der Backend-Service verwaltet keinen autoritativen Game State.

## 4. Invite-Code Flow

1. Host klickt `Lobby erstellen`.
2. Der Host startet lokal den TCP-Listener.
3. Der Host erzeugt eine neue Session-ID und ein zufälliges Join-Secret.
4. Der Host zeigt einen `AF1.…`-Invite mit Endpoint, Port und Checksumme.
5. Der Gast fügt den Invite ein oder verwendet die Direct-Address-Eingabe.
6. Der Host validiert Session, Version, Kapazität und Join-Secret.
7. Der Host weist die Player-ID zu und sendet Lobby-State und Ruleset.
8. Der Gast erscheint in der Lobby.

## 5. Invite-Code Format

- `FIX` Format `AF1.<base64url-payload>.<8-stellige SHA-256-Prüfsumme>`.
- `FIX` Payload enthält Format-, Spiel- und Protokollversion, Endpoint, Port,
  Session-ID und zufälliges Join-Secret.
- `FIX` Checksumme erkennt Übertragungs-/Tippfehler; das Join-Secret autorisiert.
- `FIX` Invite wird nach Lobby-Close ungültig; normale Late Joins bleiben gesperrt.

## 6. Lobby State

```text
LobbyState
  lobby_id
  invite_code
  host_player_id
  status
  max_players
  players[]
  ruleset
  protocol_version
  game_version
  created_at
```

```text
PlayerLobbyState
  player_id
  network_peer_id
  name
  color
  is_host
  is_ready
  connection_state
  spectator
```

Session-/Reconnect-Tokens sind Security-Daten und gehören nicht in UI-Snapshots für andere Spieler.

## 7. Lobby-Zustände

```text
CREATING
OPEN
STARTING
IN_GAME
CLOSED
```

Erlaubte Übergänge:

```text
CREATING -> OPEN
OPEN -> STARTING
STARTING -> IN_GAME
OPEN -> CLOSED
STARTING -> CLOSED
IN_GAME -> CLOSED
```

Nur Host/Backend gemäß Verantwortungsbereich dürfen autoritative Zustandswechsel auslösen.

## 8. Join-Validierung

Der Host prüft mindestens:

- Lobby ist `OPEN`.
- Match wurde nicht gestartet.
- Lobby ist nicht voll.
- Protokollversion ist kompatibel.
- Spielversion ist kompatibel.
- Join-/Session-Daten sind gültig.
- Spielername erfüllt Regeln.
- Farbe ist verfügbar oder wird neu zugeteilt.
- Peer ist nicht bereits registriert.

## 9. Ready & Match Start

- `CONFIG` Alle Nicht-Host-Spieler müssen standardmäßig Ready sein.
- `CONFIG` Host muss standardmäßig nicht separat Ready drücken.
- `FIX` Nur Host darf Matchstart auslösen.
- `FIX` Mindestspielerzahl muss erreicht sein.
- `FIX` Ruleset wird vor Start validiert und eingefroren.
- `FIX` Danach keine normalen neuen Spieler.
- `FIX` Host erzeugt initialen Game State.
- `FIX` Clients bestätigen Scene + Initial State.
- `FIX` Erst danach beginnt Zug 1.

## 10. Game Message Groups

### Client -> Host

- `JoinRequest`
- `ReadyRequest`
- `ColorChangeRequest`
- `ReinforcementRequest`
- `AttackRequest`
- `DiceCountRequest`
- `ConquestMoveRequest`
- `FortificationRequest`
- `EndPhaseRequest`
- `EndTurnRequest`
- `CardTradeRequest`
- `SurrenderRequest`
- `ReconnectRequest`

### Host -> Client(s)

- `JoinAccepted`
- `JoinRejected`
- `LobbyStateSnapshot`
- `RulesetSnapshot`
- `MatchStarting`
- `GameStateSnapshot`
- `ActionAccepted`
- `ActionRejected`
- `CombatResult`
- `CardDrawResult`
- `PlayerConnectionChanged`
- `PlayerEliminated`
- `TurnChanged`
- `PhaseChanged`
- `MatchEnded`

## 11. Message Envelope

Client-Aktion logisch:

```text
protocol_version
match_id
player_id
action_id
action_type
expected_state_revision
payload
```

Host-Antwort:

```text
action_id
accepted
new_state_revision
result/error_code
```

`action_id` schützt vor doppelter Ausführung. `expected_state_revision` schützt vor veralteten Aktionen.

## 12. State Revision

- `FIX` Game State besitzt monoton steigende `state_revision`.
- `FIX` Jede bestätigte zustandsverändernde Aktion erhöht sie.
- `FIX` Clients senden erwartete Revision mit.
- `FIX` Host kann veraltete Aktionen ablehnen.
- `FIX` Bei Desync sendet Host vollständigen Snapshot.

## 13. Synchronisation

- Kritische Game-Nachrichten zuverlässig und geordnet.
- Keine kontinuierliche Positionsreplikation nötig.
- Hover, Animationen und Cursor bleiben lokal.
- Host sendet bestätigte Resultate.
- Vollständiger Snapshot bei Join/Reconnect/Desync.
- Inkrementelle Events im normalen Spielbetrieb.

## 14. Reconnect

- `FIX` Spieler besitzt Reconnect-Token.
- `FIX` Peer-ID ist keine dauerhafte Spieleridentität.
- `FIX` Reconnect bindet neue Verbindung an bestehende `player_id`.
- `CONFIG` Reconnect-Frist Default 3 Minuten.
- `FIX` Nach Reconnect vollständiger Host-Snapshot.
- `FIX` Client verwirft spekulativen lokalen State.
- `FIX` Jede erfolgreiche Reconnect-Autorisierung rotiert Credential und Connection-Generation.
- `FIX` Ein aktiver Spieler-Slot darf nicht durch eine zweite Verbindung übernommen werden.
- `FIX` Snapshot enthält nur die Sicht des authentifizierten Spielers; fremde Karten-IDs bleiben verborgen.
- `FIX` Reconnect-Tickets sind vom Invite-/Join-Token getrennt und nur einmal für Signaling verwendbar.

## 15. Disconnect

### Client

- Spieler wird `DISCONNECTED`.
- Territorien und Truppen bleiben bestehen.
- Zugtimer läuft gemäß GDD weiter.
- Reconnect innerhalb Frist möglich.
- Nach Ablauf dauerhaft verlassen.

### Host

- Der Host bleibt in V1 die autoritative Instanz; Host-Migration ist nicht Teil dieses Meilensteins.
- Bei nicht erreichbarem Host wird ein Reconnect am Signaling-Gateway mit `HOST_UNAVAILABLE` abgewiesen.
- Host-Verlust beendet die V1-Partie statt einen zweiten autoritativen State zu erzeugen.
- `SPÄTER` Host Migration.

## 16. Sicherheit

- Invite-Code ist Convenience, kein Secret.
- Tokens müssen kryptografisch zufällig sein.
- Clients setzen niemals autoritativ Besitzer, Truppen, Karten, Würfel oder Gewinner.
- Host validiert jede Game Action gegen State und Ruleset.
- Netzwerkdaten gelten als nicht vertrauenswürdig.
- Payload-Größen und Strings begrenzen.
- Unbekannte Message-Typen ablehnen.
- Rate Limits für Backend/Join-Versuche.
- Keine Secrets unnötig loggen.

## 17. Backend

Die detaillierte Backend-/Signaling-Spezifikation befindet sich in `docs/BACKEND_SPEC.md`.

Logische REST-Endpunkte:

```text
POST /v1/lobbies
POST /v1/lobbies/{lobby_id}/heartbeat
POST /v1/lobbies/{lobby_id}/close
POST /v1/lobbies/resolve
POST /v1/lobbies/{lobby_id}/turn-credentials
```

Signaling erfolgt über WSS.

## 18. Versionierung

```text
game_version
protocol_version
backend_api_version
```

V1:

- Protocol mismatch -> Join ablehnen.
- Erste Releases verwenden exakten Game-Version-Match.
- Backend API beginnt mit `/v1`.

## 19. Fehlercodes

Mindestens:

```text
LOBBY_NOT_FOUND
LOBBY_FULL
LOBBY_CLOSED
MATCH_ALREADY_STARTED
INVALID_INVITE_CODE
INVITE_EXPIRED
VERSION_MISMATCH
PROTOCOL_MISMATCH
INVALID_TOKEN
NAME_INVALID
COLOR_UNAVAILABLE
NOT_YOUR_TURN
INVALID_PHASE
INVALID_TERRITORY
NOT_OWNER
NOT_ADJACENT
INSUFFICIENT_TROOPS
INVALID_CARD_SET
STALE_STATE
DUPLICATE_ACTION
RATE_LIMITED
INTERNAL_ERROR
```

## 20. Noch zu entscheiden

1. `OFFEN` Backend-Sprache/Framework.
2. `OFFEN` Hosting-Anbieter.
3. `OFFEN` STUN/TURN-Provider bzw. Eigenbetrieb.
4. `OFFEN` Redis ja/nein für Produktion.
5. `OFFEN` konkrete RPC-/Payload-Schemas nach Godot-Architektur.
6. `OFFEN` native WebRTC-Integration/GDExtension exakt auswählen und versionieren.

## 21. Definition of Done — Networking V1

- Host kann Lobby erstellen.
- Invite-Code wird erzeugt und angezeigt.
- Zweiter PC kann nur mit Invite-Code beitreten.
- Keine IP-Eingabe/Portfreigabe nötig.
- Bis zu 5 Spieler können Lobby betreten.
- Lobby-State bleibt synchron.
- Nur Host startet Match.
- Ruleset wird eingefroren.
- Host validiert alle Game Actions.
- Doppelte/veraltete Aktionen verändern State nicht doppelt.
- Disconnect wird erkannt.
- Client kann innerhalb Frist reconnecten.
- Reconnect erhält vollständigen State.
- Inkompatible Clients erhalten definierten Fehler.
- TURN-Fallback wurde real über getrennte Internetanschlüsse getestet.
- Host-Verlust wird gemäß V1-Regel behandelt.

## V1 Direct-Host Architecture

V1 private lobbies default to `DIRECT_HOST`. The player creating the lobby is
the authoritative host and also a player in the match. The packaged client
does not require a central service, Python process, account, or lobby lookup.

The default transport is reliable, ordered TCP on port `43100` (configurable).
The host listener binds `0.0.0.0:<port>`; LAN and manually forwarded Internet
connections are supported. Existing `LocalNetworkTransport` remains available
for loopback test fixtures. The existing WebRTC transport is retained as an
optional central-service/future NAT traversal path and is not the V1 default.

### Self-contained invite

Direct invites use the format `AF1.<base64url-payload>.<checksum>`. The payload
contains the invite format version, product/protocol versions, advertised host
address, TCP port, fresh session ID, and a cryptographically random join
secret. The checksum detects copy/paste corruption; the join secret is the
actual capability. Invite and reconnect credentials are never interchangeable.

The host validates session, protocol, product version, lobby state, capacity,
and join secret before assigning a player identity. Invalid, expired, closed,
or malformed invites receive controlled errors and do not crash the host.

### Connectivity and limitations

The host may attempt TCP UPnP port mapping when available; failure never blocks
local lobby creation. The UI distinguishes direct/LAN readiness from an
Internet guarantee and provides the configured address and port for manual
forwarding. No external “what is my IP” service is hardcoded. CGNAT and
restrictive routers can prevent direct Internet hosting.

Reconnect credentials are generated and stored by the host as hashes, rotated
per generation, expire with the match reconnect window, and are replay-safe.
Host process loss is terminal; clients receive `HOST_UNAVAILABLE` and
`TERMINATED`. There is no host migration in V1.
