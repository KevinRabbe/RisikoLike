# ATLAS FRONT — UX State Machine and Player-facing Copy

Status: **PASS / frozen**

## 1. Architecture

Separate three layers:

- **Domain State** — authoritative rules/phase.
- **UX State** — the concrete player decision currently requested.
- **Presentation State** — camera, board highlights, animations, disabled controls, overlays.

Human, AI and remote-human turns use the same visible semantic flow; only the decision source differs.

## 2. Global interaction rules

- Hover territory → tooltip + subtle border.
- Click legal territory → select.
- Click same source → deselect.
- Click another legal source → switch source.
- Illegal input never changes game state; show brief contextual reason.
- `ESC` aborts current reversible substate before closing larger surfaces.
- Mouse wheel zooms board except when pointer is over an amount selector, where it adjusts the value.
- Drag/MMB pans board.
- Reset View is available as a small utility.
- Enter/Space may activate the unambiguous focused primary action.
- No misclick ends a phase.

## 3. High-level flow

`BOOT → MAIN MENU → SINGLEPLAYER SETUP or MULTIPLAYER → TERRITORY DISTRIBUTION → INITIAL DEPLOYMENT → ROUND/TURN START → CARDS → REINFORCEMENT → ATTACK → FORTIFICATION → CARD DRAW/TURN END → NEXT PLAYER → … → VICTORY/DEFEAT`

Setup and all regular gameplay use the same final board presentation.

## 4. Surface classes

- `SCREEN` — replaces current screen.
- `MATCH_SURFACE` — persistent match scene.
- `OVERLAY` — covers current surface, may block input.
- `DRAWER` — supplemental side content.
- `MODAL` — mandatory compact decision.
- `BANNER` — transient information.
- `TOAST` — short status acknowledgement.

Do not convert one class into another ad hoc.

## 5. Permanent match layout

Permanent match UI contains:

- top command bar;
- dominant board viewport;
- right player panel;
- bottom contextual action panel.

There is no permanent generic `ZUG BEENDEN` button.

### Top command bar

Contains brand, round/current player/phase and timer when enabled.

Phase strip is informational only:

`KARTEN · VERSTÄRKUNG · ANGRIFF · VERSCHIEBUNG`

Completed/active/upcoming states are shown, but the strip is never clickable.

### Right player panel

Up to five cards, always in turn order. Each player card may show:

- display name;
- player symbol/color;
- local `DU` badge;
- host badge where relevant;
- active `AM ZUG` state;
- territory count;
- public card count;
- disconnected/eliminated/AI-takeover status.

Eliminated players stay in their turn-order position and are dimmed.

Utilities: `KARTEN`, `VERLAUF`, `REGELN`.

### Bottom action panel

Stable three-part hierarchy:

- left: phase title + concise instruction;
- center: selected context/amount/dice/result;
- right: primary and limited secondary actions.

Primary action remains in a stable far-right/end position.

Conceptual modes:

`INSTRUCTION`, `SELECTION`, `AMOUNT`, `DICE`, `RESULT`, `WAITING`, `ZERO_CHOICE`.

## 6. Attack UX

### Attack idle

Instruction: **„Wähle ein eigenes Gebiet mit mindestens 2 Armeen.“**

Legal sources receive subtle non-pulsing affordance.

Secondary action: `ANGRIFF BEENDEN`.

### Source selected

Instruction: **„Wähle ein angrenzendes feindliches Gebiet.“**

Legal enemy targets are highlighted. The source remains visually distinct.

### Target selected

Show source → target, current army counts and legal attack dice `[1] [2] [3]` with illegal options disabled.

Primary: `WÜRFELN`.

### Human defense

When attacked, lower-priority overlays yield to the defense decision.

Instruction: **„{player} greift dein Gebiet {territory} an. Wähle deine Verteidigungswürfel.“**

Primary: `VERTEIDIGEN`.

### Rolling/result

State-changing input is disabled during committed roll presentation.

Result shows attacker dice, defender dice, pairwise comparison and army counts before→after. Unpaired dice are visually dimmed.

Tie copy is explicit: **„VERTEIDIGER GEWINNT“**.

### Conquest

Banner: `GEBIET EROBERT` + territory.

