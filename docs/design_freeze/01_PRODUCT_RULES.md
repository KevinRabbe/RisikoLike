# ATLAS FRONT — Product and Rules Freeze

Status: **PASS / frozen**

## 1. Match structure

- Players: **2–5**
- Victory mode: **world conquest only** in V1
- Territories: **42**
- Regions/continents: **6**
- No neutral AI in 2-player singleplayer.
- Turn phases:
  1. `TURN_START`
  2. `CARD_TRADE`
  3. `REINFORCEMENT`
  4. `ATTACK`
  5. `FORTIFICATION`
  6. `TURN_END`

Turn order is randomized once from the authoritative match seed and remains fixed for the match. Eliminated players are skipped and are not removed from presentation order.

Round ends after one traversal of the fixed order, skipping eliminated players.

## 2. Regions

| ID | Display name | Territories | Bonus |
|---|---|---:|---:|
| NA | Nordamerika | 9 | +5 |
| SA | Südamerika | 4 | +2 |
| EU | Europa | 7 | +5 |
| AF | Afrika | 6 | +3 |
| AS | Asien | 12 | +7 |
| OC | Ozeanien | 4 | +2 |

## 3. Starting armies

| Players | Starting armies per player |
|---:|---:|
| 2 | 40 |
| 3 | 35 |
| 4 | 30 |
| 5 | 25 |

Territory distribution is randomized independently from turn order so that the first player does not systematically receive remainder territories.

## 4. Initial deployment

Final setup model: **Simultaneous Planning → Visible Reveal**.

- Territory ownership is assigned first.
- Every territory begins with the appropriate initial minimum occupancy used by the current domain setup.
- Each player privately plans allocation of all remaining start armies.
- Human placement is reversible until commit.
- AI computes a complete plan but does not reveal individual placement before commit/reveal.
- Multiplayer exposes only plan/ready state, never placement contents before reveal.
- Once all players have committed, the final placements are revealed visibly in a fast sequence.
- Normal turn timer does not run during initial deployment.
- Round 1 begins only after reveal completion.

## 5. Reinforcement

Base reinforcement each own turn:

`max(3, floor(owned_territories / 3))`

plus controlled-region bonuses and any free armies from card trades.

Territory-card `+2` bonuses are direct additions to the specific chosen owned territory and are not part of the free reinforcement pool.

Reinforcement placement is planned reversibly and committed atomically. All free armies must be assigned before confirm.

Large pools are first-class. UI/logic must support at least stress values 3, 17, 35, 75 and 150 without degraded correctness.

### Reinforcement timeout

When human decision time expires:

1. preserve already planned placement;
2. assign remaining pool automatically;
3. prioritize selected/planned owned territories;
4. then owned border territories;
5. then other owned territories;
6. tie-break with authoritative RNG;
7. commit atomically.

## 6. Attack legality

A legal attack source:

- is owned by the active player;
- has at least 2 armies;
- has at least one adjacent enemy territory.

A legal target:

- is enemy-owned;
- is adjacent according to authoritative topology.

Visual distance does not create adjacency. Ocean and world-wrap links are normal authoritative adjacencies.

## 7. Dice rules

Attacker chooses 1 through:

`min(3, source_armies - 1)`

Defender chooses 1 through:

`min(2, target_armies)`

Rolls are authoritative d6 results. Sort both sides descending and compare up to `min(attacker_dice_count, defender_dice_count)`, maximum two pairs.

For each pair:

- attacker wins only when attack die is strictly greater;
- ties are won by defender.

Combat resolution is atomic.

The presentation pipeline is fixed:

`GameState RNG → authoritative result → dice presentation → visible comparison → state presentation`

Physics never determines the game result.

## 8. Repeated attack

After a non-conquering combat result, the player explicitly chooses what to do next. A previous dice count may remain preselected if still legal, but the game never auto-rolls the next combat.

## 9. Conquest

When target armies reach 0, conquest is automatic.

Mandatory movement into the conquered territory follows:

- **minimum = number of attacker dice used in the conquering roll**;
- **maximum = source armies after combat − 1**.

If min equals max there is no fake numeric choice, but the required movement is still shown and confirmed.

