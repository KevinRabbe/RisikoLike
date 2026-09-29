# ATLAS FRONT — R0 Implementation Inventory

Status: **R0 COMPLETE for remote baseline `main@3e3cd92e9aa79178cde3b3002350e43255326cee`**

This document maps the current repository structure to the frozen V1 redesign. It is an implementation preflight only. It does not authorize gameplay-rule changes, network-protocol changes, asset deletion, or broad rewrites.

## Baseline caveat

The GitHub baseline inventoried here is `main@3e3cd92e9aa79178cde3b3002350e43255326cee`.

There are unpublished local Singleplayer commits known from the active development context (`89a9a91`, `3641fe6`, `b04085e`) that are not present on GitHub `main`. Before R1 code execution, those local changes must be reconciled with the design-freeze branch so that newer SP/AI/save work is not accidentally lost or reimplemented from the older remote baseline.

No implementation agent may assume remote `main` contains the newest Singleplayer code until that reconciliation is completed.

---

## Application entry points

### Project/bootstrap — KEEP

- `project.godot`
  - main scene: `scenes/boot/Boot.tscn`
  - autoloads: `App`, `SceneRouter`, `NetworkManager`, `BackendClient`, `SessionManager`, `SettingsManager`, `AudioManager`
  - GL Compatibility renderer remains the current renderer baseline.
- `scripts/app/app.gd` — KEEP
- `scripts/app/boot.gd` — KEEP
- `scripts/app/scene_router.gd` — KEEP interface, MODIFY later only when frozen screen inventory requires new routes.
- `scripts/app/session_manager.gd` — KEEP unless local unpublished SP integration requires reconciliation.

The redesign must not replace the boot/autoload architecture merely to simplify presentation work.

### Current scene routes

- `scenes/menu/MainMenu.tscn`
- `scenes/menu/Settings.tscn`
- `scenes/menu/LocalSetup.tscn`
- `scenes/menu/CreateLobby.tscn`
- `scenes/menu/JoinLobby.tscn`
- `scenes/menu/Lobby.tscn`
- `scenes/game/Game.tscn`

`Game.tscn` is currently a deliberately thin root Control whose behavior is created by `game_controller.gd`. Preserve the public scene path unless there is a concrete migration reason.

---

# Presentation inventory

## `scripts/presentation/atlas_front_theme.gd`

**Classification: MODIFY / REPLACE INTERNALS in R1**

Retain its role as the centralized presentation-theme entry point if practical, but replace the current token values and style construction with the frozen visual-token system.

Required changes later:

- Inter typography and fallbacks;
- frozen neutral/player/semantic color roles;
- spacing/radius/border tokens;
- Primary/Secondary/Destructive button families;
- explicit focused/hover/pressed/disabled/busy states;
- panel/modal/tooltip/toast styles;
- UI-scale support;
- remove core dependence on old PNG icons.

Do not keep the current visual language merely for compatibility.

## `scripts/presentation/atlas_front_backdrop.gd`

**Classification: KEEP ROLE / MODIFY in R2**

The current cover-crop background component is useful infrastructure. Reuse or extend it for the frozen Command Room environment and ultrawide-safe composition.

It must not become the gameplay-world source of truth.

## `scripts/presentation/atlas_front_world_table.gd`

**Classification: REPLACE / UNUSED after R2**

This is currently a non-interactive decorative homescreen world/table drawing. Its present abstract globe/table rendering is not the frozen gameplay board and contains decorative baked runtime text.

Do not evolve this class into the production match map. Replace/remove its use only after the new Command Room shell exists.

## `scripts/presentation/main_menu.gd`

**Classification: MODIFY in R10; theme dependencies touched earlier**

Current menu is heavily procedural and presently exposes a multiplayer-first flow (`Lobby erstellen`, `Lobby beitreten`). Frozen root menu is:

- EINZELSPIELER
- MULTIPLAYER
- EINSTELLUNGEN
- BEENDEN

Keep scene/router integration and branding where useful. Replace layout/copy/navigation according to the frozen screen inventory.

