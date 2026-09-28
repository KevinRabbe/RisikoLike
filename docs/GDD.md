# RisikoLike — Game Design Document

> **Status:** Pre-Production / Spezifikation  
> **Dokumentversion:** 0.2  
> **Ziel:** Verbindliche Source of Truth für Regeln, Lobby, Multiplayer, UI und technische Grundentscheidungen vor Beginn der Implementierung.

## Status-Legende

- `FIX` — beschlossen und nicht während einer Partie veränderbar
- `CONFIG` — Host kann die Regel vor Matchstart konfigurieren; Default ist festgelegt
- `OFFEN` — muss noch entschieden werden
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
| GDD-PROJ-006 | Spieleranzahl | FIX / V1 | 2–5 Spieler |
| GDD-PROJ-007 | Sprache V1 | OFFEN | Deutsch / Englisch / beide |
| GDD-PROJ-008 | Ziel-Spieldauer | OFFEN | |
| GDD-PROJ-009 | Eigene Spielidentität | FIX | Eigener Name, eigene Grafik, eigene UI und eigene Kartenpräsentation |

# 2. Designprinzipien

- `FIX` Ein Spieler hostet die Partie; der Host ist autoritativ für den Game State.
- `FIX` V1 private Lobbys sind player-hosted/direct und benötigen keinen zentralen Server.
- `FIX` Andere Spieler treten über einen Invite-Code bei.
- `FIX` Der V1-Invite ist self-contained (`AF1`) und enthält Endpoint, Port und Join-Berechtigung.
- `FIX` Clients senden Aktionen/Intents; sie bestimmen keine autoritativen Ergebnisse.
- `FIX` Regeln und Game State sind von Darstellung/UI getrennt.
- `FIX` Keine kommerziellen Originalgrafiken, Logos oder wörtlich kopierten Regel-/Kartentexte.
- `FIX` Sinnvolle Regelvarianten werden als Lobby-`CONFIG` statt als Hardcode umgesetzt.
- `FIX` Das Ruleset wird bei Matchstart gesperrt und danach nicht mehr verändert.
- `V1` Fokus auf einen stabilen Kernmodus.

Der bestehende FastAPI-/WebRTC-Pfad bleibt als optionaler zukünftiger Service-
Prototyp erhalten. Matchmaking, Accounts, Ranked, Relay und globale Lobby-
Dienste sind weiterhin keine V1-Voraussetzungen.

# 3. Scope V1

Hauptmenü, Spielername, private Lobby, Invite-Code, Ready-System, Host-Ruleset, 2–5 Spieler, 42 Territorien / 6 Regionen, Verstärkungen, Gebietskarten, Angriffe, Würfelkampf, Gebietseroberung, Truppenbewegung, Zugwechsel, Ausscheiden/Zuschauen, Welteroberung, Zugtimer, Disconnect/Reconnect, Aufgeben und Windows-Build.

# 4. Nicht-Ziele V1

`SPÄTER`: KI, Singleplayer, öffentliche Lobbys/Matchmaking, Accounts, Freundesliste, Ranglisten, Achievements, Replays, Map-Editor, Steam-Integration, Dedicated Game Server, alternative Karten, Missionen, Host-Migration, Unlimited Fortification.

# 5. Spieler und Partie

| Regel | Status | Festlegung |
|---|---|---|
| Mindestspieler | FIX | 2 |
| Maximalspieler | FIX | 5 |
| Startspieler | CONFIG | Default: wenigste Gesamttruppen; Gleichstand zufällig zwischen den gleich niedrigsten Spielern. Alternative: komplett zufällig. |
| Zugreihenfolge | FIX | Nach Festlegung bleibt sie bestehen; ausgeschiedene Spieler werden übersprungen. |
| Sieg | FIX / V1 | Welteroberung: ein Spieler kontrolliert alle Territorien. |
| Ausscheiden | FIX | Kein kontrolliertes Territorium mehr. |
| Aufgeben | CONFIG | Default erlaubt. |
| Zuschauer | CONFIG | Default erlaubt; eliminierte/aufgegebene Spieler dürfen zuschauen oder verlassen. |
| Spielerfarben | OFFEN | |

