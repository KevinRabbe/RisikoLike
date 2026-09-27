# RisikoLike — Map Specification

> **Status:** Pre-Production / Map Data  
> **Dokumentversion:** 0.1  
> **Bezug:** `docs/GDD.md`  
> **Ziel:** Verbindliche Definition der V1-Weltkarte, Territoriums-IDs, Regionen, Nachbarschaften und Gebietskarten-Symbole.

## 1. Grundregeln

- `FIX` 42 Territorien
- `FIX` 6 Regionen
- `FIX` Reale geografische Anzeigenamen
- `FIX` Eigene Kartengrafik und eigene visuelle Grenzdarstellung
- `FIX` Stabile interne IDs sind von Anzeigenamen getrennt
- `FIX` Nachbarschaften werden explizit als Daten gespeichert und nicht aus der Grafik abgeleitet
- `FIX` Jede Nachbarschaft muss bidirektional sein
- `FIX` 42 Gebietskarten: 14 Infanterie, 14 Kavallerie, 14 Artillerie
- `FIX` 2 zusätzliche Joker werden separat im Kartendeck geführt und sind keinem Territorium zugeordnet

## 2. Regionen

| ID | Region | Territorien | Bonus |
|---|---|---:|---:|
| NA | Nordamerika | 9 | +5 |
| SA | Südamerika | 4 | +2 |
| EU | Europa | 7 | +5 |
| AF | Afrika | 6 | +3 |
| AS | Asien | 12 | +7 |
| OC | Ozeanien | 4 | +2 |
| | **Gesamt** | **42** | |

## 3. Territory Schema

Jedes Territorium benötigt später mindestens:

```text
id
name_de
region_id
neighbors[]
card_symbol
map_position
army_marker_position
polygon/mask
```

`map_position`, `army_marker_position` und `polygon/mask` werden erst mit dem finalen Kartenasset festgelegt.

## 4. Territorien und Nachbarschaften

### Nordamerika — 9

| ID | Anzeigename | Nachbarn | Kartensymbol |
|---|---|---|---|
| NA_01 | Alaska | NA_02, NA_06, AS_12 | Infanterie |
| NA_02 | Nordwestterritorium | NA_01, NA_03, NA_04, NA_06 | Kavallerie |
| NA_03 | Grönland | NA_02, NA_04, NA_05, EU_01 | Artillerie |
| NA_04 | Alberta | NA_02, NA_03, NA_05, NA_06 | Infanterie |
| NA_05 | Ontario | NA_03, NA_04, NA_06, NA_07, NA_08 | Kavallerie |
| NA_06 | Westliche USA | NA_01, NA_02, NA_04, NA_05, NA_07 | Artillerie |
| NA_07 | Östliche USA | NA_05, NA_06, NA_08 | Infanterie |
| NA_08 | Mittelamerika | NA_05, NA_07, SA_01 | Kavallerie |
| NA_09 | Kanadischer Archipel | NA_03, NA_05 | Artillerie |

> `NA_09` ist eine eigene V1-Gebietsdefinition. Die konkrete grafische Grenzziehung wird mit dem Kartenasset finalisiert. Die Nachbarschaften werden vor Implementierung nochmals auf Kartenbalance geprüft.

### Südamerika — 4

| ID | Anzeigename | Nachbarn | Kartensymbol |
|---|---|---|---|
| SA_01 | Kolumbien | NA_08, SA_02, SA_03 | Infanterie |
| SA_02 | Brasilien | SA_01, SA_03, SA_04, AF_01 | Kavallerie |
| SA_03 | Peru | SA_01, SA_02, SA_04 | Artillerie |
| SA_04 | Argentinien | SA_02, SA_03 | Infanterie |

### Europa — 7

| ID | Anzeigename | Nachbarn | Kartensymbol |
|---|---|---|---|
| EU_01 | Island | NA_03, EU_02, EU_03 | Kavallerie |
| EU_02 | Skandinavien | EU_01, EU_03, EU_04, EU_05 | Artillerie |
| EU_03 | Britische Inseln | EU_01, EU_02, EU_04, EU_06 | Infanterie |
| EU_04 | Nordeuropa | EU_02, EU_03, EU_05, EU_06, EU_07 | Kavallerie |
| EU_05 | Osteuropa | EU_02, EU_04, EU_07, AS_01, AS_02, AS_03 | Artillerie |
| EU_06 | Westeuropa | EU_03, EU_04, EU_07, AF_01, AF_02 | Infanterie |
| EU_07 | Südeuropa | EU_04, EU_05, EU_06, AF_01, AF_02, AS_03 | Kavallerie |

### Afrika — 6

| ID | Anzeigename | Nachbarn | Kartensymbol |
|---|---|---|---|
| AF_01 | Nordafrika | SA_02, EU_06, EU_07, AF_02, AF_03, AF_04 | Artillerie |
| AF_02 | Ägypten | EU_06, EU_07, AF_01, AF_03, AS_03 | Infanterie |
| AF_03 | Ostafrika | AF_01, AF_02, AF_04, AF_05, AF_06, AS_03 | Kavallerie |
| AF_04 | Zentralafrika | AF_01, AF_03, AF_05 | Artillerie |
| AF_05 | Südafrika | AF_03, AF_04, AF_06 | Infanterie |
| AF_06 | Madagaskar | AF_03, AF_05 | Kavallerie |

