# RisikoLike — Implementation Roadmap

> **Status:** Pre-Production -> Implementation  
> **Dokumentversion:** 0.1  
> **Ziel:** Implementierungsreihenfolge für eine spielbare V1 mit möglichst frühen vertikalen End-to-End-Slices.

## Leitprinzip

Wir entwickeln nicht erst alle Menüs, dann alle Regeln und zuletzt Multiplayer. Jeder größere Meilenstein soll einen testbaren vertikalen Ausschnitt liefern.

Priorität:

```text
Correctness -> Multiplayer-Grundlage -> kompletter Game Loop -> UX -> Polish
```

---

# M0 — Repository & Godot Foundation

## Ziel

Das Repository enthält ein sauberes startbares Godot-Projekt mit der vereinbarten Architektur.

## Aufgaben

- Godot-Projekt auf 4.7.2 stable prüfen/setzen
- `.gitignore` prüfen
- Projektordner gemäß `docs/GODOT_ARCHITECTURE.md` anlegen
- Boot Scene
- Main Menu Scene
- Autoloads anlegen:
  - App
  - SceneRouter
  - NetworkManager
  - BackendClient
  - SessionManager
  - SettingsManager
  - AudioManager
- Basis-Logging
- Build-/Protocol-Version zentral definieren
- Settings Load/Save
- grundlegendes Theme/Placeholder UI
- Debug-Konfiguration

## Done

```text
Godot startet
-> Boot
-> Main Menu
-> Settings können gespeichert werden
-> keine Parser-/Runtime-Fehler
```

---

# M1 — Domain Core & Map Data

## Ziel

Spielregeln können ohne UI und ohne Netzwerk ausgeführt und getestet werden.

## Aufgaben

### Map

- `MapData`
- `TerritoryDefinition`
- `RegionDefinition`
- 42 Territorien als echte Daten übernehmen
- Map Validator implementieren
- Regionsgrößen prüfen
- bidirektionale Nachbarschaften prüfen
- Graph Connectivity prüfen
- 14/14/14 Kartensymbole prüfen

### State

- `GameState`
- `PlayerState`
- `TerritoryState`
- `TurnState`
- `Ruleset`
- Default Ruleset
- Ruleset Validator

### Core Rules

- Verstärkungsberechnung
- Kontinentboni
- Turn State Machine
- Startspielerlogik
- Victory Check
- deterministic `RandomSource`

## Tests

- 42 Territories
- Regions 9/4/7/6/12/4
- Reinforcement floor + Minimum 3
- Continent bonus
- Turn transitions
- Ruleset invalid/valid
- start player tie randomization

## Done

Ein Headless-/Testlauf kann einen gültigen Match-State erzeugen und mehrere leere Züge ohne UI durchlaufen.

---

# M2 — Minimal Local Board

## Ziel

Die 42 Gebiete sind in Godot sichtbar und interaktiv, zunächst mit Placeholder-Grafik.

## Aufgaben

- `Game.tscn`
- `MapController`
- Territory Nodes/Hit Areas
- Territory Hover
- Territory Selection
- Army Marker
- Besitzerfarbe
- Truppenanzahl
- Pan/Zoom
- Player Panel Placeholder
- Top Bar Placeholder
- Phase Anzeige

## Wichtig

Die finale schöne Weltkarte ist **keine Voraussetzung** für diesen Milestone. Funktionale Polygone/Placeholder reichen.

## Done

Ein lokales Debug-Match zeigt 42 anklickbare Gebiete mit Besitzer und Truppenanzahl.

---

# M3 — Reinforcement Vertical Slice

## Ziel

Eine vollständige erste autoritative Spieleraktion funktioniert lokal durch die endgültige Command-Pipeline.

## Aufgaben

- Command Envelope
- `action_id`
- `state_revision`
- Command Validator
- `PlaceReinforcementCommand`
- Reinforcement Manager
- Domain Event/Result
- UI Reinforcement Controls
- lokale Pending Selection
- Confirm/Reset
- Fehlercodes

## Done

```text
Spieler klickt Gebiet
-> wählt Truppen
-> bestätigt
-> Command wird validiert
-> GameState mutiert
-> state_revision steigt
-> UI aktualisiert sich aus Result/State
```

