# ATLAS FRONT — Direct Manipulation and Dice Interaction Amendment

Status: **PASS / frozen amendment**

This document amends the V1 interaction model without changing authoritative game rules. It is canonical for R6/R7 where it conflicts with earlier click-first interaction wording.

## 1. Product interaction principle

**The board is the primary input surface.**

ATLAS FRONT should feel like a digital strategic board game that the player manipulates directly with the mouse, not like a form-driven strategy UI.

Primary principles:

- mouse-first direct manipulation;
- the pointer behaves like the player's hand over the command table;
- legal actions are exposed spatially on the board;
- invalid destinations do not commit state;
- the authoritative domain remains the only source of legality;
- keyboard controls remain optional accessibility/fallback input, not a requirement for normal in-match play;
- text entry such as player names may still require keyboard input.

The player should be able to complete the ordinary match interaction loop with pointer buttons + mouse wheel.

## 2. Architecture

Input is translated through an explicit interaction layer:

`Pointer Gesture → UX Intent → authoritative legal-command validation → existing Domain Command`

Presentation may preview or animate an intent, but it never mutates authoritative state before the existing command path accepts the action.

Direct manipulation must not become a second rule engine.

## 3. Shared drag semantics

Dragging uses a presentation-only command ghost rather than physically relocating the authoritative piece before commit.

While dragging:

- the source remains visible;
- a ghost/drag proxy follows the pointer;
- only legal destinations receive target affordance;
- releasing on an illegal destination cancels cleanly and mutates no state;
- releasing on a legal destination advances to the relevant reversible/committed UX state.

Clicks remain valid fallback input where practical, but they are not the primary visual interaction model.

## 4. Source emphasis

Whenever a source territory is active for attack, conquest movement or fortification, the player must be able to identify it immediately.

Source emphasis may combine:

- stronger mask-based outline;
- restrained glow;
- stronger piece accent;
- slight visual scale/elevation while Reduced Motion is off;
- a source→target route/gesture line once a target is armed.

The effect must remain readable without color alone and must not obscure the army count or territory name.

Attack source emphasis is intentionally stronger than ordinary hover.

## 5. Reinforcement direct manipulation

The reinforcement phase remains a reversible plan followed by atomic confirmation.

Primary interaction:

1. select/grab reinforcement intent;
2. move to an owned territory;
3. use the mouse wheel to choose/adjust the amount in context;
4. place/update the reversible plan;
5. repeat across territories;
6. commit the completed plan with `BESTÄTIGEN`.

The exact presentation may use a reserve token/ghost or equivalent board-first interaction. The player must never be able to place reinforcement on an illegal territory.

Keyboard/buttons may provide equivalent fallback amount controls.

## 6. Attack direct manipulation

Primary attack flow:

1. grab an owned command piece/attack handle from a territory containing at least 2 armies;
2. source territory becomes strongly emphasized;
3. only legal adjacent enemy targets receive target affordance;
4. drag the command ghost to a legal enemy territory;
5. release to arm the attack;
6. source and target remain visually explicit;
7. choose legal attacker dice count with the mouse wheel while pointer focus is over the attack dice interaction;
8. physically throw the dice using the V1 throw gesture defined below.

The authoritative piece does not leave the source territory during drag.

Dropping anywhere other than a legal target cancels the drag without changing GameState.

The action panel explains the current state but does not replace the board as the primary interaction surface.

Representative armed-state copy:

`ANGRIFF · BRASILIEN → NORDAFRIKA`

`Mausrad: Würfel wählen · Würfel greifen und werfen`

## 7. Mouse-wheel routing

The mouse wheel is contextual.

Default:

- wheel over board → board zoom.

When pointer focus is over an active numeric interaction:

- reinforcement amount → adjust amount;
- conquest movement amount → adjust amount;
- fortification amount → adjust amount;
- attacker dice → choose legal attacker dice count;
- defender dice → choose legal defender dice count.

When consumed by an amount/dice interaction, the same wheel event must not also zoom the board.

Only values legal under the authoritative rules are reachable.

## 8. Human defense

Human defense uses the same mouse vocabulary as attack dice:

1. defense decision receives priority;
2. legal defender dice count is selected with the mouse wheel;
3. player grabs/throws the defender dice with the same gesture model;
4. authoritative combat result remains independent of the throw gesture.

A simple click/keyboard fallback remains available for accessibility and non-gesture input preferences.

## 9. Conquest movement

After conquest, the mandatory source/target relationship remains explicit on the board.

Primary amount interaction uses the mouse wheel and direct source→conquered-target presentation.

Only the rule-valid minimum/maximum range is reachable.

If minimum equals maximum, the mandatory value is shown directly and the interaction may collapse to a single confirmation.

## 10. Fortification / Verschiebung

Player-facing terminology remains **Verschiebung**.

Primary interaction:

1. grab an eligible owned source territory/piece;
2. only connected owned targets receive legal-target affordance;
3. drag to a valid target and release;
4. adjust the amount with the mouse wheel;
5. commit with `VERSCHIEBEN`.

Illegal destinations cancel without state mutation.

`ÜBERSPRINGEN` remains available while skipping is legal.

## 11. Dice result authority

The physical throw is presentation only.

Authoritative sequence:

`throw release → authoritative RNG/result fixed → gesture parameters mapped to presentation → physical/hybrid roll → controlled settle to fixed faces → comparison`

The gesture must never modify:

- die face probabilities;
- attack/defense result;
- loss calculation;
- reroll policy;
- network authority.

A player must not be able to improve odds by learning a particular mouse motion.

## 12. V1 dice throw gesture

Primary V1 throw gesture:

`LMB press/hold on dice group → coarse mouse movement / stirring / sling motion → release`

The gesture is intentionally forgiving.

Do not require:

- a perfect circle;
- a minimum number of rotations;
- pixel-accurate path recognition;
- a gesture-training minigame.

Useful presentation inputs may include:

- recent travel distance;
- average pointer speed;
- peak pointer speed;
- release direction;
- coarse direction changes / stirring motion.

Very small motion still produces a valid throw using the minimum force.

## 13. Dice force mapping

Gesture intensity maps only to presentation force.

V1 normalized force range:

**40%–110%**

Interpretation:

- ~40%: soft but clearly rolling throw;
- ~60–80%: ordinary throw;
- ~100%: strong throw;
- up to 110%: intentionally vigorous throw with longer travel/roll and potentially more table-edge bounces.

Input below the useful range clamps to 40%.
Input above the useful range clamps to 110%.

110% must never eject dice from the simulated table space.

## 14. Full-table dice physics space

V1 dice are **not restricted to a small dedicated dice zone**.

The whole visible command-table / board surface is the presentation space for the roll.

Dice may visibly:

- roll across the world map;
- cross territory art and ownership tints;
- pass through the visual footprint of army pieces;
- pass over labels/routes without affecting them;
- collide with other dice;
- bounce from the physical/simulated table edge;
- continue rolling until natural/controlled settle.

This intentional controlled chaos is part of the board-game feeling.

## 15. Dice collision contract

Dice collide with:

- command-table/board floor;
- invisible safety walls aligned to the table edge;
- other dice.

Dice do **not** collide with:

- army pieces;
- territory labels;
- region labels;
- ownership masks;
- hover/selected visuals;
- routes;
- tooltips;
- HUD.

Army pieces never get knocked over or displaced by dice.

## 16. Fake-3D / 2.5D table space

The dice presentation may use true 3D or a controlled fake-3D/2.5D implementation as long as the visible result is convincing.

Required visible behavior:

- dice read as occupying the same physical command table as the map;
- perspective is consistent with the table;
- table edges behave as believable collision/safety boundaries;
- stronger throws travel farther and settle later;
- dice cannot leave the simulation space;
- predetermined final faces remain visually credible.

The implementation technique is not authoritative; the visible contract is.

## 17. Settle and timeout

The existing predetermined-settle rule remains mandatory.

A stronger 100–110% presentation may take longer to settle than a soft throw, but it must remain within a bounded presentation budget.

Normal target remains approximately 1.3–2.2 seconds depending on force and collisions.

Hard presentation timeout remains approximately **2.5 seconds**. Before that deadline the system may transition from free/hybrid physics into a controlled natural-looking settle.

No teleport, obvious face swap or post-stop correction is acceptable.

## 18. Accessibility and fallback input

Direct manipulation is primary, but equivalent actions must remain possible without gesture precision.

Requirements:

- click-based source/target fallback;
- visible/focusable amount/dice alternatives where needed;
- keyboard equivalents for supported controls;
- Reduced Motion keeps semantic source/target states and dice readability;
- no rule or information is available only through motion;
- simple click/release may invoke a default-strength dice throw when a user cannot or does not want to perform the stirring/sling gesture.

Mouse-only normal gameplay remains a product goal; keyboard-only/accessibility parity remains a QA requirement rather than a competing primary visual design.

## 19. Future dice presentation surfaces — post-V1

V1 ships with one primary presentation surface:

**free throw across the command table / game board.**

The architecture should not prevent later cosmetic alternatives such as:

- dice cup;
- game-box/tray throw;
- automatic presentation surface.

These are explicitly **not V1 implementation scope**.

Future alternatives must be presentation-only and must not change:

- RNG;
- available dice counts;
- result probabilities;
- combat rules;
- multiplayer authority;
- timing semantics beyond equivalent presentation tuning.

## 20. R6 / R7 responsibility split

### R6 owns

- direct-manipulation UX state machine;
- source/target drag semantics;
- legal-target exposure;
- mouse-wheel contextual routing;
- reinforcement/conquest/fortification amount intent;
- attack source/target arming;
- fallback inputs;
- busy/commit/cancel hierarchy.

### R7 owns

- dice selection presentation attached to the R6 combat intent;
- click-hold throw gesture;
- 40–110% force mapping;
- full-table dice physics/fake-3D space;
- authoritative result handoff;
- predetermined natural settle;
- comparison/result presentation.

R6 may provide a temporary non-physical dice commit path until R7 replaces it, but it must not lock the product back into button-first combat interaction.

## 21. Acceptance gates

R6/R7 combined interaction acceptance includes:

- normal human turn can be played primarily with mouse buttons + wheel;
- attack source remains unambiguous during target selection and dice presentation;
- only legal targets accept a drop;
- illegal drops mutate no GameState;
- wheel never selects illegal amount/dice values;
- wheel consumption does not simultaneously zoom the board;
- dice gesture changes presentation only, never outcome;
- weak and strong gestures produce visibly different travel/energy;
- force is clamped to 40–110%;
- dice can cross the map without moving pieces;
- dice remain inside the table space;
- controlled settle reaches the authoritative faces before hard timeout;
- keyboard/click accessibility fallback remains functional;
- reduced-motion mode preserves all decision information.
