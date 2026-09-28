# RisikoLike — Godot Architecture

> **Status:** Pre-Production / Software Architecture  
> **Dokumentversion:** 0.1  
> **Bezug:** `GDD.md`, `MAP_SPEC.md`, `NETWORK_SPEC.md`, `BACKEND_SPEC.md`

## 1. Ziele

- `FIX` Godot 4.7.2 stable
- `FIX` Windows x86_64 als V1-Ziel
- `FIX` GDScript als primäre Sprache
- `FIX` Host-authoritative Game State
- `FIX` UI, Domain-Logik, Netzwerk und persistente Daten werden getrennt
- `FIX` Szenen enthalten Darstellung; Regeln gehören nicht in UI-Nodes
- `FIX` Netzwerk-RPCs dürfen Game State nicht direkt ungeprüft verändern
- `FIX` Regeln sollen ohne aktive UI testbar sein
- `FIX` Map-Daten sollen datengetrieben sein

## 2. Architektur-Layer

```text
Presentation / Scenes / UI
          |
Application Controllers
          |
Game Domain / Rules / State
          |
Networking + Backend Adapters
          |
Godot / WebRTC / HTTP / Filesystem
```

Abhängigkeiten sollen grundsätzlich nach unten zeigen. Domain-Regeln dürfen nicht von konkreten UI-Szenen abhängen.

## 3. Autoloads

V1-Autoloads:

```text
App
SceneRouter
NetworkManager
BackendClient
SessionManager
SettingsManager
AudioManager
```

### App

- globaler Anwendungszustand
- Build-/Protocol-Version
- Start-/Shutdown-Koordination
- keine eigentliche Spielregel-Logik

### SceneRouter

- kontrollierte Szenenwechsel
- Loading Screen
- Rückkehr ins Hauptmenü
- verhindert verteilte `change_scene`-Aufrufe

### NetworkManager

- WebRTC Peer-Verbindungen
- Godot MultiplayerPeer-Integration
- Peer Lifecycle
- RPC-/Message-Transport
- Verbindungsstatus
- keine Regelentscheidung

### BackendClient

- HTTPS-Aufrufe
- Signaling WebSocket
- Lobby registrieren/auflösen
- Heartbeats
- Join-/Host-Token im Speicher
- ICE-/TURN-Konfiguration abrufen

### SessionManager

- lokale Session-Identität
- player_id
- reconnect_token
- host/client Rolle
- aktuelle Lobby-/Match-ID
- Session-Cleanup

### SettingsManager

- lokale Einstellungen laden/speichern
- Audio
- Video
- Sprache
- Spielername

### AudioManager

- Musik
- SFX
- Lautstärkegruppen

## 4. Keine Autoloads

Folgende Systeme werden bewusst nicht global als Singleton angelegt:

```text
GameState
TurnManager
CombatManager
ReinforcementManager
CardManager
MapController
LobbyController
```

Sie gehören zur jeweiligen Lobby-/Game-Session und werden mit ihr erzeugt und zerstört. Dadurch bleibt ein Match sauber isoliert.

## 5. Hauptszenen

```text
Boot.tscn
MainMenu.tscn
CreateLobby.tscn
JoinLobby.tscn
Lobby.tscn
Game.tscn
Settings.tscn
```

Modale UI-Komponenten:

```text
ErrorDialog.tscn
ConfirmDialog.tscn
ReconnectOverlay.tscn
PauseMenu.tscn
CombatPanel.tscn
ConquestMoveDialog.tscn
FortificationPanel.tscn
CardTradePanel.tscn
VictoryScreen.tscn
EliminatedOverlay.tscn
```

## 6. Game Scene

Vorgesehene Struktur:

```text
Game
├── GameController
├── Domain
│   ├── GameState
│   ├── TurnManager
│   ├── ReinforcementManager
│   ├── CombatManager
│   ├── FortificationManager
│   ├── CardManager
│   └── VictoryManager
├── Map
│   ├── MapController
│   ├── TerritoryLayer
│   ├── ConnectionLayer
│   └── MarkerLayer
├── UI
│   ├── HUD
│   ├── PlayerList
│   ├── PhasePanel
│   ├── ActionPanel
│   └── ModalLayer
└── Effects
```