Then mandatory movement interaction. If minimum equals maximum, show the required value and only `BESTÄTIGEN`.

## 7. Reinforcement UX

Instruction at idle: **„Wähle eines deiner Gebiete.“**

Selected territory shows:

- current armies;
- planned addition;
- resulting armies;
- remaining reinforcement pool.

Amount selector supports `−`, `+`, `+1`, `+5`, `+10`, `ALLE`, hold repeat and mouse wheel.

When pool reaches 0:

- `ZURÜCKSETZEN`
- primary `BESTÄTIGEN`

Disabled confirm explanation: **„Verteile zuerst alle verbleibenden Armeen.“**

## 8. Fortification UX

Player-facing term is always **„Verschiebung“**, never “Fortification”.

Instruction: **„Du kannst einmal Armeen zwischen verbundenen eigenen Gebieten verschieben.“**

Flow:

source → connected owned target → amount → preview → `VERSCHIEBEN`.

Secondary at idle: `ÜBERSPRINGEN`.

No legal move → brief explanation and auto-advance.

## 9. Cards overlay

Modes:

- `READ_ONLY`
- `OPTIONAL_TRADE`
- `FORCED_TRADE`

Forced mode cannot be escaped.

Cards remain readable; large hands scroll horizontally instead of shrinking indefinitely.

Trade preview clearly separates free armies from territory-bound +2 bonus.

Example:

`+10 frei verteilbar`  
`+2 auf Brasilien`

Forced header: `KARTENTAUSCH ERFORDERLICH`.

## 10. Overlay/modal priority

Highest to lowest:

1. Fatal Error
2. Connection Lost / Host Lost
3. Display Confirmation
4. Mandatory Gameplay Decision
5. Confirmation Modal
6. Tutorial Hint
7. Pause / Multiplayer Menu
8. Rules / Settings / Cards
9. History Drawer
10. Toast

Only one blocking modal exists at a time.

## 11. ESC/back hierarchy

In match:

1. cancel reversible local selection/substate;
2. close current overlay/drawer when allowed;
3. open pause/menu.

Forced card trade cannot be closed.

Every screen has an explicit back route; Main Menu `ESC` never exits the application directly.

## 12. Tutorial hints

Once per concept, persisted until reset. Compact, no scrolling, always visible at 720p + 125% UI scale.

Seen only after `VERSTANDEN`.

Canonical concepts:

- reinforcement;
- attack source/target;
- dice comparison;
- conquest;
- cards;
- fortification;
- defense;
- forced trade.

## 13. Canonical terminology

| Concept | Player-facing German |
|---|---|
| Territory | Gebiet |
| Army | Armee / Armeen |
| Region | Kontinent |
| Reinforcement | Verstärkung |
| Attack | Angriff |
| Defense | Verteidigung |
| Fortification | Verschiebung |
| Card trade | Kartentausch |
| Conquest | Eroberung |
| Turn | Zug |
| Round | Runde |
| Player | Spieler |
| AI | KI |
| Spectator | Zuschauer |
| Ready | Bereit |

Brand terms such as `ATLAS // FRONT`, `ATLAS SECURED`, `FRONT LOST` and `COMMANDER` may remain English. Do not mix English jargon into ordinary instructions.

## 14. Copy style

Player-facing text is concise, calm and explicit. No debug language, blame language or fake urgency.

Good: **„Dieses Gebiet grenzt nicht an dein Ausgangsgebiet.“**

Bad: `INVALID_TARGET`.

Good: **„Die Spielsituation hat sich geändert. Bitte wähle erneut.“**

Bad: `STALE_REVISION`.

No gratuitous exclamation marks.

## 15. Canonical action/error copy

### Cards

- „Du besitzt noch keine Karten.“
- „Du besitzt noch kein vollständiges Kartenset.“
- „Du kannst aktuell kein gültiges Kartenset tauschen.“
- „Du kannst ein Kartenset tauschen oder mit der Verstärkung fortfahren.“
- `GÜLTIGES SET`
- `UNGÜLTIGES SET`
- „Wähle 3 Karten.“
- `TAUSCHEN`
- `ÜBERSPRINGEN`

### Reinforcement

