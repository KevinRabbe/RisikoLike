# ATLAS FRONT — Pieces, Dice and Cards Freeze

Status: **PASS / frozen; direct-manipulation dice amendment integrated**

## 1. Army Piece role

Each territory has exactly one visible command piece representing:

- ownership;
- army count;
- player identity;
- selection/temporary gameplay feedback.

It does not represent individual soldiers, tanks, buildings or unit classes.

## 2. Army Piece form

Target silhouette:

1. low dark base;
2. short graphite body;
3. clear number display;
4. player symbol/accent.

No tall miniature or flag.

Typical visual footprint at 1080p: ~30–38 px. Input target should be around 44 px minimum.

## 3. Piece size tiers

| Army count | Tier | Approx. relative size |
|---:|---|---:|
| 1–4 | S | 100% |
| 5–9 | M | 106% |
| 10–24 | L | 112% |
| 25+ | XL | 118% |

Size variance is deliberately small. XL does not keep growing with count.

## 4. Piece numbers

The army count is authoritative and visually dominant.

- screen-facing;
- high-contrast near-white;
- Inter Bold/tabular;
- player color is not used as text color.

Show full values through **9999**. Above that, compact form is allowed (`10.0K`, `12.5K`, `1.2M`) while tooltip/context shows the exact integer.

Stable game state must never show army count 0 or negative. Zero may appear only momentarily in combat/conquest presentation.

## 5. Player identity on piece

Every piece combines color + symbol:

- P1 ◆
- P2 ▲
- P3 ●
- P4 ■
- P5 ⬢

Base/rim carries player color; number remains neutral. This remains readable on same-color ownership fill.

## 6. Piece states

### Normal

Quiet. No pulse.

### Hover

Subtle brighter rim/plate over ~120–150 ms.

### Selected

Neutral bright ring + stronger accent + territory selection geometry. Minimal elevation is allowed when Reduced Motion is off.

### Attack source

Attack source is stronger than ordinary selected/hover state so the origin of the attack remains unambiguous during target selection and dice presentation.

Allowed treatment:

- stronger mask-based territory outline;
- controlled glow;
- stronger piece accent;
- slight scale/elevation while Reduced Motion is off;
- optional source→target route once target is armed.

Army count and territory label must remain readable. Source emphasis is presentation-only.

### Reinforced

Example `8 → +3 → 11`, total ~350–450 ms.

### Damaged

Example `12 → −2 → 10` with restrained material impact; no explosion.

### Conquered

Defender fades out, ownership transitions, attacker piece appears with moved army count, brief ownership accent. Target duration ~500–700 ms.

Dice never physically collide with pieces.

## 7. Dice role

Dice must feel physically present on the command table while remaining presentation-only.

Authoritative sequence:

`throw release → authoritative RNG/result fixed → gesture mapped to presentation → physical/hybrid roll → controlled natural-looking settle → visible comparison`

Mouse gesture, force, direction and spin never change die-face probabilities or combat outcomes.

Detailed interaction contracts are frozen in `13_DIRECT_MANIPULATION_AND_DICE_INTERACTION.md`.

## 8. Dice form/material

- classic six-sided cube;
- lightly rounded edges;
- dark graphite body;
- clear bright pips;
- restrained material detail.

Target screen size: ~38–46 px per die at 1080p.

Attacker role = warm amber/orange accent.

Defender role = cool cyan/blue accent.

Role colors are independent of player colors.

## 9. Dice collision

Dice collide with:

- the command-table / board floor;
- invisible safety walls aligned to the physical/simulated table edge;
- other dice.

Dice do not collide with:

- army pieces;
- territory labels;
- region labels;
- ownership masks;
- hover/selected visuals;
- routes;
- tooltips;
- HUD.

This is intentional. Dice may roll visually through the space occupied by pieces without knocking them over or moving them.

## 10. Dice presentation space

V1 does **not** restrict dice to a small dedicated roll zone.

The whole visible command-table / board surface is the V1 dice presentation space.

Dice may visibly:

