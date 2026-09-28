class_name ProductionMapSurface
extends Control

const MAP_SIZE := MapVisualDefinition.MAP_SIZE
const OCEAN := Color("#07111d")
const GRID := Color(0.15, 0.28, 0.38, 0.18)
const LAND_BASE := Color("#1b3444")
const LAND_EDGE := Color("#79a6b8")
const REGION_TEXT := Color(0.54, 0.75, 0.83, 0.42)
const TEXT := Color("#d9edf2")
const NEON := Color("#5be7e5")
const INVALID := Color("#ff7185")

var map_data: MapData
var game_state: GameState
var visuals: Dictionary = {}
var hovered_territory_id := ""
var selected_territory_id := ""
var source_territory_id := ""
var target_territory_id := ""
var interaction_phase := -1
var interaction_player_id := ""
var render_zoom := 1.0

func configure(p_map_data: MapData, p_game_state: GameState) -> void:
	map_data = p_map_data
	game_state = p_game_state
	visuals = MapVisualDefinition.create_default()
	custom_minimum_size = MAP_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func set_interaction_state(
		p_hovered: String,
		p_selected: String,
		p_source: String,
		p_target: String,
		p_phase: int,
		p_player_id: String
	) -> void:
	hovered_territory_id = p_hovered
	selected_territory_id = p_selected
	source_territory_id = p_source
	target_territory_id = p_target
	interaction_phase = p_phase
	interaction_player_id = p_player_id
	queue_redraw()

func set_render_zoom(value: float) -> void:
	render_zoom = value
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), OCEAN)
	_draw_grid()
	_draw_region_labels()
	_draw_water_connections()
	for territory_id: String in visuals:
		_draw_territory(territory_id, visuals[territory_id] as TerritoryVisualDefinition)

func _draw_grid() -> void:
	for x in range(0, int(MAP_SIZE.x) + 1, 80):
		draw_line(Vector2(x, 0), Vector2(x, MAP_SIZE.y), GRID, 1.0)
	for y in range(0, int(MAP_SIZE.y) + 1, 80):
		draw_line(Vector2(0, y), Vector2(MAP_SIZE.x, y), GRID, 1.0)

func _draw_region_labels() -> void:
	var font := ThemeDB.fallback_font
	var positions := MapVisualDefinition.region_label_positions()
	for region_id: String in positions:
		var region := map_data.get_region(region_id) if map_data != null else null
		if region == null:
			continue
		var position: Vector2 = positions[region_id]
		draw_string(font, position, region.name_de.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, REGION_TEXT)

func _draw_water_connections() -> void:
	if map_data == null:
		return
	var drawn := {}
	for territory_id: String in map_data.territories:
		var territory := map_data.get_territory(territory_id)
		var visual := visuals.get(territory_id) as TerritoryVisualDefinition
		if territory == null or visual == null:
			continue
		for neighbor_id: String in territory.neighbors:
			var edge_key := "%s:%s" % [territory_id, neighbor_id] if territory_id < neighbor_id else "%s:%s" % [neighbor_id, territory_id]
			if drawn.has(edge_key):
				continue
			drawn[edge_key] = true
			var neighbor := map_data.get_territory(neighbor_id)
			var neighbor_visual := visuals.get(neighbor_id) as TerritoryVisualDefinition
			if neighbor == null or neighbor_visual == null or neighbor.region_id == territory.region_id:
				continue
			var from_point := _connection_point(visual, neighbor_visual.marker_position)
			var to_point := _connection_point(neighbor_visual, visual.marker_position)
			_draw_dashed_line(from_point, to_point, Color(0.32, 0.72, 0.78, 0.52), 2.0)
	# The Alaska/Kamtschatka edge is a wrapped water connection, so draw it at both map edges.
	_draw_dashed_line(Vector2(18, 202), Vector2(78, 202), Color(0.32, 0.72, 0.78, 0.72), 2.0)
	_draw_dashed_line(Vector2(1522, 202), Vector2(1582, 202), Color(0.32, 0.72, 0.78, 0.72), 2.0)

func _connection_point(visual: TerritoryVisualDefinition, fallback: Vector2) -> Vector2:
	return visual.connection_anchors[0] if not visual.connection_anchors.is_empty() else fallback