# 6. Karte und Spielaufbau

- `FIX` 42 Territorien, 6 Regionen/Kontinente.
- `FIX` Reale geografische Anzeigenamen; eigene Kartengrafik und Grenzdarstellung.
- `FIX` Stabile interne IDs getrennt von Anzeigenamen (`NA_01`, `EU_01` usw.).
- `CONFIG` Startgebiete: **Zufällig (Default)** / **Manuell**.
- `FIX` Jedes Startterritorium beginnt mit mindestens 1 Truppe.
- `FIX` Keine neutrale Partei und keine KI im 2-Spieler-Modus; alle 42 Gebiete werden aufgeteilt.
- `FIX` Starttruppen: 2 Spieler = 40, 3 = 35, 4 = 30, 5 = 25 pro Spieler.
- `CONFIG` Starttruppen: Standardwerte / benutzerdefiniert.
- `FIX` Manuell: Spieler wählen reihum freie Territorien.
- `FIX` Danach werden verbleibende Starttruppen auf eigene Territorien verteilt.

## 6.1 Regionen und Boni

| Region | Territorien | Default-Bonus |
|---|---:|---:|
| Nordamerika | 9 | +5 |
| Südamerika | 4 | +2 |
| Europa | 7 | +5 |
| Afrika | 6 | +3 |
| Asien | 12 | +7 |
| Australien/Ozeanien | 4 | +2 |
| **Gesamt** | **42** | |

`CONFIG`: Kontinentboni standardmäßig **AN**, Host kann sie deaktivieren.

# 7. Territory-Datenmodell

Je Territorium: stabile ID, Anzeigename, Region-ID, Nachbar-IDs, Besitzer-ID, Truppenanzahl, Kartensymboltyp, Kartenposition, Army-Marker-Position, klickbare Fläche/Polygon, Hover- und Selected-Darstellung.

- `FIX` Nachbarschaften werden explizit in Daten definiert und nicht aus der Grafik abgeleitet.
- `OFFEN` konkrete 42 Namen, Nachbarschaften, Wasser-/Randverbindungen, Koordinaten und Symbolzuordnung.

# 8. Zugablauf

1. Verstärken
2. Angreifen
3. Truppen bewegen
4. Zug beenden
5. Nächster aktiver Spieler

- `FIX` Verstärkungen müssen vollständig verteilt werden, bevor angegriffen wird.
- `FIX` Angriff und Bewegung dürfen übersprungen werden.
- `CONFIG` Zugtimer Default **3 Min.**; Optionen **Aus / 2 / 3 / 5 Min.**
- `FIX` Timer gilt für den kompletten Zug; Warnung bei 30 Sekunden.
- `FIX` Bei Ablauf bleiben bestätigte Aktionen; unbestätigte Aktion wird verworfen und Zug endet.

# 9. Verstärkungen

- `FIX` Basis: `floor(eigene Territorien / 3)`, Minimum 3.
- `FIX` Regionsbonus nur bei vollständiger Kontrolle zu Beginn des Zuges; zusätzlich zur Basis.
- `FIX` Nur auf eigene Territorien.
- `FIX` Alle Verstärkungen müssen verteilt werden.
- `FIX` Vor Bestätigung darf geändert/rückgängig gemacht werden; Bestätigung ist verbindlich.
- `CONFIG` Kontinentboni Default AN.

# 10. Angriff und Würfel