Keine UI schreibt direkt in `GameState`.

---

# M4 — Local Hotseat Game Loop

## Ziel

Das komplette Spiel ist auf einem PC ohne Netzwerk spielbar.

## Aufgaben

### Attack

- Attack validation
- Würfelanzahl
- Host/Local RNG
- Würfelvergleich
- Verluste
- Eroberung
- Conquest Move

### Fortification

- Connected Pathfinding
- Adjacent Mode
- eine Bewegung pro Zug

### Cards

- Deck
- Shuffle
- Draw
- gültige Sets
- Joker
- progressive Werte
- globaler Trade Counter
- Pflichttausch
- Territory +2 Bonus
- Kartenübernahme bei Eliminierung

### Match Lifecycle

- Eliminierung
- Aufgabe
- Siegprüfung
- Match Result

## Done

2–5 lokale Debug-Spieler können eine vollständige Partie bis zum Sieg durchspielen.

---

# M5 — Local Multiplayer Transport Prototype

> **Status:** Abgeschlossen — lokaler TCP-Transport, Host-Authority, Snapshots, Privacy-Filter, Recovery und Zwei-Prozess-Smoke-Test validiert.

## Ziel

Zwei Godot-Instanzen kommunizieren über die gleiche Message-/Command-Schicht, die später Internet-WebRTC nutzt.

## Aufgaben

- Network DTO Schema
- Command Serialization
- Result/Event Serialization
- Snapshot Serialization
- Host Role
- Client Role
- Peer Join
- initial Snapshot
- Action Request
- Action Result
- stale revision handling
- duplicate `action_id`
- Client darf Game State nicht autoritativ verändern

## Test Slice

Zwei lokale Instanzen:

```text
Host startet Debug Match
Client verbindet
Client erhält Snapshot
Client setzt Verstärkung
Host validiert
beide sehen identischen State
```

## Done

State Hash/Revision ist nach Aktionen auf Host und Client identisch.

---

# M6 — Lobby Local Prototype

> **Status:** Abgeschlossen — Create/Join/Lobby, Ready, Ruleset-Sync, Matchstart, Leave und Host-Close validiert.

## Ziel

Der echte Lobby-Flow funktioniert lokal vor Backend/Internet.

## Aufgaben

- Create Lobby Screen
- Join Lobby Screen
- Lobby Screen
- Player Slots
- Host Badge
- Ready State
- Ruleset Editor
- Rules Summary
- Start Conditions
- Match Start Snapshot
- Lobby Leave

## Done

Zwei lokale Instanzen können Lobby -> Ready -> Match gemeinsam durchlaufen.

---

# M7 — Backend Minimum Viable Service

> **Status:** Abgeschlossen — FastAPI/Uvicorn-Rendezvous, Invite-Codes, Token-Auth, TTL/Heartbeat, REST und authentifiziertes WebSocket-Signaling validiert.

## Ziel

Invite-Code und Signaling-Service existieren als minimaler Entwicklungsbackend.

## Aufgaben

- Backend-Technologie endgültig festlegen
- `/v1/lobbies`
- `/resolve`
- heartbeat
- close
- Invite-Code Generator
- Lobby Registry
- Token Service
- WSS Signaling
- Host Auth
- Join Auth
- Offer/Answer Relay
- ICE Candidate Relay
- Rate Limit Basis
- Secret-safe Logging

## Entwicklungsbetrieb

Zunächst lokal/Development Deployment.

## Done

Host erhält `ABC-123`; zweiter Client kann diesen Code über Backend erfolgreich auflösen.

---

# M8 — WebRTC Internet Multiplayer

> **Status:** Technisch implementiert — lokaler Zwei-Prozess-WebRTC-Flow über Backend/Signaling/Data Channel und autorisierte Reinforcement-Aktion validiert. Getrennte-Netzwerke- und erzwungene-TURN-Runtime-Abnahme bleiben manuell ausstehend.

## Ziel

Invite-Code führt zu echter Peer-Verbindung ohne manuelle IP/Port-Eingabe.

## Aufgaben

