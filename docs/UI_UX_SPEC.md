# RisikoLike — UI / UX Specification

> **Status:** Pre-Production / UI Architecture  
> **Dokumentversion:** 0.1  
> **Bezug:** `GDD.md`, `MAP_SPEC.md`, `NETWORK_SPEC.md`, `GODOT_ARCHITECTURE.md`

## 1. Grundprinzipien

- Desktop-first für Windows.
- Karte ist während des Matches das dominante Element.
- Aktuelle Phase, aktiver Spieler und verbleibende Zeit müssen jederzeit erkennbar sein.
- Kritische Aktionen benötigen eindeutige Bestätigung.
- Keine Regel darf ausschließlich über Farbe kommuniziert werden.
- Host-spezifische Controls werden klar von normalen Spieleraktionen getrennt.
- Nicht verfügbare Aktionen werden deaktiviert oder ausgeblendet.
- Netzwerk-/Reconnect-Zustände dürfen nicht wie normale Gameplay-Fehler aussehen.
- UI zeigt nur Informationen, die der lokale Spieler laut Regeln sehen darf.

## 2. Screen Flow

```text
Boot
  -> Main Menu
      -> Create Lobby
          -> Lobby
              -> Game
                  -> Victory / Defeat / Spectator
                      -> Main Menu
      -> Join Lobby
          -> Lobby
      -> Settings
      -> Exit
```

Reconnect-Sonderpfad:

```text
Boot/Main Menu
  -> Reconnect Prompt
      -> Connecting
          -> Game Snapshot Restore
```

## 3. Boot

Elemente:

- Logo/Spielname
- Ladeindikator
- Versionsnummer
- Statuszeile
- Fehlerdialog

Zustände:

- Initialisierung
- lokale Einstellungen laden
- Netzwerkkomponenten initialisieren
- vorhandene Reconnect-Session prüfen
- Main Menu öffnen

## 4. Main Menu

Elemente:

- Spielname/Logo
- `Lobby erstellen`
- `Lobby beitreten`
- `Einstellungen`
- `Beenden`
- Versionsnummer
- optional Direct-/Connectivitystatus

## 5. Create Lobby

Elemente:

- Spielername
- maximale Spieler `2–5`
- Ruleset Preset
- Ruleset-Konfiguration
- `Standardregeln wiederherstellen`
- `Lobby erstellen`
- `Zurück`
- Loading State
- Fehlerbereich/Dialog

Ruleset Controls mindestens:

- Startgebiete
- Starttruppen
- Startspieler
- Zugtimer
- Reconnect-Zeit
- Gebietskarten
- Kartenbonus-Modus
- Tauschpflicht
- Gebietsbonus beim Kartentausch
- Kontinentboni
- Fortification Mode
- Aufgeben
- Zuschauer
- Siegbedingung

`Unlimited Fortification` wird erst sichtbar, wenn die Funktion implementiert ist.

## 6. Join Lobby

Elemente:

- Spielername
- Invite-Code Input
- Codeformat `AF1.<payload>.<checksum>`
- `Beitreten`
- `Zurück`
- Loading State
- Fehlertext/Dialog

UX:

- Eingabe case-insensitive
- Bindestrich darf automatisch ergänzt werden
- Leerzeichen trimmen
- Paste unterstützen
- ungültige Zeichen früh markieren

Fehlerzustände:

- Code ungültig
- Lobby nicht gefunden
- Lobby abgelaufen
- Lobby voll
- Match bereits gestartet
- Versionskonflikt
- Netzwerkfehler

## 7. Lobby Screen

Hauptbereiche:

```text
Header
Player List
Rules Summary / Rules Editor
Invite Panel
Lobby Actions
Status / Errors
```

### Header

- Lobby-Name optional
- Host-Indikator
- Spieleranzahl `x / max`
- Verbindungsstatus

### Invite Panel

- Invite-Code groß darstellen
- `Code kopieren`
- optional kurzer Hinweis „Freunde geben diesen Code unter Lobby beitreten ein“

### Player List

Pro Spieler:

- Name
- Farbe
- Host-Badge
- Ready-Status
- Connection State
- Slot

### Spieleraktionen

- `Bereit`
- `Nicht bereit`
- `Lobby verlassen`

### Host-Aktionen