- `FIX` Angriff nur vom eigenen auf ein direkt benachbartes feindliches Territorium.
- `FIX` Mindestens 1 Truppe bleibt im Ausgangsgebiet.
- `FIX` Angreifer: 1–3 Würfel; Verteidiger: 1–2 Würfel; jeweils durch verfügbare Truppen begrenzt.
- `FIX` Zulässige Würfelanzahl wird vom jeweiligen Spieler gewählt.
- `FIX` Ergebnisse je Seite absteigend; höchster gegen höchsten, ggf. zweithöchster gegen zweithöchsten.
- `FIX` Gleichstand gewinnt Verteidiger.
- `FIX` Verlierer jedes Vergleichs verliert 1 Truppe; maximal 2 Verluste pro Wurf.
- `FIX` Beliebig viele Angriffe; Angriffsphase freiwillig beendbar.
- `FIX / V1` RNG ausschließlich beim Host; Ergebnis wird repliziert.
- `SPÄTER` Schnellkampf/Auto-Roll als reine Komfortfunktion.

# 11. Gebietseroberung

- `FIX` Bei 0 verteidigenden Truppen wird das Gebiet sofort erobert.
- `FIX` Besitzer wechselt zum Angreifer.
- `FIX` Angreifer muss Truppen einziehen lassen.
- `FIX` Minimum = Anzahl der beim letzten Angriff verwendeten Angriffswürfel.
- `FIX` Maximum = alle verfügbaren Truppen außer 1 im Ausgangsgebiet.
- `FIX` Danach darf aus dem neuen Gebiet weiter angegriffen werden.
- `FIX` Nach relevanter Eroberung werden Eliminierung und Sieg geprüft.

# 12. Truppenbewegung / Fortification

- `FIX` Standardmäßig eine bestätigte Bewegung pro Zug.
- `FIX` Ausgang und Ziel gehören dem Spieler; mindestens 1 Truppe bleibt zurück.
- `CONFIG` **Connected (Default)** / **Adjacent**.
- `FIX` Connected: zusammenhängender eigener Pfad genügt.
- `FIX` Adjacent: direkt benachbart.
- `FIX` Beliebig viele übrige Truppen in der einen Bewegung; vor Bestätigung änderbar/abbrechbar.
- `FIX` Phase darf übersprungen werden.
- `SPÄTER / CONFIG` Unlimited Fortification ON/OFF; ermöglicht mehrere Bewegungen pro Phase.

# 13. Gebietskarten

- `CONFIG / V1` Gebietskarten Default AN; Host kann AUS wählen.
- `FIX` 42 Gebietskarten: eine pro Territorium; 14 Infanterie, 14 Kavallerie, 14 Artillerie.
- `FIX` Zusätzlich 2 Joker ohne Territorium; 44 Karten gesamt.
- `FIX` Host mischt/verwaltert Deck, Hände und Ablage autoritativ.
- `FIX` Mindestens ein erobertes Territorium im Zug = genau 1 Karte am Zugende.
- `FIX` Gültiges Set: 3 gleiche Symbole oder je 1 Symbol jeder Art; Joker ersetzt beliebigen Typ.
- `FIX` Gegner sehen nur Kartenanzahl.
- `FIX` Leerer Nachziehstapel: Ablage neu mischen.

## 13.1 Kartentausch

- `CONFIG` Kartenbonus: **Progressiv (Default)** / Fest.
- `FIX` Global progressiv: `4 → 6 → 8 → 10 → 12 → 15 → 20 → 25 → 30 → ...`, danach +5.
- `FIX` Normaler Tausch zu Beginn der Verstärkungsphase.
- `CONFIG` Pflichttausch ab 5 Karten: Default Pflicht / Alternative optional.
- `FIX` Unter Pflichtlimit freiwillig; mehrere gültige Sets pro Zug erlaubt.
- `CONFIG` Gebietsbonus Default +2 / Aus.
- `FIX` Eigene eingetauschte Gebietskarte gibt bei aktivem Bonus +2 auf dieses Gebiet; Joker keinen Gebietsbonus.
- `FIX` Karten eliminierter Spieler gehen an den eliminierenden Spieler.
- `FIX` Erreicht dieser dadurch das Pflichtlimit, muss er während der Angriffsphase sofort tauschen, bis er darunter liegt; Truppen werden sofort platziert, danach kann Angriff weitergehen.
- `SPÄTER` Missionskarten.

