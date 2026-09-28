# ATLAS FRONT – Asset Extraction Audit

Status: **PASS – extraction hard gate erfüllt**  
Datum: 2026-09-28

## Quellen

- `D:/Downloads/ChatGPT-Bild 28. Sept. 2026, 18_39_58-1.png` (1536×1024)
- `D:/Downloads/ChatGPT-Bild 28. Sept. 2026, 18_39_59-2.png` (1536×1024)

Die Quellbilder wurden nur als Rasterquellen verwendet. Kein vollständiges Sheet, kein Label und kein Dateiname aus den Sheets ist Runtime-Asset. Die Ausgabedateien bleiben auf der nativen Crop-Auflösung der gelieferten Sheets; es wurde nicht künstlich hochskaliert oder neu generiert.

## Ergebnis

- Extrahierte PNGs: **33**
- PNGs mit echtem Alpha: **27**
- Vollflächig opake rechteckige PNGs: **6**
- Verworfen: **0**
- Kontaktübersicht: `assets/ui/atlas_front/_audit/extraction_contact.png`

## Assets mit echtem Alpha

### branding/

- `branding/atlas_front_wordmark.png` (499×153)
- `branding/atlas_front_mark.png` (268×153)

### icons/

- `icons/create_lobby.png`
- `icons/join_lobby.png`
- `icons/settings.png`
- `icons/quit.png`
- `icons/ready.png`
- `icons/cards.png`
- `icons/army.png`
- `icons/timer.png`
- `icons/connection.png`
- `icons/spectator.png`
- `icons/warning.png`

Alle Icon-Crops sind 80×80 Pixel.

### decor/

- `decor/holographic_grid.png`
- `decor/scanline_overlay.png`
- `decor/command_corner.png`
- `decor/separator_glow.png`
- `decor/panel_corner.png`
- `decor/panel_bar.png`
- `decor/panel_circle.png`
- `decor/tech_pattern.png`

### game/

- `game/world_underlay.png`

### misc/

- `misc/target_marker.png`
- `misc/hex_frame.png`
- `misc/dot.png`
- `misc/vline.png`
- `misc/hline.png`

Die Alpha-Kanäle wurden auf Checkerboard geprüft. Die fünf Misc-Assets verwenden zusätzlich eine cyan-spezifische Maske, damit der farbige Sheet-Hintergrund nicht als Halo erhalten bleibt.

## Opake rechteckige Assets

- `backgrounds/main_menu_command_room.png` (574×275)
- `backgrounds/lobby_command_room.png` (516×276)
- `backgrounds/menu_dark_overlay.png` (389×276)
- `game/ocean_grid.png` (240×207)
- `states/reconnect_backdrop.png` (466×214)
- `states/victory_backdrop.png` (426×214)

Diese sechs Dateien sind absichtlich vollflächig opak gespeichert, weil sie als rechteckige Background-/Backdrop-Assets zugelassen sind.

## Auditbefund

- Keine sichtbaren Sheet-Labels oder Dateinamen in den Einzelassets.
- Keine vollständigen Sheets und keine Sheet-Rahmen als Runtime-Asset.
- Keine abgeschnittenen Kernmotive; Glows erhalten einen kleinen transparenten Rand.
- Keine offenen Crop- oder Alpha-Fehler in der finalen Kontaktübersicht.
- Bekannte Einschränkung: Die gelieferten Quellen sind bereits 1536×1024 große Asset-Sheets mit Thumbnail-Crops. Deshalb entsprechen die Ausgabedimensionen der verfügbaren Rasterauflösung und nicht den nominalen Größenangaben, die in den Sheets stehen.

## Hard-Gate-Status

Die ursprünglichen PNG-Sheets werden nicht unter `assets/ui/atlas_front/` verwendet. Es wurde keine Godot-Szene, kein Script und keine Runtime-Referenz geändert. Die Godot-Integration bleibt bis zu einer separaten Freigabe pausiert.