Konkrete Node-Typen werden erst bei Implementierung gewählt; die Verantwortungsgrenzen gelten unabhängig davon.

## 7. Domain Models

V1 benötigt mindestens:

```text
GameState
PlayerState
TerritoryState
Ruleset
TurnState
CombatState
CardState
DeckState
MatchResult
```

### GameState

Logisch:

```text
match_id
state_revision
status
ruleset
players
territories
turn_state
deck_state
combat_state
winner_player_id
```

### PlayerState

```text
player_id
name
color
connection_state
is_eliminated
has_surrendered
territory_card_ids
reinforcements_remaining
```

### TerritoryState

```text
territory_id
owner_player_id
army_count
```

Statische Dinge wie Name, Region und Nachbarschaften gehören nicht in `TerritoryState`, sondern in `MapData`.

## 8. Static Data Resources

Statische Spieldaten:

```text
MapData
TerritoryDefinition
RegionDefinition
CardDefinition
DefaultRuleset
```

Diese Daten verändern sich während eines Matches nicht.

Ziel:

```text
MapData
├── territories[42]
├── regions[6]
└── schema_version
```

## 9. Ruleset

`Ruleset` ist eine serialisierbare, validierbare Datenstruktur.

Mindestens:

```text
territory_assignment_mode
starting_armies_mode
starting_armies_by_player_count
starting_player_rule
turn_timer_seconds
reconnect_timeout_seconds
territory_cards_enabled
card_bonus_mode
progressive_card_values
forced_trade_threshold
owned_territory_card_bonus
continent_bonus_enabled
fortification_mode
unlimited_fortification
surrender_allowed
spectating_allowed
victory_condition
```

Nach Matchstart:

```text
Ruleset = immutable
```

Clients dürfen Ruleset-Werte anzeigen, aber nicht autoritativ ändern.

## 10. Match State Machine

```text
INITIALIZING
STARTING_SETUP
PLAYING
PAUSED_HOST_DISCONNECTED
FINISHED
TERMINATED
```

## 11. Turn State Machine

```text
TURN_START
CARD_TRADE
REINFORCEMENT
ATTACK
FORTIFICATION
TURN_END
```

Nur definierte Übergänge sind zulässig.

Beispiel:

```text
TURN_START -> CARD_TRADE
CARD_TRADE -> REINFORCEMENT
REINFORCEMENT -> ATTACK
ATTACK -> FORTIFICATION
FORTIFICATION -> TURN_END
TURN_END -> TURN_START
```

Deaktivierte optionale Systeme werden kontrolliert übersprungen.

## 12. Command Pattern für Spieleraktionen

UI verändert Game State niemals direkt.

Beispiel:

```text
UI Click
  -> AttackCommand
  -> GameController
  -> bei Client: NetworkManager -> Host
  -> bei Host: CommandValidator
  -> Domain Manager
  -> GameState Mutation
  -> state_revision++
  -> Event/Result
  -> Replikation
  -> UI aktualisiert sich
```

Commands mindestens:

```text
PlaceReinforcementCommand
AttackCommand
ResolveCombatCommand
ConquestMoveCommand
FortifyCommand
TradeCardsCommand
EndPhaseCommand
EndTurnCommand
SurrenderCommand
```

## 13. Host Validation Pipeline

Jeder eingehende Command:

```text
1. Envelope validieren
2. Session/Player validieren
3. action_id auf Duplikat prüfen
4. state_revision prüfen
5. Matchstatus prüfen
6. aktiven Spieler prüfen
7. Phase prüfen
8. Command-Payload validieren
9. Ruleset anwenden
10. Domain-Regel validieren
11. Mutation durchführen
12. state_revision erhöhen
13. Result erzeugen
14. replizieren
```

Bei Fehler findet keine teilweise Mutation statt.

## 14. Events

Domain erzeugt semantische Events, z. B.:

```text
ReinforcementsPlaced
AttackStarted
DiceRolled
ArmiesLost
TerritoryConquered
CardsTraded
PlayerEliminated
PlayerSurrendered
TurnEnded
TurnStarted
MatchWon
```

UI und Netzwerk reagieren auf Ergebnisse/Events, statt Regeln selbst zu rekonstruieren.

