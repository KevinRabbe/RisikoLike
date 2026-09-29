# ATLAS FRONT — Visual System and Layout Freeze

Status: **PASS / frozen**

## 1. Visual identity

ATLAS FRONT is a premium digital board game on a futuristic command table. The main menu and match should feel like the same physical room viewed from different emphasis/camera positions.

The final match presentation is a controlled 2.5D / slightly oblique top-down table view, not free 3D.

The map remains flat and strategically readable. Environment is cinematic but subordinate.

## 2. Perceptual priority

Primary hierarchy:

1. board and territory state;
2. current action;
3. active player identity;
4. phase/timer;
5. supplemental information;
6. atmosphere/decor.

Army counts outrank territory labels; territory labels outrank decorative region text.

## 3. 1080p layout target

At 1920×1080:

- outer safe margin: ~24 px;
- top command bar: ~76 px;
- right player panel: ~304 px;
- bottom action panel: ~148 px;
- board receives remaining dominant area;
- gaps between large regions: ~12–16 px.

Responsive layout is not a uniform scale-down.

## 4. Responsive targets

Official QA sizes:

- 1280×720
- 1600×900
- 1920×1080
- 1920×1200
- 2560×1440
- 3440×1440

Minimum supported free window size: **1100×650**.

UI scale presets:

- 90%
- 100%
- 110%
- 125%

At cramped sizes, degradation order is:

1. remove decoration;
2. shorten/collapse secondary labels;
3. collapse continent info;
4. compact player cards;
5. reduce panel padding;
6. allow bottom action panel to use two rows;
7. slightly reduce typography;
8. shrink board last.

Core controls never move off-screen or require horizontal scrolling.

## 5. Ultrawide / aspect behavior

Board retains its logical aspect and is never horizontally stretched. Extra ultrawide space goes to ambience, safe margins or panels.

16:10 gains vertical board space.

Very narrow/4:3 is fallback only; right player panel may become a drawer if necessary.

## 6. Spacing tokens

Base spacing unit: **4 px**.

Canonical steps:

`4, 8, 12, 16, 20, 24, 32, 40, 48`

Typical use:

- 1080p safe margin: 24;
- 900p: 18–20;
- 720p: 12;
- standard panel padding: 24;
- compact panel padding: 16;
- same-group gaps: 8–12;
- group gaps: 20–24;
- major region gaps: 32–48.

## 7. Shape tokens

Approximate radii:

- buttons: 4–6 px;
- player cards: 6 px;
- large panels: 8 px;
- tooltips: 4–6 px;
- modal: 8 px;
- cards: 8–10 px.

Standard border: 1 px; focus/selection may use 1–2 px optical weight.

## 8. Materials

Primary materials:

- Board Metal
- Dark Glass
- Holographic Light

Panels are dark navy/graphite with controlled glass feel. Avoid excessive blur, fake transparency and permanent bloom.

## 9. Neutral palette

Target implementation values:

| Role | Value |
|---|---|
| Deep Background | `#040A10` |
| Board Deep | `#07131F` |
| Board Surface | `#0A1A27` |
| Raised Surface | `#102536` |
| Border Subtle | `#264051` |
| Border Normal | `#3A6176` |
| Text Primary | `#E9F2F7` |
| Text Secondary | `#A8BAC5` |
| Text Muted | `#71838E` |
| UI Accent | `#5BCDEB` |

These are frozen target values, subject only to small runtime calibration against the final board.

## 10. Player identity palette

Each player has Fill / Border / Bright / Muted roles.

| Player | Symbol | Fill | Border | Bright | Muted |
|---|---|---|---|---|---|
| P1 | ◆ | `#27B8D8` | `#35D4F4` | `#84ECFF` | `#397684` |
| P2 | ▲ | `#D95564` | `#F06A79` | `#FF9AA4` | `#824A53` |
| P3 | ● | `#45BA7A` | `#5EDB95` | `#9AF2BC` | `#47775B` |
| P4 | ■ | `#E79A3B` | `#FFB651` | `#FFD28A` | `#80623D` |
| P5 | ⬢ | `#9A79DF` | `#B593F5` | `#D5BCFF` | `#65557E` |

Ownership fill uses only roughly 18–24% visual strength over neutral geography. Border and piece carry stronger identity.

Color is never the sole semantic signal.

## 11. Territory interaction geometry

Selected territory combines:

- neutral bright outer edge;
- four corner brackets;
- stronger piece accent;
- weak inner glow.

Hover is lighter edge emphasis only; no pulse.

Legal target uses clear geometry/corners plus subtle directional treatment.

Invalid click may flash a warm cue for ~150–250 ms and also explains the reason in the action panel.

State priority:

`conquest transition > combat target/source > selected > legal target > hover > normal`

## 12. Glow budget

- `GLOW_0`: none
- `GLOW_1`: ownership/accent
- `GLOW_2`: hover/active
- `GLOW_3`: selection/target/important action
- `GLOW_4`: brief major event only

