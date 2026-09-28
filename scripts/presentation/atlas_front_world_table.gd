class_name AtlasFrontWorldTable
extends Control

## Non-interactive homescreen atmosphere. It is deliberately separate from the
## production map so it can suggest a world without becoming gameplay geometry.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var horizon := size.y * 0.38
	var center := Vector2(size.x * 0.63, size.y * 0.48)
	var scale := minf(size.x, size.y) / 1000.0
	for radius in [230.0, 330.0, 430.0]:
		draw_arc(center, radius * scale, 0.0, TAU, 96, Color(AtlasFrontTheme.CYAN, 0.08), 1.0, true)
	for x in range(-int(size.y), int(size.x + size.y), 90):
		draw_line(Vector2(size.x * 0.55, horizon), Vector2(x, size.y), Color(AtlasFrontTheme.CYAN, 0.055), 1.0)
	for y in range(int(horizon), int(size.y) + 1, 54):
		draw_line(Vector2(size.x * 0.12, y), Vector2(size.x * 0.96, y), Color(AtlasFrontTheme.CYAN, 0.045), 1.0)
	var table := PackedVector2Array([
		Vector2(size.x * 0.28, size.y * 0.84),
		Vector2(size.x * 0.45, size.y * 0.47),
		Vector2(size.x * 0.86, size.y * 0.47),
		Vector2(size.x * 0.98, size.y * 0.84)
	])
	draw_colored_polygon(table, Color(AtlasFrontTheme.PANEL_MUTED, 0.82))
	draw_polyline(table, Color(AtlasFrontTheme.CYAN, 0.24), 2.0, true)
	var globe := PackedVector2Array([
		center + Vector2(-210, -28) * scale,
		center + Vector2(-152, -124) * scale,
		center + Vector2(-34, -164) * scale,
		center + Vector2(100, -132) * scale,
		center + Vector2(192, -48) * scale,
		center + Vector2(174, 48) * scale,
		center + Vector2(92, 112) * scale,
		center + Vector2(-48, 128) * scale,
		center + Vector2(-164, 82) * scale
	])
	# Abstract holographic landmass: visual only, not the match map.
	draw_colored_polygon(globe, Color(AtlasFrontTheme.CYAN, 0.10))
	draw_polyline(globe, Color(AtlasFrontTheme.CYAN, 0.45), 2.0, true)
	for offset in [-0.58, -0.28, 0.02, 0.32, 0.62]:
		var start := center + Vector2(-190, offset * 150.0) * scale
		var finish := center + Vector2(185, offset * 150.0) * scale
		draw_line(start, finish, Color(AtlasFrontTheme.CYAN, 0.16), 1.0)
	for offset in [-0.42, -0.12, 0.18, 0.48]:
		var start := center + Vector2(offset * 260.0, -138) * scale
		var finish := center + Vector2(offset * 260.0, 112) * scale
		draw_line(start, finish, Color(AtlasFrontTheme.CYAN, 0.14), 1.0)
	for point: Vector2 in [Vector2(-112, -56), Vector2(-28, -106), Vector2(78, -62), Vector2(124, 32), Vector2(-54, 72)]:
		var marker: Vector2 = center + point * scale
		draw_circle(marker, 4.0 * scale, Color(AtlasFrontTheme.CYAN, 0.9))
		draw_circle(marker, 12.0 * scale, Color(AtlasFrontTheme.CYAN, 0.14))
		var ray := PackedVector2Array([marker, marker + Vector2(28, -20) * scale])
		draw_polyline(ray, Color(AtlasFrontTheme.CYAN, 0.30), 1.0)
	draw_string(ThemeDB.fallback_font, center + Vector2(-205, 184) * scale, "ATLAS COMMAND TABLE  //  PRIVATE SESSION", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(AtlasFrontTheme.CYAN_SOFT, 0.68))
