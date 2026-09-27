# RisikoLike — Lobby & Network Specification

> **Status:** Pre-Production / Architektur  
> **Dokumentversion:** 0.1  
> **Bezug:** `docs/GDD.md`, `docs/MAP_SPEC.md`

## 1. Architekturziele

- `FIX` Private Online-Partien für 2–5 Spieler.
- `FIX` Ein Spieler ist Host und gleichzeitig autoritative Spielinstanz.
- `FIX` Clients senden nur Aktionen/Intents; der Host validiert und verändert den Game State.
- `FIX` Invite-Code statt manueller IP-Eingabe im normalen Nutzerfluss.
- `FIX` Kein Account-Zwang für V1.
- `FIX` Kein Dedicated Game Server für V1.
- `FIX` Ein kleiner öffentlicher Rendezvous-/Lobby-Service ist für Invite-Codes zulässig.
- `FIX` Das Ruleset wird vor Matchstart festgelegt und danach immutable.

## 2. Empfohlene V1-Topologie

```text
                   HTTPS
+-------------+  <------->  +-----------------------+
| Host Client |             | Rendezvous/Lobby API  |
+------+------+             +-----------+-----------+
       ^                                  ^
       |                                  |
       | Game Connection                  | HTTPS
       |                                  |
+------+------+                           |
| Client A   |----------------------------+
+------------+

+------------+
| Client B   |----------------------------+
+------------+
```

Der Rendezvous-Service verwaltet **nicht** den laufenden Game State. Seine Aufgaben sind ausschließlich Lobby-/Session-Vermittlung, Invite-Code-Auflösung und kurzlebige Session-Metadaten.

## 3. Transportentscheidung

### V1-Plan

- `FIX` Godot High-Level Multiplayer API für die Game Session.
- `KANDIDAT` `ENetMultiplayerPeer` als primärer nativer Windows-Transport.
- `OFFEN` Wie Hosts ohne manuelles Port-Forwarding aus dem Internet erreichbar werden.
- `OFFEN` Relay-/NAT-Traversal-Lösung.

### Begründung

ENet passt gut zum host-authoritativen Godot-Modell und unterstützt zuverlässige RPCs. Eine reine direkte ENet-Verbindung über das öffentliche Internet löst NAT/Router-Erreichbarkeit jedoch nicht automatisch. Deshalb ist die Erreichbarkeitsstrategie vor Implementierung des Invite-Systems zu entscheiden.

### WebRTC-Alternative

- `KANDIDAT` WebRTC mit Signaling + STUN/TURN.
- Vorteil: NAT-Traversal ist Teil des Verbindungsmodells.
- Nachteil: höhere Infrastruktur- und Implementierungskomplexität; native Godot-Plattformen benötigen je nach Godot-Version/Setup zusätzliche WebRTC-Unterstützung.

## 4. Invite-Code Flow

Vorgesehener Nutzerfluss:

1. Host klickt `Lobby erstellen`.
2. Spiel erzeugt eine kryptografisch zufällige `session_id` und ein Host-Session-Token.
3. Client registriert die Lobby beim Rendezvous-Service.
4. Service erzeugt einen kurzen Invite-Code.
5. Host zeigt den Code an.
6. Gast gibt den Code ein.
7. Gast fragt den Code beim Rendezvous-Service ab.
8. Service liefert ausschließlich die für den Verbindungsaufbau erforderlichen kurzlebigen Session-Daten.
9. Gast baut die Game-Verbindung zum Host bzw. Relay auf.
10. Host authentifiziert die Join-Anfrage.
11. Host sendet Lobby-State und Ruleset.
12. Gast erscheint in der Lobby.

## 5. Invite-Code Format

V1-Vorschlag:

- Länge: `6` Zeichen
- Alphabet: `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`
- Keine leicht verwechselbaren Zeichen `0/O` und `1/I`.
- Groß-/Kleinschreibung bei Eingabe ignorieren.
- Darstellung optional als `ABC-123`.
- Code ist nicht die Session-ID und kein Authentifizierungsgeheimnis.
- Code wird beim Schließen der Lobby ungültig.
- Code wird nach Matchstart nicht mehr für neue Spieler akzeptiert.
- Kollisionsprüfung erfolgt serverseitig.

