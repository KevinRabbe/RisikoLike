# RisikoLike — Lobby & Network Specification

> **Status:** Pre-Production / Architektur  
> **Dokumentversion:** 0.2  
> **Bezug:** `docs/GDD.md`, `docs/MAP_SPEC.md`, `docs/BACKEND_SPEC.md`

## 1. Architekturziele

- `FIX` Private Online-Partien für 2–5 Spieler.
- `FIX` Ein Spieler ist Host und gleichzeitig autoritative Spielinstanz.
- `FIX` Clients senden nur Aktionen/Intents; der Host validiert und verändert den Game State.
- `FIX` Invite-Code statt manueller IP-Eingabe im normalen Nutzerfluss.
- `FIX` Kein Account-Zwang für V1.
- `FIX` Kein Dedicated Game Server für V1.
- `FIX` Ein kleiner öffentlicher Rendezvous-/Signaling-Service vermittelt Sessions.
- `FIX` Das Ruleset wird vor Matchstart festgelegt und danach immutable.

## 2. V1-Technologieentscheidungen

- `FIX` Godot 4.7.2 stable als initial festgeschriebene Engine-Version.
- `FIX` Windows x86_64 als primäres V1-Target.
- `FIX` GDScript für den Game Client.
- `FIX` WebRTC als Internet-Game-Transport.
- `FIX` HTTPS + WSS für Backend und Signaling.
- `FIX` ICE/STUN für NAT-Traversal.
- `FIX` TURN als Relay-Fallback.
- `FIX` Kein manuelles Port-Forwarding im normalen Nutzerfluss.
- `FIX` Host-authoritative Game Session.
- `SPÄTER` Optional ENet/LAN/Direct Connect.

Engine-Upgrades erfolgen bewusst und werden separat getestet; während einer Implementierungsphase wird nicht automatisch auf Preview-/Dev-Versionen gewechselt.

## 3. Topologie

```text
Host Godot Client
   | HTTPS/WSS
   v
Rendezvous + Signaling Backend
   ^
   | HTTPS/WSS
Guest Godot Client

Host <------ WebRTC direct ------> Guest
  oder
Host <-------- TURN relay -------> Guest
```

Der Backend-Service verwaltet keinen autoritativen Game State.

## 4. Invite-Code Flow

1. Host klickt `Lobby erstellen`.
2. Backend registriert Lobby und erzeugt Lobby-ID, Invite-Code und Host-Token.
3. Host verbindet sich mit dem Signaling-Service.
4. Gast gibt Invite-Code ein.
5. Backend löst Code auf und erzeugt kurzlebiges Join-Token.
6. Gast verbindet sich mit Signaling.
7. Offer/Answer und ICE-Candidates werden vermittelt.
8. WebRTC versucht direkte Peer-Verbindung.
9. Falls erforderlich wird TURN verwendet.
10. Host authentifiziert den Game Join.
11. Host sendet Lobby-State und Ruleset.
12. Gast erscheint in der Lobby.

## 5. Invite-Code Format

- `FIX` 6 Zeichen.
- `FIX` Darstellung `ABC-123`.
- `FIX` Alphabet `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`.
- `FIX` Case-insensitive Eingabe.
- `FIX` Invite-Code ist kein Authentifizierungsgeheimnis.
- `FIX` Kollisionen werden serverseitig behandelt.
- `FIX` Nach Lobby-Ende ungültig.
- `FIX` Nach Matchstart keine normalen Late Joins.

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

## 15. Disconnect

### Client

- Spieler wird `DISCONNECTED`.
- Territorien und Truppen bleiben bestehen.
- Zugtimer läuft gemäß GDD weiter.
- Reconnect innerhalb Frist möglich.
- Nach Ablauf dauerhaft verlassen.

### Host

- Partie pausiert.
- Host erhält Reconnect-Frist.
- Rückkehr -> Partie fortsetzen.
- Keine Rückkehr -> Partie endet in V1.
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