- roll across the world map;
- cross territory art and ownership tints;
- pass through the visual footprint of army pieces;
- pass over labels and routes without affecting them;
- collide with other dice;
- bounce from the table edge;
- continue rolling until natural/controlled settle.

The table safety boundary prevents dice from leaving the simulated space.

Attacker and defender dice may still spawn as separate readable groups before the throw.

## 11. V1 dice throw gesture

Primary throw gesture:

`LMB press/hold on dice group → coarse mouse movement / stirring / sling motion → release`

The gesture is intentionally forgiving and must not require a perfect circle or pixel-accurate path.

Presentation inputs may include:

- recent travel distance;
- average pointer speed;
- peak pointer speed;
- release direction;
- coarse direction changes / stirring motion.

A nearly stationary release still produces a valid default/minimum-strength throw.

Click/keyboard/default-throw fallback remains available for accessibility.

## 12. Dice force mapping

Gesture intensity affects presentation only.

V1 normalized force range:

**40%–110%**

Guidance:

- ~40%: soft but clearly rolling throw;
- ~60–80%: ordinary throw;
- ~100%: strong throw;
- up to 110%: vigorous throw with longer travel/roll and potentially more table-edge bounces.

Values below the useful range clamp to 40%.
Values above the useful range clamp to 110%.

110% must never eject dice from the simulated table space.

## 13. Fake-3D / 2.5D dice space

Dice may use true 3D physics or a controlled fake-3D/2.5D implementation.

The visible contract matters more than the technique:

- dice read as occupying the same physical command table as the map;
- perspective is consistent with the table;
- table edges behave as believable collision/safety boundaries;
- stronger throws travel farther and settle later;
- dice cannot leave the simulation space;
- predetermined final faces remain visually credible.

Dice do not need physics interaction with pieces, labels or HUD.

## 14. Predetermined settle

The animation may use real or hybrid physics for motion but must deliberately settle to the precomputed faces.

The final correction must not look like teleporting, post-stop rotation or an obvious face swap.

If free physics fails to settle, use a controlled settle before the hard presentation timeout.

The gesture never changes the already-authoritative result.

## 15. Dice timing

### Normal

- spawn/grab: ~100–150 ms
- free/hybrid roll: typically ~600–1400 ms depending on force/collisions
- settle: ~200–350 ms
- result pause: ~350–500 ms
- total normal target: approximately **1.3–2.2 s**

### Fast

- spawn/grab: ~80 ms
- roll: ~350–650 ms
- settle: ~120–180 ms
- result pause: ~250–300 ms
- total target: ~0.8–1.2 s

AI 4× does not remove physical dice; visible movement retains an approximate 450–500 ms lower bound.

Hard dice presentation timeout remains approximately **2.5 s**. A 100–110% throw may roll longer than a soft throw, but must still transition into a controlled natural settle before the hard timeout.

## 16. Dice selection

Legal dice count is chosen primarily with the mouse wheel while pointer focus is over the attacker/defender dice interaction.

Only rule-legal values can be reached.

The same wheel event must not also zoom the map.

Click/keyboard selector alternatives remain available for accessibility and fallback input.

## 17. Dice result presentation

Physical dice stay where they settled while a clean result interpretation appears.

Example:

`ANGRIFF: 6 4 2`  
`VERTEIDIGUNG: 5 4`

Then comparisons:

`6 > 5 — VERTEIDIGER −1`  
`4 = 4 — ANGREIFER −1`

Unpaired dice dim. Tie rule is explicit.

Result remains readable for at least ~350 ms before a repeat action can proceed.

## 18. Future dice presentation surfaces — post-V1

V1 uses one primary presentation style:

**free throw across the command table / game board.**

The architecture should not prevent later cosmetic alternatives such as:

- dice cup;
- game-box/tray throw;
- automatic presentation surface.

These are explicitly **post-V1** and must not be implemented as part of the first release scope.

Any future surface is presentation-only and must not change:

- RNG;
- legal dice count;
- combat probabilities;
- combat rules;
- multiplayer authority.

## 19. Cards role

