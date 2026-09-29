# ATLAS FRONT — Audio and Asset Manifest Freeze

Status: **PASS / design frozen**

## 1. Audio identity

Sound should evoke a premium digital strategy table:

- subdued futuristic room ambience;
- physical tabletop sounds for dice/cards/pieces;
- precise electronic UI confirmation;
- restrained major-event emphasis.

Avoid arcade, casino, shooter and alarm-heavy sound language.

## 2. Audio buses

Conceptual buses:

- MASTER
- MUSIC
- GAME
- UI

Normal settings expose:

- Gesamt
- Musik
- Effekte

`GAME` and `UI` may remain internally separate while sharing the player-facing Effekte control.

## 3. Audio hierarchy

Priority:

`dice/combat result > major gameplay events > normal piece/card actions > UI confirmation > hover > ambience`

Repeated low-value sounds must never overpower strategic events.

## 4. Music

Required V1 tracks/stingers:

- `music_menu_ambient`
- `music_match_ambient`
- `music_victory_stinger`
- `music_defeat_stinger`

Menu and lobby share a command-room atmosphere. Match ambience is calmer/long-session oriented and does not restart dramatic music for every attack.

Preferred format for tracks/loops: Ogg Vorbis with clean loop points.

## 5. Board ambience

A very quiet board/room hum may support physical presence but must remain below gameplay cues.

Audio off must remove no information.

## 6. UI SFX

Release-required core set:

- `ui_confirm`
- `ui_back`
- `ui_invalid`
- `ui_warning`
- `timer_warning`

Optional polish: `ui_hover` with strong cooldown and very low prominence.

Hover/cursor motion must never generate audio spam.

## 7. Piece SFX

Required:

- `piece_select`
- `piece_reinforce`
- `piece_loss`
- `piece_transfer`
- `conquest_lock`

`piece_loss` should have multiple restrained variations. Multiple simultaneous/rapid placements are grouped/limited by polyphony.

## 8. Dice SFX

Required families:

- `dice_release`
- `dice_roll_surface`
- `dice_impact_light_*`
- `dice_impact_medium_*`
- `dice_impact_heavy_*`

Dice contacts are the most physical sound family and may use small randomized pitch/level variance. There is no semantic “ding” for each final face.

## 9. Card SFX

Required:

- `card_hand_open`
- `card_select`
- `card_draw`
- `card_flip`
- `card_trade`
- `card_shuffle`

AI/remote card draw does not use a face-reveal sound that could imply private information.

## 10. Major/system SFX

Required:

- `event_elimination`
- `event_timeout`
- `event_connection_lost`
- `event_reconnect`
- `event_host_lost`

Victory/defeat primarily use the musical stingers.

## 11. Audio privacy

Audio may never leak private card/type/plan information.

All opponent card backs/draws must sound information-equivalent regardless of hidden card type or joker identity.

## 12. Timer audio

A single warning near 10 seconds is allowed. Optional second subtle cue near 5 seconds. No per-second ticking countdown.

Defense timer uses the same family, at restrained level.

## 13. Ducking

Light ducking allowed for:

- elimination/victory;
- connection-lost critical notice.

Routine combat does not strongly duck the music.

## 14. Spatialization

Board sounds may use subtle positional panning. Dice are the strongest suitable spatial source.

Do not create extreme left/right isolation. UI/card overlay sounds remain primarily centered.

## 15. Audio-off parity

Complete match must remain fully understandable with:

- Music = 0;
- Effects = 0;
- Master = 0.

No gameplay state relies on sound alone.

---

# Asset Manifest

## 16. Asset status vocabulary

- **KEEP** — existing asset remains valid subject to final runtime validation.
- **REFERENCE** — may guide style/alignment but is not automatically runtime content.
- **REPLACE** — function remains but current asset does not satisfy frozen design.
- **RUNTIME** — generate/render dynamically, no dedicated external art asset.
- **NEW** — targeted new external asset required.
- **DEFERRED** — not needed for V1.
- **UNUSED** — not used by the redesign but not immediately deleted.

No existing asset is deleted during redesign until the replacement build is proven.

## 17. Final manifest fields

Every produced/retained external asset should document:

```text
asset_id
category
status
purpose
format
target_dimensions
alpha
runtime_modulation
source_asset_if_any
used_on
must_not_contain
acceptance_fixture
release_required
source/author/license information
```

## 18. Branding

### Wordmark

`branding_atlas_front_wordmark` — **KEEP**

Existing wordmark remains the allowed baked-text exception.

### Brand mark

`branding_atlas_front_mark` — **KEEP**

Used in compact top-bar/loading contexts.

### App icon

`branding_app_icon` — **KEEP**

Existing 1024 master remains baseline subject to Windows shell validation.

## 19. Environments

### Main menu

`env_main_menu_command_room` — **KEEP / validate**

Existing command-room background direction matches the product identity. Master quality should support 1080p, 1440p and ultrawide crop; 4K source preferred if regenerated.

