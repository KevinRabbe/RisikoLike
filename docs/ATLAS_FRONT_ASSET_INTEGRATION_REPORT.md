# ATLAS // FRONT Final Asset Integration Report

Status: **PASS**

The 48-PNG source-of-truth pack under `assets/ui/atlas_front_final/` is now
integrated without changing gameplay rules, network architecture, backend
optionality, reconnect logic, timers, map topology, cards, or audio logic.

## Integrated

- Final command-room background and branding are used by the menu, settings,
  lobby, and game presentation.
- Existing controls use matching final icons where available: lobby, join,
  settings, ready, copy, start, back, gameplay, cards, dice, audio, and
  status controls.
- The Windows project/export app icon points to the final 1024px mark asset.
- `ocean_grid.png` and `world_underlay.png` are atmospheric map layers only.
  The 42 territory polygons remain the interactive source of truth, and
  ownership colors are drawn above both layers.
- Direct Host/TCP remains the default; no backend requirement was introduced.

## Retained legacy assets

Only these two files remain under `assets/ui/atlas_front/`:

- `states/reconnect_backdrop.png`
- `states/victory_backdrop.png`

The final 48-asset pack contains no state-backdrop replacements, and these
files are still used by the existing reconnect/victory UI. Superseded old
backgrounds, branding, icons, map layers, decor, misc assets, and extraction
audit files were removed after reference verification.

## Capture gate

The M13 capture harness completed with the Windows/OpenGL renderer at both
resolutions:

- `builds/atlas-front-captures-final-1920/` — 16 PNGs, 1920×1080
- `builds/atlas-front-captures-final-1280/` — 16 PNGs, 1280×720

Reviewed captures include Main Menu, Lobby, Game, Attack, Cards, Reconnect,
Victory, and the other existing presentation states. No sheets, black alpha
boxes, missing final assets, or map ownership regressions were observed.

## Asset verification

- Final PNGs: **48 / 48**
- Final manifest: `assets/ui/atlas_front_final/ASSET_MANIFEST.md`
- `atlas_front_v2`: removed as obsolete generated duplicate pack
- Runtime references to `atlas_front_v2`: none

## Automated verification

- Base: `294 passed`
- M9: `29 passed`
- M10: `27 passed`
- M11: `63 passed`
- M12: `180 passed`
- M13: `14 passed`
- M14: `12 passed`
- M15: `24 passed`
- M16: `8 passed`
- Direct invite: `15 passed`
- TCP: `9 passed`
- Backend pytest: `18 passed`
- BackendClient: `6 passed`
- Legacy WebRTC two-process smoke: host/client exit `0`, identical
  revision/fingerprint
- Direct Host two-process reconnect: host/client exit `0`, identical
  revision/fingerprint
- Direct Host three-process lobby: all three exit `0`

## Windows RC package

- Version: `0.1.0`
- ZIP: `dist/AtlasFront-0.1.0-windows-x86_64.zip`
- ZIP size: `78,578,629` bytes
- SHA-256: `5F640DCC3F135726B6AACF3865210DD574860C0DE69D4A7FF3A009AD515EEC42`
- Direct dist startup smoke: exit `0`
- Package audit: no tests, captures, `.env`, secrets, or source dumps; runtime
  binary, WebRTC DLL, and license notices present.