Cards are premium command cards, not fantasy collectible cards.

Portrait ratio approximately 2:3. Normal overlay target around 180×270 px at 1080p, with a useful range of ~170–190 × 255–285.

## 20. Card visual hierarchy

Front hierarchy:

1. type label;
2. type glyph;
3. territory name;
4. region/continent.

Types:

- INFANTERIE
- KAVALLERIE
- ARTILLERIE
- JOKER

## 21. Card glyph direction

- Infantry: geometric ground/shield motif.
- Cavalry: mobility/double-chevron motif.
- Artillery: target/impact motif.
- Joker: clearly distinct wildcard/prism motif.

No requirement for literal soldier/horse/cannon illustrations.

## 22. Joker

Joker contains no territory identity and no region. It uses only Joker/Wildcard presentation.

Two jokers are visually identical but have distinct internal card IDs.

## 23. Card bonus candidate

If a traded territory card represents a territory currently owned by the player, show a subtle candidate indicator such as `+2 MÖGLICH`.

When multiple candidates exist, trade preview lists choices and exactly one may be selected.

## 24. Card selection

Selected card:

- rises roughly 10–14 px;
- brighter border;
- optional small check marker;
- scale change at most ~2–3%.

Reduced Motion removes/reduces elevation/scale and keeps border state.

Invalid set is explained in preview; do not flood all cards red.

R8 may use direct drag-to-trade slots as the primary mouse interaction, but must retain keyboard/focus parity.

## 25. Trade preview

Preview must distinguish free and bound reinforcement.

Example:

`TAUSCHWERT +10 ARMEEN`  
`+10 frei verteilbar`  
`+2 auf Brasilien`

Do not misleadingly present `+12` as if all 12 were free placement.

## 26. Card back/privacy

One identical card back for all cards:

- ATLAS mark;
- dark command-table geometry;
- no type/territory hints.

AI/remote hands are represented only by count in player panel. Opponent trade presentation uses identical backs/public trade value; never reveal card identities.

## 27. Card draw

Human draw: card back moves/reveals to front and enters hand; ~600–900 ms normal, ~400–600 ms fast.

AI/remote draw: back-only public presentation, count increases; no front reveal.

## 28. Large hand behavior

- 1–5: readable fan.
- 6–8: stronger overlap, horizontal navigation allowed.
- 9+: horizontal scroll/strip.
- 20-card QA extreme: show roughly 5–7 usable cards at a time; never shrink below readable size.

Selected cards remain summarized in trade preview even when off-screen.

Keyboard: left/right focus, Space select/deselect, Tab through preview/bonus/primary action.

## 29. Card privacy on reconnect

Unknown/private data defaults hidden before rendering. A reconnecting client must never briefly display opponent card fronts before applying filtering.

## 30. Shared material language

Pieces, dice and cards share:

- dark neutral body/material;
- precise edge accents;
- limited saturation in base material;
- controlled emission/glow;
- clean command-table aesthetic.

They must not look as if they came from unrelated asset packs.

## 31. Reduced motion/audio parity

All object state information remains understandable with Reduced Motion and with SFX disabled.

Dice still visibly roll; direct-manipulation source/target semantics remain explicit; pieces/cards use simpler fades/state changes where needed.

## 32. Object QA fixtures

### Pieces

- PIECE-A: five players, count 1
- PIECE-B: counts 9 / 10 / 99 / 100 / 999 / 1250
- PIECE-C: Europe dense, all 88

### Dice

- DICE-A: 1v1
- DICE-B: 3v2
- DICE-C: tie + mixed losses
- DICE-D: 30 FPS + forced settle
- DICE-E: weak ~40% throw across board
- DICE-F: strong ~110% throw with table-edge bounce
- DICE-G: dice pass through piece footprints without moving pieces
- DICE-H: gesture invariance — same authoritative result remains independent of throw force/path

### Cards

- CARD-A: 5-card hand
- CARD-B: 12-card hand
- CARD-C: 20-card forced trade
- CARD-D: multiple +2 candidates
- CARD-E: hidden AI/remote cards