Ownership change and movement are committed atomically.

`conquered_this_turn = true` after any successful conquest.

## 10. Elimination sequence

Exact order:

1. conquest ownership/movement committed;
2. check defender territory count;
3. if 0, eliminate player;
4. transfer eliminated player’s cards to eliminator;
5. check victory;
6. if match not won, check forced-trade interrupt;
7. resume attack as appropriate.

Eliminated players do not receive future turns.

## 11. Victory

Victory condition: one player controls **all 42 territories**.

Final conquest fully resolves and is visibly presented before the match-end overlay.

Victory takes precedence over meaningless post-victory forced trades, fortification or card draw.

Target presentation:

`final combat → conquest → elimination if applicable → ~1 s full-board moment → victory/end screen`

## 12. Fortification / Verschiebung

Optional, at most once per turn.

- source and target must both be owned;
- target may be connected through an arbitrary path of owned territories;
- amount minimum 1;
- amount maximum source armies − 1;
- preview is reversible;
- commit is atomic;
- one successful movement consumes the phase.

If no legal fortification exists, show a short zero-choice explanation and auto-advance.

## 13. Cards and deck

Deck contains:

- 42 territory cards;
- 14 infantry;
- 14 cavalry;
- 14 artillery;
- 2 jokers without territory identity.

Exactly **44 unique cards** must exist across draw pile, discard pile and all hands at all times.

### Valid sets

A trade is valid when it contains either:

- three cards of the same regular type; or
- one of each regular type.

Jokers substitute required types.

### Progressive trade value

Global match-wide progression:

`4, 6, 8, 10, 12, 15, 20, 25, 30, 35, ...`

After 15, increase by +5 per subsequent global trade.

The progression is global, not per-player.

### Draw/discard recycle

Traded cards enter discard.

When draw pile is exhausted, discard is shuffled with authoritative RNG to form a new draw pile.

## 14. Card phase thresholds

- 0–2 cards: no trade decision; auto-advance after brief explanation.
- 3–4 cards: trade is optional if a valid set exists.
- 5+ cards: mandatory trades until hand is at most 4.

A normal end-turn draw that raises a hand to 5 does **not** cause an immediate same-turn trade. The obligation is handled on that player’s next own card phase.

## 15. Territory-card +2 bonus

At most one territory bonus per trade.

If multiple traded territory cards correspond to territories the player currently owns, the human chooses exactly one. If there is one candidate it is automatic; if none, no bonus is applied.

Bonus is applied directly to that territory.

## 16. Forced trade after elimination

If card transfer during attack causes the eliminator to have 5+ cards:

- interrupt attack;
- perform all mandatory trades until hand ≤4;
- collect all free trade reinforcement values;
- apply direct +2 territory bonuses per trade;
- perform one reinforcement-placement interaction for the collected free armies;
- resume at attack idle.

No optional extra trade is allowed in this interrupt once the hand is ≤4.

### Deterministic timeout selection

If a forced regular card phase times out:

1. enumerate legal sets deterministically;
2. sort by stable card IDs;
3. choose first legal set;
4. for multiple +2 candidates choose first by stable territory order;
5. repeat until obligation is satisfied.

No RNG is used for forced-trade timeout selection.

## 17. Card draw at turn end

If `conquered_this_turn` is true and the match has not already ended, the active player draws exactly one territory card at the normal turn-end point.

## 18. Zero-choice rule

When a UX state requires no decision, the UI gives a brief human-readable explanation and advances automatically. The player is not forced to press a meaningless `WEITER` button.

Tutorial `VERSTANDEN` is the intentional exception.

## 19. Atomicity invariants

Atomic domain commits include:

- card trade;
- reinforcement confirm;
- dice/combat resolution;
- conquest movement;
- fortification.

No stable state may contain half of one of these operations.

Stable state invariants include:

- exactly 42 territories;
- exactly one owner for every territory;
- every stable territory has army count ≥1;
- active players own at least one territory;
- eliminated players own 0;
- exactly one active player outside setup/end;
- exactly one domain phase;
- exactly 44 unique cards across all card locations;
- finished match rejects further gameplay commands.

Army values are validated by command deltas rather than a global conservation rule.