- `VERSTÄRKUNG`
- „Noch {n} Armeen verfügbar.“
- „Verstärkungen können nur auf deinen eigenen Gebieten platziert werden.“

### Attack

- `ANGRIFF`
- „Wähle ein eigenes Gebiet mit mindestens 2 Armeen.“
- „Wähle ein angrenzendes feindliches Gebiet.“
- „Für einen Angriff müssen mindestens 2 Armeen im Ausgangsgebiet stehen.“
- „Von diesem Gebiet aus ist aktuell kein Angriff möglich.“
- „Wähle ein feindliches Gebiet.“
- „Dieses Gebiet grenzt nicht an dein Ausgangsgebiet.“
- `WÜRFELN`
- `NOCHMAL ANGREIFEN`
- `ANDERES ZIEL`
- `ANDERES AUSGANGSGEBIET`
- `ANGRIFF BEENDEN`

### Defense

- `VERTEIDIGUNG`
- „Wähle deine Verteidigungswürfel.“
- `VERTEIDIGEN`
- timeout banner: `VERTEIDIGUNG AUTOMATISCH`

### Conquest

- `GEBIET EROBERT`
- `ARMEEN VERSCHIEBEN`
- „Verschiebe Armeen in das eroberte Gebiet.“
- `BESTÄTIGEN`

### Fortification

- `VERSCHIEBUNG`
- „Wähle das Gebiet, von dem du Armeen verschieben möchtest.“
- „Wähle ein verbundenes eigenes Zielgebiet.“
- „Zwischen diesen Gebieten besteht keine zusammenhängende eigene Verbindung.“
- `VERSCHIEBEN`
- `ÜBERSPRINGEN`

## 16. Save/pause copy

Singleplayer pause actions:

- `FORTSETZEN`
- `REGELN`
- `EINSTELLUNGEN`
- `SPEICHERN & HAUPTMENÜ`
- `MATCH AUFGEBEN`

Quit-to-menu confirmation explains that the match is saved and resumable.

Surrender confirmation explicitly explains permanent end/deletion of the resumable save.

Corrupt save copy never auto-deletes the save; user can go back or explicitly discard it.

## 17. Multiplayer copy

Normal multiplayer uses human-language states only:

- `HOST`
- `BEREIT`
- `NICHT BEREIT`
- `VERBINDUNG VERLOREN`
- `KI ÜBERNOMMEN`

Invite UI exposes `CODE KOPIEREN`, not a full protocol payload.

Representative errors:

- `EINLADUNG UNGÜLTIG`
- `VERBINDUNG NICHT MÖGLICH`
- `MATCH VOLL`
- `SPIELVERSION NICHT KOMPATIBEL`
- `HOST NICHT MEHR VERFÜGBAR`

Advanced network help may mention TCP 43100; normal lobby does not.

## 18. End screens

Singleplayer victory:

`ATLAS SECURED`  
`WELTEROBERUNG ABGESCHLOSSEN`

Singleplayer defeat:

`FRONT LOST`  
`DEINE STREITKRÄFTE WURDEN ELIMINIERT`

Surrender:

`MATCH AUFGEGEBEN`

Multiplayer non-winner:

`MATCH BEENDET` + winner identity.

## 19. History

Player history contains semantic public information, grouped by round. No timestamps required in V1.

Examples:

- „Commander verstärkt Alaska um 3 Armeen.“
- „Commander greift Kamtschatka von Alaska aus an.“
- „Commander erobert Kamtschatka.“
- „Commander verschiebt 4 Armeen von Alaska nach Ostkanada.“
- „PLAYER 2 tauscht ein Kartenset für +10 Armeen.“
- „PLAYER 2 erhält eine Gebietskarte.“

Do not log every die by default. Do not leak opponent card identities.

When reading older history and new events arrive, preserve scroll position and show `N NEUE EREIGNISSE`.

## 20. Player-facing forbidden technical language

Normal UI must not expose:

- revision/state revision;
- action_id;
- peer_id;
- socket;
- raw state enum;
- protocol payload;
- `INVALID_COMMAND`;
- `PORT_MAPPING_FAILED`;
- null/undefined;
- stack traces.

Developer overlay is explicitly exempt.