# 14. Lobby-Ruleset

| Einstellung | Default | Optionen |
|---|---|---|
| Startgebiete | Zufällig | Zufällig / Manuell |
| Starttruppen | Standard | Standard / Benutzerdefiniert |
| Startspieler | Wenigste Truppen | Wenigste Truppen / Zufällig |
| Zugtimer | 3 Min. | Aus / 2 / 3 / 5 Min. |
| Reconnect-Zeit | 3 Min. | 1 / 3 / 5 / 10 Min. |
| Gebietskarten | An | An / Aus |
| Kartenbonus | Progressiv | Progressiv / Fest |
| Tauschpflicht ab 5 | Pflicht | Pflicht / Optional |
| Gebietsbonus Kartentausch | +2 | +2 / Aus |
| Kontinentboni | An | An / Aus |
| Fortification | Connected | Connected / Adjacent |
| Aufgeben | Erlaubt | Erlaubt / Verboten |
| Zuschauer | Erlaubt | Erlaubt / Verboten |
| Siegbedingung | Welteroberung | V1 nur Welteroberung |

- `FIX` Button **Standardregeln wiederherstellen**.
- `FIX` Ruleset wird bei Matchstart immutable und an alle Clients synchronisiert.
- `SPÄTER` Unlimited Fortification als Host-Regel.
- `OFFEN` Grenzen für benutzerdefinierte Starttruppen und Wert des festen Kartenbonus.

# 15. Lobby / Invite-Code

Benötigt: Lobby erstellen/verlassen, Invite-Code anzeigen/kopieren/eingeben, beitreten, Spieler-Slots/Namen/Farben, Host-Markierung, Ready, Kick, Ruleset, Standardregeln, Start, Fehler-/Verbindungsstatus.

- `V1` Lobby-Code wird über Vermittlungs-/Rendezvous-Dienst registriert, löst Host-Session auf und wird nach Lobby-Ende ungültig.
- `OFFEN` Farbwahl, Ready-Voraussetzungen, Late Join, Code-Länge/Zeichensatz/Lebensdauer/Kollisionen und Backend-Technik.

# 16. Netzwerkmodell

- `FIX / V1` Host-authoritative Architektur.
- `FIX / V1` Clients senden Requests/Intents; Host validiert, verändert State und repliziert Ergebnisse.
- `FIX` Host validiert Session, Spieler, Zug, Phase, Besitz, Nachbarschaft, Truppen, Verstärkungen, Würfelanzahl, Bewegung und Matchstatus.
- `OFFEN` Transport/Protokoll, NAT/Relay, Rendezvous-Service, Verschlüsselung, Heartbeat/Ping.

# 17. Disconnect / Reconnect / AFK

- `FIX / V1` Reconnect unterstützt.
- `CONFIG` Reconnect-Frist Default 3 Min.; 1 / 3 / 5 / 10 Min.
- `FIX` Client-Disconnect: Zugtimer läuft weiter; rechtzeitiger Reconnect stellt bestehenden State wieder her.
- `FIX` Frist abgelaufen: Spieler dauerhaft verlassen; Territorien/Truppen bleiben bestehen, aber keine aktiven Züge; normal eroberbar.
- `FIX` Aufgeben mit Bestätigungsdialog; bestätigte laufende Kampfaktion wird zuerst aufgelöst.
- `FIX` Aufgegebene/eliminierte Spieler dürfen bei aktivem Zuschauer-Modus bleiben.
- `FIX` Host verlässt Lobby vor Start: Lobby geschlossen.
- `FIX / V1` Host-Disconnect im Match: Partie pausiert während Reconnect-Frist; kommt Host nicht zurück, Partie beendet.
- `SPÄTER` Host-Migration.
- `FIX` Kein separates AFK-System V1; Zugtimer behandelt Inaktivität.
- `V1` Session-/Reconnect-Token.

