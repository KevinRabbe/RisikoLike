# ATLAS FRONT — Map Production Specification

Status: **PASS / design frozen**

Authoritative existing data remains in `scripts/domain/map/map_data_factory.gd`, `scripts/presentation/map_visual_definition.gd` and `docs/MAP_SPEC.md`. This document freezes the redesign presentation layer on top of that domain topology.

## 1. Coordinate system

Logical map size remains **1600 × 820**.

All presentation anchors live in this map space and are projected into the board viewport. They are not stored in 1920×1080 screen pixels.

Territory polygons remain the interactive and ownership source of truth. Presentation anchors never alter topology, save identity, cards or network identity.

## 2. Display naming policy

Internal IDs stay stable. Display names may be modernized independently.

Canonical V1 German display-name mapping:

| ID | Display name |
|---|---|
| NA_01 | Alaska |
| NA_02 | Nordwestkanada |
| NA_03 | Grönland |
| NA_04 | Westkanada |
| NA_05 | Zentralkanada |
| NA_06 | Weststaaten |
| NA_07 | Oststaaten |
| NA_08 | Mittelamerika |
| NA_09 | Ostkanada |
| SA_01 | Kolumbien |
| SA_02 | Brasilien |
| SA_03 | Peru |
| SA_04 | Argentinien |
| EU_01 | Island |
| EU_02 | Skandinavien |
| EU_03 | Britische Inseln |
| EU_04 | Mitteleuropa |
| EU_05 | Osteuropa |
| EU_06 | Westeuropa |
| EU_07 | Südeuropa |
| AF_01 | Nordafrika |
| AF_02 | Ägypten |
| AF_03 | Ostafrika |
| AF_04 | Zentralafrika |
| AF_05 | Südafrika |
| AF_06 | Madagaskar |
| AS_01 | Ural |
| AS_02 | Sibirien |
| AS_03 | Naher Osten |
| AS_04 | Zentralasien |
| AS_05 | China |
| AS_06 | Nordostsibirien |
| AS_07 | Mongolei |
| AS_08 | Indien |
| AS_09 | Südostasien |
| AS_10 | Ostasien |
| AS_11 | Kamtschatka |
| AS_12 | Fernost |
| OC_01 | Indonesien |
| OC_02 | Neuguinea |
| OC_03 | Westaustralien |
| OC_04 | Ostaustralien |

`Japan` is not used in this map version because the existing domain has no matching territory/topology slot; `AS_12` remains Fernost.

## 3. Territory presentation record

Each territory presentation entry conceptually contains:

```text
territory_id
display_name_key
region_id
layout_class
piece_anchor
label_anchor
route_anchor
label_alignment
label_max_width
label_max_lines
leader_line
tooltip_preference
camera_focus_bias
interaction_padding
dice_avoidance_weight
connection_overrides
special_notes
```

Anchor roles are independent.

- `piece_anchor` = center of Army Piece
- `label_anchor` = center of full label block
- `route_anchor` = default route origin before radius offset
- `region_anchor` = center of continent label

No runtime force-directed layout.

## 4. Piece anchors

Existing marker positions are accepted as V1 baseline/frozen design anchors:

| ID | Piece anchor |
|---|---:|
| NA_01 | `(125, 212)` |
| NA_02 | `(270, 190)` |
| NA_03 | `(620, 175)` |
| NA_04 | `(270, 290)` |
| NA_05 | `(415, 292)` |
| NA_06 | `(270, 390)` |
| NA_07 | `(420, 415)` |
| NA_08 | `(415, 495)` |
| NA_09 | `(520, 260)` |
| SA_01 | `(482, 570)` |
| SA_02 | `(615, 620)` |
| SA_03 | `(500, 675)` |
| SA_04 | `(545, 775)` |
| EU_01 | `(735, 207)` |
| EU_02 | `(855, 165)` |
| EU_03 | `(795, 300)` |
| EU_04 | `(895, 305)` |
| EU_05 | `(1025, 315)` |
| EU_06 | `(860, 415)` |
| EU_07 | `(965, 435)` |
| AF_01 | `(855, 515)` |
| AF_02 | `(980, 530)` |
| AF_03 | `(1075, 610)` |
| AF_04 | `(945, 645)` |
| AF_05 | `(950, 765)` |
| AF_06 | `(1145, 735)` |
| AS_01 | `(1135, 295)` |
| AS_02 | `(1250, 255)` |
| AS_03 | `(1090, 425)` |
| AS_04 | `(1215, 395)` |
| AS_05 | `(1350, 420)` |
| AS_06 | `(1405, 235)` |
| AS_07 | `(1370, 345)` |
| AS_08 | `(1290, 530)` |
| AS_09 | `(1400, 575)` |
| AS_10 | `(1485, 350)` |
| AS_11 | `(1550, 210)` |
| AS_12 | `(1555, 465)` |
| OC_01 | `(1370, 675)` |
| OC_02 | `(1480, 670)` |
| OC_03 | `(1430, 775)` |
| OC_04 | `(1545, 775)` |

Small runtime calibration is permitted after real-font screenshots, but these are the implementation baseline.

## 5. Label anchors