- Ruleset ändern
- Spieler entfernen — optional/später
- `Spiel starten`
- `Lobby schließen`

Start-Button nur aktiv, wenn alle Startbedingungen erfüllt sind.

## 8. Lobby Rules Summary

Für Nicht-Hosts read-only.

Darstellung gruppiert:

```text
Start
Timer
Karten
Kontinente
Bewegung
Aufgabe/Zuschauer
Siegbedingung
```

Geänderte Werte gegenüber Default können visuell markiert werden.

## 9. Game HUD Layout

Desktop-Konzept:

```text
+---------------------------------------------------------+
| Top Bar: Turn / Phase / Timer / Cards / Menu            |
+---------------------------------------------+-----------+
|                                             | Players   |
|                                             | / Info    |
|                  MAP                        |           |
|                                             |           |
|                                             |           |
+---------------------------------------------+-----------+
| Bottom Action Bar / Phase Controls                      |
+---------------------------------------------------------+
```

Die Karte erhält den größten verfügbaren Bereich.

## 10. Top Bar

Elemente:

- aktueller Spieler
- aktuelle Phase
- Zugnummer
- Timer
- eigene Kartenanzahl
- Verstärkungen verbleibend, falls relevant
- Settings/Pause-Menü

Timer-Zustände:

- normal
- Warnung bei 30 Sekunden
- abgelaufen
- deaktiviert

Warnung nicht ausschließlich über Farbe darstellen.

## 11. Player Panel

Pro Spieler:

- Name
- Farbe
- Territorienanzahl
- Kartenanzahl
- aktiver Spieler Marker
- Connection State
- eliminiert
- aufgegeben

Nicht anzeigen:

- konkrete gegnerische Karten
- versteckte Informationen

## 12. Map Interaction

Territory States visuell mindestens:

- normal
- hover
- selected
- valid target
- invalid target
- attack source
- attack target
- fortification source
- fortification target
- recently conquered optional

Pro Gebiet sichtbar:

- Besitzerfarbe
- Truppenanzahl
- optional Name bei Hover/Zoom

Tooltip:

- Gebietsname
- Region
- Besitzer
- Truppen

## 13. Kamera

V1:

- Pan
- Zoom
- Reset View
- Map Bounds

Input:

- Mausrad Zoom
- Drag/Mittlere Maustaste Pan oder definierte Alternative
- UI darf Karteninput blockieren, wenn Modal aktiv ist

## 14. Reinforcement UI

Elemente:

- verbleibende Verstärkungen
- ausgewähltes Gebiet
- aktuelle Platzierungsmenge
- `+1`
- `-1`
- optional Schnellwerte
- `Zurücksetzen`
- `Bestätigen`

Vor Bestätigung dürfen lokale Platzierungen geändert werden.

Bestätigung sendet autoritativen Command.

## 15. Card Trade UI

Elemente:

- eigene Handkarten
- Kartentyp
- Gebietsname
- Gebietsbesitz-Indikator
- Joker
- Auswahlzustand
- Set-Gültigkeit
- erwarteter Truppenbonus
- Gebietsbonus
- `Set eintauschen`
- `Überspringen`, falls erlaubt

Bei Pflichttausch ist Überspringen deaktiviert.

## 16. Attack UI

Ablauf:

```text
Eigenes Gebiet wählen
-> feindliches Nachbargebiet wählen
-> Combat Panel
```

Map Highlights zeigen gültige Angriffsziele.

Combat Panel:

- Angreifergebiet
- Verteidigergebiet
- Angreifertruppen
- Verteidigertruppen
- Angriffswürfel `1–3`
- Verteidigungswürfel Ergebnis/Host-Auswahl gemäß Regeln
- `Angreifen`
- `Abbrechen`
- Würfelergebnis
- Verluste

Keine Würfelergebnisse vor Host-Antwort darstellen.

## 17. Conquest Move Dialog

Nach Eroberung:

- Ausgangsgebiet
- Zielgebiet
- Minimum
- Maximum
- Slider/Stepper
- resultierende Truppenanzahlen
- `Bestätigen`

Dialog ist modal, bis eine gültige Anzahl bestätigt wurde.

## 18. Fortification UI

Elemente:

- Ausgangsgebiet
- Zielgebiet
- gültige Ziele hervorheben
- Truppenanzahl
- Minimum/Maximum
- `Bewegen`
- `Phase überspringen`