# 18. Autoritativer Game State

Mindestens: Match-ID/-status, Regel-/Protokollversion, eingefrorenes Ruleset, Spieler-ID/Name/Farbe/Status, Zugreihenfolge/Spieler/Runde/Phase/Timer, Territorien/Besitzer/Truppen, Verstärkungen, laufender Kampf, Würfelergebnisse, Karten-Deck/Hände/Ablage, globale Kartenbonus-Stufe, Eroberungsflag, letzte bestätigte Aktion, Gewinner, RNG-Daten soweit erforderlich.

# 19. UI-Screens und UI-Elemente

Screens: Boot/Splash, Hauptmenü, Spielername, Lobby erstellen/beitreten, Lobby + Ruleset, Laden, Spiel, Pause, Einstellungen, Disconnect/Reconnect, Zuschauer, Sieg/Ergebnis, Fehler.

Elemente: Logo, Menübuttons, Spielername, Invite-Code, Lobby-Slots, Host/Ready/Kick/Verbindung, Ruleset, Weltkarte, Territory Hover/Selected, Besitzerfarbe, Truppenanzahl, Spielerübersicht, Phase/Timer/Verstärkungen, Angriff/Würfel/Kampfergebnis, Kartenhand/Kartenanzahl/Tausch, Eroberungs-/Bewegungsdialog, Bestätigen/Abbrechen/Zugende, Pause/Aufgeben/Verlassen, Reconnect/Zuschauer/Sieg/Fehler/Tooltips.

# 20. Assets

Eigenes Logo/App-Icon, Menü-Hintergrund, eigene Weltkarte, Territory-Masks/Grenzen, Regionsgrenzen, Wasser/Verbindungslinien, Truppen-/Spielermarker, Host/Ready/Verbindung/Warnung, Würfel 1–6, Angriff/Verteidigung/Verstärkung/Bewegung, Gebietskartenrahmen und drei Symbole, Joker, Settings/Audio/Kopieren/Zurück/Schließen, Sieg-Grafik, Cursor, UI-Panels/Buttons/Inputs/Checkboxen/Slider, lizenzierte Fonts.

# 21. Audio

Menü-/Spielmusik, Button Hover/Click, Lobby Join/Leave, Spielstart, Zugstart, Gebiet auswählen, Truppen platzieren, Angriff, Würfel, Verlust, Eroberung, Karten ziehen/tauschen, Fehler, Benachrichtigung, Sieg, Ausscheiden. Konkrete Assets `OFFEN`.

# 22. Einstellungen / Speicherung

Vorgesehen: Master-/Musik-/Effekt-Lautstärke, Vollbild/Fenster, Auflösung, VSync, UI-Skalierung, Sprache, Spielername. V1-Umfang `OFFEN`.

- `V1` lokale Einstellungen, Spielername und Reconnect-Daten.
- `OFFEN` Online-Savegame / Autosave.

# 23. Fehler- und Randfälle

Mindestens testen: doppelte/verspätete/falsch sortierte Aktionen, falscher Spieler/Phase, ungültige Angriffe/Verstärkungen/Bewegungen, Disconnect in jeder Phase, Host-Disconnect, ungültiger/abgelaufener Invite-Code, Lobby voll/Match gestartet, inkompatible Version, ungültiges Reconnect-Token, Aktionen eliminierter Spieler, manipulierte Client-Daten, ungültige Territory-ID, negative/überhöhte Truppenwerte, Kartenpflichttausch nach Eliminierung, Sieg während Aktionsauflösung.

# 24. Security / Validierung

