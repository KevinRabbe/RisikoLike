# RisikoLike — Game Design Document

> **Status:** Pre-Production / Spezifikation  
> **Dokumentversion:** 0.1  
> **Ziel:** Dieses Dokument ist die verbindliche Source of Truth für Design, Regeln, Multiplayer, UI und technische Grundentscheidungen vor Beginn der eigentlichen Implementierung.

## Status-Legende

- `FIX` — beschlossen
- `OFFEN` — muss entschieden werden
- `V1` — Bestandteil der ersten spielbaren Version
- `SPÄTER` — bewusst nicht Bestandteil von V1
- `VERWORFEN` — explizit ausgeschlossen

---

# 1. Projektübersicht

| ID | Punkt | Status | Festlegung |
|---|---|---|---|
| GDD-PROJ-001 | Arbeitstitel | FIX | RisikoLike |
| GDD-PROJ-002 | Engine | FIX | Godot |
| GDD-PROJ-003 | Primärplattform | FIX | Windows PC |
| GDD-PROJ-004 | Genre | FIX | Rundenbasiertes Multiplayer-Gebietseroberungs-Strategiespiel |
| GDD-PROJ-005 | Kernmodus | FIX / V1 | Private Multiplayer-Partie mit Host und Invite-Code |
| GDD-PROJ-006 | Spieleranzahl | OFFEN | Zielbereich zunächst 2–5 Spieler; final festlegen |
| GDD-PROJ-007 | Sprache V1 | OFFEN | Deutsch / Englisch / beide |
| GDD-PROJ-008 | Ziel-Spieldauer | OFFEN | Noch festzulegen |
| GDD-PROJ-009 | Eigene Spielidentität | FIX | Eigener Name, eigene Grafik, eigene UI und eigene Kartenpräsentation |

# 2. Designziele

- `FIX` Leicht verständlicher rundenbasierter Spielfluss.
- `FIX` Private Partien sollen mit möglichst wenigen Schritten gestartet werden können.
- `FIX` Ein Spieler hostet die Partie.
- `FIX` Andere Spieler treten über einen Invite-Code bei.
- `FIX` Der Host ist für den autoritativen Game State verantwortlich.
- `FIX` Regeln und Game State werden von Darstellung/UI getrennt.
- `FIX` Keine Abhängigkeit von geschützten Originalgrafiken oder Originaltexten eines kommerziellen Brettspiels.
- `V1` Fokus auf einen stabilen Kernmodus statt großer Feature-Menge.

# 3. Scope V1

- Hauptmenü
- Spielername
- Lobby erstellen
- Invite-Code erzeugen
- Lobby per Invite-Code beitreten
- Lobby-Spielerliste
- Ready-System
- Host kann Partie starten
- Eigene Welt-/Gebietskarte
- Territorien auswählen
- Territoriumsbesitz
- Truppen pro Territorium
- Verstärkungsphase
- Angriffsphase
- Würfelkampf
- Gebietseroberung
- Truppenbewegungsphase
- Zugwechsel
- Spielerausscheidung
- Siegbedingung
- Disconnect-Behandlung
- Reconnect-Grundfunktion
- Rückkehr ins Hauptmenü

# 4. Nicht-Ziele für V1

- `SPÄTER` KI-Spieler
- `SPÄTER` Singleplayer
- `SPÄTER` Öffentliche Lobby-Liste
- `SPÄTER` Matchmaking
- `SPÄTER` Accounts
- `SPÄTER` Freundesliste
- `SPÄTER` Ranglisten
- `SPÄTER` Achievements
- `SPÄTER` Replays
- `SPÄTER` Zuschauer
- `SPÄTER` Map-Editor
- `SPÄTER` Steam-Integration
- `SPÄTER` Dedicated Game Server
- `SPÄTER` Alternative Karten
- `SPÄTER` Alternative Spielmodi

# 5. Spieler und Partie

