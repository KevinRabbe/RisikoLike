# ATLAS FRONT — V1 Design Freeze

Status: **DESIGN FROZEN**

This folder is the canonical consolidated specification for the redesign discussions that ran through the design-decision series up to **D1701**. It intentionally preserves the **latest/final decision** when earlier chat decisions were superseded.

If this folder conflicts with older presentation-oriented documentation, this folder wins for the redesign unless a later commit explicitly changes the decision.

## Product identity

**ATLAS FRONT = a digital strategic board game played on a futuristic Command Table.**

The board is the star. The room, HUD, animation and audio support the board; they do not compete with it.

## Non-negotiable principles

1. Every turn must make clear who is active, which phase is active, what the player can do, what is clickable and how to continue.
2. Game rules and authoritative state are separate from presentation.
3. AI is an automated player using the same visible game flow; it is not a debug mode.
4. Technical concepts such as revisions, action IDs, peer IDs, raw state enums and socket errors never appear in normal player UI.
5. Readability beats decorative art.
6. Player identity is always **color + symbol**.
7. Important actions use explicit text labels; icon-only actions are restricted to universally understood utilities.
8. No gameplay-relevant text is baked into images, except branding/wordmark.
9. Presentation must never own game-state truth.
10. No implementation milestone is allowed to invent unresolved product behavior.

## Documents

- [01_PRODUCT_RULES.md](01_PRODUCT_RULES.md) — core rules, phases, cards, combat, victory, setup
- [02_UX_STATE_MACHINE_AND_COPY.md](02_UX_STATE_MACHINE_AND_COPY.md) — UX states, overlays, action flows, canonical player-facing language
- [03_VISUAL_SYSTEM_AND_LAYOUT.md](03_VISUAL_SYSTEM_AND_LAYOUT.md) — layout, responsive rules, typography, colors, component system, motion
- [04_MAP_PRODUCTION_SPEC.md](04_MAP_PRODUCTION_SPEC.md) — 42-territory map production specification and final display-name mapping
- [05_PIECES_DICE_CARDS.md](05_PIECES_DICE_CARDS.md) — physical/digital tabletop objects
- [06_SINGLEPLAYER_AI_SAVE_TIMER.md](06_SINGLEPLAYER_AI_SAVE_TIMER.md) — SP setup, AI presentation, timers, save/resume, defeat/victory
- [07_MULTIPLAYER.md](07_MULTIPLAYER.md) — direct-host V1, lobby, reconnect, takeover, spectator and privacy
- [08_AUDIO_ASSET_MANIFEST.md](08_AUDIO_ASSET_MANIFEST.md) — audio system and final asset-vs-runtime plan
- [09_QA_ACCEPTANCE.md](09_QA_ACCEPTANCE.md) — acceptance gates, fixtures, edge cases, severity policy
- [10_IMPLEMENTATION_ROADMAP.md](10_IMPLEMENTATION_ROADMAP.md) — R0–R15 execution order and implementation constraints
- [11_R0_IMPLEMENTATION_INVENTORY.md](11_R0_IMPLEMENTATION_INVENTORY.md) — exact remote-baseline code/asset inventory, KEEP/MODIFY/REPLACE boundaries and pre-R1 reconciliation requirement
- [DECISION_INDEX.md](DECISION_INDEX.md) — traceability from major D-ranges to the canonical documents

## Existing source-of-truth files that remain important

The redesign does **not** replace authoritative domain/network architecture where those systems already exist. Relevant existing files remain:

- `docs/GDD.md`
- `docs/MAP_SPEC.md`
- `docs/NETWORK_SPEC.md`
- `docs/BACKEND_SPEC.md`
- `docs/GODOT_ARCHITECTURE.md`
- `docs/UI_UX_SPEC.md`
- `docs/RELEASE_CHECKLIST.md`
- `ROADMAP.md`

For presentation and interaction decisions, this design-freeze folder is newer and should be treated as the current redesign specification.

## Scope lock

V1 includes singleplayer world conquest and private direct-host multiplayer. Public matchmaking, ranked accounts, host migration, public late spectators, integrated voice/chat, replay viewer and dedicated server productization are not part of the first V1 presentation scope.

## Design freeze meaning

“Frozen” does not mean values can never be tuned. Runtime validation may still move a label by a few map units, adjust a color slightly, rebalance an audio level or choose an equivalent rendering technique. It does mean that implementation must not invent new game rules, navigation models, phase behavior or presentation semantics without an explicit design change.