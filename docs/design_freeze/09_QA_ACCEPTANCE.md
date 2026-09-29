# ATLAS FRONT — QA and Acceptance Matrix

Status: **PASS definition / frozen**

## 1. Severity model

### P0 — Match integrity

Can corrupt authoritative state, duplicate/lose data, softlock, crash critical flow or leak private information.

Examples:

- duplicate combat commit;
- broken card conservation;
- conquest state with no exit;
- opponent hand revealed;
- save duplication/loss;
- authoritative mismatch after reconnect.

Release requirement: **0 open P0**.

### P1 — Gameplay/UX critical

Rules remain technically correct but the player cannot reasonably continue or understand the core interaction.

Examples:

- mandatory confirm off-screen;
- territory cannot be selected;
- defense prompt hidden;
- source/target unclear;
- primary action unavailable at supported resolution.

Release requirement: **0 open P1**.

### P2 — Presentation/polish

Game remains correct/usable but misses visual/audio quality target.

Examples:

- label several pixels too close;
- minor animation roughness;
- sound mix imbalance;
- decorative alignment issue.

P2 requires explicit acceptance or fix plan.

## 2. Rule gate

Every command must have defined:

`precondition → effect → invalid result → timeout/disconnect behavior → next state`

At minimum cover:

- Start Match
- Initial Deployment Commit
- Trade Cards
- Reinforcement Preview/Confirm
- Attack Source/Target
- Attack Dice
- Defense Dice
- Resolve Roll
- Conquest Move
- End Attack
- Fortify
- Skip Fortification
- Draw Card
- End Turn
- Surrender/Leave

Any undefined branch is a design/implementation failure.

## 3. State-machine gate

Every UX state must have:

- at least one legal exit;
- explicit ESC/back behavior;
- timeout behavior where relevant;
- disconnect behavior where relevant;
- deterministic transition after authoritative commit.

Critical states:

- Forced Trade
- Reinforcement Commit
- Dice/Combat Commit
- Conquest Move
- Human Defense
- Reconnect

## 4. Domain invariants

At stable states verify:

- 42 territories exactly;
- unique IDs;
- exactly one owner per territory;
- stable army count ≥1;
- active player owns ≥1 territory;
- eliminated player owns 0;
- one active player outside setup/end;
- one active domain phase;
- exactly 44 unique cards across draw/discard/hands;
- finished match rejects gameplay commands;
- adjacency references are valid/bidirectional;
- all six regions retain expected sizes.

## 5. Core gameplay fixtures

Required scenario fixtures:

- `LAST_TERRITORY_VICTORY`
- `ELIMINATION_FORCED_TRADE_8_CARDS`
- `DRAW_PILE_EXHAUSTION`
- `CONQUEST_MIN_EQUALS_MAX`
- `NO_LEGAL_ATTACK`
- `NO_LEGAL_FORTIFICATION`
- `DEFENSE_TIMEOUT`
- `TURN_TIMEOUT_REINFORCEMENT`
- `HUMAN_ELIMINATED_BY_AI`
- `TWO_JOKER_TRADE`
- `MULTIPLE_OWNED_TRADE_TERRITORIES`

Tests cover normal, min, max, zero, boundary, interrupt, timeout, resume, AI, multiplayer-ready and invariant behavior.

## 6. Map fixtures

- MAP-A: 2-player early game
- MAP-B: 5-player mixed ownership
- MAP-C: dominant late game
- MAP-D: all 42 same owner
- MAP-E: Europe with dense `88` counts
- MAP-F: attack source + multiple legal targets
- MAP-G: fortification route
- MAP-H: dice roll
- MAP-I: 1280×720 + 125% UI
- MAP-J: 3440×1440
- World-edge: Alaska → Kamtschatka
- Oceania: ocean links + labels + dice nearby

Map gate passes only when land/water, all territories, ownership, counts, selection, legal targets and continent grouping remain understandable without debug data.

## 7. Piece fixtures

- five colors/symbols at count 1;
- 9 / 10 / 99 / 100 / 999 / 1250;
- dense Europe all 88;
- selected/hover/reinforced/damaged/conquered states;
- 720p clickability;
- grayscale comparison.

## 8. Dice fixtures

- 1v1;
- 3v2;
- tie + mixed losses;
- 30 FPS / frame spikes;
- forced settle hard timeout;
- Fast mode;
- AI 4× minimum visible roll;
- dice do not collide with pieces/labels/UI;
- dice cannot settle under right/bottom HUD;
- predetermined result remains visually natural.

## 9. Card fixtures

- 0 cards;
- 2 cards;
- 3 invalid;
- 4 optional-valid;
- exact 5 forced;
- 8 after elimination;
- 12-card hand;
- 14+;
- 20-card stress;
- two jokers;
- multiple +2 candidate territories;
- draw-pile exhaustion/recycle;
- AI/remote hidden hand;
- reconnect privacy.

## 10. Timer fixtures

Trigger expiry at:

- card selection;
- forced trade;
- reinforcement with/without preview;
- attack idle;
- source selected;
- target selected;
- exactly at combat commit;
- conquest move;
- fortification preview;
- human defense;
- tutorial/blocking modal.

No double commit, skipped mandatory action or softlock is acceptable.

## 11. Save/resume fixtures

Crash/exit around:

- attack idle;
- reinforcement preview;
- immediately after reinforcement commit;
- dice presentation;
- immediately after combat resolution;
- conquest;
- card draw;
- pause/menu save.

Expected invariants:

- no duplicate armies;
- no duplicate cards;
- no rerolled committed combat;
- no lost turn;
- remaining timer preserved;
- transient camera/hover selections normalized safely.