- passende WebRTC GDExtension integrieren
- WebRTC peer setup
- Signaling anbinden
- ICE
- STUN
- TURN Credentials
- TURN Fallback
- reliable Data Channel
- Godot Multiplayer Integration
- Connection State UI

## Testmatrix

- gleiches LAN
- verschiedene Netzwerke
- Host hinter NAT
- Client hinter NAT
- TURN-erzwungener Test
- Paketverlust/kurze Unterbrechung

## Done

Zwei PCs in unterschiedlichen normalen Heimnetzwerken können per Invite-Code eine Lobby öffnen und eine Aktion synchron ausführen, ohne Router-Portfreigabe.

---

# M9 — Full Multiplayer Game Loop

> **Status:** Abgeschlossen — vollständiger host-autoritärer 2-Spieler-WebRTC-Full-Match inklusive Kartenhandel, Würfeln, Eroberung, Fortifikation, Kartenziehen, Eliminierung, Aufgabe und Sieg über zwei getrennte Prozesse validiert. Die M8-Manual-Gates für getrennte Netzwerke und erzwungenes TURN bleiben offen.

## Ziel

Alle bereits lokal funktionierenden Spielregeln funktionieren host-authoritativ über Netzwerk.

## Aufgaben

- Reinforcement Commands
- Card Trade Commands
- Attack Commands
- Dice Results
- Conquest Move
- Fortification
- End Phase/Turn
- Eliminierung
- Aufgabe
- Sieg
- Timer
- spectator state

## Done

Eine komplette 2-Spieler-Partie kann über Internet bis zum Sieg gespielt werden.

Danach 3–5 Spieler testen.

---

# M10 — Disconnect & Reconnect

> **Status:** Abgeschlossen — Backend-Credentials mit Rotation/Replay-Schutz, host-autoritatives State-Preservation, player-spezifischer Snapshot-Recovery und ein echter lokaler Zwei-Prozess-WebRTC-Hard-Drop-Harness mit zwei Reconnect-Generationen sind grün. M8-Real-Network/TURN-Manual-Gates bleiben offen; M11 ist nicht gestartet.

## Ziel

Verbindungsabbrüche zerstören die Partie nicht sofort.

## Aufgaben

- disconnect detection
- reconnect token
- reconnect grace timer
- reconnect signaling
- player_id restoration
- vollständiger Host Snapshot
- State Replacement
- Host Disconnect Overlay
- Client Disconnect Overlay
- Zugtimer-Verhalten
- Reconnect während eigenem Zug
- Reconnect nach State-Änderungen
- Timeout -> verlassen

## Done

Client kann während laufender Partie Netzwerk verlieren, innerhalb der Grace Period über eine neue WebRTC-Verbindung authentifiziert werden und mit korrektem player-spezifischem State weiterspielen. Verifiziert sind unter anderem partielle Reinforcement, Pending Conquest, Fortification, Privacy, ungültige Conquest, zwei aufeinanderfolgende Reconnects sowie Abschluss bis zum Harness-Ende.

---

# M11 — Timer, AFK, Surrender, Spectator

## Ziel

Alle Multiplayer-Randfälle aus dem GDD sind spielbar.

## Aufgaben

- Turn Timer
- 30s Warning
- Auto-End Turn
- Pending Action Cleanup
- AFK via Timer
- Surrender Confirmation
- surrendered territory behavior
- eliminated spectator
- freiwilliges Verlassen
- Host timeout -> Match End

## Done

Alle definierten Lifecycle-Zustände besitzen korrekte Domain-Logik und UI.

---

# M12 — Production Map & Visual Pass

## Ziel

Placeholder-Karte wird durch eigenes finales Kartenasset ersetzt.

## Aufgaben

- eigene Weltkartenbasis
- 42 finale Territory Shapes
- Region Styling
- Borders
- Water Connections
- Alaska/Kamtschatka Edge Connection
- Army Marker Positions
- Labels/Tooltips
- Hover
- Selected
- Valid Target
- Invalid Target
- Zoom/Readability

## Validierung

Asset muss `MAP_SPEC.md` exakt entsprechen.

## Done

Jedes Territory ist eindeutig anklickbar und visuell mit den Daten konsistent.

---

# M13 — UI Visual Pass

## Ziel

Funktionale Debug-UI wird zur konsistenten V1-Oberfläche.