| ID | Label anchor | Max width | Lines |
|---|---:|---:|---:|
| NA_01 | `(125,165)` | 90 | 1 |
| NA_02 | `(270,145)` | 135 | 2 |
| NA_03 | `(620,125)` | 105 | 1 |
| NA_04 | `(270,245)` | 110 | 1 |
| NA_05 | `(415,245)` | 130 | 2 |
| NA_06 | `(270,345)` | 105 | 1 |
| NA_07 | `(420,368)` | 105 | 1 |
| NA_08 | `(415,450)` | 120 | 1 |
| NA_09 | `(520,215)` | 105 | 1 |
| SA_01 | `(482,530)` | 100 | 1 |
| SA_02 | `(615,565)` | 100 | 1 |
| SA_03 | `(500,630)` | 80 | 1 |
| SA_04 | `(545,730)` | 105 | 1 |
| EU_01 | `(720,165)` | 85 | 1 |
| EU_02 | `(855,115)` | 115 | 1 |
| EU_03 | `(770,250)` | 110 | 2 |
| EU_04 | `(900,255)` | 105 | 1 |
| EU_05 | `(1025,265)` | 105 | 1 |
| EU_06 | `(835,370)` | 100 | 1 |
| EU_07 | `(975,390)` | 100 | 1 |
| AF_01 | `(830,475)` | 105 | 1 |
| AF_02 | `(985,490)` | 85 | 1 |
| AF_03 | `(1075,555)` | 95 | 1 |
| AF_04 | `(930,600)` | 115 | 1 |
| AF_05 | `(950,720)` | 100 | 1 |
| AF_06 | `(1145,690)` | 110 | 1 |
| AS_01 | `(1135,250)` | 75 | 1 |
| AS_02 | `(1250,205)` | 95 | 1 |
| AS_03 | `(1070,380)` | 105 | 2 |
| AS_04 | `(1215,350)` | 110 | 1 |
| AS_05 | `(1350,375)` | 85 | 1 |
| AS_06 | `(1400,185)` | 130 | 2 |
| AS_07 | `(1360,300)` | 100 | 1 |
| AS_08 | `(1290,485)` | 80 | 1 |
| AS_09 | `(1400,525)` | 115 | 1 |
| AS_10 | `(1485,305)` | 95 | 1 |
| AS_11 | `(1525,165)` | 105 | 1 |
| AS_12 | `(1540,425)` | 85 | 1 |
| OC_01 | `(1355,635)` | 100 | 1 |
| OC_02 | `(1470,630)` | 95 | 1 |
| OC_03 | `(1415,730)` | 120 | 2 |
| OC_04 | `(1530,730)` | 115 | 2 |

Labels remain screen-facing after board projection. Text is never rendered as skewed artwork on the board plane.

## 6. Layout classes

Supported classes:

- `STANDARD`
- `COMPACT`
- `EXTERNAL`
- `EDGE`

Given the current stylized polygon sizes, most territories can use internal labels. `EXTERNAL` remains an available fallback rather than being mandatory for every geographical island.

Critical dense/compact areas include Europe, Naher Osten and selected Oceania/edge territories.

## 7. Route anchors

Default:

`route_anchor = piece_anchor`

The visible route does not start at the number. Compute a departure point from center toward target at approximately piece radius + small padding.

Special connections use per-neighbor override metadata rather than a single generic connection anchor array.

Conceptual form:

```text
connection_overrides[neighbor_id] = type/ports
```

## 8. Cross-region / special connection presentation

Authoritative cross-region links include:

| Link | Presentation type |
|---|---|
| Alaska ↔ Kamtschatka | WORLD_WRAP |
| Grönland ↔ Island | SHORT_STRAIT |
| Mittelamerika ↔ Kolumbien | LAND_BRIDGE |
| Brasilien ↔ Nordafrika | OCEAN_ARC |
| Osteuropa ↔ Ural | DIRECT |
| Osteuropa ↔ Sibirien | SHORT_LINK |
| Osteuropa ↔ Naher Osten | DIRECT |
| Westeuropa ↔ Nordafrika | SHORT_STRAIT |
| Westeuropa ↔ Ägypten | SHORT_STRAIT |
| Südeuropa ↔ Nordafrika | SHORT_STRAIT |
| Südeuropa ↔ Ägypten | SHORT_STRAIT |
| Südeuropa ↔ Naher Osten | DIRECT |
| Ägypten ↔ Naher Osten | DIRECT |
| Ostafrika ↔ Naher Osten | SHORT_STRAIT |
| Indien ↔ Indonesien | OCEAN_LINK |
| Südostasien ↔ Indonesien | OCEAN_LINK |

These are visualizations of existing domain links; visuals never create topology.

## 9. World wrap

Alaska ↔ Kamtschatka is represented at both map edges, not by a line across the entire world.

Target design ports are around y≈198–202 near each edge. Both edge segments brighten together when relevant.

## 10. Atlantic arc

Brasilien ↔ Nordafrika uses a restrained ocean arc, approximately from Brazil’s east side through one control region in the Atlantic to the west side of Nordafrika. It should read as a strategic board link, not an airline route.

