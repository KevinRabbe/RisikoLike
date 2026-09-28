class_name MapController
extends Control

signal territory_selected(territory_id: String)

var map_data: MapData
var game_state: GameState
var map_surface: ProductionMapSurface
var grid: Control
var hovered_territory_id := ""
var selected_territory_id := ""
var zoom_level := 0.82
var pan_offset := Vector2.ZERO
var auto_fit_pending := true
var _dragging := false
var _drag_start := Vector2.ZERO
var _drag_origin := Vector2.ZERO
var _press_position := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(_on_resized)

func configure(p_map_data: MapData, p_game_state: GameState) -> void:
	map_data = p_map_data
	game_state = p_game_state
	for child in get_children():
		child.queue_free()
	map_surface = ProductionMapSurface.new()
	map_surface.configure(map_data, game_state)
	map_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_surface)
	grid = map_surface
	pan_offset = Vector2.ZERO
	auto_fit_pending = true
	call_deferred("_layout_surface")
	refresh()

func refresh() -> void:
	if game_state == null or map_surface == null:
		return
	map_surface.game_state = game_state
	map_surface.set_interaction_state(hovered_territory_id, selected_territory_id, map_surface.source_territory_id, map_surface.target_territory_id, map_surface.interaction_phase, map_surface.interaction_player_id)
	tooltip_text = _tooltip_for(hovered_territory_id)

func set_interaction_context(source_id: String, target_id: String, phase: int, player_id: String) -> void:
	if map_surface == null:
		return
	map_surface.set_interaction_state(hovered_territory_id, selected_territory_id, source_id, target_id, phase, player_id)
	tooltip_text = _tooltip_for(hovered_territory_id)

func territory_at_screen_position(screen_position: Vector2) -> String:
	return _territory_at_world_position(_world_position(screen_position))

func zoom_in() -> void:
	_zoom_at(zoom_level + 0.1, size * 0.5)

func zoom_out() -> void:
	_zoom_at(zoom_level - 0.1, size * 0.5)

func reset_view() -> void:
	zoom_level = _default_zoom()
	pan_offset = Vector2.ZERO
	auto_fit_pending = false
	_layout_surface()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _dragging:
			pan_offset = _drag_origin + (motion.position - _drag_start)
			_layout_surface()
			return
		_set_hovered(_territory_at_world_position(_world_position(motion.position)))
		return
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_WHEEL_UP and button.pressed:
			_zoom_at(zoom_level + 0.1, button.position)
			return
		if button.button_index == MOUSE_BUTTON_WHEEL_DOWN and button.pressed:
			_zoom_at(zoom_level - 0.1, button.position)
			return
		if button.button_index == MOUSE_BUTTON_MIDDLE:
			if button.pressed:
				_dragging = true
				_drag_start = button.position
				_drag_origin = pan_offset
			else:
				_dragging = false
			return
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed:
				_press_position = button.position
			else:
				if not _dragging and button.position.distance_to(_press_position) < 8.0:
					var territory_id := _territory_at_world_position(_world_position(button.position))
					if not territory_id.is_empty():
						_on_territory_pressed(territory_id)

func _on_territory_pressed(territory_id: String) -> void:
	selected_territory_id = territory_id
	refresh()
	territory_selected.emit(territory_id)

func _set_hovered(territory_id: String) -> void:
	if hovered_territory_id == territory_id:
		return
	hovered_territory_id = territory_id
	refresh()

func _world_position(screen_position: Vector2) -> Vector2:
	if map_surface == null or zoom_level <= 0.0:
		return Vector2(-1, -1)
	return (screen_position - map_surface.position) / zoom_level

func _territory_at_world_position(world_position: Vector2) -> String:
	if map_surface == null:
		return ""
	var ids: Array[String] = []
	for territory_id: String in map_surface.visuals:
		ids.append(territory_id)
	ids.sort()
	for territory_id in ids:
		var visual := map_surface.visuals[territory_id] as TerritoryVisualDefinition
		if visual != null and Geometry2D.is_point_in_polygon(world_position, visual.polygon):
			return territory_id
	return ""

func _zoom_at(next_zoom: float, focus_position: Vector2) -> void:
	if map_surface == null:
		return
	var clamped := clampf(next_zoom, 0.7, 1.6)
	if is_equal_approx(clamped, zoom_level):
		return
	var focus_world := _world_position(focus_position)
	zoom_level = clamped
	auto_fit_pending = false
	_layout_surface()
	var focus_after := map_surface.position + focus_world * zoom_level
	pan_offset += focus_position - focus_after
	_layout_surface()

func _layout_surface() -> void:
	if map_surface == null:
		return
	if auto_fit_pending:
		zoom_level = _default_zoom()
		auto_fit_pending = false
	map_surface.scale = Vector2.ONE * zoom_level
	map_surface.position = (size - MapVisualDefinition.MAP_SIZE * zoom_level) * 0.5 + pan_offset
	map_surface.set_render_zoom(zoom_level)

func _on_resized() -> void:
	if not _dragging and map_surface != null and pan_offset == Vector2.ZERO:
		auto_fit_pending = true
	_layout_surface()

func _default_zoom() -> float:
	if size.x <= 1.0 or size.y <= 1.0:
		return 0.82
	var fit := minf(size.x / MapVisualDefinition.MAP_SIZE.x, size.y / MapVisualDefinition.MAP_SIZE.y)
	return clampf(fit * 0.96, 0.52, 1.35)

func _tooltip_for(territory_id: String) -> String:
	if territory_id.is_empty() or map_data == null or game_state == null:
		return ""
	var definition := map_data.get_territory(territory_id)
	var state := game_state.get_territory(territory_id)
	if definition == null or state == null:
		return ""
	var player := game_state.get_player(state.owner_player_id)
	var owner := player.name if player != null else "Unbesetzt"
	var region := map_data.get_region(definition.region_id)
	return "%s\n%s\nBesitzer: %s\nTruppen: %d" % [definition.name_de, region.name_de if region != null else definition.region_id, owner, state.army_count]
