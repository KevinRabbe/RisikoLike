# ATLAS FRONT — Redesign Implementation Roadmap

Status: **sequence frozen; later direct-manipulation amendment integrated**

The redesign must be implemented in small deterministic milestones. Do not ask Codex or any implementation agent to “redesign the whole game” in one task.

Each milestone must preserve authoritative game rules unless the milestone explicitly says otherwise.

## Global implementation constraints

1. Do not rewrite working domain/network logic merely for visual convenience.
2. Presentation is a read model of authoritative state.
3. Territory polygons/topology stay authoritative.
4. No technical debug state in player-facing UI.
5. No new baked-text gameplay assets.
6. Do not delete the old asset pack until replacement fixtures pass.
7. Every milestone must leave the project runnable.
8. Prefer adding/replacing presentation behind explicit interfaces over large cross-cutting rewrites.
9. Keep singleplayer playable while presentation is rebuilt.
10. Multiplayer expansion waits until the singleplayer end-to-end presentation is stable.
11. For R6/R7, board-first mouse direct manipulation is the primary interaction model; it must translate into existing authoritative command paths rather than create a parallel rule engine.
12. Pointer gestures may affect presentation only. They must never alter RNG probabilities, combat rules or network authority.

Canonical direct-manipulation details are frozen in `13_DIRECT_MANIPULATION_AND_DICE_INTERACTION.md`.

---

# R0 — Freeze documentation and implementation inventory

Goal: make this design folder the implementation reference and map current code/assets to the new plan.

Tasks:

- retain this design-freeze documentation;
- produce a current presentation-file inventory;
- classify existing assets KEEP / REFERENCE / REPLACE / UNUSED;
- identify current match shell, map surface, HUD, cards, dice and setup entry points;
- identify domain/presentation boundaries that must not be crossed;
- define QA fixture entry points if not already available.

Acceptance:

- no gameplay code behavior change;
- project launches;
- inventory references exact files/classes;
- implementation can name what will be replaced versus retained.

Codex must not redesign anything during R0.

---

# R1 — Design tokens, typography and runtime theme

Goal: remove debug/retro visual language before rebuilding complex screens.

Implement:

- Inter-based UI typography and fallbacks;
- neutral/player/semantic color roles;
- spacing/radius/border tokens;
- primary/secondary/destructive button families;
- focus/hover/pressed/disabled/busy states;
- panel/modal/tooltip/toast base styles;
- UI scale presets 90/100/110/125;
- accessibility-safe focus geometry.

Do not yet redesign board geometry or dice.

Acceptance:

- representative component gallery/fixture at 1080p and 720p;
- no critical text <15 px;
- keyboard focus clear;
- P1–P5 identities work as color + symbol.

---

# R2 — Command-room match shell

Goal: make menu and match feel like one product and establish final screen regions.

Implement:

- command-room environment integration;
- board/table viewport container;
- top bar shell;
- right panel shell;
- bottom action panel shell;
- responsive constraints and safe insets;
- ultrawide behavior;
- reset-view utility placement.

Use placeholders only where a planned P0 asset is not available; placeholders must be neutral and clearly temporary, not a new visual direction.

Acceptance:

- board is visually dominant at 1920×1080, 1600×900, 1280×720, 3440×1440;
- no panel clips;
- 5-player right panel fits at 720p compact mode;
- same command-room identity visible from menu to match.

---

# R3 — World map and territory presentation

Goal: replace the crude polygon/debug appearance with the frozen coherent-world presentation while preserving topology.

Implement:

- neutral geography layer;
- runtime grid;
- ownership masks;
- coast/territory border hierarchy;
- final display-name mapping;
- frozen piece/label anchors;
- region labels;
- hover/selected/legal-target geometry;
- world-wrap and ocean connection presentation;
- map LOD;
- camera/pan/zoom/safe insets;
- developer anchor overlay for QA.

Do not change authoritative adjacency.