### Match environment

`env_match_command_room` — **NEW**

Same room/world, composition centered on a rectangular physical command table. Must not contain world map, ownership, UI, labels, cards or dice result.

Preferred master: ~3840×2160 with safe crop margins.

### Table frame

`board_table_frame` — **NEW or runtime geometry**

Provides physical depth/material separation only.

## 20. Board surface

`board_surface_material` — **RUNTIME** plus optional small seamless material/noise texture.

No giant raster is needed for a dark glass surface.

Grid is **RUNTIME**.

Existing `ocean_grid.png` becomes **REFERENCE** only.

## 21. Neutral geography

`map_neutral_geography` — **NEW**

Preferred vector or high-resolution transparent raster aligned to 1600×820 logical map.

Raster target if used: about 3200×1640 or higher.

Contains coherent landmass/coastline/subtle geographic texture only.

Existing `world_underlay.png` is **REPLACE / ALIGNMENT REFERENCE** because it inherits the crude polygon character too directly.

## 22. Territory rendering

All of the following are **RUNTIME**:

- ownership fill;
- territory borders;
- coast/partition emphasis;
- hover;
- selection brackets;
- legal-target state;
- capture transition;
- attack/fortification routes;
- territory labels;
- continent labels.

No per-player/per-territory sprite sets.

## 23. Army piece

`piece_command_marker` — **NEW**

One neutral mesh/2.5D object, not five player variants.

Runtime supplies:

- player color;
- symbol;
- army number;
- interaction state.

Optional small neutral material/normal maps only if justified by actual screen size.

## 24. Player symbols

P1–P5 symbols are **RUNTIME VECTOR** where possible:

◆ ▲ ● ■ ⬢

No rendered PNG set required.

## 25. Dice

`dice_command_cube` — **NEW**

One neutral six-sided mesh/material with classic pips. Runtime applies attacker/defender role accent and target face orientation.

Existing `die_1.png` … `die_6.png` — **UNUSED / REFERENCE**.

## 26. Cards

Card frame/layout — **RUNTIME**.

`card_back_pattern` — **NEW** or deliberate new composition using brand mark.

Card-type glyphs:

- infantry — **REPLACE**
- cavalry — **REPLACE**
- artillery — **REPLACE**
- joker — **REPLACE**

Vector preferred.

All card text/state/badges remain runtime.

## 27. UI

Panels, buttons, modals, drawers, player cards, warnings, tooltips and phase strip are all **RUNTIME** via theme/style system.

Important gameplay actions do not require icons.

Allowed optional utility glyph categories:

- close;
- copy;
- volume/music/sfx;
- settings;
- cards;
- history;
- host.

Existing utility PNGs are **REFERENCE** until proven at final size.

Existing gameplay icons such as army/attack/fortification/target are **UNUSED in core primary actions**.

## 28. Decorative legacy assets

- `holographic_grid.png` — REFERENCE
- `scanline_overlay.png` — UNUSED
- `command_corner.png` — REFERENCE
- `separator_glow.png` — UNUSED
- `tech_pattern.png` — REFERENCE

Do not paste decorative corners/glows across the UI simply because the assets exist.

## 29. Legacy state backdrops

`reconnect_backdrop.png` — **REPLACE**. Reconnect should overlay the actual live match context.

`victory_backdrop.png` — **REPLACE**. Victory should preserve/show the actually conquered board behind the end state.

## 30. Font

`font_ui_inter` — **NEW/DEPENDENCY** with Regular 400, Medium 500, Semibold 600 and Bold 700.

Do not create/share custom font files. Use correctly licensed distribution source and document license.

Fallback only if technically necessary.

## 31. Asset licensing

Every external asset records:

- source;
- author;
- license;
- commercial-use permission;
- redistribution permission;
- modification status;
- attribution requirements.

No unknown-source asset enters release.

## 32. Generative art policy

Generated art is suitable primarily for non-interactive environment/concept layers. Gameplay-critical pieces, map state, cards, dice, labels and controls should use deterministic runtime/vector/3D systems.

Do not generate dozens of isolated gameplay icons simply because generation is available.

## 33. Production priorities

### P0 — required to judge the new visual core

1. match command-room environment
2. neutral geography
3. command piece
4. command dice
5. Inter font integration/validation

### P1

1. card back
2. four card glyphs
3. menu environment final validation
4. core UI/piece/dice SFX
5. match ambience

### P2 polish

- more impact variations;
- optional board material detail;
- optional utility glyph refinement;
- additional environment depth;
- optional music layers.

## 34. Acceptance rule

No asset is approved in isolation. It must be reviewed in the actual target fixture:

- environment behind full 5-player HUD;
- geography under 42 territories/pieces;
- piece on dense Europe fixture;
- dice in real 3v2 combat;
- card in 12-card hand/trade state;
- audio in repeated long-session actions.

Contact sheets or asset viewers are organizational aids, not quality gates.