## `scripts/presentation/local_setup.gd`

**Classification: RECONCILE FIRST, then MODIFY in R10**

Remote `main` still contains an old local-hotseat debug setup. The unpublished local SP commits are newer than this file and must be reconciled before any replacement work.

Do not redesign from this remote file as though it were the newest SP implementation.

## `scripts/presentation/settings_screen.gd`

**Classification: MODIFY in R11**

Retain SettingsManager integration. Replace the current small name/language/audio-only screen with the frozen Display / Audio / Gameplay / Controls / Accessibility structure.

Display-confirm/revert, UI scale, AI speed, camera focus, dice speed, Reduced Motion and tutorial reset belong here later.

## `scripts/presentation/create_lobby.gd`

**Classification: MODIFY in R12**

Current UI exposes host address, port, loopback/debug controls and raw network/backend failure codes. Those are incompatible with the frozen normal player flow.

NetworkManager calls may be retained behind the redesigned UI. Normal host flow must become product-facing rather than protocol-facing.

## `scripts/presentation/join_lobby.gd`

**Classification: MODIFY in R12**

Current UI includes optional manual address/session/secret/port controls and raw network error strings. Frozen normal flow uses one opaque invite input. Technical direct-address tooling may survive only as explicit developer/advanced fallback, not normal UI.

## `scripts/presentation/lobby_controller.gd`

**Classification: MODIFY in R12**

Current UI directly renders lobby IDs, player IDs, connection strings, protocol version, host address/port and technical connectivity states. Preserve LobbyState/NetworkManager integration but replace player-facing rendering with the frozen lobby model and human-language status vocabulary.

## `scripts/presentation/game_controller.gd`

**Classification: HEAVY MODIFY / DECOMPOSE across R2, R5–R10; preserve command boundary**

This is the current presentation bottleneck. It creates most match UI procedurally and combines:

- match shell;
- map integration;
- HUD labels;
- player panel;
- reinforcement controls;
- attacker/defender dice controls;
- cards shortcut/trade behavior;
- phase/end-turn controls;
- surrender/spectator controls;
- reconnect/result overlays;
- command creation/dispatch;
- local/network presentation branching.

The frozen redesign should decompose these responsibilities into reusable presentation components, but must preserve the authoritative command/state boundary.

Keep/reuse where possible:

- connection to `GameState` / `CommandProcessor` / `NetworkManager`;
- command submission and host-confirm behavior;
- lifecycle signal hookups;
- current scene entry point.

Replace:

- debug-like side panel;
- permanent combat parameter SpinBoxes;
- generic `Aktion bestätigen`, `Phase beenden`, `Zug beenden` button wall;
- raw technical status presentation;
- legacy reconnect/victory backdrop behavior;
- player-facing direct state dump patterns.

No domain rule may be moved into a UI widget during decomposition.

## `scripts/presentation/map_controller.gd`

**Classification: KEEP CORE INPUT ROLE / MODIFY in R3**

Useful existing responsibilities:

- polygon hit testing;
- pan/zoom;
- hover/selection tracking;
- screen↔map coordinate conversion;
- map-surface ownership.

Required later:

- frozen safe insets;
- 1.0 overview to ~1.8–2.2 max behavior;
- combat-focus cap;
- stable tooltip placement;
- piece/label/polygon input priority;
- final LOD and camera behavior.

Authoritative polygon hit testing remains valid.

## `scripts/presentation/map_visual_definition.gd`

**Classification: KEEP GEOMETRY / EXTEND METADATA in R3**

This file already provides the authoritative presentation polygons and the 1600×820 map coordinate system.

Do not replace the 42 polygons merely to improve visuals.

Extend or migrate presentation metadata to support the frozen fields:

- final visible-name mapping or localization key linkage;
- piece anchor;
- label anchor;
- route anchor / neighbor-specific connection overrides;
- label width/line policy;
- tooltip preference;
- interaction padding;
- camera bias;
- dice-avoidance weight.

## `scripts/presentation/territory_visual_definition.gd`

