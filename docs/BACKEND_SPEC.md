# RisikoLike — Backend & Signaling Specification

> **Status:** Optional / Future Central Services Prototype
> **Dokumentversion:** 0.1  
> **Bezug:** `docs/GDD.md`, `docs/NETWORK_SPEC.md`  
> **Ziel:** Definition des minimalen V1-Backends für Invite-Codes, WebRTC-Signaling, Session-Tokens, Lobby-Lebenszyklus und TURN-Fallback.

## 1. Architekturentscheidung

- `FIX` Die eigentliche Partie bleibt host-authoritativ auf dem PC des Lobby-Hosts.
- `FIX` Das Backend ist kein autoritativer Game Server.
- `FIX` V1 private Lobbys verwenden standardmäßig Direct Host über TCP.
- `OPTIONAL` WebRTC, STUN und TURN bleiben für spätere/explicit central-service modes erhalten.
- `OPTIONAL` HTTPS/WSS betrifft ausschließlich diesen zentralen Signaling-Pfad.
- `FIX` Direct Host darf keinen Backend-Service voraussetzen.
- `FIX` Self-contained Direct Invites werden lokal vom Host erzeugt und validiert.
- `SPÄTER` Dedicated Game Server.

## 2. Verantwortlichkeiten

### Backend verantwortlich für

- Lobby registrieren
- Invite-Code erzeugen
- Invite-Code auf Lobby auflösen
- kurzlebige Lobby-Metadaten
- Join-Token erzeugen
- Host-Session authentifizieren
- Heartbeats
- Lobby-TTL
- WebRTC-Signaling
- ICE-Candidate-Austausch
- TURN-Zugangsdaten ausgeben, falls erforderlich
- Rate Limiting
- Protokoll-/Build-Metadaten prüfen

Diese Verantwortlichkeiten gelten nur, wenn der optionale Backend-/WebRTC-Modus
explizit aktiviert wird. Sie gehören nicht zum normalen V1-Create-/Join-Flow.

### Backend ausdrücklich nicht verantwortlich für

- Territoriumsbesitz
- Truppenanzahlen
- Würfelergebnisse
- Kartenhände
- Zugreihenfolge
- Kampfvalidierung
- Siegbedingung
- Ruleset-Auswertung während der Partie
- dauerhafte Speicherung des Matchverlaufs

Diese Daten bleiben beim autoritativen Host.

## 3. Komponenten

```text
Godot Host
   |
   | HTTPS + Secure WebSocket
   v
+--------------------------+
| RisikoLike Backend       |
|                          |
| REST API                 |
| Signaling WebSocket      |
| Lobby Registry           |
| Token Service            |
+-------------+------------+
              |
              +---- STUN
              |
              +---- TURN Relay

Godot Client
   |
   +------ HTTPS/WSS ------ Backend
   |
   +------ WebRTC -------- Host
             oder
   +------ TURN Relay ---- Host
```

## 4. Invite-Code

V1 wird festgelegt auf:

```text
6 Zeichen
Darstellung: ABC-123
Alphabet: ABCDEFGHJKLMNPQRSTUVWXYZ23456789
case-insensitive
```

Ausgeschlossen werden visuell leicht verwechselbare Zeichen wie `0`, `O`, `1`, `I`.

Regeln:

- `FIX` Invite-Code ist kein Secret.
- `FIX` Invite-Code identifiziert eine aktive Lobby-Registrierung.
- `FIX` Codes werden kryptografisch zufällig erzeugt.
- `FIX` Kollisionen werden serverseitig erkannt; bei Kollision wird neu generiert.
- `FIX` Nach Lobby-Ende wird der Code ungültig.
- `FIX` Nach Matchstart sind normale neue Joins über den Code nicht mehr erlaubt.
- `FIX` Reconnect verwendet nicht den Invite-Code als Authentifizierung.

## 5. Identitäten und Tokens

### lobby_id

- serverseitig erzeugte eindeutige Lobby-ID
- nicht für die normale UI vorgesehen
- darf nicht als Authentifizierungsnachweis dienen

### player_id

- logische Spieleridentität innerhalb einer Partie
- bleibt bei Reconnect erhalten
- unabhängig von WebRTC-/Godot-Peer-ID

### host_session_token

- Secret
- wird bei Lobby-Erstellung ausgegeben
- berechtigt zum Heartbeat, Schließen und administrativen Signaling der Lobby
- niemals in Logs oder UI anzeigen

### join_token

- kurzlebiges Secret
- wird nach erfolgreicher Invite-Auflösung ausgegeben
- gilt für genau eine Lobby
- dient zum initialen Verbindungs-/Signaling-Vorgang
- nach erfolgreichem Join bzw. Ablauf nicht wiederverwenden