Acceptance fixtures:

- MAP-B mixed 5-player;
- MAP-D all same owner;
- MAP-E Europe all 88;
- Alaska→Kamtschatka;
- 720p+125%;
- ultrawide.

R3 is blocked from completion if the board still reads as 42 disconnected crude polygons.

---

# R4 — Army pieces

Goal: replace circular/debug army markers with frozen command pieces.

Implement:

- one neutral piece representation;
- runtime player accent + symbol;
- army numbers 1–9999 and compact >9999;
- S/M/L/XL subtle tiers;
- hover/selected/reinforce/loss/conquest states;
- attack-source emphasis hook stronger than ordinary hover;
- input hit area independent of visual size;
- no dice physics collision.

Acceptance:

- PIECE-A/B/C fixtures;
- Europe remains readable;
- grayscale/player-symbol test;
- 720p clickability;
- piece presentation can expose a distinct attack-source state without obscuring count/label.

---

# R5 — Core match HUD

Goal: finish top/right/bottom match interaction surfaces using real state.

Implement:

- top brand/round/current player/phase/timer;
- informational phase strip;
- right player cards in turn order;
- public territory/card counts;
- active/disconnected/eliminated/takeover badges;
- bottom ActionPanel modes;
- tooltip system;
- utility entry points for Cards/History/Rules.

Remove normal player exposure of revisions, raw state IDs and combat parameter debug controls.

Acceptance:

- new player can identify turn/phase/next action from a static screenshot;
- no old debug fields remain in normal UI;
- 5-player 720p fixture passes.

The ActionPanel is contextual explanation/fallback/commit UI. R6 makes the board itself the primary action surface.

---

# R6 — Human direct-manipulation UX state machine end-to-end

Goal: implement the frozen visible decision flow for one human player using the board as the primary mouse interaction surface without changing rules.

Architecture:

`Pointer Gesture → UX Intent → authoritative legal-command validation → existing Domain Command`

R6 must not introduce a second legality/rule engine.

Implement/refactor presentation for:

- turn start;
- card phase routing;
- reinforcement reversible plan/reset/atomic confirm;
- direct board placement/selection of reinforcement intent;
- contextual mouse-wheel amount routing;
- attack idle/source/target;
- grab/drag attack source using a presentation-only command ghost;
- strong source-territory emphasis while attack intent is active;
- legal-target-only drop affordance;
- valid drop arms source→target attack intent;
- attacker dice-count wheel routing and temporary non-physical commit fallback until R7;
- human defense decision routing and legal defender-dice selection;
- conquest movement source/target/amount;
- direct source→conquered-target amount interaction;
- end attack;
- fortification source/target/amount/skip;
- direct drag to connected owned target;
- zero-choice auto-advance;
- ESC/back/cancel hierarchy including active drags;
- busy/commit locking;
- canonical player-facing copy;
- click/keyboard accessibility fallbacks.

Direct-manipulation contracts:

- authoritative piece never moves during an uncommitted drag;
- command ghost follows pointer;
- only authoritative legal targets accept drops;
- illegal drops mutate no GameState;
- wheel amount/dice selection exposes only authoritative legal values;
- consumed wheel input does not also zoom the board;
- source remains visually unambiguous throughout target selection and subsequent combat presentation;
- ordinary in-match interaction should be completable primarily with mouse buttons + wheel;
- keyboard remains optional/fallback except for text entry.

R6 does **not** implement final physical dice physics; it prepares the combat intent and interaction hooks for R7.

Acceptance:

- complete human turn requires no debug panel knowledge;
- reinforcement, attack, conquest and fortification use board-first interaction rather than button-wall interaction;
- attack can be armed by dragging an eligible source to a legal enemy target;
- illegal drop causes no state mutation;
- source is always obvious while attack is armed;
- wheel amount/dice routing never exposes illegal values and never double-triggers map zoom;
- click/keyboard equivalent path remains available;
- no fake choices;
- timeout entry points remain compatible with frozen policy;
- input spam does not produce duplicate actions;
- a normal human turn can be performed with pointer + wheel, excluding text entry.