**Classification: MODIFY / EXTEND in R3**

Current schema contains polygon, label position, marker position and a generic connection-anchor array. Extend it to the frozen presentation record. Replace the ambiguous generic connection-anchor behavior with neighbor-specific connection overrides where required.

## `scripts/presentation/map_visual_validator.gd`

**Classification: KEEP / EXTEND in R3 and R14**

This is valuable QA infrastructure. Add validation for the expanded presentation metadata rather than replacing the validator.

## `scripts/presentation/production_map_surface.gd`

**Classification: REPLACE RENDERING INTERNALS in R3; preserve role/interface where practical**

Current renderer draws atmospheric PNG underlays, a fixed grid, cross-region dashed links, fully filled territory polygons, labels and circular army markers in one Control. This is exactly the presentation layer that must change.

Preserve:

- map-space 1600×820 basis;
- reading GameState rather than owning it;
- existing integration point with MapController where useful.

Replace:

- crude territory-first visual hierarchy;
- circular army markers;
- permanent cross-region dashed connections;
- fallback font rendering;
- ownership fills that make polygons read as disconnected cells;
- old interaction glow logic where it conflicts with frozen geometric states.

R3 must visually start from coherent neutral geography, then dynamic ownership/borders, then labels/pieces/routes.

---

# Domain boundary — DO NOT REWRITE FOR PRESENTATION

The following domain systems are authoritative and are out of scope for R1–R11 except for narrowly necessary additive adapters or display-name metadata changes:

- `scripts/domain/state/**`
- `scripts/domain/commands/**`
- `scripts/domain/combat/**`
- `scripts/domain/cards/**`
- `scripts/domain/rules/**`
- `scripts/domain/random_source.gd`
- `scripts/domain/game_clock.gd`
- `scripts/domain/map/map_data.gd`
- `scripts/domain/map/map_validator.gd`
- `scripts/domain/map/territory_definition.gd`
- `scripts/domain/map/region_definition.gd`

### Special case: `scripts/domain/map/map_data_factory.gd`

Adjacency, territory IDs, region IDs and card-symbol assignment are locked.

A display-name-only migration is permitted if this remains the canonical shared source for card/history/tooltip/rules naming. Do not mix visible-name cleanup with topology changes.

### Domain invariants that presentation must never own

- game phase and active player;
- reinforcement legality;
- attack/defense dice legality;
- RNG results;
- combat losses;
- conquest legality/minimum move;
- fortification path legality;
- card ownership/trade legality;
- turn timer truth;
- victory/elimination;
- state revision/action deduplication.

Presentation may preview or explain these values but may not become their source of truth.

---

# Network boundary — LOCK until R12

The following systems remain behaviorally out of scope during the Singleplayer-first visual rebuild:

- `scripts/network/network_manager.gd`
- `scripts/network/direct_invite.gd`
- `scripts/network/direct_network_transport.gd`
- `scripts/network/local_network_transport.gd`
- `scripts/network/in_process_transport.gd`
- `scripts/network/webrtc_network_transport.gd`
- `scripts/network/game_state_snapshot.gd`
- `scripts/network/network_message.gd`
- `scripts/network/network_serializer.gd`
- `scripts/network/network_transport.gd`
- lobby state/snapshot/player-entry data classes

R12 may replace their presentation integration, but not host authority, privacy filtering, reconnect identity, direct-host semantics or protocol behavior without an explicit separate architecture change.

`BackendClient` remains optional and must not become a V1 runtime requirement.

---

# Persistence boundary

Remote `main` currently exposes `scripts/persistence/settings_manager.gd` as the visible persistence module.

**Classification: KEEP and EXTEND only in the milestone that owns the setting.**

The unpublished local Singleplayer commits contain newer save/resume work that is not represented in this remote inventory. That implementation must be reconciled before R10 so no save system is accidentally rebuilt from scratch.

---

# Asset inventory lock

No assets are deleted during R0.

## KEEP / validate