Permanent strong pulsing, scanlines, flicker and particle clutter are prohibited.

## 13. Typography

Primary UI family: **Inter**.

Fallback direction: Noto Sans or equivalent if required.

Weights:

- Regular 400
- Medium 500
- Semibold 600
- Bold 700

1080p target roles:

| Role | Size | Weight |
|---|---:|---|
| Display | 34–38 | Bold |
| Screen Title | 30–34 | Bold |
| Phase Title | 24–26 | Semibold |
| Panel Title | 20–22 | Semibold |
| Player Name | 17–18 | Semibold |
| Body | 17–18 | Regular |
| Button | 17–18 | Semibold |
| Secondary | 15–16 | Regular/Medium |
| Caption | 13–14 | Medium, noncritical only |
| Army Number | 20–26 | Bold |
| Dice Number | 22–28 | Bold |
| Timer | 22–24 | Medium |

Relevant game text should not fall below 15 px. Strategy numbers use tabular numerals.

Player names preserve user-entered case and are never forced uppercase.

## 14. Buttons

Families:

- Primary — accent-filled/strongest emphasis;
- Secondary — dark/outlined;
- Destructive — muted warm red/orange, reserved for truly destructive actions.

States:

- normal
- hover
- pressed
- focused
- disabled
- busy

Typical heights:

- normal 44–48 px;
- primary 48–52 px;
- compact 40–44 px.

Important actions are text-labelled. Disabled controls remain legible and may explain why they are unavailable.

## 15. Player card

1080p target: roughly 272 px wide × 60 px high with ~12 px padding.

Priority in match:

`identity > active state > territory count > card count > special status`

Active state: 2–3 px player-color strip, slightly raised surface, `AM ZUG`; no pulse.

Disconnected: dim + `VERBINDUNG VERLOREN`.

Eliminated: stronger dim, gameplay counts removed/reduced + `ELIMINIERT`.

## 16. Bottom action panel

Target heights:

- 1080p: ~148 px (140–160 acceptable calibration corridor)
- 900p: ~132–144 px
- 720p: ~118–126 px

Primary action zone occupies roughly the rightmost 28–32% where space allows.

Instructions are concise, normally no more than 2–3 short lines.

## 17. Tooltips

Delay: ~180 ms.

Typical width 180–220 px; complex max ~260 px.

Tooltips may cover noncritical map labels but never cover essential match controls such as the primary bottom action or turn timer.

Tooltip is supplemental; no essential interaction is hover-only.

## 18. Overlays and dim

Approximate board dim values:

- Cards / Rules / Settings: 55–65%
- Pause: 60–70%
- Victory/Defeat: 45–60%
- Connection Lost: 65–75%

Do not black out the board more than necessary; match context remains valuable.

## 19. Motion tokens

- `T_INSTANT`: 80–100 ms
- `T_FAST`: 120–160 ms
- `T_UI`: 180–240 ms
- `T_STATE`: 280–400 ms
- `T_GAMEPLAY`: 450–700 ms
- `T_MAJOR`: 900–1500 ms

Hover: 120–150 ms. Drawer: 220–280 ms. Overlay: 180–240 ms.

Camera focus: 300–450 ms; long pan cap ~650 ms.

No bouncy/cartoon easing.

## 20. Reduced motion

Reduced Motion removes or shortens:

- hover scaling/elevation;
- decorative pulses;
- camera theatrics;
- drawer slides;
- conquest flourish.

State information remains unchanged. Dice remain visibly physical.

## 21. Focus and accessibility

Keyboard focus uses a neutral bright ring distinct from hover, player color and selection.

Player identity always combines color and symbol.

Selection/legal target use geometry in addition to color.

The match must remain understandable in grayscale and with audio disabled.

## 22. Board visual stack

Logical presentation order from back to front:

1. command-room environment
2. physical table/frame
3. board/ocean surface
4. grid
5. neutral geography
6. ownership overlays
7. territory boundaries/coastline
8. attack/fortification routes
9. continent labels
10. territory labels
11. army pieces
12. hover/selection/target geometry
13. dice
14. board tooltips
15. screen HUD / overlays / modals

## 23. Grid and geography

Grid remains subordinate:

- minor dominance roughly 5–8%;
- major roughly 10–14%;
- grid < coastline < ownership border < selection.

Land must read as one coherent world geography, not 42 disconnected colored polygons.

No satellite texture, flags, city labels, roads or political borders beyond gameplay territory partitions.

## 24. Camera

Board camera operates inside the board viewport only.

- reset to Overview;
- pan bounded so board cannot be lost;
- minimum zoom shows board overview;
- max target ~1.8–2.2×;
- combat auto-focus is capped lower (~1.5–1.7×) to preserve context;
- focus framing accounts for top/right/bottom UI safe insets;
- Reduced Motion substantially reduces auto-pan.

## 25. Long-session rule

No unskippable vanity animation. Only gameplay-critical committed actions require visible presentation.

The UI is designed for 60+ minute sessions without persistent pulsing, repeated fanfares or high-contrast noise.