---

# R7 — Full-table dice and combat presentation

Goal: make combat physically readable and tactile on the command table while preserving authoritative outcomes.

Implement:

- attacker/defender dice-count interaction attached to R6 intents;
- mouse-wheel legal dice-count selection;
- click-hold dice grab;
- forgiving coarse stirring/sling throw gesture;
- gesture analysis using coarse distance/speed/release-direction data rather than pixel-perfect recognition;
- normalized presentation-force mapping clamped to **40%–110%**;
- authoritative result handoff before presentation settles;
- full command-table / board as the dice physics presentation space;
- true-3D or convincing fake-3D/2.5D dice space consistent with table perspective;
- collisions with table floor/safety edge/other dice only;
- explicitly no physics collision with army pieces, labels, ownership, routes, HUD or tooltips;
- strong throws may travel farther, bounce from table edges and settle later;
- dice may roll visually across the world map and through piece footprints without moving pieces;
- deterministic natural-looking settle to precomputed faces;
- approximately 2.5 s hard presentation timeout;
- Normal/Fast timing;
- pair comparison overlay;
- before→after army counts;
- repeat-attack flow;
- Reduced Motion compatibility;
- default-strength fallback throw for users who do not perform the gesture.

Critical authority contract:

`throw release → authoritative RNG/result fixed → gesture mapped to force/direction/spin presentation only → roll → controlled settle`

Throw gesture must never influence result probabilities.

V1 uses free throwing across the command table/game board. Dice cup, game-box/tray or other cosmetic throw surfaces are explicitly post-V1 and must not delay R7.

Acceptance:

- DICE-A/B/C/D existing fixtures;
- weak ~40% throw fixture;
- strong ~110% throw fixture with table-edge bounce;
- dice-cross-piece-footprint fixture proving no piece displacement;
- gesture-invariance fixture proving same authoritative result semantics independent of force/path;
- 30 FPS fixture;
- AI 4× lower-bound visibility;
- dice never leave simulated table space;
- no reroll or physics-authority bug;
- no obvious post-stop face correction.

---

# R8 — Cards

Goal: replace card/debug presentation with the frozen command-card system.

Implement:

- card face/back runtime layout;
- four type glyphs;
- large-hand fan/strip behavior;
- read-only/optional/forced overlay modes;
- valid/invalid set feedback;
- trade value/free-vs-bound reinforcement;
- +2 candidate choice;
- human draw reveal;
- opponent back-only presentation;
- keyboard navigation;
- reconnect privacy-safe defaults.

Mouse-primary card interaction may use direct drag-to-trade slots, but keyboard/focus parity remains mandatory.

Acceptance:

- CARD-A through CARD-E;
- 20-card forced trade usable;
- no private-card leak.

---

# R9 — AI presentation

Goal: ensure AI uses the same polished visible flow.

Implement:

- semantic reinforcement grouping;
- visible attack source/target/dice/result/conquest;
- visible fortification;
- voluntary skip vs no-legal-action copy;
- 1×/2×/4× timing behavior;
- human defense interrupt during AI turn;
- no fake cursor/no heuristic display.

AI does not need to fake human drag gestures. It uses the same semantic source/target/presentation states while the decision source remains AI.

Acceptance:

- four consecutive AI turns remain understandable;
- 4× does not become invisible state jumps;
- repeated attacks remain readable without excessive delay.

---

# R10 — Singleplayer setup, save/resume and end screens

Goal: complete production-quality singleplayer shell.

Implement:

- root menu singleplayer flow;
- resume/new-game choice;
- setup fields;
- replacement confirmation;
- match intro/distribution/initial deployment presentation;
- pause menu;
- save/recovery warnings;
- defeat/victory/surrender screens;
- concise stats.