Status des konkreten Formats: `CONFIG/FIX VOR IMPLEMENTIERUNG`.

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

### PlayerLobbyState

```text
player_id
network_peer_id
session_token
name
color
is_host
is_ready
connection_state
spectator
```

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

Clients dürfen diese Zustände nicht autoritativ ändern.

## 8. Join-Validierung

Der Host prüft vor Aufnahme eines Clients mindestens:

- Lobby ist `OPEN`.
- Match wurde noch nicht gestartet.
- Lobby ist nicht voll.
- Protokollversion kompatibel.
- Spielversion kompatibel.
- Join-Token/Session-Daten gültig.
- Spielername erfüllt Längen-/Zeichenregeln.
- angeforderte Farbe ist verfügbar oder wird neu zugeteilt.
- Peer ist nicht bereits registriert.

## 9. Ready & Match Start

- `CONFIG` Alle Nicht-Host-Spieler müssen standardmäßig Ready sein.
- `CONFIG` Host muss standardmäßig nicht separat Ready drücken.
- `FIX` Nur Host darf `Start Match` auslösen.
- `FIX` Mindestspielerzahl muss erreicht sein.
- `FIX` Vor Start wird das Ruleset validiert.
- `FIX` Beim Start wird das Ruleset eingefroren.
- `FIX` Lobby nimmt danach keine normalen neuen Spieler mehr an.
- `FIX` Host erzeugt initialen autoritativen Game State.
- `FIX` Clients bestätigen, dass Game Scene und Initial State geladen wurden.
- `FIX` Erst danach beginnt Zug 1.

## 10. RPC-/Message-Gruppen

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

Jede spielrelevante Aktion sollte logisch mindestens enthalten:

```text
protocol_version
match_id
player_id
action_id
action_type
expected_state_revision
payload
```

Host-Antworten enthalten:

```text
action_id
accepted
new_state_revision
result/error_code
```

`action_id` verhindert, dass doppelt empfangene Requests doppelt ausgeführt werden. `expected_state_revision` ermöglicht die Ablehnung veralteter Aktionen.

## 12. State Revision

- `FIX` Autoritativer Game State besitzt eine monoton steigende `state_revision`.
- `FIX` Jede bestätigte zustandsverändernde Aktion erhöht die Revision.
- `FIX` Clients senden ihre erwartete Revision bei Aktionen mit.
- `FIX` Host darf veraltete oder inkonsistente Aktionen ablehnen.
- `FIX` Bei Desync kann der Host einen vollständigen Snapshot senden.

## 13. Synchronisationsstrategie

Für das rundenbasierte Spiel gilt:

- Kritische Aktionen: zuverlässig und geordnet.
- Keine kontinuierliche Positionsreplikation nötig.
- UI-Hover, lokale Animationen und Cursor bleiben lokal.
- Host sendet bestätigte Ergebnisse statt Client-Simulation als Wahrheit zu akzeptieren.
- Vollständiger Snapshot bei Join/Reconnect/Desync.
- Inkrementelle Events während des normalen Spiels.

## 14. Reconnect

- `FIX` Spieler besitzt ein kurzlebiges Reconnect-/Session-Token.
- `FIX` Netzwerk-Peer-ID allein ist keine dauerhafte Spieleridentität.
- `FIX` Reconnect ordnet eine neue Verbindung derselben logischen `player_id` zu.
- `CONFIG` Reconnect-Frist Default 3 Minuten.
- `FIX` Host sendet nach erfolgreichem Reconnect einen vollständigen Game-State-Snapshot.
- `FIX` Client verwirft lokalen spekulativen State und übernimmt den Host-Snapshot.

## 15. Disconnect

### Client

- Spieler wird `DISCONNECTED` markiert.
- Territorien und Truppen bleiben bestehen.
- Zugtimer läuft gemäß GDD weiter.
- Reconnect innerhalb der Frist möglich.
- Nach Ablauf wird Spieler als dauerhaft verlassen behandelt.

### Host

- Partie pausiert.
- Host erhält Reconnect-Frist.
- Kommt Host zurück, wird Partie fortgesetzt.
- Kommt Host in V1 nicht zurück, endet die Partie.
- `SPÄTER` Host Migration.