### Asien — 12

| ID | Anzeigename | Nachbarn | Kartensymbol |
|---|---|---|---|
| AS_01 | Ural | EU_05, AS_02, AS_04, AS_05 | Artillerie |
| AS_02 | Sibirien | EU_05, AS_01, AS_04, AS_06, AS_07 | Infanterie |
| AS_03 | Naher Osten | EU_05, EU_07, AF_02, AF_03, AS_04, AS_08 | Kavallerie |
| AS_04 | Zentralasien | AS_01, AS_02, AS_03, AS_05, AS_07, AS_08 | Artillerie |
| AS_05 | China | AS_01, AS_04, AS_07, AS_08, AS_09 | Infanterie |
| AS_06 | Jakutien | AS_02, AS_07, AS_10, AS_11 | Kavallerie |
| AS_07 | Mongolei | AS_02, AS_04, AS_05, AS_06, AS_09, AS_10 | Artillerie |
| AS_08 | Indien | AS_03, AS_04, AS_05, AS_09, OC_01 | Infanterie |
| AS_09 | Südostasien | AS_05, AS_07, AS_08, AS_10, OC_01 | Kavallerie |
| AS_10 | Ostasien | AS_06, AS_07, AS_09, AS_11 | Artillerie |
| AS_11 | Kamtschatka | AS_06, AS_10, AS_12, NA_01 | Infanterie |
| AS_12 | Fernost | AS_11, NA_01 | Kavallerie |

### Ozeanien — 4

| ID | Anzeigename | Nachbarn | Kartensymbol |
|---|---|---|---|
| OC_01 | Indonesien | AS_08, AS_09, OC_02, OC_03 | Artillerie |
| OC_02 | Neuguinea | OC_01, OC_03, OC_04 | Infanterie |
| OC_03 | Westaustralien | OC_01, OC_02, OC_04 | Kavallerie |
| OC_04 | Ostaustralien | OC_02, OC_03 | Artillerie |

## 5. Karten-Symbolverteilung

Aktuelle Zielverteilung:

| Symbol | Soll |
|---|---:|
| Infanterie | 14 |
| Kavallerie | 14 |
| Artillerie | 14 |

Die konkrete Tabelle in Abschnitt 4 muss vor dem Einfrieren der Map Spec automatisch validiert werden. Falls die Zählung durch spätere Gebietsänderungen abweicht, werden ausschließlich die Symbolzuordnungen angepasst; Territory-IDs bleiben stabil.

## 6. Verbindungsregeln

- Eine Verbindung `A -> B` muss immer auch als `B -> A` existieren.
- Wasserverbindungen sind spielmechanisch normale Nachbarschaften.
- Kartenrand-Verbindungen sind spielmechanisch normale Nachbarschaften.
- Die Darstellung einer Verbindung darf niemals die alleinige Regelquelle sein.
- Der Host validiert Angriffe anhand dieser Nachbarschaftsdaten.
- Fortification verwendet dieselben Nachbarschaftsdaten für die Pfadsuche durch eigene Territorien.

## 7. Noch offen vor Map Freeze

- `OFFEN` Finale Prüfung aller 42 geografischen Gebiete und Namen
- `OFFEN` Balanceprüfung der Nachbarschaftsgraphen
- `OFFEN` Finale Entscheidung zu `NA_09` und der nordamerikanischen Grenzziehung
- `OFFEN` Finale deutsche Anzeigenamen
- `OFFEN` Englische Anzeigenamen, falls Englisch in V1 enthalten ist
- `OFFEN` Kartenprojektion und Seitenverhältnis
- `OFFEN` Territoriums-Polygone/Masks
- `OFFEN` Army-Marker-Koordinaten
- `OFFEN` Kartenrand-/Wasserlinien im Asset
- `OFFEN` Automatischer Validator für Anzahl, Symbole und bidirektionale Nachbarschaften

## 8. Map Freeze Kriterien

Die Karte darf für V1 erst als `FIX`/eingefroren gelten, wenn:

1. exakt 42 eindeutige Territory-IDs existieren;
2. jede ID genau einer der sechs Regionen zugeordnet ist;
3. die Regionsgrößen 9/4/7/6/12/4 ergeben;
4. alle Nachbarschaften bidirektional sind;
5. keine Nachbarschaft auf eine unbekannte ID zeigt;
6. der gesamte Territory-Graph zusammenhängend ist;
7. jede Region intern erreichbar ist;
8. exakt 14 Infanterie-, 14 Kavallerie- und 14 Artillerie-Karten existieren;
9. jede Gebietskarte genau einem Territorium zugeordnet ist;
10. Kartenasset und Daten dieselben Verbindungen darstellen;
11. für jedes Gebiet eine gültige Klickfläche und Army-Marker-Position vorhanden ist.