### reconnect_token

- Secret
- wird nach erfolgreichem Join vom autoritativen Host einer `player_id` zugeordnet
- dient zum Wiederverbinden mit derselben logischen Spieleridentität
- Invite-Code allein reicht niemals für Reconnect
- wird serverseitig nur als Hash gespeichert und bei erfolgreicher Autorisierung rotiert
- alte Generationen werden invalidiert; ein Replay ist kein neuer Login
- Token und Match-/Player-Bindung werden niemals geloggt

### Reconnect-Flow

Nach Matchstart fordert der Host pro Gastspieler ein eigenes Reconnect-Credential an:

```text
POST /v1/lobbies/{lobby_id}/reconnect-credentials
Authorization: Bearer <host_session_token>
{ "player_id": "P2" }
```

Der Token wird genau einmal im Backend-Response an den Host geliefert und anschließend über den autoritativen Host an den passenden Spieler weitergereicht. Der Client autorisiert eine neue Verbindung über:

```text
POST /v1/matches/reconnect
{ "match_id": "...", "player_id": "P2", "reconnect_token": "...", "protocol_version": 1, "game_version": "0.1.0" }
```

Die Antwort enthält einen einmaligen kurzlebigen Signaling-Ticket, einen rotierten Reconnect-Token und eine inkrementierte Connection-Generation. Das Ticket wird nur für `AUTH_RECONNECT` am Signaling-WebSocket akzeptiert. Ein bereits aktiver Slot wird nicht übernommen; der Host bleibt die einzige Game-State-Autorität.

Die lokale V1-Implementierung hält Match-/Reconnect-Metadaten im Backend-Prozessspeicher. Ein Backend-Neustart invalidiert deshalb aktive Reconnect-Credentials; ein persistenter Session-Store ist außerhalb dieses Meilensteins.

## 6. Token-Lebensdauer

V1-Defaults:

```text
join_token:          60 Sekunden
host_session_token:  Lebensdauer der Lobby + kurze Grace Period
reconnect_token:     Lebensdauer der Partie
TURN credentials:    kurzlebig, Ziel 10 Minuten
```

Exakte serverseitige Implementierungswerte können später konfigurierbar sein, ohne das Spielprotokoll zu verändern.

## 7. Lobby TTL & Heartbeat

V1-Default:

```text
heartbeat interval: 15 Sekunden
lobby TTL:          45 Sekunden ohne gültigen Heartbeat
```

Regeln:

- Host sendet Heartbeats nur solange Lobby/Session registriert bleiben soll.
- Backend aktualisiert `last_seen_at` nur bei gültigem Host-Token.
- Nach TTL wird die Lobby automatisch aus der aktiven Registry entfernt.
- Ein Client erhält für abgelaufene Lobbys keinen Verbindungsdatensatz.
- Während eines laufenden Matches darf die Session-Registrierung für Reconnect weiterleben.

## 8. REST API

Basis:

```text
/v1
```

### POST /v1/lobbies

Erstellt eine Lobby-Registrierung.

Request logisch:

```json
{
  "game_version": "x.y.z",
  "protocol_version": 1,
  "max_players": 5
}
```

Response logisch:

```json
{
  "lobby_id": "...",
  "invite_code": "ABC-123",
  "host_session_token": "...",
  "expires_at": "...",
  "signaling_url": "wss://..."
}
```

### POST /v1/lobbies/resolve

Request:

```json
{
  "invite_code": "ABC-123",
  "game_version": "x.y.z",
  "protocol_version": 1
}
```

Response:

```json
{
  "lobby_id": "...",
  "join_token": "...",
  "join_token_expires_at": "...",
  "signaling_url": "wss://...",
  "ice_servers": []
}
```

### POST /v1/lobbies/{lobby_id}/heartbeat

Authentifizierung über Host-Session-Token.

Response enthält mindestens neuen `expires_at`.

### POST /v1/lobbies/{lobby_id}/close

Authentifizierung über Host-Session-Token.

Macht Invite-Code und Lobby-Registrierung ungültig.

### POST /v1/lobbies/{lobby_id}/turn-credentials

Authentifizierter Endpunkt für kurzlebige TURN-Zugangsdaten, sofern der TURN-Provider dieses Modell benötigt.

## 9. Signaling WebSocket

Transport:

```text
WSS
```

Der Signaling-Kanal überträgt nur Daten zum Aufbau/Erhalt der WebRTC-Verbindung.

### Client -> Backend

```text
AUTH_HOST
AUTH_JOIN
WEBRTC_OFFER
WEBRTC_ANSWER
ICE_CANDIDATE
PING
SIGNALING_CLOSE
```

