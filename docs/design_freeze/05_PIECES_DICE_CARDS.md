# ATLAS FRONT — Pieces, Dice and Cards Freeze

Status: **PASS / frozen**

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

`RNG result fixed first → physical roll animation → controlled natural-looking settle → visible comparison`

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

- board surface;
- invisible board safety edge;
- other dice.

Dice do not collide with:

- army pieces;
- labels;
- routes;
- tooltips;
- HUD.

## 10. Dice spawn/placement

Runtime chooses a visible safe roll zone based on:

1. board viewport visibility;
2. HUD safe areas;
3. source/target avoidance;
4. piece density;
5. dice-avoidance heatmap;
6. room for all dice.

Attacker and defender groups start slightly separated.

## 11. Predetermined settle

The animation may use real physics for motion but must deliberately settle to the precomputed faces.

The final correction must not look like teleporting, post-stop rotation or an obvious face swap.

If free physics fails to settle, use a controlled settle before the hard presentation timeout.

## 12. Dice timing

### Normal

- spawn: 100–150 ms
- roll: 600–900 ms
- settle: 200–350 ms
- result pause: 350–500 ms
- total target: ~1.3–1.9 s

### Fast

- spawn: ~80 ms
- roll: 350–500 ms
- settle: 120–180 ms
- result pause: 250–300 ms
- total: ~0.8–1.1 s

AI 4× does not remove physical dice; visible movement retains an approximate 450–500 ms lower bound.

Hard dice presentation timeout: ~2.5 s.

## 13. Dice result presentation

Physical dice stay where they settled while a clean result interpretation appears.

Example:

`ANGRIFF: 6 4 2`  
`VERTEIDIGUNG: 5 4`

Then comparisons:

`6 > 5 — VERTEIDIGER −1`  
`4 = 4 — ANGREIFER −1`

Unpaired dice dim. Tie rule is explicit.

Result remains readable for at least ~350 ms before a repeat action can proceed.

## 14. Cards role

Cards are premium command cards, not fantasy collectible cards.

Portrait ratio approximately 2:3. Normal overlay target around 180×270 px at 1080p, with a useful range of ~170–190 × 255–285.

## 15. Card visual hierarchy

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

## 16. Card glyph direction

- Infantry: geometric ground/shield motif.
- Cavalry: mobility/double-chevron motif.
- Artillery: target/impact motif.
- Joker: clearly distinct wildcard/prism motif.

No requirement for literal soldier/horse/cannon illustrations.

## 17. Joker

Joker contains no territory identity and no region. It uses only Joker/Wildcard presentation.

Two jokers are visually identical but have distinct internal card IDs.

## 18. Card bonus candidate

If a traded territory card represents a territory currently owned by the player, show a subtle candidate indicator such as `+2 MÖGLICH`.

When multiple candidates exist, trade preview lists choices and exactly one may be selected.

## 19. Card selection

Selected card:

- rises roughly 10–14 px;
- brighter border;
- optional small check marker;
- scale change at most ~2–3%.

Reduced Motion removes/reduces elevation/scale and keeps border state.

Invalid set is explained in preview; do not flood all cards red.

## 20. Trade preview

Preview must distinguish free and bound reinforcement.

Example:

`TAUSCHWERT +10 ARMEEN`  
`+10 frei verteilbar`  
`+2 auf Brasilien`

Do not misleadingly present `+12` as if all 12 were free placement.

## 21. Card back/privacy

One identical card back for all cards:

- ATLAS mark;
- dark command-table geometry;
- no type/territory hints.

AI/remote hands are represented only by count in player panel. Opponent trade presentation uses identical backs/public trade value; never reveal card identities.

## 22. Card draw

Human draw: card back moves/reveals to front and enters hand; ~600–900 ms normal, ~400–600 ms fast.

AI/remote draw: back-only public presentation, count increases; no front reveal.

## 23. Large hand behavior

- 1–5: readable fan.
- 6–8: stronger overlap, horizontal navigation allowed.
- 9+: horizontal scroll/strip.
- 20-card QA extreme: show roughly 5–7 usable cards at a time; never shrink below readable size.

Selected cards remain summarized in trade preview even when off-screen.

Keyboard: left/right focus, Space select/deselect, Tab through preview/bonus/primary action.

## 24. Card privacy on reconnect

Unknown/private data defaults hidden before rendering. A reconnecting client must never briefly display opponent card fronts before applying filtering.

## 25. Shared material language

Pieces, dice and cards share:

- dark neutral body/material;
- precise edge accents;
- limited saturation in base material;
- controlled emission/glow;
- clean command-table aesthetic.

They must not look as if they came from unrelated asset packs.

## 26. Reduced motion/audio parity

All object state information remains understandable with Reduced Motion and with SFX disabled.

Dice still visibly roll; pieces/cards use simpler fades/state changes where needed.

## 27. Object QA fixtures

### Pieces

- PIECE-A: five players, count 1
- PIECE-B: counts 9 / 10 / 99 / 100 / 999 / 1250
- PIECE-C: Europe dense, all 88

### Dice

- DICE-A: 1v1
- DICE-B: 3v2
- DICE-C: tie + mixed losses
- DICE-D: 30 FPS + forced settle

### Cards

- CARD-A: 5-card hand
- CARD-B: 12-card hand
- CARD-C: 20-card forced trade
- CARD-D: multiple +2 candidates
- CARD-E: hidden AI/remote cards