## 15. Signals

Godot-Signale primär für lokale lose Kopplung:

```text
state_changed
phase_changed
turn_changed
connection_changed
lobby_changed
error_occurred
territory_selected
```

Keine Signalkette darf die autoritative Validierung umgehen.

## 16. Network Boundary

Netzwerkcode darf nur definierte DTOs/Commands/Snapshots übertragen.

Nicht über Netzwerk senden:

- Node-Referenzen
- SceneTree-Pfade als Game-Identifier
- Callable
- beliebige Godot Objects
- ungefilterte Dictionaries aus UI

Territorien werden über stabile IDs wie `NA_01` übertragen.

Spieler werden über `player_id` übertragen.

## 17. Snapshots

`GameStateSnapshot` enthält den vollständigen replizierbaren Zustand.

Verwendung:

- Matchstart
- Reconnect
- Desync Recovery
- optional Debugging

Normales Gameplay verwendet Events/Results statt nach jeder Aktion den kompletten State zu übertragen.

## 18. RNG

- `FIX` Gameplay-RNG ausschließlich autoritativ beim Host
- Würfel niemals vom Client bestimmen lassen
- Shuffle des Kartendecks beim Host
- Startverteilung beim Host
- Random-Tiebreak beim Host

RNG soll hinter einer kleinen Schnittstelle liegen, damit Tests deterministische Seeds verwenden können.

## 19. MapController

Verantwortlich für Darstellung/Interaktion:

- Territory Hover
- Territory Selection
- Army Marker
- Besitzerfarbe
- erlaubte Ziel-Highlights
- Kamera/Zoom

Nicht verantwortlich für:

- Nachbarschaft als Wahrheit
- Angriffsgültigkeit
- Truppenverlust
- Besitzerwechsel

Diese Entscheidungen kommen aus Domain-Daten/Regeln.

## 20. UI State

UI besitzt lokalen transienten Zustand, z. B.:

```text
selected_territory_id
hovered_territory_id
pending_army_amount
open_modal
camera_position
```

Dieser Zustand gehört nicht in den autoritativen `GameState`.

## 21. Save / Config

V1 lokale Dateien:

```text
user://settings.cfg
user://session.dat
```

`session.dat` darf nur für notwendige Reconnect-Metadaten verwendet werden.

Secrets nicht dauerhaft speichern, wenn sie nicht für Reconnect benötigt werden. Reconnect-Daten nach Matchende löschen.

## 22. Projektstruktur

```text
res://
├── assets/
│   ├── audio/
│   ├── fonts/
│   ├── icons/
│   ├── map/
│   └── ui/
├── data/
│   ├── maps/
│   ├── rulesets/
│   └── localization/
├── resources/
│   ├── map/
│   ├── rules/
│   └── cards/
├── scenes/
│   ├── boot/
│   ├── menu/
│   ├── lobby/
│   ├── game/
│   ├── map/
│   └── ui/
├── scripts/
│   ├── app/
│   ├── backend/
│   ├── domain/
│   │   ├── cards/
│   │   ├── combat/
│   │   ├── commands/
│   │   ├── map/
│   │   ├── rules/
│   │   └── state/
│   ├── lobby/
│   ├── network/
│   ├── presentation/
│   └── persistence/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
└── project.godot
```

## 23. Naming Conventions

GDScript:

```text
class_name: PascalCase
Dateien: snake_case.gd
Variablen: snake_case
Funktionen: snake_case()
Konstanten: SCREAMING_SNAKE_CASE
Signale: snake_case
Enums: PascalCase
Enum-Werte: SCREAMING_SNAKE_CASE
```

Scenes:

```text
PascalCase.tscn
```

Territory IDs:

```text
NA_01
EU_04
AS_12
```

Network Actions:

```text
snake_case oder stabile numerische IDs nach finalem Protocol Schema
```

## 24. Fehlerbehandlung

Domain-Fehler werden als definierte Codes behandelt, nicht als UI-Strings.

Beispiel:

```text
NOT_YOUR_TURN
INVALID_PHASE
NOT_ADJACENT
INSUFFICIENT_TROOPS
STALE_STATE
```

Presentation übersetzt Fehlercodes in lokalisierte Texte.

## 25. Tests