func _draw_dashed_line(from_point: Vector2, to_point: Vector2, color: Color, width: float) -> void:
	var distance := from_point.distance_to(to_point)
	var direction := (to_point - from_point).normalized()
	var cursor := 0.0
	while cursor < distance:
		var segment_start := from_point + direction * cursor
		var segment_end := from_point + direction * minf(cursor + 8.0, distance)
		draw_line(segment_start, segment_end, color, width, true)
		cursor += 15.0

func _draw_territory(territory_id: String, visual: TerritoryVisualDefinition) -> void:
	if visual == null:
		return
	var state := game_state.get_territory(territory_id) if game_state != null else null
	var owner_color := LAND_BASE
	if state != null and game_state != null:
		var player := game_state.get_player(state.owner_player_id)
		if player != null:
			owner_color = Color(player.color, 1.0)
	var fill := _ownership_fill(owner_color)
	var interaction := _interaction_for(territory_id)
	if interaction == "valid":
		fill = fill.lightened(0.08)
	elif interaction == "invalid":
		fill = fill.darkened(0.08)
	draw_colored_polygon(visual.polygon, fill)
	var border := LAND_EDGE
	var border_width := 1.6
	match interaction:
		"hover":
			border = NEON
			border_width = 2.4
		"selected", "source":
			border = Color("#8af7ff")
			border_width = 3.6
		"valid":
			border = NEON
			border_width = 3.0
		"invalid":
			border = INVALID
			border_width = 2.5
		"target":
			border = Color("#d9faff")
			border_width = 3.2
	var closed := PackedVector2Array(visual.polygon)
	closed.append(visual.polygon[0])
	draw_polyline(closed, border, border_width, true)
	if interaction in ["selected", "source", "valid", "target"]:
		draw_polyline(closed, Color(border, 0.18), border_width * 3.0, true)
	if render_zoom >= 0.78:
		var font := ThemeDB.fallback_font
		var label_size := 13 if render_zoom < 1.0 else 15
		draw_string(font, visual.label_position, _short_name(territory_id), HORIZONTAL_ALIGNMENT_CENTER, 100, label_size, TEXT)
	_draw_army_marker(visual.marker_position, state.army_count if state != null else 0, owner_color, interaction)

func _draw_army_marker(position: Vector2, count: int, owner_color: Color, interaction: String) -> void:
	var radius := 17.0 if render_zoom >= 0.9 else 14.0
	var marker_color := Color("#101d2b").lightened(0.12)
	if interaction == "hover" or interaction == "selected" or interaction == "source" or interaction == "target":
		marker_color = Color(owner_color, 1.0).lightened(0.18)
	draw_circle(position, radius + 3.0, Color(owner_color, 0.3))
	draw_circle(position, radius, marker_color)
	draw_arc(position, radius, 0.0, TAU, 24, Color(owner_color, 0.95), 2.0, true)
	var font := ThemeDB.fallback_font
	draw_string(font, position + Vector2(-22, 6), str(count), HORIZONTAL_ALIGNMENT_CENTER, 44, 16, TEXT)

func _ownership_fill(color: Color) -> Color:
	return Color(0.08 + color.r * 0.42, 0.12 + color.g * 0.42, 0.16 + color.b * 0.42, 1.0)

func _interaction_for(territory_id: String) -> String:
	if territory_id == target_territory_id and not target_territory_id.is_empty():
		return "target" if _is_valid_target(territory_id) else "invalid"
	if territory_id == source_territory_id and not source_territory_id.is_empty():
		return "source"
	if territory_id == selected_territory_id and not selected_territory_id.is_empty():
		return "selected"
	if _is_valid_target(territory_id):
		return "valid"
	if territory_id == hovered_territory_id:
		return "hover"
	return "normal"

func _is_valid_target(territory_id: String) -> bool:
	if source_territory_id.is_empty() or map_data == null or game_state == null or interaction_player_id.is_empty():
		return false
	var source := map_data.get_territory(source_territory_id)
	var target := map_data.get_territory(territory_id)
	var target_state := game_state.get_territory(territory_id)
	if source == null or target == null or target_state == null:
		return false
	if not source.neighbors.has(territory_id):
		return false
	if interaction_phase == TurnState.Phase.ATTACK:
		return target_state.owner_player_id != interaction_player_id
	if interaction_phase == TurnState.Phase.FORTIFICATION:
		return target_state.owner_player_id == interaction_player_id
	return target_state.owner_player_id == interaction_player_id

func _short_name(territory_id: String) -> String:
	var definition := map_data.get_territory(territory_id) if map_data != null else null
	return definition.name_de if definition != null else territory_id