## 12. Multiplayer fixtures

- `MP_LOBBY_FULL`
- `MP_WRONG_SECRET`
- `MP_VERSION_MISMATCH`
- `MP_COLOR_RACE`
- `MP_DISCONNECT_LOBBY`
- `MP_DISCONNECT_MATCH_LOADING`
- `MP_DISCONNECT_ACTIVE_TURN`
- `MP_DISCONNECT_DEFENSE`
- `MP_RECONNECT_ATTACK`
- `MP_RECONNECT_AFTER_ROLL`
- `MP_SURRENDER_REMOTE`
- `MP_HOST_SURRENDER_ATTEMPT`
- `MP_HOST_ELIMINATED`
- `MP_HOST_LOSS`
- `MP_STALE_COMMAND`
- `MP_DUPLICATE_ACTION`
- `MP_CARD_PRIVACY`
- `MP_RECONNECT_PRIVACY`
- `MP_ELIMINATED_SPECTATOR`
- `MP_REMATCH`

## 13. Multiplayer privacy gate

Never leak:

- opponent card identities;
- secret initial deployment contents;
- reconnect credentials;
- raw AF1 secret in persistent normal UI;
- private data in spectator snapshot;
- hidden data for even a single render frame during reconnect/transition.

## 14. Input fixtures

- INPUT-A: normal mouse flow
- INPUT-B: double click
- INPUT-C: click/key spam
- INPUT-D: ESC during transition
- INPUT-E: Alt-Tab/focus loss
- INPUT-F: live resize
- INPUT-G: keyboard menus/cards/selectors
- INPUT-H: 30 FPS
- INPUT-I: timeout at commit boundary
- INPUT-J: AI 4×

Preview selections accept the latest local choice; committed primary action disables immediately to prevent backlog.

## 15. Input-device switching

Mouse movement after keyboard focus must not create contradictory double-focus states.

Gameplay selection and keyboard focus are separate concepts.

On application refocus, stale held inputs must not trigger accidental actions.

## 16. Responsive gate

Mandatory screenshots/playtests:

- 1920×1080
- 1600×900
- 1280×720
- 1920×1200
- 2560×1440
- 3440×1440

Also test UI scale 90/100/110/125 and OS DPI 125/150/200% where available.

At 720p + 125%:

- all five player cards remain accessible without normal scrolling;
- primary action stays on-screen;
- cards overlay remains usable;
- board remains strategically useful;
- tutorial hints fit without scroll.

## 17. Accessibility gate

Evaluate in grayscale:

- five player identities still separable via symbols;
- selected territory identifiable;
- legal target identifiable;
- active player identifiable;
- disabled/active button states distinguishable;
- critical meaning never relies on glow alone.

Run full gameplay with Audio Off and Reduced Motion.

## 18. Long-session gate

Minimum qualitative playtests:

- new player: understand core loop within several turns / about 10 minutes without external explanation;
- 60+ minute long session for visual/audio repetition fatigue;
- repeated attacks to detect dice/SFX annoyance;
- multiple consecutive AI turns at 4×.

No unskippable vanity sequence is acceptable.

## 19. History gate

History is virtualized/lazy and does not force scroll to bottom while user reads older events.

Round 200+/1000 layout remains valid.

Extreme >10,000 event handling may compact oldest completed rounds but must preserve current round and major events.

## 20. Visual acceptance

### Board

Must show all 42 counts/owners/selections/targets/geography as a premium command table.

### Action clarity

At any decision, player can answer:

- whose turn?
- which phase?
- what is happening?
- what should I do?
- what is the primary action?

### AI

Reinforcement, source/target, dice, losses, conquest and fortification remain legible.

### Combat

Without opening History, observer understands attacker, defender, dice, pair comparisons, losses and conquest result.

## 21. Original-bad-build regression gate

Release is blocked if any of these return to normal player UI:

- raw revision/state revision;
- Combat Parameters debug wall;
- prominent full AF1 payload;
- giant mixed event/state dump;
- crude disconnected polygon look with no coherent geography;
- tiny unreadable territory names;
- unclear next action;
- icon-only core interactions;
- board crushed by panels;
- raw player state dumps;
- retro/PS1-like UI typography.

## 22. Performance/presentation safety

Presentation must never permanently block domain progress.

- animation is time-based, not frame-count-based;
- dice hard timeout ~2.5 s;
- state-changing input disabled immediately after commit;
- no animation backlog from spam;
- history virtualized;
- effects degrade gracefully at low performance;
- if bloom/reflection fails, selection/ownership remain readable through geometry/text.

## 23. Copy gate

Search release UI/resources for forbidden technical terms. Normal player-facing UI must not expose:

`revision`, `action_id`, `peer_id`, `socket`, raw state enum names, `INVALID_COMMAND`, `PORT_MAPPING_FAILED`, `null`, `undefined`, stack traces.

Developer overlay is exempt.

## 24. Audio gate

Play at least one full match with Music=0 and another with Effects=0.

Run repeated-action fatigue test with audio enabled, especially 10+ attacks in succession.

## 25. Developer/QA overlay

Developer-only tooling may show:

- territory IDs;
- polygons;
- P/L/R anchors;
- legal actions;
- revision/action IDs;
- RNG/seed diagnostics;
- network peers;
- QA cheats/fixture jumps.

This overlay is off by default and not part of normal release HUD.

Useful QA cheats may include setting army count/hand/phase/timer, forcing conquest/elimination and simulating disconnect. They must not be available in normal player navigation.