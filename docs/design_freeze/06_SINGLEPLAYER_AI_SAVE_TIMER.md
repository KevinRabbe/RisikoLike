# ATLAS FRONT — Singleplayer, AI, Timer and Save Freeze

Status: **PASS / frozen**

## 1. Singleplayer scope

V1 singleplayer supports:

- Human + 1/2/3/4 AI
- total 2–5 players
- same 42-territory world-conquest rules
- same authoritative GameState / command processing rules as multiplayer-capable architecture

No AI difficulty selector in V1.

## 2. Singleplayer setup

Fields:

- commander name; default `COMMANDER`
- max 20 visible characters
- trim surrounding whitespace/control characters
- player color choice from the five unique identities
- AI count 1–4
- total player count derived automatically
- timer: AUS / 1 / 2 / 3 / 5 min, default 3
- concise match preview/rules summary

AI colors are assigned deterministically from remaining player identities.

Start action is protected against accidental double activation.

## 3. First boot

No mandatory first-boot wizard. Use sane defaults.

Tutorial/help is contextual and once-per-concept, not a startup barrier.

## 4. AI presentation principle

AI is an automated player, not a separate mode.

AI turns use the same visible semantic phase flow as human turns:

`Cards → Reinforcement → Attack → Fortification → Turn End`

Do not show artificial cursor movement, heuristic scores, threat maps, utility values or internal reasoning.

AI may compress repetitive no-choice presentation but may not hide strategically meaningful actions.

## 5. AI speed

V1 options:

- 1×
- 2×
- 4×

AI speed modifies presentation timing only; it never changes rules or decision quality.

At 4×:

- semantic grouping is encouraged;
- repeated same-target attacks may compress source/target transition delays;
- dice still visibly roll/settle;
- combat result readability is preserved.

## 6. AI reinforcement presentation

Show committed distribution semantically. Do not animate 9 separate `+1` clicks when one territory receives +9.

Example public status:

`AI 2 verteilt 9 Verstärkungsarmeen.`

Then show grouped piece updates by affected territory.

## 7. AI attack presentation

Show:

- attacking player;
- source;
- target;
- dice count;
- roll;
- result;
- conquest/movement;
- elimination when applicable.

Distinguish:

- „AI 2 kann aktuell keinen Angriff starten.“
- „AI 2 startet keinen Angriff.“

No legal move and deliberate skip are different semantic events.

## 8. Human defense against AI

AI attacking the local human temporarily replaces the bottom action area with a defense decision while the top bar still indicates the AI’s turn.

Human chooses 1–2 legal defense dice.

Defense response timer: **10 seconds**.

Timeout chooses maximum legal defense dice.

## 9. Turn timer

Configurable per match:

- AUS
- 1:00
- 2:00
- 3:00
- 5:00

Default 3:00.

Singleplayer timer runs only during the local human’s decision time.

AI does not show/use a full-turn countdown.

## 10. Timer pauses

Singleplayer turn timer pauses during:

- committed dice animation/result;
- conquest presentation;
- opponent defense response;
- mandatory non-decision animation;
- tutorial modal;
- singleplayer pause;
- blocking rules/settings states.

App focus loss in SP causes safe auto-pause after an atomic action if necessary.

## 11. Timeout behavior by state

- optional card trade → skip;
- required card trade → deterministic legal auto-trade;
- reinforcement → preserve preview, auto-place remainder, commit;
- attack idle/source/target before combat commit → end attack phase;
- committed combat → resolve fully;
- mandatory conquest move → auto minimum legal movement;
- fortification preview → discard preview/skip;
- normal card draw/turn end → continue normally.

At exact simultaneous `0` and user commit, authoritative command ordering prevents double action.

## 12. Timer presentation

Timer is hidden when disabled rather than displaying infinity or `--:--`.

Display format: `MM:SS`.

Visual warning:

- <30 s: state color shift only;
- <10 s: stronger but restrained critical state;
- no flashing full-screen warnings;
- Reduced Motion removes timer pulse.

Audio may give one warning near 10 s, not one beep per second.

## 13. Save model