## 16. Sicherheit

- Invite-Code ist Convenience, kein Sicherheits-Token.
- Session-/Reconnect-Tokens müssen ausreichend zufällig und nicht erratbar sein.
- Clients dürfen keine Besitzer-, Truppen-, Karten- oder Würfelresultate autoritativ setzen.
- Host validiert jeden Game Request gegen aktuellen State und Ruleset.
- Netzwerkdaten gelten grundsätzlich als nicht vertrauenswürdig.
- Payload-Größen begrenzen.
- Strings/Längen validieren.
- Unbekannte Message-/Action-Typen ablehnen.
- Rate Limits für Rendezvous-API und Join-Versuche.
- Keine öffentliche IP oder Session-Geheimnisse unnötig in Logs schreiben.

## 17. Rendezvous API — logische Endpunkte

Technologie noch `OFFEN`; benötigte Semantik:

```text
POST   /v1/lobbies
POST   /v1/lobbies/{lobby_id}/heartbeat
POST   /v1/lobbies/{lobby_id}/close
POST   /v1/lobbies/resolve
```

### Create Lobby

Input logisch:

```text
protocol_version
game_version
host_connection_metadata
```

Output logisch:

```text
lobby_id
invite_code
host_session_token
expires_at
```

### Resolve Invite

Input:

```text
invite_code
game_version
protocol_version
```

Output:

```text
lobby_id
connection_metadata
join_token
expires_at
```

## 18. Lobby-Service Lebenszyklus

- Host sendet Heartbeat.
- Bleibt Heartbeat aus, läuft Lobby-Registrierung automatisch ab.
- Host schließt Registrierung explizit beim normalen Lobby-Ende.
- Service speichert keinen dauerhaften Matchverlauf für V1.
- Service entscheidet nicht über Spielzüge.

## 19. Versionierung

Zwei getrennte Versionen:

```text
game_version
protocol_version
```

`game_version` ist die sichtbare Build-/Release-Version. `protocol_version` beschreibt Netzwerkkompatibilität.

V1-Regel:

- unterschiedliche inkompatible `protocol_version` -> Join ablehnen;
- unterschiedliche `game_version` -> je nach Kompatibilitätsmatrix ablehnen; für erste V1 zunächst exakter Match empfohlen.

## 20. Fehlercodes

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

## 21. Noch zu entscheiden

Vor Netzwerkimplementierung müssen diese Punkte geschlossen werden:

1. `OFFEN` Godot-Version exakt festlegen.
2. `OFFEN` ENet direkt, WebRTC oder Relay-basierte Lösung als finaler Game Transport.
3. `OFFEN` NAT-Traversal/Relay-Provider bzw. Eigenbetrieb.
4. `OFFEN` Technologie und Hosting des Rendezvous-Service.
5. `OFFEN` finale Invite-Code-Länge und Alphabet.
6. `OFFEN` Heartbeat-Intervall und Lobby-TTL.
7. `OFFEN` Token-Lebensdauer.
8. `OFFEN` maximale Spielername-Länge und erlaubte Zeichen.
9. `OFFEN` Farbkonflikt-Verhalten.
10. `OFFEN` genaue RPC-Namen und Payload-Schemas nach Festlegung der Godot-Architektur.

## 22. Definition of Done — Networking V1

- Host kann eine Lobby erstellen.
- Invite-Code wird erzeugt und angezeigt.
- Zweiter PC kann ausschließlich mit dem Invite-Code beitreten.
- Kein manuelles Eingeben einer IP-Adresse erforderlich.
- Bis zu 5 Spieler können dieselbe Lobby betreten.
- Lobby-State bleibt bei allen Peers synchron.
- Nur Host kann Match starten.
- Ruleset wird beim Start eingefroren.
- Alle spielrelevanten Aktionen werden vom Host validiert.
- Doppelte/veraltete Aktionen verändern State nicht doppelt.
- Disconnect wird erkannt.
- Client kann innerhalb der Frist reconnecten.
- Reconnect erhält einen vollständigen korrekten State.
- Ungültige/incompatible Clients erhalten einen definierten Fehler.
- Host-Verlust wird entsprechend der V1-Regel behandelt.