Acceptance:

- valid/corrupt/missing save flows;
- crash/resume fixtures;
- no restart-current-match button;
- surrender and save-to-main remain distinct.

---

# R11 — Accessibility, responsive behavior and settings

Goal: harden presentation across supported environments.

Implement:

- Display/Audio/Gameplay/Controls/Accessibility categories;
- display mode/resolution/UI scale/VSync where technically solid;
- display-change safety countdown/revert;
- AI speed;
- camera focus preference;
- dice speed Normal/Fast;
- Reduced Motion;
- tutorial/help reset;
- keyboard focus across menus/settings/cards/dialogs;
- keyboard/click equivalents for direct-manipulation actions;
- pointer/gesture fallback to default-strength dice throw;
- responsive compact modes.

Acceptance:

- all supported resolutions/UI scales;
- grayscale check;
- Audio Off / Reduced Motion full-playability;
- direct-manipulation semantic information remains available without relying on motion alone;
- keyboard/focus fallback covers the same authoritative gameplay decisions;
- display confirm auto-revert.

---

# R12 — Multiplayer UX integration

Goal: apply the frozen visual system to direct-host multiplayer without changing the network authority model.

Implement/refactor presentation for:

- multiplayer root;
- host setup;
- join screen;
- lobby/ready/start;
- opaque invite/copy;
- human-language network warnings/errors;
- secret initial deployment;
- non-pausing multiplayer menu/overlays;
- defense interrupt priority;
- reconnect overlays/countdown;
- AI takeover badge/presentation;
- eliminated spectator mode;
- host-loss terminal screen;
- post-match return-to-lobby/rematch.

Direct manipulation remains local presentation/intent input. Network authority and command validation remain unchanged.

Acceptance:

- multiplayer fixture suite;
- no raw protocol details in normal flow;
- card/plan privacy;
- host loss/surrender/takeover semantics match frozen rules.

---

# R13 — Audio

Goal: integrate the frozen semantic audio system after visuals are stable.

Implement:

- audio buses/settings;
- menu/match ambience;
- UI/piece/dice/card/major-event families;
- cooldowns/polyphony;
- light ducking/spatialization;
- privacy-safe opponent card audio.

Acceptance:

- complete match with Music=0;
- complete match with Effects=0;
- repeated 10+ combat fatigue test;
- no audio-only information.

---

# R14 — Capture/fixture gates

Goal: prove the redesign against frozen acceptance criteria before release hardening.

Automate or make reproducible:

- map fixtures;
- pieces/dice/cards fixtures;
- direct-manipulation source/target fixtures;
- illegal-drop/no-state-change fixture;
- wheel-routing/no-double-zoom fixture;
- weak/strong full-table dice throws;
- dice-through-piece-footprint fixture;
- 1080p/900p/720p/ultrawide captures;
- Reduced Motion/grayscale variants where practical;
- AI 4×;
- timeout/reconnect overlays;
- victory/defeat.

Run original-bad-build regression gate: no revision HUD, raw combat-parameter wall, tiny labels, crushed board, debug state dumps or icon-only core actions.

---

# R15 — Release hardening

Goal: production release candidate after presentation acceptance.

Tasks:

- full rule/network/save regression suite;
- P0/P1 = zero;
- asset/license audit;
- remove/retire unused legacy assets only after verified no references;
- package audit;
- Windows startup smoke;
- long-session playtest;
- final screenshot/capture review;
- direct-manipulation end-to-end playtest with mouse-first path;
- release checklist update.

Do not use R15 to introduce major new product features.

## Milestone discipline

Each implementation prompt should state:

- exact milestone goal;
- files/classes in scope;
- files/systems explicitly out of scope;
- frozen design decisions to follow;
- acceptance fixtures;
- tests to run;
- required commit/report format.

If an implementation agent encounters a real conflict in the frozen spec, it must surface the conflict instead of inventing a new design.