Unit Tests mindestens für:

- Verstärkungsberechnung
- Kontinentbonus
- Nachbarschaft
- Angriffsgültigkeit
- Würfelvergleich
- Eroberung
- Fortification Pathfinding
- Karten-Sets
- progressive Kartenboni
- Pflichttausch
- Eliminierung
- Siegprüfung
- Turn State Machine
- Ruleset Validation
- Map Validator

Integration Tests mindestens für:

- Lobby Start
- zwei lokale Peers
- Action Request -> Host -> Result
- stale revision
- duplicate action_id
- Disconnect/Reconnect
- vollständiger Snapshot
- Matchende

## 26. Deterministische Tests

Domain-Tests dürfen nicht von echter Netzwerkverbindung, Animation oder zufälligem RNG abhängen.

Dafür abstrahieren:

```text
RandomSource
Clock
NetworkTransport
BackendTransport
```

Testimplementierungen können feste Werte liefern.

## 27. Logging

Log-Kategorien:

```text
APP
BACKEND
SIGNALING
NETWORK
LOBBY
GAME
RULES
STATE
```

Keine Secrets loggen.

Für State-Probleme hilfreich:

```text
match_id
action_id
state_revision
player_id
action_type
result_code
```

## 28. Performance

Das Spiel ist rundenbasiert; Optimierungsschwerpunkte sind nicht Tickrate oder Physics.

Prioritäten:

1. korrekter State
2. deterministische Regeln
3. robuste Reconnects
4. klare UI-Reaktion
5. geringe Netzwerkkomplexität

## 29. Architekturregeln

1. UI schreibt nie direkt in `GameState`.
2. Client entscheidet nie autoritativ über Gameplay.
3. Host validiert jeden Command.
4. Statische Map-Daten und dynamischer Match-State bleiben getrennt.
5. IDs statt Node-Referenzen über Layergrenzen.
6. Ruleset wird vor Matchstart validiert und danach eingefroren.
7. Domain-Code muss ohne aktive Game-Szene testbar sein.
8. Netzwerkserialisierung wird zentral definiert.
9. Reconnect ersetzt lokalen State durch Host-Snapshot.
10. Keine Game-Regel wird ausschließlich durch UI-Verhalten erzwungen.

## 30. Noch offen

- konkrete Godot-WebRTC-GDExtension-Version passend zu Godot 4.7.2
- Testframework/Runner
- konkretes Serialisierungsformat der Game Messages
- Localization-System und V1-Sprachen
- genaue Map-Rendering-Technik
- Input-Mapping
- UI-Auflösung/Scaling-Strategie
- konkretes Theme-System

## 31. Definition of Done — Architekturgrundgerüst

Das Projektgrundgerüst gilt als fertig, wenn:

- Ordnerstruktur existiert
- Autoloads angelegt und registriert sind
- Boot -> MainMenu funktioniert
- Settings laden/speichern
- BackendClient besitzt klare Schnittstelle
- NetworkManager besitzt klare Schnittstelle
- Ruleset kann erstellt/validiert werden
- MapData kann geladen und validiert werden
- GameState kann ohne UI erzeugt werden
- Turn State Machine funktioniert isoliert
- Commands können hostseitig validiert werden
- Unit-Test-Grundgerüst läuft
- keine Domain-Klasse von einer konkreten UI-Szene abhängt

## V1 private-host networking

`NetworkManager` selects `DIRECT_HOST` for the normal Create Lobby and Join
flow. `DirectNetworkTransport` provides reliable ordered TCP with a stable
configurable default port (`43100`). The host owns the authoritative
`GameState`, `LobbyState`, RNG, validation, player slots, and local reconnect
registry. The existing command, snapshot, revision, privacy, timer, and host-
loss layers remain unchanged.

`DirectInvite` encodes a versioned, self-contained `AF1` invite containing the
advertised endpoint, session identity, join capability, protocol/product
versions, and checksum. The host assigns player IDs only after validating the
invite and handshake. Reconnect tokens are host-issued, hashed at rest,
rotated by generation, and separate from the invite join secret.

`BackendClient` and `WebRTCNetworkTransport` remain available for explicit
development/future central-service modes. They are not initialized as a
requirement of the V1 direct lobby flow.
