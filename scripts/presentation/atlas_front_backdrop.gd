class_name AtlasFrontBackdrop
extends Control

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, AtlasFrontTheme.INK)
	draw_rect(Rect2(0, 0, size.x, size.y * 0.34), Color("#0a1b2b"))
	var horizon := size.y * 0.34
	for x in range(-int(size.y), int(size.x + size.y), 90):
		draw_line(Vector2(size.x * 0.5, horizon), Vector2(x, size.y), Color(AtlasFrontTheme.CYAN, 0.055), 1.0)
	for y in range(int(horizon), int(size.y) + 1, 58):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(AtlasFrontTheme.CYAN, 0.045), 1.0)
	for x in range(0, int(size.x) + 1, 120):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(AtlasFrontTheme.CYAN, 0.018), 1.0)
	var command_table := PackedVector2Array([
		Vector2(size.x * 0.10, size.y * 0.83),
		Vector2(size.x * 0.25, size.y * 0.48),
		Vector2(size.x * 0.76, size.y * 0.48),
		Vector2(size.x * 0.91, size.y * 0.83)
	])
	draw_colored_polygon(command_table, Color("#0c2431"))
	draw_polyline(command_table, Color(AtlasFrontTheme.CYAN, 0.18), 2.0)
	draw_line(Vector2(size.x * 0.16, size.y * 0.72), Vector2(size.x * 0.84, size.y * 0.72), Color(AtlasFrontTheme.CYAN, 0.13), 1.0)
	draw_line(Vector2(size.x * 0.26, size.y * 0.57), Vector2(size.x * 0.75, size.y * 0.57), Color(AtlasFrontTheme.CYAN, 0.10), 1.0)