| ID | Regel | Status | Festlegung |
|---|---|---|---|
| GDD-MATCH-001 | Mindestspielerzahl | OFFEN | |
| GDD-MATCH-002 | Maximalspielerzahl | OFFEN | |
| GDD-MATCH-003 | Startspieler-Auswahl | OFFEN | |
| GDD-MATCH-004 | Zugreihenfolge | OFFEN | |
| GDD-MATCH-005 | Spielerfarben | OFFEN | Farben und Auswahlverfahren festlegen |
| GDD-MATCH-006 | Ausscheiden | FIX | Spieler scheidet aus, wenn er kein Territorium mehr kontrolliert |
| GDD-MATCH-007 | Haupt-Siegbedingung | OFFEN | Welteroberung als V1-Kandidat |
| GDD-MATCH-008 | Unentschieden | OFFEN | |
| GDD-MATCH-009 | Aufgabe | OFFEN | Verhalten bei freiwilligem Verlassen festlegen |

# 6. Spielaufbau

- Anzahl Territorien: `OFFEN`
- Anzahl Regionen/Kontinente: `OFFEN`
- Startgebietsverteilung: `OFFEN`
- Starttruppen je Spieler: `OFFEN`
- Starttruppen auf Startgebieten: `OFFEN`
- Reihenfolge der Startplatzierung: `OFFEN`
- Zufällige oder manuelle Gebietsverteilung: `OFFEN`
- Neutral kontrollierte Gebiete: `OFFEN`
- Startspieler: `OFFEN`

# 7. Karte und Territorien

Jedes Territorium benötigt mindestens:

- eindeutige Territory-ID
- Anzeigename
- Region/Kontinent
- Liste benachbarter Territory-IDs
- Besitzer-ID
- Truppenanzahl
- Kartenposition
- Position der Truppenanzeige
- klickbare Fläche/Polygon
- Hover-Darstellung
- Selected-Darstellung

Zu definieren:

- Kartenprojektion / Stil: `OFFEN`
- konkrete Territorien: `OFFEN`
- konkrete Nachbarschaften: `OFFEN`
- Wasserverbindungen: `OFFEN`
- Kartenrand-Verbindungen: `OFFEN`
- Regionen/Kontinente: `OFFEN`
- Regionsboni: `OFFEN`
- Zoom: `OFFEN`
- Kamerabewegung: `OFFEN`

# 8. Zugablauf

Vorgesehener Grundablauf:

1. Verstärken
2. Angreifen
3. Truppen bewegen
4. Zug beenden
5. Nächster aktiver Spieler

| ID | Regel | Status |
|---|---|---|
| GDD-TURN-001 | Phasenreihenfolge | FIX / V1 |
| GDD-TURN-002 | Verstärkungsphase überspringbar | OFFEN |
| GDD-TURN-003 | Angriffsphase überspringbar | OFFEN |
| GDD-TURN-004 | Bewegungsphase überspringbar | OFFEN |
| GDD-TURN-005 | Zug-Zeitlimit | OFFEN |
| GDD-TURN-006 | AFK-Regel | OFFEN |

# 9. Verstärkungen

Zu definieren:

- Basisformel für Gebietsverstärkung: `OFFEN`
- Mindestverstärkung: `OFFEN`
- Regions-/Kontinentbonus: `OFFEN`
- Zeitpunkt der Berechnung: `OFFEN`
- Platzierung nur auf eigenen Gebieten: `OFFEN`
- Verstärkungen müssen vollständig verteilt werden: `OFFEN`
- Rücknahme vor Bestätigung: `OFFEN`
- Bestätigungsmechanismus: `OFFEN`

# 10. Angriffssystem

Zu definieren:

- Angriff nur von eigenem Territorium: `OFFEN`
- Ziel muss feindlich sein: `OFFEN`
- Ziel muss benachbart sein: `OFFEN`
- Mindesttruppen für Angriff: `OFFEN`
- maximale Angriffswürfel: `OFFEN`
- maximale Verteidigungswürfel: `OFFEN`
- automatische oder manuelle Würfelanzahl: `OFFEN`
- weitere Angriffe nach Kampf: `OFFEN`
- Angriff jederzeit beenden: `OFFEN`
- Angriff mit letzter stationierter Truppe verboten: `OFFEN`