Singleplayer V1 has exactly **one resumable autosave slot**.

No multi-slot save browser.

Autosave occurs only at safe/stable domain commit points.

Transient presentation such as hover, selection, camera position and dice animation is not saved as authoritative game state.

## 14. Saved state content

Save includes all information required to reproduce the match exactly, including:

- game/territory/player state;
- phase/turn/round;
- turn order;
- deck/discard/hands;
- global trade progression index;
- RNG state/seed information needed by current architecture;
- timer setting;
- remaining human decision time;
- conquered-this-turn and other rule-relevant flags;
- player/controller type information needed for SP continuation.

Remaining turn time is preserved to prevent resume-based timer reset exploits.

## 15. Save atomicity

Persistence must use an atomic/recoverable strategy:

1. write new save completely;
2. validate it;
3. only then replace the prior valid save.

A crash/power loss must not intentionally leave the only copy half-written.

Settings and match save are separate data areas; corrupt settings must not invalidate a valid match save.

## 16. Resume normalization

Resume restores authoritative game state, then normalizes presentation/transient interaction to a safe UX state.

Examples:

- attack selection resumes at `ATTACK_IDLE` rather than a stale target hover;
- camera resumes in Overview;
- local placement preview is not recreated unless it was an authoritative committed state;
- a combat already committed before crash resumes from its authoritative resolved state rather than rerolling.

## 17. Main-menu resume flow

If a valid autosave exists:

`EINZELSPIELER → FORTSETZEN / NEUES SPIEL / ZURÜCK`

Resume summary may show round, player count and human-readable phase.

If no valid autosave exists, singleplayer goes directly to setup.

## 18. Starting a new game with existing save

Require confirmation that the previous resumable match will be replaced.

Where technically reasonable, do not destroy the old valid save until the new match has successfully initialized to a valid replacement state.

## 19. Pause menu

Singleplayer pause actions:

- FORTSETZEN
- REGELN
- EINSTELLUNGEN
- SPEICHERN & HAUPTMENÜ
- MATCH AUFGEBEN

There is no restart-current-match action in V1.

## 20. Save-to-main vs surrender

`SPEICHERN & HAUPTMENÜ` keeps the match resumable.

`MATCH AUFGEBEN` permanently ends the match and removes resumable continuation after explicit confirmation.

Victory and defeat also remove resumable continuation.

## 21. Save failure

Autosave failure:

- does not crash the match;
- shows one nonblocking warning;
- avoids repeated spam;
- later successful save may show one recovery toast.

Corrupt save:

- friendly blocking explanation;
- user can go back or explicitly discard;
- never auto-delete without user action.

## 22. Singleplayer defeat

When the human loses the final territory, complete the full combat/conquest/elimination presentation first, then show defeat end screen.

Singleplayer does **not** enter a post-defeat spectator mode in V1.

## 23. Singleplayer victory

After the final conquest, leave the fully owned board visible for a brief beat before `ATLAS SECURED`.

Endscreen shows only a concise subset of useful stats, roughly 5–7 values.

No performance grade, star rating or score tier.

## 24. Stats collected

Potential tracked stats:

- turns_taken
- territories_conquered
- territories_lost
- combat_rolls
- comparisons_won
- comparisons_lost
- armies_lost
- enemy_armies_defeated
- players_eliminated
- card_trades
- cards_drawn
- continents_controlled_peak

Playtest telemetry may additionally collect dice count choices, repeat frequency and presentation timing, but such data is not displayed as internal AI/debug information.

## 25. Long history

Player-facing history is semantic/public and grouped by round.

UI must be virtualized/lazy for long matches.

Target safety capacity: about 10,000 detailed events. If an extreme QA match exceeds this, only oldest fully completed rounds may be compacted into summaries; the current round and major events (eliminations, surrender, reconnect, victory) remain available.

## 26. Current technical baseline note

Prior singleplayer implementation/testing achieved strong rule/softlock reliability, including a 100-match AI QA run. That technical success does not override the presentation redesign. The frozen design in this folder is the acceptance target for the next implementation phase.