- `assets/ui/atlas_front_final/branding/atlas_front_wordmark.png`
- `assets/ui/atlas_front_final/branding/atlas_front_mark.png`
- `assets/ui/atlas_front_final/branding/atlas_front_app_icon_1024.png`
- `assets/ui/atlas_front_final/backgrounds/main_menu_command_room.png`

## REFERENCE / replacement alignment

- `assets/ui/atlas_front_final/game/world_underlay.png`
- `assets/ui/atlas_front_final/game/ocean_grid.png`
- `decor/holographic_grid.png`
- `decor/command_corner.png`
- `decor/tech_pattern.png`
- utility/status icons where useful as visual reference

## REPLACE later

- legacy reconnect backdrop
- legacy victory backdrop
- card type PNGs with frozen vector/runtime glyph system
- final world-underlay usage with coherent neutral geography

## UNUSED in new core presentation, but do not delete yet

- six dice-face PNGs
- core gameplay icon PNGs (`army`, `attack`, `fortification`, `target`) as primary controls
- permanent scanline overlay
- separator-glow asset

Legacy assets may only be physically retired after R14/R15 reference verification.

---

# Existing QA / fixture entry points

Retain all current automated rule/network tests throughout the presentation rebuild.

Existing presentation/capture infrastructure includes:

- `tests/capture_m12_visuals.gd`
- `tests/capture_m13_visuals.gd`

These are regression references, not final visual acceptance fixtures. R14 will add/replace captures for the frozen MAP/PIECE/DICE/CARD/responsive fixtures. Do not delete the old capture harnesses before replacement coverage exists.

Existing direct-host/reconnect/host-loss/multi-client tests remain the regression net for R12; presentation work must not weaken them.

---

# R0 file classification summary

| Area | Classification |
|---|---|
| Domain rules/state/commands/combat/cards | **DO NOT TOUCH behavior** |
| Map topology / IDs / adjacency | **DO NOT TOUCH** |
| Network authority/protocol/transports | **DO NOT TOUCH through R11** |
| `game_controller.gd` | **HEAVY MODIFY / DECOMPOSE** |
| `production_map_surface.gd` | **REPLACE rendering internals** |
| `map_controller.gd` | **KEEP core / MODIFY presentation** |
| `map_visual_definition.gd` | **KEEP polygons / EXTEND metadata** |
| `territory_visual_definition.gd` | **EXTEND schema** |
| `map_visual_validator.gd` | **KEEP / EXTEND** |
| `atlas_front_theme.gd` | **REBUILD internals in R1** |
| `atlas_front_backdrop.gd` | **KEEP role / MODIFY** |
| `atlas_front_world_table.gd` | **REPLACE / UNUSED later** |
| Main menu / setup / settings presentation | **MODIFY in owning milestones** |
| Lobby/join/host presentation | **MODIFY in R12** |
| Branding | **KEEP** |
| old generated gameplay icons/dice sprites | **REFERENCE/UNUSED, no deletion yet** |
| current tests | **KEEP** |

---

# Required reconciliation before R1

Before the first code-changing redesign branch/prompt:

1. preserve the current local unpublished Singleplayer commits;
2. bring the design-freeze documentation into the same working history without dropping either side;
3. re-run the current Singleplayer/domain test baseline after reconciliation;
4. inventory any presentation/save/AI files introduced by the local commits and append them to this document if they are not present on remote `main`;
5. only then begin R1.

This is the only remaining R0 integration prerequisite.

---

# R0 acceptance result

- Design documentation exists in repository: **PASS**
- Remote presentation files inventoried: **PASS**
- Existing assets classified: **PASS**
- Match/map/HUD/setup/lobby entry points identified: **PASS**
- Domain/network do-not-cross boundaries identified: **PASS**
- Existing QA/capture entry points identified: **PASS**
- Gameplay behavior changed during R0: **NO**
- Assets deleted during R0: **NO**
- Local unpublished SP delta reconciled with remote baseline: **PENDING BEFORE R1**

R0 is therefore complete as an inventory, with one explicit repository-history reconciliation prerequisite before code execution.