### Backend -> Client

```text
AUTH_OK
AUTH_ERROR
PEER_JOINING
WEBRTC_OFFER
WEBRTC_ANSWER
ICE_CANDIDATE
PEER_LEFT
PONG
ERROR
```

Das Backend darf SDP-/ICE-Inhalte vermitteln, interpretiert aber keine Game-Actions.

## 10. Signaling-Ablauf

```text
1. Host erstellt Lobby per HTTPS.
2. Host verbindet WSS und authentifiziert mit host_session_token.
3. Gast löst Invite-Code per HTTPS auf.
4. Backend erzeugt kurzlebiges join_token.
5. Gast verbindet WSS und authentifiziert mit join_token.
6. Backend ordnet Gast der Lobby zu.
7. WebRTC Offer/Answer werden vermittelt.
8. ICE Candidates werden vermittelt.
9. Peers versuchen direkte Verbindung via ICE/STUN.
10. Falls erforderlich wird TURN als Relay verwendet.
11. WebRTC Data Channels werden geöffnet.
12. Host führt die eigentliche Game-/Lobby-Authentifizierung durch.
13. Signaling-Verbindung kann für ICE-Restart/Reconnect bestehen bleiben bzw. neu aufgebaut werden.
```

## 11. WebRTC Channels

V1 logisch mindestens:

### reliable

Für:

- Lobby State
- Ruleset
- Game Actions
- Game State Events
- Snapshots
- Karten
- Combat Results
- Turn/Phase Changes

Eigenschaften:

```text
ordered = true
reliable = true
```

Für V1 ist kein eigener unreliable Gameplay-Channel erforderlich, da das Spiel rundenbasiert ist.

## 12. ICE / STUN / TURN

- `FIX` ICE wird verwendet.
- `FIX` Mindestens ein STUN-Service muss konfiguriert sein.
- `FIX` TURN-Fallback muss für V1 vorgesehen sein.
- `FIX` TURN-Zugangsdaten dürfen nicht als dauerhaftes statisches Secret im Spielclient eingebaut werden.
- `FIX` Wenn möglich kurzlebige TURN-Credentials verwenden.
- `OFFEN` Konkreter STUN/TURN-Provider bzw. Eigenbetrieb.
- `OFFEN` TURN-Transportoptionen UDP/TCP/TLS nach Deployment-Test.

## 13. Lobby Registry

Backend speichert pro aktiver Lobby logisch nur:

```text
lobby_id
invite_code
host_session_token_hash
status
protocol_version
game_version
max_players
created_at
last_seen_at
expires_at
signaling_connection_id
```

Optional kurzlebig:

```text
pending_join_tokens
active_signaling_peers
```

Nicht speichern:

```text
GameState
TerritoryState
player cards
combat history
chat history
```

## 14. Persistenz

Für V1 soll die aktive Lobby-Registry kurzlebig sein.

- `KANDIDAT` In-Memory für lokale Entwicklung.
- `KANDIDAT` Redis/kompatibler Key-Value-Store für Produktion und mehrere Backend-Instanzen.
- `FIX` Backend-Neustart darf keine dauerhaften Nutzerdaten erfordern.
- `FIX` Es gibt in V1 keine Accounts und keine langfristigen Profile.

## 15. Spielername

V1-Regeln:

```text
Länge: 2–20 Unicode-Zeichen
Trim leading/trailing whitespace
keine Steuerzeichen
kein leerer Name
```

- Namen müssen innerhalb derselben Lobby nicht zwingend global eindeutig sein.
- UI kann bei identischen Namen zusätzliche visuelle Identifikation über Farbe/Slot verwenden.
- Host validiert Namen zusätzlich beim Game Join.

## 16. Versionierung

```text
game_version
protocol_version
backend_api_version = v1
```

V1:

- `FIX` Protocol mismatch -> Join ablehnen.
- `FIX` Für erste Releases Game-Version exakt abgleichen.
- `SPÄTER` Kompatibilitätsmatrix für Patch-Versionen.

## 17. Rate Limits

Mindestens erforderlich für:

- Lobby erstellen
- Invite-Code auflösen
- Join-Token anfordern
- WebSocket-Authentifizierung
- fehlgeschlagene Token-Versuche

Konkrete Requests/Minute werden nach Lasttests festgelegt.

Zusätzlich:

- maximale WebSocket-Message-Größe
- maximale SDP-Größe
- maximale ICE-Candidates pro Peer/Zeitraum
- maximale gleichzeitige Pending Joins pro Lobby

## 18. Fehlercodes

REST/Signaling mindestens:

```text
INVALID_REQUEST
INVALID_INVITE_CODE
LOBBY_NOT_FOUND
LOBBY_EXPIRED
LOBBY_CLOSED
LOBBY_FULL
MATCH_ALREADY_STARTED
INVALID_TOKEN
TOKEN_EXPIRED
TOKEN_ALREADY_USED
RECONNECT_TOKEN_INVALID
RECONNECT_TOKEN_EXPIRED
RECONNECT_TOKEN_REUSED
RECONNECT_WINDOW_EXPIRED
PLAYER_ALREADY_CONNECTED
MATCH_NOT_FOUND
MATCH_FINISHED
HOST_UNAVAILABLE
RECONNECT_FAILED
VERSION_MISMATCH
PROTOCOL_MISMATCH
RATE_LIMITED
SIGNALING_UNAVAILABLE
TURN_UNAVAILABLE
INTERNAL_ERROR
```

## 19. Datenschutz / Logging

- Keine Session-Tokens loggen.
- Keine Reconnect-Tokens loggen.
- TURN-Secrets nicht loggen.
- Invite-Codes dürfen in Debug-Umgebungen geloggt werden; Produktion möglichst minimieren.
- IP-Adressen nur soweit technisch für Betrieb/Security erforderlich verarbeiten.
- Log-Retention vor öffentlichem Release definieren.
- Keine Account-/Profil-Daten in V1.

## 20. Deployment

Produktionsumgebung benötigt logisch:

```text
HTTPS/WSS Reverse Proxy oder TLS-fähige App
Backend API + Signaling
STUN
TURN
optional Redis
DNS
TLS-Zertifikat
Monitoring/Logs
```

`OFFEN` Konkreter Hosting-Anbieter.

## 21. Lokale Entwicklung

Entwicklungsmodus soll ermöglichen:

- Backend lokal starten
- zwei oder mehr Godot-Instanzen auf einem Rechner
- lokale Lobby-Codes
- WebRTC-Verbindung lokal testen
- STUN/TURN für reine lokale Tests optional umgehen
- künstliche Disconnects testen
- Reconnect testen
- Signaling-Verlust simulieren

## 22. Sicherheitsgrenzen

Auch wenn das Backend einen Client authentifiziert, vertraut der Host niemals dessen Gameplay-Daten.

```text
Backend-Authentifizierung != Game-State-Autorität
```

Host validiert weiterhin jede Game Action gemäß GDD und Ruleset.

## 23. Noch offen

Vor Implementierung des Produktionsbackends:

1. `OFFEN` Backend-Sprache/Framework.
2. `OFFEN` Hosting-Anbieter.
3. `OFFEN` STUN/TURN-Provider oder Eigenbetrieb.
4. `OFFEN` Redis ja/nein für erste öffentliche Version.
5. `OFFEN` Domain/Subdomain.
6. `OFFEN` Produktions-Rate-Limits.
7. `OFFEN` Monitoring.
8. `OFFEN` Log-Retention.
9. `OFFEN` Secrets-Management.
10. `OFFEN` konkrete JSON-Schemas/OpenAPI-Spezifikation.

## 24. Definition of Done — Backend V1

- Host kann Lobby registrieren.
- Backend erzeugt eindeutigen Invite-Code.
- Gast kann Invite-Code auflösen.
- Join-Token ist kurzlebig und lobbygebunden.
- Host und Gast können sich am Signaling-Kanal authentifizieren.
- Offer/Answer/ICE-Candidates werden korrekt vermittelt.
- Direkte WebRTC-Verbindung funktioniert in unterstützten NAT-Szenarien.
- TURN-Fallback funktioniert bei blockierter Direktverbindung.
- Keine Router-Portfreigabe ist für normale Spieler erforderlich.
- Lobby läuft ohne Heartbeat automatisch ab.
- Geschlossene/abgelaufene Codes können nicht mehr aufgelöst werden.
- Protocol-/Version-Mismatch wird sauber abgelehnt.
- Tokens erscheinen nicht in Produktionslogs.
- Backend enthält keinen autoritativen Game State.

## V1 Status: optional / future central services prototype

Das Backend bleibt im Repository und wird für den bestehenden WebRTC-/Rendezvous-
Pfad getestet. Es ist jedoch **keine Voraussetzung** für private V1-Lobbys.
Der normale Clientflow verwendet `DIRECT_HOST` über TCP und führt keinen
Lookup gegen `http://127.0.0.1:8000` aus.

Spätere optionale Anwendungen sind Matchmaking, Ranked/MMR, Accounts,
Leaderboards, globale Lobby-Dienste, Moderation oder ein offizieller Relay-
Service. Diese Dienste werden durch den Direct-Host-Pivot nicht vorgezogen.