# 11. Würfelsystem

Zu definieren:

- Würfeltyp: `OFFEN`
- Anzahl Angreiferwürfel: `OFFEN`
- Anzahl Verteidigerwürfel: `OFFEN`
- Sortierung der Würfel: `OFFEN`
- Paarvergleich: `OFFEN`
- Gleichstand: `OFFEN`
- Verlust pro Vergleich: `OFFEN`
- RNG ausschließlich beim Host: `FIX / V1`
- Würfelergebnis wird an Clients repliziert: `FIX / V1`

# 12. Gebietseroberung

Zu definieren:

- Eroberung bei 0 verteidigenden Truppen: `OFFEN`
- Mindesttruppen, die einziehen müssen: `OFFEN`
- maximale einziehende Truppen: `OFFEN`
- manuelle Auswahl der einziehenden Truppen: `OFFEN`
- Besitzerwechsel: `V1`
- unmittelbare Sieg-/Eliminierungsprüfung: `OFFEN`
- Angriff nach Eroberung fortsetzbar: `OFFEN`

# 13. Truppenbewegung

Zu definieren:

- Anzahl Bewegungen pro Zug: `OFFEN`
- nur benachbarte Gebiete: `OFFEN`
- Bewegung über zusammenhängende eigene Gebiete: `OFFEN`
- Mindesttruppen im Ausgangsgebiet: `OFFEN`
- maximale bewegte Truppen: `OFFEN`
- Rücknahme vor Bestätigung: `OFFEN`

# 14. Sieg und Ausscheiden

- Haupt-Siegbedingung: `OFFEN`
- Siegprüfung nach jeder Eroberung: `OFFEN`
- Siegprüfung am Zugende: `OFFEN`
- Verhalten eliminierter Spieler: `OFFEN`
- Zuschauerstatus nach Eliminierung: `OFFEN`
- Verhalten ihrer Verbindung: `OFFEN`
- Ergebnisanzeige: `V1`
- Rematch: `SPÄTER`

# 15. Karten-/Bonussystem

- Gebietskarten: `OFFEN`
- Kartenerhalt: `OFFEN`
- Kartensets: `OFFEN`
- Karten eintauschen: `OFFEN`
- steigende Set-Boni: `OFFEN`
- Missionskarten: `SPÄTER`

Entscheidung erforderlich, ob Gebietskarten überhaupt Bestandteil von V1 werden.

# 16. Lobby

Benötigte Funktionen:

- Lobby erstellen
- Lobby verlassen
- Invite-Code anzeigen
- Invite-Code kopieren
- Invite-Code eingeben
- Lobby beitreten
- Spieler anzeigen
- Spielernamen anzeigen
- Spielerfarbe anzeigen
- Host markieren
- Ready-Status
- Ready umschalten
- Spieler kicken
- Spiel starten
- Lobby-Fehler anzeigen

Zu definieren:

- maximale Lobbygröße: `OFFEN`
- Farbwahl frei/automatisch: `OFFEN`
- Host muss Ready sein: `OFFEN`
- alle Clients müssen Ready sein: `OFFEN`
- Late Join nach Matchstart: `OFFEN`

# 17. Invite-Codes

Zu definieren:

- Code-Länge: `OFFEN`
- Zeichensatz: `OFFEN`
- Groß-/Kleinschreibung: `OFFEN`
- Lebensdauer: `OFFEN`
- Kollisionsbehandlung: `OFFEN`
- Lobby-Code wird serverseitig registriert: `V1`
- Code löst Verbindung zur Host-Session auf: `V1`
- Code wird nach Lobby-Ende ungültig: `V1`

# 18. Netzwerkmodell