## Aufgaben

- Theme
- Buttons
- Panels
- Typography
- Icons
- Lobby polish
- HUD polish
- Combat Panel
- Card UI
- Dice presentation
- loading states
- errors
- reconnect UX
- victory screen
- 720p/1080p/1440p/4K scaling

## Done

Alle Screens aus `UI_UX_SPEC.md` erfüllen ihren V1-Zustand.

---

# M14 — Audio & Feedback

## Aufgaben

- UI Click
- Error
- Notification
- Turn Start
- Own Turn
- Dice Roll
- Conquest
- Card Draw
- Card Trade
- Elimination
- Victory
- optional Music
- Audio Settings

## Done

Audio ist funktional, regelbar und blockiert keine Spielfunktion.

---

# M15 — Hardening

## Ziel

V1 gegen Desyncs, ungültige Eingaben und typische Netzwerkfehler härten.

## Aufgaben

- Fuzz/invalid command tests
- stale revisions
- duplicate commands
- malformed payloads
- oversized messages
- rapid reconnect
- lobby expiration
- token expiration
- version mismatch
- forced TURN
- host quit
- client quit
- simultaneous joins
- 5-player soak test
- long match
- empty deck reshuffle
- extreme progressive card values
- timer expiration in jeder Phase

## Done

Keine bekannten Blocker/High-Severity-Fehler im V1-Flow.

---

# M16 — Packaging & Release Candidate

## Aufgaben

- Windows export preset
- Release build
- Version metadata
- production backend URLs
- TLS
- TURN production config
- logging level
- crash/log collection Entscheidung
- README
- Controls/How to Play
- Third-party licenses
- Asset licenses
- clean install test
- Windows Defender/SmartScreen Verhalten prüfen

## Done

Ein neuer Windows-PC kann den Build installieren/starten und eine Internet-Partie über Invite-Code spielen.

---

# Milestone-Abhängigkeiten

```text
M0
└─ M1
   └─ M2
      └─ M3
         └─ M4
            └─ M5
               ├─ M6
               └─ M7
                  └─ M8
                     └─ M9
                        └─ M10
                           └─ M11
                              ├─ M12
                              ├─ M13
                              └─ M14
                                 └─ M15
                                    └─ M16
```

M12–M14 können teilweise parallel zu später Multiplayer-Arbeit erfolgen, sobald die zugrunde liegenden Interfaces stabil sind.

---

# Was wir bewusst NICHT zuerst machen

Nicht vorziehen:

- finale Art Assets
- aufwendige Animationen
- Musik
- Dedicated Server
- Accounts
- Matchmaking
- Ranglisten
- KI
- Host Migration
- Unlimited Fortification
- Chat
- Replay System

Erst muss der autoritative vollständige Multiplayer-Game-Loop stabil sein.

---

# Erste konkrete Implementierungsreihenfolge

Wenn die Implementierung beginnt:

```text
1. Repository/Godot-Projekt prüfen
2. Ordnerstruktur
3. Autoload Skeletons
4. Boot + Main Menu
5. Ruleset Model
6. MapData Model
7. 42 Territory Daten
8. Map Validator
9. GameState Models
10. Turn State Machine
11. Unit Tests
12. Placeholder Game Scene
13. Territory Selection
14. Reinforcement Command
15. Host Validation Pipeline
```

Erst danach wird der erste Netzwerk-Slice aufgebaut.

---

# V1 Exit Criteria

V1 ist erreicht, wenn mindestens:

- Windows Build
- 2–5 Spieler
- Invite-Code Lobby
- kein manuelles Port Forwarding
- WebRTC + TURN Fallback
- Host-authoritative State
- 42 Territory Map
- Random/Manual Start Territory Mode
- Reinforcement
- Continent Bonuses
- Attack/Dice Combat
- Conquest Movement
- Fortification
- Territory Cards
- progressive Card Sets
- Elimination
- Surrender
- Spectator
- Turn Timer
- Disconnect/Reconnect
- World Conquest Victory
- Settings
- definierte Fehler-/Loading-Zustände
- vollständiger Match von Lobby bis Victory ohne Debug-Werkzeuge spielbar

funktionieren.
