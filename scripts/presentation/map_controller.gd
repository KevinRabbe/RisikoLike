class_name MapController
extends Control

signal territory_selected(territory_id: String)

var map_data: MapData
var game_state: GameState
var territory_buttons: Dictionary = {}
var grid: GridContainer
var scroll_container: ScrollContainer
var hovered_territory_id := ""
var selected_territory_id := ""
var zoom_level := 1.0

func configure(p_map_data: MapData, p_game_state: GameState) -> void:
	map_data = p_map_data
	game_state = p_game_state
	_build_placeholder_board()
	refresh()

func refresh() -> void:
	if game_state == null:
		return
	for territory_id: String in territory_buttons:
		var button: Button = territory_buttons[territory_id]
		var definition := map_data.get_territory(territory_id)
		var state := game_state.get_territory(territory_id)
		if definition == null or state == null:
			continue
		button.text = "%s\n%d" % [definition.name_de, state.army_count]
		button.tooltip_text = "%s | %s | %d Truppen" % [definition.name_de, state.owner_player_id, state.army_count]
		var player := game_state.get_player(state.owner_player_id)
		var color := player.color if player != null else Color.DIM_GRAY
		if territory_id == hovered_territory_id or territory_id == selected_territory_id:
			color = color.lightened(0.3)
		button.modulate = color

func zoom_in() -> void:
	zoom_level = minf(zoom_level + 0.1, 1.6)
	_apply_zoom()

func zoom_out() -> void:
	zoom_level = maxf(zoom_level - 0.1, 0.7)
	_apply_zoom()

func reset_view() -> void:
	zoom_level = 1.0
	_apply_zoom()
	if scroll_container != null:
		scroll_container.scroll_horizontal = 0
		scroll_container.scroll_vertical = 0

func _build_placeholder_board() -> void:
	for child in get_children():
		child.queue_free()
	territory_buttons.clear()
	scroll_container = ScrollContainer.new()
	scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(scroll_container)
	grid = GridContainer.new()
	grid.columns = 6
	grid.custom_minimum_size = Vector2(900, 620)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll_container.add_child(grid)
	var ids: Array[String] = []
	for territory_id: String in map_data.territories:
		ids.append(territory_id)
	ids.sort()
	for territory_id in ids:
		var button := Button.new()
		button.custom_minimum_size = Vector2(145, 72)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_on_territory_pressed.bind(territory_id))
		button.mouse_entered.connect(_on_territory_hovered.bind(territory_id))
		button.mouse_exited.connect(_on_territory_unhovered.bind(territory_id))
		grid.add_child(button)
		territory_buttons[territory_id] = button
	_apply_zoom()

func _on_territory_pressed(territory_id: String) -> void:
	selected_territory_id = territory_id
	territory_selected.emit(territory_id)
	refresh()

func _on_territory_hovered(territory_id: String) -> void:
	hovered_territory_id = territory_id
	refresh()

func _on_territory_unhovered(territory_id: String) -> void:
	if hovered_territory_id == territory_id:
		hovered_territory_id = ""
	refresh()

func _apply_zoom() -> void:
	if grid == null:
		return
	grid.scale = Vector2.ONE * zoom_level
	grid.custom_minimum_size = Vector2(900, 620) * zoom_level