- `FIX / V1` Host-authoritative Architektur
- `FIX / V1` Ein Spieler ist Host der Game Session
- `FIX / V1` Clients senden Aktionen/Intents, nicht autoritative State-Änderungen
- `FIX / V1` Host validiert Aktionen
- `FIX / V1` Host verändert Game State
- `FIX / V1` Host repliziert bestätigte Ergebnisse
- Transport/Protokoll: `OFFEN`
- NAT-Traversal/Relay: `OFFEN`
- Rendezvous-/Lobby-Service: `V1`, konkrete Technik `OFFEN`
- Verschlüsselung: `OFFEN`
- Heartbeat/Ping: `OFFEN`

# 19. Disconnect / Reconnect

Zu definieren:

- Reconnect erlaubt: `V1`
- Reconnect-Frist: `OFFEN`
- Zug pausiert bei Disconnect: `OFFEN`
- Zug läuft weiter: `OFFEN`
- Host-Disconnect: `OFFEN`
- Host-Migration: `OFFEN`
- Client-Disconnect: `OFFEN`
- freiwilliges Verlassen: `OFFEN`
- Verhalten der Territorien eines endgültig ausgeschiedenen Spielers: `OFFEN`
- Session-Token für Reconnect: `V1`

# 20. Game State

Der autoritative Game State muss mindestens enthalten:

- Match-ID
- Match-Status
- Regel-/Protokollversion
- Spieler
- Spieler-ID
- Spielername
- Spielerfarbe
- Verbindungsstatus
- Eliminierungsstatus
- Zugreihenfolge
- aktueller Spieler
- aktuelle Runde
- aktuelle Phase
- Territorien
- Besitzer jedes Territoriums
- Truppen jedes Territoriums
- verfügbare Verstärkungen
- laufender Kampf
- Würfelergebnisse
- letzte bestätigte Aktion
- Gewinner
- RNG-/Seed-Information soweit technisch erforderlich

# 21. UI-Screens

- Boot/Splash
- Hauptmenü
- Spielername
- Lobby erstellen
- Lobby beitreten
- Lobby
- Ladebildschirm
- Spiel
- Pause-Menü
- Einstellungen
- Disconnect/Reconnect
- Spieler ausgeschieden
- Sieg/Ergebnis
- Fehlerdialog

# 22. UI-Elemente

- Spiel-Logo
- Hauptmenü-Hintergrund
- Spiel erstellen
- Spiel beitreten
- Einstellungen
- Beenden
- Spielername-Eingabe
- Invite-Code-Anzeige
- Invite-Code-Kopieren
- Invite-Code-Eingabe
- Beitreten
- Lobby verlassen
- Spiel starten
- Spieler-Slots
- Spielername
- Spielerfarbe
- Host-Markierung
- Ready-Anzeige
- Ready-Button
- Kick-Button
- Verbindungsstatus
- Weltkarte
- Territorium-Hover
- Territorium-Selected
- Besitzerfarbe
- Truppenanzahl
- aktueller Spieler
- Spielerübersicht
- Zugphase
- verfügbare Verstärkungen
- Verstärken
- Angreifen
- Verschieben
- Zug beenden
- Plus
- Minus
- Bestätigen
- Abbrechen
- Angreifer
- Verteidiger
- Würfel
- Würfeln
- Kampfergebnis
- Eroberungsdialog
- Truppenverschiebungsdialog
- Pause
- Fortsetzen
- Partie verlassen
- Sieg
- Fehlermeldung
- Tooltip

# 23. Grafik-/Asset-Liste

- eigenes Logo
- App-Icon
- Menü-Hintergrund
- Karten-Hintergrund
- Territoriumsflächen/Masks
- Territoriumsgrenzen
- Regions-/Kontinentgrenzen
- Wasser-/Hintergrundgrafik
- Verbindungslinien
- Truppenmarker
- Spieler-/Farbmarker
- Host-Icon
- Ready-Icon
- Würfel 1–6
- Angriff-Icon
- Verteidigung-Icon
- Verstärkung-Icon
- Bewegung-Icon
- Einstellungen-Icon
- Audio-Icons
- Kopieren-Icon
- Zurück-Icon
- Schließen-Icon
- Warnung-Icon
- Verbindung-Icon
- Sieg-Grafik
- Cursor
- UI-Panels
- Buttons
- Eingabefelder
- Checkboxen
- Slider
- Schriftarten/Lizenzen