Clients dürfen niemals autoritativ festlegen: Würfelergebnis, Truppenverlust, Besitzer, Truppenanzahl, Verstärkungen, Karteninhalt/-ziehung, Kartenbonus-Stufe, Gewinner, Zugwechsel oder Ruleset nach Matchstart.

# 25. Vorgesehene Godot-Verantwortungsbereiche

`GameManager`, `GameState`, `GameRules`, `TurnManager`, `CombatManager`, `ReinforcementManager`, `CardManager`, `MapManager`, `LobbyManager`, `NetworkManager`, `UIManager`, `AudioManager`, `SettingsManager`, `SaveManager`.

Konkrete Nodes, Autoloads, Resources, RPCs und Signale bleiben `OFFEN` bis die Spezifikation abgeschlossen ist.

# 26. Vorgesehene Projektstruktur

```text
res://
  assets/
    audio/
    fonts/
    icons/
    map/
    cards/
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

# 27. Naming Conventions

`OFFEN`: GDScript-Dateien, Szenen, Nodes, Klassen, Signale, RPCs, Konstanten, Enums, Resources, Assets, Territory-IDs, Network Message IDs.

# 28. Release / Build

- `V1` Windows Export, Debug-/Release-Build, Versionsnummer, Logging.
- `OFFEN` Crashlogs, ZIP/Installer, Entwicklungs-/Produktionsserver.
- `SPÄTER` Auto-Updater.

# 29. Rechtliche / gestalterische Abgrenzung

- `FIX` Kein Hasbro/Risiko-Logo oder kommerzielle Brett-/Kartengrafiken/Illustrationen.
- `FIX` Keine wörtliche Übernahme von Regel-/Kartentexten.
- `FIX` Eigene UI und eigene bzw. passend lizenzierte Kartenassets.
- `FIX` Drittanbieter-Assets/Fonts werden lizenzrechtlich dokumentiert.
- `OFFEN` Finaler öffentlicher Spielname; RisikoLike bleibt Arbeitstitel.

# 30. Offene Entscheidungen

1. Sprache(n) V1
2. Ziel-Spieldauer
3. Spielerfarben/Farbauswahl
4. konkrete 42 Territorien und Namen
5. Nachbarschaften/Wasserverbindungen
6. Territory-/Marker-Koordinaten
7. Zuordnung 14/14/14 Kartensymbole
8. benutzerdefinierte Starttruppen-Grenzen
9. fester Kartenbonus
10. Lobby Ready-Regeln
11. Late Join
12. Invite-Code-Format
13. Netzwerktransport
14. NAT-/Relay-Lösung
15. Rendezvous-/Lobby-Service
16. Verschlüsselung/Heartbeat
17. V1-Einstellungen
18. Online-Savegame
19. konkrete Godot-Architektur
20. Naming Conventions
21. Installer/Distribution

# 31. Definition of Done — V1

V1 ist abgeschlossen, wenn 2–5 Spieler eine private Lobby per Invite-Code nutzen können; Host-Regeln vor Start konfiguriert und eingefroren werden; alle Clients denselben autoritativen State sehen; eine Partie vollständig bis zur Welteroberung spielbar ist; Startverteilung, Verstärkung, Gebietskarten, Angriff, Würfelkampf, Eroberung, Bewegung und Zugwechsel funktionieren; ungültige Client-Aktionen abgelehnt werden; Timer/Disconnect/Reconnect/Aufgabe funktionieren; Eliminierung/Zuschauer/Sieg korrekt sind; ein Windows-Build startbar ist; alle V1-Regeln getestet sind und keine notwendige V1-Entscheidung mehr `OFFEN` ist.

---

# Änderungsregel

1. `FIX` wird nicht stillschweigend im Code geändert.
2. `CONFIG` benötigt einen dokumentierten Default.
3. Regeländerungen zuerst ins GDD, danach Implementierung/Tests.
4. Neue offene Fragen in Abschnitt 30 aufnehmen.
5. Nach Matchstart ist das konkrete Ruleset unveränderlich.
