# ATLAS FRONT — Design Decision Traceability Index

This index maps the long-form design discussion ranges to the canonical frozen documents. It is not a verbatim chat transcript. Earlier ideas that were superseded are intentionally normalized to the final decision.

Later explicit amendments are listed after the original D-range freeze and supersede only the interaction/presentation wording they explicitly replace; authoritative game rules remain unchanged.

## D1–D365 — Product, rules, UX foundation

Canonical destinations:

- `01_PRODUCT_RULES.md`
- `02_UX_STATE_MACHINE_AND_COPY.md`
- `06_SINGLEPLAYER_AI_SAVE_TIMER.md`

Covered topics include:

- product identity and “board is the star” principle;
- domain/UX/presentation state separation;
- 42 territories / 6 regions;
- start armies;
- reinforcement formula;
- combat/dice rules;
- card deck/trades/jokers;
- simultaneous initial deployment planning/reveal;
- turn order/round behavior;
- elimination/forced-trade interrupt;
- conquest movement minimum rule;
- connected-path fortification;
- zero-choice states;
- timer policy;
- singleplayer save/resume;
- base match layout and action flow.

## D364–D495 — Stress/edge-value UX audit

Canonical destinations:

- `03_VISUAL_SYSTEM_AND_LAYOUT.md`
- `05_PIECES_DICE_CARDS.md`
- `09_QA_ACCEPTANCE.md`

Covered topics include:

- army values 1–9999 and large values;
- reinforcement pools to 150;
- card hands to 20;
- 720p + 125% compact mode;
- ultrawide/16:10 behavior;
- 30 FPS/frame-spike behavior;
- AI 4× presentation;
- history virtualization;
- keyboard/accessibility;
- grayscale/color+symbol requirements;
- map/interaction fixture families.

## D496–D696 — Multiplayer product/robustness plan

Canonical destination:

- `07_MULTIPLAYER.md`

Covered topics include:

- private direct host/listen server;
- host/join/lobby/ready;
- opaque invite code;
- secret initial deployment;
- non-pausing multiplayer overlays;
- active-player reconnect grace;
- disconnected defender behavior;
- surrender/disconnect → permanent AI takeover;
- eliminated spectators;
- host loss terminal behavior;
- privacy/filtering/idempotency;
- rematch lobby;
- explicit V1 exclusions.

## D699–D790 — Screen/component inventory

Canonical destinations:

- `02_UX_STATE_MACHINE_AND_COPY.md`
- `03_VISUAL_SYSTEM_AND_LAYOUT.md`

Covered topics include:

- surface classes Screen/Match/Overlay/Drawer/Modal/Banner/Toast;
- full navigation tree;
- match intro/distribution/deployment;
- ActionPanel modes;
- cards/history/rules/settings overlays;
- pause/menu/reconnect/host-loss/end screens;
- overlay priority;
- reusable component families and states.

## D792–D910 — Visual token system and territory-presentation model

Canonical destinations:

- `03_VISUAL_SYSTEM_AND_LAYOUT.md`
- `04_MAP_PRODUCTION_SPEC.md`

Covered topics include:

- spacing/radii/material/glow tokens;
- neutral/player/semantic color roles;
- typography roles;
- responsive degradation rules;
- board layer roles;
- territory presentation record concept;
- piece/label/route anchors;
- region labels;
- edge connection presentation;
- runtime-vs-static map split.

## D911–D958 — Map names and production-wide map rules

Canonical destination:

- `04_MAP_PRODUCTION_SPEC.md`

Covered topics include:

- region names/bonuses;
- display-name strategy;
- internal ID vs display name separation;
- 1600×820 logical map space;
- board layer order;
- coast/border/ownership strategy;
- map perspective;
- label wrapping;
- small/dense territory handling;
- map acceptance gate.

Later repo-based ID mapping supersedes earlier provisional territory-order assumptions.

## D959–D1074 — Pieces, dice, cards and physical-object edge cases

Canonical destination:

- `05_PIECES_DICE_CARDS.md`

Covered topics include:

- piece form/tiers/count formatting/states;
- dice form/physics/predetermined settle/timings;
- card layout/glyph roles/large hands/privacy;
- Reduced Motion behavior;
- object-specific QA fixtures;
- forced-trade deterministic timeout rules.

## D1075–D1223 — Player-facing copy

Canonical destination:

- `02_UX_STATE_MACHINE_AND_COPY.md`

Covered topics include:

- German terminology;
- phase/action copy;
- invalid-input reasons;
- combat/conquest/fortification text;
- tutorial copy;
- save/resume/errors;
- multiplayer lobby/reconnect/host-loss copy;
- victory/defeat/history/tooltips;
- prohibition of technical/debug language.

## D1224–D1322 — Audio system and asset/runtime split

Canonical destination:

- `08_AUDIO_ASSET_MANIFEST.md`

Covered topics include:

- audio identity/buses/priorities;
- dice/piece/card/UI/system sounds;
- polyphony/cooldown/ducking/spatialization;
- audio privacy and audio-off parity;
- external asset vs runtime rules;
- preliminary asset families.

## D1323–D1399 — Territory production records and acceptance matrix

Canonical destinations:

- `04_MAP_PRODUCTION_SPEC.md`
- `09_QA_ACCEPTANCE.md`

