class_name AtlasFrontBackdrop
extends Control

var background_texture: Texture2D
var overlay_texture: Texture2D

func configure(background_path: String, overlay_path: String = "") -> void:
	background_texture = load(background_path) as Texture2D
	overlay_texture = load(overlay_path) as Texture2D if not overlay_path.is_empty() else null
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, AtlasFrontTheme.INK)
	if background_texture != null:
		_draw_cover(background_texture, bounds, Color.WHITE)
	if overlay_texture != null:
		_draw_cover(overlay_texture, bounds, Color(1.0, 1.0, 1.0, 0.38))
	draw_rect(bounds, Color(AtlasFrontTheme.INK, 0.20))

func _draw_cover(texture: Texture2D, bounds: Rect2, modulate: Color) -> void:
	var source_size := texture.get_size()
	if source_size.x <= 0.0 or source_size.y <= 0.0 or bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return
	var source_aspect := source_size.x / source_size.y
	var target_aspect := bounds.size.x / bounds.size.y
	var source_rect := Rect2(Vector2.ZERO, source_size)
	if source_aspect > target_aspect:
		var visible_width := source_size.y * target_aspect
		source_rect.position.x = (source_size.x - visible_width) * 0.5
		source_rect.size.x = visible_width
	else:
		var visible_height := source_size.x / target_aspect
		source_rect.position.y = (source_size.y - visible_height) * 0.5
		source_rect.size.y = visible_height
	draw_texture_rect_region(texture, bounds, source_rect, modulate)