## 11. Permanent connection visibility

Normal map: special connections are hidden or extremely subdued.

- Hover: relevant special connection may appear subtly.
- Source selected: legal connections from source become clear.
- Target selected: active route is prominent.
- Combat: active route remains visible but reduced.
- Result end: route disappears.

Do not draw the full cross-region network permanently.

## 12. Region labels

Target anchors:

| Region | Anchor | Typical visibility |
|---|---:|---|
| Nordamerika | `(285,90)` | Overview + Normal |
| Südamerika | `(620,505)` | Overview + Normal |
| Europa | `(930,105)` | primarily Overview |
| Afrika | `(820,600)` | Overview + Normal, subdued |
| Asien | `(1280,105)` | Overview + Normal |
| Ozeanien | `(1450,585)` | Overview + Normal |

Format:

`EUROPA`  
`+5`

If fully controlled, append the controlling player symbol; do not write the player name into the map label.

## 13. Geography and ownership

The player should perceive a coherent neutral world first, then ownership and territory partitioning.

Visual order:

`neutral world geography → ownership masks → territory boundaries → labels/pieces/states`

The existing polygons remain exact hit/ownership data, but the final neutral geography should soften the current “42 crude polygons on a grid” appearance.

No contemporary national flags, capital labels, detailed political borders, satellite imagery or city networks.

## 14. Boundary behavior

- coastlines: continuous, neutral-cool, stronger than grid, weaker than selection;
- internal territory borders: thin and readable;
- same-owner border: roughly 40–60% weaker than different-owner border;
- same-owner boundaries are never removed entirely, even at victory.

## 15. Interaction priority

Input priority:

`piece > label > polygon`

Piece and label belong to one Territory Interaction Group, so hover must not flicker while moving between them.

Leader lines, if used, are not clickable.

## 16. Interaction padding

Use `NORMAL` for most territories.

Use `MEDIUM` for cramped/edge/small presentation cases such as Mittelamerika, Island, Britische Inseln, Westeuropa, Mitteleuropa, Südeuropa, Ägypten, Madagaskar, Ural, Naher Osten, Südostasien, Ostasien, Kamtschatka, Fernost, Indonesien and Neuguinea.

No territory currently requires a blanket `LARGE` hit expansion.

Padding may never overlap neighboring territory ownership in a way that makes selection ambiguous.

## 17. Tooltip direction

Primary directional policy:

- left map edge → tooltip right;
- right map edge → tooltip left;
- lower edge → tooltip up;
- upper edge → tooltip down;
- central area → `AUTO_INWARD`.

Runtime may mirror the preference to remain inside board safe bounds and avoid core HUD.

## 18. Dice avoidance

Weight 3 — strongly avoid: Europe, Naher Osten.

Weight 2 — avoid where possible: Zentralkanada, Mittelamerika, Nordafrika, Ägypten, Ostafrika, Ural, Zentralasien, China, Mongolei, Indien, Südostasien, Ostasien, Indonesien, Neuguinea.

Weight 1 — normal land areas.

Weight 0 — preferred open ocean/quiet board spaces.

Dice zones must be visible in the current camera and remain inside physical board/HUD safety bounds.

## 19. Europe composition

Europe is treated as one coordinated composition, not seven independent centroids.

Natural vertical bands:

- north: Island / Skandinavien;
- center: Britische Inseln / Mitteleuropa / Osteuropa;
- south: Westeuropa / Südeuropa.

Piece anchors have priority; labels radiate away from the dense center.

Routes within Europe are short/direct. Routes to Africa/Asia may arc outward to preserve readability.

## 20. Camera

Single territory focus centers within the free board viewport, not whole screen.

Combat focus uses bounding box of source + target + route plus ~12–18% padding.

Combat focus zoom is capped to preserve strategic context.

World-wrap attack does not zoom out to show the whole planet; the edge-link presentation explains the connection.

## 21. LOD

### Overview

Show ownership, pieces, counts, territory names as space permits, region labels and boundaries.

### Normal

Primary gameplay design target. All territory names, counts, interaction states and active routes must be readable.

### Close

May reveal extra material/geography detail, but never new gameplay-critical information.

Labels and army counts remain largely screen-space stable rather than scaling linearly with the board.

## 22. Special topology note

`AS_12 / Fernost` currently has only one authoritative neighbor: Kamtschatka. That is unusual but remains untouched by visual redesign. Any topology rebalance is a separate game-design change requiring tests and playtest approval.

## 23. Map acceptance fixtures

Mandatory fixtures:

- MAP-A: 2-player early game
- MAP-B: 5-player max-mixed ownership
- MAP-C: dominant late game
- MAP-D: victory, all territories same owner
- MAP-E: Europe dense with `88` army counts
- MAP-F: attack source + multiple legal targets
- MAP-G: fortification route
- MAP-H: dice roll
- MAP-I: 1280×720 + 125% UI
- MAP-J: 3440×1440
- world-edge fixture: Alaska → Kamtschatka
- Oceania fixture: ocean links + labels + dice nearby

Map is accepted only when a new player can identify land/water, all territories, owners, army counts, selection, legal targets and continent grouping without debug information.