Covered topics include:

- territory presentation record fields;
- interaction padding/tooltips/camera bias;
- Europe/edge/Oceania handling;
- LOD and dice safety;
- rule/state/board/combat/cards/AI/timer/save/network/accessibility acceptance gates;
- design-freeze semantics.

## D1400–D1459 — Final colors, symbols, font and edge-case closure

Canonical destinations:

- `03_VISUAL_SYSTEM_AND_LAYOUT.md`
- `09_QA_ACCEPTANCE.md`

Covered topics include:

- final five player symbol silhouettes;
- target HEX palettes;
- neutral palette;
- Inter typography direction;
- minimum supported window;
- input/network/save/resize/localization edge cases;
- severity model;
- scope exclusions such as replay/desktop notifications.

## D1460–D1588 — Zero-open-question design audit

Canonical destinations:

- all frozen documents;
- especially `01_PRODUCT_RULES.md`, `06_SINGLEPLAYER_AI_SAVE_TIMER.md`, `07_MULTIPLAYER.md`, `09_QA_ACCEPTANCE.md`.

Result:

- no known FAIL-category product questions;
- only data/technical validation items remained at that stage.

## D1589–D1616 — Repo-backed final map freeze

Canonical destination:

- `04_MAP_PRODUCTION_SPEC.md`

Repo inspection resolved the remaining map-data uncertainty. Finalized:

- real ID→display-name mapping;
- piece anchors;
- label anchors;
- route rules;
- special cross-region/ocean/world-wrap connections;
- region labels;
- dice avoidance;
- interaction policy.

Result: **ATLAS FRONT V1 — DESIGN FROZEN**.

## D1617–D1701 — Final asset manifest and implementation sequencing

Canonical destinations:

- `08_AUDIO_ASSET_MANIFEST.md`
- `10_IMPLEMENTATION_ROADMAP.md`

Covered topics include:

- KEEP/REFERENCE/REPLACE/RUNTIME/NEW/DEFERRED/UNUSED asset statuses;
- branding/environment/board/geography/piece/dice/card/UI/font/audio asset plan;
- legacy asset classification;
- production priorities P0/P1/P2;
- acceptance fixtures;
- R0–R15 milestone sequence.

## Post-freeze amendment A1 — Board-first direct manipulation

Canonical destinations:

- `02_UX_STATE_MACHINE_AND_COPY.md`
- `10_IMPLEMENTATION_ROADMAP.md`
- `13_DIRECT_MANIPULATION_AND_DICE_INTERACTION.md`

This explicit amendment replaces earlier button-first wording where necessary while preserving all authoritative rules.

Frozen decisions:

- the board is the primary gameplay input surface;
- ordinary in-match play is mouse-first and should be completable primarily with pointer buttons + mouse wheel;
- pointer gestures become UX intents and are still validated by the existing authoritative command path;
- command ghosts are presentation-only; authoritative pieces do not move during uncommitted drag;
- only legal targets accept drops;
- illegal drops mutate no GameState;
- attack source receives stronger emphasis than ordinary hover/selection and remains explicit through combat presentation;
- attack source→target can be armed by dragging a source command piece/ghost to a legal adjacent enemy territory;
- reinforcement, conquest movement and Verschiebung use contextual board-first amount interaction;
- mouse wheel selects legal amounts/dice values when context owns the wheel and must not simultaneously zoom the board;
- click/keyboard equivalents remain accessibility/fallback paths.

## Post-freeze amendment A2 — Full-table gesture dice

Canonical destinations:

- `05_PIECES_DICE_CARDS.md`
- `10_IMPLEMENTATION_ROADMAP.md`
- `13_DIRECT_MANIPULATION_AND_DICE_INTERACTION.md`

Frozen decisions:

- attacker/defender dice count is primarily selected with the mouse wheel;
- V1 throw gesture is `LMB hold → coarse stirring/sling movement → release`;
- no pixel-perfect circle recognition or gesture minigame;
- gesture intensity is clamped to a **40%–110%** presentation-force range;
- gesture changes direction/force/spin/travel only, never RNG probabilities or combat outcome;
- dice may roll freely across the visible command table and world map;
- dice collide with table floor/safety edges and other dice;
- dice do not collide with army pieces, labels, ownership masks, routes, tooltips or HUD;
- strong throws may bounce from table edges and settle later but cannot leave the simulated table space;
- true 3D and convincing fake-3D/2.5D implementations are both acceptable if the visible contract is met;
- predetermined natural-looking settle remains mandatory with an approximately 2.5 s hard presentation timeout;
- V1 has one presentation surface: free throw across the board/table;
- dice cup and game-box/tray alternatives are deferred cosmetic post-V1 ideas and must not affect authoritative combat.

## Freeze result

Current consolidated state:

**DESIGN FROZEN, WITH A1/A2 DIRECT-MANIPULATION AMENDMENTS.**

Remaining uncertainty is implementation validation only: exact visual calibration in the running game, font rendering/package validation, final generated/produced environment/geography quality, the exact rendering technique used for physical dice/pieces where multiple equivalent technical approaches can satisfy the frozen behavior, and runtime tuning of the 40–110% gesture-to-presentation mapping without changing its authority contract.