Bei `Connected` dürfen erreichbare eigene Gebiete hervorgehoben werden.

Bei `Adjacent` nur direkte eigene Nachbarn.

## 19. Bottom Action Bar

Inhalt abhängig von Phase.

Beispiele:

### Reinforcement

- verbleibende Truppen
- Reset
- Bestätigen

### Attack

- Angriff starten
- Angriffsphase beenden

### Fortification

- Bewegen
- Phase überspringen

Controls anderer Phasen werden nicht gleichzeitig angeboten.

## 20. Turn Transition

Kurze nicht-blockierende Anzeige:

```text
Spielername ist am Zug
```

Eigener Zug darf deutlicher signalisiert werden.

Keine lange Animation, die Spielzeit unnötig verbraucht.

## 21. Dice Presentation

V1 benötigt:

- Angriffswürfel
- Verteidigungswürfel
- sortierte Ergebnisse
- Paarvergleich
- Verlustanzeige

Animation darf Ergebnis erst nach Host-Result abspielen.

Option in Settings:

- Würfelanimationen reduziert/normal — optional

## 22. Territory Cards

Karten benötigen visuell:

- Territoriumsname
- Symbol: Infanterie/Kavallerie/Artillerie
- Joker-Darstellung
- Besitzindikator für eigenes Territorium
- selected state

Eigene Karten dürfen vollständig betrachtet werden.

Gegner: nur Kartenanzahl.

## 23. Disconnect UI

### anderer Spieler disconnected

Player Panel zeigt:

- `Verbindung verloren`
- Reconnect-Countdown, sofern für Spieler sichtbar vorgesehen

### lokaler Client disconnected

Modal/Overlay:

- `Verbindung unterbrochen`
- Reconnect läuft
- verbleibende Zeit
- `Match verlassen`

Während Reconnect keine Game Commands erlauben.

## 24. Host Disconnect

Alle Clients erhalten blockierendes Overlay:

```text
Host-Verbindung verloren
Warte auf Wiederverbindung...
Countdown
```

Bei erfolgreichem Reconnect:

- Snapshot synchronisieren
- Overlay schließen

Bei Ablauf:

- Match beendet
- Rückkehr zum Main Menu

## 25. Surrender

Pause/Game Menu:

- `Aufgeben`

Bestätigung:

```text
Möchtest du die Partie wirklich aufgeben?
```

Buttons:

- `Abbrechen`
- `Aufgeben`

Nach Aufgabe:

- Spectator Mode, falls erlaubt
- ansonsten Match verlassen

## 26. Eliminated State

Overlay:

- eliminiert
- Eliminator optional anzeigen
- `Zuschauen`
- `Match verlassen`

Wenn Zuschauer deaktiviert:

- nur `Match verlassen`

## 27. Spectator Mode

- Karte vollständig sichtbar wie normaler öffentlicher State
- keine Gameplay-Aktionsbuttons
- Player Panel sichtbar
- Turn/Phase sichtbar
- Karteninhalte aktiver Spieler bleiben verborgen
- Match verlassen möglich

## 28. Victory Screen

Elemente:

- Gewinner
- Match beendet
- optionale Basisstatistiken
- `Zum Hauptmenü`

Später möglich:

- Rematch
- ausführliche Statistik
- Match History

## 29. Pause / Game Menu

Elemente:

- Spiel fortsetzen
- Einstellungen
- Ruleset ansehen
- Aufgeben, falls erlaubt
- Match verlassen

Bei Multiplayer pausiert das Öffnen dieses Menüs nicht automatisch den autoritativen Match-Timer.

## 30. Settings

Kategorien V1:

### Allgemein

- Spielername
- Sprache

### Audio

- Master
- Musik
- SFX

### Grafik

- Fenster/Vollbild
- Auflösung optional
- UI Scale optional

### Gameplay

- Kameraempfindlichkeit optional
- reduzierte Animationen optional

## 31. Fehlerdarstellung

Drei Klassen:

### Inline

Für Eingabevalidierung:

- ungültiger Invite-Code
- ungültiger Spielername

### Toast/Notification

Für nicht-blockierende Ereignisse:

- Code kopiert
- Spieler beigetreten
- Spieler reconnectet

### Modal

Für blockierende Probleme:

- Verbindung verloren
- Lobby geschlossen
- Version mismatch
- Host nicht zurückgekehrt
- schwerer Synchronisationsfehler

## 32. Loading States

Benötigt für:

- Lobby erstellen
- Lobby beitreten
- Direct TCP Listener starten
- Direct TCP verbinden
- Match starten
- Snapshot synchronisieren
- Reconnect

Doppelklick/mehrfaches Absenden während Pending Request verhindern.

## 33. Accessibility

V1 mindestens:

- Text zusätzlich zu kritischen Farbcodes
- ausreichender Kontrast
- UI Scale berücksichtigen
- klare Focus States
- Buttons mit Text/Icons nicht nur Icon, wo Bedeutung unklar wäre
- Spielerfarben zusätzlich durch Namen/Position identifizierbar

`SPÄTER` farbenblindfreundliche Muster/Palette als dedizierte Option.

## 34. Auflösungen

Design-Basis:

```text
1920x1080
16:9
```

V1 muss mindestens sinnvoll skalieren auf:

```text
1280x720
1920x1080
2560x1440
3840x2160
```

Keine Gameplay-Information darf bei 1280x720 abgeschnitten sein.

Ultrawide darf zusätzlichen Kartenraum verwenden, ohne Gameplay-Vorteil durch versteckte Information zu erzeugen.

## 35. UI Assets — benötigt

- Spiel-Logo
- Hauptmenü-Hintergrund
- Panel-Hintergründe
- Buttons normal/hover/pressed/disabled
- Checkbox
- Dropdown
- Slider
- Text Input
- Tabs
- Tooltip
- Scrollbar
- Modal-Hintergrund
- Toast
- Loading Spinner
- Connection Icons
- Ready Icon
- Host Icon
- Spectator Icon
- Warning Icon
- Error Icon
- Copy Icon
- Settings Icon
- Exit Icon
- Cards Icon
- Infantry Icon
- Cavalry Icon
- Artillery Icon
- Joker Icon
- Dice Faces 1–6
- Army Marker
- Territory Selection/Highlight
- Valid/Invalid Target Highlight
- Timer Warning State
- Player Color Indicators

## 36. Map Assets — benötigt

- eigene Weltkartenbasis
- 42 Territory Shapes/Masks
- 6 Regiondarstellungen
- Grenzen
- Wasser-/Verbindungslinien
- Army Marker Positions
- Territory Label Positions
- Kartenrand-Verbindung Alaska/Kamtschatka
- Hover/Selection Masks

## 37. Audio Assets — benötigt

- Main Menu Musik optional
- Match Musik optional
- Button Hover optional
- Button Click
- Error
- Notification
- Turn Start
- Own Turn
- Dice Roll
- Territory Conquered
- Card Received
- Card Trade
- Player Eliminated
- Victory
- Defeat optional

## 38. UI State darf Gameplay nicht bestimmen

Beispiele:

- deaktivierter Button ist Komfort, nicht Sicherheitsgrenze
- Host validiert Aktion trotzdem
- Highlight eines Nachbarn ersetzt keine Adjacency-Prüfung
- angezeigte Verstärkungsmenge ersetzt keine Domain-Validierung

## 39. V1 nicht erforderlich

- Chat
- Freundesliste
- Accounts
- Matchmaking
- Rangliste
- Achievements
- Cosmetics
- Emotes
- Mobile Layout
- Controller Support
- Replay Viewer
- umfangreiche Statistiken
- Rematch Flow

## 40. Definition of Done — UI/UX V1

- kompletter Flow Main Menu -> Lobby -> Match -> Matchende funktioniert
- Invite-Code kann erstellt, kopiert und eingegeben werden
- Lobby zeigt Spieler/Ready/Ruleset eindeutig
- alle Matchphasen besitzen eindeutige Controls
- Karte ist mit Maus vollständig bedienbar
- eigener und fremder Zug sind klar unterscheidbar
- Kartenhand ist regelkonform sichtbar
- Combat Result ist nachvollziehbar
- Reconnect besitzt eigenen UX-Flow
- Host-Disconnect blockiert Match korrekt
- Aufgabe/Eliminierung/Spectator sind abgedeckt
- Fehler- und Loading-Zustände sind definiert
- 1280x720 bis 4K sind ohne abgeschnittene Kerninformationen nutzbar