# 24. Audio

- Menü-Musik: `OFFEN`
- Spiel-Musik: `OFFEN`
- Button Hover
- Button Click
- Lobby Join
- Lobby Leave
- Spielstart
- Zugstart
- Gebiet auswählen
- Truppen platzieren
- Angriff
- Würfel
- Truppenverlust
- Gebiet erobert
- Fehler
- Benachrichtigung
- Sieg
- Niederlage/Ausscheiden

# 25. Einstellungen

- Master-Lautstärke
- Musik-Lautstärke
- Effekt-Lautstärke
- Vollbild/Fenster
- Auflösung
- VSync
- UI-Skalierung
- Sprache
- Spielername

Welche Einstellungen Bestandteil von V1 sind: `OFFEN`.

# 26. Speicherung

- lokale Einstellungen: `V1`
- Spielername: `V1`
- Audioeinstellungen: `V1`
- Grafikeinstellungen: `OFFEN`
- Reconnect-Daten: `V1`
- Savegame laufender Online-Partien: `OFFEN`
- Autosave: `OFFEN`

# 27. Fehler- und Randfälle

Vor Implementierung zu definieren/testen:

- Doppelklick / doppelte Aktion
- doppelt empfangenes Netzwerkpaket
- verspätete Aktion
- Aktion in falscher Reihenfolge
- Aktion eines falschen Spielers
- Aktion außerhalb der eigenen Phase
- Angriff auf Nicht-Nachbar
- Angriff auf eigenes Gebiet
- Angriff ohne ausreichende Truppen
- Bewegung ohne ausreichende Truppen
- ungültige Verstärkungsplatzierung
- Disconnect während Verstärkung
- Disconnect während Angriff
- Disconnect während Würfeln
- Disconnect während Bewegung
- Host beendet Spiel
- Host verliert Internet
- Client beendet Spiel
- Client verliert Internet
- Lobby voll
- ungültiger Invite-Code
- abgelaufener Invite-Code
- Match bereits gestartet
- inkompatible Spielversion
- ungültiges Reconnect-Token
- eliminierter Spieler sendet Aktion
- gleichzeitig eintreffende Aktionen
- manipulierte Client-Nachricht
- ungültiger Territory-Identifier
- negativer/überhöhter Truppenwert
- Gewinner wird während laufender Aktion festgestellt

# 28. Security / Host-Validierung

Der Host validiert mindestens:

- Session
- Spieler-ID
- aktueller Spieler
- aktuelle Phase
- Territoriumsbesitz
- Nachbarschaft
- Truppenanzahl
- Verstärkungsbudget
- erlaubte Würfelanzahl
- Bewegung
- Eliminierungsstatus
- Matchstatus
- Aktionsreihenfolge

Clients dürfen niemals selbst autoritativ festlegen:

- Würfelergebnis
- Truppenverlust
- Territoriumsbesitzer
- Truppenanzahl
- Verstärkungsanzahl
- Gewinner
- Zugwechsel

# 29. Godot-Architektur

Vorgesehene Verantwortungsbereiche:

- `GameManager`
- `GameState`
- `TurnManager`
- `CombatManager`
- `ReinforcementManager`
- `MapManager`
- `LobbyManager`
- `NetworkManager`
- `UIManager`
- `AudioManager`
- `SettingsManager`
- `SaveManager`

Konkrete Nodes, Autoloads, Resources und Signalstruktur werden erst nach Abschluss der Regelspezifikation festgelegt.

# 30. Vorgesehene Projektstruktur

```text
res://
  assets/
    audio/
    fonts/
    icons/
    map/
    ui/
  data/
  scenes/
    game/
    lobby/
    menu/
    ui/
  scripts/
    game/
    network/
    ui/
  resources/
  tests/
```

Status: `OFFEN` bis zur technischen Architekturentscheidung.

# 31. Naming Conventions

Zu definieren:

- GDScript-Dateien
- Szenen
- Nodes
- Klassen
- Signale
- RPCs
- Konstanten
- Enums
- Resources
- Asset-Dateien
- Territory-IDs
- Network Message IDs

Status: `OFFEN`.

# 32. Release / Build

- Windows Export: `V1`
- Debug Build: `V1`
- Release Build: `V1`
- Versionsnummer: `V1`
- Logging: `V1`
- Crash-/Fehlerlogs: `OFFEN`
- ZIP/Installer: `OFFEN`
- Auto-Updater: `SPÄTER`
- Entwicklungsserver: `OFFEN`
- Produktionsserver: `OFFEN`

# 33. Rechtliche / gestalterische Abgrenzung

- `FIX` Keine Übernahme des Hasbro/Risiko-Logos.
- `FIX` Keine Übernahme kommerzieller Brett-/Kartengrafiken.
- `FIX` Keine Übernahme geschützter Illustrationen.
- `FIX` Keine wörtliche Übernahme von Regel- oder Kartentexten.
- `FIX` Eigene UI und eigenes visuelles Design.
- `FIX` Eigene Kartenassets bzw. Assets mit geeigneter Lizenz.
- `FIX` Drittanbieter-Assets und Fonts müssen lizenzrechtlich geprüft und dokumentiert werden.
- Projektname `RisikoLike` ist aktuell ein Arbeitstitel; finaler öffentlicher Name: `OFFEN`.

# 34. Offene Entscheidungen — Entscheidungsregister

Diese Punkte müssen vor der jeweiligen Implementierungsphase geschlossen werden:

1. Spielerzahl
2. Sprache(n)
3. Ziel-Spieldauer
4. Siegbedingung V1
5. konkrete Karte
6. Territorien und Nachbarschaften
7. Regionen und Boni
8. Startgebietsverteilung
9. Starttruppen
10. Startspieler/Zugreihenfolge
11. Verstärkungsformel
12. Angriffsbedingungen
13. Würfelregeln
14. Eroberungsbewegung
15. Fortification-/Bewegungsregeln
16. Gebietskarten in V1 ja/nein
17. AFK-/Turn-Timer
18. Verhalten bei Aufgabe
19. Reconnect-Frist
20. Host-Disconnect/Host-Migration
21. Invite-Code-Format
22. Netzwerktransport
23. NAT-/Relay-Lösung
24. Rendezvous-Service
25. Lobby-Ready-Regeln
26. Late Join
27. V1-Einstellungen
28. Online-Savegame
29. konkrete Godot-Architektur
30. Naming Conventions

# 35. Definition of Done — V1

V1 gilt erst als abgeschlossen, wenn:

- zwei oder mehr unterstützte Spieler eine private Lobby erstellen und ihr beitreten können;
- ein Invite-Code zuverlässig zur richtigen Lobby führt;
- alle Spieler denselben autoritativen Match-State sehen;
- eine Partie vom Start bis zum Sieg ohne manuelle Eingriffe durchgespielt werden kann;
- Verstärkung, Angriff, Würfelkampf, Eroberung, Bewegung und Zugwechsel vollständig funktionieren;
- ungültige Client-Aktionen vom Host abgelehnt werden;
- definierte Disconnect-/Reconnect-Fälle funktionieren;
- Sieg und Ausscheiden korrekt erkannt werden;
- die Anwendung als Windows-Build gestartet werden kann;
- alle für V1 als `FIX` markierten Regeln implementiert und getestet sind;
- keine für V1 notwendige Designentscheidung mehr `OFFEN` ist.

---

# Änderungsregel für dieses GDD

1. Eine `FIX`-Entscheidung wird nicht stillschweigend im Code geändert.
2. Regeländerungen werden zuerst hier dokumentiert.
3. Implementierung und Tests folgen anschließend der GDD-Festlegung.
4. Neue offene Fragen werden in Abschnitt 34 aufgenommen.
5. Sobald eine offene Frage entschieden ist, wird ihre konkrete Regel im passenden Abschnitt eingetragen und auf `FIX` gesetzt.
